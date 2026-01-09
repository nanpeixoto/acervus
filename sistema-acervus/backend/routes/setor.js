// routes/setor.js
const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ Autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');

/**
 * POST /setores/cadastrar
 */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { descricao, ativo = true } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!descricao || !descricao.trim()) {
    return res.status(400).json({ erro: 'O campo "descricao" é obrigatório.' });
  }

  try {
    // Unicidade (case/acentos-insensitive)
    const dup = await pool.query(
      `SELECT 1
         FROM public.setor
        WHERE unaccent(lower(descricao)) = unaccent(lower($1))
        LIMIT 1`,
      [descricao.trim()]
    );
    if (dup.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe um setor com esse descricao.' });
    }

    const insert = await pool.query(
      `INSERT INTO public.setor (descricao, ativo, criado_por, data_criacao)
       VALUES ($1, $2, $3, $4)
       RETURNING cd_setor`,
      [descricao.trim(), ativo, userId, dataAtual]
    );

    res.status(201).json({
      message: 'Setor cadastrado com sucesso!',
      cd_setor: insert.rows[0].cd_setor
    });
  } catch (err) {
    logger.error('Erro ao cadastrar setor: ' + err.stack, 'setor');
    res.status(500).json({ erro: 'Erro ao cadastrar setor.' });
  }
});

/**
 * GET /setores/listar
 * GET /setores/buscar   (alias)
 * Query: page, limit, ativo, q
 */
router.get('/listar', tokenOpcional, listarSetores);
router.get('/buscar', tokenOpcional, listarSetores);

async function listarSetores(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q , search } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true');
    filtros.push(`s.ativo = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`(
      unaccent(s.descricao) ILIKE unaccent($${valores.length})
      OR CAST(s.cd_setor AS TEXT) ILIKE $${valores.length}
    )`);
  }

   if (search) {
    valores.push(`%${search}%`);
    filtros.push(`(
      unaccent(s.descricao) ILIKE unaccent($${valores.length})
      OR CAST(s.cd_setor AS TEXT) ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM public.setor s ${where}`;
  const baseQuery = `
    SELECT
      s.cd_setor,
      s.descricao,
      s.ativo,
      s.criado_por,
      s.data_criacao,
      s.alterado_por,
      s.data_alteracao
    FROM public.setor s
    ${where}
    ORDER BY s.descricao
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json(resultado);
  } catch (err) {
    logger.error('Erro ao listar setores: ' + err.stack, 'setor');
    res.status(500).json({ erro: 'Erro ao listar setores.' });
  }
}

/**
 * PUT /setores/alterar/:cd_setor
 */
router.put('/alterar/:cd_setor', verificarToken, async (req, res) => {
  const { cd_setor } = req.params;
  const { descricao, ativo } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  try {
    // Busca atual
    const cur = await pool.query(
      `SELECT descricao, ativo FROM public.setor WHERE cd_setor = $1`,
      [cd_setor]
    );
    if (cur.rowCount === 0) {
      return res.status(404).json({ erro: 'Setor não encontrado.' });
    }

    const atual = cur.rows[0];
    const novoNome = (descricao ?? atual.descricao)?.trim();
    const novoAtivo = (ativo ?? atual.ativo);

    if (!novoNome) {
      return res.status(400).json({ erro: 'O campo "descricao" não pode ser vazio.' });
    }

    // Unicidade ao alterar
    if (novoNome.toLowerCase() !== atual.descricao.trim().toLowerCase()) {
      const dup = await pool.query(
        `SELECT 1
           FROM public.setor
          WHERE unaccent(lower(descricao)) = unaccent(lower($1))
            AND cd_setor <> $2
          LIMIT 1`,
        [novoNome, cd_setor]
      );
      if (dup.rowCount > 0) {
        return res.status(409).json({ erro: 'Já existe um setor com esse descricao.' });
      }
    }

    const upd = await pool.query(
      `UPDATE public.setor
          SET descricao = $1,
              ativo = $2,
              data_alteracao = $3,
              alterado_por = $4
        WHERE cd_setor = $5
        RETURNING cd_setor`,
      [novoNome, novoAtivo, dataAtual, userId, cd_setor]
    );

    res.status(200).json({
      message: 'Setor atualizado com sucesso!',
      cd_setor: upd.rows[0].cd_setor
    });
  } catch (err) {
    logger.error('Erro ao atualizar setor: ' + err.stack, 'setor');
    res.status(500).json({ erro: 'Erro ao atualizar setor.' });
  }
});

/**
 * GET /setores/exportar/csv
 */
const exportSetores = createCsvExporter({
  filename: () => `setores-${new Date().toISOString().slice(0,10)}.csv`,
  header: ['Código','Nome','Ativo','Criado Por','Data Criação','Alterado Por','Data Alteração'],
  baseQuery: `
    SELECT 
      s.cd_setor,
      s.descricao,
      s.ativo,
      COALESCE(u1.descricao,'') AS criado_por,
      to_char(s.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.descricao,'') AS alterado_por,
      to_char(s.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.setor s
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = s.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = s.alterado_por
    {{WHERE}}
    ORDER BY s.cd_setor
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [], params = [];
    let i = 1;

    if (ativo !== undefined) { filters.push(`s.ativo = $${i++}`); params.push(ativo === 'true'); }
    if (q) { filters.push(`(unaccent(s.descricao) ILIKE unaccent($${i++}) OR CAST(s.cd_setor AS TEXT) ILIKE $${i-1})`); params.push(`%${q}%`); }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    return { where, params };
  },
  rowMap: (r) => [
    r.cd_setor,
    r.descricao || '',
    r.ativo ? 'Sim' : 'Não',
    r.criado_por,
    r.data_criacao || '',
    r.alterado_por,
    r.data_alteracao || '',
  ],
});

router.get('/exportar/csv', verificarToken, exportSetores);

module.exports = router;
