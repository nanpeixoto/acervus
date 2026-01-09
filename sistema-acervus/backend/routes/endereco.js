const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
 
router.post('/cadastrar', tokenOpcional, async (req, res) => {
  const {
    cep,
    logradouro,
    bairro,
    cidade,
    numero,
    complemento,
    telefone,
    codigo_ibge,
    ativo,
    principal,
    cd_instituicao_ensino,
    cd_candidato,
    cd_seguradora,
    cd_empresa, // ➕ novo campo para empresa
    uf
  } = req.body;

  console.log("Dados recebidos:", req.body);

  const endereco = {
    cep,
    logradouro,
    bairro,
    cidade,
    numero,
    complemento,
    telefone,
    codigo_ibge,
    ativo,
    principal,
    uf
  };

  try {
    const novoEndereco = await cadastrarEndereco(
      endereco,
      cd_candidato,
      req.usuario?.cd_usuario|| null ,
      cd_instituicao_ensino,
      cd_seguradora,
      cd_empresa // ➕ passa empresa
    );

    res.status(201).json({
      mensagem: 'Endereço cadastrado com sucesso!',
      id_endereco: novoEndereco.id_endereco
    });

  } catch (err) {
    console.error('Erro ao cadastrar endereço:', err.message);
    res.status(400).json({ erro: err.message });
  }
});

async function cadastrarEndereco(
  endereco,
  cd_candidato = null,
  cd_usuario = null,
  cd_instituicao_ensino = null,
  cd_seguradora = null,
  cd_empresa = null,
  client = pool
) {
  const {
    cep,
    logradouro,
    bairro,
    cidade,
    numero,
    complemento,
    telefone,
    codigo_ibge,
    ativo,
    principal,
    uf
  } = endereco;

  const executor = client || pool;

  // 🔐 Verificação de vínculo obrigatório
  if (!cd_instituicao_ensino && !cd_candidato && !cd_seguradora && !cd_empresa) {
    throw new Error('É necessário informar cd_instituicao_ensino, cd_candidato, cd_seguradora ou cd_empresa:'
      +cd_instituicao_ensino+','+ cd_candidato+','+  cd_seguradora +','+  cd_empresa
    );
  }

  // 🛑 Verifica duplicidade de endereço ativo + principal para o vínculo
  if (ativo && principal) {
    let checkQuery = `SELECT 1 FROM public.endereco WHERE ativo = true AND principal = true`;
    const checkParams = [];

    if (cd_instituicao_ensino) {
      checkQuery += ' AND cd_instituicao_ensino = $1';
      checkParams.push(cd_instituicao_ensino);
    } else if (cd_candidato) {
      checkQuery += ' AND cd_candidato = $1';
      checkParams.push(cd_candidato);
    } else if (cd_seguradora) {
      checkQuery += ' AND cd_seguradora = $1';
      checkParams.push(cd_seguradora);
    } else if (cd_empresa) {
      checkQuery += ' AND cd_empresa = $1';
      checkParams.push(cd_empresa);
    }

    // Imprime a query e os parâmetros
    console.log('Query de verificação de duplicidade:', checkQuery, 'Parâmetros:', checkParams);
    logger.error('Query de verificação de duplicidade:', checkQuery, 'Parâmetros:', checkParams);
    const checkResult = await executor.query(checkQuery, checkParams);
    if (checkResult.rowCount > 0) {
      throw new Error('Já existe um endereço ativo e principal para este vínculo.');
    }
  }

  // ✅ Validação de campos obrigatórios
  const obrigatorios = [
    { campo: 'CEP', valor: cep },
    { campo: 'Logradouro', valor: logradouro },
    { campo: 'Bairro', valor: bairro },
    { campo: 'Cidade', valor: cidade },
    { campo: 'UF', valor: uf }
  ];

  const faltando = obrigatorios.filter(c => !c.valor);
  if (faltando.length > 0) {
    throw new Error(
      `Campos obrigatórios não fornecidos: ${faltando.map(c => c.campo).join(', ')}.`
    );
  }

  // 🧱 Montagem dinâmica da query
  const campos = [
    'cep', 'logradouro', 'numero', 'bairro', 'cidade',
    'complemento', 'telefone', 'codigo_ibge', 'ativo',
    'principal', 'uf'
  ];
  const valores = [
    cep, logradouro, numero, bairro, cidade,
    complemento, telefone, codigo_ibge, ativo,
    principal, uf
  ];

  if (cd_instituicao_ensino) {
    campos.push('cd_instituicao_ensino');
    valores.push(cd_instituicao_ensino);
  }

  if (cd_candidato) {
    campos.push('cd_candidato');
    valores.push(cd_candidato);
  }

  if (cd_seguradora) {
    campos.push('cd_seguradora');
    valores.push(cd_seguradora);
  }

  if (cd_empresa) {
    campos.push('cd_empresa');
    valores.push(cd_empresa);
  }

  campos.push('criado_por', 'data_criacao');
  valores.push(cd_usuario, new Date().toISOString().split('T').join(' ').split('.')[0]);

  const placeholders = valores.map((_, i) => `$${i + 1}`);

  const query = `
    INSERT INTO public.endereco (${campos.join(', ')})
    VALUES (${placeholders.join(', ')})
    RETURNING id_endereco;
  `;

  try {
    const result = await executor.query(query, valores);
    return result.rows[0];
  } catch (err) {
    logger.error('Erro ao inserir endereço: ' + err.stack, 'enderecos');
    throw new Error('Erro ao inserir endereço no banco de dados.');
  }
}


 router.get('/instituicao/listar/:cd_instituicao_ensino', tokenOpcional, async (req, res) => {
  const page = parseInt(req.query.page) || 1; // Página atual
  const limit = parseInt(req.query.limit) || 50; // Limite de registros por página
  const offset = (page - 1) * limit; // Deslocamento para a consulta SQL
  const { cd_instituicao_ensino } = req.params; // Recebe o código da instituição de ensino da URL

  console.log("Código da instituição de ensino:", cd_instituicao_ensino); // Log de depuração

  // Base query para buscar os endereços
  const baseQuery = `
    SELECT
      id_endereco,
      cep,
      logradouro,
      numero,
      bairro,
      cidade,
      complemento,
      telefone,
      codigo_ibge,
      ativo,
      principal,
      cd_instituicao_ensino,
      criado_por,
      data_criacao,
      data_alteracao,
      alterado_por, uf
    FROM public.endereco
    WHERE cd_instituicao_ensino = $1
    ORDER BY principal DESC, data_criacao DESC
  `;

  // Query para contar o total de endereços
  const countQuery = `
    SELECT COUNT(*) FROM public.endereco
    WHERE cd_instituicao_ensino = $1
  `;

  // Parâmetros de valores (filtro)
  const valores = [cd_instituicao_ensino];

  try {
    // Usando a função de paginização do helper
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);

    // Retorna os dados paginados
    res.json(resultado);

  } catch (err) {
    console.error('Erro ao buscar endereços:', err);
    logger.error('Erro ao buscar endereços: ' + err.stack, 'enderecos');
    res.status(500).json({ erro: 'Erro ao buscar endereços.' });
  }
});


router.get('/listarPorEmpresa/:id', tokenOpcional, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const offset = (page - 1) * limit;
  const { id } = req.params;

  console.log("Código da empresa:", id);

  const baseQuery = `
    SELECT
      id_endereco,
      cep,
      logradouro,
      numero,
      bairro,
      cidade,
      complemento,
      telefone,
      codigo_ibge,
      ativo,
      principal,
      cd_empresa,
      criado_por,
      data_criacao,
      data_alteracao,
      alterado_por,
      uf
    FROM public.endereco
    WHERE cd_empresa = $1
    ORDER BY principal DESC, data_criacao DESC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.endereco
    WHERE cd_empresa = $1
  `;

  const valores = [id];

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.json(resultado);
  } catch (err) {
    console.error('Erro ao buscar endereços da empresa:', err);
    logger.error('Erro ao buscar endereços da empresa: ' + err.stack, 'enderecos');
    res.status(500).json({ erro: 'Erro ao buscar endereços da empresa.' });
  }
});



router.get('/listar', verificarToken, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const offset = (page - 1) * limit;

  const { tipo, id } = req.query;

  if (!tipo || !id) {
    return res.status(400).json({ erro: 'Parâmetros obrigatórios: tipo e id.' });
  }

  // Determina o campo a ser usado com base no tipo
  let campo;
  if (tipo === 'instituicao') {
    campo = 'cd_instituicao_ensino';
  } else if (tipo === 'candidato') {
    campo = 'cd_candidato';
  } else {
    return res.status(400).json({ erro: 'Tipo inválido. Use "instituicao" ou "candidato".' });
  }

  const baseQuery = `
    SELECT
      id_endereco, cep, logradouro, numero, bairro, cidade, complemento, telefone,
      codigo_ibge, ativo, principal, cd_instituicao_ensino, cd_candidato,
      criado_por, data_criacao, data_alteracao, alterado_por, uf
    FROM public.endereco
    WHERE ${campo} = $1
    ORDER BY principal DESC, data_criacao DESC
  `;

  const countQuery = `
    SELECT COUNT(*) FROM public.endereco
    WHERE ${campo} = $1
  `;

  const valores = [id];

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.json(resultado);
  } catch (err) {
    console.error('Erro ao buscar endereços:', err);
    logger.error('Erro ao buscar endereços: ' + err.stack, 'enderecos');
    res.status(500).json({ erro: 'Erro ao buscar endereços.' });
  }
});



router.put('/alterar/:id_endereco', tokenOpcional, async (req, res) => {
  const { id_endereco } = req.params;
  const endereco = req.body;

  try {
    const resultado = await alterarEndereco(
      endereco,
      id_endereco,
      req.usuario?.cd_usuario || null
    );

    res.status(200).json({
      message: 'Endereço atualizado com sucesso!',
      id_endereco: resultado.id_endereco
    });

  } catch (err) {
    console.error('Erro ao atualizar endereço:', err);
    logger.error('Erro ao atualizar endereço: ' + err.stack, 'enderecos');

    const status = err.message.includes('não fornecidos') || err.message.includes('Já existe') ? 400 : 500;
    res.status(status).json({ erro: err.message });
  }
});

 async function alterarEndereco(
  endereco,
  id_endereco,
  cd_usuario = null,
  client = pool
) {
  const {
    cep,
    logradouro,
    numero,
    bairro,
    cidade,
    complemento,
    telefone,
    codigo_ibge,
    ativo,
    principal,
    uf,
    cd_instituicao_ensino,
    cd_candidato,
    cd_seguradora,
    cd_empresa // ✅ novo campo
  } = endereco;


   // 🔐 Verificação de vínculo obrigatório
  if (  !cd_seguradora && !cd_empresa && !cd_instituicao_ensino && !cd_candidato) {
    throw new Error('É necessário informar   cd_seguradora ou cd_empresa ou cd_instituicao_ensino ou cd_candidato:'
       + cd_seguradora +','+  cd_empresa+','+cd_instituicao_ensino +','+cd_candidato
    );
  }

  if (!cep || !logradouro || !bairro || !cidade || !uf) {
    throw new Error('Campos obrigatórios não fornecidos: cep, logradouro, bairro, cidade, uf.');
  }

  if (!id_endereco) {
    throw new Error('ID do endereço é obrigatório para alteração.');
  }

  // 🔍 Verificação de duplicidade de principal ativo para o mesmo vínculo
  if (ativo && principal) {
    let checkQuery = `
      SELECT COUNT(*) FROM public.endereco
      WHERE ativo = true AND principal = true
        AND id_endereco <> $1
    `;
    const checkParams = [id_endereco];

    if (cd_instituicao_ensino) {
      checkQuery += ' AND cd_instituicao_ensino = $2';
      checkParams.push(cd_instituicao_ensino);
    } else if (cd_candidato) {
      checkQuery += ' AND cd_candidato = $2';
      checkParams.push(cd_candidato);
    } else if (cd_seguradora) {
      checkQuery += ' AND cd_seguradora = $2';
      checkParams.push(cd_seguradora);
    } else if (cd_empresa) {
      checkQuery += ' AND cd_empresa = $2';
      checkParams.push(cd_empresa);
    }

     console.log('Query de verificação de duplicidade:', checkQuery, 'Parâmetros:', checkParams);
     

    const result = await client.query(checkQuery, checkParams);
    if (parseInt(result.rows[0].count) > 0) {
      throw new Error('Já existe um endereço ativo e principal para este vínculo.');
    }
  }

  // 🧱 Campos que serão atualizados
  const campos = [
    'cep', 'logradouro', 'numero', 'bairro', 'cidade',
    'complemento', 'telefone', 'codigo_ibge',
    'ativo', 'principal', 'uf',
    'data_alteracao', 'alterado_por'
  ];
  const valores = [
    cep, logradouro, numero, bairro, cidade,
    complemento, telefone, codigo_ibge,
    ativo, principal, uf,
    new Date().toISOString().split('T').join(' ').split('.')[0],
    cd_usuario
  ];

  const setQuery = campos.map((campo, idx) => `${campo} = $${idx + 1}`).join(', ');

  const updateQuery = `
    UPDATE public.endereco
    SET ${setQuery}
    WHERE id_endereco = $${valores.length + 1}
    RETURNING id_endereco;
  `;

  try {
    const result = await client.query(updateQuery, [...valores, id_endereco]);
    if (result.rowCount === 0) {
      throw new Error('Endereço não encontrado.');
    }

    return result.rows[0];
  } catch (err) {
    logger.error('Erro ao alterar endereço: ' + err.stack, 'enderecos');
    throw new Error('Erro ao alterar endereço no banco de dados.');
  }
}


module.exports = {
  router,
  cadastrarEndereco, 
  alterarEndereco
};