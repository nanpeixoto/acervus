const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');

/* =========================================================
   LISTAR / BUSCAR (PAGINADO)
========================================================= */
router.get('/listar', tokenOpcional, listarEstados);
router.get('/buscar', tokenOpcional, listarEstados);

async function listarEstados(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true' ? 'A' : 'I');
    filtros.push(`sts_estado_conservacao = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`(
      unaccent(ds_estado_conservacao) ILIKE unaccent($${valores.length})
      OR CAST(cd_estado_conservacao AS TEXT) ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_estado_conservacao
    ${where}
  `;

  const baseQuery = `
    SELECT
      cd_estado_conservacao,
      ds_estado_conservacao AS descricao,
      sts_estado_conservacao
    FROM public.ace_estado_conservacao
    ${where}
    ORDER BY ds_estado_conservacao
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
      ativo: e.sts_estado_conservacao === 'A'
    }));

    res.status(200).json(resultado);

  } catch (err) {
    logger.error(
      'Erro ao listar Estados de Conservação: ' + err.stack,
      'EstadoConservacao'
    );
    res.status(500).json({
      erro: 'Erro ao listar Estados de Conservação.',
      motivo: err.message
    });
  }
}

/* =========================================================
   CADASTRAR
========================================================= */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { descricao, ativo = true } = req.body;

  if (!descricao) {
    return res.status(400).json({
      erro: 'O campo "descricao" é obrigatório.'
    });
  }

  try {
    // Verifica duplicidade
    const dup = await pool.query(
      `
      SELECT 1
      FROM public.ace_estado_conservacao
      WHERE LOWER(ds_estado_conservacao) = LOWER($1)
      LIMIT 1
      `,
      [descricao.trim()]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe um estado de conservação com essa descrição.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ace_estado_conservacao
        (ds_estado_conservacao, sts_estado_conservacao)
      VALUES ($1, $2)
      RETURNING cd_estado_conservacao
      `,
      [
        descricao.trim(),
        ativo ? 'A' : 'I'
      ]
    );

    res.status(201).json({
      message: 'Estado de conservação cadastrado com sucesso!',
      cd_estado_conservacao: result.rows[0].cd_estado_conservacao
    });

  } catch (err) {
    logger.error(
      'Erro ao cadastrar Estado de Conservação: ' + err.stack,
      'EstadoConservacao'
    );
    res.status(500).json({
      erro: 'Erro ao cadastrar Estado de Conservação.'
    });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:cd_estado_conservacao', verificarToken, async (req, res) => {
  const { cd_estado_conservacao } = req.params;
  const { descricao, ativo } = req.body;

  try {
    const atual = await pool.query(
      `
      SELECT ds_estado_conservacao
      FROM public.ace_estado_conservacao
      WHERE cd_estado_conservacao = $1
      `,
      [cd_estado_conservacao]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({
        erro: 'Estado de conservação não encontrado.'
      });
    }

    // valida duplicidade
    if (
      descricao &&
      descricao.trim().toLowerCase() !==
        atual.rows[0].ds_estado_conservacao.toLowerCase()
    ) {
      const dup = await pool.query(
        `
        SELECT 1
        FROM public.ace_estado_conservacao
        WHERE LOWER(ds_estado_conservacao) = LOWER($1)
          AND cd_estado_conservacao <> $2
        `,
        [descricao.trim(), cd_estado_conservacao]
      );

      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe um estado de conservação com essa descrição.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ace_estado_conservacao
      SET ds_estado_conservacao = COALESCE($1, ds_estado_conservacao),
          sts_estado_conservacao = COALESCE($2, sts_estado_conservacao)
      WHERE cd_estado_conservacao = $3
      `,
      [
        descricao?.trim(),
        ativo !== undefined ? (ativo ? 'A' : 'I') : null,
        cd_estado_conservacao
      ]
    );

    res.status(200).json({
      message: 'Estado de conservação atualizado com sucesso!'
    });

  } catch (err) {
    logger.error(
      'Erro ao atualizar Estado de Conservação: ' + err.stack,
      'EstadoConservacao'
    );
    res.status(500).json({
      erro: 'Erro ao atualizar Estado de Conservação.'
    });
  }
});

/* =========================================================
   EXPORTAR CSV
========================================================= */
const exportEstados = createCsvExporter({
  filename: () =>
    `estado_conservacao-${new Date().toISOString().slice(0, 10)}.csv`,
  header: ['Código', 'Descrição', 'Status'],
  baseQuery: `
    SELECT
      cd_estado_conservacao,
      ds_estado_conservacao,
      sts_estado_conservacao
    FROM public.ace_estado_conservacao
    {{WHERE}}
    ORDER BY ds_estado_conservacao
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`sts_estado_conservacao = $${i++}`);
      params.push(ativo === 'true' ? 'A' : 'I');
    }

    if (q) {
      filters.push(`unaccent(ds_estado_conservacao) ILIKE unaccent($${i++})`);
      params.push(`%${q}%`);
    }

    return {
      where: filters.length ? `WHERE ${filters.join(' AND ')}` : '',
      params
    };
  },
  rowMap: (r) => [
    r.cd_estado_conservacao,
    r.ds_estado_conservacao,
    r.sts_estado_conservacao === 'A' ? 'Ativo' : 'Inativo'
  ]
});

router.get('/exportar/csv', verificarToken, exportEstados);

module.exports = router;
