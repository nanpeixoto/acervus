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

 

 



app.use('/uploads', express.static(path.join(__dirname, 'uploads')));



app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
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
 

const autenticacaoRoute = require('./routes/autenticacao.js');
app.use('/autenticacao', autenticacaoRoute);
  
const idiomaRoute = require('./routes/idioma.js');
app.use('/idioma',idiomaRoute);
     
const dashboardRouter = require('./routes/dashboard.js');
app.use('/dashboard', dashboardRouter);

const { router: usuarioRouter } = require('./routes/usuario.js');
app.use('/usuario', usuarioRouter);
  


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


const sala = require('./routes/sala.js');
app.use('/sala', sala);


const estante = require('./routes/estante.js');
app.use('/estante', estante);



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
