const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

/* =========================================================
   LISTAR / BUSCAR (PAGINADO)
========================================================= */
router.get('/listar', tokenOpcional, listarSalas);
router.get('/buscar', tokenOpcional, listarSalas);

async function listarSalas(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const { q, ativo } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true' ? 'A' : 'I');
    filtros.push(`s.sts_sala = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`
      (
        unaccent(s.ds_sala) ILIKE unaccent($${valores.length})
        OR CAST(s.cd_sala AS TEXT) ILIKE $${valores.length}
      )
    `);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_sala s
    ${where}
  `;

  const baseQuery = `
    SELECT
      s.cd_sala,
      s.ds_sala,
      s.sts_sala,
      s.observacao
    FROM public.ace_sala s
    ${where}
    ORDER BY s.ds_sala
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

    // converte sts_sala A/I -> boolean
    resultado.dados = resultado.dados.map(s => ({
      ...s,
      ativo: s.sts_sala === 'A'
    }));

    res.status(200).json(resultado);

  } catch (err) {
    logger.error('Erro ao listar Salas: ' + err.stack, 'Sala');
    res.status(500).json({
      erro: 'Erro ao listar salas.',
      motivo: err.message
    });
  }
}

/* =========================================================
   BUSCAR POR ID
========================================================= */
router.get('/:cd_sala', tokenOpcional, async (req, res) => {
  const { cd_sala } = req.params;

  try {
    const result = await pool.query(
      `
      SELECT
        cd_sala,
        ds_sala,
        sts_sala,
        observacao
      FROM public.ace_sala
      WHERE cd_sala = $1
      `,
      [cd_sala]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        erro: 'Sala não encontrada.'
      });
    }

    const sala = result.rows[0];

    res.status(200).json({
      dados: {
        ...sala,
        ativo: sala.sts_sala === 'A'
      }
    });

  } catch (err) {
    logger.error('Erro ao buscar Sala: ' + err.stack, 'Sala');
    res.status(500).json({ erro: 'Erro ao buscar sala.' });
  }
});

/* =========================================================
   CADASTRAR
========================================================= */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { descricao, observacao, ativo = true } = req.body;

  if (!descricao) {
    return res.status(400).json({
      erro: 'O campo "descricao" é obrigatório.'
    });
  }

  try {
    // valida duplicidade
    const dup = await pool.query(
      `
      SELECT 1
      FROM public.ace_sala
      WHERE LOWER(ds_sala) = LOWER($1)
      LIMIT 1
      `,
      [descricao.trim()]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe uma sala com essa descrição.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ace_sala (
        ds_sala,
        sts_sala,
        observacao
      )
      VALUES ($1, $2, $3)
      RETURNING cd_sala
      `,
      [
        descricao.trim(),
        ativo ? 'A' : 'I',
        observacao?.trim() || null
      ]
    );

    res.status(201).json({
      message: 'Sala cadastrada com sucesso!',
      cd_sala: result.rows[0].cd_sala
    });

  } catch (err) {
    logger.error('Erro ao cadastrar Sala: ' + err.stack, 'Sala');
    res.status(500).json({ erro: 'Erro ao cadastrar sala.' });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:cd_sala', verificarToken, async (req, res) => {
  const { cd_sala } = req.params;
  const { descricao, observacao, ativo } = req.body;

  try {
    const atual = await pool.query(
      `
      SELECT ds_sala
      FROM public.ace_sala
      WHERE cd_sala = $1
      `,
      [cd_sala]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({
        erro: 'Sala não encontrada.'
      });
    }

    // valida duplicidade
    if (
      descricao &&
      descricao.trim().toLowerCase() !== atual.rows[0].ds_sala.toLowerCase()
    ) {
      const dup = await pool.query(
        `
        SELECT 1
        FROM public.ace_sala
        WHERE LOWER(ds_sala) = LOWER($1)
          AND cd_sala <> $2
        `,
        [descricao.trim(), cd_sala]
      );

      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe uma sala com essa descrição.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ace_sala
      SET
        ds_sala   = COALESCE($1, ds_sala),
        observacao = COALESCE($2, observacao),
        sts_sala  = COALESCE($3, sts_sala)
      WHERE cd_sala = $4
      `,
      [
        descricao?.trim(),
        observacao?.trim(),
        ativo !== undefined ? (ativo ? 'A' : 'I') : null,
        cd_sala
      ]
    );

    res.status(200).json({
      message: 'Sala atualizada com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao atualizar Sala: ' + err.stack, 'Sala');
    res.status(500).json({ erro: 'Erro ao atualizar sala.' });
  }
});

/* =========================================================
   EXCLUIR (opcional)
========================================================= */
router.delete('/excluir/:cd_sala', verificarToken, async (req, res) => {
  const { cd_sala } = req.params;

  try {
    await pool.query(
      `DELETE FROM public.ace_sala WHERE cd_sala = $1`,
      [cd_sala]
    );

    res.status(200).json({
      message: 'Sala excluída com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao excluir Sala: ' + err.stack, 'Sala');
    res.status(500).json({ erro: 'Erro ao excluir sala.' });
  }
});

module.exports = router;
