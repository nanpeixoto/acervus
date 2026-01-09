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
router.get('/listar', tokenOpcional, listarTipos);
router.get('/buscar', tokenOpcional, listarTipos);

async function listarTipos(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true' ? 'A' : 'I');
    filtros.push(`sts_tipo_peca = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`(
      unaccent(ds_tipo_peca) ILIKE unaccent($${valores.length})
      OR CAST(cd_tipo_peca AS TEXT) ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_tipo_peca
    ${where}
  `;

  const baseQuery = `
    SELECT
      cd_tipo_peca,
      ds_tipo_peca AS descricao,
      sts_tipo_peca
    FROM public.ace_tipo_peca
    ${where}
    ORDER BY ds_tipo_peca
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

    resultado.dados = resultado.dados.map(t => ({
      ...t,
      ativo: t.sts_tipo_peca === 'A'
    }));

    res.status(200).json(resultado);

  } catch (err) {
    logger.error('Erro ao listar Tipos de Obra: ' + err.stack, 'TipoObra');
    res.status(500).json({
      erro: 'Erro ao listar Tipos de Obra.',
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
    return res.status(400).json({ erro: 'O campo "descricao" é obrigatório.' });
  }

  try {
    const dup = await pool.query(
      `
      SELECT 1 FROM public.ace_tipo_peca
      WHERE LOWER(ds_tipo_peca) = LOWER($1)
      LIMIT 1
      `,
      [descricao.trim()]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe um tipo de obra com essa descrição.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ace_tipo_peca
        (ds_tipo_peca, sts_tipo_peca)
      VALUES ($1, $2)
      RETURNING cd_tipo_peca
      `,
      [
        descricao.trim(),
        ativo ? 'A' : 'I'
      ]
    );

    res.status(201).json({
      message: 'Tipo de Obra cadastrado com sucesso!',
      cd_tipo_peca: result.rows[0].cd_tipo_peca
    });

  } catch (err) {
    logger.error('Erro ao cadastrar Tipo de Obra: ' + err.stack, 'TipoObra');
    res.status(500).json({ erro: 'Erro ao cadastrar Tipo de Obra.' });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:cd_tipo_peca', verificarToken, async (req, res) => {
  const { cd_tipo_peca } = req.params;
  const { descricao, ativo } = req.body;

  try {
    const atual = await pool.query(
      `
      SELECT ds_tipo_peca
      FROM public.ace_tipo_peca
      WHERE cd_tipo_peca = $1
      `,
      [cd_tipo_peca]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({ erro: 'Tipo de Obra não encontrado.' });
    }

    if (
      descricao &&
      descricao.trim().toLowerCase() !== atual.rows[0].ds_tipo_peca.toLowerCase()
    ) {
      const dup = await pool.query(
        `
        SELECT 1 FROM public.ace_tipo_peca
        WHERE LOWER(ds_tipo_peca) = LOWER($1)
        AND cd_tipo_peca <> $2
        `,
        [descricao.trim(), cd_tipo_peca]
      );

      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe um tipo de obra com essa descrição.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ace_tipo_peca
      SET ds_tipo_peca = COALESCE($1, ds_tipo_peca),
          sts_tipo_peca = COALESCE($2, sts_tipo_peca)
      WHERE cd_tipo_peca = $3
      `,
      [
        descricao?.trim(),
        ativo !== undefined ? (ativo ? 'A' : 'I') : null,
        cd_tipo_peca
      ]
    );

    res.status(200).json({
      message: 'Tipo de Obra atualizado com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao atualizar Tipo de Obra: ' + err.stack, 'TipoObra');
    res.status(500).json({ erro: 'Erro ao atualizar Tipo de Obra.' });
  }
});

/* =========================================================
   EXPORTAR CSV
========================================================= */
const exportTipos = createCsvExporter({
  filename: () => `tipos-obra-${new Date().toISOString().slice(0, 10)}.csv`,
  header: ['Código', 'Descrição', 'Status'],
  baseQuery: `
    SELECT
      cd_tipo_peca,
      ds_tipo_peca,
      sts_tipo_peca
    FROM public.ace_tipo_peca
    {{WHERE}}
    ORDER BY ds_tipo_peca
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`sts_tipo_peca = $${i++}`);
      params.push(ativo === 'true' ? 'A' : 'I');
    }

    if (q) {
      filters.push(`unaccent(ds_tipo_peca) ILIKE unaccent($${i++})`);
      params.push(`%${q}%`);
    }

    return {
      where: filters.length ? `WHERE ${filters.join(' AND ')}` : '',
      params
    };
  },
  rowMap: (r) => [
    r.cd_tipo_peca,
    r.ds_tipo_peca,
    r.sts_tipo_peca === 'A' ? 'Ativo' : 'Inativo'
  ],
});

router.get('/exportar/csv', verificarToken, exportTipos);

module.exports = router;
