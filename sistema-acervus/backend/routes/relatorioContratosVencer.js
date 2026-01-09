// routes/relatorioContratosVencer.js
const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken } = require('../auth');
const logger = require('../utils/logger');
const { Parser } = require('@json2csv/plainjs');
const nodemailer = require('nodemailer');
const puppeteer = require('puppeteer');
 const { sendEmail } = require('../utils/emailService');

// -------- helpers -------- //
function parseBool(v) {
  return String(v).toLowerCase() === 'true';
}

function normalizaPeriodo(dtIni, dtFim) {
  // espera 'DD/MM/YYYY'
  const [di, mi, yi] = dtIni.split('/');
  const [df, mf, yf] = dtFim.split('/');
  // para comparação no SQL, uso YYYY-MM-DD
  return {
    iniISO: `${yi}-${mi}-${di}`,
    fimISO: `${yf}-${mf}-${df}`
  };
}

// aceita: 'A', 'C', 'D', 'ATIVO', 'CANCELADO', 'DESLIGADO' (case-insensitive)
function normalizeStatus(s) {
  if (!s) return null;
  const v = String(s).trim().toUpperCase();
  if (v === 'A' || v === 'ATIVO') return 'A';
  if (v === 'C' || v === 'CANCELADO') return 'C';
  // D = desligado/encerrado/terminado (se seu sistema usa só 'D' para “fim”)
  if (v === 'D' || v === 'DESLIGADO' || v === 'ENCERRADO' || v === 'TERMINADO') return 'D';
  return null;
}

// suporta lista separada por vírgula: status=A,D  ou  status=ativo,desligado
function parseStatusList(param) {
  if (!param) return null;
  const parts = String(param).split(',').map(p => normalizeStatus(p)).filter(Boolean);
  return parts.length ? [...new Set(parts)] : null; // unique
}

 // -------- helpers -------- //
 function buildBaseQuery({ tipo, unidadeGestora, empresa, terminoIni, terminoFim, terminadosAte, statusParam }) {
  const filtros = [];
  const valores = [];
  let i = 0;

  const tipoMap = { aprendiz: 1, estagio: 2 };
  const tipoNum = tipoMap[(tipo || 'estagio').toLowerCase()] || 2;

  const { iniISO, fimISO } = normalizaPeriodo(terminoIni, terminoFim);
  filtros.push(`c.data_termino BETWEEN $${++i}::date AND $${++i}::date`);
  valores.push(iniISO, fimISO);

  filtros.push(`c.tipo_contrato = $${++i}`);
  valores.push(tipoNum);

  if (empresa) {
    filtros.push(`unaccent(upper(c.nome_fantasia)) ILIKE unaccent(upper($${++i}))`);
    valores.push(`%${empresa}%`);
  }

  // ---- STATUS ----
  const statusList = parseStatusList(statusParam);
  if (statusList && statusList.length) {
    // status explicitamente solicitado (um ou vários)
    const placeholders = statusList.map(() => `$${++i}`).join(', ');
    filtros.push(`c.status IN (${placeholders})`);
    valores.push(...statusList);
  } else if (terminadosAte) {
    // sem status explícito: A + D (terminados até a data)
    filtros.push(`(c.status = 'A' OR (c.status = 'D' AND c.data_termino <= $${++i}::date))`);
    valores.push(terminadosAte.split('/').reverse().join('-'));
  } else {
    // padrão: somente ATIVOS
    filtros.push(`c.status = 'A'`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  //aletarra o sel para trazer a data de inicio

  const sql = `
   select c.*,         (c.data_termino::date - c.data_inicio_date::date) AS dias_vigencia
 ,  CASE 
        WHEN (c.data_termino::date - c.data_inicio_date::date) >= 650 
        THEN '⚠️ Próximo de 2 anos'
        ELSE ''
    END AS alerta_2_anos
    from (SELECT
      c.cd_contrato,
      e.cd_empresa,
      COALESCE(e.nome_fantasia, e.razao_social) AS nome_fantasia,
      cand.nome_completo                         AS estudante,
	  c.data_termino dt_vigencia, 
    (SELECT MAX(ca.data_termino)                                                  
                     FROM contrato ca
                     WHERE (ca.cd_contrato = c.cd_contrato OR ca.cd_contrato_origem = c.cd_contrato)
                       AND ca.data_termino IS NOT NULL)   AS data_termino,
      e.email                                    AS email_empresa,
      sup.email                                  AS email_supervisor,
      sup.nome                                   AS nome_supervisor,
	  aditivo, cd_contrato_origem, c.tipo_contrato, c.status
    , to_char(c.data_inicio, 'DD/MM/YYYY') AS data_inicio
    , c.data_inicio AS data_inicio_date
    FROM public.contrato c
    JOIN public.empresa e           ON e.cd_empresa = c.cd_empresa
    JOIN public.candidato cand      ON cand.cd_candidato = c.cd_estudante
    LEFT JOIN public.supervisor sup ON sup.cd_supervisor = c.cd_supervisor
	where coalesce(aditivo,false) = false
	) c 
      ${where}
	
    ORDER BY nome_fantasia, c.data_termino, estudante
    
   
   
  `;
  //imprimir sql completo ja com paramteros
  console.log('SQL Relatório Contratos a Vencer:', sql, valores);

  console.log('SQL Relatório Contratos a Vencer:', sql, valores);
  return { sql, valores, tabela: 'contrato' };
}


function htmlRelatorio({ unidadeGestora, periodoIni, periodoFim, linhas }) {
  return `
<!doctype html>
<html lang="pt-br">
<head>
<meta charset="utf-8">
<title>Relação Contratos a Vencer</title>
<style>
  body { font-family: Arial, Helvetica, sans-serif; font-size: 12px; color: #222; }
  h1 { font-size: 16px; margin: 0 0 6px 0; }
  .sub { margin: 0 0 12px 0; }
  table { width: 100%; border-collapse: collapse; }
  th, td { border: 1px solid #999; padding: 6px 8px; }
  th { background: #E9D1DB; text-align: left; }
  .muted { color: #666; font-size: 11px; }
</style>
</head>
<body>
  <h1>Relação Contratos a Vencer</h1>
  <div class="sub">
    <div><strong>Unidade Gestora:</strong> ${unidadeGestora || 'TODAS'}</div>
    <div><strong>Período:</strong> ${periodoIni} à ${periodoFim}</div>
    <div class="muted">${linhas.length} registro(s) encontrado(s)</div>
  </div>
  <table>
    <thead>
      <tr>
        <th>Nome Fantasia</th>
        <th>Estudante</th>
        <th>Data de Início</th>
        <th>Data Término</th>
        <th>Supervisor</th>
        <th>Tempo de Vigência (Dias)</th>
        <th>Alerta</th>
      </tr>
    </thead>
    <tbody>
      ${linhas.map(l => `
        <tr>
          <td>${l.nome_fantasia || ''}</td>
          <td>${l.estudante || ''}</td>
          <td>${l.data_inicio || ''}</td>
         <td>${l.data_termino ? new Date(l.data_termino).toLocaleDateString('pt-BR') : ''}</td>

          <td>${l.nome_supervisor || ''}</td>
            <td>${l.dias_vigencia || ''}</td>
            <td>${l.alerta_2_anos || ''}</td>
        </tr>`).join('')}
    </tbody>
  </table>
</body>
</html>`;
}

async function gerarPdf(html) {
  const browser = await puppeteer.launch({ args: ['--no-sandbox','--disable-setuid-sandbox'] });
  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'networkidle0' });
    return await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: { top: '10mm', bottom: '10mm', left: '8mm', right: '8mm' }
    });
  } finally { await browser.close(); }
}

// -------- ROTAS -------- //

// GET /relatorios/contratos-a-vencer?tipo=estagio|aprendiz&unidadeGestora=Todas&empresa=&terminoIni=01/08/2025&terminoFim=31/08/2025&terminadosAte=&formato=json|csv|pdf
router.get('/contratos-a-vencer', verificarToken, async (req, res) => {
  try {
    const {
      tipo = 'estagio',
      unidadeGestora,
      empresa,
      terminoIni,
      terminoFim,
      terminadosAte,
      formato = 'json'
    } = req.query;

    if (!terminoIni || !terminoFim) {
      return res.status(400).json({ erro: 'Informe terminoIni e terminoFim no formato DD/MM/YYYY.' });
    }

    const { sql, valores } = buildBaseQuery({
      tipo, unidadeGestora, empresa, terminoIni, terminoFim, terminadosAte
    });

    const r = await pool.query(sql, valores);
    const linhas = r.rows;

    if (formato === 'csv') {
      const fields = [
        { label: 'Nome Fantasia', value: 'nome_fantasia' },
   
        { label: 'Estudante', value: 'estudante' },
         { label: 'Data Inicio', value: 'data_inicio' },
        { label: 'Data Término', value: 'data_termino' },
        { label: 'Supervisor', value: 'nome_supervisor' },
        { label: 'Alerta', value: 'alerta_2_anos' },
        {label: 'Dias de Vigência', value: 'dias_vigencia' }
      ];
      const parser = new Parser({ fields, withBOM: true });
      const csv = parser.parse(linhas);
      const dt = new Date().toISOString().slice(0,10);
      res.setHeader('Content-Type', 'text/csv; charset=UTF-8');
      res.setHeader('Content-Disposition', `attachment; filename=contratos-a-vencer-${dt}.csv`);
      return res.send(csv);
    }

    if (formato === 'pdf') {
      const html = htmlRelatorio({
        unidadeGestora,
        periodoIni: terminoIni,
        periodoFim: terminoFim,
        linhas
      });
      //print linhas
      console.log(linhas);

      const pdf = await gerarPdf(html);
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'inline; filename=contratos-a-vencer.pdf');
      return res.send(pdf);
    }

    // default json + paginação se quiser encaixar seu paginarConsulta
    return res.json({ total: linhas.length, dados: linhas });

  } catch (err) {
    logger.error('Erro ao gerar Relatório Contratos a Vencer: ' + err.stack, 'relatorio');
    res.status(500).json({ erro: 'Erro ao gerar relatório.' + err.message });
  }
});

// POST /relatorios/contratos-a-vencer/disparar-emails
// body: { tipo, unidadeGestora, empresa, terminoIni, terminoFim, terminadosAte, enviarParaSupervisor: true|false, cc: "rh@cide..." }
router.post('/contratos-a-vencer/disparar-emails', verificarToken, async (req, res) => {
  const {
    tipo = 'estagio',
    unidadeGestora,
    empresa,
    terminoIni,
    terminoFim,
    terminadosAte,
    enviarParaSupervisor = true,
    cc
  } = req.body || {};

  if (!terminoIni || !terminoFim) {
    return res.status(400).json({ erro: 'Informe terminoIni e terminoFim no formato DD/MM/YYYY.' });
  }

  try {
    const { sql, valores } = buildBaseQuery({
      tipo, unidadeGestora, empresa, terminoIni, terminoFim, terminadosAte
    });
    const r = await pool.query(sql, valores);
    const linhas = r.rows;

    // agrupa por empresa (1 e-mail por empresa)
    const porEmpresa = new Map();
    for (const l of linhas) {
      if (!porEmpresa.has(l.cd_empresa)) porEmpresa.set(l.cd_empresa, { info: l, itens: [] });
      porEmpresa.get(l.cd_empresa).itens.push(l);
    }

  
    let enviados = 0, pulados = 0, erros = 0, logs = [];

    for (const [, grp] of porEmpresa) {
      const to = (grp.info.email_empresa || '').trim();
      const supervisorEmails = enviarParaSupervisor && grp.itens
        .map(x => (x.email_supervisor || '').trim())
        .filter((v, i, arr) => v && arr.indexOf(v) === i);

      if (!to && (!supervisorEmails || supervisorEmails.length === 0)) {
        pulados++;
        logs.push(`Sem e-mail para empresa ${grp.info.nome_fantasia}`);
        continue;
      }

      const htmlLista = `
        <p>Prezados,</p>
        <p>Segue a lista de contratos com término entre <strong>${terminoIni}</strong> e <strong>${terminoFim}</strong>.</p>
        <table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:Arial;font-size:12px;">
          <thead style="background:#E9D1DB;">
            <tr>
              <th>Estudante</th><th>Data Início</th><th>Data Término</th><th>Supervisor</th><th>Alerta</th>
            </tr>
          </thead>
          <tbody>
            ${grp.itens.map(i => `
              <tr>
                <td>${i.estudante || ''}</td>
                 <td>${i.data_inicio || ''}</td>
                <td>${l.data_termino ? new Date(l.data_termino).toLocaleDateString('pt-BR') : ''}</td>

                
                <td>${i.nome_supervisor || ''}</td>
                  <td>${i.alerta_2_anos || ''}</td>
              </tr>`).join('')}
          </tbody>
        </table>
        <p>Qualquer dúvida, estamos à disposição.</p>
      `;

     const result = await sendEmail({
        to: to || 'nanpeixoto@gmail.com', // fallback fixo
        cc,
        bcc: supervisorEmails && supervisorEmails.length ? supervisorEmails : undefined,
        subject: `Contratos a vencer (${terminoIni} a ${terminoFim}) - ${grp.info.nome_fantasia}`,
        html: htmlLista
      });

      if (result.success) {
        enviados++;
      } else {
        erros++;
        logs.push(`Falha ao enviar para ${to || supervisorEmails?.join(',')}: ${result.error}`);
      }
    }

    return res.json({ totalEmpresas: porEmpresa.size, enviados, pulados, erros, logs });

  } catch (err) {
    logger.error('Erro ao disparar e-mails do Relatório Contratos a Vencer: ' + err.stack, 'relatorio');
    res.status(500).json({ erro: 'Erro ao enviar e-mails.' });
  }
});

module.exports = router;
