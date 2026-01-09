// routes/turma.js
const express = require('express');
const router = express.Router();
const pool = require('../db');
const logger = require('../utils/logger');
const { verificarToken, tokenOpcional } = require('../auth');
const { paginarConsulta } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');

/**
 * POST /turma/cadastrar
 * body: { numero, cd_curso, ativo }
 */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { numero, cd_curso, ativo } = req.body;

  if (!numero || !cd_curso) {
    return res.status(400).json({ erro: 'Campos obrigatórios: numero, cd_curso.' });
  }

  const userId = req.usuario.cd_usuario;
  const agora = new Date().toISOString().split('T').join(' ').split('.')[0];

  try {
    // valida curso existente e ativo (opcional)
    const curso = await pool.query(
      `SELECT cd_curso FROM public.curso_aprendizagem WHERE cd_curso = $1`,
      [cd_curso]
    );
    if (curso.rowCount === 0) {
      return res.status(400).json({ erro: 'Curso informado não existe.' });
    }

    // evita duplicidade (ux_turma_numero_por_curso)
    const dup = await pool.query(
      `SELECT 1 FROM public.turma WHERE cd_curso = $1 AND numero = $2 LIMIT 1`,
      [cd_curso, numero]
    );
    if (dup.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe uma turma com este número para este curso.' });
    }

    const r = await pool.query(
      `INSERT INTO public.turma
         (numero, cd_curso, ativo, criado_por, data_criacao)
       VALUES ($1, $2, COALESCE($3, TRUE), $4, $5)
       RETURNING cd_turma`,
      [numero, cd_curso, ativo, userId, agora]
    );

    res.status(201).json({
      mensagem: 'Turma cadastrada com sucesso!',
      cd_turma: r.rows[0].cd_turma
    });
  } catch (err) {
    logger.error('Erro ao cadastrar turma: ' + err.stack, 'turma');
    res.status(500).json({ erro: 'Erro ao cadastrar turma.' + err.stack });
  }
});

/**
 * PUT /turma/alterar/:id
 */
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { numero, cd_curso, ativo } = req.body;

  const userId = req.usuario.cd_usuario;
  const agora = new Date().toISOString().split('T').join(' ').split('.')[0];

  const sets = [];
  const vals = [];
  let i = 1;

  const add = (campo, valor) => {
    sets.push(`${campo} = $${i++}`);
    vals.push(valor);
  };

  try {
    if (numero !== undefined) add('numero', numero);
    if (cd_curso !== undefined) {
      // valida curso
      const curso = await pool.query(
        `SELECT 1 FROM public.curso_aprendizagem WHERE cd_curso = $1`,
        [cd_curso]
      );
      if (curso.rowCount === 0) {
        return res.status(400).json({ erro: 'Curso informado não existe.' });
      }
      add('cd_curso', cd_curso);
    }
    if (ativo !== undefined) add('ativo', ativo);

    if (sets.length === 0) {
      return res.status(400).json({ erro: 'Nenhum campo enviado para alteração.' });
    }

    add('alterado_por', userId);
    add('data_alteracao', agora);

    // checa duplicidade caso esteja mudando numero ou curso
    if (numero !== undefined || cd_curso !== undefined) {
      const rAtual = await pool.query(
        `SELECT cd_curso, numero FROM public.turma WHERE cd_turma = $1`,
        [id]
      );
      if (rAtual.rowCount === 0) return res.status(404).json({ erro: 'Turma não encontrada.' });

      const novoCurso = cd_curso ?? rAtual.rows[0].cd_curso;
      const novoNumero = numero ?? rAtual.rows[0].numero;

      const dup = await pool.query(
        `SELECT 1 FROM public.turma
          WHERE cd_curso = $1 AND numero = $2 AND cd_turma <> $3
          LIMIT 1`,
        [novoCurso, novoNumero, id]
      );
      if (dup.rowCount > 0) {
        return res.status(409).json({ erro: 'Já existe uma turma com este número para este curso.' });
      }
    }

    const sql = `
      UPDATE public.turma
         SET ${sets.join(', ')}
       WHERE cd_turma = $${i}
       RETURNING *`;
    vals.push(id);

    const r = await pool.query(sql, vals);
    if (r.rowCount === 0) return res.status(404).json({ erro: 'Turma não encontrada.' });

    res.json({ mensagem: 'Turma alterada com sucesso!', turma: r.rows[0] });
  } catch (err) {
    logger.error('Erro ao alterar turma: ' + err.stack, 'turma');
    res.status(500).json({ erro: 'Erro ao alterar turma.' });
  }
});

/**
 * PATCH /turma/status/:id  — ativa/desativa rápido (opcional)
 */
router.patch('/status/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { ativo } = req.body;
  if (ativo === undefined) return res.status(400).json({ erro: 'Informe ativo: true|false.' });

  try {
    const r = await pool.query(
      `UPDATE public.turma
          SET ativo = $1, alterado_por = $2, data_alteracao = now()
        WHERE cd_turma = $3
        RETURNING cd_turma, numero, cd_curso, ativo`,
      [ativo, req.usuario.cd_usuario, id]
    );
    if (r.rowCount === 0) return res.status(404).json({ erro: 'Turma não encontrada.' });
    res.json({ mensagem: 'Status atualizado!', turma: r.rows[0] });
  } catch (err) {
    logger.error('Erro ao atualizar status da turma: ' + err.stack, 'turma');
    res.status(500).json({ erro: 'Erro ao atualizar status.' });
  }
});

/**
 * GET /turma/listar  (ou /turma/buscar)
 * Filtros: ?ativo=true|false & q=texto & cd_curso=#
 * Paginação: ?page=1&limit=50
 */
router.get('/listar', tokenOpcional, listarTurmas);
router.get('/buscar', tokenOpcional, listarTurmas);

async function listarTurmas(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q, cd_curso } = req.query;

  const filtros = [];
  const params = [];

  if (ativo !== undefined) {
    params.push(ativo === 'true');
    filtros.push(`t.ativo = $${params.length}`);
  }
  if (cd_curso) {
    params.push(Number(cd_curso));
    filtros.push(`t.cd_curso = $${params.length}`);
  }
  if (q) {
    // busca por número ou nome do curso
    params.push(`%${q}%`);
    filtros.push(`(
      CAST(t.numero AS TEXT) ILIKE $${params.length}
      OR unaccent(c.nome) ILIKE unaccent($${params.length})
    )`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';
  const countQuery = `SELECT COUNT(*) FROM public.turma t JOIN public.curso_aprendizagem c ON c.cd_curso = t.cd_curso ${where}`;

  const baseQuery = `
    SELECT
      t.cd_turma,
      t.numero,
      t.cd_curso,
      c.nome AS curso,
      t.ativo,
      t.criado_por,
      t.data_criacao,
      t.alterado_por,
      t.data_alteracao
    FROM public.turma t
    JOIN public.curso_aprendizagem c ON c.cd_curso = t.cd_curso
    ${where}
    ORDER BY t.numero, c.nome
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, params, page, limit);
    res.json({ ...resultado, dados: resultado.dados });
  } catch (err) {
    logger.error('Erro ao listar turmas: ' + err.stack, 'turma');
    res.status(500).json({ erro: 'Erro ao listar turmas.' });
  }
}

/**
 * GET /turma/buscar/:id
 */
router.get('/buscar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  try {
    const r = await pool.query(
      `SELECT
         t.cd_turma, t.numero, t.cd_curso, c.nome AS curso,
         t.ativo, t.criado_por, t.data_criacao, t.alterado_por, t.data_alteracao
       FROM public.turma t
       JOIN public.curso_aprendizagem c ON c.cd_curso = t.cd_curso
       WHERE t.cd_turma = $1`,
      [id]
    );
    if (r.rowCount === 0) return res.status(404).json({ erro: 'Turma não encontrada.' });
    res.json(r.rows[0]);
  } catch (err) {
    logger.error('Erro ao buscar turma: ' + err.stack, 'turma');
    res.status(500).json({ erro: 'Erro ao buscar turma.' });
  }
});

/**
 * DELETE /turma/:id  (opcional — “remoção lógica” use status se preferir)
 */
router.delete('/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  try {
    const r = await pool.query(`DELETE FROM public.turma WHERE cd_turma = $1`, [id]);
    if (r.rowCount === 0) return res.status(404).json({ erro: 'Turma não encontrada.' });
    res.json({ mensagem: 'Turma excluída com sucesso!' });
  } catch (err) {
    logger.error('Erro ao excluir turma: ' + err.stack, 'turma');
    res.status(500).json({ erro: 'Erro ao excluir turma.' });
  }
});

/**
 * EXPORT CSV /turma/exportar/csv
 */
const exportTurmas = createCsvExporter({
  filename: () => `turmas-${new Date().toISOString().slice(0,10)}.csv`,
  header: [
    'Código Turma', 'Número', 'Código Curso', 'Curso', 'Ativo',
    'Criado Por', 'Data Criação', 'Alterado Por', 'Data Alteração'
  ],
  baseQuery: `
    SELECT
      t.cd_turma,
      t.numero,
      t.cd_curso,
      c.nome AS curso,
      t.ativo,
      COALESCE(u1.nome,'') AS criado_por,
      to_char(t.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.nome,'') AS alterado_por,
      to_char(t.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.turma t
    JOIN public.curso_aprendizagem c ON c.cd_curso = t.cd_curso
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = t.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = t.alterado_por
    {{WHERE}}
    ORDER BY t.numero, c.nome
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q, cd_curso } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`t.ativo = $${i++}`);
      params.push(ativo === 'true');
    }
    if (cd_curso) {
      filters.push(`t.cd_curso = $${i++}`);
      params.push(Number(cd_curso));
    }
    if (q) {
      filters.push(`(
        CAST(t.numero AS TEXT) ILIKE $${i}
        OR unaccent(c.nome) ILIKE unaccent($${i})
      )`);
      params.push(`%${q}%`);
    }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    return { where, params };
  },
  rowMap: (r) => [
    r.cd_turma,
    r.numero,
    r.cd_curso,
    r.curso || '',
    r.ativo ? 'Sim' : 'Não',
    r.criado_por,
    r.data_criacao || '',
    r.alterado_por,
    r.data_alteracao || '',
  ],
});

// criar endpoint que, a partir do Id do curso, lista as turmas com paginação
router.get('/listar/curso/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

  // paginação (valores padrão caso não venham na query)
  const page = Number.parseInt(req.query.page, 10) || 1;
  const limit = Number.parseInt(req.query.limit, 10) || 10;

  // parâmetros da consulta
  const params = [id];

  // query base (sem OFFSET/LIMIT — o helper aplica)
  const baseQuery = `
    SELECT
      t.cd_turma,
      t.numero,
      t.cd_curso,
      c.nome AS curso,
      t.ativo,
      t.criado_por,
      t.data_criacao,
      t.alterado_por,
      t.data_alteracao
    FROM public.turma t
    JOIN public.curso_aprendizagem c ON c.cd_curso = t.cd_curso
    WHERE t.cd_curso = $1
    ORDER BY t.numero ASC, t.cd_turma ASC
  `;

  // query para totalização
  const countQuery = `
    SELECT COUNT(*) AS total
    FROM public.turma t
    WHERE t.cd_curso = $1
  `;

  try {
    const resultado = await paginarConsulta(
      pool,
      baseQuery,
      countQuery,
      params,
      page,
      limit
    );

    // retorno no padrão solicitado
    res.json({ ...resultado, dados: resultado.dados });
  } catch (err) {
    logger.error('Erro ao listar turmas por curso: ' + err.stack, 'turma');
    res.status(500).json({ erro: 'Erro ao listar turmas por curso.' });
  }
});


router.get('/exportar/csv', verificarToken, exportTurmas);

module.exports = router;
