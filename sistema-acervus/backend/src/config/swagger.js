// src/config/swagger.js
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

// src/config/swagger.js
const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'API do CIDE',
      version: '1.0.0',
      description: 'API para gerenciar e buscar instituições, cidades e outras entidades do CIDE Estágio',
    },
  },
  // Aqui você ajusta o caminho para os arquivos de rotas onde as anotações Swagger estão
  apis: ['./routes/*.js'],  // Ajuste se necessário
};

const swaggerSpec = swaggerJsdoc(options);

// Função para configurar o Swagger UI
function setupSwagger(app) {
  app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));  // Configura o Swagger UI na URL /docs
}

module.exports = setupSwagger;
