const express = require('express');
const cors = require('cors');
require('dotenv').config();
const YAML = require('yamljs');
const path = require('path');
const swaggerUi = require('swagger-ui-express');
const logger = require('./utils/logger'); // Importando o logger para registrar erros e informações

const loginRoute = require('./routes/login');
// ✅ CORREÇÃO: Importação correta do middleware de autenticação
const { verificarToken, tokenOpcional } = require('./auth');

const app = express();
const PORT = process.env.PORT || 3000;

 

 

app.use('/uploads/imagem_modelo', express.static(path.join(__dirname, 'uploads/imagem_modelo')));



app.use(cors());


// Handlers globais de exceção
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
});
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection:', reason);
});

// ✅ Limite de tamanho de requisição aumentado
app.use(express.json({ limit: '500mb' }));
app.use(express.urlencoded({ extended: true, limit: '500mb' }));

// Swagger
const swaggerDocument = YAML.load(path.join(__dirname, './docs/main.yaml'));
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.use('/adm', loginRoute);

// rota pública
app.get('/ping', (req, res) => {
  res.json({ mensagem: 'API rodando! 2.0' });
});

// Rotas
const instituicaoRoute = require('./routes/instituicao');
app.use('/instituicao', instituicaoRoute);


const representante_legalRoute = require('./routes/representante_legal.js');
app.use('/representantelegal', representante_legalRoute);

const OrientadorRoute = require('./routes/orientador.js');
app.use('/orientador', OrientadorRoute);

const usuarioInstituicaoRoute = require('./routes/usuarioInstituicao.js');
app.use('/usuarioInstituicao', usuarioInstituicaoRoute);

const signatarioRoute = require('./routes/signatario.js');
app.use('/signatario', signatarioRoute);

const { router: enderecoRoute } = require('./routes/endereco');
app.use('/endereco', enderecoRoute);

const tagsRoute = require('./routes/tags.js');
app.use('/tags', tagsRoute);

const tipoModeloRoute = require('./routes/tipoModelo.js');
app.use('/tipoModelo', tipoModeloRoute);

const modeloRoute = require('./routes/modelo.js');
app.use('/modelo', modeloRoute);

const gerarTemplateRoute = require('./routes/gerarTemplate.js');
app.use('/gerarTemplate', gerarTemplateRoute);

const candidatoRoute = require('./routes/candidato.js');
app.use('/candidato', candidatoRoute);

const autenticacaoRoute = require('./routes/autenticacao.js');
app.use('/autenticacao', autenticacaoRoute);

const regime_contratacaoRoute = require('./routes/regime_contratacao.js');
app.use('/regime_contratacao', regime_contratacaoRoute);

const { router: contatoRoute } = require('./routes/contatos.js');
app.use('/contato', contatoRoute);;


const statusCursoRoute = require('./routes/status_curso.js');
app.use('/statuscurso',statusCursoRoute);

const turnoRoute = require('./routes/turno.js');
app.use('/turno',turnoRoute);


const modalideEnsinoRoute = require('./routes/modalidade_ensino.js');
app.use('/modalidade_ensino',modalideEnsinoRoute);

const nivelFormacaoRoute = require('./routes/nivel_formacao.js');
app.use('/nivel_formacao',nivelFormacaoRoute);

const cursoRoute = require('./routes/curso.js');
app.use('/curso',cursoRoute);

const idiomaRoute = require('./routes/idioma.js');
app.use('/idioma',idiomaRoute);

const nivelConhecimentoRoute = require('./routes/nivel_conhecimento.js');
app.use('/nivel_conhecimento',nivelConhecimentoRoute);

const conhecimentoRoute = require('./routes/conhecimento.js');
app.use('/conhecimento',conhecimentoRoute);

const bancoRoute = require('./routes/banco.js');
app.use('/banco',bancoRoute);

const receitaRoute = require('./routes/receita.js');
app.use('/receita',receitaRoute);

const seguradoraRoute = require('./routes/seguradora.js');
app.use('/seguradora',seguradoraRoute);

const empresaRoute = require('./routes/empresa.js');
app.use('/empresa',empresaRoute);


const supervisorRoute = require('./routes/supervisor.js');
app.use('/supervisor',supervisorRoute);

const vagasRoute = require('./routes/vagas.js');
app.use('/vaga',vagasRoute);

const planoPagamentoRoute = require('./routes/plano_pagamento.js');
app.use('/plano_pagamento',planoPagamentoRoute);

const empresaPlanoRoute = require('./routes/empresa_plano_pagamento.js');
app.use('/empresa_plano', empresaPlanoRoute);

const estagioRoute = require('./routes/contrato-estagio.js');
app.use('/contrato-estagio', estagioRoute);

app.use('/contrato', estagioRoute); // /contrato agora expõe as rotas de estágio


const AprendizRoute = require('./routes/contrato-aprendiz.js');
app.use('/contrato-aprendiz', AprendizRoute);

const dashboardRouter = require('./routes/dashboard.js');
app.use('/dashboard', dashboardRouter);

const { router: usuarioRouter } = require('./routes/usuario.js');
app.use('/usuario', usuarioRouter);


const SetorRouter = require('./routes/setor.js');
app.use('/setor', SetorRouter);


const cboRouter = require('./routes/cbo.js');
app.use('/cbo', cboRouter);

const cursoAprendizagemRouter = require('./routes/cursoAprendizagem.js');
app.use('/curso_aprendizagem', cursoAprendizagemRouter);


const turmaRouter = require('./routes/turma.js');
app.use('/turma', turmaRouter);

const documentosComplementaresRouter = require('./routes/documentosComplementares.js');
app.use('/documentos-complementares', documentosComplementaresRouter);


const relatorioContratosVencerRouter = require('./routes/relatorioContratosVencer.js');
app.use('/relatorios', relatorioContratosVencerRouter);


const taxaAdministrativaRouter = require('./routes/taxa_administrativa.js');
app.use('/taxa-administrativa', taxaAdministrativaRouter);



const autor = require('./routes/autor.js');
app.use('/autor', autor);
const assunto = require('./routes/assunto.js');
app.use('/assunto', assunto);

const material = require('./routes/material.js');
app.use('/Materiais', material);

const tipo_obra = require('./routes/tipo_obra.js');
app.use('/tipo_obra', tipo_obra);

const estado = require('./routes/estado.js');
app.use('/estado', estado);

const cidadeRoute = require('./routes/cidade');
app.use('/cidade', cidadeRoute);



const pais = require('./routes/pais.js');
app.use('/pais', pais);


const subtipo_obra = require('./routes/subtipo_obra.js');
app.use('/subtipo_obra', subtipo_obra);


const obra = require('./routes/obra.js');
app.use('/obra', obra);

const editora = require('./routes/editora.js');
app.use('/editora', editora);


const estadoConservacao = require('./routes/estadoConservacao.js');
app.use('/estado-conservacao', estadoConservacao);

const authResetRoutes = require('./routes/auth_reset');
app.use('/auth', authResetRoutes);




// Serve arquivos da pasta uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));


// Rota protegidaturno
app.get('/protegido', verificarToken, (req, res) => {
  res.json({ mensagem: 'Você está autenticado!', usuario: req.usuario });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});
