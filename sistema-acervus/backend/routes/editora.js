const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

/* =========================================================
   LISTAR / BUSCAR (PAGINADO)
========================================================= */
router.get('/listar', tokenOpcional, listarEditoras);
router.get('/buscar', tokenOpcional, listarEditoras);

async function listarEditoras(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const {
    q,
    ativo,
    pais_id,
    estado_id,
    cidade_id
  } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true' ? 'A' : 'I');
    filtros.push(`e.sts_editora = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`
      (
        unaccent(e.ds_editora) ILIKE unaccent($${valores.length})
        OR CAST(e.cd_editora AS TEXT) ILIKE $${valores.length}
      )
    `);
  }

  if (pais_id) {
    valores.push(pais_id);
    filtros.push(`e.pais_id = $${valores.length}`);
  }

  if (estado_id) {
    valores.push(estado_id);
    filtros.push(`e.estado_id = $${valores.length}`);
  }

  if (cidade_id) {
    valores.push(cidade_id);
    filtros.push(`e.cidade_id = $${valores.length}`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_editora e
    ${where}
  `;

  const baseQuery = `
    SELECT
      e.cd_editora,
      e.ds_editora,
      e.sts_editora,
      e.pais_id,
      p.nome   AS pais_nome,
      e.estado_id,
      s.nome   AS estado_nome,
      s.sigla  AS estado_sigla,
      e.cidade_id,
      c.nome   AS cidade_nome
    FROM public.ace_editora e
    LEFT JOIN public.ger_pais   p ON p.id = e.pais_id
    LEFT JOIN public.ger_estado s ON s.id = e.estado_id
    LEFT JOIN public.ger_cidade c ON c.id = e.cidade_id
    ${where}
    ORDER BY e.ds_editora
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

    // converte status A/I → boolean
    resultado.dados = resultado.dados.map(e => ({
      ...e,
      ativo: e.sts_editora === 'A'
    }));

    res.status(200).json(resultado);

  } catch (err) {
    logger.error('Erro ao listar Editoras: ' + err.stack, 'Editora');
    res.status(500).json({
      erro: 'Erro ao listar editoras.',
      motivo: err.message
    });
  }
}

/* =========================================================
   CADASTRAR
========================================================= */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const {
    descricao,
    pais_id,
    estado_id,
    cidade_id,
    ativo = true
  } = req.body;

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
      FROM public.ace_editora
      WHERE LOWER(ds_editora) = LOWER($1)
      LIMIT 1
      `,
      [descricao.trim()]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe uma editora com essa descrição.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ace_editora (
        ds_editora,
        sts_editora,
        pais_id,
        estado_id,
        cidade_id
      )
      VALUES ($1, $2, $3, $4, $5)
      RETURNING cd_editora
      `,
      [
        descricao.trim(),
        ativo ? 'A' : 'I',
        pais_id || null,
        estado_id || null,
        cidade_id || null
      ]
    );

    res.status(201).json({
      message: 'Editora cadastrada com sucesso!',
      cd_editora: result.rows[0].cd_editora
    });

  } catch (err) {
    logger.error('Erro ao cadastrar Editora: ' + err.stack, 'Editora');
    res.status(500).json({
      erro: 'Erro ao cadastrar editora.'
    });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:cd_editora', verificarToken, async (req, res) => {
  const { cd_editora } = req.params;

  const {
    descricao,
    pais_id,
    estado_id,
    cidade_id,
    ativo
  } = req.body;

  try {
    const atual = await pool.query(
      `
      SELECT ds_editora
      FROM public.ace_editora
      WHERE cd_editora = $1
      `,
      [cd_editora]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({
        erro: 'Editora não encontrada.'
      });
    }

    // valida duplicidade se mudar descrição
    if (
      descricao &&
      descricao.trim().toLowerCase() !== atual.rows[0].ds_editora.toLowerCase()
    ) {
      const dup = await pool.query(
        `
        SELECT 1
        FROM public.ace_editora
        WHERE LOWER(ds_editora) = LOWER($1)
          AND cd_editora <> $2
        `,
        [descricao.trim(), cd_editora]
      );

      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe uma editora com essa descrição.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ace_editora
      SET
        ds_editora = COALESCE($1, ds_editora),
        pais_id    = COALESCE($2, pais_id),
        estado_id  = COALESCE($3, estado_id),
        cidade_id  = COALESCE($4, cidade_id),
        sts_editora = COALESCE($5, sts_editora)
      WHERE cd_editora = $6
      `,
      [
        descricao?.trim(),
        pais_id,
        estado_id,
        cidade_id,
        ativo !== undefined ? (ativo ? 'A' : 'I') : null,
        cd_editora
      ]
    );

    res.status(200).json({
      message: 'Editora atualizada com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao alterar Editora: ' + err.stack, 'Editora');
    res.status(500).json({
      erro: 'Erro ao atualizar editora.'
    });
  }
});

module.exports = router;
