const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');

// POST /tipoModelo/cadastrar
// POST /tipoModelo/cadastrar
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { nome, descricao, tipo_modelo, complementar } = req.body;

  if (!nome) return res.status(400).json({ erro: 'O campo Nome é obrigatório.' });

  try {
    const tiposValidos = ['Convenio', 'Estagio', 'Aprendiz', 'Aditivo Estagio', 'Aditivo Aprendiz', 'Aditivo_Estagio', 'Aditivo_Aprendiz',];
    if (!tipo_modelo || !tiposValidos.includes(tipo_modelo)) {
      return res.status(400).json({ 
        erro: `Tipo de modelo inválido. Valores permitidos: Convenio, Estagio, Aprendiz, Aditivo Estagio ou Aditivo Aprendiz.`,
        recebido: tipo_modelo
      });
    }

    const checkQuery = 'SELECT 1 FROM template_tipo_modelo WHERE nome = $1 LIMIT 1';
    const checkResult = await pool.query(checkQuery, [nome]);
    if (checkResult.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe um tipo de modelo com este nome.' });
    }

    const userId = req.usuario.cd_usuario;
    const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

    const insertQuery = `
      INSERT INTO template_tipo_modelo (nome, descricao, tipo_modelo, ativo, complementar, criado_em, criado_por)
      VALUES ($1, $2, $3, true, $4, $5, $6)
      RETURNING id_tipo_modelo;
    `;
    const values = [nome, descricao || null, tipo_modelo, (complementar), dataAtual, userId];

    const result = await pool.query(insertQuery, values);

    res.status(201).json({
      mensagem: 'Tipo de modelo cadastrado com sucesso!',
      id_tipo_modelo: result.rows[0].id_tipo_modelo
    });
  } catch (err) {
    console.error('Erro ao cadastrar tipo de modelo:', err);
    logger.error('Erro ao cadastrar tipo de modelo: ' + err.stack, 'tipo_modelo');
    res.status(500).json({ erro: 'Erro ao cadastrar tipo de modelo.' });
  }
});

 router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { nome, descricao, ativo, tipo_modelo, complementar } = req.body;

  const updateFields = [];
  const updateValues = [];

  if (nome) {
    updateFields.push(`nome = $${updateValues.length + 1}`);
    updateValues.push(nome);
  }

  if (descricao !== undefined) {
    updateFields.push(`descricao = $${updateValues.length + 1}`);
    updateValues.push(descricao);
  }

  if (tipo_modelo) {
    const tiposValidos = ['Convenio', 'Estagio', 'Aprendiz']; // ajuste se for usar 'Aditivo ...'
    if (!tiposValidos.includes(tipo_modelo)) {
      return res.status(400).json({ erro: 'Tipo de modelo inválido. Valores permitidos: Convenio, Estagio ou Aprendiz.' });
    }
    updateFields.push(`tipo_modelo = $${updateValues.length + 1}`);
    updateValues.push(tipo_modelo);
  }

  if (typeof ativo !== 'undefined') {
    updateFields.push(`ativo = $${updateValues.length + 1}`);
    updateValues.push((ativo));
  }

  // ✅ NOVO: update de complementar (quando enviado)
  if (typeof complementar !== 'undefined') {
    updateFields.push(`complementar = $${updateValues.length + 1}`);
    updateValues.push((complementar));
  }

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  updateFields.push(`alterado_em = $${updateValues.length + 1}`);
  updateValues.push(dataAtual);

  updateFields.push(`alterado_por = $${updateValues.length + 1}`);
  updateValues.push(userId);

  updateValues.push(id);

  if (updateFields.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo fornecido para atualização.' });
  }

  const query = `
    UPDATE template_tipo_modelo
    SET ${updateFields.join(', ')}
    WHERE id_tipo_modelo = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(query, updateValues);
    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Tipo de modelo não encontrado.' });
    }

    res.json({
      mensagem: 'Tipo de modelo alterado com sucesso!',
      tipo_modelo: result.rows[0]
    });
  } catch (err) {
    console.error('Erro ao alterar tipo de modelo:', err);
    logger.error('Erro ao alterar tipo de modelo: ' + err.stack, 'tipo_modelo');
    res.status(500).json({ erro: 'Erro ao alterar tipo de modelo.' });
  }
});


router.get('/listar', verificarToken, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { nome, ativo, complementar } = req.query; // <- se quiser filtrar

  const filtros = [];
  const valores = [];

  if (nome) {
    valores.push(`%${nome}%`);
    filtros.push(`unaccent(nome) ILIKE unaccent($${valores.length})`);
  }

  // (opcional) filtros por ativo/complementar
  if (typeof ativo !== 'undefined') {
    valores.push(ativo === 'true');
    filtros.push(`ativo = $${valores.length}`);
  }
  if (typeof complementar !== 'undefined') {
    valores.push(complementar === 'true');
    filtros.push(`complementar = $${valores.length}`);
  } 

  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM template_tipo_modelo ${where}`;
  const baseQuery = `
    SELECT 
      id_tipo_modelo,
      nome,
      descricao,
      tipo_modelo,
      ativo,
      complementar,      -- ✅ novo campo no SELECT
      criado_em,
      criado_por,
      alterado_em,
      alterado_por
    FROM template_tipo_modelo
    ${where}
    ORDER BY nome
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.json(resultado);
  } catch (err) {
    console.error('Erro ao listar tipos de modelo:', err);
    logger.error('Erro ao listar tipos de modelo: ' + err.stack, 'tipo_modelo');
    res.status(500).json({ erro: 'Erro ao listar tipos de modelo.' });
  }
});



const exportTipoModelo = createCsvExporter({
  filename: () => `tipo-modelo-${new Date().toISOString().slice(0,10)}.csv`,
  header: [
    'ID','Nome','Descrição','Tipo','Complementar','Ativo',
    'Criado Por','Criado Em','Alterado Por','Alterado Em'
  ],
  baseQuery: `
    SELECT
      tm.id_tipo_modelo,
      tm.nome,
      tm.descricao,
      CASE 
        WHEN tm.tipo_modelo = 'CONVENIO' THEN 'Convênio'
        WHEN tm.tipo_modelo = 'ESTAGIO'  THEN 'Estágio'
        WHEN tm.tipo_modelo = 'APRENDIZ' THEN 'Aprendiz'
        ELSE tm.tipo_modelo
      END AS tipo_label,
      tm.complementar,
      tm.ativo,
      COALESCE(u1.nome,'') AS criado_por,
      to_char(tm.criado_em,'DD/MM/YYYY HH24:MI')   AS criado_em,
      COALESCE(u2.nome,'') AS alterado_por,
      to_char(tm.alterado_em,'DD/MM/YYYY HH24:MI') AS alterado_em
    FROM public.template_tipo_modelo tm
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = tm.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = tm.alterado_por
    {{WHERE}}
    ORDER BY tm.id_tipo_modelo
  `,
  // 👉 se não quiser filtro nenhum, pode deixar só `return { where: '', params: [] }`
  buildWhereAndParams: (req) => {
    return { where: '', params: [] };
  },
  rowMap: (r) => [
    r.id_tipo_modelo,
    r.nome || '',
    r.descricao || '',
    r.tipo_label || '',
    r.complementar ? 'Sim' : 'Não',
    r.ativo ? 'Sim' : 'Não',
    r.criado_por,
    r.criado_em || '',
    r.alterado_por,
    r.alterado_em || '',
  ],
});

router.get('/exportar/csv', verificarToken, exportTipoModelo);

module.exports = router;
