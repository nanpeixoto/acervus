const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');


// ✅ POST - Vincular plano a empresa
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { cd_empresa, cd_plano_pagamento } = req.body;

  const userId = req.usuario?.cd_usuario || null;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!cd_empresa || !cd_plano_pagamento) {
    return res.status(400).json({ erro: 'cd_empresa e cd_plano_pagamento são obrigatórios.' });
  }

  // Evitar duplicidade
  const checkQuery = `
    SELECT 1 FROM empresa_plano_pagamento
    WHERE cd_empresa = $1 AND cd_plano_pagamento = $2
  `;
  const check = await pool.query(checkQuery, [cd_empresa, cd_plano_pagamento]);
  if (check.rowCount > 0) {
    return res.status(409).json({ erro: 'Plano já está vinculado a esta empresa.' });
  }

  const insertQuery = `
    INSERT INTO empresa_plano_pagamento (
      cd_empresa, cd_plano_pagamento, data_criacao, criado_por
    ) VALUES ($1, $2, $3, $4)
    RETURNING cd_empresa_plano;
  `;

  try {
    const result = await pool.query(insertQuery, [cd_empresa, cd_plano_pagamento, dataAtual, userId]);
    res.status(201).json({
      message: 'Plano vinculado com sucesso!',
      cd_empresa_plano: result.rows[0].cd_empresa_plano
    });
  } catch (err) {
    logger.error('Erro ao vincular plano: ' + err.stack, 'empresa_plano_pagamento');
    res.status(500).json({ erro: 'Erro ao vincular plano à empresa.' });
  }
});

// ✅ GET - Listar planos por empresa
router.get('/empresa/listar/:cd_empresa', verificarToken, async (req, res) => {
  const { cd_empresa } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const baseQuery = `
    SELECT epp.cd_empresa_plano, p.cd_plano_pagamento, p.nome, p.valor, epp.ativo
    FROM empresa_plano_pagamento epp
    JOIN plano_pagamento p ON p.cd_plano_pagamento = epp.cd_plano_pagamento
    WHERE epp.cd_empresa = $1
    ORDER BY p.nome
  `;

  const countQuery = `
    SELECT COUNT(*) FROM empresa_plano_pagamento
    WHERE cd_empresa = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, [cd_empresa], page, limit);
    res.json(resultado);
  } catch (err) {
    logger.error('Erro ao listar planos da empresa: ' + err.stack, 'empresa_plano_pagamento');
    res.status(500).json({ erro: 'Erro ao listar planos da empresa.' });
  }
});

// ✅ PUT - Alterar plano vinculado ou ativar/inativar vínculo
router.put('/alterar/:cd_empresa_plano', verificarToken, async (req, res) => {
  const { cd_empresa_plano } = req.params;
  const { cd_plano_pagamento, ativo } = req.body;

  const userId = req.usuario?.cd_usuario || null;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  const campos = [];
  const valores = [];
  let idx = 1;

  if (cd_plano_pagamento !== undefined) {
    campos.push(`cd_plano_pagamento = $${idx++}`);
    valores.push(cd_plano_pagamento);
  }

  if (ativo !== undefined) {
    campos.push(`ativo = $${idx++}`);
    valores.push(ativo);
  }

  if (campos.length === 0) {
    return res.status(400).json({ erro: 'Informe pelo menos cd_plano_pagamento ou ativo.' });
  }

  campos.push(`data_alteracao = $${idx++}`);
  valores.push(dataAtual);

  campos.push(`alterado_por = $${idx++}`);
  valores.push(userId);

  valores.push(cd_empresa_plano); // Para o WHERE

  const updateQuery = `
    UPDATE empresa_plano_pagamento
    SET ${campos.join(', ')}
    WHERE cd_empresa_plano = $${valores.length}
    RETURNING cd_empresa_plano;
  `;

  try {
    const result = await pool.query(updateQuery, valores);
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Vínculo não encontrado.' });
    }

    res.status(200).json({
      message: 'Vínculo atualizado com sucesso!',
      cd_empresa_plano: result.rows[0].cd_empresa_plano
    });
  } catch (err) {
    logger.error('Erro ao atualizar vínculo de plano: ' + err.stack, 'empresa_plano_pagamento');
    res.status(500).json({ erro: 'Erro ao atualizar vínculo.' });
  }
});

module.exports = router;
