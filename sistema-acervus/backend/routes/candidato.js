const express = require('express');
const router = express.Router();
const app = express();
const pool = require('../db');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('../auth');
const logger = require('../utils/logger');
const { paginarConsulta, paginarConsultaComEndereco } = require('../helpers/paginador');
const { cadastrarEndereco , alterarEndereco} = require('./endereco');
const { cadastrarContato, alterarContato } = require('./contatos');
const md5 = require('md5');
const { createCsvExporter } = require('../factories/exportCsvFactory');
const PDFDocument = require('pdfkit');





const multer = require('multer');
const path = require('path');

const fs = require('fs');

app.use(express.json()); // Para application/json
app.use(express.urlencoded({ extended: true })); // Para application/x-www-form-urlencoded

 
const idiomaRoutes = require('./candidato_idioma');
const experienciaRoutes = require('./candidato_experiencia');
const conhecimentoRoutes = require('./candidato_conhecimento');


router.use('/idioma', idiomaRoutes);
router.use('/experiencia', experienciaRoutes);
router.use('/conhecimento', conhecimentoRoutes);

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Pasta onde os arquivos serão armazenados localmente
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/comprovantes/');
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'comprovante_' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage });


router.get('/listar/:id', tokenOpcional, listarStatus);
router.get('/buscar/:id', verificarToken, listarStatus);



// GET - Buscar candidatos com filtros combinados (nome, CPF, e-mail, tipo, ativo, cidade, curso)
router.get('/buscar', verificarToken, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;

  const { nome, cpf, email, tipo, ativo, cidade, curso } = req.query;

  const valores = [];
  const filtrosBusca = [];
  const filtrosAnd = [];
  let where = '';

  // 🔹 Filtro por nome ou código do candidato
  if (nome) {
    const nomeTrim = nome.trim();
    if (/^\d+$/.test(nomeTrim) && nomeTrim.length < 9) {
      valores.push(parseInt(nomeTrim, 10));
      filtrosBusca.push(`c.cd_candidato = $${valores.length}`);
    } else {
      valores.push(`%${nomeTrim}%`);
      filtrosBusca.push(`unaccent(LOWER(c.nome_completo)) ILIKE unaccent(LOWER($${valores.length}))`);
    }
  }

  // 🔹 Filtro por CPF
  if (cpf) {
    const cpfSemMascara = cpf.replace(/[./-]/g, '');
    valores.push(`%${cpfSemMascara}%`);
    filtrosBusca.push(`REPLACE(REPLACE(REPLACE(c.cpf, '.', ''), '-', ''), '/', '') ILIKE $${valores.length}`);
  }

  // 🔹 Filtro por e-mail
  if (email) {
    valores.push(`%${email.trim()}%`);
    filtrosBusca.push(`LOWER(c.email) ILIKE LOWER($${valores.length})`);
  }

  //imprimir ativo
  console.log('Ativo:', ativo);

  // 🔹 Filtro por ativo
  if (ativo != undefined) {
    const ativoBool = String(ativo).trim().toLowerCase() === 'true';
    valores.push(ativoBool);
    filtrosAnd.push(`c.ativo = $${valores.length}`);
  }

  // 🔹 Filtro por tipo (regime de contratação)
  if (tipo) {
    const tipoLower = tipo.toLowerCase();
    if (['estagio', 'estagiario', 'estudante', '2'].includes(tipoLower)) {
      filtrosAnd.push(`c.id_regime_contratacao = 2`);
    } else if (['aprendiz', '1'].includes(tipoLower)) {
      filtrosAnd.push(`c.id_regime_contratacao = 1`);
    }
  }

  // 🔹 Filtro por cidade (campo na tabela endereco)
  if (cidade) {
    valores.push(`%${cidade.trim()}%`);
    filtrosAnd.push(`unaccent(LOWER(e.cidade)) ILIKE unaccent(LOWER($${valores.length}))`);
  }

  // 🔹 Filtro por curso
  if (curso) {
    valores.push(`%${curso.trim()}%`);
    filtrosAnd.push(`unaccent(LOWER(cur.descricao)) ILIKE unaccent(LOWER($${valores.length}))`);
  }

  // 🔹 Montagem do WHERE
  const condicoes = [];
  if (filtrosBusca.length > 0) condicoes.push(`(${filtrosBusca.join(' OR ')})`);
  if (filtrosAnd.length > 0) condicoes.push(filtrosAnd.join(' AND '));
  if (condicoes.length > 0) where = `WHERE ${condicoes.join(' AND ')}`;

  const countQuery = `
    SELECT COUNT(*) 
    FROM public.candidato c
    LEFT JOIN public.curso cur ON cur.cd_curso = c.cd_curso
    LEFT JOIN public.endereco e ON e.cd_candidato = c.cd_candidato
    ${where}
  `;

  const baseQuery = `
    SELECT distinct 
      c.*, 
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
    FROM public.candidato c
    INNER JOIN public.regime_contratacao rc   ON rc.id_regime_contratacao = c.id_regime_contratacao
    LEFT JOIN public.nivel_formacao nf        ON nf.cd_nivel_formacao = c.cd_nivel_formacao
    LEFT JOIN public.curso cur                ON cur.cd_curso = c.cd_curso
    LEFT JOIN public.instituicao_ensino ie    ON ie.cd_instituicao_ensino = c.cd_instituicao_ensino
    LEFT JOIN public.status_curso sc          ON sc.cd_status = c.cd_status_curso
    LEFT JOIN public.turno t                  ON t.cd_turno = c.cd_turno
    LEFT JOIN public.modalidade_ensino m      ON m.cd_modalidade_ensino = c.cd_modalidade_ensino
    LEFT JOIN public.endereco e               ON e.cd_candidato = c.cd_candidato  AND e.principal = true
    ${where}
    ORDER BY c.nome_completo
  `;

  try {
    const resultado = await paginarConsultaComEndereco(pool, baseQuery, countQuery, valores, page, limit);
    res.json(resultado);
  } catch (err) {
    console.error('Erro ao buscar candidatos:', err);
    logger.error('Erro ao buscar candidatos: ' + err.stack, 'candidatos');
    res.status(500).json({ erro: 'Erro ao buscar candidatos.' });
  }
});

// Esta rota busca um candidato específico pelo ID e retorna seus dados completos, incluindo informações de formação

// =====================
// GET /buscar/:id (adicionar retorno dos novos campos)
// =====================
 // =====================
// GET /listar/:id ou /buscar/:id
// =====================
async function listarStatus(req, res) {
  const { id } = req.params;

  const query = `
       SELECT 
      c.*, 
      rc.descricao AS regime_contratacao,
      nf.descricao AS nivel_formacao,
      cur.descricao AS curso,
      ie.razao_social AS instituicao_ensino,
      sc.descricao AS status_curso,
      t.descricao AS turno,
      m.descricao AS modalidade_ensino,
      e.id_endereco,
      e.cep, e.logradouro, e.numero, e.bairro, e.cidade, e.complemento, e.uf,
      e.telefone AS telefone_endereco, e.codigo_ibge, e.principal AS endereco_principal,
      ct. cd_contatos, ct.nome AS contato_nome, ct.grau_parentesco, ct.telefone AS contato_telefone, 
      ct.celular AS contato_celular, ct.whatsapp, ct.principal AS contato_principal, comprovante_path, comprovante_path comprovante_url
    FROM public.candidato c
    LEFT JOIN public.regime_contratacao rc ON rc.id_regime_contratacao = c.id_regime_contratacao
    LEFT JOIN public.nivel_formacao nf ON nf.cd_nivel_formacao = c.cd_nivel_formacao
    LEFT JOIN public.curso cur ON cur.cd_curso = c.cd_curso
    LEFT JOIN public.instituicao_ensino ie ON ie.cd_instituicao_ensino = c.cd_instituicao_ensino
    LEFT JOIN public.status_curso sc ON sc.cd_status = c.cd_status_curso
    LEFT JOIN public.turno t ON t.cd_turno = c.cd_turno
    LEFT JOIN public.modalidade_ensino m ON m.cd_modalidade_ensino = c.cd_modalidade_ensino
    LEFT JOIN public.endereco e ON e.cd_candidato = c.cd_candidato   AND e.principal = true
    LEFT JOIN public.contatos ct ON ct.cd_candidato = c.cd_candidato   AND ct.principal = true
    WHERE c.cd_candidato = $1
    LIMIT 1;
  `;

  try {
    const result = await pool.query(query, [id]);
    if (result.rowCount === 0)
      return res.status(404).json({ erro: 'Candidato não encontrado.' });

    const c = result.rows[0];

    const response = {
      id: c.cd_candidato,
      nome_completo: c.nome_completo,
      nome_social: c.nome_social,
      data_nascimento: c.data_nascimento,
      pais_origem: c.pais_origem,
      nacionalidade: c.nacionalidade,
      email: c.email,
      cpf: c.cpf,
      rg: c.rg,
      org_emissor: c.org_emissor,
      uf_rg: c.uf_rg,
      cep: c.cep,
      logradouro: c.logradouro,
      numero: c.numero,
      bairro: c.bairro,
      cidade: c.cidade,
      uf: c.estado,
      complemento: c.complemento,
      celular: c.celular,
      telefone: c.telefone,
      resumo_profissional: c.resumo_profissional,
      sexo: c.sexo,
      genero: c.genero,
      estado_civil: c.estado_civil,
      estrangeiro: c.estrangeiro,
      cor: c.cor,
      raca: c.raca,
      tipo_cadastro_candidato: c.tipo_cadastro_candidato,
      nome_pai: c.nome_pai,
      nome_mae: c.nome_mae,
      pcd: c.pcd,
      tipo_pcd: c.tipo_pcd,
      nivel_pcd: c.nivel_pcd,
      data_criacao: c.data_criacao,
      data_atualizacao: c.data_atualizacao,
      id_regime_contratacao: c.id_regime_contratacao,
      ativo: c.ativo,
      observacao: c.observacao,
      ra_matricula: c.ra_matricula,
      comprovante_path: c.comprovante_path,
      comprovante_url: c.comprovante_path
        ? `${process.env.APP_URL || ''}/${c.comprovante_path}`
        : null,
      aceite_lgpd: c.aceite_lgpd,
      data_aceite_lgpd: c.data_aceite_lgpd,
      tipo_curso: c.tipo_curso,
      cd_banco: c.cd_banco,
      agencia: c.agencia,
      conta: c.conta,
      tipo_conta: c.tipo_conta,
      nome_responsavel: c.nome_responsavel,
      numero_carteira_trabalho: c.numero_carteira_trabalho,
      numero_serie_carteira_trabalho: c.numero_serie_carteira_trabalho,
      possui_carteira_fisica: c.possui_carteira_fisica,
      pis: c.pis,
      qtd_membros_domicilio: c.qtd_membros_domicilio,
      renda_domiciliar_mensal: c.renda_domiciliar_mensal,
      recebe_auxilio_governo: c.recebe_auxilio_governo,
      qual_auxilio_governo: c.qual_auxilio_governo,
 
       

      // 📚 Bloco de Formação Acadêmica
      formacao: {
        cd_nivel_formacao: c.cd_nivel_formacao,
        nivel: c.nivel_formacao,
        cd_curso: c.cd_curso,
        curso: c.curso,
        cd_instituicao_ensino: c.cd_instituicao_ensino,
        instituicao: c.instituicao_ensino,
        cd_status_curso: c.cd_status_curso,
        status_curso: c.status_curso,
        cd_turno: c.cd_turno,
        turno: c.turno,
        cd_modalidade_ensino: c.cd_modalidade_ensino,
        modalidade: c.modalidade_ensino,
        ra_matricula: c.ra_matricula,
        tipo_curso: c.tipo_curso,
        data_inicio_curso: c.data_inicio_curso,
        ds_curso: c.ds_curso,
        ds_instituicao: c.ds_instituicao,
        cd_instituicao_nao_listada: c.ds_instituicao,
        cd_curso_nao_listado: c.ds_curso,
        semestre_ano: c.semestre_ano
      },

      // 🏠 Bloco Endereço
      endereco: c.id_endereco
        ? {
            id_endereco: c.id_endereco,
            cep: c.cep,
            logradouro: c.logradouro,
            numero: c.numero,
            bairro: c.bairro,
            cidade: c.cidade,
            complemento: c.complemento,
            telefone: c.telefone_endereco,
            codigo_ibge: c.codigo_ibge,
            uf: c.uf,
            ativo: true,
            principal: c.endereco_principal
          }
        : null,

      // ☎️ Bloco Contato
      contato: c.id_contato
        ? {
            id_contato: c.id_contato,
            nome: c.contato_nome,
            grau_parentesco: c.grau_parentesco,
            telefone: c.contato_telefone,
            celular: c.contato_celular,
            whatsapp: c.whatsapp,
            principal: c.contato_principal
          }
        : null
    };

    res.status(200).json(response);
  } catch (err) {
    console.error('Erro ao listar candidato:', err);
    logger.error('Erro ao listar candidato: ' + err.stack, 'candidatos');
    res.status(500).json({ erro: 'Erro interno ao listar candidato.' });
  }
}

// Cadastrar candidato
router.post('/cadastrar', tokenOpcional, upload.single('comprovante'), async (req, res) => {
  const {
    cpf, rg, org_emissor, uf_rg, pais_origem, uf,
    nome_completo, nome_social, data_nascimento,
    nacionalidade, estrangeiro, sexo, raca, genero,
    estado_civil, telefone, celular, email, senha,
    pcd, observacao, id_regime_contratacao, aceite_lgpd, data_aceite_lgpd,
    endereco, contato,
    cd_banco, agencia, conta, tipo_conta,
    pis, qtd_membros_domicilio, renda_domiciliar_mensal, recebe_auxilio_governo, qual_auxilio_governo,
    tipo_curso, data_inicio_curso
  } = req.body;

  const {
    possui_carteira_fisica,
    nome_responsavel,
    numero_carteira_trabalho,
    numero_serie_carteira_trabalho
  } = req.body;

  let formacao = req.body.formacao;
  const comprovante = req.file?.path || null;

  // Formação obrigatória
  if (!formacao) {
    return res.status(400).json({ erro: 'Os dados de formação são obrigatórios.' });
  }

  // Se vier como string, converte
  if (typeof formacao === 'string') {
    try {
      formacao = JSON.parse(formacao);
    } catch {
      return res.status(400).json({ erro: 'Erro ao interpretar os dados da formação.' });
    }
  }

  // Verificar CPF duplicado
  if (cpf) {
    const cpfLimpo = cpf.replace(/[^\d]/g, '');
    if (!cpfLimpo) return res.status(400).json({ erro: 'CPF inválido.' });

    try {
      const consultaCpf = `
        SELECT cd_candidato
        FROM public.candidato
        WHERE REPLACE(REPLACE(REPLACE(cpf, '.', ''), '-', ''), '/', '') = $1
        LIMIT 1
      `;
      const resultadoCpf = await pool.query(consultaCpf, [cpfLimpo]);
      if (resultadoCpf.rowCount > 0) {
        return res.status(400).json({ erro: 'CPF já cadastrado.' });
      }
    } catch (err) {
      console.error('Erro ao verificar CPF duplicado:', err);
      return res.status(500).json({ erro: 'Erro ao verificar CPF.' });
    }
  }

  // Campos da formação
  const {
    cd_nivel_formacao,
    cd_curso,
    ds_curso,
    cd_instituicao_ensino,
    ds_instituicao,
    cd_status_curso,
    semestre_ano,
    cd_turno,
    cd_modalidade_ensino,
    ra_matricula
  } = formacao;

  const userId = req.usuario?.cd_usuario || null;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  // QUERY DE INSERÇÃO DO CANDIDATO
  const query = `
    INSERT INTO public.candidato (
      cpf, rg, org_emissor, uf_rg, pais_origem, estado,
      nome_completo, nome_social, data_nascimento,
      nacionalidade, estrangeiro, sexo, raca, genero,
      estado_civil, telefone, celular, email, senha,
      pcd, observacao, id_regime_contratacao,
      criado_por, data_criacao,
      cd_nivel_formacao, cd_curso, cd_instituicao_ensino, cd_status_curso,
      semestre_ano, cd_turno, cd_modalidade_ensino, ra_matricula,
      comprovante_path, ds_curso, ds_instituicao, aceite_lgpd, data_aceite_lgpd,
      cd_banco, agencia, conta, tipo_conta,
      possui_carteira_fisica, nome_responsavel, numero_carteira_trabalho, numero_serie_carteira_trabalho,
      pis, qtd_membros_domicilio, renda_domiciliar_mensal, recebe_auxilio_governo, qual_auxilio_governo,
      tipo_curso, data_inicio_curso
    ) VALUES (
      $1, $2, $3, $4, $5, $6,
      $7, $8, $9, $10, $11, $12, $13, $14,
      $15, $16, $17, $18, $19, $20, $21, $22,
      $23, $24, $25, $26, $27, $28, $29, $30,
      $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41,
      $42, $43, $44, $45,
      $46, $47, $48, $49, $50,
      $51, $52
    ) RETURNING cd_candidato;
  `;

  const values = [
    cpf, rg, org_emissor, uf_rg, pais_origem, uf,
    (nome_completo || '').toUpperCase(),
    (nome_social || '').toUpperCase(),
    data_nascimento,
    nacionalidade, estrangeiro, sexo, raca, genero,
    estado_civil, telefone, celular, email, md5(senha),
    pcd, observacao, id_regime_contratacao,
    userId, dataAtual,
    cd_nivel_formacao,
    cd_curso || null,
    cd_instituicao_ensino || null,
    cd_status_curso,
    semestre_ano,
    cd_turno,
    cd_modalidade_ensino,
    ra_matricula || null,
    comprovante,
    ds_curso || null,
    ds_instituicao || null,
    aceite_lgpd,
    data_aceite_lgpd,
    cd_banco || null,
    agencia || null,
    conta || null,
    tipo_conta || null,
    possui_carteira_fisica || null,
    nome_responsavel || null,
    numero_carteira_trabalho || null,
    numero_serie_carteira_trabalho || null,
    pis || null,
    qtd_membros_domicilio || null,
    renda_domiciliar_mensal || null,
    (recebe_auxilio_governo && recebe_auxilio_governo.toLowerCase() === 'sim'
      ? true
      : (recebe_auxilio_governo === 'não' || recebe_auxilio_governo?.toLowerCase() === 'nao'
        ? false
        : recebe_auxilio_governo)) || null,
    qual_auxilio_governo || null,
    tipo_curso || null,
    data_inicio_curso || null
  ];

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1️⃣ INSERIR CANDIDATO
    const result = await client.query(query, values);
    const cdCandidato = result.rows[0].cd_candidato;

    // 2️⃣ INSERIR ENDEREÇO (SE FALHAR → ROLLBACK)
    if (endereco && Object.keys(endereco).length > 0) {
      const okEndereco = await cadastrarEndereco(
        endereco,
        cdCandidato,
        userId,
        null,
        null,
        null,
        client
      );

      if (okEndereco === false) throw new Error('Falha ao cadastrar endereço.');
    }

    // 3️⃣ INSERIR CONTATO (SE FALHAR → ROLLBACK)
    if (contato && Object.keys(contato).length > 0) {
      const okContato = await cadastrarContato(
        contato,
        cdCandidato,
        userId,
        null,
        client
      );

      if (okContato === false) throw new Error('Falha ao cadastrar contato.');
    }

    // 4️⃣ TUDO OK → COMMIT
    await client.query('COMMIT');

    res.status(201).json({
      mensagem: 'Candidato cadastrado com sucesso!',
      cd_candidato: cdCandidato
    });

  } catch (err) {
    await client.query('ROLLBACK');

    console.error('Erro ao cadastrar candidato:', err);

    res.status(500).json({
      erro: 'Erro interno ao cadastrar candidato.',
      motivo: err.message
    });

  } finally {
    client.release();
  }
});


router.get('/exists/:cd_candidato', async (req, res) => {
  const { cd_candidato } = req.params;

  if (!cd_candidato) {
    return res.status(400).json({ erro: 'cd_candidato é obrigatório.' });
  }

  try {
    const query = `
      SELECT 1 
      FROM public.candidato 
      WHERE cd_candidato = $1
      LIMIT 1
    `;
    const result = await pool.query(query, [cd_candidato]);

    if (result.rowCount > 0) {
      return res.status(200).json({ existe: true });
    }

    return res.status(404).json({ existe: false });

  } catch (err) {
    console.error('Erro ao verificar candidato:', err);
    return res.status(500).json({ erro: 'Erro interno ao verificar candidato.' });
  }
});



// =====================
// PUT /alterar/:id
// =====================
router.put('/alterar/:id', verificarToken, upload.single('comprovante'), async (req, res) => {
  const { id } = req.params;
  const novoComprovante = req.file?.path || null;
  const body = req.body;
  const formacao = body.formacao || {};
  const endereco = body.endereco || {};
  const contato = body.contato || {};
  const id_regime_contratacao = body.id_regime_contratacao;

  const campos = [
    'cpf', 'rg', 'org_emissor', 'uf_rg', 'pais_origem', 'estado',
    'nome_completo', 'nome_social', 'data_nascimento', 'nacionalidade',
    'estrangeiro', 'sexo', 'raca', 'genero', 'estado_civil',
    'telefone', 'celular', 'email', 'pcd', 'observacao',
    'id_regime_contratacao', 'ativo', 'aceite_lgpd', 'data_aceite_lgpd',
    'ra_matricula', 'cd_nivel_formacao', 'cd_curso', 'cd_instituicao_ensino',
    'cd_status_curso', 'semestre_ano', 'cd_turno', 'cd_modalidade_ensino',
    'ds_curso', 'ds_instituicao',
    'cd_banco', 'agencia', 'conta', 'tipo_conta',
    'possui_carteira_fisica', 'nome_responsavel', 'numero_carteira_trabalho', 'numero_serie_carteira_trabalho',
    'pis', 'qtd_membros_domicilio', 'renda_domiciliar_mensal', 'recebe_auxilio_governo', 'qual_auxilio_governo',
    'tipo_curso', 'data_inicio_curso' // 🆕 novos campos
  ];

  const updateFields = [];
  const updateValues = [];
  const client = await pool.connect();

  campos.forEach((campo) => {
    const valor = body[campo] ?? formacao[campo];
    if (valor !== undefined) {
      // Substitui string vazia por null
      const valorFinal = (valor === '' ? null : valor);
      updateFields.push(`${campo} = $${updateValues.length + 1}`);
      updateValues.push(valorFinal);
    }
  });

  if (body.senha !== undefined) {
    updateFields.push(`senha = $${updateValues.length + 1}`);
    updateValues.push(md5(body.senha));
  }

  if (novoComprovante) {
    const busca = await pool.query('SELECT comprovante_path FROM public.candidato WHERE cd_candidato = $1', [id]);
    const antigo = busca.rows[0]?.comprovante_path;
    const fullPath = path.join(__dirname, '..', antigo || '');
    if (antigo && fs.existsSync(fullPath)) fs.unlinkSync(fullPath);
    updateFields.push(`comprovante_path = $${updateValues.length + 1}`);
    updateValues.push(novoComprovante);
  }

  const userId = req.usuario?.cd_usuario || body.atualizado_por || 0;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];
  updateFields.push(`atualizado_por = $${updateValues.length + 1}`);
  updateValues.push(userId);
  updateFields.push(`data_atualizacao = $${updateValues.length + 1}`);
  updateValues.push(dataAtual);
  updateValues.push(id);

  if (updateFields.length <= 2) {
    return res.status(400).json({ erro: 'Nenhum campo fornecido para atualização.' });
  }

  const query = `
    UPDATE public.candidato
    SET ${updateFields.join(', ')}
    WHERE cd_candidato = $${updateValues.length}
    RETURNING *;
  `;

  try {
    //imprimir o que esta sendo atualizado
    console.log('Atualizando candidato com os seguintes campos:', updateFields);
    await client.query('BEGIN');
    const result = await client.query(query, updateValues);
    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Candidato não encontrado.' });
    }
    if (endereco && Object.keys(endereco).length > 0) { 
      if (endereco.id_endereco == null)
        await cadastrarEndereco(endereco, id, userId, null, null, null, client);
      else
        await alterarEndereco(endereco, endereco.id_endereco, userId, client);
    }
    
    if (contato && Object.keys(contato).length > 0)
      if (contato.id_contato == null)
        await cadastrarContato(contato, id, userId, null, client);
      else
        await alterarContato(contato, contato.id_contato, userId, client);

    await client.query('COMMIT');
    res.status(200).json({ mensagem: 'Candidato alterado com sucesso!', candidato: result.rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erro ao alterar candidato:', err);
    res.status(500).json({ erro: 'Erro ao alterar candidato.', motivo: err.message });
  } finally {
    client.release();
  }
});
// Verificar se CPF já existe
router.get('/cpf/:cpf', verificarToken, async (req, res) => {
  const { cpf } = req.params;

  // Remove pontos e traços
  const cpfLimpo = cpf.replace(/[^\d]/g, '');

  const query = `
    SELECT cd_candidato, nome_completo, email
    FROM public.candidato
    WHERE REPLACE(REPLACE(REPLACE(cpf, '.', ''), '-', ''), '/', '') = $1
    LIMIT 1
  `;

  try {
    const result = await pool.query(query, [cpfLimpo]);

    if (result.rows.length === 0) {
      return res.status(404).json({ existe: false });
    }

    res.json({ existe: true, candidato: result.rows[0] });
  } catch (err) {
    console.error('Erro ao verificar CPF:', err);
    logger.error('Erro ao verificar CPF: ' + err.stack, 'candidatos');
    res.status(500).json({ erro: 'Erro ao verificar CPF.' });
  }
});
// Atualizar aceite LGPD
router.put('/lgpd/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const { aceite_lgpd, data_aceite_lgpd } = req.body;

  if (typeof aceite_lgpd !== 'boolean' || !data_aceite_lgpd) {
    return res.status(400).json({ erro: 'Campos obrigatórios: aceite_lgpd (boolean), data_aceite_lgpd (ISO string)' });
  }

  try {
    const result = await pool.query(
      `UPDATE public.candidato
       SET aceite_lgpd = $1,
           data_aceite_lgpd = $2
       WHERE cd_candidato = $3
       RETURNING *`,
      [aceite_lgpd, data_aceite_lgpd, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Candidato não encontrado' });
    }

    res.json({ mensagem: 'Aceite LGPD atualizado com sucesso', candidato: result.rows[0] });
  } catch (err) {
    console.error('Erro ao atualizar LGPD:', err);
    res.status(500).json({ erro: 'Erro interno do servidor' });
  }
});
// Atualizar formação do candidato
// Esta rota atualiza a formação do candidato, incluindo o upload de um comprovante
router.post('/formacao/cadastrar', upload.single('comprovante'), async (req, res) => {
  const {
    cd_candidato,
    cd_nivel_formacao,
    cd_curso,
    cd_instituicao_ensino,
    cd_status_curso,
    semestre_ano,
    cd_turno,
    cd_modalidade_ensino,
    ra_matricula,
    ds_curso,
    ds_instituicao
  } = req.body;

  const comprovantePath = req.file?.path || null;

  if (!cd_candidato) {
    return res.status(400).json({ erro: 'Código do candidato é obrigatório.' });
  }

  const query = `
    UPDATE public.candidato
    SET
      cd_nivel_formacao = $1,
      cd_curso = $2,
      cd_instituicao_ensino = $3,
      cd_status_curso = $4,
      semestre_ano = $5,
      cd_turno = $6,
      cd_modalidade_ensino = $7,
      ra_matricula = $8,
      comprovante_path = $9,
      ds_curso = $10,
      ds_instituicao = $11,
      data_atualizacao = NOW()
    WHERE cd_candidato = $12
    RETURNING cd_candidato;
  `;

  const values = [
    cd_nivel_formacao,
    cd_curso,
    cd_instituicao_ensino,
    cd_status_curso,
    semestre_ano,
    cd_turno,
    cd_modalidade_ensino,
    ra_matricula,
    comprovantePath,
    ds_curso,
    ds_instituicao,
    cd_candidato
  ];

  try {
    const result = await pool.query(query, values);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Candidato não encontrado.' });
    }

    res.status(200).json({
      mensagem: 'Formação do candidato atualizada com sucesso.',
      cd_candidato: result.rows[0].cd_candidato,
      comprovante: comprovantePath
    });
  } catch (error) {
    console.error('Erro ao atualizar formação:', error);
    res.status(500).json({ erro: 'Erro ao atualizar formação.' });
  }
});
//  Buscar formação do candidato
// Esta rota busca a formação de um candidato específico pelo ID    
router.get('/formacao/:cd_formacao', verificarToken, async (req, res) => {
  const { cd_formacao } = req.params;

  const query = `
    SELECT 
      cd_candidato AS id,
      ra_matricula,
      semestre_ano,
      can.data_criacao,
      can.data_atualizacao,
      can.criado_por,
      can.atualizado_por,
      can.comprovante_path,
      ds_curso,
      ds_instituicao,
      nf.descricao AS nivel_formacao,
      c.descricao AS curso,
      ie.razao_social AS instituicao_ensino,
      sc.descricao AS status_curso,
      t.descricao AS turno,
      m.descricao AS modalidade_ensino
    FROM public.candidato can
    LEFT JOIN public.nivel_formacao nf ON nf.cd_nivel_formacao = can.cd_nivel_formacao
    LEFT JOIN public.curso c ON c.cd_curso = can.cd_curso
    LEFT JOIN public.instituicao_ensino ie ON ie.cd_instituicao_ensino = can.cd_instituicao_ensino
    LEFT JOIN public.status_curso sc ON sc.cd_status = can.cd_status_curso
    LEFT JOIN public.turno t ON t.cd_turno = can.cd_turno
    LEFT JOIN public.modalidade_ensino m ON m.cd_modalidade_ensino = can.cd_modalidade_ensino
    WHERE can.cd_candidato = $1
    LIMIT 1;
  `;

  try {
    const result = await pool.query(query, [cd_formacao]);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Formação não encontrada.' });
    }

    res.status(200).json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao buscar formação:', err);
    logger.error('Erro ao buscar formação: ' + err.stack, 'formacao-candidato');
    res.status(500).json({ erro: 'Erro ao buscar formação do candidato.' });
  }
});
// Atualizar formação do candidato
// Esta rota atualiza a formação do candidato, incluindo o upload de um novo comprovante
router.put('/formacao/alterar/:id', verificarToken, upload.single('comprovante'), async (req, res) => {
  const { id } = req.params;
  const novoComprovante = req.file?.path || null;

  // Todos os campos que podem ser atualizados
  const campos = [
    'cd_nivel_formacao',
    'cd_curso',
    'cd_instituicao_ensino',
    'cd_status_curso',
    'semestre_ano',
    'cd_turno',
    'cd_modalidade_ensino',
    'ra_matricula',
    'ds_curso',
    'ds_instituicao'
  ];

  const updateFields = [];
  const updateValues = [];

  campos.forEach((campo) => {
    if (req.body[campo] !== undefined) {
      updateFields.push(`${campo} = $${updateValues.length + 1}`);
      updateValues.push(req.body[campo]);
    }
  });

  // Atualizar comprovante (remover o anterior se necessário)
  if (novoComprovante) {
    const busca = await pool.query(
      'SELECT comprovante_path FROM public.candidato WHERE cd_candidato = $1',
      [id]
    );

    if (busca.rowCount > 0) {
      const comprovanteAntigo = busca.rows[0].comprovante_path;
      const fullOldPath = path.join(__dirname, '..', comprovanteAntigo);
      if (comprovanteAntigo && fs.existsSync(fullOldPath)) {
        fs.unlinkSync(fullOldPath);
        console.log('Comprovante antigo removido:', comprovanteAntigo);
      }
    }

    updateFields.push(`comprovante_path = $${updateValues.length + 1}`);
    updateValues.push(novoComprovante);
  }

  // Auditoria
  const userId = req.usuario?.cd_usuario || req.body.atualizado_por || 0;
  const dataAtual = new Date().toISOString().split('T').join(' ').split('.')[0];

  updateFields.push(`atualizado_por = $${updateValues.length + 1}`);
  updateValues.push(userId);

  updateFields.push(`data_atualizacao = $${updateValues.length + 1}`);
  updateValues.push(dataAtual);

  updateValues.push(id); // WHERE

  if (updateFields.length <= 2) {
    return res.status(400).json({ erro: 'Nenhum campo fornecido para atualização.' });
  }

  const query = `
    UPDATE public.candidato
    SET ${updateFields.join(', ')}
    WHERE cd_candidato = $${updateValues.length}
    RETURNING *;
  `;

  try {
    const result = await pool.query(query, updateValues);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Candidato não encontrado.' });
    }

    res.status(200).json({
      mensagem: 'Formação do candidato atualizada com sucesso.',
      candidato: result.rows[0]
    });
  } catch (err) {
    console.error('Erro ao atualizar formação:', err);
    logger.error('Erro ao atualizar formação: ' + err.stack, 'formacao-candidato');
    res.status(500).json({ erro: 'Erro ao atualizar formação.' });
  }
});
// Listar formação do candidato
// Esta rota lista a formação de um candidato específico pelo ID
router.get('/formacao/listar/:cd_candidato', verificarToken, async (req, res) => {
  const { cd_candidato } = req.params;

  const query = `
    SELECT 
      cd_candidato AS id,
      ra_matricula,
      semestre_ano,
      can.data_criacao,
      can.data_atualizacao,
      can.criado_por,
      can.atualizado_por,
      can.comprovante_path,
      ds_curso,
      ds_instituicao,
      nf.descricao AS nivel_formacao,
      c.descricao AS curso,
      ie.razao_social AS instituicao_ensino,
      sc.descricao AS status_curso,
      t.descricao AS turno,
      m.descricao AS modalidade_ensino
    FROM public.candidato can
    LEFT JOIN public.nivel_formacao nf ON nf.cd_nivel_formacao = can.cd_nivel_formacao
    LEFT JOIN public.curso c ON c.cd_curso = can.cd_curso
    LEFT JOIN public.instituicao_ensino ie ON ie.cd_instituicao_ensino = can.cd_instituicao_ensino
    LEFT JOIN public.status_curso sc ON sc.cd_status = can.cd_status_curso
    LEFT JOIN public.turno t ON t.cd_turno = can.cd_turno
    LEFT JOIN public.modalidade_ensino m ON m.cd_modalidade_ensino = can.cd_modalidade_ensino
    WHERE can.cd_candidato = $1
    LIMIT 1;
  `;

  try {
    const result = await pool.query(query, [cd_candidato]);

    if (result.rowCount === 0) {
      return res.json({ dados: [], pagination: { totalItems: 0, totalPages: 1, currentPage: 1 } });
    }

    res.json({
      dados: [result.rows[0]],
      pagination: {
        totalItems: 1,
        totalPages: 1,
        currentPage: 1,
        hasNextPage: false,
        hasPrevPage: false
      }
    });
  } catch (err) {
    console.error('Erro ao listar formação:', err);
    logger.error('Erro ao listar formação: ' + err.stack, 'formacao-candidato');
    res.status(500).json({ erro: 'Erro ao listar formação do candidato.' });
  }
});
 

 



// ==========================
// EXPORTADOR DE CANDIDATOS
// ==========================
 // ==========================
// EXPORTADOR DE CANDIDATOS
// ==========================
const exportCandidato = createCsvExporter({
  filename: () =>
    `candidatos-${new Date().toISOString().slice(0, 10)}.csv`,

  header: [
    'Código',
    'Nome Completo',
    'Nome Social',
    'CPF',
    'E-mail',
    'Telefone',
    'Celular',
    'Ativo',
    'Regime de Contratação',
    'Nível Formação',
    'Curso',
    'Instituição',
    'Status do Curso',
    'Turno',
    'Modalidade',
    'Semestre/Ano',
    'Data Início Curso',
    'Tipo Curso',
    'Sexo',
    'Observação',
    'Cidade',
    'UF',
    'Criado Por',
    'Data Criação',
    'Atualizado Por',
    'Data Atualização'
  ],

  baseQuery: `
    SELECT DISTINCT
      c.cd_candidato,
      c.nome_completo,
      c.nome_social,
      c.cpf,
      c.email,
      c.telefone,
      c.celular,
      c.ativo,

      rc.descricao AS regime_contratacao,
      nf.descricao AS nivel_formacao,
      COALESCE(cur.descricao, c.ds_curso) AS curso,
      COALESCE(ie.razao_social, c.ds_instituicao) AS instituicao,
      sc.descricao AS status_curso,
      t.descricao AS turno,
      m.descricao AS modalidade,

      c.semestre_ano,
      to_char(c.data_inicio_curso, 'DD/MM/YYYY') AS data_inicio_curso,
      c.tipo_curso,
      c.sexo,
      c.observacao,

      e.cidade,
      e.uf,

      COALESCE(u1.nome,'') AS criado_por,
      to_char(c.data_criacao,'DD/MM/YYYY HH24:MI') AS data_criacao,
      COALESCE(u2.nome,'') AS atualizado_por,
      to_char(c.data_atualizacao,'DD/MM/YYYY HH24:MI') AS data_atualizacao

    FROM public.candidato c
    LEFT JOIN public.regime_contratacao rc ON rc.id_regime_contratacao = c.id_regime_contratacao
    LEFT JOIN public.nivel_formacao nf ON nf.cd_nivel_formacao = c.cd_nivel_formacao
    LEFT JOIN public.curso cur ON cur.cd_curso = c.cd_curso
    LEFT JOIN public.instituicao_ensino ie ON ie.cd_instituicao_ensino = c.cd_instituicao_ensino
    LEFT JOIN public.status_curso sc ON sc.cd_status = c.cd_status_curso
    LEFT JOIN public.turno t ON t.cd_turno = c.cd_turno
    LEFT JOIN public.modalidade_ensino m ON m.cd_modalidade_ensino = c.cd_modalidade_ensino
    LEFT JOIN public.endereco e ON e.cd_candidato = c.cd_candidato AND e.principal = true
    LEFT JOIN public.usuarios u1 ON u1.cd_usuario = c.criado_por
    LEFT JOIN public.usuarios u2 ON u2.cd_usuario = c.atualizado_por

    {{WHERE}}
    ORDER BY c.nome_completo
  `,

  // ========================================
  // 🔥 buildWhereAndParams – versão final
  // ========================================
  buildWhereAndParams: (req) => {
  const { nome, cpf, email, tipo, ativo, cidade, curso } = req.query;

  const params = [];
  const filtrosBusca = [];
  const filtrosAnd = [];
  let i = 1;

  // 🔹 Filtro por nome ou código do candidato
  if (nome) {
    const nomeTrim = nome.trim();

    if (/^\d+$/.test(nomeTrim) && nomeTrim.length < 9) {
      params.push(parseInt(nomeTrim, 10));
      filtrosBusca.push(`c.cd_candidato = $${i++}`);
    } else {
      params.push(`%${nomeTrim}%`);
      filtrosBusca.push(
        `unaccent(LOWER(c.nome_completo)) ILIKE unaccent(LOWER($${i++}))`
      );
    }
  }

  // 🔹 Filtro por CPF
  if (cpf) {
    const cpfSemMascara = cpf.replace(/[./-]/g, "");
    params.push(`%${cpfSemMascara}%`);
    filtrosBusca.push(
      `REPLACE(REPLACE(REPLACE(c.cpf, '.', ''), '-', ''), '/', '') ILIKE $${i++}`
    );
  }

  // 🔹 Filtro por e-mail
  if (email) {
    params.push(`%${email.trim()}%`);
    filtrosBusca.push(`LOWER(c.email) ILIKE LOWER($${i++})`);
  }

  // 🔹 Filtro por ativo
  if (ativo !== undefined) {
    const ativoBool = String(ativo).trim().toLowerCase() === "true";
    params.push(ativoBool);
    filtrosAnd.push(`c.ativo = $${i++}`);
  }

  // 🔹 Filtro por tipo (regime de contratação)
  if (tipo) {
    const tipoLower = tipo.toLowerCase();

    if (["estagio", "estagiario", "estudante", "2"].includes(tipoLower)) {
      filtrosAnd.push(`c.id_regime_contratacao = 2`);
    } else if (["aprendiz", "1"].includes(tipoLower)) {
      filtrosAnd.push(`c.id_regime_contratacao = 1`);
    }
  }

  // 🔹 Filtro por cidade
  if (cidade) {
    params.push(`%${cidade.trim()}%`);
    filtrosAnd.push(
      `unaccent(LOWER(e.cidade)) ILIKE unaccent(LOWER($${i++}))`
    );
  }

  // 🔹 Filtro por curso
  if (curso) {
    params.push(`%${curso.trim()}%`);
    filtrosAnd.push(
      `unaccent(LOWER(cur.descricao)) ILIKE unaccent(LOWER($${i++}))`
    );
  }

  // 🔹 Montagem do WHERE
  const condicoes = [];

  if (filtrosBusca.length > 0) {
    condicoes.push(`(${filtrosBusca.join(" OR ")})`);
  }

  if (filtrosAnd.length > 0) {
    condicoes.push(filtrosAnd.join(" AND "));
  }

  const where = condicoes.length > 0 ? `WHERE ${condicoes.join(" AND ")}` : "";

  console.log("WHERE EXPORT:", where);
  console.log("PARAMS EXPORT:", params);

  return { where, params };
},

  // ========================================
  // MAPEAMENTO DAS COLUNAS
  // ========================================
  rowMap: (r) => [
    r.cd_candidato,
    r.nome_completo || '',
    r.nome_social || '',
    r.cpf || '',
    r.email || '',
    r.telefone || '',
    r.celular || '',
    r.ativo ? 'Sim' : 'Não',
    r.regime_contratacao || '',
    r.nivel_formacao || '',
    r.curso || '',
    r.instituicao || '',
    r.status_curso || '',
    r.turno || '',
    r.modalidade || '',
    r.semestre_ano || '',
    r.data_inicio_curso || '',
    r.tipo_curso || '',
    r.sexo || '',
    r.observacao || '',
    r.cidade || '',
    r.uf || '',
    r.criado_por || '',
    r.data_criacao || '',
    r.atualizado_por || '',
    r.data_atualizacao || ''
  ]
});




module.exports = { exportCandidato };




router.get('/exportar/csv', verificarToken, exportCandidato );
 
router.get('/pdf/:cd_candidato', async (req, res) => {
  const { cd_candidato } = req.params;

  try {
    // =================
    // 1) DADOS PESSOAIS
    // =================
    const sql = `
      SELECT 
        c.cd_candidato, c.nome_completo, c.nome_social, c.cpf, 
        c.rg, c.data_nascimento, c.email, c.celular,
        c.tipo_curso, c.data_inicio_curso, c.semestre_ano,
        c.ra_matricula,
        e.cep, e.logradouro, e.numero, e.bairro, e.cidade, e.uf,
        ct.telefone AS telefone_contato, ct.nome AS nome_contato,
        rc.descricao AS regime_contratacao,
        nf.descricao AS nivel_formacao,
        COALESCE(cur.descricao, c.ds_curso) AS curso,
        COALESCE(ie.razao_social, c.ds_instituicao) AS instituicao,
        sc.descricao AS status_curso,
        t.descricao AS turno,
        m.descricao AS modalidade_ensino
      FROM public.candidato c
      LEFT JOIN public.regime_contratacao rc ON rc.id_regime_contratacao = c.id_regime_contratacao
      LEFT JOIN public.nivel_formacao nf ON nf.cd_nivel_formacao = c.cd_nivel_formacao
      LEFT JOIN public.curso cur ON cur.cd_curso = c.cd_curso
      LEFT JOIN public.instituicao_ensino ie ON ie.cd_instituicao_ensino = c.cd_instituicao_ensino
      LEFT JOIN public.status_curso sc ON sc.cd_status = c.cd_status_curso
      LEFT JOIN public.turno t ON t.cd_turno = c.cd_turno
      LEFT JOIN public.modalidade_ensino m ON m.cd_modalidade_ensino = c.cd_modalidade_ensino
      LEFT JOIN public.endereco e ON e.cd_candidato = c.cd_candidato AND e.principal = true
      LEFT JOIN public.contatos ct ON ct.cd_candidato = c.cd_candidato AND ct.principal = true
      WHERE c.cd_candidato = $1
      LIMIT 1;
    `;

    const result = await pool.query(sql, [cd_candidato]);
    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Estudante não encontrado.' });
    }

    const estudante = result.rows[0];

    // ========================
    // 2) BUSCAR EXPERIÊNCIAS
    // ========================
    const experiencias = await pool.query(`
      SELECT nome_empresa empresa, atividades, data_inicio, data_fim 
      FROM candidato_experiencia 
      WHERE cd_candidato = $1
      ORDER BY data_inicio DESC
    `, [cd_candidato]);

    // ======================
    // 3) BUSCAR IDIOMAS
    // ======================
    const idiomas = await pool.query(`
     SELECT  i.descricao idioma, nc.descricao   nivel
      FROM candidato_idioma ci  inner join idioma i on  ci.cd_idioma = i.cd_idioma
	   inner join public.nivel_conhecimento  nc on   nc.cd_nivel_conhecimento = ci.cd_nivel_conhecimento
      WHERE cd_candidato = $1
      ORDER BY i.descricao
    `, [cd_candidato]);

    // ============================
    // 4) BUSCAR CONHECIMENTOS
    // ============================
    const conhecimentos = await pool.query(`
      SELECT i.descricao conhecimento, nc.descricao   nivel
      FROM candidato_conhecimento ci
	     inner join public.conhecimento  i on  ci.cd_conhecimento  = i. cd_conhecimento
	   inner join public.nivel_conhecimento  nc on   nc.cd_nivel_conhecimento = ci.cd_nivel_conhecimento
      WHERE cd_candidato = $1
      ORDER BY i.descricao 
    `, [cd_candidato]);

    // Função para formatar datas
    const formatarData = (data) => {
      if (!data) return '-';
      const d = new Date(data);
      return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
    };

    // ===============
    // 5) GERAR PDF
    // ===============
     // ----------------------
// CONFIGURAÇÃO DO PDF
// ----------------------
const doc = new PDFDocument({
  size: 'A4',
  margin: 45
});

res.setHeader("Content-Type", "application/pdf");
res.setHeader(
  "Content-Disposition",
  `attachment; filename=resumo_estudante_${cd_candidato}.pdf`
);

doc.pipe(res);

// ----------------------
// FUNÇÃO PARA SEÇÕES
// ----------------------
function tituloSecao(texto) {
  doc
    .moveDown()
    .fontSize(14)
    .fillColor('#0057D9')
    .text(texto, { underline: false, bold: true })
    .fillColor('black')
    .moveDown(0.3);

  // linha de separação elegante
  doc
    .strokeColor('#D0D0D0')
    .lineWidth(1)
    .moveTo(45, doc.y)
    .lineTo(550, doc.y)
    .stroke();
    
  doc.moveDown();
}

// ----------------------
// CABEÇALHO ESTILO CURRÍCULO
// ----------------------
doc
  .fontSize(24)
  .fillColor('#333333')
  .text(estudante.nome_completo, { align: 'center' });

doc.moveDown(0.3);

doc
  .fontSize(10)
  .fillColor('#555555')
  .text(`${estudante.email}  |  ${estudante.celular}`, { align: 'center' });

doc.fillColor('black');

// ----------------------
// SEÇÃO: DADOS PESSOAIS
// ----------------------
tituloSecao('Dados Pessoais');

doc.fontSize(11)
  .text(`CPF: ${estudante.cpf}`)
  .text(`RG: ${estudante.rg}`)
  .text(`Data Nascimento: ${formatarData(estudante.data_nascimento)}`);

// ----------------------
// SEÇÃO: FORMAÇÃO / ACADÊMICO
// ----------------------
tituloSecao('Formação Acadêmica');

doc.fontSize(11)
  .text(`Nível: ${estudante.nivel_formacao}`)
  .text(`Curso: ${estudante.curso}`)
  .text(`Instituição: ${estudante.instituicao}`)
  .text(`Status: ${estudante.status_curso}`)
  .text(`Turno: ${estudante.turno}`)
  .text(`Modalidade: ${estudante.modalidade_ensino}`)
  .text(`RA/Matrícula: ${estudante.ra_matricula || '-'}`)
  .text(`Semestre/Ano Atual: ${estudante.semestre_ano}`)
  .moveDown();

// ----------------------
// SEÇÃO: EXPERIÊNCIA
// ----------------------
tituloSecao('Experiência Profissional');

if (experiencias.rows.length === 0) {
  doc.text('Nenhuma experiência cadastrada.');
} else {
  experiencias.rows.forEach((exp, i) => {
    doc
      .fontSize(12)
      .fillColor('#0057D9')
      .text(`${exp.empresa}`, { bold: true });
    doc.fillColor('black')
      .fontSize(10)
      .text(`${formatarData(exp.data_inicio)} — ${formatarData(exp.data_fim)}`)
      .moveDown(0.3)
      .fontSize(10)
      .text(exp.atividades)
      .moveDown(0.8);
  });
}

// ----------------------
// SEÇÃO: IDIOMAS
// ----------------------
tituloSecao('Idiomas');

idiomas.rows.length === 0
  ? doc.text('Nenhum idioma cadastrado.')
  : idiomas.rows.forEach(id => {
      doc.fontSize(11).text(`• ${id.idioma} — ${id.nivel}`);
    });

// ----------------------
// SEÇÃO: CONHECIMENTOS
// ----------------------
tituloSecao('Conhecimentos Técnicos');

conhecimentos.rows.length === 0
  ? doc.text('Nenhum conhecimento cadastrado.')
  : conhecimentos.rows.forEach(c => {
      doc.fontSize(11).text(`• ${c.conhecimento} — ${c.nivel}`);
    });

// ----------------------
// FOOTER
// ----------------------
doc.moveDown(2);
doc
  .fontSize(9)
  .fillColor('#888888')
  .text('Documento gerado automaticamente pelo Sistema CIDE Estágio.', {
    align: 'center',
  });

// Finaliza
doc.end();


  } catch (error) {
    console.error(error);
    res.status(500).json({ erro: 'Erro ao gerar PDF.', motivo: error.message });
  }
});

 
 




module.exports = router;
