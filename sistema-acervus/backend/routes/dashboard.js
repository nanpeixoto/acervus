const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken } = require('../auth');


router.get('/grafico/obras-por-tipo', verificarToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        t.descricao  AS tipo,
        COUNT(o.cd_obra) AS total
      FROM public.ace_subtipo_peca t
      LEFT JOIN ace_obra o
        ON o.cd_subtipo_peca  = t.cd_subtipo_peca
      GROUP BY t.descricao
      ORDER BY total DESC
    `);

    return res.json(result.rows);
  } catch (err) {
    console.error('Erro gráfico obras por tipo:', err);
    return res.status(500).json({
      erro: 'Erro ao carregar gráfico de obras por tipo', motivo  : err.message
    });
  }
});


router.get('/grafico/obras-por-assunto', verificarToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        a.ds_assunto AS assunto,
        COUNT(o.cd_obra) AS total
      FROM ace_assunto a
      LEFT JOIN ace_obra o
        ON o.cd_assunto = a.cd_assunto
      WHERE a.sts_assunto = 'A'
      GROUP BY a.ds_assunto
      ORDER BY total DESC
      LIMIT 10
    `);

    return res.json(result.rows);
  } catch (err) {
    console.error('Erro gráfico obras por assunto:', err);
    return res.status(500).json({
      erro: 'Erro ao carregar gráfico de obras por assunto'
    });
  }
});

 // GET /dashboard/adm
router.get('/adm', verificarToken, async (req, res) => {
  const client = await pool.connect();

  try {
    const [
      obras,
      assuntos,
      autores,
      salas,
      estantes,
      tipos,
      subtipos,
      obrasPorAssuntoResult
    ] = await Promise.all([
      client.query('SELECT COUNT(*) FROM ace_obra'),
      client.query("SELECT COUNT(*) FROM ace_assunto WHERE sts_assunto = 'A'"),
      client.query("SELECT COUNT(*) FROM ace_autor WHERE sts_autor = 'A'"),
      client.query('SELECT COUNT(*) FROM ace_sala'),
      client.query('SELECT COUNT(*) FROM ace_estante'),
      client.query('SELECT COUNT(*) FROM ace_tipo_peca'),
      client.query('SELECT COUNT(*) FROM ace_subtipo_peca'),

      // 🎬 Carrossel Netflix-style por Assunto
      client.query(`
        SELECT *
        FROM (
          SELECT
            a.ds_assunto AS assunto,
            o.cd_obra,
            o.titulo,
            NULL AS capa_url,
            ROW_NUMBER() OVER (
              PARTITION BY a.cd_assunto
              ORDER BY o.cd_obra DESC
            ) AS rn
          FROM ace_obra o
          JOIN ace_assunto a
            ON a.cd_assunto = o.cd_assunto
          WHERE a.sts_assunto = 'A'
        ) t
        WHERE t.rn <= 10
        ORDER BY assunto, rn
      `),
    ]);

    // 🔁 Agrupar por assunto
    const carrosselPorAssunto = {};

    for (const row of obrasPorAssuntoResult.rows) {
      if (!carrosselPorAssunto[row.assunto]) {
        carrosselPorAssunto[row.assunto] = [];
      }

      carrosselPorAssunto[row.assunto].push({
        cd_obra: row.cd_obra,
        titulo: row.titulo,
        capa_url: row.capa_url,
      });
    }

    return res.json({
      totais: {
        obras: Number(obras.rows[0].count),
        assuntos: Number(assuntos.rows[0].count),
        autores: Number(autores.rows[0].count),
        salas: Number(salas.rows[0].count),
        estantes: Number(estantes.rows[0].count),
        tipos: Number(tipos.rows[0].count),
        subtipos: Number(subtipos.rows[0].count),
      },

      // 🎬 Netflix real
      obrasPorAssuntoCarousel: Object.entries(carrosselPorAssunto).map(
        ([assunto, obras]) => ({
          assunto,
          obras,
        })
      ),
    });

  } catch (err) {
    console.error('Erro dashboard acervo:', err);
    return res.status(500).json({
      erro: 'Erro ao carregar dashboard',
      motivo: err.message,
    });
  } finally {
    client.release();
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
