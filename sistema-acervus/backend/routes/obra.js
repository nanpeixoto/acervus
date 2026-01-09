const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

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
