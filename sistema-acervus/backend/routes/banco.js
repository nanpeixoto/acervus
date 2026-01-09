const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');

// POST - Cadastrar Banco
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { descricao, ativo = true } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!descricao) {
    return res.status(400).json({ erro: 'O campo "descricao" é obrigatório.' });
  }

  try {
    // Verifica se já existe Banco com esse nome (case insensitive)
    const verificaQuery = `
      SELECT 1 FROM public.Banco
      WHERE LOWER(descricao) = LOWER($1)
      LIMIT 1;
    `;
    const verifica = await pool.query(verificaQuery, [descricao.trim()]);
    if (verifica.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe um Banco com essa descrição.' });
    }

    const insertQuery = `
      INSERT INTO public.Banco (
        descricao, ativo, criado_por, data_criacao
      )
      VALUES ($1, $2, $3, $4)
      RETURNING cd_banco;
    `;

    const result = await pool.query(insertQuery, [
      descricao.trim(),
      ativo,
      userId,
      dataAtual
    ]);

    res.status(201).json({
      message: 'Banco cadastrado com sucesso!',
      cd_banco: result.rows[0].cd_banco
    });
  } catch (err) {
    logger.error('Erro ao cadastrar Banco: ' + err.stack, 'Banco');
    res.status(500).json({ erro: 'Erro ao cadastrar Banco.' });
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
    filtros.push(`( unaccent(descricao) ILIKE unaccent($${valores.length})   OR CAST(cd_banco AS TEXT) ILIKE($${valores.length} )) `);
  }
 console.log(`filtros: ${filtros}`);
  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM public.Banco ${where}`;
  const baseQuery = `
    SELECT cd_banco, descricao, ativo, criado_por, data_criacao, data_alteracao, alterado_por
    FROM public.Banco
    ${where}
    ORDER BY descricao
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json(resultado);
  } catch (err) {
    console.error('Erro ao listar Banco:', err);
    logger.error('Erro ao listar Banco: ' + err.stack, 'Banco');
    res.status(500).json({ erro: 'Erro ao listar Banco.' });
  }
};



router.put('/alterar/:cd_banco', verificarToken, async (req, res) => {
  const { cd_banco } = req.params;
  const { descricao, ativo } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  try {
    // Busca o registro atual
    const buscaQuery = `
      SELECT descricao, ativo FROM public.Banco
      WHERE cd_banco = $1
    `;
    const busca = await pool.query(buscaQuery, [cd_banco]);

    if (busca.rowCount === 0) {
      return res.status(404).json({ erro: 'Banco não encontrado.' });
    }

    const registroAtual = busca.rows[0];
    const novaDescricao = descricao ?? registroAtual.descricao;
    const novoAtivo = ativo ?? registroAtual.ativo;

    // Se o nome mudou, verifica unicidade
    if (descricao && descricao.trim().toLowerCase() !== registroAtual.descricao.trim().toLowerCase()) {
      const verifica = await pool.query(
        `SELECT 1 FROM public.Banco WHERE LOWER(descricao) = LOWER($1) AND cd_banco <> $2 LIMIT 1`,
        [descricao.trim(), cd_banco]
      );
      if (verifica.rowCount > 0) {
        return res.status(409).json({ erro: 'Já existe um Banco com essa descrição.' });
      }
    }

    const updateQuery = `
      UPDATE public.Banco
      SET descricao = $1,
          ativo = $2,
          data_alteracao = $3,
          alterado_por = $4
      WHERE cd_banco = $5
      RETURNING cd_banco;
    `;

    const result = await pool.query(updateQuery, [
      novaDescricao.trim(),
      novoAtivo,
      dataAtual,
      userId,
      cd_banco
    ]);

    res.status(200).json({
      message: 'Banco atualizado com sucesso!',
      cd_banco: result.rows[0].cd_banco
    });

  } catch (err) {
    console.error('Erro ao atualizar Banco:', err);
    logger.error('Erro ao atualizar Banco: ' + err.stack, 'Banco');
    res.status(500).json({ erro: 'Erro ao atualizar Banco.' });
  }
});
 




const exportItens = createCsvExporter({
  filename: () => `turnos-${new Date().toISOString().slice(0,10)}.csv`,
  header: ['Código','Descrição','Ativo','Criado Por','Data Criação','Alterado Por','Data Alteração'],
  baseQuery: `
    SELECT 
      t.cd_banco,
      t.descricao,
      t.ativo,
      COALESCE(u1.nome,'') AS criado_por,
      to_char(t.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.nome,'') AS alterado_por,
      to_char(t.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.banco t
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = t.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = t.alterado_por
    {{WHERE}}
    ORDER BY t.cd_banco
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [], params = [];
    let i = 1;

    if (ativo !== undefined) { filters.push(`t.ativo = $${i++}`); params.push(ativo === 'true'); }
    if (q) { filters.push(`(unaccent(t.descricao) ILIKE unaccent($${i++}) OR CAST(t.cd_banco AS TEXT) ILIKE $${i-1})`); params.push(`%${q}%`); }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    return { where, params };
  },
  rowMap: (r) => [
    r.cd_banco,
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
