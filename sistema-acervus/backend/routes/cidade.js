const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

/* =========================================================
   LISTAR / BUSCAR (PAGINADO)
========================================================= */
router.get('/listar', tokenOpcional, listarCidades);
router.get('/buscar', tokenOpcional, listarCidades);

async function listarCidades(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const {
    q,
    estado_id,
    pais_id,
    codigo_ibge
  } = req.query;

  const filtros = [];
  const valores = [];

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`
      (
        unaccent(c.nome) ILIKE unaccent($${valores.length})
        OR CAST(c.codigo_ibge AS TEXT) ILIKE $${valores.length}
        OR CAST(c.id AS TEXT) ILIKE $${valores.length}
      )
    `);
  }

  if (codigo_ibge) {
    valores.push(codigo_ibge);
    filtros.push(`c.codigo_ibge = $${valores.length}`);
  }

  if (estado_id) {
    valores.push(estado_id);
    filtros.push(`c.estado_id = $${valores.length}`);
  }

  if (pais_id) {
    valores.push(pais_id);
    filtros.push(`e.pais_id = $${valores.length}`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM public.ger_cidade c
    JOIN public.ger_estado e ON e.id = c.estado_id
    ${where}
  `;

  const baseQuery = `
    SELECT
      c.id,
      c.nome,
      c.codigo_ibge,
      c.estado_id,
      e.nome   AS estado_nome,
      e.sigla  AS estado_sigla,
      e.pais_id,
      p.nome   AS pais_nome,
      p.sigla  AS pais_sigla,
      c.populacao_2010,
      c.densidade_demo,
      c.gentilico,
      c.area
    FROM public.ger_cidade c
    JOIN public.ger_estado e ON e.id = c.estado_id
    JOIN public.ger_pais   p ON p.id = e.pais_id
    ${where}
    ORDER BY c.nome
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
    logger.error('Erro ao listar Cidades: ' + err.stack, 'Cidade');
    res.status(500).json({
      erro: 'Erro ao listar cidades.',
      motivo: err.message
    });
  }
}

/* =========================================================
   LISTAR SIMPLES (POR ESTADO)
========================================================= */
router.get('/listar-por-estado/:estado_id', tokenOpcional, async (req, res) => {
  const { estado_id } = req.params;

  try {
    const sql = `
      SELECT  c.id,
      c.nome,
      c.codigo_ibge,
      c.estado_id,
      e.nome   AS estado_nome,
      e.sigla  AS estado_sigla,
      e.pais_id,
      p.nome   AS pais_nome,
      p.sigla  AS pais_sigla,
      c.populacao_2010,
      c.densidade_demo,
      c.gentilico,
      c.area
       FROM public.ger_cidade c
    JOIN public.ger_estado e ON e.id = c.estado_id
    JOIN public.ger_pais   p ON p.id = e.pais_id
      WHERE estado_id = $1
      ORDER BY nome
    `;

    const result = await pool.query(sql, [estado_id]);
    res.status(200).json(result.rows);

  } catch (err) {
    logger.error('Erro ao listar cidades por estado: ' + err.stack, 'Cidade');
    res.status(500).json({ erro: 'Erro ao listar cidades.' });
  }
});

/* =========================================================
   CADASTRAR
========================================================= */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const {
    nome,
    codigo_ibge,
    estado_id,
    populacao_2010,
    densidade_demo,
    gentilico,
    area
  } = req.body;

  if (!nome || !estado_id) {
    return res.status(400).json({
      erro: 'Os campos "nome" e "estado_id" são obrigatórios.'
    });
  }

  try {
    // valida duplicidade (nome + estado)
    const dup = await pool.query(
      `
      SELECT 1
      FROM public.ger_cidade
      WHERE LOWER(nome) = LOWER($1)
        AND estado_id = $2
      LIMIT 1
      `,
      [nome.trim(), estado_id]
    );

    if (dup.rowCount > 0) {
      return res.status(409).json({
        erro: 'Já existe uma cidade com esse nome para o estado informado.'
      });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ger_cidade (
        nome,
        codigo_ibge,
        estado_id,
        populacao_2010,
        densidade_demo,
        gentilico,
        area
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING id
      `,
      [
        nome.trim(),
        codigo_ibge || null,
        estado_id,
        populacao_2010 || null,
        densidade_demo || null,
        gentilico?.trim() || null,
        area || null
      ]
    );

    res.status(201).json({
      message: 'Cidade cadastrada com sucesso!',
      id: result.rows[0].id
    });

  } catch (err) {
    logger.error('Erro ao cadastrar Cidade: ' + err.stack, 'Cidade');
    res.status(500).json({ erro: 'Erro ao cadastrar cidade.' });
  }
});

/* =========================================================
   ALTERAR
========================================================= */
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

  const {
    nome,
    codigo_ibge,
    estado_id,
    populacao_2010,
    densidade_demo,
    gentilico,
    area
  } = req.body;

  try {
    const atual = await pool.query(
      `
      SELECT nome, estado_id
      FROM public.ger_cidade
      WHERE id = $1
      `,
      [id]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({
        erro: 'Cidade não encontrada.'
      });
    }

    // valida duplicidade se mudar nome ou estado
    if (
      (nome && nome.trim().toLowerCase() !== atual.rows[0].nome.toLowerCase()) ||
      (estado_id && estado_id !== atual.rows[0].estado_id)
    ) {
      const dup = await pool.query(
        `
        SELECT 1
        FROM public.ger_cidade
        WHERE LOWER(nome) = LOWER($1)
          AND estado_id = $2
          AND id <> $3
        `,
        [
          nome?.trim() || atual.rows[0].nome,
          estado_id || atual.rows[0].estado_id,
          id
        ]
      );

      if (dup.rowCount > 0) {
        return res.status(409).json({
          erro: 'Já existe uma cidade com esse nome para o estado informado.'
        });
      }
    }

    await pool.query(
      `
      UPDATE public.ger_cidade
      SET
        nome = COALESCE($1, nome),
        codigo_ibge = COALESCE($2, codigo_ibge),
        estado_id = COALESCE($3, estado_id),
        populacao_2010 = COALESCE($4, populacao_2010),
        densidade_demo = COALESCE($5, densidade_demo),
        gentilico = COALESCE($6, gentilico),
        area = COALESCE($7, area)
      WHERE id = $8
      `,
      [
        nome?.trim(),
        codigo_ibge,
        estado_id,
        populacao_2010,
        densidade_demo,
        gentilico?.trim(),
        area,
        id
      ]
    );

    res.status(200).json({
      message: 'Cidade atualizada com sucesso!'
    });

  } catch (err) {
    logger.error('Erro ao alterar Cidade: ' + err.stack, 'Cidade');
    res.status(500).json({ erro: 'Erro ao atualizar cidade.' });
  }
});

module.exports = router;
