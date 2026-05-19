const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');
const path = require('path');
const fs = require('fs');
const puppeteer = require('puppeteer');
 
 
 
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
        OR  unaccent(lower(a.ds_assunto)) ILIKE unaccent(lower($${valores.length}))
         OR  unaccent(lower(tp.ds_tipo_peca)) ILIKE unaccent(lower($${valores.length}))
          OR  unaccent(lower(st.descricao)) ILIKE unaccent(lower($${valores.length}))
            OR  unaccent(lower(au.ds_autor)) ILIKE unaccent(lower($${valores.length}))
      `);
    }
  }

const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_obra o
    INNER JOIN ace_tipo_peca tp  ON tp.cd_tipo_peca = o.cd_tipo_peca

    INNER JOIN ace_subtipo_peca st  ON st.cd_subtipo_peca = o.cd_subtipo_peca

    INNER JOIN ace_assunto a  ON a.cd_assunto = o.cd_assunto

    INNER JOIN ace_idioma i  ON i.cd_idioma = o.cd_idioma

    INNER JOIN ace_estado_conservacao ec  ON ec.cd_estado_conservacao = o.cd_estado_conservacao

    INNER JOIN ace_autor au  ON au.cd_autor = o.cd_autor
    ${where}
  `;

  const baseQuery = `
     
      SELECT
      o.cd_obra,
      cd_material,
      o.cd_tipo_peca,
      o.cd_subtipo_peca,
      o.cd_assunto,
      o.cd_idioma,
      o.titulo,
      o.subtitulo,
      o.cd_estado_conservacao,
      o.data_compra,
      o.numero_apolice,
      o.valor,
      o.cd_estante_prateleira,
      o.cd_editora,
      o.numero_edicao,
      o.qtd_paginas,
      o.volume,
      o.resumo,
      o.observacao,
      o.carimbo,
      o.cd_autor,
      o.cd_autor_2,
      o.medida,
      o.conjunto,
      o.origem,
      o.data_historica,
      o.codigo_obra_tipo,
      posicao_obra,
      o.nr_carimbo,
      o.cd_estante_prateleira
      , a.ds_assunto AS dsAssunto
      , i.ds_idioma AS dsIdioma
      , ec.ds_estado_conservacao AS dsEstadoConservacao
      , tp.ds_tipo_peca AS dsTipoPeca
      , st.descricao AS dsSubtipoPeca
      , au.ds_autor AS dsAutor
          FROM public.ace_obra o
    INNER JOIN ace_tipo_peca tp  ON tp.cd_tipo_peca = o.cd_tipo_peca

    INNER JOIN ace_subtipo_peca st  ON st.cd_subtipo_peca = o.cd_subtipo_peca

    INNER JOIN ace_assunto a  ON a.cd_assunto = o.cd_assunto

    INNER JOIN ace_idioma i  ON i.cd_idioma = o.cd_idioma

    INNER JOIN ace_estado_conservacao ec  ON ec.cd_estado_conservacao = o.cd_estado_conservacao

    INNER JOIN ace_autor au  ON au.cd_autor = o.cd_autor
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

  try {
    const result = await pool.query(
      `
      SELECT cd_obra, nome
      FROM ace_obra_galeria
      WHERE id = $1
      `,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Imagem não encontrada.' });
    }

    const { cd_obra, nome } = result.rows[0];

    const filePath = path.join(
      __dirname,
      '..',
      'uploads',
      'obras',
      String(cd_obra),
      nome
    );

    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ erro: 'Arquivo não encontrado no disco.' });
    }

    return res.sendFile(filePath);
  } catch (err) {
    console.error('Erro ao obter arquivo da galeria:', err);
   // console.log();
    logger.error('Erro ao obter arquivo da galeria: ' + err.stack, 'obras');
    return res.status(500).json({ erro: 'Erro ao obter arquivo.', motivo: err.message });
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
    sts_principal
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
      extensao 
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
    return res.status(500).json({ erro: 'Erro ao atualizar imagem da galeria.', motivo: err.message } );
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
  o.cd_obra,
  o.cd_material,
  o.cd_tipo_peca,
  o.cd_subtipo_peca,
  o.cd_assunto,
  o.cd_idioma,
  o.titulo,
  o.subtitulo,
  o.cd_estado_conservacao,
  o.data_compra,
  o.numero_apolice,
  o.valor,
  o.cd_estante_prateleira,
  o.cd_editora,
  o.numero_edicao,
  o.qtd_paginas,
  o.volume,
  o.resumo,
  o.observacao,
  o.carimbo,
  o.cd_autor,
  a.ds_autor AS autor_nome,
  o.cd_autor_2,
  o.medida,
  o.conjunto,
  o.origem,
  o.data_historica,
  o.codigo_obra_tipo,
  o.posicao_obra,
  o.nr_carimbo,
  o.cd_estante_prateleira_from,
  e.ds_editora AS ds_editora
FROM public.ace_obra o
  LEFT JOIN public.ace_autor a ON a.cd_autor = o.cd_autor
  LEFT JOIN public.ace_editora e ON e.cd_editora = o.cd_editora
WHERE o.cd_obra = $1
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
    res.status(500).json({ erro: 'Erro ao buscar obra.' , motivo: err.message });
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
  $21,$22,$23,$24,$25,$26,$27,$28,$29
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
    res.status(500).json({ erro: 'Erro ao cadastrar obra.', motivo: err.message });
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
    res.status(500).json({ erro: 'Erro ao alterar obra.', motivo    : err.message });
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


router.get('/relatorio/ficha/:id', verificarToken, async (req, res) => {


  const { id } = req.params;

  const query = `
 SELECT
o.cd_obra,
o.titulo,
o.subtitulo,
o.carimbo,
o.numero_edicao,
o.qtd_paginas,
o.volume,
o.resumo,
o.observacao,
o.data_compra,
o.numero_apolice,
o.valor,
o.origem,
o.medida,
o.data_historica,

tp.ds_tipo_peca        AS tipo_obra,
st.descricao     AS subtipo_obra,
a.ds_assunto           AS assunto,
i.ds_idioma            AS idioma,
ec.ds_estado_conservacao AS conservacao,
ed.ds_editora          AS editora,
au.ds_autor            AS autor,

CONCAT_WS('-',
    UPPER(est.nome),
    UPPER(cid.nome),
    sal.ds_sala,
    e.descricao,
    ep.descricao_prateleira
)  as ds_localizacao,

g.nome AS imagem_capa

FROM ace_obra o

INNER JOIN ace_tipo_peca tp  ON tp.cd_tipo_peca = o.cd_tipo_peca

INNER JOIN ace_subtipo_peca st  ON st.cd_subtipo_peca = o.cd_subtipo_peca

INNER JOIN ace_assunto a  ON a.cd_assunto = o.cd_assunto

INNER JOIN ace_idioma i  ON i.cd_idioma = o.cd_idioma

INNER JOIN ace_estado_conservacao ec  ON ec.cd_estado_conservacao = o.cd_estado_conservacao

INNER JOIN ace_autor au  ON au.cd_autor = o.cd_autor

LEFT JOIN ace_editora ed  ON ed.cd_editora = o.cd_editora

INNER JOIN ace_estante_prateleira ep  ON ep.cd_estante_prateleira = o.cd_estante_prateleira

 inner join public.ace_estante  e on e.cd_estante = ep.cd_estante  
 inner join public.ger_estado est on  est.id = e.estado_id
 inner join public.ger_cidade cid on cid.id = e.cidade_id
 inner join public.ace_sala sal  on sal.cd_sala = e.cd_sala

LEFT JOIN ace_obra_galeria g
  ON g.cd_obra = o.cd_obra
  AND g.sts_principal = true

WHERE o.cd_obra = $1
LIMIT 1
`;

  try {

    const result = await pool.query(query, [id]);

    if(result.rowCount === 0){
      return res.status(404).json({erro:'Obra não encontrada'});
    }

    res.json(result.rows[0]);

  } catch(err){

    logger.error('Erro ficha obra: ' + err.stack,'obras');
    res.status(500).json({
      erro:'Erro ao gerar ficha da obra',
      motivo:err.message
    });

  }

});

router.get('/relatorio/ficha/:id/pdf', async (req, res) => {

  
  const fs = require('fs');

  const logo = fs.readFileSync('/var/www/sistema-acervus/img/logo_acervus.png');
  const logoBase64 = logo.toString('base64');


  const id = req.params.id;

  const query = `
 SELECT
    o.cd_obra,
    o.titulo,
    o.subtitulo,
    o.qtd_paginas,

    tp.ds_tipo_peca AS tipo,
    st.descricao AS subtipo,

    a.ds_assunto AS assunto,
    i.ds_idioma AS idioma,

    ec.ds_estado_conservacao AS conservacao,

    au.ds_autor AS autor,
     

    ed.ds_editora AS editora,

    trim(mat.descricao) AS material,
    o.medida ,
    o.origem,
    o.numero_edicao,
    o.volume,
    o.conjunto,
    o.resumo,
    o.observacao ,

    o.data_compra,
    o.numero_apolice,
    o.valor,

    

    CONCAT_WS(' - ',
        UPPER(est.nome),
        UPPER(cid.nome),
        sal.ds_sala,
        e.descricao,
        ep.descricao_prateleira
    ) AS localizacao, o.nr_carimbo, carimbo

FROM ace_obra o

INNER JOIN ace_tipo_peca tp ON tp.cd_tipo_peca = o.cd_tipo_peca

INNER JOIN ace_subtipo_peca st ON st.cd_subtipo_peca = o.cd_subtipo_peca

INNER JOIN ace_assunto a ON a.cd_assunto = o.cd_assunto

INNER JOIN ace_idioma i  ON i.cd_idioma = o.cd_idioma

INNER JOIN ace_estado_conservacao ec ON ec.cd_estado_conservacao = o.cd_estado_conservacao

INNER JOIN ace_autor au ON au.cd_autor = o.cd_autor

LEFT JOIN ace_editora ed ON ed.cd_editora = o.cd_editora

INNER JOIN ace_estante_prateleira ep ON ep.cd_estante_prateleira = o.cd_estante_prateleira

INNER JOIN ace_estante e ON e.cd_estante = ep.cd_estante

INNER JOIN ace_sala sal ON sal.cd_sala = e.cd_sala

INNER JOIN ger_estado est ON est.id = e.estado_id

INNER JOIN ger_cidade cid ON cid.id = e.cidade_id
 inner join public.ace_material mat ON mat.cd_material = o.cd_material

WHERE o.cd_obra = $1
`;

const result = await pool.query(query, [id]);

const obra = result.rows[0];

 const capaQuery = `
SELECT nome, extensao
FROM ace_obra_galeria
WHERE cd_obra = $1
AND sts_principal = true
LIMIT 1
`;

const capaResult = await pool.query(capaQuery, [id]);

let capaPath = '';


let capaBase64 = '';

 if (capaResult.rows.length > 0) {

  const nomeArquivo = capaResult.rows[0].nome;

  const caminho = path.join(
    __dirname,
    '..',
    'uploads',
    'obras',
    id.toString(),
    nomeArquivo
  );

  const buffer = fs.readFileSync(caminho);

  capaBase64 = `data:image/jpeg;base64,${buffer.toString('base64')}`;
}


   

  const html = `<html>
<head>
<meta charset="UTF-8">

<style>

body{
  font-family: Arial, Helvetica, sans-serif;
  margin:40px;
  font-size:12px;
}

.header{
  display:flex;
  justify-content:space-between;
  align-items:flex-start;
}
.logo img{
  height:60px;
}

.top-right{
  text-align:right;
  font-size:11px;
}

.titulo{
  text-align:center;
  margin-top:10px;
}

.titulo h1{
  margin:0;
  font-size:20px;
}

.codigo{
  color:red;
  font-weight:bold;
  font-size:16px;
  margin-top:5px;
}

.idobra{
  position:absolute;
  right:40px;
  margin-top:-20px;
  font-weight:bold;
}

.subtitulo{
  font-size:16px;
  font-weight:bold;
}

.subtitulo2{
  font-size:11px;
}

.section-title{
  margin-top:15px;
  background:#cfcfcf;
  text-align:center;
  font-weight:bold;
  padding:4px;
  border:1px solid #999;
   page-break-after:avoid;
  
}

.dados{
  display:flex;
  margin-top:10px;
}

.col1{
  width:40%;
}

.col2{
  width:30%;
}

.img{
  width:30%;
  text-align:right;
}

.img img{
  width:150px;
  height:auto;
  object-fit:contain;
  border:1px solid #999;
}

.linha{
  margin:3px 0;
}

.autor-box{
  border:1px solid #999;
  padding:6px;
}

.autor-row{
  display:flex;
  justify-content:space-between;
}

.resumo-box{
   border:1px solid #999;
  padding:6px;
  text-align:justify;
  line-height:1.4;
  page-break-inside:avoid;
}

.info-box{
  border:1px solid #999;
  padding:6px;
}

.info-row{
  display:flex;
  justify-content:space-between;
}

</style>
</head>

<body>

<div class="header">

<div class="logo">
<img src="data:image/png;base64,${logoBase64}">
</div>

<div class="top-right">
Página: 1 de 1<br>
Impressão: ${new Date().toLocaleString()}
</div>

</div>

<div class="titulo">

<h1>FICHA DA OBRA</h1>

<div class="codigo">
${obra.carimbo}
</div>

<div class="idobra">
${obra.cd_obra}
</div>

<div class="subtitulo">
${obra.titulo}
</div>

<div class="subtitulo2">
${obra.subtitulo || ''}
</div>

</div>

<div class="section-title">DADOS DA OBRA</div>

<div class="dados">

<div class="col1">

<div class="linha"><b>Tipo de Obra:</b> ${obra.tipo}</div>
<div class="linha"><b>Assunto:</b> ${obra.assunto}</div>
<div class="linha"><b>Localização:</b> ${obra.localizacao}</div>
<div class="linha"><b>Material:</b> ${obra.material || ''}</div>
<div class="linha"><b>Dimensões:</b> ${obra.medida || ''}</div>
<div class="linha"><b>Origem:</b> ${obra.origem || ''}</div>
<div class="linha"><b>Nº Edição:</b> ${obra.numero_edicao || ''}</div>
<div class="linha"><b>Volume:</b> ${obra.volume || ''}</div>
<div class="linha"><b>Conjunto:</b> ${obra.conjunto || ''}</div>

</div>

<div class="col2">

<div class="linha"><b>Subtipo de Obra:</b> ${obra.subtipo || ''}</div>
<div class="linha"><b>Idioma:</b> ${obra.idioma || ''}</div>
<div class="linha"><b>Conservação:</b> ${obra.conservacao || ''}</div>
<div class="linha"><b>Data:</b> ${obra.data_historica || ''}</div>
<div class="linha"><b>Qtd Páginas:</b> ${obra.qtd_paginas || ''}</div>

</div>

<div class="img">

<img src="${capaBase64}">

</div>

</div>

<div class="section-title">AUTOR</div>

<div class="autor-box">

<b>Autor:</b> ${obra.autor || ''}

<div class="autor-row">

<div>
<b>Data de Nascimento:</b> ${obra.data_nascimento || ''}
</div>

<div>
<b>Data de Falecimento:</b> ${obra.data_falecimento || ''}
</div>

</div>

</div>

<div class="section-title">RESUMO</div>

<div class="resumo-box">
${obra.resumo || ''}
</div>

<div class="section-title">INFORMAÇÕES COMPLEMENTARES</div>

<div class="info-box">

<div class="info-row">

<div>
<b>Data da Compra:</b> ${obra.data_compra || ''}
</div>

<div>
<b>Nº Apólice:</b> ${obra.numero_apolice || ''}
</div>

<div>
<b>Valor:</b> ${obra.valor || ''}
</div>

</div>

<div style="margin-top:6px;">
<b>Observações:</b> ${obra.observacao || ''}
</div>

</div>

</body>
</html>`;

   const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();

  await page.setContent(html, { waitUntil: 'networkidle0' });

 const pdf = await page.pdf({
  format: 'A4',
  printBackground: true,
  margin: {
    top: '20px',
    bottom: '20px',
    left: '20px',
    right: '20px'
  }
});

  await browser.close();

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', 'attachment; filename=ficha_obra.pdf');

  res.send(pdf);
});


router.get('/filtros', async (req, res) => {
  try {

    const [
      tipos,
      subtipos,
      assuntos,
      idiomas,
      materiais,
      localizacoes,
      estados,
      editoras
    ] = await Promise.all([
      pool.query('SELECT cd_tipo_peca id, ds_tipo_peca descricao FROM ace_tipo_peca ORDER BY ds_tipo_peca'),
      pool.query('SELECT cd_subtipo_peca id, descricao FROM ace_subtipo_peca ORDER BY descricao'),
      pool.query('SELECT  cd_assunto id, ds_assunto descricao FROM ace_assunto ORDER BY ds_assunto'),
      pool.query('SELECT cd_idioma id, ds_idioma descricao FROM ace_idioma ORDER BY descricao'),
      pool.query('SELECT  cd_material id,  descricao FROM ace_material ORDER BY descricao'),
      pool.query(`
              SELECT 
                  cd_estante_prateleira id,
                  CONCAT_WS(
                      ' - ',
                      UPPER(est.nome),
                      UPPER(cid.nome),
                      sal.ds_sala,
                      e.descricao,
                      ep.descricao_prateleira
                  ) AS descricao
              FROM ace_estante_prateleira ep
              INNER JOIN ace_estante e 
                  ON e.cd_estante = ep.cd_estante
              INNER JOIN ace_sala sal 
                  ON sal.cd_sala = e.cd_sala
              INNER JOIN ger_estado est 
                  ON est.id = e.estado_id
              INNER JOIN ger_cidade cid 
                  ON cid.id = e.cidade_id
              ORDER BY  CONCAT_WS(
                      ' - ',
                      UPPER(est.nome),
                      UPPER(cid.nome),
                      sal.ds_sala,
                      e.descricao,
                      ep.descricao_prateleira
                  )
              `),
      pool.query('SELECT cd_estado_conservacao id, ds_estado_conservacao descricao FROM ace_estado_conservacao ORDER BY descricao'),
      pool.query('SELECT cd_editora id, ds_editora descricao FROM ace_editora ORDER BY descricao')
    ]);

    res.json({
      tipos: tipos.rows,
      subtipos: subtipos.rows,
      assuntos: assuntos.rows,
      idiomas: idiomas.rows,
      materiais: materiais.rows,
      localizacoes: localizacoes.rows,
      estados: estados.rows,
      editoras: editoras.rows
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ erro: 'Erro ao carregar filtros' });
  }
});



function gerarListaObrasHTML(obras) {

return `
<html>

<head>

<style>

body{
    font-family: Arial, Helvetica, sans-serif;
    font-size:9px;
    color:#222;
    margin:15px;
}

.container{
    display:grid;
    grid-template-columns:1fr 1fr;
    gap:10px;
}

.card{
    border:1px solid #cfcfcf;
    border-radius:8px;
    padding:10px;
    height:135px;
    break-inside: avoid;
    page-break-inside: avoid;
    background:#fff;
    box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

/* =========================
   TOPO
========================= */

.topo{
    display:flex;
    justify-content:space-between;
    align-items:flex-start;
    margin-bottom:4px;
}

.codigo{
    font-size:8px;
    color:#888;
}

.carimbo{
    font-size:10px;
    font-weight:600;
    color:#777;
    letter-spacing:0.5px;
}

/* =========================
   TÍTULO
========================= */

.titulo{
    text-align:center;
    font-weight:bold;
    font-size:12px;
    color:#111;
    line-height:1.1;
    margin-top:2px;
}

.autor{
    text-align:center;
    font-size:9px;
    font-weight:bold;
    color:#444;
    margin-top:2px;
}

.subtitulo{
    text-align:center;
    font-size:7px;
    color:#666;
    margin-top:1px;
    margin-bottom:4px;
    font-style:italic;
}

/* =========================
   DADOS
========================= */

.dados{
    background:#f2f2f2;
    text-align:center;
    font-weight:bold;
    padding:4px;
    margin-bottom:6px;
    border-radius:4px;
    color:#333;
}

.linha{
    position:relative;
    min-height:68px;
}

.info{
    padding-right:60px;
    font-size:8px;
    line-height:1.35;
}

.info div{
    margin-bottom:1px;
}

.info b{
    color:#111;
}

/* =========================
   IMAGEM
========================= */

.galeria{
    position:absolute;
    top:0;
    right:0;

    width:48px;
    height:64px;

    border:1px solid #ddd;
    border-radius:4px;
    overflow:hidden;
    background:#fafafa;
}

.galeria img{
    width:100%;
    height:100%;
    object-fit:cover;
}

.localizacao{
    line-height:1.2;
    max-height:20px;
    overflow:hidden;
}

</style>

</head>

<body>

<div class="container">

${obras.map(o => `

<div class="card">

    <div class="topo">

        <div class="carimbo">
            ${o.carimbo ?? ''}
        </div>

        <div class="codigo">
            ${o.cd_obra ?? ''}
        </div>

    </div>

    <div class="titulo">
        ${o.titulo ?? '(SEM TÍTULO)'}
    </div>

    <div class="autor">
        ${o.autor ?? ''}
    </div>

    <div class="subtitulo">
        ${o.subtitulo ?? ''}
    </div>

    <div class="dados">
        DADOS DA OBRA
    </div>

    <div class="linha">

        <div class="info">

            <div><b>Tipo:</b> ${o.tipo ?? ''}</div>

            <div><b>Subtipo:</b> ${o.subtipo ?? ''}</div>

            <div><b>Assunto:</b> ${o.assunto ?? ''}</div>

<div class="localizacao">
    <b>Localização:</b> ${o.localizacao ?? ''}
</div>
            <div><b>Editora:</b> ${o.editora ?? ''}</div>

        </div>

        <div class="galeria">

            ${o.imagem
            ? `<img src="${o.imagem}"/>`
            : ''}

        </div>

    </div>

</div>

`).join('')}

</div>

</body>
</html>
`;
}

 async function buscarObras(filtros) {

  console.time("TEMPO TOTAL buscarObras");

  const fs = require('fs');
  const path = require('path');

  const valores = [];
  const where = [];

  console.time("MONTAGEM FILTROS");

  if (filtros.titulo) {
  valores.push(`%${filtros.titulo}%`);
  const idx = valores.length;

  where.push(`
    (
      unaccent(LOWER(o.titulo)) LIKE unaccent(LOWER($${idx}))
      OR unaccent(LOWER(o.subtitulo)) LIKE unaccent(LOWER($${idx}))
      OR unaccent(LOWER(au.ds_autor)) LIKE unaccent(LOWER($${idx}))
      OR unaccent(LOWER(ed.ds_editora)) LIKE unaccent(LOWER($${idx}))
      OR unaccent(LOWER(a.ds_assunto)) LIKE unaccent(LOWER($${idx}))
    )
  `);
}

  if (filtros.autor) {
    valores.push(filtros.autor);
    where.push(`o.cd_autor = $${valores.length}`);
  }

  if (filtros.material) {
    valores.push(filtros.material);
    where.push(`o.cd_material = $${valores.length}`);
  }

  if (filtros.tipo) {
    valores.push(filtros.tipo);
    where.push(`o.cd_tipo_peca = $${valores.length}`);
  }

  if (filtros.subtipo) {
    valores.push(filtros.subtipo);
    where.push(`o.cd_subtipo_peca = $${valores.length}`);
  }

  if (filtros.editora) {
    valores.push(filtros.editora);
    where.push(`o.cd_editora = $${valores.length}`);
  }

  if (filtros.conservacao) {
    valores.push(filtros.conservacao);
    where.push(`o.cd_estado_conservacao = $${valores.length}`);
  }

  if (filtros.localizacao) {
    valores.push(filtros.localizacao);
    where.push(`o.cd_estante_prateleira = $${valores.length}`);
  }

  if (filtros.assunto) {
    valores.push(filtros.assunto);
    where.push(`o.cd_assunto = $${valores.length}`);
  }

  if (filtros.idioma) {
    valores.push(filtros.idioma);
    where.push(`o.cd_idioma = $${valores.length}`);
  }

  console.timeEnd("MONTAGEM FILTROS");

  console.time("MONTAGEM QUERY");

  let query = `

SELECT
    o.cd_obra,
    o.titulo,
    o.subtitulo,
    o.qtd_paginas,

    tp.ds_tipo_peca AS tipo,
    st.descricao AS subtipo,

    a.ds_assunto AS assunto,
    i.ds_idioma AS idioma,

    ec.ds_estado_conservacao AS conservacao,

    au.ds_autor AS autor,
    ed.ds_editora AS editora,

    trim(mat.descricao) AS material,
    o.medida,
    o.origem,
    o.numero_edicao,
    o.volume,
    o.conjunto,
    o.resumo,
    o.observacao,

    o.data_compra,
    o.numero_apolice,
    o.valor,

    CONCAT_WS(' - ',
        UPPER(est.nome),
        UPPER(cid.nome),
        sal.ds_sala,
        e.descricao,
        ep.descricao_prateleira
    ) AS localizacao,

    o.nr_carimbo,
    o.carimbo,

    gal.nome AS imagem_nome

FROM ace_obra o

INNER JOIN ace_tipo_peca tp ON tp.cd_tipo_peca = o.cd_tipo_peca
INNER JOIN ace_subtipo_peca st ON st.cd_subtipo_peca = o.cd_subtipo_peca
INNER JOIN ace_assunto a ON a.cd_assunto = o.cd_assunto
INNER JOIN ace_idioma i ON i.cd_idioma = o.cd_idioma
INNER JOIN ace_estado_conservacao ec ON ec.cd_estado_conservacao = o.cd_estado_conservacao
INNER JOIN ace_autor au ON au.cd_autor = o.cd_autor
LEFT JOIN ace_editora ed ON ed.cd_editora = o.cd_editora
INNER JOIN ace_estante_prateleira ep ON ep.cd_estante_prateleira = o.cd_estante_prateleira
INNER JOIN ace_estante e ON e.cd_estante = ep.cd_estante
INNER JOIN ace_sala sal ON sal.cd_sala = e.cd_sala
INNER JOIN ger_estado est ON est.id = e.estado_id
INNER JOIN ger_cidade cid ON cid.id = e.cidade_id
INNER JOIN ace_material mat ON mat.cd_material = o.cd_material

LEFT JOIN LATERAL (
    SELECT nome
    FROM ace_obra_galeria
    WHERE cd_obra = o.cd_obra
    AND sts_principal = true
    LIMIT 1
) gal ON true
`;

  if (where.length > 0) {
    query += ` WHERE ` + where.join(" AND ");
  }

  query += ` ORDER BY o.titulo`;

  //impirmit query 
  console.log("QUERY MONTADA:", query);
  console.log("VALORES:", valores);

  console.timeEnd("MONTAGEM QUERY");

  console.time("EXECUÇÃO QUERY BANCO");

  const result = await pool.query(query, valores);
  //qtd de registros
  const totalRegistros = result.rowCount;
      console.log ("REGISTROS ENCONTRADOS:", totalRegistros);

  console.timeEnd("EXECUÇÃO QUERY BANCO");

  const obras = result.rows;

  console.log("TOTAL OBRAS:", obras.length);

  console.time("CARREGAMENTO IMAGENS");

  let contadorImagens = 0;

  for (const obra of obras) {

    if (obra.imagem_nome) {

      const caminho = path.join(
        __dirname,
        '..',
        'uploads',
        'obras',
        obra.cd_obra.toString(),
        obra.imagem_nome
      );

      if (fs.existsSync(caminho)) {

        const buffer = fs.readFileSync(caminho);

        obra.imagem = `data:image/jpeg;base64,${buffer.toString('base64')}`;

        contadorImagens++;
      }

    }

  }

  console.timeEnd("CARREGAMENTO IMAGENS");

  console.log("IMAGENS CARREGADAS:", contadorImagens);

  console.timeEnd("TEMPO TOTAL buscarObras");

  return obras;

}
 

async function gerarPDF(html) {

  const browser = await puppeteer.launch({
    headless: "new",
    args: ['--no-sandbox']
  });

  const page = await browser.newPage();

  await page.setContent(html, { waitUntil: 'networkidle0' });

  const pdf = await page.pdf({
  format: 'A4',
  landscape: false,
  printBackground: true,
  margin: {
    top: '10mm',
    right: '10mm',
    bottom: '10mm',
    left: '10mm'
  }
});

  await browser.close();

  return pdf;
}


  

router.post('/relatorio/lista-resumida', async (req, res) => {

  const obras = await buscarObras(req.body);

  const html = gerarListaObrasHTML(obras);

  const pdf = await gerarPDF(html);

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition','attachment; filename=lista_obras.pdf');

  res.send(pdf);

});

function montarFiltrosObra(filtros) {
  const valores = [];
  const where = [];

  if (filtros.titulo) {
    valores.push(`%${filtros.titulo}%`);
    const idx = valores.length;

    where.push(`
      (
        unaccent(LOWER(o.titulo)) LIKE unaccent(LOWER($${idx}))
        OR unaccent(LOWER(o.subtitulo)) LIKE unaccent(LOWER($${idx}))
        OR unaccent(LOWER(au.ds_autor)) LIKE unaccent(LOWER($${idx}))
        OR unaccent(LOWER(ed.ds_editora)) LIKE unaccent(LOWER($${idx}))
        OR unaccent(LOWER(a.ds_assunto)) LIKE unaccent(LOWER($${idx}))
      )
    `);
  }

  if (filtros.autor) {
    valores.push(filtros.autor);
    where.push(`o.cd_autor = $${valores.length}`);
  }

  if (filtros.material) {
    valores.push(filtros.material);
    where.push(`o.cd_material = $${valores.length}`);
  }

  if (filtros.tipo) {
    valores.push(filtros.tipo);
    where.push(`o.cd_tipo_peca = $${valores.length}`);
  }

  if (filtros.subtipo) {
    valores.push(filtros.subtipo);
    where.push(`o.cd_subtipo_peca = $${valores.length}`);
  }

  if (filtros.editora) {
    valores.push(filtros.editora);
    where.push(`o.cd_editora = $${valores.length}`);
  }

  if (filtros.conservacao) {
    valores.push(filtros.conservacao);
    where.push(`o.cd_estado_conservacao = $${valores.length}`);
  }

  if (filtros.localizacao) {
    valores.push(filtros.localizacao);
    where.push(`o.cd_estante_prateleira = $${valores.length}`);
  }

  if (filtros.assunto) {
    valores.push(filtros.assunto);
    where.push(`o.cd_assunto = $${valores.length}`);
  }

  if (filtros.idioma) {
    valores.push(filtros.idioma);
    where.push(`o.cd_idioma = $${valores.length}`);
  }

  return { valores, where };
}


function getBaseQuery(whereClause) {
  return `
    SELECT
      o.cd_obra,
      o.titulo,
      o.subtitulo,
      au.ds_autor AS autor,
      ed.ds_editora AS editora,
      a.ds_assunto AS assunto,
      tp.ds_tipo_peca AS tipo,
      st.descricao AS subtipo,

      gal.nome AS imagem_nome

    FROM ace_obra o

    INNER JOIN ace_tipo_peca tp ON tp.cd_tipo_peca = o.cd_tipo_peca
    INNER JOIN ace_subtipo_peca st ON st.cd_subtipo_peca = o.cd_subtipo_peca
    INNER JOIN ace_assunto a ON a.cd_assunto = o.cd_assunto
    INNER JOIN ace_autor au ON au.cd_autor = o.cd_autor
    LEFT JOIN ace_editora ed ON ed.cd_editora = o.cd_editora

    LEFT JOIN LATERAL (
      SELECT nome
      FROM ace_obra_galeria
      WHERE cd_obra = o.cd_obra
      AND sts_principal = true
      LIMIT 1
    ) gal ON true

    ${whereClause}
  `;
}

router.post('/buscar', async (req, res) => {
  try {
    const { valores, where } = montarFiltrosObra(req.body);

    const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

    const query = getBaseQuery(whereSql) + ` ORDER BY o.titulo`;

    const result = await pool.query(query, valores);

    const lista = result.rows.map(o => ({
      ...o,
      capa_url: o.imagem_nome
        ? `/uploads/obras/${o.cd_obra}/${o.imagem_nome}`
        : null
    }));

    res.json(lista);

  } catch (err) {
    res.status(500).json({ erro: err.message });
  }
});



module.exports = router;
