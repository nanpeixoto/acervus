// routes/documentosComplementares.js
const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken } = require('../auth');
const logger = require('../utils/logger');
const puppeteer = require('puppeteer');
const { gerarHtmlComTagsSubstituidas } = require('../services/templateDataService');

/** Util: gerar PDF com Puppeteer */
async function gerarPdfDoHtml(html) {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'networkidle0' });
    return await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: { top: '10mm', bottom: '10mm', left: '10mm', right: '10mm' }
    });
  } finally {
    await browser.close();
  }
}

/**
 * GET /contratos/:id/documentos-complementares/preview?cd_template_modelo=#
 * - Se existe salvo → retorna
 * - Se não → gera do template
 */
router.get('/contratos/:id/preview', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { cd_template_modelo } = req.query;

  if (!id || !cd_template_modelo) {
    return res.status(400).json({ erro: 'id (contrato) e cd_template_modelo são obrigatórios.' });
  }

  try {
    const { rows } = await pool.query(
      `SELECT cd_doc_complementar, conteudo_html,
              criado_por, data_criacao, alterado_por, data_alteracao
         FROM public.contrato_documento_complementar
        WHERE cd_contrato = $1 AND cd_template_modelo = $2`,
      [id, cd_template_modelo]
    );

    if (rows.length) {
      return res.json({ origem: 'salvo', ...rows[0] });
    }

    // Se não tem salvo → gerar a partir do template
    const htmlGerado = await gerarHtmlComTagsSubstituidas(id, cd_template_modelo);
    return res.json({ origem: 'gerado', conteudo_html: htmlGerado });
  } catch (error) {
    logger.error('Preview doc compl: ' + error.stack, 'documentos-complementares');
    return res.status(500).json({ erro: 'Erro ao gerar pré-visualização.' + error.stack });
  }
});

/**
 * POST /contratos/:id/documentos-complementares
 * Upsert: cria ou sobrescreve
 * Body: { cd_template_modelo, conteudo_html }
 */
router.post('/contratos/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { cd_template_modelo, conteudo_html } = req.body;
  const usuario = req.usuario?.cd_usuario;

  if (!id || !cd_template_modelo || !conteudo_html) {
    return res.status(400).json({ erro: 'id, cd_template_modelo e conteudo_html são obrigatórios.' });
  }
  if (!usuario) {
    return res.status(401).json({ erro: 'Usuário não identificado no token.' });
  }

  try {
    const sql = `
      INSERT INTO public.contrato_documento_complementar
        (cd_contrato, cd_template_modelo, conteudo_html, criado_por, data_criacao)
      VALUES ($1,$2,$3,$4,NOW())
      ON CONFLICT (cd_contrato, cd_template_modelo)
      DO UPDATE SET
        conteudo_html = EXCLUDED.conteudo_html,
        alterado_por  = $4,
        data_alteracao= NOW()
      RETURNING cd_doc_complementar, cd_contrato, cd_template_modelo, data_criacao, data_alteracao
    `;

    const { rows } = await pool.query(sql, [
      id, cd_template_modelo, conteudo_html, usuario
    ]);

    return res.status(200).json({ mensagem: 'Documento complementar salvo.', ...rows[0] });
  } catch (error) {
    logger.error('Salvar doc compl: ' + error.stack, 'documentos-complementares');
    return res.status(500).json({ erro: 'Erro ao salvar documento complementar.' });
  }
});

/**
 * GET /contratos/:id/documentos-complementares?cd_template_modelo=#
 * Retorna o salvo (se existir)
 */
router.get('/contratos/:id/documentos-complementares', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { cd_template_modelo } = req.query;

  if (!id || !cd_template_modelo) {
    return res.status(400).json({ erro: 'id e cd_template_modelo são obrigatórios.' });
  }

  try {
    const { rows } = await pool.query(
      `SELECT cd_doc_complementar, conteudo_html,
              criado_por, data_criacao, alterado_por, data_alteracao
         FROM public.contrato_documento_complementar
        WHERE cd_contrato = $1 AND cd_template_modelo = $2`,
      [id, cd_template_modelo]
    );
    if (!rows.length) {
      return res.status(404).json({ erro: 'Documento complementar não encontrado.' });
    }
    return res.json(rows[0]);
  } catch (error) {
    logger.error('Obter doc compl: ' + error.stack, 'documentos-complementares');
    return res.status(500).json({ erro: 'Erro ao obter documento complementar.' });
  }
});

/**
 * POST /contratos/:id/documentos-complementares/pdf
 * Gera PDF do salvo (ou do template se não existir)
 * Body: { cd_template_modelo, download = true }
 */
router.post('/contratos/:id/pdf', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { cd_template_modelo, download = true } = req.body;

  if (!id || !cd_template_modelo) {
    return res.status(400).json({ erro: 'id e cd_template_modelo são obrigatórios.' });
  }

  try {
    const { rows } = await pool.query(
      `SELECT conteudo_html
         FROM public.contrato_documento_complementar
        WHERE cd_contrato = $1 AND cd_template_modelo = $2`,
      [id, cd_template_modelo]
    );

    let html = rows.length ? rows[0].conteudo_html : null;
    if (!html) {
      html = await gerarHtmlComTagsSubstituidas(id, cd_template_modelo);
    }

    const pdfBuffer = await gerarPdfDoHtml(html);

    const nomeArquivo = `${id}-docComp-${cd_template_modelo}.pdf`;
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `${download ? 'attachment' : 'inline'}; filename="${nomeArquivo}"`
    });
    return res.send(pdfBuffer);
  } catch (error) {
    logger.error('PDF doc compl: ' + error.stack, 'documentos-complementares');
    return res.status(500).json({ erro: 'Erro ao gerar PDF do documento complementar.' });
  }
});

module.exports = router;
