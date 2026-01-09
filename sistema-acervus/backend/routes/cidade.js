const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ MELHOR ABORDAGEM: Importar o objeto completo
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');


router.get('/cidades', verificarToken, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const offset = (page - 1) * limit;

  const { nome, uf } = req.query;

  let filtros = [];
  let valores = [];
  let where = '';

  if (nome) {
    valores.push(`%${nome}%`);
    filtros.push(`unaccent(nome) ILIKE unaccent($${valores.length})`);
  }

  if (uf) {
    valores.push(uf.toUpperCase());
    filtros.push(`uf = $${valores.length}`);
  }

  if (filtros.length > 0) {
    where = `WHERE ${filtros.join(' AND ')}`;
  }

  
    const countQuery =  `SELECT COUNT(*) FROM cidade ${where}` 
 

    valores.push(limit);
    valores.push(offset);

    const baseQuery =  `
      SELECT cd_cidade as id, nome, uf
      FROM cidade
      ${where}
      ORDER BY nome
        `;


      logger.info('Base query montada', 'instituicoes');
      logger.info('Filtros aplicados: ' + JSON.stringify(filtros), 'instituicoes');
      logger.info('Valores: ' + JSON.stringify(valores), 'instituicoes');
    

    try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, filtros, page, limit);
    res.json(resultado);
  } catch (err) {
    console.error('Erro ao buscar CIDADES:', err);
      logger.error('Erro ao buscar CIDADES: ' + err.stack, 'CIDADES');
    res.status(500).json({ erro: 'Erro ao buscar CIDADES.' });
    
  }
});


// LISTAR UFs ORDENADAS
router.get('/uf/listar', tokenOpcional, async (req, res) => {
  try {
    const sql = `
       
      select    uf.sigla, uf.nome from cidade inner join uf on uf.sigla = cidade.uf
       group by uf.sigla, uf.nome 
      ORDER BY uf.nome ASC ;
    `;

    const result = await pool.query(sql);

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error('Erro ao listar UFs:', error);
    return res.status(500).json({ erro: 'Erro interno ao listar UFs.' });
  }
});


router.get('/:ufSigla/listar', tokenOpcional, async (req, res) => {
  const { ufSigla } = req.params;

  if (!ufSigla) {
    return res.status(400).json({ erro: "UF não informada." });
  }

  try {
    const sql = `
      SELECT cd_cidade AS id, nome, uf
      FROM cidade
      WHERE uf = $1
      ORDER BY nome ASC;
    `;

    const result = await pool.query(sql, [ufSigla.toUpperCase()]);

    const cidades = result.rows.map(c => ({
      id: c.id.toString(),
      nome: c.nome,
      uf: c.uf
    }));

    return res.status(200).json(cidades);

  } catch (error) {
    console.error('Erro ao listar cidades:', error);
    return res.status(500).json({ erro: "Erro interno ao listar cidades." });
  }
});




module.exports = router;
