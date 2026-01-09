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
router.get('/listar', tokenOpcional, listarMateriais);
router.get('/buscar', tokenOpcional, listarMateriais);

async function listarMateriais(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true' ? 'A' : 'I');
    filtros.push(`sts_material = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`
      (
        unaccent(descricao) ILIKE unaccent($${valores.length})
        OR CAST(cd_material AS TEXT) ILIKE $${valores.length}
      )
    `);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ace_material
    ${where}
  `;

  const baseQuery = `
    SELECT
      cd_material,
      descricao,
      sts_material
    FROM public.ace_material
    ${where}
    ORDER BY descricao
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

    // converte A/I → boolean
    resultado.dados = resultado.dados.map(m => ({
      ...m,
      ativo: m.sts_material === 'A'
    }));

    res.status(200).json(resultado);

  } catch (err) {
    logger.error('Erro ao listar Materiais: ' + err.stack, 'Material');
    res.status(500).json({
      erro: 'Erro ao listar Materiais.',
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
    // Verifica duplicidade
    const dup = await pool.query(
      `
      SELECT 1
      FROM public.ace_material
      WHERE LOWER(descricao) = LOWER($1)
      LIMIT 1
      `,
      [descricao.trim()]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe um material com essa descrição.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ace_material
        (descricao, sts_material)
      VALUES ($1, $2)
      RETURNING cd_material
      `,
      [
        descricao.trim(),
        ativo ? 'A' : 'I'
      ]
    );

    res.status(201).json({
      message: 'Material cadastrado com sucesso!',
      cd_material: result.rows[0].cd_material
    });

  } catch (err) {
    logger.error('Erro ao cadastrar Material: ' + err.stack, 'Material');
    res.status(500).json({ erro: 'Erro ao cadastrar Material.' });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:cd_material', verificarToken, async (req, res) => {
  const { cd_material } = req.params;
  const { descricao, ativo } = req.body;

  try {
    const atual = await pool.query(
      `SELECT descricao FROM public.ace_material WHERE cd_material = $1`,
      [cd_material]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({ erro: 'Material não encontrado.' });
    }

    // valida duplicidade
    if (
      descricao &&
      descricao.trim().toLowerCase() !== atual.rows[0].descricao.toLowerCase()
    ) {
      const dup = await pool.query(
        `
        SELECT 1
        FROM public.ace_material
        WHERE LOWER(descricao) = LOWER($1)
        AND cd_material <> $2
        `,
        [descricao.trim(), cd_material]
      );

      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe um material com essa descrição.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ace_material
      SET descricao = COALESCE($1, descricao),
          sts_material = COALESCE($2, sts_material)
      WHERE cd_material = $3
      `,
      [
        descricao?.trim(),
        ativo !== undefined ? (ativo ? 'A' : 'I') : null,
        cd_material
      ]
    );

    res.status(200).json({
      message: 'Material atualizado com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao atualizar Material: ' + err.stack, 'Material');
    res.status(500).json({ erro: 'Erro ao atualizar Material.' });
  }
});

/* =========================================================
   EXPORTAR CSV
========================================================= */
const exportMateriais = createCsvExporter({
  filename: () => `materiais-${new Date().toISOString().slice(0, 10)}.csv`,
  header: ['Código', 'Descrição', 'Status'],
  baseQuery: `
    SELECT
      cd_material,
      descricao,
      sts_material
    FROM public.ace_material
    {{WHERE}}
    ORDER BY descricao
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`sts_material = $${i++}`);
      params.push(ativo === 'true' ? 'A' : 'I');
    }

    if (q) {
      filters.push(`unaccent(descricao) ILIKE unaccent($${i++})`);
      params.push(`%${q}%`);
    }

    return {
      where: filters.length ? `WHERE ${filters.join(' AND ')}` : '',
      params
    };
  },
  rowMap: (r) => [
    r.cd_material,
    r.descricao,
    r.sts_material === 'A' ? 'Ativo' : 'Inativo'
  ],
});

router.get('/exportar/csv', verificarToken, exportMateriais);

module.exports = router;
