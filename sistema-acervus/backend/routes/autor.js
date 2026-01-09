const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');
 

router.get('/listar', tokenOpcional, listarAutores);
router.get('/buscar', tokenOpcional, listarAutores);

async function listarAutores(req, res) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { ativo, q } = req.query;

  const filtros = [];
  const valores = [];

  if (ativo !== undefined) {
    valores.push(ativo === 'true' ? 'A' : 'I');
    filtros.push(`sts_autor = $${valores.length}`);
  }

  if (q) {
    valores.push(`%${q}%`);
    filtros.push(`(
      unaccent(ds_autor) ILIKE unaccent($${valores.length})
      OR CAST(cd_autor AS TEXT) ILIKE $${valores.length}
    )`);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*) FROM public.ace_autor ${where}`;
  const baseQuery = `
    SELECT 
      cd_autor,
      ds_autor AS nome,
      sts_autor,
      dt_nascimento as data_nascimento,
      dt_falecimento as data_falecimento,
      observacao
    FROM public.ace_autor
    ${where}
    ORDER BY ds_autor
  `;

  try {
    const resultado = await paginarConsulta(
      pool,
      baseQuery,
      countQuery,
      valores,
      page,
      limit
    );

    // Converte status para boolean
    resultado.dados = resultado.dados.map(a => ({
      ...a,
      ativo: a.sts_autor === 'A'
    }));

    res.status(200).json(resultado);

  } catch (err) {
    logger.error('Erro ao listar Autores: ' + err.stack, 'Autor');
    res.status(500).json({ erro: 'Erro ao listar Autores.', motivo: err.message } );
  }
}


router.post('/cadastrar', verificarToken, async (req, res) => {
  const { nome, ativo = true, data_nascimento, data_falecimento, observacao } = req.body;

  if (!nome) {
    return res.status(400).json({ erro: 'O campo "nome" é obrigatório.' });
  }

  try {
    // Verifica duplicidade
    const verifica = await pool.query(
      `SELECT 1 FROM public.ace_autor 
       WHERE LOWER(ds_autor) = LOWER($1) LIMIT 1`,
      [nome.trim()]
    );

    if (verifica.rowCount > 0) {
      return res.status(409).json({ erro: 'Já existe um autor com esse nome.' });
    }

    const result = await pool.query(
      `
      INSERT INTO public.ace_autor
        (ds_autor, sts_autor, dt_nascimento, dt_falecimento, observacao)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING cd_autor
      `,
      [
        nome.trim(),
        ativo ? 'A' : 'I',
        data_nascimento || null,
        data_falecimento || null,
        observacao || null,
      ]
    );

    res.status(201).json({
      message: 'Autor cadastrado com sucesso!',
      cd_autor: result.rows[0].cd_autor,
    });

  } catch (err) {
    logger.error('Erro ao cadastrar Autor: ' + err.stack, 'Autor');
    res.status(500).json({ erro: 'Erro ao cadastrar Autor.' });
  }
});


router.put('/alterar/:cd_autor', verificarToken, async (req, res) => {
  const { cd_autor } = req.params;
  const { nome, ativo, data_nascimento, data_falecimento, observacao } = req.body;

  try {
    const atual = await pool.query(
      `SELECT ds_autor FROM public.ace_autor WHERE cd_autor = $1`,
      [cd_autor]
    );

    if (atual.rowCount === 0) {
      return res.status(404).json({ erro: 'Autor não encontrado.' });
    }

    if (nome && nome.trim().toLowerCase() !== atual.rows[0].ds_autor.toLowerCase()) {
      const dup = await pool.query(
        `SELECT 1 FROM public.ace_autor 
         WHERE LOWER(ds_autor) = LOWER($1) AND cd_autor <> $2`,
        [nome.trim(), cd_autor]
      );
      if (dup.rowCount > 0) {
        return res.status(409).json({ erro: 'Já existe um autor com esse nome.' });
      }
    }

    await pool.query(
      `
      UPDATE public.ace_autor
      SET ds_autor = COALESCE($1, ds_autor),
          sts_autor = COALESCE($2, sts_autor),
          dt_nascimento = $3,
          dt_falecimento = $4,
          observacao = $5
      WHERE cd_autor = $6
      `,
      [
        nome?.trim(),
        ativo !== undefined ? (ativo ? 'A' : 'I') : null,
        data_nascimento || null,
        data_falecimento || null,
        observacao || null,
        cd_autor,
      ]
    );

    res.status(200).json({ message: 'Autor atualizado com sucesso!' });

  } catch (err) {
    logger.error('Erro ao atualizar Autor: ' + err.stack, 'Autor');
    res.status(500).json({ erro: 'Erro ao atualizar Autor.' });
  }
});


const exportAutores = createCsvExporter({
  filename: () => `autores-${new Date().toISOString().slice(0,10)}.csv`,
  header: ['Código','Nome','Status','Nascimento','Falecimento','Observação'],
  baseQuery: `
    SELECT 
      cd_autor,
      ds_autor,
      sts_autor,
      to_char(dt_nascimento,'DD/MM/YYYY') AS data_nascimento,
      to_char(dt_falecimento,'DD/MM/YYYY') AS data_falecimento,
      observacao
    FROM public.ace_autor
    {{WHERE}}
    ORDER BY ds_autor
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [], params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`sts_autor = $${i++}`);
      params.push(ativo === 'true' ? 'A' : 'I');
    }

    if (q) {
      filters.push(`unaccent(ds_autor) ILIKE unaccent($${i++})`);
      params.push(`%${q}%`);
    }

    return {
      where: filters.length ? `WHERE ${filters.join(' AND ')}` : '',
      params
    };
  },
  rowMap: (r) => [
    r.cd_autor,
    r.ds_autor,
    r.sts_autor === 'A' ? 'Ativo' : 'Inativo',
    r.data_nascimento || '',
    r.data_falecimento || '',
    r.observacao || '',
  ],
});

router.get('/exportar/csv', verificarToken, exportAutores);
module.exports = router;