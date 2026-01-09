const express = require('express');
const router = express.Router();
const app = express();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');

/** Cadastrar */
router.post('/cadastrar', verificarToken, async (req, res) => {
  const { nome, descricao, valor, ativo, isMatricula } = req.body;

  if (!valor) {
    return res.status(400).json({ erro: 'Campos obrigatórios: valor.' });
  }
  if (!nome) {
    return res.status(400).json({ erro: 'Campos obrigatórios: nome.' });
  }

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  try {
    const result = await pool.query(
      `
        INSERT INTO plano_pagamento
          (nome, descricao, valor, ativo, isMatricula, criado_por, data_criacao)
        VALUES
          ($1,   $2,       $3,    $4,    $5,           $6,        $7)
        RETURNING cd_plano_pagamento
      `,
      [
        nome.toUpperCase(),
        descricao ? descricao.toUpperCase() : null,
        valor,
        ativo ?? true,
        isMatricula ?? false,
        userId,
        dataAtual
      ]
    );

    res.status(201).json({
      mensagem: 'Plano de pagamento cadastrado com sucesso!',
      cd_plano_pagamento: result.rows[0].cd_plano_pagamento
    });
  } catch (err) {
    logger.error('Erro ao cadastrar plano: ' + err.stack, 'plano_pagamento');
    res.status(500).json({ erro: 'Erro ao cadastrar plano de pagamento.' });
  }
});

/** Alterar */
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  let { nome, descricao, valor, ativo, isMatricula } = req.body;
  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  const campos = [];
  const valores = [];
  let idx = 1;

  const adicionar = (campo, valor) => {
    campos.push(`${campo} = $${idx++}`); // aqui respeitamos camelCase do banco
    valores.push(valor);
  };

  if (nome) adicionar('nome', nome.toUpperCase());
  if (descricao !== undefined) adicionar('descricao', descricao ? descricao.toUpperCase() : null);
  if (valor !== undefined) adicionar('valor', valor);
  if (ativo !== undefined) adicionar('ativo', ativo);
  if (isMatricula !== undefined) adicionar('isMatricula', !!isMatricula);

  adicionar('alterado_por', userId);
  adicionar('data_alteracao', dataAtual);

  if (campos.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo enviado para alteração.' });
  }

  const query = `
    UPDATE plano_pagamento
       SET ${campos.join(', ')}
     WHERE cd_plano_pagamento = $${idx}
     RETURNING *;
  `;
  valores.push(id);

  try {
    const result = await pool.query(query, valores);
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Plano de pagamento não encontrado.' });
    }

    res.status(200).json({ mensagem: 'Plano alterado com sucesso!', plano: result.rows[0] });
  } catch (err) {
    logger.error('Erro ao alterar plano: ' + err.stack, 'plano_pagamento');
    res.status(500).json({ erro: 'Erro ao alterar plano de pagamento.' });
  }
});

/** Listar / Buscar paginado */
router.get('/listar', tokenOpcional, listarPlanosPagamento);
router.get('/buscar', tokenOpcional, listarPlanosPagamento);

async function listarPlanosPagamento(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q, matricula } = req.query; // <-- novo filtro

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true');
    filtros.push(`p.ativo = $${valores.length}`);
  }

  if (matricula !== undefined) {
    const boolVal =
      matricula === 'true' || matricula === '1'
        ? true
        : matricula === 'false' || matricula === '0'
        ? false
        : null;
    if (boolVal !== null) {
      valores.push(boolVal);
      filtros.push(`p.isMatricula = $${valores.length}`);
    }
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`(
      unaccent(p.nome) ILIKE unaccent($${valores.length}) OR
      unaccent(p.descricao) ILIKE unaccent($${valores.length})
    )`);
  }

  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM plano_pagamento p ${where}`;

  const baseQuery = `
    SELECT
      p.cd_plano_pagamento,
      p.nome,
      p.descricao,
      p.valor,
      p.ativo,
      p.isMatricula,
      p.criado_por,
      p.data_criacao,
      p.alterado_por,
      p.data_alteracao
    FROM plano_pagamento p
    ${where}
    ORDER BY p.nome
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json({ ...resultado, dados: resultado.dados });
  } catch (err) {
    logger.error('Erro ao listar planos: ' + err.stack, 'plano_pagamento');
    res.status(500).json({ erro: 'Erro ao listar planos de pagamento.' });
  }
}

/** Buscar por ID */
router.get('/buscar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `SELECT * FROM plano_pagamento WHERE cd_plano_pagamento = $1`,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Plano de pagamento não encontrado.' });
    }

    res.status(200).json(result.rows[0]);
  } catch (err) {
    logger.error('Erro ao buscar plano: ' + err.stack, 'plano_pagamento');
    res.status(500).json({ erro: 'Erro ao buscar plano de pagamento.' });
  }
});

/** Exportar CSV */
const exportPlanosPagamento = createCsvExporter({
  filename: () => `planos-pagamento-${new Date().toISOString().slice(0,10)}.csv`,
  header: [
    'Código','Nome','Descrição','Valor','Ativo','É Matrícula',
    'Criado Por','Data Criação','Alterado Por','Data Alteração'
  ],
  baseQuery: `
    SELECT
      pp.cd_plano_pagamento,
      pp.nome,
      pp.descricao,
      pp.valor,
      pp.ativo,
      pp.isMatricula,
      COALESCE(u1.nome,'') AS criado_por,
      to_char(pp.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.nome,'') AS alterado_por,
      to_char(pp.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.plano_pagamento pp
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = pp.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = pp.alterado_por
    {{WHERE}}
    ORDER BY pp.cd_plano_pagamento
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q, matricula } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`pp.ativo = $${i++}`);
      params.push(ativo === 'true');
    }
    if (matricula !== undefined) {
      const boolVal =
        matricula === 'true' || matricula === '1'
          ? true
          : matricula === 'false' || matricula === '0'
          ? false
          : null;
      if (boolVal !== null) {
        filters.push(`pp.isMatricula = $${i++}`);
        params.push(boolVal);
      }
    }
    if (q) {
      filters.push(`(
        unaccent(pp.nome) ILIKE unaccent($${i++})
        OR unaccent(pp.descricao) ILIKE unaccent($${i})
        OR CAST(pp.cd_plano_pagamento AS TEXT) ILIKE $${i}
      )`);
      params.push(`%${q}%`);
    }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    return { where, params };
  },
  rowMap: (r) => [
    r.cd_plano_pagamento,
    r.nome || '',
    r.descricao || '',
    r.valor ?? '',
    r.ativo ? 'Sim' : 'Não',
    r.isMatricula ? 'Sim' : 'Não',
    r.criado_por,
    r.data_criacao || '',
    r.alterado_por,
    r.data_alteracao || '',
  ],
});

router.get('/exportar/csv', verificarToken, exportPlanosPagamento);

module.exports = router;
