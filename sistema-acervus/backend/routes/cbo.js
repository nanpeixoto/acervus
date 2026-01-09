// routes/cbo.js
const express = require('express');
const router = express.Router();
const app = express();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');

// ---------- Helpers ----------
function agoraISO() {
  return new Date().toISOString().split('T').join(' ').split('.')[0];
}

function sanitizarCodigoCBO(codigo) {
  if (codigo == null) return null;
  // Mantém apenas dígitos
  const onlyDigits = String(codigo).replace(/\D/g, '');
  return onlyDigits;
}

function validarCodigoCBO(codigo) {
  const d = sanitizarCodigoCBO(codigo);
  return !!d && d.length === 6;
}

// ---------- POST /cbo/cadastrar ----------
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { codigo, descricao, ativo } = req.body;

  if (!codigo) {
    return res.status(400).json({ erro: 'Campo obrigatório: codigo (CBO de 6 dígitos).' });
  }
  const codSan = sanitizarCodigoCBO(codigo);
  if (!validarCodigoCBO(codSan)) {
    return res.status(400).json({ erro: 'O código CBO deve conter exatamente 6 dígitos numéricos.' });
  }

  const userId = req.usuario.cd_usuario;
  const dataAtual = agoraISO();

  try {
    const result = await pool.query(
      `
      INSERT INTO cbo (codigo, descricao, ativo, criado_por, data_criacao)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING cd_cbo
      `,
      [codSan, descricao ? descricao.toUpperCase() : null, ativo ?? true, userId, dataAtual]
    );

    res.status(201).json({
      mensagem: 'CBO cadastrado com sucesso!',
      cd_cbo: result.rows[0].cd_cbo
    });
  } catch (err) {
    // Chave única do Postgres
    if (err.code === '23505') {
      return res.status(409).json({ erro: 'Já existe um CBO com esse código.' });
    }
    logger.error('Erro ao cadastrar CBO: ' + err.stack, 'cbo');
    res.status(500).json({ erro: 'Erro ao cadastrar CBO.' });
  }
});

// ---------- PUT /cbo/alterar/:id ----------
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  let { codigo, descricao, ativo } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = agoraISO();

  const campos = [];
  const valores = [];
  let i = 1;

  const add = (campo, valor) => {
    campos.push(`${campo} = $${i++}`);
    valores.push(valor);
  };

  if (codigo !== undefined) {
    const codSan = sanitizarCodigoCBO(codigo);
    if (!validarCodigoCBO(codSan)) {
      return res.status(400).json({ erro: 'O código CBO deve conter exatamente 6 dígitos numéricos.' });
    }
    add('codigo', codSan);
  }

  if (descricao !== undefined) add('descricao', descricao ? String(descricao).toUpperCase() : null);
  if (ativo !== undefined) add('ativo', !!ativo);

  add('alterado_por', userId);
  add('data_alteracao', dataAtual);

  if (campos.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo enviado para alteração.' });
  }

  const sql = `
    UPDATE cbo
       SET ${campos.join(', ')}
     WHERE cd_cbo = $${i}
     RETURNING *;
  `;
  valores.push(id);

  try {
    const r = await pool.query(sql, valores);
    if (r.rowCount === 0) {
      return res.status(404).json({ erro: 'CBO não encontrado.' });
    }
    res.status(200).json({ mensagem: 'CBO alterado com sucesso!', cbo: r.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ erro: 'Já existe um CBO com esse código.' });
    }
    logger.error('Erro ao alterar CBO: ' + err.stack, 'cbo');
    res.status(500).json({ erro: 'Erro ao alterar CBO.' });
  }
});

// ---------- GET /cbo/listar e /cbo/buscar (com paginação e filtros) ----------
router.get('/listar', tokenOpcional, listarCBO);
router.get('/buscar', tokenOpcional, listarCBO);

async function listarCBO(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true');
    filtros.push(`c.ativo = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    // Pesquisa por descricao (unaccent) e por codigo
    filtros.push(`(
      unaccent(c.descricao) ILIKE unaccent($${valores.length})
      OR c.codigo ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM cbo c ${where}`;
  const baseQuery = `
    SELECT
      c.cd_cbo,
      c.codigo,
      c.descricao,
      c.ativo,
      c.criado_por,
      c.data_criacao,
      c.alterado_por,
      c.data_alteracao
    FROM cbo c
    ${where}
    ORDER BY c.codigo
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json({ ...resultado, dados: resultado.dados });
  } catch (err) {
    logger.error('Erro ao listar CBO: ' + err.stack, 'cbo');
    res.status(500).json({ erro: 'Erro ao listar CBO.' });
  }
}

// ---------- GET /cbo/buscar/:id ----------
router.get('/buscar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  try {
    const r = await pool.query(`SELECT * FROM cbo WHERE cd_cbo = $1`, [id]);
    if (r.rowCount === 0) {
      return res.status(404).json({ erro: 'CBO não encontrado.' });
    }
    res.status(200).json(r.rows[0]);
  } catch (err) {
    logger.error('Erro ao buscar CBO: ' + err.stack, 'cbo');
    res.status(500).json({ erro: 'Erro ao buscar CBO.' });
  }
});

// ---------- Exportação CSV ----------
const exportCBO = createCsvExporter({
  filename: () => `cbo-${new Date().toISOString().slice(0,10)}.csv`,
  header: [
    'Código Interno','Código CBO','Descrição','Ativo',
    'Criado Por','Data Criação','Alterado Por','Data Alteração'
  ],
  baseQuery: `
    SELECT
      c.cd_cbo,
      c.codigo,
      c.descricao,
      c.ativo,
      COALESCE(u1.nome,'') AS criado_por,
      to_char(c.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.nome,'') AS alterado_por,
      to_char(c.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.cbo c
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = c.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = c.alterado_por
    {{WHERE}}
    ORDER BY c.codigo
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`c.ativo = $${i++}`);
      params.push(ativo === 'true');
    }
    if (q) {
      filters.push(`(
        unaccent(c.descricao) ILIKE unaccent($${i++})
        OR c.codigo ILIKE $${i}
      )`);
      params.push(`%${q}%`);
    }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    return { where, params };
  },
  rowMap: (r) => [
    r.cd_cbo,
    r.codigo || '',
    r.descricao || '',
    r.ativo ? 'Sim' : 'Não',
    r.criado_por,
    r.data_criacao || '',
    r.alterado_por,
    r.data_alteracao || '',
  ],
});

router.get('/exportar/csv', verificarToken, exportCBO);

module.exports = router;
