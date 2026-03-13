// routes/vaga.js
const express = require('express');
const router = express.Router();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');

const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');

router.get('/listar', verificarToken, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { status, q, search, disponivel_web, setor, tipo_regime, sexo, com_candidatura, pcd } = req.query;
  const filtros = [];
  const valores = [];

  // 🔹 Filtro por status
  if (status) {
    valores.push(status);
    filtros.push(`vaga.status = $${valores.length}`);
  }

  // 🔹 Filtro de busca geral (empresa, setor, atividades, observação, código)
  if (search) {
    const termo = search.trim();
    valores.push(`%${termo}%`);
    filtros.push(`
      (
        unaccent(LOWER(vaga.nome_processo_seletivo)) ILIKE unaccent(LOWER($${valores.length})) OR
        unaccent(LOWER(vaga.atividades)) ILIKE unaccent(LOWER($${valores.length})) OR
        unaccent(LOWER(vaga.observacao)) ILIKE unaccent(LOWER($${valores.length})) OR
        unaccent(LOWER(emp.razao_social)) ILIKE unaccent(LOWER($${valores.length})) OR
        unaccent(LOWER(emp.nome_fantasia)) ILIKE unaccent(LOWER($${valores.length})) OR
        CAST(vaga.cd_vaga AS TEXT) ILIKE $${valores.length}
      )
    `);
  }

  if (com_candidatura == true || com_candidatura == 'true'  ) {
    filtros.push(`  (select count(*)   FROM candidatura_vaga cv       where  vaga.cd_vaga = cv.cd_vaga) >0  `);
  }

  // 🔹 Filtro por setor
  if (setor) {
    const termo = setor.trim();
    valores.push(`%${termo}%`);
    filtros.push(`unaccent(LOWER(vaga.setor)) ILIKE unaccent(LOWER($${valores.length}))`);
  }

  // 🔹 Filtro pelo campo disponivel_web (true/false)
  if (typeof disponivel_web !== 'undefined') {
    const dv = String(disponivel_web).trim().toLowerCase();
    const truthy = ['1', 'true', 't', 'yes', 'sim'];
    const falsy = ['0', 'false', 'f', 'no', 'nao', 'não'];
    if (truthy.includes(dv) || falsy.includes(dv)) {
      valores.push(truthy.includes(dv));
      filtros.push(`vaga.disponivel_web = $${valores.length}`);
    }
  }

  // 🔹 Filtro pelo tipo de regime (1 = Jovem Aprendiz, 2 = Estágio)
  if (tipo_regime) {
    const termo = tipo_regime
      .trim()
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '');

    let idRegime = null;
    const estagioTerms = ['estagio', 'estagiario', '2'];
    const jovemTerms = ['jovem', 'jovem_aprendiz', 'jovem aprendiz', '1'];

    if (estagioTerms.includes(termo)) idRegime = 2;
    if (jovemTerms.includes(termo)) idRegime = 1;

    if (idRegime) {
      valores.push(idRegime);
      filtros.push(`vaga.id_regime_contratacao = $${valores.length}`);
    }
  }

  // 🔹 Filtro por sexo
  if (sexo) {
    valores.push(sexo);
    filtros.push(`vaga.sexo = $${valores.length}`);
  }

  // 🔹 Filtro por PCD
  if (typeof pcd !== 'undefined') {
    const truthy = ['1', 'true', 't', 'yes', 'sim'];
    const falsy = ['0', 'false', 'f', 'no', 'nao', 'não'];

    const v = String(pcd).toLowerCase().trim();

    if (truthy.includes(v) || falsy.includes(v)) {
      valores.push(truthy.includes(v));
      filtros.push(`vaga.pcd = $${valores.length}`);
    }
  }       

  // 🔹 WHERE final
  const where = filtros.length > 0 ? `WHERE ${filtros.join(' AND ')}` : '';

  // 🔹 Query principal
  //colocar o contador pra informar quantas pessoas se candidataram a vaga

  const baseQuery = `
    SELECT 
      vaga.*,
      vaga.nome_processo_seletivo,
      vaga.exibir_empresa,
      vaga.exibir_salario,
      vaga.exibir_beneficios,
      emp.razao_social AS nome_empresa,
      emp.nome_fantasia AS nome_fantasia,
      cidade.nome AS nome_cidade,
      supervisor.nome AS nome_supervisor,
      cidade.uf 
      , (select count(*)   FROM candidatura_vaga cv       where  vaga.cd_vaga = cv.cd_vaga) qtd_candidatura
    FROM public.vaga
    LEFT JOIN public.empresa emp ON emp.cd_empresa = vaga.cd_empresa
    LEFT JOIN public.cidade cidade ON cidade.cd_cidade = vaga.cd_cidade
    LEFT JOIN public.supervisor supervisor ON supervisor.cd_supervisor = vaga.cd_supervisor
    ${where}
    ORDER BY vaga.data_criacao DESC
  `;

  // 🔹 Query de contagem
  const countQuery = `
    SELECT COUNT(*) 
    FROM public.vaga
    LEFT JOIN public.empresa emp ON emp.cd_empresa = vaga.cd_empresa
    ${where}
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json(resultado);
  } catch (err) {
    logger.error('Erro ao listar vagas: ' + err.stack, 'Vaga');
    res.status(500).json({ erro: 'Erro ao listar vagas.', motivo: err.message });
  }
});





//
// GET - Buscar detalhes da vaga por ID (inclui cursos vinculados)
//
router.get('/listar/:id', verificarToken, async (req, res) => {
  const { id } = req.params;

  try {
    const vagaQuery = `
      SELECT 
        vaga.cd_vaga,
        vaga.status,
        vaga.observacao,
        vaga.id_regime_contratacao,
        vaga.cd_cidade,
        vaga.cd_turno,
        vaga.setor,
        vaga.cd_supervisor,
        vaga.atividades,
        vaga.sexo,
        vaga.semestre_inicio,
        vaga.ano_inicio,
        vaga.semestre_fim,
        vaga.ano_fim,
        TO_CHAR(vaga.horario_turno1_inicio, 'HH24:MI') AS horario_turno1_inicio,
        TO_CHAR(vaga.horario_turno1_fim, 'HH24:MI') AS horario_turno1_fim,
        TO_CHAR(vaga.horario_turno2_inicio, 'HH24:MI') AS horario_turno2_inicio,
        TO_CHAR(vaga.horario_turno2_fim, 'HH24:MI') AS horario_turno2_fim,
        vaga.data_entrevista,
        vaga.contato_entrevista,
        vaga.endereco_entrevista,
        vaga.telefone_entrevista,
        vaga.data_inicio_contrato,
        vaga.data_fim_contrato,
        vaga.valor_bolsa,
        vaga.carga_horaria,
        vaga.transporte,
        vaga.cesta_basica,
        vaga.duracao_meses,
        vaga.observacao_contrato,
        vaga.cd_empresa,
        vaga.data_criacao,
        vaga.criado_por,
        vaga.data_alteracao,
        vaga.alterado_por,
        vaga.cd_nivel_formacao,
        vaga.disponivel_web,
        vaga.exibir_empresa,       -- ✅ novo campo
        vaga.exibir_salario,       -- ✅ novo campo
        vaga.exibir_beneficios,    -- ✅ novo campo
        cidade.nome AS nome_cidade,
        supervisor.nome AS nome_supervisor,
        vaga.nome_processo_seletivo,
        cidade.uf
      FROM public.vaga
      LEFT JOIN cidade ON cidade.cd_cidade = vaga.cd_cidade
      LEFT JOIN supervisor ON supervisor.cd_supervisor = vaga.cd_supervisor
      WHERE vaga.cd_vaga = $1
    `;

    const vagaResult = await pool.query(vagaQuery, [id]);

    if (vagaResult.rowCount === 0) {
      return res.status(404).json({ erro: 'Vaga não encontrada.' });
    }

    const vaga = vagaResult.rows[0];

    const cursosQuery = `
      SELECT 
        vc.cd_vaga_curso,
        c.cd_curso,
        c.descricao
      FROM vaga_curso vc
      JOIN curso c ON c.cd_curso = vc.cd_curso
      WHERE vc.cd_vaga = $1
      ORDER BY c.descricao
    `;
    const cursosResult = await pool.query(cursosQuery, [id]);
    vaga.cursosids = cursosResult.rows;

    res.status(200).json(vaga);

  } catch (err) {
    logger.error('Erro ao buscar vaga por ID: ' + err.stack, 'Vaga');
    res.status(500).json({ erro: 'Erro ao buscar vaga por ID.' });
  }
});




//
// GET - Listar vagas por empresa (com paginação)
//
router.get('/listarPorEmpresa/:cd_empresa', verificarToken, async (req, res) => {
  const { cd_empresa } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const valores = [cd_empresa];

  const baseQuery = `
    SELECT 
      vaga.*,
      vaga.exibir_empresa,       -- ✅ novo
      vaga.exibir_salario,       -- ✅ novo
      vaga.exibir_beneficios,    -- ✅ novo
      cidade.nome AS nome_cidade,
      cidade.uf AS uf_cidade,
      supervisor.nome AS nome_supervisor
    FROM public.vaga
    LEFT JOIN cidade ON cidade.cd_cidade = vaga.cd_cidade
    LEFT JOIN supervisor ON supervisor.cd_supervisor = vaga.cd_supervisor
    WHERE vaga.cd_empresa = $1
    ORDER BY vaga.data_criacao DESC
  `;

  const countQuery = `
    SELECT COUNT(*) 
    FROM public.vaga
    WHERE cd_empresa = $1
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);
    res.status(200).json(resultado);
  } catch (err) {
    logger.error('Erro ao listar vagas por empresa: ' + err.stack, 'Vaga');
    res.status(500).json({ erro: 'Erro ao listar vagas por empresa.' });
  }
});


 
// POST - Cadastrar vaga (inclui nome_processo_seletivo e disponivel_web)
//
router.post('/cadastrar', verificarToken, async (req, res) => {
  const {
    status,
    observacao,
    id_regime_contratacao,
    cd_cidade,
    cd_turno,
    setor,
    cd_supervisor,
    atividades,
    sexo,
    semestre_inicio,
    ano_inicio,
    semestre_fim,
    ano_fim,
    horario_turno1_inicio,
    horario_turno1_fim,
    horario_turno2_inicio,
    horario_turno2_fim,
    data_entrevista,
    contato_entrevista,
    endereco_entrevista,
    telefone_entrevista,
    data_inicio_contrato,
    data_fim_contrato,
    valor_bolsa,
    carga_horaria,
    transporte,
    cesta_basica,
    duracao_meses,
    observacao_contrato,
    cd_empresa,
    cd_nivel_formacao,

    // 🆕 campos booleanos novos
    disponivel_web = true,
    exibir_empresa = true,
    exibir_salario = true,
    exibir_beneficios = true,

    pcd = false,

    cursosids = [],
    nome_processo_seletivo
  } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  // 🛑 Validação obrigatória
  if (!status || !id_regime_contratacao || !cd_empresa || !nome_processo_seletivo) {
    return res.status(400).json({
      erro:
        'Campos obrigatórios não preenchidos: status, regime de contratação, empresa e nome_processo_seletivo.'
    });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 🔎 Validações referenciais
    const verificacoes = [
      { campo: 'empresa', tabela: 'empresa', coluna: 'cd_empresa', valor: cd_empresa },
      { campo: 'regime de contratação', tabela: 'regime_contratacao', coluna: 'id_regime_contratacao', valor: id_regime_contratacao },
      { campo: 'turno', tabela: 'turno', coluna: 'cd_turno', valor: cd_turno },
      { campo: 'cidade', tabela: 'cidade', coluna: 'cd_cidade', valor: cd_cidade },
      { campo: 'supervisor', tabela: 'supervisor', coluna: 'cd_supervisor', valor: cd_supervisor },
      { campo: 'nível de formação', tabela: 'nivel_formacao', coluna: 'cd_nivel_formacao', valor: cd_nivel_formacao }
    ];

    for (const { campo, tabela, coluna, valor } of verificacoes) {
      if (valor !== undefined && valor !== null) {
        const check = await client.query(
          `SELECT 1 FROM public.${tabela} WHERE ${coluna} = $1`,
          [valor]
        );
        if (check.rowCount === 0) {
          throw new Error(`O(a) ${campo} informado(a) não existe.`);
        }
      }
    }

    // 📌 Inserção principal
    const insertQuery = `
      INSERT INTO public.vaga (
        status, observacao, id_regime_contratacao, cd_cidade, cd_turno, setor,
        cd_supervisor, atividades, sexo, semestre_inicio, ano_inicio, semestre_fim,
        ano_fim, horario_turno1_inicio, horario_turno1_fim, horario_turno2_inicio,
        horario_turno2_fim, data_entrevista, contato_entrevista, endereco_entrevista,
        telefone_entrevista, data_inicio_contrato, data_fim_contrato, valor_bolsa,
        carga_horaria, transporte, cesta_basica, duracao_meses, observacao_contrato,
        cd_empresa, cd_nivel_formacao, disponivel_web,
        exibir_empresa, exibir_salario, exibir_beneficios,
        pcd,
        data_criacao, criado_por, nome_processo_seletivo
      )
      VALUES (
        $1, $2, $3, $4, $5, $6,
        $7, $8, $9, $10, $11, $12,
        $13, $14, $15, $16,
        $17, $18, $19, $20,
        $21, $22, $23, $24,
        $25, $26, $27, $28, $29,
       $30, $31, $32,
        $33, $34, $35,
        $36,
        $37, $38, $39
      )
      RETURNING cd_vaga;
    `;

    const result = await client.query(insertQuery, [
      status, observacao, id_regime_contratacao, cd_cidade, cd_turno, setor,
      cd_supervisor, atividades, sexo, semestre_inicio, ano_inicio, semestre_fim,
      semestre_fim, horario_turno1_inicio, horario_turno1_fim, horario_turno2_inicio,
      horario_turno2_fim, data_entrevista, contato_entrevista, endereco_entrevista,
      telefone_entrevista, data_inicio_contrato, data_fim_contrato, valor_bolsa,
      carga_horaria, transporte, cesta_basica, duracao_meses, observacao_contrato,
      cd_empresa, cd_nivel_formacao, Boolean(disponivel_web),
      Boolean(exibir_empresa), Boolean(exibir_salario), Boolean(exibir_beneficios),
      Boolean(pcd),
      dataAtual, userId, nome_processo_seletivo
    ]);

    const cd_vaga = result.rows[0].cd_vaga;

    // 📌 Inserção dos cursos vinculados
    for (const cd_curso of cursosids) {
      const cursoCheck = await client.query(`SELECT 1 FROM curso WHERE cd_curso = $1`, [cd_curso]);
      if (cursoCheck.rowCount === 0) {
        throw new Error(`Curso com código ${cd_curso} não encontrado.`);
      }

      await client.query(
        `INSERT INTO vaga_curso (cd_vaga, cd_curso) VALUES ($1, $2)`,
        [cd_vaga, cd_curso]
      );
    }

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Vaga cadastrada com sucesso!',
      cd_vaga
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao cadastrar vaga: ' + err.stack, 'Vaga');
    res.status(500).json({ erro: err.message || 'Erro ao cadastrar vaga.' });
  } finally {
    client.release();
  }
});



// PUT - Alterar vaga (inclui nome_processo_seletivo como obrigatório)
//
router.put('/alterar/:cd_vaga', verificarToken, async (req, res) => {
  const { cd_vaga } = req.params;
  const { cursosids = [], ...campos } = req.body;

  logger.info(`[PUT /vaga/alterar] cd_vaga recebido: ${cd_vaga}`);
  logger.info(`[PUT /vaga/alterar] cursosids recebido: ${JSON.stringify(cursosids)}`);
  logger.info(`[PUT /vaga/alterar] campos recebidos: ${JSON.stringify(campos)}`);

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  if (!cd_vaga) {
    return res.status(400).json({ erro: 'O código da vaga (cd_vaga) é obrigatório na URL.' });
  }

  // 🔹 Normalização dos novos booleanos
  const truthy = ['1','true','t','yes','sim'];
  function normalizarBool(v) {
    if (v === undefined || v === null) return v;
    return truthy.includes(String(v).toLowerCase());
  }

  campos.exibir_empresa = normalizarBool(campos.exibir_empresa);
  campos.exibir_salario = normalizarBool(campos.exibir_salario);
  campos.exibir_beneficios = normalizarBool(campos.exibir_beneficios);
  campos.pcd = normalizarBool(campos.pcd);

  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    logger.info(`[PUT /vaga/alterar] Transação iniciada`);

    // 🔎 Verifica se a vaga existe
    const busca = await client.query('SELECT * FROM public.vaga WHERE cd_vaga = $1', [cd_vaga]);
    if (busca.rowCount === 0) {
      throw new Error('Vaga não encontrada.');
    }

    // 🔎 Obter colunas reais da tabela
    const colunasVagaResult = await client.query(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'vaga'
    `);
    const colunasVaga = colunasVagaResult.rows.map(r => r.column_name);

    const atualizaveis = Object.keys(campos);
    const camposInvalidos = atualizaveis.filter(c => !colunasVaga.includes(c));

    if (camposInvalidos.length > 0) {
      logger.warn(`[PUT /vaga/alterar] Ignorando campos inválidos: ${camposInvalidos.join(', ')}`);
    }

    const camposValidos = atualizaveis.filter(c =>
      colunasVaga.includes(c) && c !== 'cd_vaga'
    );

    // 🔎 Validações referenciais
    const validacoes = [
      { campo: 'id_regime_contratacao', tabela: 'regime_contratacao', coluna: 'id_regime_contratacao' },
      { campo: 'cd_cidade', tabela: 'cidade', coluna: 'cd_cidade' },
      { campo: 'cd_turno', tabela: 'turno', coluna: 'cd_turno' },
      { campo: 'cd_empresa', tabela: 'empresa', coluna: 'cd_empresa' },
      { campo: 'cd_supervisor', tabela: 'supervisor', coluna: 'cd_supervisor' },
      { campo: 'cd_nivel_formacao', tabela: 'nivel_formacao', coluna: 'cd_nivel_formacao' }
    ];

    for (const { campo, tabela, coluna } of validacoes) {
      if (campos[campo] !== undefined && campos[campo] !== null) {
        const check = await client.query(
          `SELECT 1 FROM public.${tabela} WHERE ${coluna} = $1`,
          [campos[campo]]
        );
        if (check.rowCount === 0) {
          throw new Error(`O valor de ${campo} informado não existe.`);
        }
      }
    }

    // 🔎 Validação obrigatória
    if (
      campos.nome_processo_seletivo !== undefined &&
      (!campos.nome_processo_seletivo || !campos.nome_processo_seletivo.trim())
    ) {
      throw new Error('O campo nome_processo_seletivo é obrigatório e não pode estar vazio.');
    }

    // 🔧 Construção do UPDATE
    const setParts = [];
    const valores = [];

    camposValidos.forEach((campo) => {
      setParts.push(`${campo} = $${valores.length + 1}`);
      valores.push(campos[campo]);
    });

    setParts.push(`alterado_por = $${valores.length + 1}`);
    valores.push(userId);

    setParts.push(`data_alteracao = $${valores.length + 1}`);
    valores.push(dataAtual);

    valores.push(cd_vaga);

    const updateQuery = `
      UPDATE public.vaga
      SET ${setParts.join(', ')}
      WHERE cd_vaga = $${valores.length}
      RETURNING cd_vaga;
    `;

    logger.info(`[PUT /vaga/alterar] UPDATE: ${updateQuery}`);
    logger.info(`[PUT /vaga/alterar] VALUES: ${JSON.stringify(valores)}`);

    const result = await client.query(updateQuery, valores);

    // 🔧 Atualizar cursos
    await client.query(`DELETE FROM vaga_curso WHERE cd_vaga = $1`, [cd_vaga]);

    for (const cd_curso of cursosids) {
      const cursoCheck = await client.query(`SELECT 1 FROM curso WHERE cd_curso = $1`, [cd_curso]);
      if (cursoCheck.rowCount === 0) {
        throw new Error(`Curso ${cd_curso} não encontrado.`);
      }

      await client.query(
        `INSERT INTO vaga_curso (cd_vaga, cd_curso) VALUES ($1, $2)`,
        [cd_vaga, cd_curso]
      );
    }

    await client.query('COMMIT');

    res.status(200).json({
      message: 'Vaga atualizada com sucesso!',
      cd_vaga: result.rows[0].cd_vaga
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error(`[PUT /vaga/alterar] ERRO: ${err.stack}`);
    res.status(500).json({ erro: err.message });
  } finally {
    client.release();
    logger.info(`[PUT /vaga/alterar] Conexão liberada para vaga ${cd_vaga}`);
  }
});


router.post('/:cd_vaga/curso/cadastrar', verificarToken, async (req, res) => {
  const { cd_vaga } = req.params;
  const { cd_curso } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  // 🔹 Validação inicial
  if (!cd_vaga || !cd_curso) {
    return res.status(400).json({ erro: 'Informe o código da vaga e o código do curso.' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 🔹 Verifica se a vaga existe
    const vaga = await client.query(
      'SELECT cd_vaga FROM vaga WHERE cd_vaga = $1',
      [cd_vaga]
    );
    if (vaga.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Vaga não encontrada.' });
    }

    // 🔹 Verifica se o curso existe
    const curso = await client.query(
      'SELECT cd_curso FROM curso WHERE cd_curso = $1',
      [cd_curso]
    );
    if (curso.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Curso não encontrado.' });
    }

    // 🔹 Impede duplicidade
    const existe = await client.query(
      'SELECT 1 FROM vaga_curso WHERE cd_vaga = $1 AND cd_curso = $2',
      [cd_vaga, cd_curso]
    );
    if (existe.rowCount > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ erro: 'Este curso já está vinculado a esta vaga.' });
    }

    // 🔹 Inserção com auditoria
    const insertQuery = `
      INSERT INTO vaga_curso (
        cd_vaga, cd_curso, data_criacao, criado_por
      ) VALUES ($1, $2, $3, $4)
      RETURNING cd_vaga_curso;
    `;

    const insert = await client.query(insertQuery, [
      cd_vaga,
      cd_curso,
      dataAtual,
      userId
    ]);

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Curso vinculado com sucesso!',
      cd_vaga_curso: insert.rows[0].cd_vaga_curso
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao vincular curso à vaga: ' + err.stack, 'VagaCurso');
    res.status(500).json({
      erro: err.message || 'Erro ao vincular curso à vaga.'
    });
  } finally {
    client.release();
  }
});



//
// PUT - Alterar vínculo de curso
//
//
// PUT - Alterar vínculo de curso da vaga (com auditoria e transação)
//
router.put('/curso/alterar/:cd_vaga_curso', verificarToken, async (req, res) => {
  const { cd_vaga_curso } = req.params;
  const { cd_curso } = req.body;

  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  // 🔹 Validação inicial
  if (!cd_vaga_curso || !cd_curso) {
    return res.status(400).json({
      erro: 'Informe o ID do vínculo (cd_vaga_curso) e o novo código do curso (cd_curso).'
    });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 🔹 Verifica se o vínculo existe
    const vinculo = await client.query(
      'SELECT cd_vaga FROM vaga_curso WHERE cd_vaga_curso = $1',
      [cd_vaga_curso]
    );

    if (vinculo.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Vínculo não encontrado.' });
    }

    const cd_vaga = vinculo.rows[0].cd_vaga;

    // 🔹 Verifica se o novo curso existe
    const curso = await client.query(
      'SELECT cd_curso FROM curso WHERE cd_curso = $1',
      [cd_curso]
    );

    if (curso.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Curso informado não existe.' });
    }

    // 🔹 Impede duplicidade do mesmo curso para a vaga
    const duplicado = await client.query(
      `SELECT 1 
       FROM vaga_curso 
       WHERE cd_vaga = $1 
         AND cd_curso = $2 
         AND cd_vaga_curso <> $3`,
      [cd_vaga, cd_curso, cd_vaga_curso]
    );

    if (duplicado.rowCount > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        erro: 'Este curso já está vinculado a esta vaga.'
      });
    }

    // 🔹 Atualiza o vínculo com auditoria
    const updateQuery = `
      UPDATE vaga_curso
      SET cd_curso = $1,
          alterado_por = $2,
          data_alteracao = $3
      WHERE cd_vaga_curso = $4
      RETURNING cd_vaga_curso;
    `;

    const result = await client.query(updateQuery, [
      cd_curso,
      userId,
      dataAtual,
      cd_vaga_curso
    ]);

    await client.query('COMMIT');

    res.status(200).json({
      message: 'Vínculo de curso atualizado com sucesso!',
      cd_vaga_curso: result.rows[0].cd_vaga_curso,
      novo_cd_curso: cd_curso
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao alterar curso da vaga: ' + err.stack, 'VagaCurso');
    res.status(500).json({
      erro: err.message || 'Erro ao alterar curso da vaga.'
    });
  } finally {
    client.release();
  }
});



 
router.get('/:cd_vaga/curso/listar', verificarToken, async (req, res) => {
  const { cd_vaga } = req.params;

  try {
    // 🔹 Validação inicial
    if (!cd_vaga) {
      return res.status(400).json({ erro: 'Informe o código da vaga (cd_vaga).' });
    }

    // 🔹 Verificar se a vaga existe
    const vaga = await pool.query(
      'SELECT 1 FROM vaga WHERE cd_vaga = $1',
      [cd_vaga]
    );

    if (vaga.rowCount === 0) {
      return res.status(404).json({ erro: 'Vaga não encontrada.' });
    }

    // 🔹 Buscar cursos vinculados
    const sql = `
      SELECT 
        c.cd_curso,
        c.descricao AS nome,
        c.descricao AS descricao
      FROM vaga_curso vc
      JOIN curso c ON c.cd_curso = vc.cd_curso
      WHERE vc.cd_vaga = $1
      ORDER BY c.descricao;
    `;

    const result = await pool.query(sql, [cd_vaga]);

    // 🔹 Retorno final padronizado
    return res.status(200).json({
      cd_vaga: Number(cd_vaga),
      total: result.rowCount,
      cursos: result.rows
    });

  } catch (err) {
    logger.error('Erro ao listar cursos da vaga: ' + err.stack, 'VagaCurso');
    return res.status(500).json({
      erro: 'Erro ao listar cursos da vaga.',
      motivo: err.message
    });
  }
});



 
router.delete('/curso/:cd_vaga_curso', verificarToken, async (req, res) => {
  const { cd_vaga_curso } = req.params;
  const userId = req.usuario.cd_usuario;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  // 🔹 Validação inicial
  if (!cd_vaga_curso) {
    return res.status(400).json({ erro: 'Informe o identificador do vínculo (cd_vaga_curso).' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 🔹 Verifica se o vínculo existe
    const check = await client.query(
      'SELECT cd_vaga, cd_curso FROM vaga_curso WHERE cd_vaga_curso = $1',
      [cd_vaga_curso]
    );
    if (check.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ erro: 'Vínculo não encontrado.' });
    }

    const { cd_vaga, cd_curso } = check.rows[0];

    // 🔹 Se sua tabela vaga_curso tiver colunas de auditoria, use UPDATE lógico (soft delete)
    const possuiColunasAuditoria = true; // troque para false se for DELETE físico

    if (possuiColunasAuditoria) {
      await client.query(
        `
        UPDATE vaga_curso
        SET ativo = false,
            excluido_por = $1,
            data_exclusao = $2
        WHERE cd_vaga_curso = $3
        `,
        [userId, dataAtual, cd_vaga_curso]
      );
    } else {
      // 🔹 Remoção física (DELETE direto)
      await client.query('DELETE FROM vaga_curso WHERE cd_vaga_curso = $1', [cd_vaga_curso]);
    }

    await client.query('COMMIT');

    res.status(200).json({
      message: 'Curso desvinculado da vaga com sucesso!',
      cd_vaga_curso,
      cd_vaga,
      cd_curso
    });

  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Erro ao excluir vínculo de curso da vaga: ' + err.stack, 'VagaCurso');
    res.status(500).json({
      erro: err.message || 'Erro ao excluir vínculo de curso da vaga.'
    });
  } finally {
    client.release();
  }
});


 
router.get('/listarDisponiveis', async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const { q, idregime } = req.query;

  const filtros = ['vaga.disponivel_web = true'];
  // status diferente de "Cancelada""Aberta pela Empresa" 
  filtros.push(`vaga.status != 'Cancelada' AND vaga.status != 'Aberta pela Empresa'`);
  const valores = [];


   if (idregime) {
      valores.push(idregime);
      filtros.push(`vaga.id_regime_contratacao = $${valores.length}`);
    }

  // 🔹 Filtro de texto livre
  if (q) {
    valores.push(`%${q}%`); // $1
    const idx1 = valores.length;

    valores.push(`%${q}%`); // $2
    const idx2 = valores.length;

    filtros.push(`
      (
        unaccent(LOWER(vaga.observacao)) ILIKE unaccent(LOWER($${idx1})) OR
        unaccent(LOWER(vaga.nome_processo_seletivo)) ILIKE unaccent(LOWER($${idx1})) OR
        CAST(vaga.cd_vaga AS TEXT) ILIKE $${idx1} OR
        EXISTS (
          SELECT 1
          FROM vaga_curso vc
          JOIN curso c ON c.cd_curso = vc.cd_curso
          WHERE vc.cd_vaga = vaga.cd_vaga
            AND unaccent(LOWER(c.descricao)) ILIKE unaccent(LOWER($${idx2}))
        )
      )
    `);
  }

  const where = filtros.length ? `WHERE ${filtros.join(' AND ')}` : '';

  // 🔹 Query principal
  const baseQuery = `
    SELECT
      vaga.cd_vaga,
      vaga.status,
      vaga.observacao,
      vaga.nome_processo_seletivo,
      vaga.valor_bolsa,
      vaga.carga_horaria,
      vaga.transporte,
      vaga.cesta_basica,
      vaga.duracao_meses,
      vaga.disponivel_web,

      -- 🆕 CAMPOS NOVOS
      vaga.exibir_empresa,
      vaga.exibir_salario,
      vaga.exibir_beneficios,

      vaga.cd_empresa,
      cidade.nome         AS nome_cidade,
      cidade.uf           AS uf_cidade,
      supervisor.nome     AS nome_supervisor,
      empresa.razao_social,
      empresa.nome_fantasia,
      empresa.cnpj,
      empresa.email,
      empresa.telefone,
      id_regime_contratacao,

      vaga.pcd,

      COALESCE(
        ARRAY_AGG(
          DISTINCT jsonb_build_object(
            'cd_curso', c.cd_curso,
            'nome',     c.descricao
          )
        ) FILTER (WHERE c.cd_curso IS NOT NULL),
        '{}'::jsonb[]
      ) AS cursos , atividades
    FROM public.vaga
    LEFT JOIN cidade         ON cidade.cd_cidade       = vaga.cd_cidade
    LEFT JOIN supervisor     ON supervisor.cd_supervisor = vaga.cd_supervisor
    LEFT JOIN empresa        ON empresa.cd_empresa     = vaga.cd_empresa
    LEFT JOIN vaga_curso vc  ON vc.cd_vaga             = vaga.cd_vaga
    LEFT JOIN curso c        ON c.cd_curso             = vc.cd_curso
    ${where}
    GROUP BY
      vaga.cd_vaga,
      vaga.status,
      vaga.observacao,
      vaga.nome_processo_seletivo,
      vaga.valor_bolsa,
      vaga.carga_horaria,
      vaga.transporte,
      vaga.cesta_basica,
      vaga.duracao_meses,
      vaga.disponivel_web,
      vaga.exibir_empresa,
      vaga.exibir_salario,
      vaga.exibir_beneficios,
      vaga.cd_empresa,
      cidade.nome,
      supervisor.nome,
      empresa.razao_social,
      empresa.nome_fantasia,
      empresa.cnpj,
      empresa.email,
      empresa.telefone,
      cidade.uf,
      id_regime_contratacao
    ORDER BY vaga.data_criacao DESC
  `;

  const countQuery = `
    SELECT COUNT(DISTINCT vaga.cd_vaga) AS total
    FROM public.vaga
    ${where}
  `;

  try {
    const resultado = await paginarConsulta(pool, baseQuery, countQuery, valores, page, limit);

    const countResult = await pool.query(countQuery, valores);
    const totalItems = parseInt(countResult.rows[0]?.total || 0, 10);
    const totalPages = limit > 0 ? Math.ceil(totalItems / limit) : 1;

    // 🔹 Mapeamento
    const dados = resultado.dados.map(v => ({
      cd_vaga: v.cd_vaga,
      status: v.status,
      observacao: v.observacao,
      nome_processo_seletivo: v.nome_processo_seletivo,
      valor_bolsa: v.valor_bolsa,
      carga_horaria: v.carga_horaria,
      transporte: v.transporte,
      cesta_basica: v.cesta_basica,
      duracao_meses: v.duracao_meses,
      disponivel_web: v.disponivel_web,

      // 🆕 CAMPOS NOVOS NO RETORNO
      exibir_empresa: v.exibir_empresa,
      exibir_salario: v.exibir_salario,
      exibir_beneficios: v.exibir_beneficios,

      atividades: v.atividades,
      nome_cidade: v.nome_cidade,
      uf_cidade: v.uf_cidade,
      id_regime_contratacao: v.id_regime_contratacao,
      nome_supervisor: v.nome_supervisor,

      empresa: {
        cd_empresa: v.cd_empresa,
        razao_social: v.razao_social,
        nome_fantasia: v.nome_fantasia,
        cnpj: v.cnpj,
        email: v.email,
        telefone: v.telefone
      },

      cursos: (v.cursos || []).map(j => ({
        cd_curso: j.cd_curso,
        nome: j.nome
      }))
    }));

    res.status(200).json({
      dados,
      pagination: {
        page,
        limit,
        totalItems,
        totalPages
      }
    });

  } catch (err) {
    logger.error('Erro ao listar vagas disponíveis na web: ' + err.stack, 'Vaga');
    res.status(500).json({
      erro: 'Erro ao listar vagas disponíveis na web.',
      motivo: err.message
    });
  }
});


// POST /vaga/:cd_vaga/candidatura
router.post('/:cd_vaga/candidatura', verificarToken, async (req, res) => {
  const client = await pool.connect();
  try {
    const { cd_vaga } = req.params;
    const { cd_candidato, mensagem, dataCandidatura } = req.body;

    if (!cd_vaga) {
      return res.status(400).json({ message: "Parâmetro cd_vaga é obrigatório" });
    }

    if (!cd_candidato) {
      return res.status(400).json({ message: "Campo cd_candidato é obrigatório" });
    }

    await client.query('BEGIN');

    // 🔎 Verifica se a vaga existe e está ativa
    const vagaCheck = await client.query(
      `SELECT cd_vaga, status, disponivel_web 
       FROM vaga 
       WHERE cd_vaga = $1`,
      [cd_vaga]
    );

    if (vagaCheck.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: "Vaga não encontrada" });
    }

    if (!vagaCheck.rows[0].disponivel_web) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: "Vaga não está disponível para candidatura" });
    }

    // 🔎 Verifica candidatura duplicada
    const existe = await client.query(
      `SELECT 1 
       FROM candidatura_vaga 
       WHERE cd_vaga = $1 AND cd_candidato = $2`,
      [cd_vaga, cd_candidato]
    );

    if (existe.rowCount > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ message: "Você já se candidatou para esta vaga" });
    }

    // 📝 Insere candidatura
    const insert = await client.query(
      `INSERT INTO candidatura_vaga 
        (cd_vaga, cd_candidato, mensagem, data_candidatura)
       VALUES ($1, $2, $3, $4)
       RETURNING id, cd_vaga, cd_candidato, data_candidatura`,
      [
        cd_vaga,
        cd_candidato,
        mensagem || null,
        dataCandidatura || new Date()
      ]
    );

    await client.query('COMMIT');

    return res.status(201).json({
      message: "Candidatura enviada com sucesso",
      candidatura: insert.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erro ao registrar candidatura:', error);
    return res.status(500).json({ message: 'Erro interno ao registrar candidatura' });
  } finally {
    client.release();
  }
});


// GET /vaga/:cd_vaga/candidaturas
router.get('/:cd_vaga/candidaturas', verificarToken, async (req, res) => {
  const client = await pool.connect();
  try {
    const { cd_vaga } = req.params;

    if (!cd_vaga) {
      return res.status(400).json({ message: "Parâmetro cd_vaga é obrigatório" });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const { q, cpf, status } = req.query;

    const filtros = ["cv.cd_vaga = $1"];
    const valores = [cd_vaga];

    // 🔍 Filtro por nome do candidato
    if (q) {
      valores.push(`%${q.toLowerCase()}%`);
      filtros.push(`unaccent(LOWER(c.nome_completo)) LIKE unaccent(LOWER($${valores.length}))`);
    }

    // 🔍 Filtro por CPF
    if (cpf) {
      const cpfLimpo = cpf.replace(/[^\d]/g, '');
      valores.push(cpfLimpo);
      filtros.push(`REPLACE(REPLACE(REPLACE(c.cpf, '.', ''), '-', ''), '/', '') = $${valores.length}`);
    }

    // 🔍 Filtro por status
    if (status) {
      valores.push(status);
      filtros.push(`c.status = $${valores.length}`);
    }

    const where = `WHERE ${filtros.join(' AND ')}`;

    // ============================
    // 🔹 Consulta principal
    // ============================
    const sql = `
           SELECT distinct cv.mensagem, cv.data_candidatura, 
        c.cd_candidato,
  c.cpf,
  c.rg,
  c.org_emissor,
  c.uf_rg,
  c.pais_origem,
  c.estado,
  c.nome_completo,
  c.nome_social,
  c.data_nascimento,
  c.nacionalidade,
  c.estrangeiro,
  c.sexo,
  c.raca,
  c.genero,
  c.estado_civil,
  c.telefone,
  c.celular,
  c.email,
  c.pcd,
  c.observacao,
  c.id_regime_contratacao,
  c.criado_por,
  c.data_criacao,
  c.atualizado_por,
  c.data_atualizacao,
  c.aceite_lgpd,
  c.data_aceite_lgpd,
  c.cd_nivel_formacao,
  c.cd_curso,
  c.cd_instituicao_ensino,
  c.cd_status_curso,
  c.semestre_ano,
  c.cd_turno,
  c.cd_modalidade_ensino,
  c.ra_matricula,
  c.ds_curso,
  c.ds_instituicao,
  c.ativo,
  c.cd_banco,
  c.agencia,
  c.conta,
  c.tipo_conta,
  c.possui_carteira_fisica,
  c.nome_responsavel,
  c.numero_carteira_trabalho,
  c.numero_serie_carteira_trabalho,
  c.pis,
  c.qtd_membros_domicilio,
  c.renda_domiciliar_mensal,
  c.recebe_auxilio_governo,
  c.qual_auxilio_governo,
  c.tipo_curso,
  c.data_inicio_curso,
  c.ds_curso_legado,
  c.cd_sistema_legado,
  c.migradao,
  c.migracao,
  c.origem,
  c.cpf_clean,
  c.comprovante_path,
      c.cd_candidato AS id,
      rc.descricao AS nome_regime_contratacao,
      nf.descricao AS nivel_formacao,
      cur.descricao AS curso,
      ie.razao_social AS instituicao_ensino,
      sc.descricao AS status_curso,
      t.descricao AS turno,
      m.descricao AS modalidade_ensino,
      e.cidade AS cidade,
      e.uf AS uf,
      numero_carteira_trabalho,
      numero_serie_carteira_trabalho,
      pis,
      qtd_membros_domicilio,
      renda_domiciliar_mensal,
      recebe_auxilio_governo,
      qual_auxilio_governo,
      comprovante_path, 
      comprovante_path AS comprovante_url
    FROM candidatura_vaga cv 
    inner join  public.candidato c   ON c.cd_candidato = cv.cd_candidato
    INNER JOIN public.regime_contratacao rc 
      ON rc.id_regime_contratacao = c.id_regime_contratacao
    LEFT JOIN public.nivel_formacao nf 
      ON nf.cd_nivel_formacao = c.cd_nivel_formacao
    LEFT JOIN public.curso cur 
      ON cur.cd_curso = c.cd_curso
    LEFT JOIN public.instituicao_ensino ie 
      ON ie.cd_instituicao_ensino = c.cd_instituicao_ensino
    LEFT JOIN public.status_curso sc 
      ON sc.cd_status = c.cd_status_curso
    LEFT JOIN public.turno t 
      ON t.cd_turno = c.cd_turno
    LEFT JOIN public.modalidade_ensino m 
      ON m.cd_modalidade_ensino = c.cd_modalidade_ensino
    LEFT JOIN public.endereco e 
      ON e.cd_candidato = c.cd_candidato
     
      ${where}
      ORDER BY cv.data_candidatura DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await client.query(sql, valores);

    // ============================
    // 🔹 Total para paginação
    // ============================
    const countSql = `
      SELECT COUNT(*) AS total
      FROM candidatura_vaga cv
      JOIN candidato c ON c.cd_candidato = cv.cd_candidato
      ${where}
    `;

    const totalResult = await client.query(countSql, valores);
    const totalItems = parseInt(totalResult.rows[0].total, 10);
    const totalPages = Math.ceil(totalItems / limit);

    return res.status(200).json({
      dados: result.rows,
      pagination: {
        currentPage: page,
        totalPages,
        totalItems,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1,
      }
    });

  } catch (error) {
    console.error('Erro ao listar candidaturas:', error);
    return res.status(500).json({ message: "Erro interno ao listar candidaturas", motivo  : error.message });
  } finally {
    client.release();
  }
});


// GET /candidaturas/:cd_candidato
router.get('/candidaturas/:cd_candidato', verificarToken, async (req, res) => {
  const client = await pool.connect();

  try {
    const { cd_candidato } = req.params;

    if (!cd_candidato) {
      return res.status(400).json({ message: "cd_candidato é obrigatório" });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    const { status } = req.query;

    const filtros = ["cv.cd_candidato = $1"];
    const valores = [cd_candidato];

    // 🔍 Filtro por status
    if (status) {
      valores.push(status);
      filtros.push(`cv.status = $${valores.length}`);
    }

    const where = `WHERE ${filtros.join(' AND ')}`;

    // ================================
    // 🔹 Consulta principal
    // ================================
    const sql = `
      SELECT
        cv.id,
        cv.cd_vaga,
        cv.cd_candidato,
        cv.mensagem,
        to_char(cv.data_candidatura, 'DD/MM/YYYY HH24:MI') AS data_candidatura,

        -- dados da vaga
        v.nome_processo_seletivo,
        v.observacao,
        v.setor,
             v.id_regime_contratacao,
        v.disponivel_web, v.status  
      FROM candidatura_vaga cv
      JOIN vaga v ON v.cd_vaga = cv.cd_vaga
      ${where}
      ORDER BY cv.data_candidatura DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await client.query(sql, valores);

    // ================================
    // 🔹 Contagem para paginação
    // ================================
    const countSql = `
      SELECT COUNT(*) AS total
      FROM candidatura_vaga cv
      JOIN vaga v ON v.cd_vaga = cv.cd_vaga
      ${where}
    `;

    const totalResult = await client.query(countSql, valores);
    const totalItems = parseInt(totalResult.rows[0].total, 10);
    const totalPages = Math.ceil(totalItems / limit);

    return res.status(200).json({
      candidaturas: result.rows,
      pagination: {
        currentPage: page,
        totalPages,
        totalItems,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1,
      }
    });

  } catch (error) {
    console.error('Erro ao listar candidaturas do candidato:', error);
    return res.status(500).json({ message: "Erro interno ao listar candidaturas", motivo: error.message });
  } finally {
    client.release();
  }
});



module.exports = router;
