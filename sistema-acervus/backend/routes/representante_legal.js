const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

// Cadastrar representante legal
router.post('/cadastrar', tokenOpcional, async (req, res) => {
  const {
    nome,
    data_nascimento,
    rg,
    cpf,
    email,
    celular,
    telefone,
    cargo,
    nacionalidade,
    observacoes,
    ativo,
    principal,
    cd_instituicao_ensino,
    cd_empresa // ✅ novo campo
  } = req.body;

  const userId = req.usuario?.cd_usuario||null;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!nome || (!cd_instituicao_ensino && !cd_empresa)) {
    return res.status(400).json({ erro: 'Nome e vínculo (instituição ou empresa) são obrigatórios.' });
  }

  // Verifica se já existe principal ativo para o vínculo
  if (ativo && principal) {
    const checkQuery = `
      SELECT 1 FROM public.representante_legal
      WHERE ${cd_instituicao_ensino ? 'cd_instituicao_ensino' : 'cd_empresa'} = $1
      AND ativo = true AND principal = true
      LIMIT 1;
    `;
    const result = await pool.query(checkQuery, [cd_instituicao_ensino || cd_empresa]);
    if (result.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe um representante principal ativo para esse vínculo.' });
    }
  }

  const campos = [
    'nome', 'data_nascimento', 'rg', 'cpf', 'email', 'celular', 'telefone',
    'cargo', 'nacionalidade', 'observacoes',
    'ativo', 'principal', 'data_criacao', 'criado_por'
  ];
  const values = [
    nome, data_nascimento, rg, cpf, email, celular, telefone,
    cargo, nacionalidade, observacoes,
    ativo, principal, dataAtual, userId
  ];

  if (cd_instituicao_ensino) {
    campos.push('cd_instituicao_ensino');
    values.push(cd_instituicao_ensino);
  } else {
    campos.push('cd_empresa');
    values.push(cd_empresa);
  }

  const placeholders = values.map((_, i) => `$${i + 1}`);
  const insertQuery = `
    INSERT INTO public.representante_legal (${campos.join(', ')})
    VALUES (${placeholders.join(', ')})
    RETURNING id_representante_legal;
  `;

  try {
    const result = await pool.query(insertQuery, values);
    res.status(201).json({
      message: 'Representante legal cadastrado com sucesso!',
      id_representante_legal: result.rows[0].id_representante_legal
    });
  } catch (err) {
    logger.error('Erro ao cadastrar representante legal: ' + err.stack, 'representantes');
    res.status(500).json({ erro: 'Erro ao cadastrar representante legal.' });
  }
});


// Listar representantes de uma instituição
router.get('/instituicao/listar/:cd_instituicao_ensino', tokenOpcional, async (req, res) => {
  const { cd_instituicao_ensino } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT * FROM public.representante_legal
    WHERE cd_instituicao_ensino = $1
    ORDER BY principal DESC, data_criacao DESC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.representante_legal
    WHERE cd_instituicao_ensino = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_instituicao_ensino], page, limit);
    res.json(resultado);
  } catch (err) {
    logger.error('Erro ao buscar representantes: ' + err.stack, 'representantes');
    res.status(500).json({ erro: 'Erro ao buscar representantes.' });
  }
});


router.get('/empresa/listar/:cd_empresa', tokenOpcional, async (req, res) => {
  const { cd_empresa } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT * FROM public.representante_legal
    WHERE cd_empresa = $1
    ORDER BY principal DESC, data_criacao DESC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.representante_legal
    WHERE cd_empresa = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_empresa], page, limit);
    res.json(resultado);
  } catch (err) {
    logger.error('Erro ao buscar representantes da empresa: ' + err.stack, 'representantes');
    res.status(500).json({ erro: 'Erro ao buscar representantes da empresa.' });
  }
});


// Alterar representante legal
// Alterar representante legal
router.put('/alterar/:id_representante_legal', tokenOpcional, async (req, res) => {
  const { id_representante_legal } = req.params;
  const {
    nome,
    data_nascimento,
    rg,
    cpf,
    email,
    celular,
    telefone,
    cargo,
    nacionalidade,
    observacoes,
    ativo,
    principal,
    cd_instituicao_ensino,
    cd_empresa
  } = req.body;

  const userId = req.usuario?.cd_usuario || null ;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!nome || (!cd_instituicao_ensino && !cd_empresa)) {
    return res.status(400).json({ erro: 'Nome e vínculo (Instituição ou Empresa) são obrigatórios.' });
  }

  if (ativo && principal) {
    try {
      const campoVinculo = cd_instituicao_ensino ? 'cd_instituicao_ensino' : 'cd_empresa';
      const valorVinculo = cd_instituicao_ensino || cd_empresa;

      const checkQuery = `
        SELECT COUNT(*) FROM public.representante_legal
        WHERE ${campoVinculo} = $1
          AND ativo = true AND principal = true
          AND id_representante_legal <> $2;
      `;

      const result = await pool.query(checkQuery, [valorVinculo, id_representante_legal]);

      if (parseInt(result.rows[0].count) >= 1) {
        return res.status(409).json({
          erro: 'Já existe outro representante legal ativo e principal para esse vínculo.'
        });
      }
    } catch (err) {
      logger.error('Erro ao validar principal: ' + err.stack, 'representantes');
      return res.status(500).json({ erro: 'Erro na validação de dados.' });
    }
  }

  const updateQuery = `
    UPDATE public.representante_legal
    SET nome = $1, data_nascimento = $2, rg = $3, cpf = $4, email = $5,
        celular = $6, telefone = $7, cargo = $8, nacionalidade = $9,
        observacoes = $10, ativo = $11, principal = $12,
        cd_instituicao_ensino = $13, cd_empresa = $14,
        data_alteracao = $15, alterado_por = $16
    WHERE id_representante_legal = $17
    RETURNING id_representante_legal;
  `;

  const values = [
    nome, data_nascimento, rg, cpf, email,
    celular, telefone, cargo, nacionalidade,
    observacoes, ativo, principal,
    cd_instituicao_ensino || null,
    cd_empresa || null,
    dataAtual, userId, id_representante_legal
  ];

  try {
    const result = await pool.query(updateQuery, values);
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Representante não encontrado.' });
    }

    res.status(200).json({
      message: 'Representante legal atualizado com sucesso!',
      id_representante_legal: result.rows[0].id_representante_legal
    });
  } catch (err) {
    logger.error('Erro ao atualizar representante legal: ' + err.stack, 'representantes');
    res.status(500).json({ erro: 'Erro ao atualizar representante legal.' });
  }
});


module.exports = router;
