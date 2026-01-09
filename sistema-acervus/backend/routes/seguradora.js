const express = require('express');
const router = express.Router();
const app = express();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
const { cadastrarEndereco , alterarEndereco} = require('./endereco');
const { cadastrarContato, alterarContato } = require('./contatos');
const { createCsvExporter } = require('../factories/exportCsvFactory');




const multer = require('multer');
const path = require('path');

const fs = require('fs');

app.use(express.json()); // Para application/json
app.use(express.urlencoded({ extended: true })); // Para application/x-www-form-urlencoded

 
    
router.post('/cadastrar', verificarToken, async (req, res) => {
  const {
    razao_social, nome_fantasia, cnpj, telefone, celular,
    valor_apolice, numero_apolice, porcentagem_dhmo, observacao, ativo,
    endereco
  } = req.body;

  const camposObrigatorios = [
    { campo: 'Razão Social', valor: razao_social },
    { campo: 'Nome Fantasia', valor: nome_fantasia },
    { campo: 'CNPJ', valor: cnpj }
  ];

  const camposFaltando = camposObrigatorios.filter(c => !c.valor);
  if (camposFaltando.length > 0) {
    return res.status(400).json({
      erro: `Campos obrigatórios ausentes: ${camposFaltando.map(c => c.campo).join(', ')}`
    });
  }

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];



  const query = `
    INSERT INTO seguradora (
      razao_social, nome_fantasia, cnpj, telefone, celular,
      valor_apolice, numero_apolice, porcentagem_dhmo, observacao,
      ativo, criado_por, data_criacao
    ) VALUES (
      $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12
    ) RETURNING cd_seguradora;
  `;

  const values = [
    razao_social.toUpperCase(),
    nome_fantasia.toUpperCase(),
    cnpj,
    telefone || null,
    celular || null,
    valor_apolice || null,
    numero_apolice || null,
    porcentagem_dhmo || null,
    observacao || null,
    ativo ?? true,
    userId,
    dataAtual
  ];

  const client = await pool.connect();

  
  const verificarDuplicidade = `
  SELECT 1 FROM seguradora WHERE cnpj = $1`;
  const existe = await client.query(verificarDuplicidade, [cnpj]);
 /* if (existe.rowCount > 0) {
    await client.query('ROLLBACK');
     return res.status(409).json({ erro: 'Já existe uma SEGURADORA com esse CNPJ.' });
    }*/

  try {
    await client.query('BEGIN');

    const result = await client.query(query, values);
    const idSeguradora = result.rows[0].cd_seguradora;

    if (endereco && Object.keys(endereco).length > 0) {
      try {
         await cadastrarEndereco(endereco,null , userId, null,  result.rows[0].cd_seguradora,  null, client);
      } catch (erroEndereco) {
        await client.query('ROLLBACK');
        logger.error('Erro ao cadastrar endereço: ' + erroEndereco.stack, 'enderecos');
        return res.status(400).json({ erro: 'Erro ao cadastrar endereço: ' + erroEndereco.message });
      }
    }

    await client.query('COMMIT');
    res.status(201).json({ mensagem: 'Seguradora cadastrada com sucesso!', cd_seguradora: idSeguradora });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao cadastrar seguradora: ' + err.stack, 'seguradora');
    res.status(500).json({ erro: 'Erro interno ao cadastrar seguradora.', motivo: err.message });
  } finally {
    client.release();
  }
});

router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const {
    razao_social, nome_fantasia, cnpj, telefone, celular,
    valor_apolice, numero_apolice, porcentagem_dhmo, observacao, ativo,
    endereco
  } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Validação de duplicidade de CNPJ apenas se for enviado um novo CNPJ
    if (cnpj) {
      const existe = await client.query(
        `SELECT 1 FROM seguradora WHERE cnpj = $1 AND cd_seguradora <> $2`,
        [cnpj, id]
      );

      /*if (existe.rowCount > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({ erro: 'Já existe uma seguradora cadastrada com este CNPJ.' });
      }*/
    }

    // Construção dinâmica do update
    const campos = [];
    const valores = [];
    let idx = 1;

    const adicionarCampo = (campo, valor) => {
      campos.push(`${campo} = $${idx++}`);
      valores.push(valor);
    };

    if (razao_social) adicionarCampo('razao_social', razao_social.toUpperCase());
    if (nome_fantasia) adicionarCampo('nome_fantasia', nome_fantasia.toUpperCase());
    if (cnpj) adicionarCampo('cnpj', cnpj);
    if (telefone !== undefined) adicionarCampo('telefone', telefone || null);
    if (celular !== undefined) adicionarCampo('celular', celular || null);
    if (valor_apolice !== undefined) adicionarCampo('valor_apolice', valor_apolice || null);
    if (numero_apolice !== undefined) adicionarCampo('numero_apolice', numero_apolice || null);
    if (porcentagem_dhmo !== undefined) adicionarCampo('porcentagem_dhmo', porcentagem_dhmo || null);
    if (observacao !== undefined) adicionarCampo('observacao', observacao || null);
    if (ativo !== undefined) adicionarCampo('ativo', ativo);

    adicionarCampo('alterado_por', userId);
    adicionarCampo('data_alteracao', dataAtual);

    if (campos.length === 0 && !endereco) {
      await client.query('ROLLBACK');
      return res.status(400).json({ erro: 'Nenhum campo enviado para alteração.' });
    }

    const query = `
      UPDATE seguradora
      SET ${campos.join(', ')}
      WHERE cd_seguradora = $${idx}
      RETURNING *;
    `;

    valores.push(id);

    const result = await client.query(query, valores);

    if (result.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Seguradora não encontrada.' });
    }

    // Atualizar endereço, se enviado
    if (endereco && Object.keys(endereco).length > 0) {
      try {
        await alterarEndereco(endereco, endereco.id_endereco, userId, client);
      } catch (erroEndereco) {
        await client.query('ROLLBACK');
        logger.error('Erro ao alterar endereço: ' + erroEndereco.stack, 'enderecos');
        return res.status(400).json({ erro: 'Erro ao alterar endereço: ' + erroEndereco.message });
      }
    }

    await client.query('COMMIT');

    res.status(200).json({
      mensagem: 'Seguradora alterada com sucesso!',
      seguradora: result.rows[0]
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao alterar seguradora: ' + err.stack, 'seguradora');
    res.status(500).json({ erro: 'Erro ao alterar seguradora.', motivo: err.message });
  } finally {
    client.release();
  }
});


router.get('/listar', tokenOpcional, listarSeguradoras);
router.get('/buscar', tokenOpcional, listarSeguradoras);

 
async function listarSeguradoras(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true');
    filtros.push(`s.ativo = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`(
      unaccent(s.razao_social) ILIKE unaccent($${valores.length}) OR
      unaccent(s.nome_fantasia) ILIKE unaccent($${valores.length}) OR
      s.cnpj ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM seguradora s ${where}`;

  const baseQuery = `
    SELECT
      s.cd_seguradora,
      s.razao_social,
      s.nome_fantasia,
      s.cnpj,
      s.telefone,
      s.celular,
      s.valor_apolice,
      s.numero_apolice,
      s.porcentagem_dhmo,
      s.observacao,
      s.ativo,
      s.criado_por,
      s.data_criacao,
      s.data_alteracao,
      s.alterado_por,

      e.id_endereco,
      e.cep,
      e.logradouro,
      e.numero AS numero_endereco,
      e.bairro,
      e.cidade,
      e.complemento,
      e.uf,
      e.telefone AS telefone_endereco,
      e.principal,
      e.ativo AS endereco_ativo

    FROM seguradora s
    LEFT JOIN endereco e ON e.cd_seguradora = s.cd_seguradora AND e.principal = true
    ${where}
    ORDER BY s.razao_social
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);

    // 🧠 Reestrutura os dados com objeto `endereco`
    const dadosComEndereco = resultado.dados.map(row => {
      const {
        id_endereco,
        cep,
        logradouro,
        numero_endereco,
        bairro,
        cidade,
        complemento,
        uf,
        telefone_endereco,
        principal,
        endereco_ativo,
        ...seguradora
      } = row;

      return {
        ...seguradora,
        endereco: id_endereco ? {
          id_endereco,
          cep,
          logradouro,
          numero: numero_endereco,
          bairro,
          cidade,
          complemento,
          uf,
          telefone: telefone_endereco,
          principal,
          ativo: endereco_ativo
        } : null
      };
    });

    res.status(200).json({
      ...resultado,
      dados: dadosComEndereco
    });

  } catch (err) {
    console.error('Erro ao listar seguradoras:', err);
    logger.error('Erro ao listar seguradoras: ' + err.stack, 'seguradora');
    res.status(500).json({ erro: 'Erro ao listar seguradoras.' });
  }
}


 router.get('/buscar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT
      s.cd_seguradora,
      s.razao_social,
      s.nome_fantasia,
      s.cnpj,
      s.telefone,
      s.celular,
      s.valor_apolice,
      s.numero_apolice,
      s.porcentagem_dhmo,
      s.observacao,
      s.ativo,
      s.criado_por,
      s.data_criacao,
      s.data_alteracao,
      s.alterado_por,

      e.id_endereco,
      e.cep,
      e.logradouro,
      e.numero AS numero_endereco,
      e.bairro,
      e.cidade,
      e.complemento,
      e.uf,
      e.telefone AS telefone_endereco,
      e.principal,
      e.ativo AS endereco_ativo

    FROM seguradora s
    LEFT JOIN endereco e ON e.cd_seguradora = s.cd_seguradora AND e.principal = true
    WHERE s.cd_seguradora = $1
  `;

  try {
    const result = await pool.query(query, [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Seguradora não encontrada.' });
    }

    const row = result.rows[0];

    const {
      id_endereco,
      cep,
      logradouro,
      numero_endereco,
      bairro,
      cidade,
      complemento,
      uf,
      telefone_endereco,
      principal,
      endereco_ativo,
      ...seguradora
    } = row;

    const resposta = {
      ...seguradora,
      endereco: id_endereco ? {
        id_endereco,
        cep,
        logradouro,
        numero: numero_endereco,
        bairro,
        cidade,
        complemento,
        uf,
        telefone: telefone_endereco,
        principal,
        ativo: endereco_ativo
      } : null
    };

    res.status(200).json(resposta);
  } catch (err) {
    console.error('Erro ao buscar seguradora por ID:', err);
    logger.error('Erro ao buscar seguradora: ' + err.stack, 'seguradora');
    res.status(500).json({ erro: 'Erro ao buscar seguradora.' });
  }
});

 

 
 
const exportSeguradoras = createCsvExporter({
  filename: () => `seguradoras-${new Date().toISOString().slice(0,10)}.csv`,
  header: [
    'Código','Razão Social','Nome Fantasia','CNPJ',
    'Telefone','Celular','Valor Apólice','Número Apólice',
    'Porcentagem DHMO','Observação','Ativo',
    'Criado Por','Data Criação','Alterado Por','Data Alteração'
  ],
  baseQuery: `
    SELECT 
      s.cd_seguradora,
      s.razao_social,
      s.nome_fantasia,
      s.cnpj,
      s.telefone,
      s.celular,
      s.valor_apolice,
      s.numero_apolice,
      s.porcentagem_dhmo,
      s.observacao,
      s.ativo,
      COALESCE(u1.nome,'') AS criado_por,
      to_char(s.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.nome,'') AS alterado_por,
      to_char(s.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.seguradora s
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = s.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = s.alterado_por
    {{WHERE}}
    ORDER BY s.cd_seguradora
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [], params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`s.ativo = $${i++}`);
      params.push(ativo === 'true');
    }
    if (q) {
      filters.push(`(
        unaccent(s.razao_social) ILIKE unaccent($${i++})
        OR unaccent(s.nome_fantasia) ILIKE unaccent($${i})
        OR CAST(s.cd_seguradora AS TEXT) ILIKE $${i}
      )`);
      params.push(`%${q}%`);
    }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    return { where, params };
  },
  rowMap: (r) => [
    r.cd_seguradora,
    r.razao_social || '',
    r.nome_fantasia || '',
    r.cnpj || '',
    r.telefone || '',
    r.celular || '',
    r.valor_apolice || '',
    r.numero_apolice || '',
    r.porcentagem_dhmo || '',
    r.observacao || '',
    r.ativo ? 'Sim' : 'Não',
    r.criado_por,
    r.data_criacao || '',
    r.alterado_por,
    r.data_alteracao || '',
  ],
});

router.get('/exportar/csv', verificarToken, exportSeguradoras);





module.exports = router;
