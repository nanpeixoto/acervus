const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta } = require('../helpers/paginador');
const { createCsvExporter } = require('../factories/exportCsvFactory');

// ----------------- helpers -----------------
function agoraISO() {
  return new Date().toISOString().split('T').join(' ').split('.')[0];
}
function parseDateBRtoISO(d) {
  if (!d) return null;
  if (/^\d{2}\/\d{2}\/\d{4}$/.test(d)) {
    const [dd, mm, yyyy] = d.split('/');
    return `${yyyy}-${mm}-${dd}`;
  }
  return d;
}

// ===================================================================
// POST /cursoAprendizagem/cadastrar
// ===================================================================
router.post('/cadastrar', verificarToken, async (req, res) => {
  const client = await pool.connect();
  try {
    const userId = req.usuario.cd_usuario;
    const {
      nome,
      cd_cbo,
      validade,
      ativo = true,
      modulos = []
    } = req.body;

    if (!nome || !nome.trim()) {
      return res.status(400).json({ erro: 'Campo obrigatório: nome.' });
    }
  

    const validadeISO = parseDateBRtoISO(validade);
    const dataAtual = agoraISO();

    await client.query('BEGIN');

    if (cd_cbo) {
      const chk = await client.query('SELECT 1 FROM cbo WHERE cd_cbo = $1 AND ativo = TRUE', [cd_cbo]);
      if (chk.rowCount === 0) {
        await client.query('ROLLBACK');
        return res.status(422).json({ erro: 'CBO informado não existe ou está inativo no domínio.' });
      }
    }

    const dup = await client.query(
      `SELECT 1 FROM curso_aprendizagem 
        WHERE unaccent(lower(nome)) = unaccent(lower($1)) LIMIT 1`,
      [nome.trim()]
    );
    if (dup.rowCount > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ erro: 'Já existe um curso com esse nome.' });
    }

    const ins = await client.query(
      `INSERT INTO curso_aprendizagem
         (nome, cd_cbo, validade, ativo, criado_por, data_criacao)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING cd_curso`,
      [nome.trim(), cd_cbo || null, validadeISO, !!ativo, userId, dataAtual]
    );
    const cd_curso = ins.rows[0].cd_curso;

    if (Array.isArray(modulos) && modulos.length > 0) {
      const params = [];
      const values = [];
      let i = 1;
      for (const m of modulos) {
        const nome_disciplina = (m?.nome_disciplina || '').trim();
        if (!nome_disciplina) continue;
        params.push(cd_curso, nome_disciplina, m?.ativo === false ? false : true, userId, dataAtual);
        values.push(`($${i++},$${i++},$${i++},$${i++},$${i++})`);
      }
      if (values.length) {
        await client.query(
          `INSERT INTO curso_modulo (cd_curso, nome_disciplina, ativo, criado_por, data_criacao)
           VALUES ${values.join(',')}`,
          params
        );
      }
    }

    await client.query('COMMIT');
    return res.status(201).json({ mensagem: 'Curso cadastrado com sucesso!', cd_curso });
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao cadastrar curso: ' + err.stack, 'cursoAprendizagem');
    //add o motivo do erro
    return res.status(500).json({ erro: 'Erro ao cadastrar curso: ' + err.message });
  } finally {
    client.release();
  }
});

// ===================================================================
// GET /cursoAprendizagem/listar  (pagina, limite, q, ativo, cd_cbo)
// ===================================================================
router.get('/listar', tokenOpcional, listarCursos);
router.get('/buscar', tokenOpcional, listarCursos);

async function listarCursos(req, res) {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const { q, ativo, cd_cbo } = req.query;

    const filtros = [];
    const valores = [];

    if (q) {
      valores.push(`%${q}%`);
      filtros.push(`unaccent(lower(c.nome)) ILIKE unaccent(lower($${valores.length}))`);
    }
    if (ativo !== undefined) {
      valores.push(ativo === 'true');
      filtros.push(`c.ativo = $${valores.length}`);
    }
    if (cd_cbo) {
      valores.push(cd_cbo);
      filtros.push(`c.cd_cbo = $${valores.length}`);
    }
    const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

    const countQuery = `SELECT COUNT(*) FROM curso_aprendizagem c ${where}`;
    const baseQuery = `
      SELECT
        c.cd_curso, c.nome, c.cd_cbo, b.codigo as cbo_codigo, b.descricao as cbo_descricao,
        c.validade, c.ativo,
        to_char(c.data_criacao,'DD/MM/YYYY HH24:MI') as data_criacao,
        to_char(c.data_alteracao,'DD/MM/YYYY HH24:MI') as data_alteracao
      FROM curso_aprendizagem c
      LEFT JOIN cbo b ON b.cd_cbo = c.cd_cbo
      ${where}
      ORDER BY c.data_criacao DESC, c.cd_curso DESC
    `;

    //imprimir query
    console.log('Count Query:', countQuery);
    console.log('Base Query:', baseQuery);
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    return res.status(200).json(resultado);
  } catch (err) {
    logger.error('Erro ao listar cursos: ' + err.stack, 'cursoAprendizagem');
    //informar o motivo do erro
    return res.status(500).json({ erro: 'Erro ao listar cursos: ' + err.message });
  }
}

// ===================================================================
// GET /cursoAprendizagem/buscar/:id  (curso + módulos)
// ===================================================================
router.get('/buscar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  try {
    const cab = await pool.query(
      `SELECT c.cd_curso, c.nome, c.cd_cbo, b.codigo as cbo_codigo, b.descricao as cbo_descricao,
              c.validade, c.ativo,
              c.criado_por, c.data_criacao, c.alterado_por, c.data_alteracao
         FROM curso_aprendizagem c
         LEFT JOIN cbo b ON b.cd_cbo = c.cd_cbo
        WHERE c.cd_curso = $1`,
      [id]
    );
    if (cab.rowCount === 0) return res.status(404).json({ erro: 'Curso não encontrado.' });

    const mods = await pool.query(
      `SELECT cd_modulo, nome_disciplina, ativo,
              criado_por, data_criacao, alterado_por, data_alteracao
         FROM curso_modulo
        WHERE cd_curso = $1
        ORDER BY cd_modulo`,
      [id]
    );

    return res.status(200).json({ ...cab.rows[0], modulos: mods.rows });
  } catch (err) {
    logger.error('Erro ao buscar curso: ' + err.stack, 'cursoAprendizagem');
    return res.status(500).json({ erro: 'Erro ao buscar curso.' });
  }
});

// ===================================================================
// PUT /cursoAprendizagem/alterar/:id
// ===================================================================
router.put('/alterar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { nome, cd_cbo, validade,ativo, modulos = [] } = req.body;

  const client = await pool.connect();
  try {
    const userId = req.usuario.cd_usuario;
    const dataAtual = agoraISO();
    const validadeISO = validade !== undefined ? parseDateBRtoISO(validade) : undefined;

    await client.query('BEGIN');

    if (cd_cbo) {
      const chk = await client.query('SELECT 1 FROM cbo WHERE cd_cbo = $1 AND ativo = TRUE', [cd_cbo]);
      if (chk.rowCount === 0) {
        await client.query('ROLLBACK');
        return res.status(422).json({ erro: 'CBO informado não existe ou está inativo no domínio.' });
      }
    }

    const sets = [];
    const vals = [];
    let i = 1;
    const add = (campo, valor) => { sets.push(`${campo} = $${i++}`); vals.push(valor); };

    if (nome !== undefined) add('nome', nome?.trim() || null);
    if (cd_cbo !== undefined) add('cd_cbo', cd_cbo || null);
    if (validade !== undefined) add('validade', validadeISO || null);

    if (ativo !== undefined) add('ativo', !!ativo);
    add('alterado_por', userId);
    add('data_alteracao', dataAtual);

    if (sets.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ erro: 'Nenhum campo enviado para alteração.' });
    }

    const upd = await client.query(
      `UPDATE curso_aprendizagem SET ${sets.join(', ')} WHERE cd_curso = $${i} RETURNING cd_curso`,
      [...vals, id]
    );
    if (upd.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Curso não encontrado.' });
    }

    await client.query('DELETE FROM curso_modulo WHERE cd_curso = $1', [id]);

    if (Array.isArray(modulos) && modulos.length > 0) {
      const params = [];
      const values = [];
      let k = 1;
      for (const m of modulos) {
        const nome_disciplina = (m?.nome_disciplina || '').trim();
        if (!nome_disciplina) continue;
        params.push(id, nome_disciplina, m?.ativo === false ? false : true, userId, dataAtual);
        values.push(`($${k++},$${k++},$${k++},$${k++},$${k++})`);
      }
      if (values.length) {
        await client.query(
          `INSERT INTO curso_modulo (cd_curso, nome_disciplina, ativo, criado_por, data_criacao)
           VALUES ${values.join(',')}`,
          params
        );
      }
    }

    await client.query('COMMIT');
    return res.status(200).json({ mensagem: 'Curso alterado com sucesso.' });
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao alterar curso: ' + err.stack, 'cursoAprendizagem');
    return res.status(500).json({ erro: 'Erro ao alterar curso.' });
  } finally {
    client.release();
  }
});

// ===================================================================
// PATCH /cursoAprendizagem/:id/status
// ===================================================================
router.patch('/:id/status', verificarToken, async (req, res) => {
  const { id } = req.params;
  const { ativo } = req.body;
  try {
    const r = await pool.query(
      `UPDATE curso_aprendizagem
          SET ativo = $1, alterado_por = $2, data_alteracao = $3
        WHERE cd_curso = $4`,
      [!!ativo, req.usuario.cd_usuario, agoraISO(), id]
    );
    if (r.rowCount === 0) return res.status(404).json({ erro: 'Curso não encontrado.' });
    return res.status(200).json({ mensagem: 'Status atualizado.' });
  } catch (err) {
    logger.error('Erro ao atualizar status do curso: ' + err.stack, 'cursoAprendizagem');
    return res.status(500).json({ erro: 'Erro ao atualizar status do curso.' });
  }
});


// exportador: curso_aprendizagem
const exportCursosAprendizagem = createCsvExporter({
  filename: () => `cursos-aprendizagem-${new Date().toISOString().slice(0,10)}.csv`,
  header: [
    'Código','Nome','Nome (Aprendizagem)','Validade','Ativo',
    'CBO Código','CBO Nome',
    'Criado Por','Data Criação','Alterado Por','Data Alteração'
  ],
  //convetrer validade

  baseQuery: `
    SELECT
      ca.cd_curso,
      ca.nome,
       to_char(ca.validade,'DD/MM/YYYY') AS validade,
      ca.ativo,
      COALESCE(c.codigo::text,'')   AS cbo_codigo,   -- ajuste se o campo for diferente
      COALESCE(c.descricao,'')           AS cbo_nome,     -- ajuste se for 'descricao'
      COALESCE(u1.nome,'')          AS criado_por,
      to_char(ca.data_criacao,'DD/MM/YYYY HH24:MI')   AS data_criacao,
      COALESCE(u2.nome,'')          AS alterado_por,
      to_char(ca.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.curso_aprendizagem ca
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = ca.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = ca.alterado_por
    LEFT JOIN public.cbo c        ON c.cd_cbo      = ca.cd_cbo
    {{WHERE}}
    ORDER BY ca.cd_curso
  `,
  buildWhereAndParams: (req) => {
    const { ativo, q } = req.query;
    const filters = [];
    const params = [];
    let i = 1;

    if (ativo !== undefined) {
      filters.push(`ca.ativo = $${i++}`);
      params.push(ativo === 'true');
    }

    if (q) {
      filters.push(`(
        unaccent(ca.nome) ILIKE unaccent($${i})
        OR unaccent(COALESCE(c.nome,'')) ILIKE unaccent($${i})
        OR COALESCE(c.codigo::text,'') ILIKE $${i}
        OR CAST(ca.cd_curso AS TEXT) ILIKE $${i}
      )`);
      params.push(`%${q}%`);
    }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    return { where, params };
  },
  rowMap: (r) => [
    r.cd_curso,
    r.nome || '',
    r.validade ?? '',
    r.ativo ? 'Sim' : 'Não',
    r.cbo_codigo || '',
    r.cbo_nome || '',
    r.criado_por,
    r.data_criacao || '',
    r.alterado_por,
    r.data_alteracao || '',
  ],
});

// rota (ex.: /curso-aprendizagem/exportar/csv)
router.get('/exportar/csv', verificarToken, exportCursosAprendizagem);

module.exports = router;
