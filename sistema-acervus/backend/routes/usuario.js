const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

const multer = require('multer');
const path = require('path');
const fs = require('fs');
const md5 = require('md5');

// ✅ CORREÇÃO: Remover app.use aqui - isso deve estar no arquivo principal
// app.use(express.json()); // Para application/json
// app.use(express.urlencoded({ extended: true })); // Para application/x-www-form-urlencoded

// Função para limpar máscara do CNPJ
function limparCNPJ(cnpj) {
  return cnpj.replace(/[^\d]+/g, '');
}

// Função para limpar CPF (remove pontos e traços)
function limparCPF(cpf) {
  return cpf.replace(/[^\d]+/g, '');
}

// ✅ ENDPOINT: Cadastrar usuário
router.post('/cadastrar', verificarToken, async (req, res) => {
  const {
    nome, login, email, senha, cpf, telefone, celular,
    perfil, observacao, ativo, recebe_email,
    cd_empresa, cd_instituicao_ensino, cd_supervisor
  } = req.body;

  const camposObrigatorios = [
    { campo: 'Nome', valor: nome },
    { campo: 'Login', valor: login },
    { campo: 'Email', valor: email },
    { campo: 'Senha', valor: senha },
    { campo: 'Perfil', valor: perfil }
  ];

  const camposFaltando = camposObrigatorios.filter(c => !c.valor);
  if (camposFaltando.length > 0) {
    return res.status(400).json({
      erro: `Campos obrigatórios ausentes: ${camposFaltando.map(c => c.campo).join(', ')}`
    });
  }

  // Validação de email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ erro: 'Email inválido.' });
  }

  // Validação de perfil
  const perfilValidos = ['ADMIN', 'COLABORADOR', 'ESTAGIARIO', 'EMPRESA', 'INSTITUICAO', 'JOVEM_APRENDIZ'];
  if (!perfilValidos.includes(perfil)) {
    return res.status(400).json({ erro: 'Perfil inválido.' });
  }

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Verificar duplicidade de login
    const verificarLogin = `SELECT 1 FROM usuarios WHERE login = $1`;
    const existeLogin = await client.query(verificarLogin, [login]);
    if (existeLogin.rowCount > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ erro: 'Já existe um usuário com esse login.' });
    }

    // Verificar duplicidade de email
    const verificarEmail = `SELECT 1 FROM usuarios WHERE email = $1`;
    const existeEmail = await client.query(verificarEmail, [email]);
    if (existeEmail.rowCount > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ erro: 'Já existe um usuário com esse email.' });
    }

    // Verificar duplicidade de CPF (se fornecido)
    if (cpf) {
      const verificarCPF = `SELECT 1 FROM usuarios WHERE cpf = $1`;
      const existeCPF = await client.query(verificarCPF, [cpf]);
      if (existeCPF.rowCount > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({ erro: 'Já existe um usuário com esse CPF.' });
      }
    }

    // Criptografar senha
    const senhaHash = md5(senha);

    const query = `
      INSERT INTO usuarios (
        nome, login, email, senha, cpf, telefone, celular,
        perfil, observacao, ativo, bloqueado, recebe_email,
        cd_empresa, cd_instituicao_ensino, cd_supervisor,
        criado_por, data_criacao
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17
      ) RETURNING cd_usuario;
    `;

    const values = [
      nome.trim(),
      login.trim().toLowerCase(),
      email.trim().toLowerCase(),
      senhaHash,
      cpf || null,
      telefone || null,
      celular || null,
      perfil,
      observacao || null,
      ativo ?? true,
      false, // bloqueado = false por padrão
      recebe_email ?? true,
      cd_empresa || null,
      cd_instituicao_ensino || null,
      cd_supervisor || null,
      userId,
      dataAtual
    ];

    const result = await client.query(query, values);
    const idUsuario = result.rows[0].cd_usuario;

    await client.query('COMMIT');
    
    res.status(201).json({ 
      mensagem: 'Usuário cadastrado com sucesso!', 
      cd_usuario: idUsuario 
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao cadastrar usuário: ' + err.stack, 'usuario');
    res.status(500).json({ erro: 'Erro interno ao cadastrar usuário.', motivo: err.message });
  } finally {
    client.release();
  }
});

// ✅ ENDPOINT: Alterar usuário
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const {
    nome, login, email, senha, cpf, telefone, celular,
    perfil, observacao, ativo, bloqueado, recebe_email,
    cd_empresa, cd_instituicao_ensino, cd_supervisor
  } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Verificar se usuário existe
    const verificarUsuario = `SELECT 1 FROM usuarios WHERE cd_usuario = $1`;
    const usuarioExiste = await client.query(verificarUsuario, [id]);
    if (usuarioExiste.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }

    // Validação de duplicidade de login apenas se for enviado um novo login
    if (login) {
      const existe = await client.query(
        `SELECT 1 FROM usuarios WHERE login = $1 AND cd_usuario <> $2`,
        [login.trim().toLowerCase(), id]
      );
      if (existe.rowCount > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({ erro: 'Já existe um usuário cadastrado com este login.' });
      }
    }

    // Validação de duplicidade de email apenas se for enviado um novo email
    if (email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ erro: 'Email inválido.' });
      }

      const existe = await client.query(
        `SELECT 1 FROM usuarios WHERE email = $1 AND cd_usuario <> $2`,
        [email.trim().toLowerCase(), id]
      );
      if (existe.rowCount > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({ erro: 'Já existe um usuário cadastrado com este email.' });
      }
    }

    // Validação de duplicidade de CPF apenas se for enviado um novo CPF
    if (cpf) {
      const existe = await client.query(
        `SELECT 1 FROM usuarios WHERE cpf = $1 AND cd_usuario <> $2`,
        [cpf, id]
      );
      if (existe.rowCount > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({ erro: 'Já existe um usuário cadastrado com este CPF.' });
      }
    }

    // Validação de perfil
    if (perfil) {
      const perfilValidos = ['ADMIN', 'COLABORADOR', 'ESTAGIARIO', 'EMPRESA', 'INSTITUICAO', 'JOVEM_APRENDIZ'];
      if (!perfilValidos.includes(perfil)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ erro: 'Perfil inválido.' });
      }
    }

    // Construção dinâmica do update
    const campos = [];
    const valores = [];
    let idx = 1;

    const adicionarCampo = (campo, valor) => {
      campos.push(`${campo} = $${idx++}`);
      valores.push(valor);
    };

    if (nome) adicionarCampo('nome', nome.trim());
    if (login) adicionarCampo('login', login.trim().toLowerCase());
    if (email) adicionarCampo('email', email.trim().toLowerCase());
    if (cpf !== undefined) adicionarCampo('cpf', cpf || null);
    if (telefone !== undefined) adicionarCampo('telefone', telefone || null);
    if (celular !== undefined) adicionarCampo('celular', celular || null);
    if (perfil) adicionarCampo('perfil', perfil);
    if (observacao !== undefined) adicionarCampo('observacao', observacao || null);
    if (ativo !== undefined) adicionarCampo('ativo', ativo);
    if (bloqueado !== undefined) adicionarCampo('bloqueado', bloqueado);
    if (recebe_email !== undefined) adicionarCampo('recebe_email', recebe_email);
    if (cd_empresa !== undefined) adicionarCampo('cd_empresa', cd_empresa || null);
    if (cd_instituicao_ensino !== undefined) adicionarCampo('cd_instituicao_ensino', cd_instituicao_ensino || null);
    if (cd_supervisor !== undefined) adicionarCampo('cd_supervisor', cd_supervisor || null);

    // Criptografar nova senha se fornecida
    if (senha) {
      const senhaHash = await md5(senha);
      adicionarCampo('senha', senhaHash);
    }

    adicionarCampo('alterado_por', userId);
    adicionarCampo('data_alteracao', dataAtual);

    if (campos.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ erro: 'Nenhum campo enviado para alteração.' });
    }

    const query = `
      UPDATE usuarios
      SET ${campos.join(', ')}
      WHERE cd_usuario = $${idx}
      RETURNING cd_usuario, nome, login, email, cpf, telefone, celular, 
                perfil, observacao, ativo, bloqueado, recebe_email,
                cd_empresa, cd_instituicao_ensino, cd_supervisor,
                data_criacao, data_alteracao;
    `;

    valores.push(id);

    const result = await client.query(query, valores);

    await client.query('COMMIT');

    res.status(200).json({
      mensagem: 'Usuário alterado com sucesso!',
      usuario: result.rows[0]
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao alterar usuário: ' + err.stack, 'usuario');
    res.status(500).json({ erro: 'Erro ao alterar usuário.', motivo: err.message });
  } finally {
    client.release();
  }
});

// ✅ ENDPOINT: Listar usuários (com paginação e filtros)
router.get('/listar', tokenOpcional, listarUsuarios);
router.get('/buscar', tokenOpcional, listarUsuarios);

async function listarUsuarios(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, perfil, q, search } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true');
    filtros.push(`u.ativo = $${valores.length}`);
  }

  if (perfil) {
    valores.push(perfil);
    filtros.push(`u.perfil = $${valores.length}`);
  }

  // Busca textual (compatível com search e q)
  const termoBusca = search || q;
  if (termoBusca) {
    valores.push(`%${termoBusca}%`);
    filtros.push(`(
      unaccent(u.nome) ILIKE unaccent($${valores.length}) OR
      unaccent(u.login) ILIKE unaccent($${valores.length}) OR
      unaccent(u.email) ILIKE unaccent($${valores.length}) OR
      u.cpf ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM usuarios u ${where}`;

  const baseQuery = `
    SELECT
      u.cd_usuario,
      u.nome,
      u.login,
      u.email,
      u.cpf,
      u.telefone,
      u.celular,
      u.perfil,
      u.observacao,
      u.ativo,
      u.bloqueado,
      u.recebe_email,
      u.cd_empresa,
      u.cd_instituicao_ensino,
      u.cd_supervisor,
      u.criado_por,
      u.data_criacao,
      u.data_alteracao,
      u.alterado_por

    FROM usuarios u
    ${where}
    ORDER BY u.nome
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);

    // Mapear dados para compatibilidade com o frontend
    const dadosFormatados = resultado.dados.map(row => ({
      id: row.cd_usuario,
      cd_usuario: row.cd_usuario,
      nome: row.nome,
      login: row.login,
      email: row.email,
      cpf: row.cpf,
      telefone: row.telefone,
      celular: row.celular,
      perfil: row.perfil,
      observacao: row.observacao,
      ativo: row.ativo,
      bloqueado: row.bloqueado,
      recebe_email: row.recebe_email,
      cd_empresa: row.cd_empresa,
      cd_instituicao_ensino: row.cd_instituicao_ensino,
      cd_supervisor: row.cd_supervisor,
      criado_por: row.criado_por,
      data_criacao: row.data_criacao,
      data_alteracao: row.data_alteracao,
      alterado_por: row.alterado_por
    }));

    res.status(200).json({
      usuarios: dadosFormatados, // Para compatibilidade com o service do frontend
      dados: dadosFormatados,     // Para compatibilidade geral
      pagination: resultado.pagination
    });

  } catch (err) {
    console.error('Erro ao listar usuários:', err);
    logger.error('Erro ao listar usuários: ' + err.stack, 'usuario');
    res.status(500).json({ erro: 'Erro ao listar usuários.' });
  }
}

// ✅ ENDPOINT: Buscar usuário por ID
router.get('/buscar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT
      u.cd_usuario,
      u.nome,
      u.login,
      u.email,
      u.cpf,
      u.telefone,
      u.celular,
      u.perfil,
      u.observacao,
      u.ativo,
      u.bloqueado,
      u.recebe_email,
      u.cd_empresa,
      u.cd_instituicao_ensino,
      u.cd_supervisor,
      u.criado_por,
      u.data_criacao,
      u.data_alteracao,
      u.alterado_por

    FROM usuarios u
    WHERE u.cd_usuario = $1
  `;

  try {
    const result = await pool.query(query, [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }

    const usuario = result.rows[0];

    // Mapear para compatibilidade com o frontend
    const resposta = {
      id: usuario.cd_usuario,
      cd_usuario: usuario.cd_usuario,
      nome: usuario.nome,
      login: usuario.login,
      email: usuario.email,
      cpf: usuario.cpf,
      telefone: usuario.telefone,
      celular: usuario.celular,
      perfil: usuario.perfil,
      observacao: usuario.observacao,
      ativo: usuario.ativo,
      bloqueado: usuario.bloqueado,
      recebe_email: usuario.recebe_email,
      cd_empresa: usuario.cd_empresa,
      cd_instituicao_ensino: usuario.cd_instituicao_ensino,
      cd_supervisor: usuario.cd_supervisor,
      criado_por: usuario.criado_por,
      data_criacao: usuario.data_criacao,
      data_alteracao: usuario.data_alteracao,
      alterado_por: usuario.alterado_por
    };

    res.status(200).json(resposta);
  } catch (err) {
    console.error('Erro ao buscar usuário por ID:', err);
    logger.error('Erro ao buscar usuário: ' + err.stack, 'usuario');
    res.status(500).json({ erro: 'Erro ao buscar usuário.' });
  }
});

// ✅ ENDPOINT: Estatísticas dos usuários
router.get('/estatisticas', verificarToken, async (req, res) => {
  try {
    const query = `
      SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN ativo = true THEN 1 END) as ativos,
        COUNT(CASE WHEN ativo = false THEN 1 END) as inativos,
        COUNT(CASE WHEN bloqueado = true THEN 1 END) as bloqueados,
        COUNT(CASE WHEN perfil = 'ADMIN' THEN 1 END) as admins,
        COUNT(CASE WHEN perfil = 'COLABORADOR' THEN 1 END) as colaboradores,
        COUNT(CASE WHEN perfil = 'ESTAGIARIO' THEN 1 END) as estagiarios,
        COUNT(CASE WHEN perfil = 'EMPRESA' THEN 1 END) as empresas,
        COUNT(CASE WHEN perfil = 'INSTITUICAO' THEN 1 END) as instituicoes,
        COUNT(CASE WHEN perfil = 'JOVEM_APRENDIZ' THEN 1 END) as jovens_aprendizes,
        COUNT(CASE WHEN data_criacao >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as criados_ultimo_mes
      FROM usuarios
    `;

    const result = await pool.query(query);
    const stats = result.rows[0];

    res.status(200).json({
      total: parseInt(stats.total),
      ativos: parseInt(stats.ativos),
      inativos: parseInt(stats.inativos),
      bloqueados: parseInt(stats.bloqueados),
      criadosEsteMes: parseInt(stats.criados_ultimo_mes),
      porTipo: {
        admin: parseInt(stats.admins),
        colaborador: parseInt(stats.colaboradores),
        estagiario: parseInt(stats.estagiarios),
        empresa: parseInt(stats.empresas),
        instituicao: parseInt(stats.instituicoes),
        jovemAprendiz: parseInt(stats.jovens_aprendizes)
      }
    });

  } catch (err) {
    logger.error('Erro ao buscar estatísticas: ' + err.stack, 'usuario');
    res.status(500).json({ erro: 'Erro ao buscar estatísticas.' });
  }
});

// ✅ Função para cadastrar usuário empresa
async function cadastrarUsuarioEmpresa({
  client,
  nome,
  email,
  senha,
  cnpj,
  cd_empresa,
  criado_por,
  data_criacao = new Date().toISOString().split('T').join(' ').split('.')[0]
}) {
  if (!client) {
    throw new Error('Database client não fornecido para cadastrarUsuarioEmpresa.');
  }
  try {
    const perfil = 'EMPRESA'; // ✅ CORREÇÃO: usar perfil padrão do enum
    const login = limparCNPJ(cnpj); // remove pontos, traços e barra

    // Verifica se já existe login/email
    const checkQuery = `
      SELECT cd_usuario FROM usuarios
      WHERE login = $1  
      LIMIT 1;
    `;
    const existing = await client.query(checkQuery, [login]);
    if (existing.rowCount > 0) {
      throw new Error('Já existe um usuário com este CNPJ ou e-mail.');
    }

    const senhaHash = await md5(senha);

    const insertQuery = `
      INSERT INTO usuarios (
        nome, login, email, senha, perfil, ativo,
        data_criacao, criado_por, cd_empresa
      )
      VALUES ($1, $2, $3, $4, $5, true, $6, $7, $8)
      RETURNING cd_usuario;
    `;

    const values = [
      nome, login, email, senhaHash, perfil, data_criacao, criado_por, cd_empresa
    ];

    const result = await client.query(insertQuery, values);
    return { cd_usuario: result.rows[0].cd_usuario };
   } catch (error) {
    // Mensagem amigável para o cliente final
    if (error.message.includes('Já existe')) {
      throw { status: 400, message: error.message };
    }
    if (error.message.includes('duplicate key value')) {
      throw { status: 400, message: 'Já existe um usuário com este e-mail ou login.' };
    }
    logger.error('Erro ao cadastrar usuário empresa: ' + error.message, 'usuario_empresa');
    throw { status: 500, message: 'Erro ao cadastrar usuário da empresa.' + error.message };
  }
}

// ✅ Função para cadastrar usuário supervisor
async function cadastrarUsuarioSupervisor({
  client,
  nome,
  email,
  senha,
  cpf,
  cd_supervisor,
  criado_por,
  data_criacao = new Date().toISOString().split('T').join(' ').split('.')[0]
}) {
  try {
    const perfil = 'SUPERVISOR'; // ✅ CORREÇÃO: usar perfil padrão do enum
    const login = limparCPF(cpf);

    // Verificar se já existe login com esse CPF
    const checkQuery = `
      SELECT cd_usuario FROM usuarios
      WHERE login = $1
      LIMIT 1;
    `;
    const existing = await client.query(checkQuery, [login]);
    if (existing.rowCount > 0) {
      throw new Error('Já existe um usuário com este CPF.');
    }

    const senhaHash = await md5(senha);

    const insertQuery = `
      INSERT INTO usuarios (
        nome, login, email, senha, perfil, ativo,
        data_criacao, criado_por, cd_supervisor
      )
      VALUES ($1, $2, $3, $4, $5, true, $6, $7, $8)
      RETURNING cd_usuario;
    `;

    const values = [
      nome, login, email, senhaHash, perfil, data_criacao, criado_por, cd_supervisor
    ];

    const result = await client.query(insertQuery, values);
    return { cd_usuario: result.rows[0].cd_usuario };
  } catch (error) {
    logger.error('Erro ao cadastrar usuário supervisor: ' + error.message, 'usuario_supervisor');
    throw error;
  }
}

module.exports = {
  router,
  cadastrarUsuarioEmpresa,
  cadastrarUsuarioSupervisor
};