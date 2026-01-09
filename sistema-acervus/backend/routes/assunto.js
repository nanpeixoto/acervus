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
router.get('/listar', tokenOpcional, listarAssuntos);
router.get('/buscar', tokenOpcional, listarAssuntos);

async function listarAssuntos(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true' ? 'A' : 'I');
    filtros.push(`sts_assunto = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`(
      unaccent(ds_assunto) ILIKE unaccent($${valores.length})
      OR unaccent(sigla) ILIKE unaccent($${valores.length})
      OR CAST(cd_assunto AS TEXT) ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*) 
    FROM public.ace_assunto
    ${where}
  `;

  const baseQuery = `
    SELECT
      cd_assunto,
      ds_assunto AS descricao,
      sigla,
      sts_assunto
    FROM public.ace_assunto
    ${where}
    ORDER BY ds_assunto
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
    resultado.dados = resultado.dados.map(a => ({
      ...a,
      ativo: a.sts_assunto === 'A'
    }));

    res.status(200).json(resultado);

  } catch (err) {
    logger.error('Erro ao listar Assuntos: ' + err.stack, 'Assunto');
    res.status(500).json({
      erro: 'Erro ao listar Assuntos.',
      motivo: err.message
    });
  }
}

/* =========================================================
   CADASTRAR
========================================================= */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { descricao, sigla, ativo = true } = req.body;

  if (!descricao) {
    return res.status(400).json({ erro: 'O campo "descricao" é obrigatório.' });
  }

  try {
    // Verifica duplicidade
    const dup = await pool.query(
      `SELECT 1 FROM public.ace_assunto
       WHERE LOWER(ds_assunto) = LOWER($1)
       LIMIT 1`,
      [descricao.trim()]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe um assunto com essa descrição.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ace_assunto
        (ds_assunto, sigla, sts_assunto)
      VALUES ($1, $2, $3)
      RETURNING cd_assunto
      `,
      [
        descricao.trim(),
        sigla?.trim() || null,
        ativo ? 'A' : 'I'
      ]
    );

    res.status(201).json({
      message: 'Assunto cadastrado com sucesso!',
      cd_assunto: result.rows[0].cd_assunto
    });

  } catch (err) {
    logger.error('Erro ao cadastrar Assunto: ' + err.stack, 'Assunto');
    res.status(500).json({ erro: 'Erro ao cadastrar Assunto.' });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:cd_assunto', verificarToken, async (req, res) => {
  const { cd_assunto } = req.params;
  const { descricao, sigla, ativo } = req.body;

  try {
    const atual = await pool.query(
      `SELECT ds_assunto FROM public.ace_assunto WHERE cd_assunto = $1`,
      [cd_assunto]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({ erro: 'Assunto não encontrado.' });
    }

    // valida duplicidade
    if (
      descricao &&
      descricao.trim().toLowerCase() !== atual.rows[0].ds_assunto.toLowerCase()
    ) {
      const dup = await pool.query(
        `SELECT 1 FROM public.ace_assunto
         WHERE LOWER(ds_assunto) = LOWER($1)
         AND cd_assunto <> $2`,
        [descricao.trim(), cd_assunto]
      );
      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe um assunto com essa descrição.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ace_assunto
      SET ds_assunto = COALESCE($1, ds_assunto),
          sigla = COALESCE($2, sigla),
          sts_assunto = COALESCE($3, sts_assunto)
      WHERE cd_assunto = $4
      `,
      [
        descricao?.trim(),
        sigla?.trim(),
        ativo !== undefined ? (ativo ? 'A' : 'I') : null,
        cd_assunto
      ]
    );

    res.status(200).json({
      message: 'Assunto atualizado com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao atualizar Assunto: ' + err.stack, 'Assunto');
    res.status(500).json({ erro: 'Erro ao atualizar Assunto.' });
  }
});

/* =========================================================
   EXPORTAR CSV
========================================================= */
const exportAssuntos = createCsvExporter({
  filename: () => `assuntos-${new Date().toISOString().slice(0, 10)}.csv`,
  header: ['Código', 'Descrição', 'Sigla', 'Status'],
  baseQuery: `
    SELECT
      cd_assunto,
      ds_assunto,
      sigla,
      sts_assunto
    FROM public.ace_assunto
    {{WHERE}}
    ORDER BY ds_assunto
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`sts_assunto = $${i++}`);
      params.push(ativo === 'true' ? 'A' : 'I');
    }

    if (q) {
      filters.push(`unaccent(ds_assunto) ILIKE unaccent($${i++})`);
      params.push(`%${q}%`);
    }

    return {
      where: filters.length ? `WHERE ${filters.join(' AND ')}` : '',
      params
    };
  },
  rowMap: (r) => [
    r.cd_assunto,
    r.ds_assunto,
    r.sigla || '',
    r.sts_assunto === 'A' ? 'Ativo' : 'Inativo'
  ],
});

router.get('/exportar/csv', verificarToken, exportAssuntos);

module.exports = router;
