const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');

const { createCsvExporter } = require('../factories/exportCsvFactory');


// POST - Cadastrar status do curso
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { descricao, ativo = true } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!descricao) {
    return res.status(400).json({ erro: 'O campo "descricao" é obrigatório.' });
  }

  try {
    // Verifica se já existe status com esse nome (case insensitive)
    const verificaQuery = `
      SELECT 1 FROM public.status_curso
      WHERE LOWER(descricao) = LOWER($1)
      LIMIT 1;
    `;
    const verifica = await pool.query(verificaQuery, [descricao.trim()]);
    if (verifica.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe um status com essa descrição.' });
    }

    const insertQuery = `
      INSERT INTO public.status_curso (
        descricao, ativo, criado_por, data_criacao
      )
      VALUES ($1, $2, $3, $4)
      RETURNING cd_status;
    `;

    const result = await pool.query(insertQuery, [
      descricao.trim(),
      ativo,
      userId,
      dataAtual
    ]);

    res.status(201).json({
      message: 'Status cadastrado com sucesso!',
      cd_status: result.rows[0].cd_status
    });
  } catch (err) {
    logger.error('Erro ao cadastrar status do curso: ' + err.stack, 'status_curso');
    res.status(500).json({ erro: 'Erro ao cadastrar status do curso.' });
  }
});




router.get('/listar', tokenOpcional, listarStatus);
router.get('/buscar', tokenOpcional, listarStatus);



async function listarStatus(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo , q} = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true'); // Converte para boolean
    filtros.push(`ativo = $${valores.length}`);
  }


    
  if (q ) {
    valores.push(`%${q}%`);
    filtros.push(`( unaccent(descricao) ILIKE unaccent($${valores.length})   OR CAST(cd_status AS TEXT) ILIKE($${valores.length} )) `);
  }
 console.log(`filtros: ${filtros}`);

  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM public.status_curso ${where}`;
  const baseQuery = `
    SELECT cd_status, descricao, ativo, criado_por, data_criacao, data_alteracao, alterado_por
    FROM public.status_curso
    ${where}
    ORDER BY descricao
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json(resultado);
  } catch (err) {
    console.error('Erro ao listar status do curso:', err);
    logger.error('Erro ao listar status do curso: ' + err.stack, 'status_curso');
    res.status(500).json({ erro: 'Erro ao listar status do curso.' });
  }
};



router.put('/alterar/:cd_status', verificarToken, async (req, res) => {
  const { cd_status } = req.params;
  const { descricao, ativo } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  try {
    // Busca o registro atual
    const buscaQuery = `
      SELECT descricao, ativo FROM public.status_curso
      WHERE cd_status = $1
    `;
    const busca = await pool.query(buscaQuery, [cd_status]);

    if (busca.rowCount === 0) {
      return res.status(404).json({ erro: 'Status não encontrado.' });
    }

    const registroAtual = busca.rows[0];
    const novaDescricao = descricao ?? registroAtual.descricao;
    const novoAtivo = ativo ?? registroAtual.ativo;

    // Se o nome mudou, verifica unicidade
    if (descricao && descricao.trim().toLowerCase() !== registroAtual.descricao.trim().toLowerCase()) {
      const verifica = await pool.query(
        `SELECT 1 FROM public.status_curso WHERE LOWER(descricao) = LOWER($1) AND cd_status <> $2 LIMIT 1`,
        [descricao.trim(), cd_status]
      );
      if (verifica.rowCount > 0) {
        return res.status(409).json({ erro: 'Já existe um status com essa descrição.' });
      }
    }

    const updateQuery = `
      UPDATE public.status_curso
      SET descricao = $1,
          ativo = $2,
          data_alteracao = $3,
          alterado_por = $4
      WHERE cd_status = $5
      RETURNING cd_status;
    `;

    const result = await pool.query(updateQuery, [
      novaDescricao.trim(),
      novoAtivo,
      dataAtual,
      userId,
      cd_status
    ]);

    res.status(200).json({
      message: 'Status atualizado com sucesso!',
      cd_status: result.rows[0].cd_status
    });

  } catch (err) {
    console.error('Erro ao atualizar status do curso:', err);
    logger.error('Erro ao atualizar status do curso: ' + err.stack, 'status_curso');
    res.status(500).json({ erro: 'Erro ao atualizar status do curso.' });
  }
});
 
const exportStatusCurso = createCsvExporter({
  filename: () => `status_curso-${new Date().toISOString().slice(0,10)}.csv`,
  header: ['Código','Descrição','Ativo','Criado Por','Data Criação','Alterado Por','Data Alteração'],
  baseQuery: `
    SELECT 
      s.cd_status,
      s.descricao,
      s.ativo,
      COALESCE(u1.nome,'') AS criado_por,
      to_char(s.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.nome,'') AS alterado_por,
      to_char(s.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.status_curso s
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = s.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = s.alterado_por
    {{WHERE}}
    ORDER BY s.cd_status
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
      filters.push(`(unaccent(s.descricao) ILIKE unaccent($${i++}) OR CAST(s.cd_status AS TEXT) ILIKE $${i-1})`); 
      params.push(`%${q}%`); 
    }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    return { where, params };
  },
  rowMap: (r) => [
    r.cd_status,
    r.descricao || '',
    r.ativo ? 'Sim' : 'Não',
    r.criado_por,
    r.data_criacao || '',
    r.alterado_por,
    r.data_alteracao || '',
  ],
});

router.get('/exportar/csv', verificarToken, exportStatusCurso);



module.exports = router;
