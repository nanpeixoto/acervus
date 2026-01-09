const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
const { cadastrarUsuarioEmpresa } = require('./usuario');
const md5 = require('md5');
 

// Função para limpar máscara do CNPJ
function limparCNPJ(cnpj) {
  return cnpj.replace(/[^\d]+/g, '');
}

router.post('/cadastrar', tokenOpcional, async (req, res) => {
  const {
    tipo_pessoa, // <--- novo campo
    cnpj,
    razao_social,
    nome_fantasia,
    site,
    tipo_inscricao,
    numero_inscricao,
    email,
    telefone,
    celular,
    observacao,
    taxa_pagamento_aprendiz,
    taxa_pagamento_estagio,
    cd_seguradora,
    senha,
    conteudo_html,
    cd_template_modelo
  } = req.body;

  const userId = req.usuario?.cd_usuario || null;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];
  const cnpjLimpo = limparCNPJ(cnpj);

  // ✅ Validação do tipo_pessoa
  const tipoPessoaUpper = (tipo_pessoa || '').trim().toUpperCase();
  if (!['FISICA', 'JURIDICA'].includes(tipoPessoaUpper)) {
    return res.status(400).json({ erro: 'Tipo de pessoa inválido. Use FISICA ou JURIDICA.' });
  }

  // Validar senha
  if (!req.body.senha) {
    return res.status(400).json({ erro: 'Senha é obrigatória.' });
  }

  let senhaHash;
  try {
    senhaHash = await md5(req.body.senha);
  } catch (err) {
    logger.error('Erro ao gerar hash da senha: ' + err.stack, 'empresa');
    return res.status(500).json({ erro: 'Erro ao processar senha.' });
  }

  // Verificar duplicidade do CNPJ
  try {
    const checkQuery = `
      SELECT 1 FROM empresa
      WHERE REPLACE(REPLACE(REPLACE(cnpj, '.', ''), '/', ''), '-', '') = $1
      LIMIT 1
    `;
    const check = await pool.query(checkQuery, [cnpjLimpo]);
    if (check.rowCount > 0) {
      return res.status(409).json({ erro: 'CNPJ já cadastrado.' });
    }
  } catch (e) {
    logger.error('Erro ao verificar CNPJ: ' + e.stack, 'empresa');
    return res.status(500).json({ erro: 'Erro ao verificar CNPJ.' });
  }

  const obrigatorios = [
    { campo: 'CNPJ', valor: cnpj },
    { campo: 'Razão Social', valor: razao_social },
    { campo: 'Nome Fantasia', valor: nome_fantasia },
    { campo: 'Email', valor: email },
    { campo: 'Tipo de Pessoa', valor: tipo_pessoa }
  ];

  const faltando = obrigatorios.filter(f => !f.valor);
  if (faltando.length > 0) {
    return res.status(400).json({
      erro: `Campos obrigatórios não fornecidos: ${faltando.map(f => f.campo).join(', ')}`
    });
  }

  const client = await pool.connect();
  await client.query('BEGIN');

  const insertQuery = `
    INSERT INTO empresa (
      tipo_pessoa, cnpj, razao_social, nome_fantasia, site,
      tipo_inscricao, numero_inscricao, email, telefone, celular,
      observacao, taxa_pagamento_aprendiz, taxa_pagamento_estagio,
      cd_seguradora, criado_por, data_criacao, senha,
      conteudo_html, cd_template_modelo
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)
    RETURNING cd_empresa;
  `;

  const valores = [
    tipoPessoaUpper,
    cnpj, razao_social, nome_fantasia, site,
    tipo_inscricao, numero_inscricao, email, telefone, celular,
    observacao, taxa_pagamento_aprendiz, taxa_pagamento_estagio,
    cd_seguradora, userId, dataAtual, senhaHash,
    conteudo_html, cd_template_modelo
  ];

  try {
    const result = await client.query(insertQuery, valores);
    const cd_empresa = result.rows[0].cd_empresa;

    await cadastrarUsuarioEmpresa({
      client,
      nome: razao_social,
      email,
      senha,
      cnpj,
      cd_empresa,
      criado_por: userId
    });

    await client.query('COMMIT');
    res.status(201).json({ mensagem: 'Empresa cadastrada com sucesso!', cd_empresa });
  } catch (e) {
    await client.query('ROLLBACK');
    logger.error('Erro ao cadastrar empresa e usuário: ' + e.stack, 'empresa');
    res.status(500).json({ erro: 'Erro ao cadastrar empresa e usuário.' });
  } finally {
    client.release();
  }
});


router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const {
    cnpj,
    razao_social,
    nome_fantasia,
    site,
    tipo_inscricao,
    numero_inscricao,
    email,
    telefone,
    celular,
    observacao,
    taxa_pagamento_aprendiz,
    taxa_pagamento_estagio,
    cd_seguradora,
    senha, 
     conteudo_html,
    cd_template_modelo, 
  } = req.body;


  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  const updateFields = [];
  const updateValues = [];

   

  // CNPJ duplicado (se foi alterado)
  if (cnpj) {
    const cnpjLimpo = cnpj.replace(/[^\d]+/g, '');
    try {
      const checkCNPJ = `
        SELECT 1 FROM empresa
        WHERE REPLACE(REPLACE(REPLACE(cnpj, '.', ''), '/', ''), '-', '') = $1
        AND cd_empresa != $2
        LIMIT 1
      `;
      const cnpjCheck = await pool.query(checkCNPJ, [cnpjLimpo, id]);
     /* if (cnpjCheck.rowCount > 0) {
        return res.status(409).json({ erro: 'CNPJ já cadastrado em outra empresa.' });
      } */
    } catch (err) {
      logger.error('Erro ao verificar CNPJ: ' + err.stack, 'empresa');
      return res.status(500).json({ erro: 'Erro ao verificar CNPJ.' });
    }
    updateFields.push(`cnpj = $${updateValues.length + 1}`);
    updateValues.push(cnpj);
  }

// Se a senha foi enviada, precisamos atualizar a senha do usuário com login igual ao CNPJ da empresa
if (senha && senha.trim() !== '') {
  try {
    // Buscar o CNPJ atual da empresa se não foi enviado no corpo
    let cnpjUsuario = cnpj;
    if (!cnpjUsuario) {
      const buscaCNPJQuery = `SELECT cnpj FROM empresa WHERE cd_empresa = $1 LIMIT 1`;
      const resultadoBusca = await pool.query(buscaCNPJQuery, [id]);

      if (resultadoBusca.rowCount === 0) {
        return res.status(404).json({ erro: 'Empresa não encontrada para atualizar a senha do usuário.' });
      }

      cnpjUsuario = resultadoBusca.rows[0].cnpj;
    }

    // Limpar o CNPJ para ser compatível com o login do usuário
    const cnpjLogin = cnpjUsuario.replace(/[^\d]+/g, '');

    // Verifica se o usuário existe
    const buscaUsuarioQuery = `SELECT 1 FROM public.usuarios WHERE login = $1 LIMIT 1`;
    const usuarioExiste = await pool.query(buscaUsuarioQuery, [cnpjLogin]);

    const senhaHash = await md5(senha);

    if (usuarioExiste.rowCount > 0) {
      // Usuário existe, atualiza a senha
      const updateUserQuery = `
        UPDATE public.usuarios
        SET senha = $1, data_alteracao = $2, alterado_por = $3
        WHERE login = $4
      `;
      await pool.query(updateUserQuery, [senhaHash, dataAtual, userId, cnpjLogin]);
    } else {
      // Usuário não existe, cria o usuário
      await cadastrarUsuarioEmpresa({
        client: pool,
        nome: razao_social,
        email,
        senha,
        cnpj: cnpjUsuario,
        cd_empresa: id,
        criado_por: userId
      });
    }
  } catch (err) {
    logger.error('Erro ao atualizar/criar usuário vinculado à empresa: ' + err.stack, 'empresa');
    //informar motivo do erro 
    return res.status(500).json({ erro: 'Erro ao atualizar/criar o usuário.' + err.stack });
  }
}


  // Validar seguradora
  if (cd_seguradora) {
    try {
      const checkSeg = `
        SELECT 1 FROM seguradora
        WHERE cd_seguradora = $1 AND ativo = true
        LIMIT 1
      `;
      const segCheck = await pool.query(checkSeg, [cd_seguradora]);
      if (segCheck.rowCount === 0) {
        return res.status(400).json({ erro: 'Seguradora inválida ou inativa.' });
      }
      updateFields.push(`cd_seguradora = $${updateValues.length + 1}`);
      updateValues.push(cd_seguradora);
    } catch (err) {
      logger.error('Erro ao validar seguradora: ' + err.stack, 'empresa');
      return res.status(500).json({ erro: 'Erro ao validar seguradora.' });
    }
  }

  // Campos dinâmicos
  const campos = {
    razao_social,
    nome_fantasia,
    site,
    tipo_inscricao,
    numero_inscricao,
    email,
    telefone,
    celular,
    observacao,
    taxa_pagamento_aprendiz,
    taxa_pagamento_estagio,
    conteudo_html,
    cd_template_modelo
  };

  for (const [campo, valor] of Object.entries(campos)) {
    if (typeof valor !== 'undefined') {
      updateFields.push(`${campo} = $${updateValues.length + 1}`);
      updateValues.push(valor);
    }
  }

  // Auditoria
  updateFields.push(`data_alteracao = $${updateValues.length + 1}`);
  updateValues.push(dataAtual);
  updateFields.push(`alterado_por = $${updateValues.length + 1}`);
  updateValues.push(userId);

  // ✅ Atualizar tipo_pessoa, se enviado
if (req.body.tipo_pessoa) {
  const tipoPessoaUpper = req.body.tipo_pessoa.trim().toUpperCase();
  if (!['FISICA', 'JURIDICA'].includes(tipoPessoaUpper)) {
    return res.status(400).json({ erro: 'Tipo de pessoa inválido. Use FISICA ou JURIDICA.' });
  }
  updateFields.push(`tipo_pessoa = $${updateValues.length + 1}`);
  updateValues.push(tipoPessoaUpper);
}

  updateValues.push(id); // para o WHERE

  if (updateFields.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo enviado para atualização.' });
  }

  const updateQuery = `
    UPDATE empresa
    SET ${updateFields.join(', ')}
    WHERE cd_empresa = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(updateQuery, updateValues);
    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Empresa não encontrada.' });
    }
    res.json({
      mensagem: 'Empresa atualizada com sucesso!',
      empresa: result.rows[0]
    });
  } catch (err) {
    logger.error('Erro ao atualizar empresa: ' + err.stack, 'empresa');
    res.status(500).json({ erro: 'Erro ao atualizar empresa.' });
  }
});

router.get('/listar', verificarToken, listarEmpresas);
router.get('/buscar', verificarToken, listarEmpresas);

async function listarEmpresas(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { bloqueado, q } = req.query;

  const filtros = [];
  const valores = [];

 if (bloqueado !== undefined) {
  const bloqueadoBool = String(bloqueado).trim().toLowerCase() === 'true';
  valores.push(bloqueadoBool);
  filtros.push(`e.bloqueado = $${valores.length}`);
}

   

  if (q) {
     const qTrim = q.trim();
     if (/^\d+$/.test(qTrim)) {
    valores.push(parseInt(qTrim, 10));
    filtros.push(`e.cd_empresa = $${valores.length}`);
  } else {

      valores.push(`%${q}%`);
      filtros.push(`(
        unaccent(e.razao_social) ILIKE unaccent($${valores.length}) OR
        unaccent(e.nome_fantasia) ILIKE unaccent($${valores.length}) OR
        REPLACE(REPLACE(REPLACE(e.cnpj, '.', ''), '/', ''), '-', '') ILIKE REPLACE(REPLACE(REPLACE($${valores.length}, '.', ''), '/', ''), '-', '')
      )`);
    }
  }

  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM empresa e ${where}`;

  const baseQuery = `
    SELECT
      e.cd_empresa,
      e.razao_social,
      e.nome_fantasia,
      e.cnpj,
      e.site,
      e.tipo_inscricao,
      e.numero_inscricao,
      e.email,
      e.telefone,
      e.celular,
      e.observacao,
      e.taxa_pagamento_aprendiz,
      e.taxa_pagamento_estagio,
      e.cd_seguradora,
      e.bloqueado,
      e.criado_por,
      e.data_criacao,
      e.alterado_por,
      e.data_alteracao,
      s.nome_fantasia AS nome_seguradora
      , 
          CONCAT_WS(' ',
            endie.logradouro || ' - ' || endie.numero || ' - ' || endie.bairro || ' - ' ||
            endie.cidade || '/' || endie.uf
          ) AS endereco_completo , e.cd_template_modelo , e.tipo_pessoa
    FROM empresa e
    LEFT JOIN seguradora s ON s.cd_seguradora = e.cd_seguradora
     LEFT JOIN public.endereco endie
          ON endie.cd_empresa = e.cd_empresa
        AND endie.principal = true
        AND endie.ativo = true
    ${where}
    ORDER BY e.nome_fantasia
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json(resultado);
  } catch (err) {
    console.error('Erro ao listar empresas:', err);
    logger.error('Erro ao listar empresas: ' + err.stack, 'empresa');
    res.status(500).json({ erro: 'Erro ao listar empresas.'  + err.stack, 'empresa': 'empresa' });
  }
}

router.get('/dashboard/:cd_empresa', verificarToken, async (req, res) => {
  const client = await pool.connect();

  try {
       const cdEmpresa = req.params.cd_empresa;
    if (!cdEmpresa) {
         return res.status(400).json({ erro: 'Empresa é obrigatória para acessar o dashboard.' });
    }

    const sql = `
      SELECT
        (
          SELECT COUNT(*)
          FROM supervisor s
          WHERE s.cd_empresa = $1
            AND s.ativo = true
        ) AS total_supervisores,

        (
          SELECT COUNT(*)
          FROM contrato c
          WHERE c.cd_empresa = $1
            AND (c.aditivo IS NULL OR c.aditivo = false)
            AND c.status = 'A'
        ) AS total_contratos_ativos,

        (
          SELECT COUNT(*)
          FROM vaga v
          WHERE v.cd_empresa = $1
            AND v.status IN ('Em Andamento', 'Aberta')
        ) AS total_vagas_ativas
    `;

     
    //imprimir query 
    console.log('Query para dashboard empresa:', sql);

   const { rows } = await client.query(sql, [cdEmpresa]);

    const dados = rows[0];

    res.json({
      dados: {
        total_supervisores: Number(dados.total_supervisores),
        total_contratos_ativos: Number(dados.total_contratos_ativos),
        total_vagas_ativas: Number(dados.total_vagas_ativas)
      }
    });
  } catch (err) {
    console.error('Erro dashboard empresa:', err);
    res.status(500).json({ erro: 'Erro ao carregar dashboard', motivo: err.message });
  } finally {
    client.release();
  }
});



router.get('/buscar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT 
      e.cd_empresa,
      e.cnpj,
      e.razao_social,
      e.nome_fantasia,
      e.site,
      e.tipo_inscricao,
      e.numero_inscricao,
      e.email,
      e.telefone,
      e.celular,
      e.observacao,
      e.taxa_pagamento_aprendiz,
      e.taxa_pagamento_estagio,
      e.cd_seguradora,
      e.bloqueado,
      e.criado_por,
      e.data_criacao,
      e.alterado_por,
      e.data_alteracao,  
      e.conteudo_html,
      e.cd_template_modelo, 
      tm.nome,   e.tipo_pessoa
    FROM public.empresa e
     left join public.template_modelo tm ON tm.id_modelo = e.cd_template_modelo
    WHERE cd_empresa = $1
  `;

  try {
    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Empresa não encontrada.' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao buscar empresa por ID:', err);
    logger.error('Erro ao buscar empresa por ID: ' + err.stack, 'empresa');
    res.status(500).json({ erro: 'Erro ao buscar empresa.' });
  }
});


router.put('/bloquear/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { bloqueado } = req.body;

  if (typeof bloqueado === 'undefined') {
    return res.status(400).json({ erro: 'O campo "bloqueado" é obrigatório.' });
  }

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const queryEmpresa = `
      UPDATE public.empresa
      SET bloqueado = $1,
          data_alteracao = $2,
          alterado_por = $3
      WHERE cd_empresa = $4
      RETURNING cd_empresa, bloqueado;
    `;

    const result = await client.query(queryEmpresa, [bloqueado, dataAtual, userId, id]);

    if (result.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Empresa não encontrada.' });
    }

    // ✅ Atualiza usuários vinculados
    const queryUsuarios = `
      UPDATE public.usuarios
      SET ativo = $1,
        bloqueado = $2,
        data_alteracao = $3,
        alterado_por = $4
      WHERE cd_empresa = $5
    `;

    const novoStatusAtivo = bloqueado ? false : true;
    const novoStatusBloqueado = bloqueado ? true : false;

   

    const novoStatus = bloqueado ? false : true;

    await client.query(queryUsuarios, [novoStatusAtivo, novoStatusBloqueado, dataAtual, userId, id]);

    await client.query('COMMIT');

    res.json({
      mensagem: 'Status de bloqueio da empresa (e dos usuários) atualizado com sucesso!',
      empresa: result.rows[0]
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erro ao atualizar status de bloqueio da empresa:', err);
    logger.error('Erro ao atualizar status de bloqueio da empresa: ' + err.stack, 'empresa');
    res.status(500).json({ erro: 'Erro ao atualizar status de bloqueio da empresa e usuários.' });
  } finally {
    client.release();
  }
});


  
  
  
module.exports = router;