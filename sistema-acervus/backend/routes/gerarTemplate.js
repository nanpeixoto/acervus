const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const puppeteer = require('puppeteer');
const sharp = require('sharp');
const {   gerarHtmlComTagsSubstituidas , obterHtmlContrato} = require('../services/templateDataService');
 


router.post('/gerar-pdf-aditivo', verificarToken, async (req, res) => {
  const { id, download = true, cd_template_modelo } = req.body;

  console.log ('Requisição recebida para gerar PDF do aditivo de estágio com id:', id, 'download:', download, 'cd_template_modelo:', cd_template_modelo);

  if (!id) {
    return res.status(400).json({ erro: 'id é obrigatório.' });
  }

  try {

    let tipo_modelo = "";
    // Busca o HTML diretamente do contrato
    const queryText = `
      SELECT tipo_modelo
      FROM public.template_modelo tm
      INNER JOIN public.template_tipo_modelo ttm
      ON tm.id_tipo_modelo = ttm.id_tipo_modelo
      WHERE tm.id_modelo = $1
    `.trim();

    const { rows: rowsTemplate } = await pool.query(queryText, [cd_template_modelo]);
    console.log('Tipo de modelo buscado:', rowsTemplate.length ? rowsTemplate[0].tipo_modelo : 'Não encontrado');

    if (!rowsTemplate || !Array.isArray(rowsTemplate) || !rowsTemplate.length || !rowsTemplate[0].tipo_modelo) {
      console.log('Tipo de modelo não encontrado para o id_modelo:', cd_template_modelo);
      return res.status(401).json({
      erro: 'Modelo de template não encontrado.',
      detalhe: queryText
      });
    } else {
      console.log('Tipo de modelo encontrado:', rowsTemplate[0].tipo_modelo);
      // preencher variavel tipo_modelo
      tipo_modelo = rowsTemplate[0].tipo_modelo;
    }
     
     //se tipo de modelo contiver a palavra estagio
     if (tipo_modelo.includes('Estagio') || tipo_modelo.includes('Aprendiz')) {
       // Busca o HTML diretamente do contrato
       const { rows } = await pool.query(
         'SELECT conteudo_html FROM contrato WHERE cd_contrato = $1',
         [id]
       );
   

       console  .log('HTML do contrato buscado:', rows.length ? 'Encontrado' : 'Não encontrado');

       if (!rows.length || !rows[0].conteudo_html) {
         return res.status(404).json({ erro: 'Contrato não encontrado ou sem conteúdo HTML.' });
       }  
    if (!rows.length || !rows[0].conteudo_html) {
      return res.status(404).json({ erro: 'Contrato não encontrado ou sem conteúdo HTML.' });
    }

    const htmlFinal = rows[0].conteudo_html;

    // Gera o PDF
    const pdfBuffer = await gerarPdfDoHtml(htmlFinal);

    // Define o tipo de resposta
    // Busca o nome do estagiário para o nome do arquivo
    const { rows: rowsEstagiario } = await pool.query(
      `SELECT e.nome_completo nm_candidato 
       FROM contrato c
       JOIN candidato e ON c.cd_estudante = e.cd_candidato
       WHERE c.cd_contrato = $1`,
      [id]
    );

    let nomeCandidado = 'candidato';
    if (rowsEstagiario.length && rowsEstagiario[0].nm_candidato) {
      nomeCandidado = rowsEstagiario[0].nm_candidato
      .replace(/[^\w\s-]/gi, '') // remove caracteres especiais
      .replace(/\s+/g, '_'); // troca espaços por _
    }

    const nomeArquivo = `${id} - ${nomeCandidado}.pdf`;

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `${download ? 'attachment' : 'inline'}; filename="${nomeArquivo}"`
    });

    res.send(pdfBuffer);
  }

      res.status(500).json({ erro: 'Erro ao gerar PDF do contrato. - Nenhum tipo parametrizado' });
  } catch (error) {
    console.error('Erro ao gerar PDF do contrato:', error);
    res.status(500).json({ erro: 'Erro ao gerar PDF do contrato.' });
  }
});

// Novo endpoint
router.post('/gerar-pdf-contrato', verificarToken, async (req, res) => {
  const { id, download = true } = req.body;

  console.log ('Requisição recebida para gerar PDF do contrato com id:', id, 'download:', download);

  if (!id) {
    return res.status(400).json({ erro: 'id é obrigatório.' });
  }

  try {
    // Busca o HTML diretamente do contrato
    const { rows } = await pool.query(
      'SELECT conteudo_html FROM contrato WHERE cd_contrato = $1',
      [id]
    );

    if (!rows.length || !rows[0].conteudo_html) {
      return res.status(404).json({ erro: 'Contrato não encontrado ou sem conteúdo HTML.' });
    }

    const htmlFinal = rows[0].conteudo_html;

    // Gera o PDF
    const pdfBuffer = await gerarPdfDoHtml(htmlFinal);

    // Define o tipo de resposta
    // Busca o nome do estagiário para o nome do arquivo
    const { rows: rowsEstagiario } = await pool.query(
      `SELECT e.nome_completo nm_candidato 
       FROM contrato c
       JOIN candidato e ON c.cd_estudante = e.cd_candidato
       WHERE c.cd_contrato = $1`,
      [id]
    );

    let nomeCandidado = 'candidato';
    if (rowsEstagiario.length && rowsEstagiario[0].nm_candidato) {
      nomeCandidado = rowsEstagiario[0].nm_candidato
      .replace(/[^\w\s-]/gi, '') // remove caracteres especiais
      .replace(/\s+/g, '_'); // troca espaços por _
    }

    const nomeArquivo = `${id} - ${nomeCandidado}.pdf`;

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `${download ? 'attachment' : 'inline'}; filename="${nomeArquivo}"`
    });

    res.send(pdfBuffer);
  } catch (error) {
    console.error('Erro ao gerar PDF do contrato:', error);
    res.status(500).json({ erro: 'Erro ao gerar PDF do contrato.' });
  }
});

// Função para gerar PDF
async function gerarPdfDoHtml(htmlContent) {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();

  await page.setContent(htmlContent, { waitUntil: 'networkidle0' });

  const pdfBuffer = await page.pdf({
    format: 'A4',
    printBackground: true,
    margin: {
      top: '10mm',
      bottom: '10mm',
      left: '10mm',
      right: '10mm'
    }
  });

  await browser.close();
  return pdfBuffer;
}


router.post('/gerar-html-contrato', verificarToken, async (req, res) => {
  const { id, idModelo } = req.body;

  if (!id || !idModelo) {
    return res.status(400).json({ erro: 'id e idModelo são obrigatórios.' });
  }

  try {
    const htmlFinal = await gerarHtmlComTagsSubstituidas(id, idModelo);

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(htmlFinal);
  } catch (error) {
    console.error('Erro ao gerar contrato HTML:', error);
    res.status(500).json({ erro: 'Erro ao gerar contrato HTML.', motivo: error.message });
  }
});

router.post('/montar-pdf-contrato', verificarToken, async (req, res) => {
  const { id, idModelo, download = true } = req.body;

  console.log ('Requisição recebida para montar PDF do contrato com id:', id, 'idModelo:', idModelo, 'download:', download);
  if (!id || !idModelo) {
    return res.status(400).json({ erro: 'id e idModelo são obrigatórios.' });
  }

  try {
    const htmlFinal = await obterHtmlContrato(id, idModelo);
    const pdfBuffer = await gerarPdfDoHtml(htmlFinal);

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `${download ? 'attachment' : 'inline'}; filename=contrato.pdf`
    });

    res.send(pdfBuffer);
  } catch (error) {
    console.error('[gerarTemplate.js]Erro ao gerar contrato PDF:', error);
    //ESCRVER NO ARQUIVO DE LOG
    logger.error('[gerarTemplate.js]Erro ao gerar contrato PDF:', error);
    res.status(500).json({ erro: '[gerarTemplate.js]Erro ao gerar contrato PDF.' + error.message });
  }
});

// Gera PDF usando Puppeteer
async function gerarPdfDoHtml(htmlContent) {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();

  await page.setContent(htmlContent, { waitUntil: 'networkidle0' });

  const pdfBuffer = await page.pdf({
    format: 'A4',
    printBackground: true,
    margin: {
      top: '10mm',
      bottom: '10mm',
      left: '10mm',
      right: '10mm'
    }
  });

  await browser.close();
  return pdfBuffer;
}



module.exports = router;
