const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

// POST - Cadastrar orientador
router.post('/cadastrar', tokenOpcional, async (req, res) => {
  const {
    nome,
    data_nascimento,
    cargo,
    email,
    graduacao,
    ativo = true,
    cd_instituicao_ensino
  } = req.body;

  const userId = req.usuario?.cd_usuario || null ; 
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!nome || !cd_instituicao_ensino) {
    return res.status(400).json({ erro: 'Nome e Código da Instituição são obrigatórios.' });
  }

  const insertQuery = `
    INSERT INTO public.orientador (
      nome, data_nascimento, cargo, email, graduacao,
      ativo, data_criacao, criado_por, cd_instituicao_ensino
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    RETURNING id_orientador;
  `;

  const values = [
    nome, data_nascimento, cargo, email, graduacao,
    ativo, dataAtual, userId, cd_instituicao_ensino
  ];

  try {
    const result = await pool.query(insertQuery, values);
    res.status(201).json({
      message: 'Orientador cadastrado com sucesso!',
      id_orientador: result.rows[0].id_orientador
    });
  } catch (err) {
    logger.error('Erro ao inserir orientador: ' + err.stack, 'orientadores');
    res.status(500).json({ erro: 'Erro ao cadastrar orientador.' });
  }
});

// GET - Listar orientadores por instituição
router.get('/instituicao/listar/:cd_instituicao_ensino', tokenOpcional, async (req, res) => {
  const { cd_instituicao_ensino } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT *
    FROM public.orientador
    WHERE cd_instituicao_ensino = $1
    ORDER BY nome ASC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.orientador
    WHERE cd_instituicao_ensino = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_instituicao_ensino], page, limit);
    res.json(resultado);
  } catch (err) {
    logger.error('Erro ao buscar orientadores: ' + err.stack, 'orientadores');
    res.status(500).json({ erro: 'Erro ao buscar orientadores.' });
  }
});

// PUT - Alterar orientador
router.put('/alterar/:id_orientador', tokenOpcional, async (req, res) => {
  const { id_orientador } = req.params;
  const {
    nome,
    data_nascimento,
    cargo,
    email,
    graduacao,
    ativo,
    cd_instituicao_ensino
  } = req.body;

  const userId = req.usuario?.cd_usuario || null ; 
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!nome || !cd_instituicao_ensino) {
    return res.status(400).json({ erro: 'Nome e Código da Instituição são obrigatórios.' });
  }

  const updateQuery = `
    UPDATE public.orientador
    SET nome = $1,
        data_nascimento = $2,
        cargo = $3,
        email = $4,
        graduacao = $5,
        ativo = $6,
        data_alteracao = $7,
        alterado_por = $8
    WHERE id_orientador = $9
    RETURNING id_orientador;
  `;

  const values = [
    nome, data_nascimento, cargo, email, graduacao,
    ativo, dataAtual, userId, id_orientador
  ];

  try {
    const result = await pool.query(updateQuery, values);
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Orientador não encontrado.' });
    }

    res.status(200).json({
      message: 'Orientador atualizado com sucesso!',
      id_orientador: result.rows[0].id_orientador
    });
  } catch (err) {
    logger.error('Erro ao atualizar orientador: ' + err.stack, 'orientadores');
    res.status(500).json({ erro: 'Erro ao atualizar orientador.' });
  }
});

module.exports = router;
