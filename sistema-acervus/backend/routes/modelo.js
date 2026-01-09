const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');

const fs = require('fs');
const path = require('path');


async function processarImagensBase64(html) {
  const regex = /<img[^>]*src="data:image\/(png|jpeg|jpg);base64,([^"]+)"[^>]*>/g;
  let match;
  const promises = [];

  // Diretório de destino absoluto e público
  const pastaAbsoluta = path.join('/var/www/sistema-cide/backend/uploads/imagem_modelo');
  const pastaPublica = '/uploads/imagem_modelo';

  // Garante que a pasta existe
  if (!fs.existsSync(pastaAbsoluta)) {
    fs.mkdirSync(pastaAbsoluta, { recursive: true });
  }

  while ((match = regex.exec(html)) !== null) {
    const [tagCompleta, tipo, base64] = match;
    const buffer = Buffer.from(base64, 'base64');
    const nomeArquivo = `img_${Date.now()}_${Math.random().toString(36).substring(7)}.${tipo}`;
    const caminhoAbsoluto = path.join(pastaAbsoluta, nomeArquivo);
    const urlPublica = `${pastaPublica}/${nomeArquivo}`; // Ex: /uploads/imagem_modelo/xxx.png

    const p = fs.promises.writeFile(caminhoAbsoluto, buffer)
      .then(() => {
        html = html.replace(tagCompleta, `<img src="${urlPublica}" />`);
      })
      .catch(console.error);

    promises.push(p);
  }

  await Promise.all(promises);
  return html;
}
 
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { nome, id_tipo_modelo, modelo = true, ativo = true, conteudo_html, descricao } = req.body;

  if (!nome || !id_tipo_modelo) {
    return res.status(400).json({ erro: 'Campos Nome e Tipo de Modelo são obrigatórios.' });
  }

  try {
    const checkQuery = 'SELECT 1 FROM template_modelo WHERE nome = $1 LIMIT 1';
    const checkResult = await pool.query(checkQuery, [nome]);

    if (checkResult.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe um modelo com este nome.' });
    }

    const userId = req.usuario.cd_usuario;
    const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

    const insertQuery = `
      INSERT INTO template_modelo
      (nome, id_tipo_modelo, modelo, ativo, conteudo_html, descricao, criado_em, criado_por)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING id_modelo;
    `;

    const values = [nome, id_tipo_modelo, modelo, ativo, conteudo_html || null, descricao || null, dataAtual, userId];

    const result = await pool.query(insertQuery, values);

    res.status(201).json({
      mensagem: 'Modelo cadastrado com sucesso!',
      id_modelo: result.rows[0].id_modelo
    });
  } catch (err) {
    console.error('Erro ao cadastrar modelo:', err);
    logger.error('Erro ao cadastrar modelo: ' + err.stack, 'modelo');
    res.status(500).json({ erro: 'Erro ao cadastrar modelo.' });
  }
});

// PUT /modelo/alterar/:id
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { nome, id_tipo_modelo, modelo, ativo, conteudo_html, descricao } = req.body;

  const updateFields = [];
  const updateValues = [];

  if (nome) {
    updateFields.push(`nome = $${updateValues.length + 1}`);
    updateValues.push(nome);
  }

  if (id_tipo_modelo !== undefined) {
    updateFields.push(`id_tipo_modelo = $${updateValues.length + 1}`);
    updateValues.push(id_tipo_modelo);
  }

  if (typeof modelo !== 'undefined') {
    updateFields.push(`modelo = $${updateValues.length + 1}`);
    updateValues.push(modelo);
  }

  if (typeof ativo !== 'undefined') {
    updateFields.push(`ativo = $${updateValues.length + 1}`);
    updateValues.push(ativo);
  }

 if (conteudo_html !== undefined) {
 // const htmlFinal = await processarImagensBase64(conteudo_html);
  updateFields.push(`conteudo_html = $${updateValues.length + 1}`);
  updateValues.push(conteudo_html);
}

  if (descricao !== undefined) {
    updateFields.push(`descricao = $${updateValues.length + 1}`);
    updateValues.push(descricao);
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
    UPDATE template_modelo
    SET ${updateFields.join(', ')}
    WHERE id_modelo = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(query, updateValues);

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Modelo não encontrado.' });
    }

    res.json({
      mensagem: 'Modelo alterado com sucesso!',
      modelo: result.rows[0]
    });
  } catch (err) {
    console.error('Erro ao alterar modelo:', err);
    logger.error('Erro ao alterar modelo: ' + err.stack, 'modelo');
    res.status(500).json({ erro: 'Erro ao alterar modelo.' });
  }
});

  router.get('/listar', verificarToken, async (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const { nome, id_tipo_modelo, tipo_modelo, ativo, q , complementar } = req.query;

    const filtros = [];
    const valores = [];

    if (nome) {
      valores.push(`%${nome}%`);
      filtros.push(`unaccent(tm.nome) ILIKE unaccent($${valores.length})`);
    }

    if (id_tipo_modelo) {
      valores.push(id_tipo_modelo);
      filtros.push(`tm.id_tipo_modelo = $${valores.length}`);
    }

    if (tipo_modelo) {
      let tipoNormalizado = tipo_modelo;

      // se chegar "Jovem_Aprendiz", considerar "Aprendiz"
      if (tipo_modelo.trim().toLowerCase() === 'jovem_aprendiz') {
        tipoNormalizado = 'Aprendiz';
      }

      valores.push(tipoNormalizado);
      filtros.push(`unaccent(upper(ttm.tipo_modelo)) = unaccent(upper($${valores.length}))`);
    }

    if (ativo !== undefined) {
      valores.push(ativo === 'true');
      filtros.push(`tm.ativo = $${valores.length}`);
    }

    // 🔍 Pesquisa genérica por 'q' (nome ou id_modelo)
    if (q) {
      valores.push(`%${q}%`);
      filtros.push(`(unaccent(tm.nome) ILIKE unaccent($${valores.length}) OR CAST(tm.id_modelo AS TEXT) ILIKE $${valores.length})`);
    }

    if (typeof complementar !== 'undefined') {
    valores.push(complementar === 'true');
    filtros.push(`complementar = $${valores.length}`);
  }  
    const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

    const countQuery = `
      SELECT COUNT(*) 
      FROM template_modelo tm
      LEFT JOIN template_tipo_modelo ttm ON tm.id_tipo_modelo = ttm.id_tipo_modelo
      ${where}
    `;

    const baseQuery = `
      SELECT 
        tm.id_modelo, tm.nome, tm.id_tipo_modelo, tm.modelo, tm.ativo, 
        tm.conteudo_html, tm.descricao, tm.criado_em, tm.criado_por, 
        tm.alterado_em, tm.alterado_por,
        ttm.tipo_modelo
      FROM template_modelo tm
      LEFT JOIN template_tipo_modelo ttm ON tm.id_tipo_modelo = ttm.id_tipo_modelo
      ${where}
      ORDER BY tm.nome
    `;

    try {
      const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
      res.json(resultado);
    } catch (err) {
      console.error('Erro ao listar modelos:', err);
      logger.error('Erro ao listar modelos: ' + err.stack, 'modelo');
      res.status(500).json({ erro: 'Erro ao listar modelos.' });
    }
  });



module.exports = router;
