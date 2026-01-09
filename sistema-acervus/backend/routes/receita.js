const express = require('express');
const router = express.Router();
const axios = require('axios');
const pool = require('../db'); // sua conexão com PostgreSQL
const logger = require('../utils/logger');

const RECEITAWS_TOKEN = 'SEU_TOKEN_AQUI'; // troque pelo seu token real

router.get('/consulta-cnpj/:cnpj', async (req, res) => {
  const { cnpj } = req.params;
  const cnpjLimpo = cnpj.replace(/\D/g, '');

  if (cnpjLimpo.length !== 14) {
    return res.status(400).json({ erro: 'CNPJ inválido.' });
  }

  try {
    // 1. Verifica se já existe no banco
    const result = await pool.query(
      'SELECT * FROM public.cnpj_cache WHERE cnpj = $1',
      [cnpjLimpo]
    );

    if (result.rows.length > 0) {
      return res.status(200).json({
        origem: 'cache',
        dados: result.rows[0].dados_json
      });
    }

    // 2. Consulta a API Receitaws
    const { data } = await axios.get(`https://www.receitaws.com.br/v1/cnpj/${cnpjLimpo}`, {
      params: { token: RECEITAWS_TOKEN },
      headers: { 'Accept': 'application/json' }
    });

    if (data.status === 'ERROR') {
      return res.status(404).json({ erro: data.message });
    }

    // 3. Salva no banco
    await pool.query(
      `INSERT INTO public.cnpj_cache (cnpj, dados_json) VALUES ($1, $2)`,
      [cnpjLimpo, data]
    );

    return res.status(200).json({
      origem: 'api',
      dados: data
    });

  } catch (err) {
    logger.error('Erro ao consultar ou gravar CNPJ: ' + err.message, 'cnpj');
    return res.status(500).json({ erro: 'Erro ao processar a consulta.' });
  }
});

module.exports = router;
