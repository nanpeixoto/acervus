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
router.get('/listar', tokenOpcional, listarIdiomas);
router.get('/buscar', tokenOpcional, listarIdiomas);

async function listarIdiomas(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const { ativo, q } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true' ? 'A' : 'I');
    filtros.push(`sts_idioma = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`(
      unaccent(ds_idioma) ILIKE unaccent($${valores.length})
      OR CAST(cd_idioma AS TEXT) ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_idioma
    ${where}
  `;

  const baseQuery = `
    SELECT
      cd_idioma,
      ds_idioma AS descricao,
      sts_idioma,
      (sts_idioma = 'A') AS ativo
    FROM public.ace_idioma
    ${where}
    ORDER BY ds_idioma
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
    logger.error('Erro ao listar Idiomas: ' + err.stack, 'Idioma');
    res.status(500).json({
      erro: 'Erro ao listar Idiomas.',
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
      `SELECT 1 FROM public.ace_idioma
       WHERE LOWER(ds_idioma) = LOWER($1)
       LIMIT 1`,
      [descricao.trim()]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe um idioma com essa descrição.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ace_idioma
        (ds_idioma, sts_idioma)
      VALUES ($1, $2)
      RETURNING cd_idioma
      `,
      [
        descricao.trim(),
        ativo ? 'A' : 'I'
      ]
    );

    res.status(201).json({
      message: 'Idioma cadastrado com sucesso!',
      cd_idioma: result.rows[0].cd_idioma
    });

  } catch (err) {
    logger.error('Erro ao cadastrar Idioma: ' + err.stack, 'Idioma');
    res.status(500).json({ erro: 'Erro ao cadastrar Idioma.' });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:cd_idioma', verificarToken, async (req, res) => {
  const { cd_idioma } = req.params;
  const { descricao, ativo } = req.body;

  try {
    const atual = await pool.query(
      `SELECT ds_idioma, sts_idioma
       FROM public.ace_idioma
       WHERE cd_idioma = $1`,
      [cd_idioma]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({ erro: 'Idioma não encontrado.' });
    }

    if (
      descricao &&
      descricao.trim().toLowerCase() !== atual.rows[0].ds_idioma.toLowerCase()
    ) {
      const dup = await pool.query(
        `SELECT 1 FROM public.ace_idioma
         WHERE LOWER(ds_idioma) = LOWER($1)
         AND cd_idioma <> $2`,
        [descricao.trim(), cd_idioma]
      );
      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe um idioma com essa descrição.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ace_idioma
      SET ds_idioma = COALESCE($1, ds_idioma),
          sts_idioma = COALESCE($2, sts_idioma)
      WHERE cd_idioma = $3
      `,
      [
        descricao?.trim(),
        ativo !== undefined ? (ativo ? 'A' : 'I') : null,
        cd_idioma
      ]
    );

    res.status(200).json({
      message: 'Idioma atualizado com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao atualizar Idioma: ' + err.stack, 'Idioma');
    res.status(500).json({ erro: 'Erro ao atualizar Idioma.' });
  }
});

/* =========================================================
   EXPORTAR CSV
========================================================= */
const exportIdiomas = createCsvExporter({
  filename: () => `idiomas-${new Date().toISOString().slice(0, 10)}.csv`,
  header: ['Código', 'Descrição', 'Status'],
  baseQuery: `
    SELECT
      cd_idioma,
      ds_idioma,
      sts_idioma
    FROM public.ace_idioma
    {{WHERE}}
    ORDER BY ds_idioma
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`sts_idioma = $${i++}`);
      params.push(ativo === 'true' ? 'A' : 'I');
    }

    if (q) {
      filters.push(`unaccent(ds_idioma) ILIKE unaccent($${i++})`);
      params.push(`%${q}%`);
    }

    return {
      where: filters.length ? `WHERE ${filters.join(' AND ')}` : '',
      params
    };
  },
  rowMap: (r) => [
    r.cd_idioma,
    r.ds_idioma,
    r.sts_idioma === 'A' ? 'Ativo' : 'Inativo'
  ],
});

router.get('/exportar/csv', verificarToken, exportIdiomas);

module.exports = router;
