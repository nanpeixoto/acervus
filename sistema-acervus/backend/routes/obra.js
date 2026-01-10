const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

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
      o.cd_obra AS id,
      o.titulo,
      o.subtitulo
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
    res.status(500).json({ erro: 'Erro ao listar obras.' });
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
      rotacao,
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
router.post('/galeria/adicionar/:obraId', verificarToken, async (req, res) => {
  const obraId = parseInt(req.params.obraId, 10);
  if (!obraId) {
    return res.status(400).json({ erro: 'Obra inválida.' });
  }

  const {
    nome,
    ds_imagem,
    extensao,
    imagem_base64,
    sts_principal,
  } = req.body || {};

  if (!imagem_base64 || typeof imagem_base64 !== 'string') {
    return res.status(400).json({ erro: 'Imagem (base64) é obrigatória.' });
  }

  const buffer = decodeBase64(imagem_base64);
  if (!buffer) {
    return res.status(400).json({ erro: 'Falha ao decodificar imagem.' });
  }

  const insertQuery = `
    INSERT INTO public.ace_obra_galeria
      (cd_obra, ds_imagem, sts_principal, nome, extensao, imagem, rotacao)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING
      id,
      cd_obra,
      ds_imagem,
      sts_principal,
      nome,
      extensao,
      rotacao,
      CASE WHEN imagem IS NOT NULL THEN encode(imagem, 'base64') END AS imagem_base64
  `;

  const params = [
    obraId,
    ds_imagem || null,
    sts_principal === true,
    nome || null,
    extensao || null,
    buffer,
    0,
  ];

  try {
    const result = await pool.query(insertQuery, params);
    const row = result.rows[0];
    return res.status(201).json({ dados: row });
  } catch (err) {
    console.error('Erro ao salvar imagem da galeria:', err);
    logger.error('Erro ao salvar imagem da galeria: ' + err.stack, 'obras');
    return res.status(500).json({ erro: 'Erro ao salvar imagem da galeria.' });
  }
});

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
      rotacao,
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
      cd_obra AS id,
      titulo,
      subtitulo,
      cd_assunto,
      cd_material,
      cd_autor,
      valor,
      data_compra
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
  const {
    titulo,
    subtitulo,
    cd_assunto,
    cd_material,
    cd_autor,
    valor,
    data_compra
  } = req.body;

  if (!titulo) {
    return res.status(400).json({ erro: 'Título é obrigatório.' });
  }

  const query = `
    INSERT INTO public.ace_obra (
      titulo,
      subtitulo,
      cd_assunto,
      cd_material,
      cd_autor,
      valor,
      data_compra
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7
    )
    RETURNING cd_obra;
  `;

  const values = [
    titulo.toUpperCase(),
    subtitulo?.toUpperCase() || null,
    cd_assunto || null,
    cd_material || null,
    cd_autor || null,
    valor || null,
    data_compra || null
  ];

  try {
    const result = await pool.query(query, values);

    res.status(201).json({
      mensagem: 'Obra cadastrada com sucesso!',
      cd_obra: result.rows[0].cd_obra
    });
  } catch (err) {
    console.error('Erro ao cadastrar obra:', err);
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

  const campos = [
    'titulo',
    'subtitulo',
    'cd_assunto',
    'cd_material',
    'cd_autor',
    'valor',
    'data_compra'
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
    UPDATE public.ace_obra
    SET ${updateFields.join(', ')}
    WHERE cd_obra = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(query, updateValues);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Obra não encontrada.' });
    }

    res.json({
      mensagem: 'Obra alterada com sucesso!',
      obra: result.rows[0]
    });
  } catch (err) {
    console.error('Erro ao alterar obra:', err);
    logger.error('Erro ao alterar obra: ' + err.stack, 'obras');
    res.status(500).json({ erro: 'Erro ao alterar obra.' });
  }
});

module.exports = router;
