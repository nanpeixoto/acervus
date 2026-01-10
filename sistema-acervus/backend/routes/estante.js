const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

/* =========================================================
   LISTAR / BUSCAR (PAGINADO)
========================================================= */
router.get('/listar', tokenOpcional, listarEstantes);
router.get('/buscar', tokenOpcional, listarEstantes);

async function listarEstantes(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const { q, cd_sala } = req.query;

  const filtros = [];
  const valores = [];

  if (cd_sala) {
    valores.push(cd_sala);
    filtros.push(`e.cd_sala = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`
      (
        unaccent(e.descricao) ILIKE unaccent($${valores.length})
        OR CAST(e.cd_estante AS TEXT) ILIKE $${valores.length}
      )
    `);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_estante e
    ${where}
  `;

  const baseQuery = `
    SELECT
      e.cd_estante,
      e.descricao,
      e.cd_sala,
      e.pais_id,
      e.estado_id,
      e.cidade_id,
      COUNT(p.cd_estante_prateleira) AS total_prateleiras
    FROM public.ace_estante e
    LEFT JOIN public.ace_estante_prateleira p
      ON p.cd_estante = e.cd_estante
    ${where}
    GROUP BY
      e.cd_estante,
      e.descricao,
      e.cd_sala,
      e.pais_id,
      e.estado_id,
      e.cidade_id
    ORDER BY unaccent(e.descricao)
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

    // normaliza COUNT (Postgres retorna string)
    resultado.dados = resultado.dados.map(e => ({
      ...e,
      total_prateleiras: Number(e.total_prateleiras)
    }));

    res.status(200).json(resultado);

  } catch (err) {
    logger.error(
      'Erro ao listar Estantes: ' + err.stack,
      'Estante'
    );
    res.status(500).json({
      erro: 'Erro ao listar estantes.',
      motivo: err.message
    });
  }
}

/* =========================================================
   BUSCAR POR ID (COM PRATELEIRAS)
========================================================= */
router.get('/:cd_estante', tokenOpcional, async (req, res) => {
  const { cd_estante } = req.params;

  try {
    const estanteRes = await pool.query(
      `
      SELECT *
      FROM public.ace_estante
      WHERE cd_estante = $1
      `,
      [cd_estante]
    );

    if (estanteRes.rowCount === 0) {
      return res.status(404).json({ erro: 'Estante não encontrada.' });
    }

    const prateleirasRes = await pool.query(
      `
      SELECT cd_estante_prateleira, descricao_prateleira
      FROM public.ace_estante_prateleira
      WHERE cd_estante = $1
      ORDER BY cd_estante_prateleira
      `,
      [cd_estante]
    );

    res.status(200).json({
      dados: {
        ...estanteRes.rows[0],
        prateleiras: prateleirasRes.rows
      }
    });

  } catch (err) {
    logger.error(
      'Erro ao buscar Estante: ' + err.stack,
      'Estante'
    );
    res.status(500).json({ erro: 'Erro ao buscar estante.' });
  }
});

/* =========================================================
   CADASTRAR (ESTANTE + PRATELEIRAS)
========================================================= */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const {
    pais_id,
    estado_id,
    cidade_id,
    cd_sala,
    descricao,
    prateleiras = []
  } = req.body;

  if (!descricao || !cd_sala) {
    return res.status(400).json({
      erro: 'Os campos "descricao" e "cd_sala" são obrigatórios.'
    });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // duplicidade (descricao + sala)
    const dup = await client.query(
      `
      SELECT 1
      FROM public.ace_estante
      WHERE LOWER(descricao) = LOWER($1)
        AND cd_sala = $2
      LIMIT 1
      `,
      [descricao.trim(), cd_sala]
    );

    if (dup.rowCount > 0) {
      throw {
        status: 409,
        message: 'Já existe uma estante com essa descrição para a sala informada.'
      };
    }

    const estanteRes = await client.query(
      `
      INSERT INTO public.ace_estante
        (pais_id, estado_id, cidade_id, cd_sala, descricao)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING cd_estante
      `,
      [
        pais_id || null,
        estado_id || null,
        cidade_id || null,
        cd_sala,
        descricao.trim()
      ]
    );

    const cd_estante = estanteRes.rows[0].cd_estante;

    for (const p of prateleiras) {
      if (!p.descricao_prateleira) continue;

      await client.query(
        `
        INSERT INTO public.ace_estante_prateleira
          (cd_estante, descricao_prateleira)
        VALUES ($1, $2)
        `,
        [cd_estante, p.descricao_prateleira.trim()]
      );
    }

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Estante cadastrada com sucesso!',
      cd_estante
    });

  } catch (err) {
    await client.query('ROLLBACK');

    logger.error(
      'Erro ao cadastrar Estante: ' + err.stack,
      'Estante'
    );

    res.status(err.status || 500).json({
      erro: err.message || 'Erro ao cadastrar estante.'
    });
  } finally {
    client.release();
  }
});

/* =========================================================
   ALTERAR (ESTANTE + RESET PRATELEIRAS)
========================================================= */
router.put('/alterar/:cd_estante', verificarToken, async (req, res) => {
  const { cd_estante } = req.params;
  const {
    pais_id,
    estado_id,
    cidade_id,
    cd_sala,
    descricao,
    prateleiras = []
  } = req.body;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const atual = await client.query(
      `
      SELECT *
      FROM public.ace_estante
      WHERE cd_estante = $1
      `,
      [cd_estante]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({ erro: 'Estante não encontrada.' });
    }

    await client.query(
      `
      UPDATE public.ace_estante
      SET
        pais_id   = COALESCE($1, pais_id),
        estado_id = COALESCE($2, estado_id),
        cidade_id = COALESCE($3, cidade_id),
        cd_sala   = COALESCE($4, cd_sala),
        descricao = COALESCE($5, descricao)
      WHERE cd_estante = $6
      `,
      [
        pais_id,
        estado_id,
        cidade_id,
        cd_sala,
        descricao?.trim(),
        cd_estante
      ]
    );

    // remove prateleiras antigas
    await client.query(
      `DELETE FROM public.ace_estante_prateleira WHERE cd_estante = $1`,
      [cd_estante]
    );

    // recria prateleiras
    for (const p of prateleiras) {
      if (!p.descricao_prateleira) continue;

      await client.query(
        `
        INSERT INTO public.ace_estante_prateleira
          (cd_estante, descricao_prateleira)
        VALUES ($1, $2)
        `,
        [cd_estante, p.descricao_prateleira.trim()]
      );
    }

    await client.query('COMMIT');

    res.status(200).json({
      message: 'Estante atualizada com sucesso!'
    });

  } catch (err) {
    await client.query('ROLLBACK');

    logger.error(
      'Erro ao atualizar Estante: ' + err.stack,
      'Estante'
    );

    res.status(500).json({ erro: 'Erro ao atualizar estante.' });
  } finally {
    client.release();
  }
});

/* =========================================================
   EXCLUIR
========================================================= */
router.delete('/excluir/:cd_estante', verificarToken, async (req, res) => {
  const { cd_estante } = req.params;

  try {
    await pool.query(
      `DELETE FROM public.ace_estante_prateleira WHERE cd_estante = $1`,
      [cd_estante]
    );

    await pool.query(
      `DELETE FROM public.ace_estante WHERE cd_estante = $1`,
      [cd_estante]
    );

    res.status(200).json({
      message: 'Estante excluída com sucesso!'
    });

  } catch (err) {
    logger.error(
      'Erro ao excluir Estante: ' + err.stack,
      'Estante'
    );
    res.status(500).json({ erro: 'Erro ao excluir estante.' });
  }
});

module.exports = router;
