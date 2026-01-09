const express = require('express');
const router = express.Router();
const pool = require('../db');
const { paginarConsulta } = require('../helpers/paginador'); // Reutilizando seu helper de paginação

router.get('/listar', async (req, res) => {
  const page = parseInt(req.query.page) || 1;    // Página atual
  const limit = parseInt(req.query.limit) || 10000; // Limite por página
  const offset = (page - 1) * limit;

  const baseQuery = `
    SELECT entidade, campo, tag, descricao
    FROM template_tag
    WHERE ativo = true
    ORDER BY entidade, tag
  `;

  const countQuery = `
    SELECT COUNT(*) FROM template_tag
    WHERE ativo = true
  `;

  const valores = []; // Sem filtros por enquanto

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);

     res.json(resultado);
  } catch (err) {
    console.error('Erro ao listar tags:', err);
    res.status(500).json({ sucesso: false, erro: 'Erro ao buscar tags.' });
  }
});

module.exports = router;
