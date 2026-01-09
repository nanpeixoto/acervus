const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

// POST - Cadastrar Signatário
router.post('/cadastrar', verificarToken, async (req, res) => {
  const {
    nome,
    cpf,
    email,
    celular,
    data_nascimento,
    descricao,
    ativo = true,
    cd_instituicao_ensino
  } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!nome || !cpf || !cd_instituicao_ensino) {
    return res.status(400).json({ erro: 'Nome, CPF e Código da Instituição são obrigatórios.' });
  }

  const insertQuery = `
    INSERT INTO public.signatario (
      nome, cpf, email, celular, data_nascimento, descricao,
      ativo, data_criacao, criado_por, cd_instituicao_ensino
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING cd_signatario;
  `;

  const values = [
    nome, cpf, email, celular, data_nascimento, descricao,
    ativo, dataAtual, userId, cd_instituicao_ensino
  ];

  try {
    const result = await pool.query(insertQuery, values);
    res.status(201).json({
      message: 'Signatário cadastrado com sucesso!',
      cd_signatario: result.rows[0].cd_signatario
    });
  } catch (err) {
    if (err.code === '23505') {
      logger.warn(`CPF duplicado para a mesma instituição: ${cpf} - IE: ${cd_instituicao_ensino}`, 'signatarios');
      return res.status(409).json({ erro: 'Já existe um signatário com este CPF para esta instituição.' });
    }
    logger.error('Erro ao cadastrar signatário: ' + err.stack, 'signatarios');
    res.status(500).json({ erro: 'Erro ao cadastrar signatário.' });
  }
});

// GET - Listar Signatários por Instituição
router.get('/instituicao/listar/:cd_instituicao_ensino', verificarToken, async (req, res) => {
  const { cd_instituicao_ensino } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT cd_signatario, nome, cpf, email, celular, data_nascimento, descricao, ativo
    FROM public.signatario
    WHERE cd_instituicao_ensino = $1
    ORDER BY nome ASC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.signatario
    WHERE cd_instituicao_ensino = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_instituicao_ensino], page, limit);
    res.json(resultado);
  } catch (err) {
    logger.error('Erro ao listar signatários: ' + err.stack, 'signatarios');
    res.status(500).json({ erro: 'Erro ao listar signatários.' });
  }
});

// PUT - Alterar Signatário
router.put('/alterar/:cd_signatario', verificarToken, async (req, res) => {
  const { cd_signatario } = req.params;
  const {
    nome,
    cpf,
    email,
    celular,
    data_nascimento,
    descricao,
    ativo,
    cd_instituicao_ensino
  } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!nome || !cpf || !cd_instituicao_ensino) {
    return res.status(400).json({ erro: 'Nome, CPF e Código da Instituição são obrigatórios.' });
  }

  const updateQuery = `
    UPDATE public.signatario
    SET nome = $1,
        cpf = $2,
        email = $3,
        celular = $4,
        data_nascimento = $5,
        descricao = $6,
        ativo = $7,
        data_alteracao = $8,
        alterado_por = $9,
        cd_instituicao_ensino = $10
    WHERE cd_signatario = $11
    RETURNING cd_signatario;
  `;

  const values = [
    nome, cpf, email, celular, data_nascimento, descricao,
    ativo, dataAtual, userId, cd_instituicao_ensino, cd_signatario
  ];

  try {
  const result = await pool.query(updateQuery, values);
  if (result.rowCount === 0) {
    return res.status(404).json({ erro: 'Signatário não encontrado.' });
  }

  res.status(200).json({
    message: 'Signatário atualizado com sucesso!',
    cd_signatario: result.rows[0].cd_signatario
  });
} catch (err) {
  if (err.code === '23505') {
    logger.warn(`Tentativa de atualizar CPF duplicado para a mesma instituição: ${cpf} - IE: ${cd_instituicao_ensino}`, 'signatarios');
    return res.status(409).json({ erro: 'Já existe outro signatário com este CPF para esta instituição.' });
  }
  logger.error('Erro ao atualizar signatário: ' + err.stack, 'signatarios');
  res.status(500).json({ erro: 'Erro ao atualizar signatário.' });
}
});

module.exports = router;
