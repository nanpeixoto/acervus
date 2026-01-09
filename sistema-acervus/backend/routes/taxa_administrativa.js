
// routes/taxaAdministrativa.js
const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken, tokenOpcional } = require('../auth');

/**
 * GET /taxa-administrativa?page=1&limit=10&search=BYD&tipo_taxa=estagio&competencia=09/2025
 * - search: nome da empresa (ILIKE)
 * - tipo_taxa: 'estagio' | 'aprendiz' | etc. (opcional)
 * - competencia: 'MM/YYYY' (obrigatório)
 */
router.get('/', /*verificarToken,*/ async (req, res) => {
  try {
    const page = 1;
    const limit = 10000;
    const offset = (page - 1) * limit;

    const { search, tipo_taxa, competencia, empresa } = req.query;
    //imprimir competencia
    console.log('Competencia recebida:', competencia);

    // valida competencia (MM/YYYY)
    //if (!competencia || !/^\d{2}\/\d{4}$/.test(competencia)) {
    //  return res.status(400).json({ error: "Parâmetro 'competencia' é obrigatório no formato MM/YYYY." });
    //}

    // converte competencia -> primeiro dia do mês
    // ex.: '09/2025' -> '2025-09-01'
    //const [mm, yyyy] = competencia.split('/');
    //const competenciaDate = `${yyyy}-${mm}-01`;

    const filtros = [];
    const valores = [];

    // competência é sempre obrigatória (match no mês)
    //valores.push(competenciaDate);
    //filtros.push(`cce.competencia = $${valores.length}`);

    //quando for estagio tipo_contrato = 2
    // quando for aprendiz tipo_contrato = 1
   /* if (tipo_taxa) {
     // valores.push(tipo_taxa);
      // quando for estagio tipo_contrato = 2
      // quando for aprendiz tipo_contrato = 1
      // tipo de taxa se vinher 'estagio' ou 2
      if (tipo_taxa === 'estagio' || tipo_taxa === '2') {    
        filtros.push(`cce.tipo_contrato = 2`);
      } else if (tipo_taxa === 'aprendiz' || tipo_taxa === '1') {
        filtros.push(`cce.tipo_contrato = 1`);
      } else {
        return res.status(400).json({ error: "Parâmetro 'tipo_taxa' inválido. Use 'estagio/2' ou 'aprendiz/1'." });
      }
    }*/
 


    if (search) {
      valores.push(`%${search.toUpperCase()}%`);
      filtros.push(`
        (
          unaccent(upper(emp.nome_fantasia)) ILIKE unaccent($${valores.length})
          OR unaccent(upper(emp.razao_social)) ILIKE unaccent($${valores.length})
        )
      `);
    }


     if (empresa ) {
      valores.push(`${empresa.toUpperCase()}`);
      filtros.push(`
        (
          emp.cd_empresa = $${valores.length}
        )
      `);
    }

    const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

    // COUNT para paginação
    const countQuery = `
      SELECT COUNT(*) AS total
      FROM public.cobranca_competencia_estagio cce
      inner join contrato c on c.cd_contrato = cce.cd_contrato
      JOIN public.empresa emp ON emp.cd_empresa = c.cd_empresa
      ${where};
    `;

    const { rows: countRows } = await pool.query(countQuery, valores);
    const totalItems = parseInt(countRows[0]?.total || '0', 10000);

    // Dados paginados
    const dataQuery = `
      SELECT
        cce.id            AS codigo_cobranca,
        c.cd_empresa,
        emp.nome_fantasia                      AS empresa,
        to_char(cce.competencia, 'MM/YYYY')    AS competencia,
         to_char(cce.criado_em , 'DD/MM/YYYY HH24:MI')    AS criado_emE,

        cce.tipo_contrato,
            cce.*
            , ca.cpf cpf_candidato
            , cp.nome as nm_plano_pagamento
            , concat(cp.nome ,' - R$ ',valor_base  )   plano_pagamento
            , valor_base
            , CASE c.status
              WHEN 'A' THEN 'ATIVO'
              WHEN 'C' THEN 'CANCELADO'
              WHEN 'D' THEN 'DESLIGADO'
              ELSE c.status
          END AS status_descricao , us.nome usuario_alteracao
      FROM public.cobranca_competencia_estagio cce
      left join contrato c on c.cd_contrato = cce.cd_contrato
        left  join candidato ca on c.cd_estudante = ca.cd_candidato
        left join plano_pagamento cp on cp.cd_plano_pagamento = cce.cd_plano_pagamento
      left join public.empresa emp ON emp.cd_empresa = c.cd_empresa
      left join public.USUARIOS us ON us.cd_usuario = cce.alterado_por
      ${where}
      ORDER BY   nome_candidato,  cce.id DESC
      LIMIT $${valores.length + 1} OFFSET $${valores.length + 2};
    `;
    //imprimir dataQuery
    console.log('Data Query gerada:', dataQuery);

    const { rows } = await pool.query(dataQuery, [...valores, limit, offset]);

    const totalPages = Math.ceil(totalItems / limit) || 1;

    return res.json({
      dados: rows,
      pagination: {
        currentPage: page,
        totalPages,
        totalItems,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1
      }
    });
  } catch (err) {
    console.error('[GET /taxa-administrativa] Erro:', err);
    return res.status(500).json({ error: 'Erro ao consultar taxa administrativa.' , details: err.message});
  }
});

// GET /taxa-administrativa/competencias?tipo_taxa=estagio&empresa_id=5
router.get('/competencias', async (req, res) => {
  try {
    // assumir estagio quando não informado
    const { tipo_taxa = 'estagio', empresa_id } = req.query;
    const valores = [];
    const filtrosEstagio = [];
    const filtrosAprendiz = [];


    

    // filtro por empresa (opcional)
    if (empresa_id) {
      valores.push(empresa_id);
      filtrosEstagio.push(`cce.cd_empresa = $${valores.length}`);
      filtrosAprendiz.push(`cca.cd_empresa = $${valores.length}`);
    }

    const whereEstagio = filtrosEstagio.length ? `WHERE ${filtrosEstagio.join(' AND ')}` : '';
    const whereAprendiz = filtrosAprendiz.length ? `WHERE ${filtrosAprendiz.join(' AND ')}` : '';

    const tipo = String(tipo_taxa).toLowerCase();
    if (!['estagio', '2', 'aprendiz', '1', 'ambos'].includes(tipo)) {
      return res.status(400).json({ error: "Parâmetro 'tipo_taxa' inválido. Use 'estagio/2', 'aprendiz/1' ou 'ambos'." });
    }

    let query = '';

    if (tipo === 'aprendiz' || tipo === '1') {
      query = `
        SELECT DISTINCT
          to_char(cca.competencia, 'MM/YYYY') AS competencia,
          DATE_TRUNC('month', cca.competencia) AS competencia_date,
          'aprendiz' AS tipo_taxa
        FROM public.cobranca_competencia_aprendiz cca
        ${whereAprendiz}
        ORDER BY competencia_date;
      `;
    } else if (tipo === 'ambos') {
      query = `
        SELECT *
        FROM (
          SELECT DISTINCT
            to_char(cce.competencia, 'MM/YYYY') AS competencia,
            DATE_TRUNC('month', cce.competencia) AS competencia_date,
            'estagio' AS tipo_taxa
          FROM public.cobranca_competencia_estagio cce
          ${whereEstagio}

          UNION

          SELECT DISTINCT
            to_char(cca.competencia, 'MM/YYYY') AS competencia,
            DATE_TRUNC('month', cca.competencia) AS competencia_date,
            'aprendiz' AS tipo_taxa
          FROM public.cobranca_competencia_aprendiz cca
          ${whereAprendiz}
        ) t
        ORDER BY competencia_date;
      `;
    } else {
      // estagio (padrão) ou '2'
      query = `
        SELECT DISTINCT
          to_char(cce.competencia, 'MM/YYYY') AS competencia,
          DATE_TRUNC('month', cce.competencia) AS competencia_date,
          'estagio' AS tipo_taxa
        FROM public.cobranca_competencia_estagio cce
        ${whereEstagio}
        ORDER BY competencia_date;
      `;
    }

    console.log('Query de competências gerada:', query, valores);

    const { rows } = await pool.query(query, valores);

    return res.json({
      competencias: rows.map(r => ({
        competencia: r.competencia,
        tipo_taxa: r.tipo_taxa
      })),
      total: rows.length
    });
  } catch (err) {
    console.error('[GET /taxa-administrativa/competencias] Erro:', err);
    return res.status(500).json({ error: 'Erro ao listar competências.', details: err.message });
  }
});



router.put('/:idCobranca/valor', verificarToken, async (req, res) => {
  const idCobranca = parseInt(req.params.idCobranca, 10);
  const { valor, motivo } = req.body;

 
  const cdUsuario = req.usuario.cd_usuario;
  if (!Number.isInteger(idCobranca) || idCobranca <= 0) {
    return res.status(400).json({ error: 'idCobranca inválido.' });
  }
  if (valor === undefined || valor === null || isNaN(Number(valor))) {
    return res.status(400).json({ error: 'Campo "valor" é obrigatório e deve ser numérico.' });
  }
  

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1) Busca o registro atual e bloqueia para atualização (evita race condition)
    const sel = await client.query(
      `
      SELECT id, valor_calculado
      FROM public.cobranca_competencia_estagio
      WHERE id = $1
      FOR UPDATE
      `,
      [idCobranca]
    );

    if (sel.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Cobrança não encontrada.' });
    }

    const atual = sel.rows[0];
    const valorAnterior = atual.valor_calculado;
    const valorNovo = Number(valor);

    // 2) Atualiza a cobrança
    const upd = await client.query(
      `
      UPDATE public.cobranca_competencia_estagio
         SET valor_calculado = $2,
             alterado_por = $3,
             data_alteracao = NOW(), motivo = $4
       WHERE id = $1
       RETURNING id, valor_calculado, alterado_por, data_alteracao
      `,
      [idCobranca, valorNovo, cdUsuario, motivo || "Ajuste Manual"]
    );

    // 3) Insere auditoria
    await client.query(
      `
      INSERT INTO public.cobranca_competencia_estagio_auditoria
        (cd_cobranca, campo, valor_anterior, valor_novo, alterado_por, data_alteracao, motivo)
      VALUES
        ($1, 'valor_calculado', $2, $3, $4, NOW(), $5)
      `,
      [idCobranca, valorAnterior, valorNovo, cdUsuario, motivo || "Ajuste Manual"]
    );

    await client.query('COMMIT');

    const row = upd.rows[0];
    return res.json({
      message: 'Valor atualizado com sucesso.',
      cobranca: {
        cd_cobranca: row.id,
        valor_anterior: Number(valorAnterior),
        valor_novo: Number(row.valor_calculado),
        alterado_por: row.alterado_por,
        data_alteracao: row.data_alteracao
      }
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[PUT /taxa-administrativa/:idCobranca/valor] Erro:', err);
    return res.status(500).json({ error: 'Erro ao atualizar valor da cobrança.' , details: err.message});
  } finally {
    client.release();
  }
});

// Normaliza "09/2023" | "2023-09" | "2023-09-15" -> "2023-09-01"
function normalizarCompetencia(raw) {
  if (!raw) return null;
  const v = String(raw).trim();

  // MM/YYYY
  const mmYYYY = /^(\d{2})\/(\d{4})$/;
  // YYYY-MM
  const yyyyMM = /^(\d{4})-(\d{2})$/;
  // YYYY-MM-DD
  const yyyyMMDD = /^(\d{4})-(\d{2})-(\d{2})$/;

  if (mmYYYY.test(v)) {
    const [, mm, yyyy] = v.match(mmYYYY);
    return `${yyyy}-${mm}-01`;
  }
  if (yyyyMM.test(v)) {
    const [, yyyy, mm] = v.match(yyyyMM);
    return `${yyyy}-${mm}-01`;
  }
  if (yyyyMMDD.test(v)) {
    const [, yyyy, mm] = v.match(yyyyMMDD);
    return `${yyyy}-${mm}-01`;
  }
  return null;
}

/**
 * POST /taxa-administrativa/gerar-consolidados?competencia=09/2023[&tipo=ambos|aprendiz|estagio]
 * - competencia: obrigatório, na query (MM/YYYY recomendado)
 * - tipo: opcional (default: ambos)
 */
router.post('/gerar-consolidadas', verificarToken, async (req, res) => {
  try {
    const { competencia: competenciaRaw, tipo = 'ambos' } = req.query;
    const competencia = normalizarCompetencia(competenciaRaw);

    if (!competencia) {
      return res.status(400).json({
        erro: "Parâmetro 'competencia' inválido. Use 'MM/YYYY', 'YYYY-MM' ou 'YYYY-MM-DD'.",
      });
    }

    const tipoNorm = String(tipo).toLowerCase();
    if (!['ambos', 'aprendiz', 'estagio'].includes(tipoNorm)) {
      return res.status(400).json({
        erro: "Parâmetro 'tipo' inválido. Use 'ambos', 'aprendiz' ou 'estagio'.",
      });
    }

    const client = await pool.connect();
    const executados = [];
    const t0 = Date.now();

    try {
      await client.query('BEGIN');

      if (tipoNorm === 'ambos' || tipoNorm === 'aprendiz') {
        await client.query(
          'SELECT public.fn_calcular_cobranca_aprendiz($1::date);',
          [competencia]
        );
        executados.push('aprendiz');
      }

      if (tipoNorm === 'ambos' || tipoNorm === 'estagio') {
        await client.query(
          'SELECT public.fn_calcular_cobranca_estagio($1::date);',
          [competencia]
        );
        executados.push('estagio');
      }

      await client.query('COMMIT');

      return res.json({
        ok: true,
        competencia_normalizada: competencia, // YYYY-MM-01
        tipo_executado: executados,
        duracao_ms: Date.now() - t0,
        mensagem: 'Cobranças geradas com sucesso.',
      });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Erro ao gerar cobranças:', err);
      return res.status(500).json({ erro: 'Falha ao gerar cobranças.', detalhe: String(err.message || err) });
    } finally {
      client.release();
    }
  } catch (err) {
    console.error(err);
    return res.status(500).json({ erro: 'Erro inesperado.', detalhe: String(err.message || err) });
  }
});


// POST /gerar-consolidadas/:cd_empresa
router.post('/gerar-consolidadas/:cd_empresa', verificarToken, async (req, res) => {
  const client = await pool.connect();
  const t0 = Date.now();

  try {
    const { competencia: competenciaRaw, tipo_contrato } = req.body; // ← body, não query
    const { cd_empresa } = req.params;
    const competencia = normalizarCompetencia(competenciaRaw);

    if (!competencia) {
      return res.status(400).json({
        erro: "Parâmetro 'competencia' inválido. Use 'MM/YYYY', 'YYYY-MM' ou 'YYYY-MM-DD'.",
      });
    }

    if (!cd_empresa || isNaN(cd_empresa)) {
      return res.status(400).json({
        erro: "Parâmetro de rota 'cd_empresa' é obrigatório e deve ser numérico.",
      });
    }

    if (!tipo_contrato) {
      return res.status(400).json({
        erro: "Parâmetro 'tipo_contrato' é obrigatório.",
      });
    }

    const tipoNorm = String(tipo_contrato).toLowerCase().trim();
    if (!['ambos', 'aprendiz', 'estagio', '1', '2'].includes(tipoNorm)) {
      return res.status(400).json({
        erro: "Parâmetro 'tipo_contrato' inválido. Use 'ambos', 'aprendiz', 'estagio', '1' ou '2'.",
      });
    }

    await client.query('BEGIN');
    const executados = [];

    // 🔸 executa conforme tipo
    if (tipoNorm === 'ambos' || tipoNorm === 'aprendiz' || tipoNorm === '1') {
      await client.query('SELECT public.fn_calcular_cobranca_aprendiz($1::date, $2::integer);',
        [competencia, cd_empresa]);
      executados.push('aprendiz');
    }

    if (tipoNorm === 'ambos' || tipoNorm === 'estagio' || tipoNorm === '2') {
      await client.query('SELECT public.fn_calcular_cobranca_estagio($1::date, $2::integer);',
        [competencia, cd_empresa]);
      executados.push('estagio');
    }

    await client.query('COMMIT');

    return res.json({
      ok: true,
      competencia_normalizada: competencia,
      tipo_executado: executados,
      cd_empresa: Number(cd_empresa),
      duracao_ms: Date.now() - t0,
      mensagem: 'Cobranças geradas com sucesso.',
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    return res.status(500).json({ erro: 'Erro ao gerar cobranças.', detalhe: String(err.message || err) });
  } finally {
    client.release();
  }
});


module.exports = router;
