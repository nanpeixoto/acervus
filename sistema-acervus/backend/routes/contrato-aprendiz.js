// contratoEstagioRouter.js
const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verificarToken } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
const e = require('express');
const { createCsvExporter } = require('../factories/exportCsvFactory');

// POST /contrato-estagio/cadastrar
router.post('/cadastrar', verificarToken, async (req, res) => {
  const {
    cd_empresa,
    cd_estudante,
    cd_instituicao_ensino,
    bolsa,
    cd_supervisor,
    cd_plano_pagamento,
    cd_template_modelo,
    data_inicio,
    data_termino,
    conteudo_html,

    // ✅ novos campos
    data_inicio_basico,
    data_fim_basico,
    cd_curso,
    cd_turma,
    numero_carteira_trabalho,
    serie
  } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  // ⚠️ obrigatórios
  if (!cd_empresa || !cd_estudante  || !cd_template_modelo || !cd_plano_pagamento || !cd_curso || !cd_turma) {
    return res.status(400).json({ erro: 'Campos obrigatórios ausentes.' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // validações base já existentes
    const emp = await client.query(`SELECT 1 FROM empresa WHERE cd_empresa = $1`, [cd_empresa]);
    if (emp.rowCount === 0) throw new Error('Empresa não encontrada.');

    const est = await client.query(`SELECT 1 FROM candidato WHERE cd_candidato = $1`, [cd_estudante]);
    if (est.rowCount === 0) throw new Error('Estudante (candidato) não encontrado.');

  
    if (cd_supervisor) {
      const sup = await client.query(`SELECT 1 FROM supervisor WHERE cd_supervisor = $1`, [cd_supervisor]);
      if (sup.rowCount === 0) throw new Error('Supervisor não encontrado.');
    }

    const plano = await client.query(`SELECT 1 FROM plano_pagamento WHERE cd_plano_pagamento = $1`, [cd_plano_pagamento]);
    if (plano.rowCount === 0) throw new Error('Plano de pagamento não encontrado.');

    const modelo = await client.query(`SELECT 1 FROM template_modelo WHERE id_modelo = $1`, [cd_template_modelo]);
    if (modelo.rowCount === 0) throw new Error('Modelo de contrato não encontrado.');

    // ✅ validações curso/turma
    const curso = await client.query(`SELECT 1 FROM curso_aprendizagem WHERE cd_curso = $1`, [cd_curso]);
    if (curso.rowCount === 0) throw new Error('Curso não encontrado.');

    const turma = await client.query(
      `SELECT 1 FROM turma WHERE cd_turma = $1 AND cd_curso = $2`,
      [cd_turma, cd_curso]
    );
    if (turma.rowCount === 0) throw new Error('Turma não encontrada para o curso informado.');

    // INSERT (campos removidos foram excluídos do insert)
    const insertQuery = `
      INSERT INTO contrato (
        cd_empresa, cd_estudante, cd_instituicao_ensino,
        bolsa, cd_supervisor, cd_plano_pagamento, cd_template_modelo,
        criado_por, data_criacao,
        data_inicio, data_termino, conteudo_html, status, tipo_contrato,

        -- ✅ novos campos
        data_inicio_basico, data_fim_basico, cd_curso, cd_turma, numero_carteira_trabalho, serie
      ) VALUES (
        $1, $2, $3,
        $4, $5, $6, $7,
        $8, $9,
        $10, $11, $12, 'A', 1,

        $13, $14, $15, $16, $17, $18
      )
      RETURNING cd_contrato
    `;

    const values = [
      cd_empresa, cd_estudante, cd_instituicao_ensino,
      bolsa ?? null, cd_supervisor ?? null, cd_plano_pagamento, cd_template_modelo,
      userId, dataAtual,
      parseDateBRtoISO(data_inicio) ?? null, parseDateBRtoISO(data_termino) ?? null, conteudo_html ?? null,

      // novos
      parseDateBRtoISO(data_inicio_basico) ?? null,
      parseDateBRtoISO(data_fim_basico) ?? null,
      cd_curso, cd_turma,
      numero_carteira_trabalho ?? null, serie ?? null
    ];

    const result = await client.query(insertQuery, values);
    const cd_contrato = result.rows[0].cd_contrato;

    await client.query('COMMIT');
    res.status(201).json({ mensagem: 'Contrato de estágio cadastrado com sucesso.', cd_contrato });
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('[POST /contrato-estagio/cadastrar] Erro: ' + err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    client.release();
  }
});


// GET /contrato-aprendiz/listar
router.get('/listar', verificarToken, async (req, res) => {
  const page  = parseInt(req.query.page)  || 1;
  const limit = parseInt(req.query.limit) || 10;

  const filtros = [];
  const valores = [];

  // Número do contrato
  if (req.query.numero) {
    filtros.push(`ce.cd_contrato = $${valores.length + 1}`);
    valores.push(req.query.numero);
  }

  // Busca por empresa/estudante/CPF
  if (req.query.search) {
    const q = req.query.search.trim();
    if (q) {
      filtros.push(`(
        unaccent(LOWER(e.razao_social)) LIKE unaccent(LOWER($${valores.length + 1}))
        OR unaccent(LOWER(c.nome_completo)) LIKE unaccent(LOWER($${valores.length + 1}))
        OR REGEXP_REPLACE(c.cpf, '[^0-9]', '', 'g') = REGEXP_REPLACE($${valores.length + 1}, '[^0-9]', '', 'g')
      )`);
      valores.push(`%${q}%`);
    }
  }

  // Status (A, D, C)
  if (req.query.status) {
    let status = req.query.status.trim().toUpperCase();
    if (status === 'CANCELADO') status = 'C';
    else if (status === 'ATIVO') status = 'A';
    else if (status === 'DESLIGADO') status = 'D';
    if (['A', 'D', 'C'].includes(status)) {
      filtros.push(`ce.status = $${valores.length + 1}`);
      valores.push(status);
    }
  }

  // Apenas com aditivo
  if (req.query.apenas_com_aditivo !== undefined) {
    const temAditivo = req.query.apenas_com_aditivo === 'true' || req.query.apenas_com_aditivo === '1';
    if (temAditivo) {
      filtros.push(`EXISTS (SELECT 1 FROM contrato a WHERE a.cd_contrato_origem = ce.cd_contrato)`);
    }
  }

  // 🔎 Filtros novos (opcionais): curso/turma
  if (req.query.cd_curso) {
    filtros.push(`ce.cd_curso = $${valores.length + 1}`);
    valores.push(req.query.cd_curso);
  }
  if (req.query.cd_turma) {
    filtros.push(`ce.cd_turma = $${valores.length + 1}`);
    valores.push(req.query.cd_turma);
  }

  const whereExtra = filtros.length > 0 ? ' AND ' + filtros.join(' AND ') : '';

  const countQuery = `
    SELECT COUNT(*)
    FROM contrato ce
    LEFT JOIN empresa e              ON ce.cd_empresa = e.cd_empresa
    LEFT JOIN candidato c            ON ce.cd_estudante = c.cd_candidato
    LEFT JOIN instituicao_ensino ie  ON ce.cd_instituicao_ensino = ie.cd_instituicao_ensino
    LEFT JOIN supervisor s2          ON ce.cd_supervisor = s2.cd_supervisor
    LEFT JOIN plano_pagamento pp     ON ce.cd_plano_pagamento = pp.cd_plano_pagamento
    LEFT JOIN template_modelo tm     ON ce.cd_template_modelo = tm.id_modelo
    LEFT JOIN curso_aprendizagem ca  ON ca.cd_curso = ce.cd_curso
    LEFT JOIN turma t                ON t.cd_turma = ce.cd_turma
    INNER JOIN public.contrato_status cs ON ce.status = cs.status
    WHERE (ce.aditivo = false OR ce.aditivo IS NULL) AND ce.tipo_contrato = 1
    ${whereExtra}
  `;

  const baseQuery = `
    SELECT 
      ce.cd_contrato,
      ce.cd_setor,                  -- ⬅️ novo FK
      s.descricao AS setor_nome,         -- ⬅️ nome do setor associado
      ce.bolsa,
      ce.transporte,
      ce.atividades,
      ce.horario_inicio,
      ce.horario_inicio_intervalo,
      ce.horario_fim_intervalo,
      ce.horario_fim,
      ce.carga_horaria,
      ce.tipo_horario,
      ce.possui_intervalo,
      ce.total_horas_semana,
      ce.data_criacao,
      ce.data_inicio, 
      ce.data_termino as data_fim,

      e.razao_social AS empresa,
      e.nome_fantasia  AS empresa_fantasia,
      concat ( e.cd_empresa  , ' - ' , e.razao_social , '/', e.nome_fantasia) AS empresa_nome_completo,
      c.nome_completo AS estudante,
      ie.razao_social AS instituicao_ensino,
      s2.nome AS supervisor,
      pp.descricao AS plano_pagamento,
      tm.nome AS modelo_contrato,
      ce.status AS status,
      cs.descricao_status,
      ce.data_desligamento,
      ce.cd_template_modelo
    FROM contrato ce
    LEFT JOIN empresa e ON ce.cd_empresa = e.cd_empresa
    LEFT JOIN candidato c ON ce.cd_estudante = c.cd_candidato
    LEFT JOIN instituicao_ensino ie ON ce.cd_instituicao_ensino = ie.cd_instituicao_ensino
    LEFT JOIN supervisor s2 ON ce.cd_supervisor = s2.cd_supervisor
    LEFT JOIN plano_pagamento pp ON ce.cd_plano_pagamento = pp.cd_plano_pagamento
    LEFT JOIN template_modelo tm ON ce.cd_template_modelo = tm.id_modelo
    LEFT JOIN public.setor s ON s.cd_setor = ce.cd_setor     
    INNER JOIN public.contrato_status cs ON ce.status = cs.status
    WHERE (ce.aditivo = false or ce.aditivo is null) and tipo_contrato = 1
    ${whereExtra}
    ORDER BY ce.data_criacao DESC
  `;

  // imprimir queries completas
  console.log('Base Query:', baseQuery);
  console.log('Count Query:', countQuery);
  console.log('Valores:', valores);

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);

    // 🔁 aditivos (mantido)
    const contratosComExtras = await Promise.all(resultado.dados.map(async (contrato) => {
      const aditivosResult = await pool.query(`
        SELECT cd_contrato AS cd_contrato_aditivo, cd_contrato, numero_aditivo, status, data_criacao, data_termino, cd_template_modelo
        FROM contrato
        WHERE tipo_contrato = 1 AND cd_contrato_origem = $1
        ORDER BY numero_aditivo ASC
      `, [contrato.cd_contrato]);

      const aditivos = aditivosResult.rows.map(a => ({
        ...a,
        numero_exibicao: `${contrato.cd_contrato} - ${a.numero_aditivo}`
      }));

      return { ...contrato, aditivos };
    }));

    res.status(200).json({ ...resultado, dados: contratosComExtras });

  } catch (err) {
    logger.error('[GET /contrato-aprendiz/listar] Erro:', err);
    res.status(500).json({ erro: 'Erro ao listar contratos: ' + err });
  }
});


 // PUT /contrato-aprendiz/alterar/:cd_contrato
router.put('/alterar/:cd_contrato', verificarToken, async (req, res) => {
  const { cd_contrato } = req.params;
  if (!cd_contrato) return res.status(400).json({ erro: 'Código do contrato ausente na URL.' });

  // ✅ apenas os campos permitidos (sem setor/horários/transporte/atividades)
  const camposPermitidos = [
    'cd_empresa','cd_estudante','cd_instituicao_ensino',
    'bolsa','cd_supervisor',
    'cd_plano_pagamento','cd_template_modelo',
    'data_inicio','data_termino',
    'conteudo_html','status','data_desligamento',

    // 🆕 novos campos
    'data_inicio_basico','data_fim_basico',
    'cd_curso','cd_turma',
    'numero_carteira_trabalho','serie'
  ];

  

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  const campos = [];
  const valores = [];
  let idx = 1;

  // Carrega estado atual p/ validações de coerência (curso/turma)
  const current = await pool.query(
    `SELECT cd_curso, cd_turma FROM contrato WHERE cd_contrato = $1`,
    [cd_contrato]
  );
  if (current.rowCount === 0) {
    return res.status(404).json({ erro: 'Contrato não encontrado.' });
  }
  const atual = current.rows[0];

  // Monta SET dinâmico
  for (const campo of camposPermitidos) {
    if (req.body[campo] !== undefined) {
      campos.push(`${campo} = $${idx}`);
      valores.push(req.body[campo]);
      idx++;
    }
  }

  if (campos.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo enviado para atualização.' });
  }

  // Auditoria
  campos.push(`alterado_por = $${idx++}`);
  campos.push(`data_alteracao = $${idx++}`);
  valores.push(userId, dataAtual);

  // Converte datas (se vierem no formato BR)
  const dataFields = ['data_inicio','data_termino','data_inicio_basico','data_fim_basico'];
  for (const field of dataFields) {
    if (req.body[field] !== undefined) {
      const iso = parseDateBRtoISO(req.body[field]);
      const pos = campos.findIndex(c => c.startsWith(`${field} =`));
      if (pos !== -1) valores[pos] = iso;
    }
  }

  const updateQuery = `
    UPDATE contrato
       SET ${campos.join(', ')}
     WHERE cd_contrato = $${idx}
  `;
  valores.push(cd_contrato);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ✅ validações de domínio
    const validacoes = [
      { campo: 'cd_empresa',           query: 'SELECT 1 FROM empresa WHERE cd_empresa = $1',                       msg: 'Empresa não encontrada.' },
      { campo: 'cd_estudante',         query: 'SELECT 1 FROM candidato WHERE cd_candidato = $1',                   msg: 'Estudante não encontrado.' },
      { campo: 'cd_plano_pagamento',   query: 'SELECT 1 FROM plano_pagamento WHERE cd_plano_pagamento = $1',       msg: 'Plano de pagamento não encontrado.' },
      { campo: 'cd_template_modelo',   query: 'SELECT 1 FROM template_modelo WHERE id_modelo = $1',                msg: 'Modelo de contrato não encontrado.' },
      { campo: 'cd_supervisor',        query: 'SELECT 1 FROM supervisor WHERE cd_supervisor = $1',                 msg: 'Supervisor não encontrado.' },
      { campo: 'cd_curso',             query: 'SELECT 1 FROM curso_aprendizagem WHERE cd_curso = $1',              msg: 'Curso não encontrado.' }
    ];

    for (const v of validacoes) {
      if (req.body[v.campo] !== undefined) {
        const ok = await client.query(v.query, [req.body[v.campo]]);
        if (ok.rowCount === 0) throw new Error(v.msg);
      }
    }

    // ✅ coerência cd_turma ↔ cd_curso
    //   - se vier cd_turma, ele deve existir e pertencer ao cd_curso (do body se vier, senão o atual do contrato)
    if (req.body.cd_turma !== undefined) {
      const cursoParaValidar = req.body.cd_curso !== undefined ? req.body.cd_curso : atual.cd_curso;
      const turmaOk = await client.query(
        `SELECT 1 FROM turma WHERE cd_turma = $1 AND cd_curso = $2`,
        [req.body.cd_turma, cursoParaValidar]
      );
      if (turmaOk.rowCount === 0) throw new Error('Turma não encontrada para o curso informado.');
    }

    // Executa UPDATE
    await client.query(updateQuery, valores);

    await client.query('COMMIT');
    res.status(200).json({ mensagem: 'Contrato de aprendizagem atualizado com sucesso.' });
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('[PUT /contrato-aprendiz/alterar] Erro: ' + err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    client.release();
  }
});


 // GET /contrato-aprendiz/listar/:id
router.get('/listar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

  try {
    const query = `
      SELECT 
        ce.cd_contrato,
        ce.cd_empresa,
        ce.cd_estudante,
        ce.cd_instituicao_ensino,
        ce.cd_supervisor,
        ce.cd_plano_pagamento,
        ce.cd_template_modelo,
        ce.bolsa,
        ce.data_inicio,
        ce.data_termino,
        ce.data_criacao,
        ce.data_alteracao,
        ce.conteudo_html,
        ce.status,
        cs.descricao_status,
        ce.data_desligamento,

        -- 🆕 campos
        ce.data_inicio_basico,
        ce.data_fim_basico,
        ce.cd_curso,
        ce.cd_turma,
        c.numero_carteira_trabalho
        ,c.numero_serie_carteira_trabalho

        -- descrições/relacionamentos
        ,e.razao_social            AS empresa,
        e.cnpj                   AS empresa_cnpj,
        c.nome_completo          AS estudante,
        c.cpf                    AS estudante_cpf,
        ie.razao_social          AS instituicao_ensino,
        s.nome                   AS supervisor,
        pp.descricao             AS plano_pagamento,
        tm.nome                  AS modelo_contrato,
        ca.nome                  AS curso,
        t.numero                 AS turma_numero,

        -- endereços principais (se houver)
        CONCAT_WS(' ',
          endie.logradouro || ' - ' || endie.numero || ' - ' || endie.bairro || ' - ' ||
          endie.cidade || '/' || endie.uf
        ) AS endereco_completo_instituicao,
        CONCAT_WS(' ',
          endieempresa.logradouro || ' - ' || endieempresa.numero || ' - ' || endieempresa.bairro || ' - ' ||
          endieempresa.cidade || '/' || endieempresa.uf
        ) AS endereco_completo_empresa
      FROM contrato ce
      INNER JOIN empresa e               ON ce.cd_empresa = e.cd_empresa
      INNER JOIN candidato c             ON ce.cd_estudante = c.cd_candidato
      LEFT JOIN instituicao_ensino ie   ON ce.cd_instituicao_ensino = ie.cd_instituicao_ensino
      LEFT  JOIN supervisor s            ON ce.cd_supervisor = s.cd_supervisor
      INNER JOIN plano_pagamento pp      ON ce.cd_plano_pagamento = pp.cd_plano_pagamento
      INNER JOIN template_modelo tm      ON ce.cd_template_modelo = tm.id_modelo
      INNER JOIN public.contrato_status cs ON ce.status = cs.status
      LEFT  JOIN curso_aprendizagem ca   ON ca.cd_curso = ce.cd_curso
      LEFT  JOIN turma t                 ON t.cd_turma = ce.cd_turma
      LEFT  JOIN public.endereco endie
             ON endie.cd_instituicao_ensino = ie.cd_instituicao_ensino
            AND endie.principal = true
            AND endie.ativo = true
      LEFT  JOIN public.endereco endieempresa
             ON endieempresa.cd_empresa = ce.cd_empresa
            AND endieempresa.principal = true
            AND endieempresa.ativo = true
      WHERE ce.tipo_contrato = 1
        AND ce.cd_contrato = $1
    `;

    const result = await pool.query(query, [id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Contrato de aprendizagem não encontrado.' });
    }

    // ✅ sem escala_horarios (foi descontinuado junto com os campos de horários)
    res.status(200).json(result.rows[0]);
  } catch (err) {
    logger.error('[GET /contrato-aprendiz/listar/:id] Erro:', err);
    res.status(500).json({ erro: 'Erro ao buscar contrato de aprendizagem: ' + err.message });
  }
});


function parseDateBRtoISO(dateStr) {
  if (!dateStr) return null;
  const [dia, mes, ano] = dateStr.split('/');
  return `${ano}-${mes}-${dia}`; // formato ISO
}
 
 


 
// POST /contrato-estagio/:id/aditivos
router.post('/:id/aditivos', verificarToken, async (req, res) => {
  const { id } = req.params; // cd_contrato (origem)
  const {
    conteudo_html,
    atividades,
    carga_horaria,
    tipo_horario,
    possui_intervalo,
    total_horas_semana,
    horario_inicio,
    horario_inicio_intervalo,
    horario_fim_intervalo,
    horario_fim,
    data_inicio,
    data_termino,
    valor_transporte,
    valor_alimentacao,
    status,
    itens_aditivo,            // ✅ agrupado
    cd_template_modelo,
    cd_setor                  // ✅ NOVO: setor (FK) opcional para o aditivo
    , escala_horarios  
    , motivo_gravidez        
    , novo_cnpj      // ✅ ACEITAR NO ADITIVO TAMBÉM
  } = req.body;

  const adt_atividades     = itens_aditivo?.atividades     ?? false;
  const adt_beneficios     = itens_aditivo?.beneficios     ?? false;
  const adt_conta_bancaria = itens_aditivo?.conta_bancaria ?? false;
  const adt_horarios       = itens_aditivo?.horarios       ?? false;
  const adt_local_estagio  = itens_aditivo?.local_estagio  ?? false;
  const adt_modalidade     = itens_aditivo?.modalidade     ?? false;
  const adt_recessos       = itens_aditivo?.recessos       ?? false;
  const adt_remuneracao    = itens_aditivo?.remuneracao    ?? false;
  const adt_seguradora     = itens_aditivo?.seguradora     ?? false;
  const adt_supervisor     = itens_aditivo?.supervisor     ?? false;
  const adt_vigencia       = itens_aditivo?.vigencia       ?? false;
  const adt_todos          = itens_aditivo?.todos          ?? false;
  const adt_setor          = itens_aditivo?.setor          ?? false;
  const adt_gravidez       = itens_aditivo?.gravidez       ?? false;
  const adt_cnpj          = itens_aditivo?.cnpj          ?? false;


  const userId = req.usuario.cd_usuario;
  const client = await pool.connect();

  try {
    // ✅ converter datas para ISO antes de inserir
    const di = data_inicio  ? parseDateBRtoISO(data_inicio)  : null;
    const dt = data_termino ? parseDateBRtoISO(data_termino) : null;

    // Se veio vigência no payload (di/dt) ou o aditivo foi marcado como de vigência, valida 24 meses
    const veioVigencia = adt_vigencia || di || dt;

    if (veioVigencia) {

       // Calcula limites considerando o novo aditivo
      const v = await client.query(`
        WITH cadeia AS (
          SELECT data_inicio, data_termino
            FROM contrato
         WHERE  tipo_contrato = 1 and (cd_contrato = $1
                OR cd_contrato_origem = $1)
                and status= 'A'
        ),
        limites AS (
          SELECT
            LEAST(MIN(data_inicio), COALESCE($2::date, MIN(data_inicio))) AS ini,
            GREATEST(MAX(data_termino), COALESCE($3::date, MAX(data_termino))) AS fim
          FROM cadeia
        )
        SELECT
          ini,
          fim,
          (ini + INTERVAL '24 months') AS limite_legal,
          -- true se estourar > 24 meses
          CASE WHEN fim > (ini + INTERVAL '24 months') THEN true ELSE false END AS excede,
          -- métricas auxiliares para mensagem
          (EXTRACT(year  FROM age(fim, ini)) * 12
          + EXTRACT(month FROM age(fim, ini)))::int AS total_meses,
          (fim - ini) AS total_dias
        FROM limites;
      `, [id, di, dt]);

      const { excede, ini, fim, limite_legal, total_meses, total_dias } = v.rows[0];

       if (excede) {
      // Não faz INSERT; aborta com erro de regra de negócio
      await client.query('ROLLBACK');
      return res.status(422).json({
        erro: `Vigência acima do limite legal de 24 meses. O contrato já possui ${total_meses} meses.`,
        detalhe: {
          inicio_cadeia: ini,
          fim_cadeia: fim,
          limite_legal_ate: limite_legal,
          total_meses,
          total_dias: Number(total_dias) // pode serializar como número
        }
       });
    }

 
    }


    await client.query('BEGIN');

    // valida contrato origem
    const origem = await client.query(
      `SELECT cd_empresa, cd_estudante, cd_instituicao_ensino, cd_plano_pagamento
         FROM contrato
        WHERE  tipo_contrato = 1 and cd_contrato = $1`,
      [id]
    );
    if (origem.rowCount === 0) throw new Error('Contrato de estágio de origem não encontrado.');

    const { cd_empresa, cd_estudante, cd_instituicao_ensino, cd_plano_pagamento } = origem.rows[0];


    // ✅ valida setor se veio
    if (cd_setor !== undefined && cd_setor !== null) {
      const setorOk = await client.query(`SELECT 1 FROM setor WHERE cd_setor = $1`, [cd_setor]);
      if (setorOk.rowCount === 0) throw new Error('Setor não encontrado.');
    }

    // pega último numero_aditivo e trava (sem agregação)
    const ultimo = await client.query(
      `SELECT numero_aditivo
         FROM contrato
        WHERE  tipo_contrato = 1 and cd_contrato_origem = $1
        ORDER BY numero_aditivo DESC
        LIMIT 1
        FOR UPDATE`,
      [id]
    );
    const numero_aditivo = (ultimo.rowCount ? ultimo.rows[0].numero_aditivo : 0) + 1;

    // ✅ incluir cd_setor entre as colunas do aditivo
     // INSERT: adiciona adt_setor ANTES de cd_setor
    const insert = `
      INSERT INTO contrato (
        cd_contrato_origem, numero_aditivo, conteudo_html,
        atividades, carga_horaria, tipo_horario, possui_intervalo, total_horas_semana,
        horario_inicio, horario_inicio_intervalo, horario_fim_intervalo, horario_fim,
        data_inicio, data_termino, valor_transporte, valor_alimentacao,
        status,
        adt_atividades, adt_beneficios, adt_conta_bancaria, adt_horarios, adt_local_estagio,
        adt_modalidade, adt_recessos, adt_remuneracao, adt_seguradora, adt_supervisor,
        adt_vigencia, adt_todos,
        adt_setor,                      -- ✅ NOVO AQUI
        cd_setor,                       -- FK opcional
        criado_por, data_criacao, cd_template_modelo, aditivo,
        cd_empresa, cd_estudante, cd_instituicao_ensino, cd_plano_pagamento,  tipo_contrato, adt_gravidez, adt_cnpj, novo_cnpj
      ) VALUES (
        $1,$2,$3,
        $4,$5,$6,$7,$8,
        $9,$10,$11,$12,
        $13,$14,$15,$16,
        COALESCE($17,'A'),
        $18,$19,$20,$21,$22,
        $23,$24,$25,$26,$27,
        $28,$29,
        $30,                           -- ✅ adt_setor
        $31,                           -- ✅ cd_setor
        $32, NOW(), $33, true,
        $34, $35, $36, $37 ,1, $38, $39, $40
      )
      RETURNING cd_contrato, numero_aditivo
    `;

    const vals = [
      id, numero_aditivo, (conteudo_html ?? null),
      (atividades ?? null), (carga_horaria ?? null), (tipo_horario ?? null), (possui_intervalo ?? null), (total_horas_semana ?? null),
      (horario_inicio ?? null), (horario_inicio_intervalo ?? null), (horario_fim_intervalo ?? null), (horario_fim ?? null),
      di, dt, (valor_transporte ?? null), (valor_alimentacao ?? null),
      status ?? null,
      adt_atividades, adt_beneficios, adt_conta_bancaria, adt_horarios, adt_local_estagio,
      adt_modalidade, adt_recessos, adt_remuneracao, adt_seguradora, adt_supervisor,
      adt_vigencia, adt_todos,
      adt_setor,                      // ✅ $30
      (cd_setor ?? null),             // ✅ $31
      userId,                         // ✅ $32
      cd_template_modelo,             // ✅ $33
      cd_empresa, cd_estudante, cd_instituicao_ensino, cd_plano_pagamento // $34..$37
      , adt_gravidez, adt_cnpj, novo_cnpj
    ];

    const r = await client.query(insert, vals);


    const cd_contrato_novo = r.rows[0].cd_contrato;   
    
     // ✅✅ LÓGICA DE ESCALA PARA ADITIVO (igual ao cadastro)
  if (tipo_horario === 'com_escala') {
    if (escala_horarios && Object.keys(escala_horarios).length > 0) {
      // 1) Se veio no payload, grava o que veio
      for (const [dia, dados] of Object.entries(escala_horarios)) {
        await client.query(`
          INSERT INTO contrato_escala (
            cd_contrato, dia_semana, ativo, possui_intervalo,
            horario_inicio, horario_fim, horario_inicio_intervalo, horario_fim_intervalo
          ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
        `, [
          cd_contrato_novo,
          dia,
          dados.ativo ?? false,
          dados.possui_intervalo ?? false,
          dados.horario_inicio ?? null,
          dados.horario_fim ?? null,
          dados.horario_inicio_intervalo ?? null,
          dados.horario_fim_intervalo ?? null
        ]);
      }
    } else {
      // 2) Se NÃO veio no payload, copia a escala do contrato de origem
      const escOrig = await client.query(`
        SELECT dia_semana, ativo, possui_intervalo,
               horario_inicio, horario_fim,
               horario_inicio_intervalo, horario_fim_intervalo
          FROM contrato_escala
         WHERE cd_contrato = $1
      `, [id]);

      for (const e of escOrig.rows) {
        await client.query(`
          INSERT INTO contrato_escala (
            cd_contrato, dia_semana, ativo, possui_intervalo,
            horario_inicio, horario_fim, horario_inicio_intervalo, horario_fim_intervalo
          ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
        `, [
          cd_contrato_novo,
          e.dia_semana,
          e.ativo ?? false,
          e.possui_intervalo ?? false,
          e.horario_inicio ?? null,
          e.horario_fim ?? null,
          e.horario_inicio_intervalo ?? null,
          e.horario_fim_intervalo ?? null
        ]);
      }
    }
  }// ✅ ID do ADITIVO criado


    await client.query('COMMIT');
    res.status(201).json({
      mensagem: 'Aditivo criado com sucesso.',
      cd_contrato: r.rows[0].cd_contrato,
      numero_aditivo
    });
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('[POST /contrato-estagio/:id/aditivos] ' + err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    client.release();
  }
});


// GET /aditivos/:cd_contrato
router.get('/aditivos/:cd', verificarToken, async (req, res) => {
  const { cd } = req.params;
  try {
    const r = await pool.query(`
      SELECT a.*,
             ce.cd_contrato AS numero_base,
             st.cd_setor,
             st.descricao AS setor_nome
        FROM contrato a
        JOIN contrato ce ON ce.cd_contrato = a.cd_contrato_origem
        LEFT JOIN setor st       ON st.cd_setor = a.cd_setor
       WHERE  ce.tipo_contrato = 1 and a.aditivo = true
         AND a.cd_contrato = $1
    `, [cd]);

    if (r.rowCount === 0) return res.status(404).json({ erro: 'Aditivo não encontrado.' });

    const row = r.rows[0];
    row.numero_exibicao = `${row.numero_base} - ${row.numero_aditivo}`;
    row.itens_aditivo = {
      todos: row.adt_todos,
      modalidade: row.adt_modalidade,
      supervisor: row.adt_supervisor,
      atividades: row.adt_atividades,
      beneficios: row.adt_beneficios,
      conta_bancaria: row.adt_conta_bancaria,
      horarios: row.adt_horarios,
      local_estagio: row.adt_local_estagio,
      recessos: row.adt_recessos,
      remuneracao: row.adt_remuneracao,
      seguradora: row.adt_seguradora,
      vigencia: row.adt_vigencia,
      setor: row.adt_setor,          // ✅ NOVO
      gravidez: row.adt_gravidez,
      cnpj: row.adt_cnpj
    };

    res.json(row);
  } catch (err) {
    logger.error('[GET /aditivos/:cd] ' + err.message);
    res.status(500).json({ erro: err.message });
  }
});


// PUT /aditivos/:cd  — excluir escala e recriar (igual contrato)
router.put('/aditivos/:cd', verificarToken, async (req, res) => {
  const { cd } = req.params;
  const userId = req.usuario.cd_usuario;

  const permitidos = [
    'conteudo_html','atividades','carga_horaria','tipo_horario','possui_intervalo',
    'total_horas_semana','horario_inicio','horario_inicio_intervalo','horario_fim_intervalo',
    'horario_fim','data_inicio','data_termino','valor_transporte','valor_alimentacao','status',
    'cd_setor','cd_supervisor','bolsa','transporte', 'cd_template_modelo'
  ];

  const campos = [];
  const valores = [];
  let i = 1;

  // converter datas
  const di = req.body.data_inicio  ? parseDateBRtoISO(req.body.data_inicio)  : null;
  const dt = req.body.data_termino ? parseDateBRtoISO(req.body.data_termino) : null;

  // valida setor se veio
  if (req.body.cd_setor !== undefined && req.body.cd_setor !== null) {
    const valSetor = await pool.query(`SELECT 1 FROM setor WHERE cd_setor = $1`, [req.body.cd_setor]);
    if (valSetor.rowCount === 0) {
      return res.status(400).json({ erro: 'Setor não encontrado.' });
    }
  }

  // campos normais
  for (const c of permitidos) {
    if (req.body[c] !== undefined) {
      if (c === 'data_inicio') {
        campos.push(`${c} = $${i++}`); valores.push(di);
      } else if (c === 'data_termino') {
        campos.push(`${c} = $${i++}`); valores.push(dt);
      } else {
        campos.push(`${c} = $${i++}`); valores.push(req.body[c]);
      }
    }
  }

  // flags itens_aditivo -> colunas adt_*
  const itens = req.body.itens_aditivo;
  if (itens && typeof itens === 'object') {
    const mapa = {
      atividades:      'adt_atividades',
      beneficios:      'adt_beneficios',
      conta_bancaria:  'adt_conta_bancaria',
      horarios:        'adt_horarios',
      local_estagio:   'adt_local_estagio',
      modalidade:      'adt_modalidade',
      recessos:        'adt_recessos',
      remuneracao:     'adt_remuneracao',
      seguradora:      'adt_seguradora',
      supervisor:      'adt_supervisor',
      vigencia:        'adt_vigencia',
      setor:           'adt_setor',
      gravidez:        'adt_gravidez',
      cnpj:           'adt_cnpj'
    };

    if ('todos' in itens) {
      campos.push(`adt_todos = $${i++}`);
      valores.push(!!itens.todos);
    }

    for (const [k, coluna] of Object.entries(mapa)) {
      if (k in itens) {
        campos.push(`${coluna} = $${i++}`);
        valores.push(!!itens[k]);
      } else if (itens?.todos === true) {
        campos.push(`${coluna} = $${i++}`);
        valores.push(true);
      }
    }
  }

  const client = await pool.connect();

  
    // Busca dados atuais do aditivo e identifica o contrato raiz da cadeia
    const cur = await client.query(`
      SELECT cd_contrato, cd_contrato_origem, cd_estudante, data_inicio AS atual_ini, data_termino AS atual_fim
      FROM contrato
      WHERE  tipo_contrato =1 and  cd_contrato = $1
      FOR UPDATE
    `, [cd]);

    if (cur.rowCount === 0) {
      await client.query('ROLLBACK');
      client.release();
      return res.status(404).json({ erro: 'Aditivo não encontrado.' });
    }

    const row = cur.rows[0];
    const raiz = row.cd_contrato_origem ?? row.cd_contrato; // se não tiver origem, ele é o contrato base
    const novoIni = (di ?? row.atual_ini) || null;
    const novoFim = (dt ?? row.atual_fim) || null;

  const mudouVigencia = ('data_inicio' in req.body) || ('data_termino' in req.body) || (itens?.vigencia === true);
 


  if (mudouVigencia) {
    // calcula janela total da cadeia incluindo os novos valores deste aditivo

     const v = await client.query(`
          WITH cadeia AS (
            SELECT data_inicio, data_termino
              FROM contrato
             WHERE  tipo_contrato = 1 and (cd_contrato = $1
                OR cd_contrato_origem = $1)
                and status= 'A'
          ),
          limites AS (
            SELECT
              LEAST(MIN(data_inicio), COALESCE($2::date, MIN(data_inicio))) AS ini,
              GREATEST(MAX(data_termino), COALESCE($3::date, MAX(data_termino))) AS fim
            FROM cadeia
          )
          SELECT
            ini,
            fim,
            (ini + INTERVAL '24 months') AS limite_legal,
            CASE WHEN fim > (ini + INTERVAL '24 months') THEN true ELSE false END AS excede,
            (EXTRACT(year  FROM age(fim, ini)) * 12
             + EXTRACT(month FROM age(fim, ini)))::int AS total_meses,
            (fim - ini) AS total_dias
          FROM limites;
        `, [raiz, novoIni, novoFim]);

        const { excede, ini, fim, limite_legal, total_meses, total_dias } = v.rows[0] || {};

        if (excede) {
          await client.query('ROLLBACK');
          client.release();
            return res.status(422).json({
            erro: `Vigência acima do limite legal de 24 meses. O contrato já possui ${total_meses} meses`,
            detalhe: {
              inicio_cadeia: ini,
              fim_cadeia: fim,
              limite_legal_ate: limite_legal,
              total_meses,
              total_dias: Number(total_dias)
            }
            });
        }

  }


  if (!campos.length && !('escala_horarios' in req.body) && !('tipo_horario' in req.body)) {
    return res.status(400).json({ erro: 'Nada para atualizar.' });
  }

  campos.push(`alterado_por = $${i++}`);
  campos.push(`data_alteracao = NOW()`);
  valores.push(userId);

  const sqlUpdate = `
    UPDATE contrato
       SET ${campos.join(', ')}
     WHERE cd_contrato = $${i}
  `;
  valores.push(cd);


  try {
    await client.query('BEGIN');

    // aplica UPDATE se houver campos
    if (campos.length) {
      await client.query(sqlUpdate, valores);
    }

    // ====== ESCALA: excluir tudo e recriar (como no contrato) ======
    // Só mexe na escala se vier tipo_horario ou escala_horarios no payload
    if ('tipo_horario' in req.body || 'escala_horarios' in req.body) {
      // tipo efetivo: se não veio no body, usa o atual do aditivo
      let tipoEfetivo = req.body.tipo_horario;
      if (tipoEfetivo === undefined) {
        const rTipo = await client.query(
          `SELECT tipo_horario FROM contrato WHERE  tipo_contrato = 1 and cd_contrato = $1`,
          [cd]
        );
        tipoEfetivo = rTipo.rows[0]?.tipo_horario ?? null;
      }

      // 1) apaga tudo
      await client.query(`DELETE FROM contrato_escala WHERE cd_contrato = $1`, [cd]);

      // 2) recria se "com_escala" e houver payload de escala
      if (tipoEfetivo === 'com_escala' && req.body.escala_horarios) {
        const escala = req.body.escala_horarios;
        for (const [dia, dados] of Object.entries(escala)) {
          await client.query(`
            INSERT INTO contrato_escala (
              cd_contrato, dia_semana, ativo, possui_intervalo,
              horario_inicio, horario_fim, horario_inicio_intervalo, horario_fim_intervalo
            ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
          `, [
            cd,
            dia,
            dados.ativo ?? false,
            dados.possui_intervalo ?? false,
            dados.horario_inicio ?? null,
            dados.horario_fim ?? null,
            dados.horario_inicio_intervalo ?? null,
            dados.horario_fim_intervalo ?? null
          ]);
        }
      }
      // Se tipo não for "com_escala" ou não veio escala no payload, fica sem linhas (igual ao contrato).
    }
    // ====== /ESCALA ======

    await client.query('COMMIT');
    res.json({ mensagem: 'Aditivo atualizado com sucesso.' });
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('[PUT /aditivos/:cd] ' + err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    client.release();
  }
});


 // ✅ Exportação CSV com filtros dinâmicos
router.get('/exportar/contratos-seguro', verificarToken, async (req, res) => {
  const filtros = [];
  const valores = [];

  // 🔹 Filtro por código do contrato
  if (req.query.numero !== undefined && req.query.numero !== null) {
    const numero = String(req.query.numero).trim();
    if (numero.length > 0) {
      filtros.push(`ce.cd_contrato = $${valores.length + 1}`);
      valores.push(numero);
    }
  }

  // 🔹 Filtro unificado por nome do estudante, CPF, empresa ou CNPJ
  if (req.query.search !== undefined && req.query.search !== null) {
    const termoBusca = String(req.query.search || '').trim();
    if (termoBusca.length > 0) {
      filtros.push(`(
        unaccent(LOWER(es.nome_completo)) LIKE unaccent(LOWER($${valores.length + 1}))
        OR REGEXP_REPLACE(es.cpf, '[^0-9]', '', 'g') = REGEXP_REPLACE(COALESCE($${valores.length + 1}, ''), '[^0-9]', '', 'g')
        OR unaccent(LOWER(e.razao_social)) LIKE unaccent(LOWER($${valores.length + 1}))
        OR unaccent(LOWER(e.nome_fantasia)) LIKE unaccent(LOWER($${valores.length + 1}))
        OR REGEXP_REPLACE(e.cnpj, '[^0-9]', '', 'g') = REGEXP_REPLACE(COALESCE($${valores.length + 1}, ''), '[^0-9]', '', 'g')
      )`);
      valores.push(`%${termoBusca}%`);
    }
  }

  // 🔹 Filtro por nome ou CNPJ da instituição
  if (req.query.instituicao !== undefined && req.query.instituicao !== null) {
    const instituicao = String(req.query.instituicao || '').trim();
    if (instituicao.length > 0) {
      filtros.push(`(
        unaccent(LOWER(ie.razao_social)) LIKE unaccent(LOWER($${valores.length + 1}))
        OR REGEXP_REPLACE(ie.cnpj, '[^0-9]', '', 'g') = REGEXP_REPLACE(COALESCE($${valores.length + 1}, ''), '[^0-9]', '', 'g')
      )`);
      valores.push(`%${instituicao}%`);
    }
  }

  // 🔹 Filtro por status
  if (req.query.status !== undefined && req.query.status !== null) {
    let status = String(req.query.status || '').trim().toUpperCase();
    if (status === 'CANCELADO') status = 'C';
    else if (status === 'ATIVO') status = 'A';
    else if (status === 'DESLIGADO') status = 'D';
    if (['A', 'D', 'C'].includes(status)) {
      filtros.push(`ce.status = $${valores.length + 1}`);
      valores.push(status);
    }
  }

  // 🔹 Filtro por período de data de início (vigência inicial)
  if (req.query.dataInicioVigenciaDe && req.query.dataInicioVigenciaAte) {
    const de = parseDateBrToISO(String(req.query.dataInicioVigenciaDe || '').trim());
    const ate = parseDateBrToISO(String(req.query.dataInicioVigenciaAte || '').trim());
    if (de && ate) {
      filtros.push(`ce.data_inicio BETWEEN $${valores.length + 1} AND $${valores.length + 2}`);
      valores.push(de, ate);
    }
  }

  // 🔹 Filtro por período de data de término (vigência final)
  if (req.query.dataFinalVigenciaDe && req.query.dataFinalVigenciaAte) {
    const de = parseDateBrToISO(String(req.query.dataFinalVigenciaDe || '').trim());
    const ate = parseDateBrToISO(String(req.query.dataFinalVigenciaAte || '').trim());
    if (de && ate) {
      filtros.push(`ce.data_termino BETWEEN $${valores.length + 1} AND $${valores.length + 2}`);
      valores.push(de, ate);
    }
  }

  // 🔹 Filtro por período de encerramento (data de desligamento)
  if (req.query.dataEncerramentoDe && req.query.dataEncerramentoAte) {
    const de = parseDateBrToISO(String(req.query.dataEncerramentoDe || '').trim());
    const ate = parseDateBrToISO(String(req.query.dataEncerramentoAte || '').trim());
    if (de && ate) {
      filtros.push(`ce.data_desligamento BETWEEN $${valores.length + 1} AND $${valores.length + 2}`);
      valores.push(de, ate);
    }
  }

  // 🔹 Montagem do WHERE dinâmico
  const where =
    filtros.length > 0
      ? `WHERE ce.tipo_contrato = 1 AND (ce.aditivo IS NULL OR ce.aditivo = FALSE) AND ${filtros.join(' AND ')}`
      : `WHERE ce.tipo_contrato = 1 AND (ce.aditivo IS NULL OR ce.aditivo = FALSE)`;

  // ✅ Query base
  const query = `
    SELECT
      ce.cd_contrato,
      to_char(ce.data_inicio,  'DD/MM/YYYY')  AS data_inicio,
      to_char(ce.data_termino, 'DD/MM/YYYY')  AS data_termino,
      CASE 
        WHEN ce.status = 'A' THEN 'ATIVO'
        WHEN ce.status = 'D' THEN 'DESLIGADO'
        WHEN ce.status = 'C' THEN 'CANCELADO'
        ELSE ce.status
      END AS status,
      e.razao_social AS empresa_razao_social,
      es.nome_completo AS estudante_nome,
      es.cpf AS estudante_cpf,
      es.email AS estudante_email,
      CASE 
        WHEN es.sexo = 'M' THEN 'MASCULINO'
        WHEN es.sexo = 'F' THEN 'FEMININO'
        ELSE 'NÃO INFORMADO'
      END AS estudante_sexo,
      to_char(es.data_nascimento, 'DD/MM/YYYY') AS estudante_data_nascimento,
      to_char(ce.data_desligamento, 'DD/MM/YYYY') AS data_encerramento,
      es.rg AS estudante_rg,
      s.numero_apolice AS numero_apolice
    FROM public.contrato ce
      INNER JOIN public.candidato es ON es.cd_candidato = ce.cd_estudante
      INNER JOIN public.empresa e ON e.cd_empresa = ce.cd_empresa
      left JOIN public.seguradora s ON s.cd_seguradora = e.cd_seguradora
      INNER JOIN public.instituicao_ensino ie ON ie.cd_instituicao_ensino = ce.cd_instituicao_ensino
    ${where}
    ORDER BY ce.cd_contrato;
  `;

  console.log('Query Export:', query);
  console.log('Valores:', valores);

  try {
    const result = await pool.query(query, valores);
    const linhas = result.rows;

    // 🔹 Caso não haja dados, retorna apenas cabeçalho
    if (!linhas || linhas.length === 0) {
      console.warn('⚠️ Nenhum contrato encontrado para exportar.');
      const csvExporter = createCsvExporter({
        filename: () => `contratos-seguro-${new Date().toISOString().slice(0, 10)}.csv`,
        fields: [
          'cd_contrato',
          'data_inicio',
          'data_termino',
          'status',
          'empresa_razao_social',
          'estudante_nome',
          'estudante_cpf',
          'estudante_email',
          'estudante_sexo',
          'estudante_data_nascimento',
          'data_encerramento',
          'estudante_rg',
          'numero_apolice'
        ],
        header: [
          'ID do Contrato',
          'Início da Vigência',
          'Final da Vigência',
          'Status do Contrato',
          'Razão Social da Empresa',
          'Nome do Estudante',
          'CPF do Estudante',
          'E-mail do Estudante',
          'Sexo',
          'Data de Nascimento',
          'Data de Encerramento',
          'RG do Estudante',
          'Número da Apólice'
        ]
      });
      return csvExporter(req, res, []); // Exporta CSV vazio com cabeçalho
    }

    // 🔹 Limpa dados nulos/indefinidos para exportação
    const rows = linhas
      .filter(r => r !== null && typeof r === 'object')
      .map(r => {
        const safeRow = {};
        for (const key in r) {
          safeRow[key] = (r[key] === null || r[key] === undefined) ? '' : r[key];
        }
        return safeRow;
      });

    // 🔹 Exporta CSV
    const csvExporter = createCsvExporter({
      filename: () => `contratos-seguro-${new Date().toISOString().slice(0, 10)}.csv`,
      fields: Object.keys(rows[0]),
      header: [
        'ID do Contrato',
        'Início da Vigência',
        'Final da Vigência',
        'Status do Contrato',
        'Razão Social da Empresa',
        'Nome do Estudante',
        'CPF do Estudante',
        'E-mail do Estudante',
        'Sexo',
        'Data de Nascimento',
        'Data de Encerramento',
        'RG do Estudante',
        'Número da Apólice'
      ]
    });

    return csvExporter(req, res, rows);
  } catch (err) {
    console.error('Erro ao exportar contratos do seguro:', err);
    res.status(500).json({ erro: 'Erro ao exportar contratos do seguro', motivo: err.message });
  }
});




const exportContratos = createCsvExporter({
  filename: () => `contratos-aprendiz-${new Date().toISOString().slice(0,10)}.csv`,
  fields: [
    'cd_contrato',
    'aprendiz',
    'empresa',
    'instituicao',
    'curso',
    'cd_curso',
    'turma_numero',
    'cd_turma',
    'bolsa',
    'data_inicio',
    'data_fim','data_desligamento',
    'data_inicio_basico',
    'data_fim_basico',
    'numero_carteira_trabalho',
    'serie',
    'status',
    'criado_por',
    'data_criacao',
    'alterado_por',
    'data_alteracao',
    'data_inicio_iso',
    'data_fim_iso',
    'data_inicio_basico_iso',
    'data_fim_basico_iso'
  ],
  header: [
    'Número',
    'Aprendiz',
    'Empresa',
    'Instituição',
    'Curso',
    'Cód. Curso',
    'Turma',
    'Cód. Turma',
    'Bolsa (R$)',
    'Data Vigencia Início'
    ,'Data Vigencia Fim'
    ,'Data Encerramento',
    'Data Início (Básico)',
    'Data Fim (Básico)',
    'Nº Carteira',
    'Série Carteira',
    'Status',
    'Criado Por',
    'Data Criação',
    'Alterado Por',
    'Data Alteração',
    'Início Contrato (ISO)',
    'Fim Contrato (ISO)',
    'Início Básico (ISO)',
    'Fim Básico (ISO)'
  ],
  baseQuery: `
    SELECT
      ce.cd_contrato,
      es.nome_completo AS aprendiz,
      e.razao_social AS empresa,
      ie.razao_social AS instituicao,
      ca.nome AS curso,
      ce.cd_curso,
      t.numero AS turma_numero,
      ce.cd_turma,
      ce.bolsa,
      to_char(ce.data_inicio,        'DD/MM/YYYY') AS data_inicio,
      to_char(ce.data_termino,       'DD/MM/YYYY') AS data_fim,
      to_char(ce.data_inicio_basico, 'DD/MM/YYYY') AS data_inicio_basico,
      to_char(ce.data_fim_basico,    'DD/MM/YYYY') AS data_fim_basico,
      to_char(ce.data_desligamento, 'DD/MM/YYYY') AS data_desligamento,
      ce.data_inicio AS data_inicio_iso,
      ce.data_termino AS data_fim_iso,
      ce.data_inicio_basico AS data_inicio_basico_iso,
      ce.data_fim_basico AS data_fim_basico_iso,
      ce.numero_carteira_trabalho,
      ce.serie,
      ce.status,
      COALESCE(u1.nome,'') AS criado_por,
      to_char(ce.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.nome,'') AS alterado_por,
      to_char(ce.data_alteracao,'DD/MM/YYYY HH24:MI') AS data_alteracao
    FROM public.contrato ce
      INNER JOIN public.candidato es ON es.cd_candidato = ce.cd_estudante
      INNER JOIN public.empresa e ON e.cd_empresa = ce.cd_empresa
      LEFT JOIN public.instituicao_ensino ie ON ie.cd_instituicao_ensino = ce.cd_instituicao_ensino
      LEFT JOIN public.curso_aprendizagem ca ON ca.cd_curso = ce.cd_curso
      LEFT JOIN public.turma t ON t.cd_turma = ce.cd_turma
      LEFT JOIN public.usuarios u1 ON u1.cd_usuario = ce.criado_por
      LEFT JOIN public.usuarios u2 ON u2.cd_usuario = ce.alterado_por
    {{WHERE}}
    ORDER BY ce.cd_contrato
  `,

  // 🔹 Aplica exatamente os mesmos filtros do /contratos-seguro
  buildWhereAndParams: (req) => {
    const filtros = [];
    const valores = [];

    // Código do contrato
    if (req.query.numero !== undefined && req.query.numero !== null) {
      const numero = String(req.query.numero).trim();
      if (numero.length > 0) {
        filtros.push(`ce.cd_contrato = $${valores.length + 1}`);
        valores.push(numero);
      }
    }

    // Nome, CPF, Empresa, CNPJ
    if (req.query.search !== undefined && req.query.search !== null) {
      const termoBusca = String(req.query.search || '').trim();
      if (termoBusca.length > 0) {
        filtros.push(`(
          unaccent(LOWER(es.nome_completo)) LIKE unaccent(LOWER($${valores.length + 1}))
          OR REGEXP_REPLACE(es.cpf, '[^0-9]', '', 'g') = REGEXP_REPLACE(COALESCE($${valores.length + 1}, ''), '[^0-9]', '', 'g')
          OR unaccent(LOWER(e.razao_social)) LIKE unaccent(LOWER($${valores.length + 1}))
          OR unaccent(LOWER(e.nome_fantasia)) LIKE unaccent(LOWER($${valores.length + 1}))
          OR REGEXP_REPLACE(e.cnpj, '[^0-9]', '', 'g') = REGEXP_REPLACE(COALESCE($${valores.length + 1}, ''), '[^0-9]', '', 'g')
        )`);
        valores.push(`%${termoBusca}%`);
      }
    }

    // Instituição (nome ou CNPJ)
    if (req.query.instituicao !== undefined && req.query.instituicao !== null) {
      const instituicao = String(req.query.instituicao || '').trim();
      if (instituicao.length > 0) {
        filtros.push(`(
          unaccent(LOWER(ie.razao_social)) LIKE unaccent(LOWER($${valores.length + 1}))
          OR REGEXP_REPLACE(ie.cnpj, '[^0-9]', '', 'g') = REGEXP_REPLACE(COALESCE($${valores.length + 1}, ''), '[^0-9]', '', 'g')
        )`);
        valores.push(`%${instituicao}%`);
      }
    }

    // Status
    if (req.query.status !== undefined && req.query.status !== null) {
      let status = String(req.query.status || '').trim().toUpperCase();
      if (status === 'CANCELADO') status = 'C';
      else if (status === 'ATIVO') status = 'A';
      else if (status === 'DESLIGADO') status = 'D';
      if (['A', 'D', 'C'].includes(status)) {
        filtros.push(`ce.status = $${valores.length + 1}`);
        valores.push(status);
      }
    }

    // Período de início do contrato
    if (req.query.dataInicioVigenciaDe && req.query.dataInicioVigenciaAte) {
      const de = parseDateBrToISO(String(req.query.dataInicioVigenciaDe || '').trim());
      const ate = parseDateBrToISO(String(req.query.dataInicioVigenciaAte || '').trim());
      if (de && ate) {
        filtros.push(`ce.data_inicio BETWEEN $${valores.length + 1} AND $${valores.length + 2}`);
        valores.push(de, ate);
      }
    }

    // Período de término do contrato
    if (req.query.dataFinalVigenciaDe && req.query.dataFinalVigenciaAte) {
      const de = parseDateBrToISO(String(req.query.dataFinalVigenciaDe || '').trim());
      const ate = parseDateBrToISO(String(req.query.dataFinalVigenciaAte || '').trim());
      if (de && ate) {
        filtros.push(`ce.data_termino BETWEEN $${valores.length + 1} AND $${valores.length + 2}`);
        valores.push(de, ate);
      }
    }

    // Período de encerramento (data desligamento)
    if (req.query.dataEncerramentoDe && req.query.dataEncerramentoAte) {
      const de = parseDateBrToISO(String(req.query.dataEncerramentoDe || '').trim());
      const ate = parseDateBrToISO(String(req.query.dataEncerramentoAte || '').trim());
      if (de && ate) {
        filtros.push(`ce.data_desligamento BETWEEN $${valores.length + 1} AND $${valores.length + 2}`);
        valores.push(de, ate);
      }
    }

    // Base: tipo contrato
    filtros.push(`ce.tipo_contrato = 1`);
    filtros.push(`(ce.aditivo IS NULL OR ce.aditivo = FALSE)`);

    const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';
    return { where, params: valores };
  },

  rowMap: (r) => [
    r.cd_contrato,
    r.aprendiz || '',
    r.empresa || '',
    r.instituicao || '',
    r.curso || '',
    r.cd_curso ?? '',
    r.turma_numero ?? '',
    r.cd_turma ?? '',
    r.bolsa ?? '',
    r.data_inicio || '',
    r.data_fim || '',
    r.data_desligamento || '',
    r.data_inicio_basico || '',
    r.data_fim_basico || '',
    r.numero_carteira_trabalho || '',
    r.serie || '',
    r.status || '',
    r.criado_por || '',
    r.data_criacao || '',
    r.alterado_por || '',
    r.data_alteracao || '',
    r.data_inicio_iso || '',
    r.data_fim_iso || '',
    r.data_inicio_basico_iso || '',
    r.data_fim_basico_iso || ''
  ]
});

 


// registre a rota
router.get('/exportar/csv', verificarToken, exportContratos);




module.exports = router;
