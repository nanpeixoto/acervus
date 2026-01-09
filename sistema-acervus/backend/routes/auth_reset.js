const express = require('express');
const router = express.Router();
const pool = require('../db');
const md5 = require('md5');
const { sendEmail } = require('../utils/emailService'); // 👈 usa o serviço central
const logger = require('../utils/logger'); // <-- adiciona


// ==== Utils ====
function gen6() {
  return String(Math.floor(100000 + Math.random() * 900000));
}
function isMd5(str) {
  return typeof str === 'string' && /^[a-f0-9]{32}$/i.test(str);
}
function hashIfNeeded(raw) {
  if (raw == null) return raw;
  const s = String(raw).trim();
  return isMd5(s) ? s : md5(s);
}

// Envia o código via serviço central
async function sendResetCodeEmail(to, code) {
  const appName = process.env.APP_NAME || 'CIDE Estágio';
  const subject = `Código de redefinição de senha (${appName})`;
  const html = `
    <p>Olá,</p>
    <p>Seu código para redefinição de senha é:</p>
    <h2 style="letter-spacing:3px">${code}</h2>
    <p>Ele expira em <b>10 minutos</b>.</p>
    <p>Se você não solicitou, ignore este e-mail.</p>
  `;
  return await sendEmail({ to, subject, html });
}

/**
 * POST /auth/request-reset
 * body: { email, tipo? } // 'usuario' | 'candidato'
 */
router.post('/request-reset', async (req, res) => {
  const { email, tipo } = req.body;
  if (!email) return res.status(400).json({ erro: 'Informe o e-mail.' });

  const ip = req.ip || null;
  const ua = req.headers['user-agent'] || null;
  const showCodeInLogs = (process.env.SHOW_RESET_CODE_IN_LOGS === 'true');

  const startedAt = Date.now();
  logger.info(`[auth/request-reset] start email="${email}" tipo="${tipo || '-'}" ip=${ip} ua="${ua}"`, 'auth-reset');

  try {
    const client = await pool.connect();
    let found = null;

    // Resolve o perfil/origem
    if (tipo === 'candidato') {
      const rC = await client.query(
        `SELECT cd_candidato AS id, email FROM public.candidato WHERE email = $1 LIMIT 1`,
        [email]
      );
      if (rC.rowCount > 0) {
        found = {
          entity_type: 'candidato',
          entity_id: rC.rows[0].id,
          email: rC.rows[0].email,
          perfil: null // candidato não tem "perfil" da tabela usuarios
        };
      }
    } else {
      const rU = await client.query(
        `SELECT cd_usuario AS id, email, perfil FROM public.usuarios WHERE email = $1 LIMIT 1`,
        [email]
      );
      if (rU.rowCount > 0) {
        found = {
          entity_type: 'usuario',
          entity_id: rU.rows[0].id,
          email: rU.rows[0].email,
          perfil: rU.rows[0].perfil // 👈 perfil vindo da tabela usuarios
        };
      } else {
        const rC = await client.query(
          `SELECT cd_candidato AS id, email FROM public.candidato WHERE email = $1 LIMIT 1`,
          [email]
        );
        if (rC.rowCount > 0) {
          found = {
            entity_type: 'candidato',
            entity_id: rC.rows[0].id,
            email: rC.rows[0].email,
            perfil: null
          };
        }
      }
    }

    // Se não achou, loga e responde explicitamente
    if (!found) {
      client.release();
      logger.info(
        `[auth/request-reset] not_found email="${email}" elapsed=${Date.now() - startedAt}ms`,
        'auth-reset'
      );
      return res.json({
        emailExiste: false,
        perfil: null,      // origem
        perfilDb: null,    // perfil vindo da tabela usuarios (não encontrado)
        mensagem: 'E-mail não encontrado.'
      });
    }

    // Log de "found" com o perfil da tabela usuarios (se houver)
    logger.info(
      `[auth/request-reset] found email="${email}" tipo=${found.entity_type} perfilUsuario=${found.perfil ?? '-'} id=${found.entity_id}`,
      'auth-reset'
    );

    // Gera token
    const code = gen6();
    const codeHash = md5(code);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 min

    // Insere e pega o id para log
    const insert = await client.query(
      `INSERT INTO public.password_reset
         (entity_type, entity_id, email, code_hash, expires_at, ip, user_agent)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING id`,
      [
        found.entity_type,
        found.entity_id,
        found.email,
        codeHash,
        expiresAt,
        ip,
        ua
      ]
    );
    const tokenId = insert.rows[0]?.id;

    client.release();

    // Envia e-mail
    let emailSendOk = false;
    let messageId = null;
    try {
      const r = await sendResetCodeEmail(found.email, code);
      emailSendOk = !!r?.success || !!r?.messageId;
      messageId = r?.messageId || null;
    } catch (e) {
      logger.error(`[auth/request-reset] send_email_fail email="${email}" err="${e.message}"`, 'auth-reset');
    }

    // Log final
    const codeLog = showCodeInLogs ? code : '******';
    logger.info(
      `[auth/request-reset] ok email="${email}" tipo=${found.entity_type} perfilUsuario=${found.perfil ?? '-'} token_id=${tokenId} expira="${expiresAt.toISOString()}" email_enviado=${emailSendOk} messageId=${messageId || '-'} code=${codeLog} elapsed=${Date.now() - startedAt}ms`,
      'auth-reset'
    );

    // Retorno (mantém compat e inclui perfilDb)
    return res.json({
      emailExiste: true,
      tipo: found.entity_type,            // 'usuario' | 'candidato'
      perfil: found.entity_type,          // (compat) se já consumido no front
      perfilDb: found.perfil ?? null,     // 👈 perfil REAL da tabela usuarios
      mensagem: emailSendOk ? 'Código enviado por e-mail.' : 'Código gerado, mas houve falha ao enviar e-mail.',
      tokenId,
      expiraEm: expiresAt,
      emailEnviado: emailSendOk
    });
  } catch (err) {
    logger.error(`[auth/request-reset] error email="${email}" err="${err.message}"`, 'auth-reset');
    return res.status(500).json({ erro: 'Erro ao solicitar redefinição de senha.' });
  }
});

/**
 * POST /auth/confirm-reset
 * body: { email, code, nova_senha, tipo? }
 */
router.post('/confirm-reset', async (req, res) => {
  const { email, code, nova_senha, tipo } = req.body;
  if (!email || !code || !nova_senha)
    return res.status(400).json({ erro: 'email, code e nova_senha são obrigatórios.' });

  if (String(nova_senha).length < 6)
    return res.status(400).json({ erro: 'A nova senha deve ter ao menos 6 caracteres.' });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const params = [email];
    let sql = `
      SELECT *
      FROM public.password_reset
      WHERE email = $1
        AND used_at IS NULL
        AND expires_at >= NOW()
    `;
    if (tipo === 'usuario' || tipo === 'candidato') {
      sql += ` AND entity_type = $2 `;
      params.push(tipo);
    }
    sql += ` ORDER BY created_at DESC LIMIT 1`;

    const tk = await client.query(sql, params);
    if (tk.rowCount === 0) {
      await client.query('COMMIT');
      return res.status(400).json({ erro: 'Código inválido ou expirado.' });
    }

    const token = tk.rows[0];
    if (token.code_hash !== md5(String(code).trim())) {
      await client.query(`UPDATE public.password_reset SET attempts = attempts + 1 WHERE id = $1`, [token.id]);
      await client.query('COMMIT');
      return res.status(400).json({ erro: 'Código inválido.' });
    }

    const newHash = hashIfNeeded(nova_senha);
    if (token.entity_type === 'usuario') {
      await client.query(`UPDATE public.usuarios SET senha = $1 WHERE cd_usuario = $2`, [newHash, token.entity_id]);
    } else {
      await client.query(`UPDATE public.candidato SET senha = $1 WHERE cd_candidato = $2`, [newHash, token.entity_id]);
    }

    await client.query(`UPDATE public.password_reset SET used_at = NOW() WHERE id = $1`, [token.id]);

    await client.query('COMMIT');
    return res.json({ mensagem: 'Senha alterada com sucesso.' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erro em /auth/confirm-reset:', err);
    return res.status(500).json({ erro: 'Erro ao confirmar redefinição de senha.' });
  } finally {
    client.release();
  }
});

module.exports = router;
