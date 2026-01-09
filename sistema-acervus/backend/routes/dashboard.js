const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken } = require('../auth');

// GET /dashboard/adm
router.get('/adm', verificarToken, async (req, res) => {
  try {
    const client = await pool.connect();

       // 🔹 1. Lê o parâmetro ?limit (padrão = 10)
    let limitParam = parseInt(req.query.limit);
    if (isNaN(limitParam)) limitParam = 10; // fallback
    if (limitParam < 0) limitParam = 0; // garante que não seja negativo

    const limitClause = limitParam > 0 ? `LIMIT ${limitParam}` : ''; // 0 = sem limite


    // Total de vagas
    const vagasResult = await client.query('SELECT COUNT(*) AS total FROM vaga');
    const totalVagas = parseInt(vagasResult.rows[0].total);

    // Total de contratos
    const contratosResult = await client.query('SELECT COUNT(*) AS total FROM contrato');
    const totalContratos = parseInt(contratosResult.rows[0].total);

    // Total de estudantes
    const estudantesResult = await client.query('SELECT COUNT(*) AS total FROM candidato where id_regime_contratacao = 2 ');
    const totalEstudantes = parseInt(estudantesResult.rows[0].total);

    // Total de aprendizes
    const aprendizesResult = await client.query('SELECT COUNT(*) AS total FROM candidato where id_regime_contratacao = 1');
    const totalAprendizes = parseInt(aprendizesResult.rows[0].total);

    // Total de empresas
    const empresasResult = await client.query('SELECT COUNT(*) AS total FROM empresa');
    const totalEmpresas = parseInt(empresasResult.rows[0].total);

    // Contratos com data_fim nos próximos 30 dias
    const contratosVencerResult = await client.query(`
    WITH data_finais AS (
  SELECT 
    COALESCE(cd_contrato_origem, cd_contrato) AS grupo_contrato,
    MAX(data_termino) AS data_fim
  FROM contrato
  WHERE data_termino IS NOT NULL
 
  GROUP BY COALESCE(cd_contrato_origem, cd_contrato)
)
SELECT
  ce.cd_contrato,
  df.data_fim,
  UPPER(e.razao_social) AS empresa,
  UPPER(c.nome_completo) AS estagiario
FROM contrato ce
JOIN data_finais df 
  ON df.grupo_contrato = COALESCE(ce.cd_contrato_origem, ce.cd_contrato)
JOIN empresa e 
  ON ce.cd_empresa = e.cd_empresa
JOIN candidato c 
  ON ce.cd_estudante = c.cd_candidato
WHERE ce.tipo_contrato = 2
  AND ce.status NOT IN ('D','C')
  AND (ce.aditivo IS NULL OR ce.aditivo <> 'true')
  AND df.data_fim IS NOT NULL
  AND (
       df.data_fim < CURRENT_DATE
       OR df.data_fim BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
      )
  AND EXTRACT(YEAR FROM df.data_fim) >= 2025
ORDER BY df.data_fim, empresa ASC

${limitClause}; -- 👈 aplica o limit conforme parâmetro

    `);
    //WHERE ce.data_termino BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'

    const contratosAVencer = contratosVencerResult.rows.map(row => ({
      cd_contrato: row.cd_contrato,
      empresa: row.empresa,
      estagiario: row.estagiario,
      vencimento: row.data_fim.toISOString().split('T')[0]
    }));

    client.release();

    return res.json({
      totalVagas,
      totalContratos,
      totalEstudantes,
      totalAprendizes,
      totalEmpresas,
      contratosAVencer
    });
  } catch (err) {
    console.error('Erro no dashboard:', err);
    return res.status(500).json({ erro: 'Erro ao buscar dados do dashboard' });
  }
});

router.get('/ie/:cd_instituicao', verificarToken, async (req, res) => {
  const { cd_instituicao } = req.params;

  // Query para vagas abertas
  const queryVagasAbertas = `
    SELECT COUNT(*) AS total
    FROM vaga v
    WHERE v.status = 'Aberta'
  `;

  // Query para estudantes da IE
  const queryEstudantesIE = `
    SELECT COUNT(*) AS total
    FROM candidato c
    WHERE c.cd_instituicao_ensino = $1
  `;

  try {
    const client = await pool.connect();

    // Executar as duas queries
    const [vagasAbertasResult, estudantesIEResult] = await Promise.all([
      client.query(queryVagasAbertas),              // não precisa de parâmetro
      client.query(queryEstudantesIE, [cd_instituicao]) // precisa do cd_instituicao
    ]);

    client.release();

    const totalVagasAbertas = parseInt(vagasAbertasResult.rows[0].total || '0', 10);
    const totalEstudantesIE = parseInt(estudantesIEResult.rows[0].total || '0', 10);

    return res.json({
      cd_instituicao,
      totalVagasAbertas,
      totalEstudantesIE
    });
  } catch (err) {
    console.error('Erro no dashboard/ie:', err);
    return res.status(500).json({ erro: 'Erro ao buscar dados (dashboard IE): ' + err.message });
  }
});


router.get('/empresa/:cd_empresa', verificarToken, async (req, res) => {
  const { cd_empresa } = req.params;

  // Ajuste os nomes das colunas/constrangimentos conforme seu schema real
  const qSupervisores = `
    SELECT COUNT(*) AS total
    FROM supervisor s
    WHERE s.cd_empresa = $1
      AND (s.ativo IS TRUE OR s.ativo IS NULL)
  `;

  // Contrato "ativo" = ainda não venceu (ou sem data fim)
  const qContratosAtivos = `
    SELECT COUNT(*) AS total
    FROM contrato c
    WHERE c.cd_empresa = $1
      AND (c.data_termino IS NULL OR c.data_termino >= CURRENT_DATE)
      AND (c.tipo_contrato IN (1,2)) -- 1=aprendiz, 2=estágio (ajuste se necessário)
      AND (c.aditivo IS NULL OR c.aditivo <> 'true')
  `;

  // Vaga "ativa" = status aberto/publicada e não expirada
  const qVagasAtivas = `
    SELECT COUNT(*) AS total
    FROM vaga v
    WHERE v.cd_empresa = $1
      AND (v.status ILIKE 'Aberta' OR v.status ILIKE 'Publicada')
 
  `;

  const qContratosVencer = `
    SELECT 
      c.data_termino AS data_fim,
      cand.nome_completo AS pessoa
    FROM contrato c
    INNER JOIN candidato cand ON cand.cd_candidato = c.cd_estudante
    WHERE c.cd_empresa = $1
      AND (c.tipo_contrato IN (1,2))
      AND (c.aditivo IS NULL OR c.aditivo <> 'true')
      AND c.data_termino IS NOT NULL
      -- se quiser "nos próximos 30 dias", descomente a linha abaixo
       AND c.data_termino BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
    ORDER BY c.data_termino ASC
    LIMIT 5
  `;

  try {
    const client = await pool.connect();

    const [
      supervisoresResult,
      contratosAtivosResult,
      vagasAtivasResult,
      contratosVencerResult
    ] = await Promise.all([
      client.query(qSupervisores, [cd_empresa]),
      client.query(qContratosAtivos, [cd_empresa]),
      client.query(qVagasAtivas, [cd_empresa]),
      client.query(qContratosVencer, [cd_empresa]),
    ]);

    client.release();

    const totalSupervisores    = parseInt(supervisoresResult.rows[0]?.total || '0', 10);
    const totalContratosAtivos = parseInt(contratosAtivosResult.rows[0]?.total || '0', 10);
    const totalVagasAtivas     = parseInt(vagasAtivasResult.rows[0]?.total || '0', 10);

    const contratosAVencer = contratosVencerResult.rows.map(r => ({
      pessoa: r.pessoa,
      vencimento: r.data_fim ? r.data_fim.toISOString().split('T')[0] : null
    }));

    return res.json({
      cd_empresa,
      totalSupervisores,
      totalContratosAtivos,
      totalVagasAtivas,
      contratosAVencer
    });
  } catch (err) {
    console.error('Erro no dashboard/empresa:', err);
    return res.status(500).json({ erro: 'Erro ao buscar dados do dashboard da empresa: ' + err.message });
  }
});


module.exports = router;
