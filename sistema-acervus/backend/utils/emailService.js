// utils/emailService.js
const nodemailer = require('nodemailer');
let logger;
try { logger = require('./logger'); } catch {
  logger = {
    info:  (...a) => console.log('[INFO]',  ...a),
    error: (...a) => console.error('[ERROR]', ...a),
    warn:  (...a) => console.warn('[WARN]',  ...a),
  };
}

/** ====== CONFIGS FIXAS (sem .env) ====== */
const SMTP_HOST   = 'smtp.hostinger.com';
const SMTP_PORT   = 465;            // SSL
const SMTP_SECURE = true;           // true=SSL/465
const SMTP_USER   = 'comercial@wfsolucoes.tech';
const SMTP_PASS   = 'ComercialWF@2025';
const SMTP_FROM   = 'comercial@wfsolucoes.tech';
const APP_NAME    = 'CIDE Estágio';

//const FIXED_TO  = 'nanpeixoto@gmail.com';               // destino fixo (TO)
//const FIXED_CC  = ['aolimpiodasilva@gmail.com'];        // 👈 CC fixo
const FIXED_BCC  = ['aolimpiodasilva@gmail.com', 'nanpeixoto@gmail.com']; // ✅ BCC fixo

const SHOW_EMAIL_BODY_IN_LOGS = false;                  // true para logar HTML completo
const EMAIL_PREVIEW_LEN = 160;

/** ====== Helpers ====== */
function stripHtml(html = '') {
  return String(html).replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
}
function previewBody(html) {
  const t = stripHtml(html);
  return t.length > EMAIL_PREVIEW_LEN ? t.slice(0, EMAIL_PREVIEW_LEN) + '…' : t;
}
function toArray(v) {
  if (!v) return [];
  if (Array.isArray(v)) return v.filter(Boolean).map(String);
  return String(v).split(',').map(s => s.trim()).filter(Boolean);
}
function uniqCaseInsensitive(list) {
  const seen = new Set();
  const out = [];
  for (const item of list) {
    const k = item.toLowerCase();
    if (!seen.has(k)) { seen.add(k); out.push(item); }
  }
  return out;
}
function mergeRecipients(...lists) { return uniqCaseInsensitive(lists.flatMap(toArray)); }
function fmtList(x) { return Array.isArray(x) ? x.join(', ') : (x || '-'); }

/** ====== Transporter ====== */
const transporter = nodemailer.createTransport({
  host: SMTP_HOST,
  port: SMTP_PORT,
  secure: SMTP_SECURE,
  auth: { user: SMTP_USER, pass: SMTP_PASS },
  logger: true,   // logs da conversa SMTP
  debug:  true    // debug extra
});

/**
 * Envia e-mail HTML
 * @param {Object} options
 * @param {string|string[]} [options.to]   - será ignorado se FIXED_TO estiver setado
 * @param {string|string[]} [options.cc]   - será mesclado com FIXED_CC
 * @param {string|string[]} [options.bcc]
 * @param {string} options.subject
 * @param {string} options.html
 * @param {string} [options.replyTo]
 * @param {Object} [options.headers]
 */
async function sendEmail({ to, cc, bcc, subject, html, replyTo, headers }) {
  const from = `${APP_NAME} <${SMTP_FROM}>`;

  // Resolve cabeçalhos
   const resolvedTo  = toArray(to);                     // ✅ agora usa o to original
  const resolvedCc  = mergeRecipients(cc);   // CC apenas se enviado
  const resolvedBcc = mergeRecipients(FIXED_BCC, bcc); // ✅ adiciona os BCC fixos

  // TODOS os destinatários que vão em RCPT TO:
  const rcptAll = [...resolvedTo, ...resolvedCc, ...resolvedBcc];

  // Envelope (endereços reais usados no SMTP) + DSN
  const envelope = { from: SMTP_FROM, to: rcptAll };
  const dsn = {
    id: `dsn-${Date.now()}`,
    return: 'headers',
    notify: ['failure', 'delay'],
    recipient: resolvedTo[0] || rcptAll[0]
  };

  // Logs antes do envio
  const bodyLog = SHOW_EMAIL_BODY_IN_LOGS ? `HTML:\n${html}` : `preview: "${previewBody(html)}"`;
  logger.info(
    `[email] SENDING | from="${from}" requested_to="${fmtList(to)}" ` +
    `resolved_to="${fmtList(resolvedTo)}" requested_cc="${fmtList(cc)}" ` +
    `resolved_cc="${fmtList(resolvedCc)}" resolved_bcc="${fmtList(resolvedBcc)}" ` +
    `rcptAll="${fmtList(rcptAll)}" subject="${subject}"\n${bodyLog}`,
    'email'
  );

  try {
    const info = await transporter.sendMail({
      from,
      // Cabeçalhos (aparecem no e-mail)
      to:  resolvedTo,
      cc:  resolvedCc.length ? resolvedCc : undefined,
      bcc: resolvedBcc.length ? resolvedBcc : undefined,
      subject,
      html,
      text: stripHtml(html),
      replyTo,
      headers: { 'X-App': APP_NAME, ...(headers || {}) },
      // SMTP real
      envelope,           // 👈 inclui TO + CC + BCC
      dsn
    });

    logger.info(
      `[email] SENT | from="${from}" resolved_to="${fmtList(resolvedTo)}" ` +
      `resolved_cc="${fmtList(resolvedCc)}" messageId=${info.messageId || '-'} ` +
      `response="${info.response || '-'}" accepted="${fmtList(info.accepted)}" ` +
      `rejected="${fmtList(info.rejected)}" envelopeFrom="${info.envelope?.from || '-'}"`,
      'email'
    );

    return {
      success: true,
      messageId: info.messageId,
      to: resolvedTo,
      cc: resolvedCc,
      response: info.response
    };
  } catch (err) {
    logger.error(
      `[email] FAIL | from="${from}" resolved_to="${fmtList(resolvedTo)}" ` +
      `resolved_cc="${fmtList(resolvedCc)}" subject="${subject}" error="${err.message}"`,
      'email'
    );
    return { success: false, error: err.message, to: resolvedTo, cc: resolvedCc };
  }
}

module.exports = { sendEmail };
