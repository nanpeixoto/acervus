const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');

// POST - Cadastrar Conhecimento
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { descricao, ativo = true } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!descricao) {
    return res.status(400).json({ erro: 'O campo "descricao" é obrigatório.' });
  }

  try {
    // Verifica se já existe Conhecimento com esse nome (case insensitive)
    const verificaQuery = `
      SELECT 1 FROM public.conhecimento
      WHERE LOWER(descricao) = LOWER($1)
      LIMIT 1;
    `;
    const verifica = await pool.query(verificaQuery, [descricao.trim()]);
    if (verifica.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe um Conhecimento com essa descrição.' });
    }

    const insertQuery = `
      INSERT INTO public.conhecimento (
        descricao, ativo, criado_por, data_criacao
      )
      VALUES ($1, $2, $3, $4)
      RETURNING cd_conhecimento;
    `;

    const result = await pool.query(insertQuery, [
      descricao.trim(),
      ativo,
      userId,
      dataAtual
    ]);

    res.status(201).json({
      message: 'Conhecimento cadastrado com sucesso!',
      cd_conhecimento: result.rows[0].cd_conhecimento
    });
  } catch (err) {
    logger.error('Erro ao cadastrar Conhecimento: ' + err.stack, 'Conhecimento');
    res.status(500).json({ erro: 'Erro ao cadastrar Conhecimento.' });
  }
});



router.get('/listar', tokenOpcional, listarStatus);
router.get('/buscar', tokenOpcional, listarStatus);



async function listarStatus(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true'); // Converte para boolean
    filtros.push(`ativo = $${valores.length}`);
  }


  console.log(`Query: ${q}`);

  
  if (q ) {
    valores.push(`%${q}%`);
    filtros.push(`( unaccent(descricao) ILIKE unaccent($${valores.length})   OR CAST(cd_conhecimento AS TEXT) ILIKE($${valores.length} )) `);
  }
 console.log(`filtros: ${filtros}`);
  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM public.conhecimento ${where}`;
  const baseQuery = `
    SELECT cd_conhecimento, descricao, ativo, criado_por, data_criacao, data_alteracao, alterado_por
    FROM public.conhecimento
    ${where}
    ORDER BY descricao
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json(resultado);
  } catch (err) {
    console.error('Erro ao listar Conhecimento:', err);
    logger.error('Erro ao listar Conhecimento: ' + err.stack, 'Conhecimento');
    res.status(500).json({ erro: 'Erro ao listar Conhecimento.' });
  }
};



router.put('/alterar/:cd_conhecimento', verificarToken, async (req, res) => {
  const { cd_conhecimento } = req.params;
  const { descricao, ativo } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  try {
    // Busca o registro atual
    const buscaQuery = `
      SELECT descricao, ativo FROM public.conhecimento
      WHERE cd_conhecimento = $1
    `;
    const busca = await pool.query(buscaQuery, [cd_conhecimento]);

    if (busca.rowCount === 0) {
      return res.status(404).json({ erro: 'Conhecimento não encontrado.' });
    }

    const registroAtual = busca.rows[0];
    const novaDescricao = descricao ?? registroAtual.descricao;
    const novoAtivo = ativo ?? registroAtual.ativo;

    // Se o nome mudou, verifica unicidade
    if (descricao && descricao.trim().toLowerCase() !== registroAtual.descricao.trim().toLowerCase()) {
      const verifica = await pool.query(
        `SELECT 1 FROM public.conhecimento WHERE LOWER(descricao) = LOWER($1) AND cd_conhecimento <> $2 LIMIT 1`,
        [descricao.trim(), cd_conhecimento]
      );
      if (verifica.rowCount > 0) {
        return res.status(409).json({ erro: 'Já existe um Conhecimento com essa descrição.' });
      }
    }

    const updateQuery = `
      UPDATE public.conhecimento
      SET descricao = $1,
          ativo = $2,
          data_alteracao = $3,
          alterado_por = $4
      WHERE cd_conhecimento = $5
      RETURNING cd_conhecimento;
    `;

    const result = await pool.query(updateQuery, [
      novaDescricao.trim(),
      novoAtivo,
      dataAtual,
      userId,
      cd_conhecimento
    ]);

    res.status(200).json({
      message: 'Conhecimento atualizado com sucesso!',
      cd_conhecimento: result.rows[0].cd_conhecimento
    });

  } catch (err) {
    console.error('Erro ao atualizar Conhecimento:', err);
    logger.error('Erro ao atualizar Conhecimento: ' + err.stack, 'Conhecimento');
    res.status(500).json({ erro: 'Erro ao atualizar Conhecimento.' });
  }
});
 




const exportItens = createCsvExporter({
  filename: () => `turnos-${new Date().toISOString().slice(0,10)}.csv`,
  header: ['Código','Descrição','Ativo','Criado Por','Data Criação','Alterado Por','Data Alteração'],
  baseQuery: `
    SELECT 
      t.cd_conhecimento,
      t.descricao,
      t.ativo,
      COALESCE(u1.nome,'') AS criado_por,
      to_char(t.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.nome,'') AS alterado_por,
      to_char(t.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.conhecimento t
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = t.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = t.alterado_por
    {{WHERE}}
    ORDER BY t.cd_conhecimento
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [], params = [];
    let i = 1;

    if (ativo !== undefined) { filters.push(`t.ativo = $${i++}`); params.push(ativo === 'true'); }
    if (q) { filters.push(`(unaccent(t.descricao) ILIKE unaccent($${i++}) OR CAST(t.cd_conhecimento AS TEXT) ILIKE $${i-1})`); params.push(`%${q}%`); }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    return { where, params };
  },
  rowMap: (r) => [
    r.cd_conhecimento,
    r.descricao || '',
    r.ativo ? 'Sim' : 'Não',
    r.criado_por,
    r.data_criacao || '',
    r.alterado_por,
    r.data_alteracao || '',
  ],
});

router.get('/exportar/csv', verificarToken, exportItens);




module.exports = router;
