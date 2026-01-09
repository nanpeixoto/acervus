const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
  const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');





router.get('/buscar', async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const offset = (page - 1) * limit;

  const { descricao  } = req.query;

  let filtros = [];
  let valores = [];
  let where = '';

  if (descricao) {
    valores.push(`%${descricao}%`);
    filtros.push(`unaccent(descricao) ILIKE unaccent($${valores.length})`);
  }

  

  const countQuery = `SELECT COUNT(*) FROM public.regime_contratacao ${where}`;
  const baseQuery = `
    SELECT id_regime_contratacao, descricao 
    FROM public.regime_contratacao
    ${where}
    ORDER BY descricao
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.json(resultado);
  } catch (err) {
    console.error('Erro ao buscar Regime de Contratacao:', err);
    logger.error('Erro ao buscar Regime de Contratacao: ' + err.stack, 'Regime de Contratacao');
    res.status(500).json({ erro: 'Erro ao buscar Regime de Contratacao.' });
  }
});


module.exports = router;
