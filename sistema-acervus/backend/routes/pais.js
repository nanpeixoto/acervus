const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

/* =========================================================
   LISTAR / BUSCAR (PAGINADO)
========================================================= */
router.get('/listar', tokenOpcional, listarPaises);
router.get('/buscar', tokenOpcional, listarPaises);

async function listarPaises(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { q, sigla } = req.query;

  const filtros = [];
  const valores = [];

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`
      (
        unaccent(nome) ILIKE unaccent($${valores.length})
        OR unaccent(sigla) ILIKE unaccent($${valores.length})
        OR CAST(id AS TEXT) ILIKE $${valores.length}
      )
    `);
  }

  if (sigla) {
    valores.push(sigla.toUpperCase());
    filtros.push(`sigla = $${valores.length}`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ger_pais
    ${where}
  `;

  const baseQuery = `
    SELECT
      id,
      nome,
      sigla
    FROM public.ger_pais
    ${where}
    ORDER BY nome
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

    res.status(200).json(resultado);

  } catch (err) {
    logger.error('Erro ao listar Países: ' + err.stack, 'País');
    res.status(500).json({
      erro: 'Erro ao listar países.',
      motivo: err.message
    });
  }
}

/* =========================================================
   LISTAR SIMPLES (COMBO / DROPDOWN)
========================================================= */
router.get('/listar-simples', tokenOpcional, async (req, res) => {
  try {
    const sql = `
      SELECT id, nome, sigla
      FROM public.ger_pais
      ORDER BY nome
    `;

    const result = await pool.query(sql);
    res.status(200).json(result.rows);

  } catch (err) {
    logger.error('Erro ao listar países simples: ' + err.stack, 'País');
    res.status(500).json({ erro: 'Erro ao listar países.' });
  }
});

/* =========================================================
   CADASTRAR
========================================================= */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { nome, sigla } = req.body;

  if (!nome) {
    return res.status(400).json({
      erro: 'O campo "nome" é obrigatório.'
    });
  }

  try {
    // valida duplicidade por nome
    const dup = await pool.query(
      `
      SELECT 1
      FROM public.ger_pais
      WHERE LOWER(nome) = LOWER($1)
      LIMIT 1
      `,
      [nome.trim()]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe um país com esse nome.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ger_pais (nome, sigla)
      VALUES ($1, $2)
      RETURNING id
      `,
      [
        nome.trim(),
        sigla?.trim()?.toUpperCase() || null
      ]
    );

    res.status(201).json({
      message: 'País cadastrado com sucesso!',
      id: result.rows[0].id
    });

  } catch (err) {
    logger.error('Erro ao cadastrar País: ' + err.stack, 'País');
    res.status(500).json({ erro: 'Erro ao cadastrar país.' });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { nome, sigla } = req.body;

  try {
    const atual = await pool.query(
      `SELECT nome FROM public.ger_pais WHERE id = $1`,
      [id]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({
        erro: 'País não encontrado.'
      });
    }

    // valida duplicidade de nome
    if (
      nome &&
      nome.trim().toLowerCase() !== atual.rows[0].nome.toLowerCase()
    ) {
      const dup = await pool.query(
        `
        SELECT 1
        FROM public.ger_pais
        WHERE LOWER(nome) = LOWER($1)
        AND id <> $2
        `,
        [nome.trim(), id]
      );

      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe um país com esse nome.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ger_pais
      SET
        nome = COALESCE($1, nome),
        sigla = COALESCE($2, sigla)
      WHERE id = $3
      `,
      [
        nome?.trim(),
        sigla?.trim()?.toUpperCase(),
        id
      ]
    );

    res.status(200).json({
      message: 'País atualizado com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao alterar País: ' + err.stack, 'País');
    res.status(500).json({ erro: 'Erro ao atualizar país.' });
  }
});

module.exports = router;
