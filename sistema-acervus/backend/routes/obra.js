const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');
 
 
 
const upload = require('../middlewares/uploadObraImagem');
 
 ;



const mimeByExt = {
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  gif: 'image/gif',
  bmp: 'image/bmp',
  webp: 'image/webp'
};

const resolveMime = (ext) => {
  if (!ext) return 'application/octet-stream';
  const clean = `${ext}`.replace('.', '').toLowerCase();
  return mimeByExt[clean] || 'application/octet-stream';
};

const decodeBase64 = (base64Str) => {
  try {
    return Buffer.from(base64Str, 'base64');
  } catch (e) {
    return null;
  }
};

const mapMovimentoRow = (row) => ({
  id: row.id,
  cd_obra: row.cd_obra,
  tipo_movimento: row.tipo_movimento,
  descricao: row.descricao,
  pais_id: row.pais_id,
  estado_id: row.estado_id,
  cidade_id: row.cidade_id,
  data_inicial: row.data_inicial,
  data_final: row.data_final,
  valor: row.valor,
  laudo_inicial: row.laudo_inicial,
  laudo_final: row.laudo_final,
});

// =====================
// GET /obra/listar
// =====================
router.get('/listar', tokenOpcional, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const search = req.query.q?.trim();

  const valores = [];
  const filtros = [];

  if (search) {
    if (/^\d+$/.test(search)) {
      valores.push(parseInt(search, 10));
      filtros.push(`o.cd_obra = $${valores.length}`);
    } else {
      valores.push(`%${search}%`);
      filtros.push(`
        unaccent(lower(o.titulo)) ILIKE unaccent(lower($${valores.length}))
        OR unaccent(lower(o.subtitulo)) ILIKE unaccent(lower($${valores.length}))
      `);
    }
  }

  const where = filtros.length ? `WHERE (${filtros.join(' OR ')})` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_obra o
    ${where}
  `;

  const baseQuery = `
     
      SELECT
      cd_obra,
      cd_material,
      cd_tipo_peca,
      cd_subtipo_peca,
      cd_assunto,
      cd_idioma,
      titulo,
      subtitulo,
      cd_estado_conservacao,
      data_compra,
      numero_apolice,
      valor,
      cd_estante_prateleira,
      cd_editora,
      numero_edicao,
      qtd_paginas,
      volume,
      resumo,
      observacao,
      carimbo,
      cd_autor,
      cd_autor_2,
      medida,
      conjunto,
      origem,
      data_historica,
      codigo_obra_tipo,
      posicao_obra,
      nr_carimbo,
      cd_estante_prateleira_from
    FROM public.ace_obra o
    ${where}
    ORDER BY o.cd_obra DESC
  `;

  try {
    const resultado = await paginarConsulta(
      pool,
      baseQuery,
      countQuery,
      valores,
      page,
      limit
    );

    res.json(resultado);
  } catch (err) {
    console.error('Erro ao listar obras:', err);
    logger.error('Erro ao listar obras: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao listar obras.' , motivo: err.message});
  }
});

// =====================
// GET /obra/galeria/:obraId
// Lista imagens cadastradas na tabela ace_obra_galeria
// =====================
router.get('/galeria/:obraId', tokenOpcional, async (req, res) => {
  const obraId = parseInt(req.params.obraId, 10);

  if (!obraId) {
    return res.status(400).json({ erro: 'Obra inválida.' });
  }

  const query = `
    SELECT
      id,
      cd_obra,
      ds_imagem,
      sts_principal,
      nome,
      extensao,
      CASE WHEN imagem IS NOT NULL THEN encode(imagem, 'base64') END AS imagem_base64
    FROM public.ace_obra_galeria
    WHERE cd_obra = $1
    ORDER BY id DESC
  `;

  try {
    const result = await pool.query(query, [obraId]);
    res.json({ dados: result.rows });
  } catch (err) {
    console.error('Erro ao listar galeria:', err);
    logger.error('Erro ao listar galeria: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao listar galeria.' });
  }
});

// =====================
// GET /obra/galeria/arquivo/:id
// Retorna o binário da imagem
// =====================
router.get('/galeria/arquivo/:id', tokenOpcional, async (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT imagem, extensao, nome
    FROM public.ace_obra_galeria
    WHERE id = $1
    LIMIT 1
  `;

  try {
    const result = await pool.query(query, [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Imagem não encontrada.' });
    }

    const row = result.rows[0];

    if (!row.imagem) {
      return res.status(404).json({ erro: 'Imagem sem conteúdo.' });
    }

    const mime = resolveMime(row.extensao);
    const filenameBase = row.nome || 'imagem';
    const ext = row.extensao ? `${row.extensao}`.replace('.', '') : 'bin';

    res.setHeader('Content-Type', mime);
    res.setHeader(
      'Content-Disposition',
      `inline; filename="${filenameBase}.${ext}"`
    );

    return res.send(row.imagem);
  } catch (err) {
    console.error('Erro ao obter arquivo da galeria:', err);
    logger.error('Erro ao obter arquivo da galeria: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao obter arquivo.' });
  }
});

// =====================
// POST /obra/galeria/:obraId
// Salva imagem da galeria (base64)
// =====================
// =====================
// POST /obra/galeria/adicionar/:obraId
// Upload de imagem (arquivo físico, sem base64)
// =====================
router.post(
  '/galeria/adicionar/:obraId',
  verificarToken,
  upload.single('arquivo'),
  async (req, res) => {
    const obraId = parseInt(req.params.obraId, 10);
    if (!obraId) {
      return res.status(400).json({ erro: 'Obra inválida.' });
    }

    const client = await pool.connect();

    try {
      const {
        ds_imagem = null,
        sts_principal = false,
      } = req.body;

      if (!req.file) {
        return res.status(400).json({ erro: 'Arquivo não enviado.' });
      }

      // ⭐ Se for capa, desmarca as outras
      if (sts_principal === 'true' || sts_principal === true || sts_principal === '1') {
        await client.query(
          `
          UPDATE ace_obra_galeria
             SET sts_principal = false
           WHERE cd_obra = $1
          `,
          [obraId]
        );
      }

      // 💾 Salva SOMENTE metadados
      const insertQuery = `
        INSERT INTO ace_obra_galeria
          (cd_obra, nome, extensao, sts_principal, ds_imagem)
        VALUES
          ($1, $2, $3, $4, $5)
        RETURNING
          id,
          cd_obra,
          nome,
          extensao,
          sts_principal,
          ds_imagem
      `;

      const values = [
        obraId,
        req.file.filename,        // nome físico salvo
        req.file.mimetype,        // ex: image/jpeg
        sts_principal === 'true' || sts_principal === true || sts_principal === '1',
        ds_imagem,
      ];

      const result = await client.query(insertQuery, values);
      const row = result.rows[0];

      return res.status(201).json({
        ...row,
        url: `/uploads/obras/${obraId}/${req.file.filename}`,
      });
    } catch (err) {
      console.error('Erro ao salvar imagem da galeria:', err);
      logger.error('Erro ao salvar imagem da galeria: ' + err.stack, 'obras');
      return res.status(500).json({
        erro: 'Erro ao salvar imagem da galeria.',
        detalhe: err.message,
      });
    } finally {
      client.release();
    }
  }
);


// =====================
// PUT /obra/galeria/:id
// Atualiza metadados/rotacao e (opcional) substitui a imagem
// =====================
router.put('/galeria/editar/:id', verificarToken, async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (!id) {
    return res.status(400).json({ erro: 'Imagem inválida.' });
  }

  const {
    nome,
    ds_imagem,
    extensao,
    imagem_base64,
    sts_principal,
    rotacao,
  } = req.body || {};

  const updates = [];
  const values = [];

  const pushUpdate = (col, val) => {
    updates.push(`${col} = $${updates.length + 1}`);
    values.push(val);
  };

  if (nome !== undefined) pushUpdate('nome', nome || null);
  if (ds_imagem !== undefined) pushUpdate('ds_imagem', ds_imagem || null);
  if (extensao !== undefined) pushUpdate('extensao', extensao || null);
  if (sts_principal !== undefined) pushUpdate('sts_principal', !!sts_principal);
  if (rotacao !== undefined && rotacao !== null && !Number.isNaN(Number(rotacao))) {
    pushUpdate('rotacao', Number(rotacao));
  }

  if (imagem_base64) {
    const buffer = decodeBase64(imagem_base64);
    if (!buffer) {
      return res.status(400).json({ erro: 'Falha ao decodificar imagem.' });
    }
    pushUpdate('imagem', buffer);
  }

  if (!updates.length) {
    return res.status(400).json({ erro: 'Nenhum campo para atualizar.' });
  }

  const query = `
    UPDATE public.ace_obra_galeria
    SET ${updates.join(', ')}
    WHERE id = $${updates.length + 1}
    RETURNING
      id,
      cd_obra,
      ds_imagem,
      sts_principal,
      nome,
      extensao,
      CASE WHEN imagem IS NOT NULL THEN encode(imagem, 'base64') END AS imagem_base64
  `;

  values.push(id);

  try {
    const result = await pool.query(query, values);
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Imagem não encontrada.' });
    }
    return res.json({ dados: result.rows[0] });
  } catch (err) {
    console.error('Erro ao atualizar imagem da galeria:', err);
    logger.error('Erro ao atualizar imagem da galeria: ' + err.stack, 'obras');
    return res.status(500).json({ erro: 'Erro ao atualizar imagem da galeria.' });
  }
});

// =====================
// GET /obra/movimentacoes/:obraId
// Lista movimentações de uma obra
// =====================
router.get('/movimentacoes/:obraId', tokenOpcional, async (req, res) => {
  const obraId = parseInt(req.params.obraId, 10);

  if (!obraId) {
    return res.status(400).json({ erro: 'Obra inválida.' });
  }

  const query = `
    SELECT
      id,
      cd_obra,
      tipo_movimento,
      descricao,
      pais_id,
      estado_id,
      cidade_id,
      data_inicial,
      data_final,
      valor,
      laudo_inicial,
      laudo_final
    FROM public.ace_obra_movimentacao
    WHERE cd_obra = $1
    ORDER BY id DESC
  `;

  try {
    const result = await pool.query(query, [obraId]);
    res.json({ dados: result.rows.map(mapMovimentoRow) });
  } catch (err) {
    console.error('Erro ao listar movimentações:', err);
    logger.error('Erro ao listar movimentações: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao listar movimentações.' });
  }
});

// =====================
// POST /obra/movimentacoes/:obraId
// Cria nova movimentação
// =====================
router.post('/movimentacoes/:obraId', verificarToken, async (req, res) => {
  const obraId = parseInt(req.params.obraId, 10);
  if (!obraId) {
    return res.status(400).json({ erro: 'Obra inválida.' });
  }

  const {
    tipo_movimento,
    descricao,
    pais_id,
    estado_id,
    cidade_id,
    data_inicial,
    data_final,
    valor,
    laudo_inicial,
    laudo_final,
  } = req.body || {};

  const query = `
    INSERT INTO public.ace_obra_movimentacao (
      cd_obra,
      tipo_movimento,
      descricao,
      pais_id,
      estado_id,
      cidade_id,
      data_inicial,
      data_final,
      valor,
      laudo_inicial,
      laudo_final
    ) VALUES (
      $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11
    )
    RETURNING *;
  `;

  const values = [
    obraId,
    tipo_movimento,
    descricao,
    pais_id,
    estado_id,
    cidade_id,
    data_inicial,
    data_final,
    valor,
    laudo_inicial,
    laudo_final,
  ];

  try {
    const result = await pool.query(query, values);
    return res.status(201).json({ dados: mapMovimentoRow(result.rows[0]) });
  } catch (err) {
    console.error('Erro ao criar movimentação:', err);
    logger.error('Erro ao criar movimentação: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao criar movimentação.' });
  }
});

// =====================
// PUT /obra/movimentacoes/:id
// Atualiza movimentação existente
// =====================
router.put('/movimentacoes/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const body = req.body || {};

  const campos = [
    'tipo_movimento',
    'descricao',
    'pais_id',
    'estado_id',
    'cidade_id',
    'data_inicial',
    'data_final',
    'valor',
    'laudo_inicial',
    'laudo_final',
  ];

  const updateFields = [];
  const updateValues = [];

  campos.forEach((campo) => {
    if (body[campo] !== undefined) {
      updateFields.push(`${campo} = $${updateValues.length + 1}`);
      updateValues.push(body[campo]);
    }
  });

  if (updateFields.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo para atualizar.' });
  }

  updateValues.push(id);

  const query = `
    UPDATE public.ace_obra_movimentacao
    SET ${updateFields.join(', ')}
    WHERE id = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(query, updateValues);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Movimentação não encontrada.' });
    }

    return res.json({ dados: mapMovimentoRow(result.rows[0]) });
  } catch (err) {
    console.error('Erro ao alterar movimentação:', err);
    logger.error('Erro ao alterar movimentação: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao alterar movimentação.' });
  }
});

// =====================
// GET /obra/buscar/:id
// =====================
router.get('/buscar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

   const query = `
    SELECT
      cd_obra,
      cd_material,
      cd_tipo_peca,
      cd_subtipo_peca,
      cd_assunto,
      cd_idioma,
      titulo,
      subtitulo,
      cd_estado_conservacao,
      data_compra,
      numero_apolice,
      valor,
      cd_estante_prateleira,
      cd_editora,
      numero_edicao,
      qtd_paginas,
      volume,
      resumo,
      observacao,
      carimbo,
      cd_autor,
      cd_autor_2,
      medida,
      conjunto,
      origem,
      data_historica,
      codigo_obra_tipo,
      posicao_obra,
      nr_carimbo,
      cd_estante_prateleira_from
    FROM public.ace_obra
    WHERE cd_obra = $1
    LIMIT 1
  `;


  try {
    const result = await pool.query(query, [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Obra não encontrada.' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao buscar obra:', err);
    logger.error('Erro ao buscar obra: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao buscar obra.' });
  }
});

// =====================
// POST /obra/cadastrar
// =====================
router.post('/cadastrar', verificarToken, async (req, res) => {
  const o = req.body;

  if (!o.titulo || !o.cd_material || !o.cd_tipo_peca || !o.cd_subtipo_peca || !o.cd_assunto) {
    return res.status(400).json({
      erro: 'Campos obrigatórios: titulo, cd_material, cd_tipo_peca, cd_subtipo_peca, cd_assunto'
    });
  }

  const query = `
    INSERT INTO public.ace_obra (
      cd_material,
      cd_tipo_peca,
      cd_subtipo_peca,
      cd_assunto,
      cd_idioma,
      titulo,
      subtitulo,
      cd_estado_conservacao,
      data_compra,
      numero_apolice,
      valor,
      cd_estante_prateleira,
      cd_editora,
      numero_edicao,
      qtd_paginas,
      volume,
      resumo,
      observacao,
      carimbo,
      cd_autor,
      cd_autor_2,
      medida,
      conjunto,
      origem,
      data_historica,
      codigo_obra_tipo,
      posicao_obra,
      nr_carimbo,
      cd_estante_prateleira_from
    ) VALUES (
      $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
      $11,$12,$13,$14,$15,$16,$17,$18,$19,$20,
      $21,$22,$23,$24,$25,$26,$27,$28
    )
    RETURNING cd_obra
  `;

  const values = [
    o.cd_material,
    o.cd_tipo_peca,
    o.cd_subtipo_peca,
    o.cd_assunto,
    o.cd_idioma || null,
    o.titulo?.toUpperCase(),
    o.subtitulo?.toUpperCase() || null,
    o.cd_estado_conservacao || null,
    o.data_compra || null,
    o.numero_apolice || null,
    o.valor || null,
    o.cd_estante_prateleira || null,
    o.cd_editora || null,
    o.numero_edicao || null,
    o.qtd_paginas || null,
    o.volume || null,
    o.resumo || null,
    o.observacao || null,
    o.carimbo || null,
    o.cd_autor || null,
    o.cd_autor_2 || null,
    o.medida || null,
    o.conjunto || null,
    o.origem || null,
    o.data_historica || null,
    o.codigo_obra_tipo || null,
    o.posicao_obra || 1,
    o.nr_carimbo || null,
    o.cd_estante_prateleira_from || null
  ];

  try {
    const result = await pool.query(query, values);

    res.status(201).json({
      mensagem: 'Obra cadastrada com sucesso!',
      cd_obra: result.rows[0].cd_obra
    });
  } catch (err) {
    logger.error('Erro ao cadastrar obra: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao cadastrar obra.' });
  }
});

// =====================
// PUT /obra/alterar/:id
// =====================
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const body = req.body;

  const camposPermitidos = [
    'cd_material',
    'cd_tipo_peca',
    'cd_subtipo_peca',
    'cd_assunto',
    'cd_idioma',
    'titulo',
    'subtitulo',
    'cd_estado_conservacao',
    'data_compra',
    'numero_apolice',
    'valor',
    'cd_estante_prateleira',
    'cd_editora',
    'numero_edicao',
    'qtd_paginas',
    'volume',
    'resumo',
    'observacao',
    'carimbo',
    'cd_autor',
    'cd_autor_2',
    'medida',
    'conjunto',
    'origem',
    'data_historica',
    'codigo_obra_tipo',
    'posicao_obra',
    'nr_carimbo',
    'cd_estante_prateleira_from'
  ];

  const updates = [];
  const values = [];

  camposPermitidos.forEach(campo => {
    if (body[campo] !== undefined) {
      updates.push(`${campo} = $${values.length + 1}`);
      values.push(
        campo === 'titulo' || campo === 'subtitulo'
          ? body[campo]?.toUpperCase()
          : body[campo]
      );
    }
  });

  if (!updates.length) {
    return res.status(400).json({ erro: 'Nenhum campo para atualizar.' });
  }

  values.push(id);

  const query = `
    UPDATE public.ace_obra
    SET ${updates.join(', ')}
    WHERE cd_obra = $${values.length}
    RETURNING *
  `;

  try {
    const result = await pool.query(query, values);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Obra não encontrada.' });
    }

    res.json({
      mensagem: 'Obra atualizada com sucesso!',
      obra: result.rows[0]
    });
  } catch (err) {
    logger.error('Erro ao alterar obra: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao alterar obra.' });
  }
});


// =======================================
// 📂 LISTAR GALERIA
// GET /obras/:cdObra/galeria
// =======================================
router.get(
  '/:cdObra/galeria',
  verificarToken,
  async (req, res) => {
    const client = await pool.connect();
    try {
      const { cdObra } = req.params;

      const result = await client.query(
        `
        SELECT
          id,
          nome,
          extensao,
          sts_principal,
          ds_imagem
        FROM ace_obra_galeria
        WHERE cd_obra = $1
        ORDER BY sts_principal DESC, id DESC
        `,
        [cdObra]
      );

      return res.json(result.rows);
    } catch (err) {
      return res.status(500).json({ erro: err.message });
    } finally {
      client.release();
    }
  }
);


 
// =======================================
router.post(  '/galeria/adicionar/:cdObra',
  verificarToken,
  upload.single('arquivo'),
  async (req, res) => {
    const client = await pool.connect();
    try {
      const { cdObra } = req.params;
      const {
        sts_principal = false,
        ds_imagem = null,
      } = req.body;

      if (!req.file) {
        return res.status(400).json({ erro: 'Arquivo não enviado' });
      }

      // 🔒 Se for capa → desmarca outras capas
      if (sts_principal === 'true' || sts_principal === '1') {
        await client.query(
          `
          UPDATE ace_obra_galeria
             SET sts_principal = false
           WHERE cd_obra = $1
          `,
          [cdObra]
        );
      }

      // 💾 Salva SOMENTE metadados
      const result = await client.query(
        `
        INSERT INTO ace_obra_galeria
          (cd_obra, nome, extensao, sts_principal, ds_imagem)
        VALUES
          ($1, $2, $3, $4, $5)
        RETURNING id, nome, extensao, sts_principal
        `,
        [
          cdObra,
          req.file.filename,
          req.file.mimetype,
          sts_principal === 'true' || sts_principal === '1',
          ds_imagem,
        ]
      );

      return res.json({
        ...result.rows[0],
        caminho: `/uploads/obras/${cdObra}/${req.file.filename}`,
      });
    } catch (err) {
      console.error('Erro upload galeria:', err);
      return res.status(500).json({
        erro: 'Erro ao salvar imagem',
        detalhe: err.message,
      });
    } finally {
      client.release();
    }
  }
);



module.exports = router;
