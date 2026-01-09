  const express = require('express');
  const router = express.Router();
  const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
  const logger = require('../utils/logger');
  const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
 

  

// Sua rota de cadastro de instituição
  router.post('/cadastrar', tokenOpcional, async (req, res) => {
    const { 
    cnpj,
    razao_social,
    nome_fantasia,
    sigla,
    site,
    tipo_ie,
    nivel_ie,
    ie_formadora,
    isento,
    tipo_inscricao,
    numero_inscricao, 
    mantenedora,
    campus,
    telefone,
    celular,
    observacao,
    aguardar_ie_para_assinar = false,
    acesso_contratos = false,
    bloqueado = false,
    conteudo_html,
    cd_template_modelo, 
    } = req.body;

    console.log("Dados recebidos:", req.body);  // Log de depuração


    // Remove a máscara do CNPJ
    const cnpjSemMascara = cnpj.replace(/[./-]/g, '');
    console.log("CNPJ sem máscara:", cnpjSemMascara);  // Log de depuração

    // Verifica se o CNPJ já existe
     /* try {
      const checkCnpjQuery = 'SELECT 1 FROM public.instituicao_ensino WHERE REPLACE(REPLACE(REPLACE(cnpj, \'.\', \'\'), \'/\', \'\'), \'-\', \'\') = $1 LIMIT 1';
       console.log("checkCnpjQuery: ", checkCnpjQuery);  // Log de depuração
      const checkCnpjResult = await pool.query(checkCnpjQuery, [cnpjSemMascara]);
    if (checkCnpjResult.rowCount > 0) {
        return res.status(409).json({ erro: 'CNPJ já cadastrado.' });
      }
    } catch (err) {
      console.error('Erro ao verificar CNPJ:', err);
      return res.status(500).json({ erro: 'Erro ao verificar CNPJ.' });
    }*/

    // Campos obrigatórios
    const camposObrigatorios = [
      { campo: 'CNPJ', valor: cnpj },
      { campo: 'Razão Social', valor: razao_social },
      { campo: 'Nome Fantasia', valor: nome_fantasia }
    ];

    // Verifica se todos os campos obrigatórios estão presentes
    const camposFaltando = camposObrigatorios.filter(campo => !campo.valor);

    if (camposFaltando.length > 0) {
      const camposFaltandoTexto = camposFaltando.map(campo => campo.campo).join(', ');
      return res.status(400).json({ 
        erro: `Campos obrigatórios não fornecidos: ${camposFaltandoTexto}. Por favor, forneça todos os campos obrigatórios.` 
      });
    }

    

    const userId =req.usuario?.cd_usuario || null ;  // Acesso ao ID do usuário do token

    // Atualização de data e usuário
  const dataAtual = new Date();
  const dataHoraFormatada = dataAtual.toISOString().split('T').join(' ').split('.')[0];
  

    const query = `
    INSERT INTO public.instituicao_ensino (
      cnpj, razao_social, nome_fantasia, sigla, site, tipo_ie, nivel_ie, ie_formadora, isento, tipo_inscricao
      , numero_inscricao, campus, telefone, celular, observacao, criado_por, data_criacao
       , aguardar_ie_para_assinar, acesso_contratos, mantenedora, bloqueado, conteudo_html, cd_template_modelo
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23)
    RETURNING cd_instituicao_ensino;
  `;

    const values = [
       cnpj, razao_social, nome_fantasia, sigla, site, tipo_ie, nivel_ie, ie_formadora, isento, tipo_inscricao
      , numero_inscricao, campus, telefone, celular, observacao, userId, dataHoraFormatada
      , aguardar_ie_para_assinar, acesso_contratos, mantenedora, bloqueado, conteudo_html, cd_template_modelo
    ];


    try {
      const result = await pool.query(query, values);
      const newInstitution = result.rows[0];  // Retorna a instituição inserida
      res.status(201).json({
        message: 'Instituição inserida com sucesso!',
        cd_instituicao_ensino: newInstitution.cd_instituicao_ensino,
      });
    } catch (err) {
      console.error('API::Erro ao inserir instituição:', err);
      logger.error('API::Erro ao inserir instituição: ' + err.stack, 'instituicoes');
      res.status(500).json({ erro: 'API::Erro ao inserir instituição ::'+err });
    }
  });


 
// Função para validar o CNPJ
function validarCNPJ(cnpj) {
  const cnpjLimpo = cnpj.replace(/[^\d]+/g, ''); // Remove tudo que não for número
  return cnpjLimpo.length === 14;
}


router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { 
    cnpj,
    razao_social,
    nome_fantasia,
    sigla,
    site,
    tipo_ie,
    nivel_ie,
    ie_formadora,
    isento,
    tipo_inscricao,
    numero_inscricao, 
    mantenedora,
    campus,
    telefone,
    celular,
    observacao,
    aguardar_ie_para_assinar,
    acesso_contratos,
    conteudo_html, cd_template_modelo
  } = req.body;

  // Validação básica
  //if (!razao_social || !nome_fantasia) {
  //  return res.status(400).json({ erro: 'Razão social e Nome fantasia são obrigatórios.' });
  //}

  if(cnpj && !validarCNPJ(cnpj)) {
    return res.status(400).json({ erro: 'CNPJ inválido.' });
  }

  const updateFields = [];
  const updateValues = [];

  if (cnpj) {
    updateFields.push(`cnpj = $${updateValues.length + 1}`);
    updateValues.push(cnpj);
  }
   if (cd_template_modelo) {
    updateFields.push(`cd_template_modelo = $${updateValues.length + 1}`);
    updateValues.push(cd_template_modelo);
  }
  if (razao_social) {
    updateFields.push(`razao_social = $${updateValues.length + 1}`);
    updateValues.push(razao_social);
  }
  if (nome_fantasia) {
    updateFields.push(`nome_fantasia = $${updateValues.length + 1}`);
    updateValues.push(nome_fantasia);
  }
  if (sigla) {
    updateFields.push(`sigla = $${updateValues.length + 1}`);
    updateValues.push(sigla);
  }
  if (site) {
    updateFields.push(`site = $${updateValues.length + 1}`);
    updateValues.push(site);
  }
  if (tipo_ie) {
    updateFields.push(`tipo_ie = $${updateValues.length + 1}`);
    updateValues.push(tipo_ie);
  }
  if (nivel_ie) {
    updateFields.push(`nivel_ie = $${updateValues.length + 1}`);
    updateValues.push(nivel_ie);
  }
  if (typeof ie_formadora !== 'undefined') {
    updateFields.push(`ie_formadora = $${updateValues.length + 1}`);
    updateValues.push(ie_formadora);
  }
  if (typeof isento !== 'undefined') {
    updateFields.push(`isento = $${updateValues.length + 1}`);
    updateValues.push(isento);
  }
  if (tipo_inscricao) {
    updateFields.push(`tipo_inscricao = $${updateValues.length + 1}`);
    updateValues.push(tipo_inscricao);
  }
  if (numero_inscricao) {
    updateFields.push(`numero_inscricao = $${updateValues.length + 1}`);
    updateValues.push(numero_inscricao);
  }
  if (conteudo_html !== undefined) {
  updateFields.push(`conteudo_html = $${updateValues.length + 1}`);
  updateValues.push(conteudo_html);
}

  if (mantenedora) {
    updateFields.push(`mantenedora = $${updateValues.length + 1}`);
    updateValues.push(mantenedora);
  }
  if (campus) {
    updateFields.push(`campus = $${updateValues.length + 1}`);
    updateValues.push(campus);
  }
  if (telefone) {
    updateFields.push(`telefone = $${updateValues.length + 1}`);
    updateValues.push(telefone);
  }
  if (celular) {
    updateFields.push(`celular = $${updateValues.length + 1}`);
    updateValues.push(celular);
  }
  if (observacao) {
    updateFields.push(`observacao = $${updateValues.length + 1}`);
    updateValues.push(observacao);
  }
  if (typeof aguardar_ie_para_assinar !== 'undefined') {
    updateFields.push(`aguardar_ie_para_assinar = $${updateValues.length + 1}`);
    updateValues.push(aguardar_ie_para_assinar);
  }
  if (typeof acesso_contratos !== 'undefined') {
    updateFields.push(`acesso_contratos = $${updateValues.length + 1}`);
    updateValues.push(acesso_contratos);
  }

  // Controle de alteração
  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  updateFields.push(`data_atualizacao = $${updateValues.length + 1}`);
  updateValues.push(dataAtual);

  updateFields.push(`atualizado_por = $${updateValues.length + 1}`);
  updateValues.push(userId);

  updateValues.push(id);

  if (updateFields.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo fornecido para atualização.' });
  }


  // Verifica se o CNPJ já existe
  if(cnpj) {
    try {

          // Remove a máscara do CNPJ
    const cnpjSemMascara = cnpj.replace(/[./-]/g, '');
    console.log("CNPJ sem máscara:", cnpjSemMascara);  // Log de depuração

       const checkQuery = `
    SELECT 1 FROM public.instituicao_ensino
    WHERE REPLACE(REPLACE(REPLACE(cnpj, '.', ''), '/', ''), '-', '') = $1
    AND cd_instituicao_ensino != $2
     AND duplicado_legado = false
    LIMIT 1
  `;
       console.log("checkCnpjQuery: ", checkQuery);  // Log de depuração
       const checkResult = await pool.query(checkQuery, [cnpjSemMascara, id]);
     /* if (checkResult.rowCount > 0) {
        return res.status(409).json({ erro: 'CNPJ já cadastrado.' });
      }*/
    } catch (err) {
      console.error('Erro ao verificar CNPJ:', err);
      return res.status(500).json({ erro: 'Erro ao verificar CNPJ.' });
    }
  }

  const query = `
    UPDATE public.instituicao_ensino
    SET ${updateFields.join(', ')}
    WHERE cd_instituicao_ensino = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(query, updateValues);

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Instituição não encontrada.' });
    }

    res.status(200).json({
      mensagem: 'Instituição alterada com sucesso!',
      instituicao: result.rows[0]
    });
  } catch (err) {
    console.error('Erro ao alterar instituição:', err);
    res.status(500).json({ erro: 'Erro ao alterar a instituição.' });
  }
});

  
router.get('/buscar', tokenOpcional, async (req, res) => {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const offset = (page - 1) * limit;

    const { nome, cnpj , ativo} = req.query;

    // Monta condições dinamicamente
    let filtros = [];
    let valores = [];
    let where = '';
    // Filtros dinâmicos
    if (nome) {
      valores.push(`%${nome}%`);
      filtros.push(`(unaccent(nome_fantasia) ILIKE unaccent($${valores.length}) OR unaccent(razao_social) ILIKE unaccent($${valores.length}))`);
    }

    if (cnpj) {
      const cnpjSemMascara = cnpj.replace(/[./-]/g, ''); // Remove '.', '/' e '-'
      valores.push(`%${cnpjSemMascara}%`);
      filtros.push(`REPLACE(REPLACE(REPLACE(cnpj, '.', ''), '/', ''), '-', '') ILIKE $${valores.length}`);
    }

   
    if (filtros.length > 0) {
      where = `WHERE (${filtros.join(' OR ')})`;
    }

    if (ativo !== undefined) {
      valores.push(ativo === 'true'); // Converte para boolean
      where += (where ? ' AND ' : 'WHERE ') + `bloqueado = $${valores.length}`;
    }


        // Total de registros com filtro
        const countQuery =  `SELECT COUNT(*) FROM public.instituicao_ensino ${where}` ;
      //const total = parseInt(countQuery.rows[0].count);

      // Consulta paginada
      //valores.push(limit);
      //valores.push(offset);

        const baseQuery =  `
         SELECT
          ie.cd_instituicao_ensino AS cd_ie,
          ie.razao_social,
          ie.nome_fantasia,
          ie.cnpj,
          ie.email_principal,
          ie.telefone,
          ie.celular,
          ie.bloqueado,

          e.logradouro,
          e.numero,
          e.bairro,
          e.cidade,
          e.uf,
          e.cep,
          e.complemento,
          e.telefone AS endereco_telefone,

          -- Endereço completo no formato solicitado
          CONCAT_WS(' ',
            e.logradouro || ' - ' || e.numero || ' - ' || e.bairro || ' - ' ||
            e.cidade || '/' || e.uf
          ) AS endereco_completo
           , cd_template_modelo

        FROM public.instituicao_ensino ie
        LEFT JOIN public.endereco e
          ON e.cd_instituicao_ensino = ie.cd_instituicao_ensino
        AND e.principal = true
        AND e.ativo = true
        ${where}
        ORDER BY ie.nome_fantasia
      `
      ; 

        

    try {
    const resultado = await paginarConsultaComEndereco(pool, baseQuery, countQuery, valores, page, limit);


      res.json(resultado);
    } catch (err) {
      console.error('Erro ao buscar instituições:', err);
      logger.error('Erro ao buscar instituições: ' + err.stack, 'instituicoes');
      res.status(500).json({ erro: 'Erro ao buscar instituições.' });
    }
  });


  router.get('/buscar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT
      ie.cd_instituicao_ensino as cd_ie,
      ie.id_externo_legado,
      ie.razao_social,
      ie.nome_fantasia,
      ie.cnpj,
      ie.email_principal,
      ie.mantenedora,
      ie.campus,
      ie.telefone,
      ie.celular,
      ie.unidade,
      ie.representante_legal,
      ie.cpf,
      ie.data_criacao,
      ie.procedimento,
      ie.nome_modelo,
      ie.sigla,
      ie.site,
      ie.tipo_ie,
      ie.nivel_ie,
      ie.ie_formadora,
      ie.isento,
      ie.tipo_inscricao,
      ie.numero_inscricao,
      ie.observacao,
      ie.aguardar_ie_para_assinar,
      ie.acesso_contratos,
      ie.criado_por,
      ie.data_atualizacao,
      ie.atualizado_por, ie.bloqueado, 
      ie.conteudo_html, 
      ie.cd_template_modelo, 
      tm.nome
    FROM public.instituicao_ensino ie
    left join public.template_modelo tm ON tm.id_modelo = ie.cd_template_modelo
    WHERE cd_instituicao_ensino = $1
  `;

  try {
    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Instituição não encontrada.' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao buscar instituição por ID:', err);
    logger.error('Erro ao buscar instituição por ID: ' + err.stack, 'instituicoes');
    res.status(500).json({ erro: 'Erro ao buscar instituição.' });
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

  const query = `
    UPDATE public.instituicao_ensino
    SET bloqueado = $1,
        data_atualizacao = $2,
        atualizado_por = $3
    WHERE cd_instituicao_ensino = $4
    RETURNING cd_instituicao_ensino, bloqueado;
  `;

  try {
    const result = await pool.query(query, [bloqueado, dataAtual, userId, id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Instituição não encontrada.' });
    }

    res.json({
      mensagem: 'Status de bloqueio alterado com sucesso!',
      instituicao: result.rows[0]
    });
  } catch (err) {
    console.error('Erro ao atualizar status de bloqueio da instituição:', err);
    logger.error('Erro ao atualizar status de bloqueio da instituição: ' + err.stack, 'instituicoes');
    res.status(500).json({ erro: 'Erro ao atualizar status de bloqueio da instituição.' });
  }
});


  module.exports = router;