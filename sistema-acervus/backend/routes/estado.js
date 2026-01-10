const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

/* =========================================================
   LISTAR / BUSCAR (PAGINADO)
========================================================= */
router.get('/listar', tokenOpcional, listarEstados);
router.get('/buscar', tokenOpcional, listarEstados);

async function listarEstados(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const { q, sigla, pais_id } = req.query;

  const filtros = [];
  const valores = [];

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`
      (
        unaccent(e.nome) ILIKE unaccent($${valores.length})
        OR unaccent(e.sigla) ILIKE unaccent($${valores.length})
        OR CAST(e.id AS TEXT) ILIKE $${valores.length}
      )
    `);
  }

  if (sigla) {
    valores.push(sigla.toUpperCase());
    filtros.push(`e.sigla = $${valores.length}`);
  }

  if (pais_id) {
    valores.push(pais_id);
    filtros.push(`e.pais_id = $${valores.length}`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ger_estado e
    ${where}
  `;

  const baseQuery = `
    SELECT
      e.id,
      e.nome,
      e.sigla,
      e.pais_id,
      p.nome AS pais_nome,
      p.sigla AS pais_sigla
    FROM public.ger_estado e
    LEFT JOIN public.ger_pais p ON p.id = e.pais_id
    ${where}
    ORDER BY e.nome
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
    logger.error('Erro ao listar Estados: ' + err.stack, 'Estado');
    res.status(500).json({
      erro: 'Erro ao listar estados.',
      motivo: err.message
    });
  }
}

/* =========================================================
   LISTAR SIMPLES (POR PAÍS)
========================================================= */
router.get('/listar-por-pais/:pais_id', tokenOpcional, async (req, res) => {
  const { pais_id } = req.params;

  try {
    const sql = `
      SELECT id, nome, sigla
      FROM public.ger_estado
      WHERE pais_id = $1
      ORDER BY nome
    `;

    const result = await pool.query(sql, [pais_id]);
    res.status(200).json(result.rows);

  } catch (err) {
    logger.error('Erro ao listar estados por país: ' + err.stack, 'Estado');
    res.status(500).json({ erro: 'Erro ao listar estados.' });
  }
});

/* =========================================================
   CADASTRAR
========================================================= */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { nome, sigla, pais_id } = req.body;

  if (!nome || !pais_id) {
    return res.status(400).json({
      erro: 'Os campos "nome" e "pais_id" são obrigatórios.'
    });
  }

  try {
    // valida duplicidade (nome + país)
    const dup = await pool.query(
      `
      SELECT 1
      FROM public.ger_estado
      WHERE LOWER(nome) = LOWER($1)
        AND pais_id = $2
      LIMIT 1
      `,
      [nome.trim(), pais_id]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe um estado com esse nome para o país informado.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ger_estado (nome, sigla, pais_id)
      VALUES ($1, $2, $3)
      RETURNING id
      `,
      [
        nome.trim(),
        sigla?.trim()?.toUpperCase() || null,
        pais_id
      ]
    );

    res.status(201).json({
      message: 'Estado cadastrado com sucesso!',
      id: result.rows[0].id
    });

  } catch (err) {
    logger.error('Erro ao cadastrar Estado: ' + err.stack, 'Estado');
    res.status(500).json({ erro: 'Erro ao cadastrar estado.' });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { nome, sigla, pais_id } = req.body;

  try {
    const atual = await pool.query(
      `SELECT nome, pais_id FROM public.ger_estado WHERE id = $1`,
      [id]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({
        erro: 'Estado não encontrado.'
      });
    }

    // valida duplicidade se mudar nome ou país
    if (
      (nome && nome.trim().toLowerCase() !== atual.rows[0].nome.toLowerCase()) ||
      (pais_id && pais_id !== atual.rows[0].pais_id)
    ) {
      const dup = await pool.query(
        `
        SELECT 1
        FROM public.ger_estado
        WHERE LOWER(nome) = LOWER($1)
          AND pais_id = $2
          AND id <> $3
        `,
        [
          nome?.trim() || atual.rows[0].nome,
          pais_id || atual.rows[0].pais_id,
          id
        ]
      );

      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe um estado com esse nome para o país informado.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ger_estado
      SET
        nome = COALESCE($1, nome),
        sigla = COALESCE($2, sigla),
        pais_id = COALESCE($3, pais_id)
      WHERE id = $4
      `,
      [
        nome?.trim(),
        sigla?.trim()?.toUpperCase(),
        pais_id,
        id
      ]
    );

    res.status(200).json({
      message: 'Estado atualizado com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao alterar Estado: ' + err.stack, 'Estado');
    res.status(500).json({ erro: 'Erro ao atualizar estado.' });
  }
});

module.exports = router;
