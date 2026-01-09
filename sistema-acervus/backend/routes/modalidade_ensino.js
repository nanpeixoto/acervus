const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');

// POST - Cadastrar Modalide Ensino do curso
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { descricao, ativo = true } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!descricao) {
    return res.status(400).json({ erro: 'O campo "descricao" é obrigatório.' });
  }

  try {
    // Verifica se já existe Modalide Ensino com esse nome (case insensitive)
    const verificaQuery = `
      SELECT 1 FROM public.modalidade_ensino
      WHERE LOWER(descricao) = LOWER($1)
      LIMIT 1;
    `;
    const verifica = await pool.query(verificaQuery, [descricao.trim()]);
    if (verifica.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe um Modalide Ensino com essa descrição.' });
    }

    const insertQuery = `
      INSERT INTO public.modalidade_ensino (
        descricao, ativo, criado_por, data_criacao
      )
      VALUES ($1, $2, $3, $4)
      RETURNING cd_modalidade_ensino;
    `;

    const result = await pool.query(insertQuery, [
      descricao.trim(),
      ativo,
      userId,
      dataAtual
    ]);

    res.status(201).json({
      message: 'Modalide Ensino cadastrado com sucesso!',
      cd_modalidade_ensino: result.rows[0].cd_modalidade_ensino
    });
  } catch (err) {
    logger.error('Erro ao cadastrar Modalide Ensino do curso: ' + err.stack, 'Modalide Ensino');
    res.status(500).json({ erro: 'Erro ao cadastrar Modalide Ensino do curso.' });
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
    filtros.push(`( unaccent(descricao) ILIKE unaccent($${valores.length})   OR CAST(cd_modalidade_ensino AS TEXT) ILIKE($${valores.length} )) `);
  }
 console.log(`filtros: ${filtros}`);


  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM public.modalidade_ensino ${where}`;
  const baseQuery = `
    SELECT cd_modalidade_ensino , cd_modalidade_ensino as codigo , descricao, ativo, criado_por, data_criacao, data_alteracao, alterado_por
    FROM public.modalidade_ensino
    ${where}
    ORDER BY descricao
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json(resultado);
  } catch (err) {
    console.error('Erro ao listar Modalide Ensino do curso:', err);
    logger.error('Erro ao listar Modalide Ensino do curso: ' + err.stack, 'Modalide Ensino');
    res.status(500).json({ erro: 'Erro ao listar Modalide Ensino do curso.' });
  }
};



router.put('/alterar/:cd_modalidade_ensino', verificarToken, async (req, res) => {
  const { cd_modalidade_ensino } = req.params;
  const { descricao, ativo } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  try {
    // Busca o registro atual
    const buscaQuery = `
      SELECT descricao, ativo FROM public.modalidade_ensino
      WHERE cd_modalidade_ensino = $1
    `;
    const busca = await pool.query(buscaQuery, [cd_modalidade_ensino]);

    if (busca.rowCount === 0) {
      return res.status(404).json({ erro: 'Modalide Ensino não encontrado.' });
    }

    const registroAtual = busca.rows[0];
    const novaDescricao = descricao ?? registroAtual.descricao;
    const novoAtivo = ativo ?? registroAtual.ativo;

    // Se o nome mudou, verifica unicidade
    if (descricao && descricao.trim().toLowerCase() !== registroAtual.descricao.trim().toLowerCase()) {
      const verifica = await pool.query(
        `SELECT 1 FROM public.modalidade_ensino WHERE LOWER(descricao) = LOWER($1) AND cd_modalidade_ensino <> $2 LIMIT 1`,
        [descricao.trim(), cd_modalidade_ensino]
      );
      if (verifica.rowCount > 0) {
        return res.status(409).json({ erro: 'Já existe um Modalide Ensino com essa descrição.' });
      }
    }

    const updateQuery = `
      UPDATE public.modalidade_ensino
      SET descricao = $1,
          ativo = $2,
          data_alteracao = $3,
          alterado_por = $4
      WHERE cd_modalidade_ensino = $5
      RETURNING cd_modalidade_ensino;
    `;

    const result = await pool.query(updateQuery, [
      novaDescricao.trim(),
      novoAtivo,
      dataAtual,
      userId,
      cd_modalidade_ensino
    ]);

    res.status(200).json({
      message: 'Modalide Ensino atualizado com sucesso!',
      cd_modalidade_ensino: result.rows[0].cd_modalidade_ensino
    });

  } catch (err) {
    console.error('Erro ao atualizar Modalide Ensino do curso:', err);
    logger.error('Erro ao atualizar Modalide Ensino do curso: ' + err.stack, 'Modalide Ensino');
    res.status(500).json({ erro: 'Erro ao atualizar Modalide Ensino do curso.' });
  }
});
 


module.exports = router;
