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
router.get('/listar', tokenOpcional, listarSubtipos);
router.get('/buscar', tokenOpcional, listarSubtipos);

async function listarSubtipos(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q, cd_tipo_peca } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true' ? 'A' : 'I');
    filtros.push(`s.sts_tipo_peca = $${valores.length}`);
  }

  if (cd_tipo_peca) {
    valores.push(cd_tipo_peca);
    filtros.push(`s.cd_tipo_peca = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`(
      unaccent(s.descricao) ILIKE unaccent($${valores.length})
      OR CAST(s.cd_subtipo_peca AS TEXT) ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_subtipo_peca s
    ${where}
  `;

  const baseQuery = `
    SELECT
      s.cd_subtipo_peca,
      s.descricao,
      s.cd_tipo_peca,
      t.ds_tipo_peca AS tipo_obra_descricao,
      s.sts_tipo_peca
    FROM public.ace_subtipo_peca s
    JOIN public.ace_tipo_peca t ON t.cd_tipo_peca = s.cd_tipo_peca
    ${where}
    ORDER BY s.descricao
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

    resultado.dados = resultado.dados.map(s => ({
      ...s,
      ativo: s.sts_tipo_peca === 'A'
    }));

    res.status(200).json(resultado);

  } catch (err) {
    logger.error(
      'Erro ao listar Subtipos de Obra: ' + err.stack,
      'SubtipoObra'
    );
    res.status(500).json({
      erro: 'Erro ao listar Subtipos de Obra.',
      motivo: err.message
    });
  }
}

/* =========================================================
   CADASTRAR
========================================================= */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { descricao, cd_tipo_peca, ativo = true } = req.body;

  if (!descricao || !cd_tipo_peca) {
    return res.status(400).json({
      erro: 'Os campos "descricao" e "cd_tipo_peca" são obrigatórios.'
    });
  }

  try {
    // duplicidade por tipo de obra
    const dup = await pool.query(
      `
      SELECT 1
      FROM public.ace_subtipo_peca
      WHERE LOWER(descricao) = LOWER($1)
        AND cd_tipo_peca = $2
      LIMIT 1
      `,
      [descricao.trim(), cd_tipo_peca]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro:
          'Já existe um subtipo com essa descrição para o tipo de obra informado.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ace_subtipo_peca
        (descricao, cd_tipo_peca, sts_tipo_peca)
      VALUES ($1, $2, $3)
      RETURNING cd_subtipo_peca
      `,
      [
        descricao.trim(),
        cd_tipo_peca,
        ativo ? 'A' : 'I'
      ]
    );

    res.status(201).json({
      message: 'Subtipo de Obra cadastrado com sucesso!',
      cd_subtipo_peca: result.rows[0].cd_subtipo_peca
    });

  } catch (err) {
    logger.error(
      'Erro ao cadastrar Subtipo de Obra: ' + err.stack,
      'SubtipoObra'
    );
    res.status(500).json({ erro: 'Erro ao cadastrar Subtipo de Obra.' });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:cd_subtipo_peca', verificarToken, async (req, res) => {
  const { cd_subtipo_peca } = req.params;
  const { descricao, cd_tipo_peca, ativo } = req.body;

  try {
    const atual = await pool.query(
      `
      SELECT descricao, cd_tipo_peca
      FROM public.ace_subtipo_peca
      WHERE cd_subtipo_peca = $1
      `,
      [cd_subtipo_peca]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({
        erro: 'Subtipo de Obra não encontrado.'
      });
    }

    const tipoFinal = cd_tipo_peca ?? atual.rows[0].cd_tipo_peca;

    // valida duplicidade
    if (
      descricao &&
      descricao.trim().toLowerCase() !==
        atual.rows[0].descricao.toLowerCase()
    ) {
      const dup = await pool.query(
        `
        SELECT 1
        FROM public.ace_subtipo_peca
        WHERE LOWER(descricao) = LOWER($1)
          AND cd_tipo_peca = $2
          AND cd_subtipo_peca <> $3
        `,
        [descricao.trim(), tipoFinal, cd_subtipo_peca]
      );

      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro:
            'Já existe um subtipo com essa descrição para o tipo de obra informado.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ace_subtipo_peca
      SET descricao = COALESCE($1, descricao),
          cd_tipo_peca = COALESCE($2, cd_tipo_peca),
          sts_tipo_peca = COALESCE($3, sts_tipo_peca)
      WHERE cd_subtipo_peca = $4
      `,
      [
        descricao?.trim(),
        cd_tipo_peca,
        ativo !== undefined ? (ativo ? 'A' : 'I') : null,
        cd_subtipo_peca
      ]
    );

    res.status(200).json({
      message: 'Subtipo de Obra atualizado com sucesso!'
    });

  } catch (err) {
    logger.error(
      'Erro ao atualizar Subtipo de Obra: ' + err.stack,
      'SubtipoObra'
    );
    res.status(500).json({ erro: 'Erro ao atualizar Subtipo de Obra.' });
  }
});

/* =========================================================
   EXPORTAR CSV
========================================================= */
const exportSubtipos = createCsvExporter({
  filename: () =>
    `subtipos-obra-${new Date().toISOString().slice(0, 10)}.csv`,
  header: ['Código', 'Descrição', 'Tipo de Obra', 'Status'],
  baseQuery: `
    SELECT
      s.cd_subtipo_peca,
      s.descricao,
      t.ds_tipo_peca AS tipo_obra,
      s.sts_tipo_peca
    FROM public.ace_subtipo_peca s
    JOIN public.ace_tipo_peca t ON t.cd_tipo_peca = s.cd_tipo_peca
    {{WHERE}}
    ORDER BY s.descricao
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q, cd_tipo_peca } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`s.sts_tipo_peca = $${i++}`);
      params.push(ativo === 'true' ? 'A' : 'I');
    }

    if (cd_tipo_peca) {
      filters.push(`s.cd_tipo_peca = $${i++}`);
      params.push(cd_tipo_peca);
    }

    if (q) {
      filters.push(`unaccent(s.descricao) ILIKE unaccent($${i++})`);
      params.push(`%${q}%`);
    }

    return {
      where: filters.length ? `WHERE ${filters.join(' AND ')}` : '',
      params
    };
  },
  rowMap: (r) => [
    r.cd_subtipo_peca,
    r.descricao,
    r.tipo_obra,
    r.sts_tipo_peca === 'A' ? 'Ativo' : 'Inativo'
  ],
});

router.get('/exportar/csv', verificarToken, exportSubtipos);

module.exports = router;
