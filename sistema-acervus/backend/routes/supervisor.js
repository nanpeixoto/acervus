const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');
const { cadastrarUsuarioSupervisor } = require('./usuario'); // ajuste o path se necessário
const md5 = require('md5');


// POST - Cadastrar supervisor
router.post('/cadastrar', tokenOpcional, async (req, res) => {
 const { nome, cargo, email, ativo = true, cd_empresa, cpf, cd_curso, senha, numero_registro } = req.body;


  const userId = req.usuario?.cd_usuario || null;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];
  
  if (!nome || !cd_empresa  ) {
    return res.status(400).json({
      erro: 'Nome, Código da Empresa são obrigatórios.'
    });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Inserir supervisor
    const insertQuery = `
     INSERT INTO public.supervisor (
          nome, cargo, email, ativo, cd_empresa, cpf, cd_curso, numero_registro, data_criacao, criado_por
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING cd_supervisor;
    `;
    const  values = [nome, cargo, email, ativo, cd_empresa, cpf, cd_curso, numero_registro, dataAtual, userId];
    const result = await client.query(insertQuery, values);

    const cd_supervisor = result.rows[0].cd_supervisor;

    // Cadastrar usuário supervisor somente se CPF e email forem informados
    if (cpf && email) {
      await cadastrarUsuarioSupervisor({
      client,
      nome,
      email,
      senha,
      cpf,
      cd_supervisor,
      criado_por: userId
      });
    }

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Supervisor e usuário cadastrados com sucesso!',
      cd_supervisor
    });
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao cadastrar supervisor e usuário: ' + err.stack, 'supervisores');
    res.status(500).json({ erro: 'Erro ao cadastrar supervisor e usuário.' + err.stack });
  } finally {
    client.release();
  }
});


// GET - Listar supervisores por empresa
// GET - Listar supervisores por empresa
router.get('/empresa/listar/:cd_empresa', tokenOpcional, async (req, res) => {
  const { cd_empresa } = req.params;
  const { ativo, search } = req.query; // parâmetros opcionais
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10000;

  const valores = [cd_empresa];
  const filtros = ['cd_empresa = $1'];

  // 🔹 Filtro por nome (search)
  if (search) {
    const q = search.trim();
    if (q) {
      valores.push(`%${q}%`);
      filtros.push(`unaccent(LOWER(nome)) LIKE unaccent(LOWER($${valores.length}))`);
    }
  }

  // 🔹 Filtro por ativo (true/false)
  if (ativo !== undefined) {
    const ativoBool = String(ativo).trim().toLowerCase() === 'true';
    valores.push(ativoBool);
    filtros.push(`ativo = $${valores.length}`);
  }

  const where = `WHERE ${filtros.join(' AND ')}`;

  const baseQuery = `
    SELECT *
    FROM public.supervisor
    ${where}
    ORDER BY nome ASC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.supervisor
    ${where}
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.json(resultado);
  } catch (err) {
    logger.error('Erro ao listar supervisores: ' + err.stack, 'supervisores');
    res.status(500).json({ erro: 'Erro ao listar supervisores.' });
  }
});


// PUT - Alterar supervisor
// PUT - Alterar supervisor
router.put('/alterar/:cd_supervisor', tokenOpcional, async (req, res) => {
  const { cd_supervisor } = req.params;
  const { senha, cpf, email, nome } = req.body;

  const camposSupervisor = [
    'nome', 'cargo', 'email', 'ativo',
    'cd_empresa', 'cpf', 'cd_curso', 'numero_registro' // ✅ novo campo incluído
  ];

  const updateFields = [];
  const updateValues = [];

  camposSupervisor.forEach((campo) => {
    if (req.body[campo] !== undefined) {
      updateFields.push(`${campo} = $${updateValues.length + 1}`);
      updateValues.push(req.body[campo]);
    }
  });

  if (updateFields.length === 0 && !senha && !cpf && !email && !nome) {
    return res.status(400).json({ erro: 'Nenhum campo fornecido para atualização.' });
  }

  const userId = req.usuario?.cd_usuario || null;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  updateFields.push(`data_alteracao = $${updateValues.length + 1}`);
  updateValues.push(dataAtual);
  updateFields.push(`alterado_por = $${updateValues.length + 1}`);
  updateValues.push(userId);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Atualizar supervisor
    if (updateFields.length > 0) {
      const updateQuery = `
        UPDATE public.supervisor
        SET ${updateFields.join(', ')}
        WHERE cd_supervisor = $${updateValues.length + 1}
        RETURNING cd_supervisor;
      `;
      updateValues.push(cd_supervisor);
      const result = await client.query(updateQuery, updateValues);

      if (result.rowCount === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ erro: 'Supervisor não encontrado.' });
      }
    }

    // Atualizar usuário vinculado (se necessário)
    if (cpf || email || senha || nome) {
      const selectUserQuery = `SELECT * FROM usuarios WHERE cd_supervisor = $1 LIMIT 1`;
      const resultUser = await client.query(selectUserQuery, [cd_supervisor]);

      if (resultUser.rowCount > 0) {
        const usuario = resultUser.rows[0];
        const updates = [];
        const values = [];
        let senhaHash;

        if (cpf) {
          const novoLogin = cpf.replace(/[^\d]+/g, '');
          updates.push(`login = $${values.length + 1}`);
          values.push(novoLogin);
        }

        if (email) {
          updates.push(`email = $${values.length + 1}`);
          values.push(email);
        }

        if (nome) {
          updates.push(`nome = $${values.length + 1}`);
          values.push(nome);
        }

        if (senha) {
          senhaHash = await md5(senha);
          updates.push(`senha = $${values.length + 1}`);
          values.push(senhaHash);
        }

        updates.push(`data_alteracao = $${values.length + 1}`);
        values.push(dataAtual);
        updates.push(`alterado_por = $${values.length + 1}`);
        values.push(userId);

        const updateUserQuery = `
          UPDATE usuarios
          SET ${updates.join(', ')}
          WHERE cd_supervisor = $${values.length + 1}
        `;
        values.push(cd_supervisor);

        await client.query(updateUserQuery, values);
      }
    }

    await client.query('COMMIT');

    res.status(200).json({
      message: 'Supervisor e usuário atualizados com sucesso!',
      cd_supervisor
    });
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao atualizar supervisor e usuário: ' + err.stack, 'supervisores');
    res.status(500).json({ erro: 'Erro ao atualizar supervisor e usuário.' });
  } finally {
    client.release();
  }
});

module.exports = router;

