# Sistema de Gestão de Estágios e Aprendizagem - Backend

Sistema completo para gerenciamento de estágios e programas de jovem aprendiz, desenvolvido com Node.js, TypeScript, PostgreSQL e Prisma ORM.

## 🚀 Características

- ✅ **API REST completa** com autenticação JWT
- ✅ **Banco de dados robusto** com PostgreSQL e Prisma ORM
- ✅ **Validações automáticas** (CPF, CNPJ, email, telefone)
- ✅ **Sistema de permissões** por perfil de usuário
- ✅ **Integração com Receita Federal** para consulta de CNPJ
- ✅ **Geração de PDFs** para contratos e convênios
- ✅ **Rate limiting** e medidas de segurança
- ✅ **Arquitetura escalável** e bem estruturada

## 📋 Funcionalidades

### Cadastros Principais
- **Estagiários**: Cadastro completo com validação de menor de idade
- **Jovens Aprendizes**: Gestão de carteira de trabalho e dados específicos
- **Empresas/Concedentes**: Integração com Receita Federal, gestão de taxas
- **Instituições de Ensino**: Convênios automáticos, professores orientadores
- **Supervisores**: Vinculação com empresas e setores
- **Usuários Internos**: Sistema de permissões (Admin, Gestor, Operador, Consultor)

### Sistema de Contratos (Futuro)
- Geração automática de contratos de estágio
- Termos aditivos com histórico de alterações
- Controle de vencimentos e alertas
- Documentação completa em PDF

## 🛠️ Tecnologias

- **Node.js** + **TypeScript**
- **Express.js** - Framework web
- **PostgreSQL** - Banco de dados
- **Prisma ORM** - Gerenciamento de banco
- **JWT** - Autenticação
- **bcryptjs** - Hash de senhas
- **Zod** - Validação de dados
- **Helmet** - Segurança
- **Rate Limiting** - Proteção contra spam

## 📦 Instalação

### Pré-requisitos
- Node.js 18+ 
- PostgreSQL 12+
- npm ou yarn

### 1. Clone o repositório
```bash
git clone https://github.com/seu-usuario/sistema-gestao-estagios.git
cd sistema-gestao-estagios
```

### 2. Instale as dependências
```bash
npm install
```

### 3. Configure o banco de dados
```bash
# Copie o arquivo de exemplo
cp .env.example .env

# Edite o arquivo .env com suas configurações
# DATABASE_URL="postgresql://usuario:senha@localhost:5432/sistema_estagios"
# JWT_SECRET="seu_jwt_secret_muito_seguro"
```

### 4. Execute as migrações do banco
```bash
# Gerar cliente Prisma
npm run db:generate

# Aplicar migrações
npm run db:push

# OU criar migrações (em produção)
npm run db:migrate
```

### 5. Execute o seed inicial
```bash
npm run db:seed
```

### 6. Inicie o servidor
```bash
# Desenvolvimento
npm run dev

# Produção
npm run build
npm start
```

## 🎯 API Endpoints

### Autenticação
```
POST   /api/auth/login              # Login
GET    /api/auth/perfil             # Perfil do usuário logado
PUT    /api/auth/alterar-senha      # Alterar senha
GET    /api/auth/usuarios           # Listar usuários (Gestor+)
POST   /api/auth/usuarios           # Criar usuário (Admin)
PUT    /api/auth/usuarios/:id       # Editar usuário (Admin)
```

### Estagiários
```
GET    /api/estagiarios             # Listar estagiários
GET    /api/estagiarios/:id         # Buscar estagiário
POST   /api/estagiarios             # Criar estagiário (Gestor+)
PUT    /api/estagiarios/:id         # Editar estagiário (Gestor+)
PUT    /api/estagiarios/:id/desativar  # Desativar (Gestor+)
```

### Jovens Aprendizes
```
GET    /api/jovens-aprendizes       # Listar jovens aprendizes
GET    /api/jovens-aprendizes/:id   # Buscar jovem aprendiz
POST   /api/jovens-aprendizes       # Criar (Gestor+)
PUT    /api/jovens-aprendizes/:id   # Editar (Gestor+)
```

### Empresas
```
GET    /api/empresas                # Listar empresas
GET    /api/empresas/:id            # Buscar empresa
POST   /api/empresas                # Criar empresa (Gestor+)
PUT    /api/empresas/:id            # Editar empresa (Gestor+)
GET    /api/empresas/consultar-cnpj/:cnpj  # Consultar CNPJ
POST   /api/empresas/:id/gerar-convenio    # Gerar convênio
```

### Instituições de Ensino
```
GET    /api/instituicoes-ensino     # Listar instituições
GET    /api/instituicoes-ensino/:id # Buscar instituição
POST   /api/instituicoes-ensino     # Criar (Gestor+)
PUT    /api/instituicoes-ensino/:id # Editar (Gestor+)
```

### Supervisores e Setores
```
GET    /api/supervisores            # Listar supervisores
GET    /api/supervisores/:id        # Buscar supervisor
POST   /api/supervisores            # Criar (Gestor+)
PUT    /api/supervisores/:id        # Editar (Gestor+)

GET    /api/supervisores/setores    # Listar setores por empresa
POST   /api/supervisores/setores    # Criar setor (Gestor+)
PUT    /api/supervisores/setores/:id  # Editar setor (Gestor+)
DELETE /api/supervisores/setores/:id  # Excluir setor (Gestor+)
```

## 🔐 Sistema de Permissões

### Perfis de Usuário
- **ADMIN**: Acesso total ao sistema
- **GESTOR**: Criação e edição de cadastros
- **OPERADOR**: Consulta e operações básicas
- **CONSULTOR**: Apenas consulta

### Autenticação JWT
```javascript
// Header de Authorization
Authorization: Bearer <seu_jwt_token>
```

## 📊 Modelo de Dados

### Entidades Principais
- **Usuario**: Usuários internos do sistema
- **Estagiario**: Estudantes interessados em estágio
- **JovemAprendiz**: Jovens no programa de aprendizagem
- **Empresa**: Empresas concedentes
- **InstituicaoEnsino**: Universidades e escolas
- **Supervisor**: Responsáveis nas empresas
- **Setor**: Departamentos das empresas
- **ContratoEstagio**: Contratos de estágio (futuro)
- **ContratoAprendiz**: Contratos de aprendizagem (futuro)

## 🔍 Validações Implementadas

### CPF e CNPJ
- Validação de dígitos verificadores
- Formato automático com pontos e traços
- Verificação de duplicatas

### Email e Telefone
- Validação de formato
- Normalização automática

### Endereços
- Validação de CEP
- Campos obrigatórios

### Menor de Idade
- Detecção automática por data de nascimento
- Campos obrigatórios para responsável

## 🚨 Segurança

### Medidas Implementadas
- **Rate Limiting**: 100 req/15min geral, 5 req/15min para login
- **Helmet**: Headers de segurança
- **CORS**: Configurado para frontend específico
- **JWT**: Tokens com expiração
- **Hash de Senhas**: bcrypt com salt
- **Validação de Entrada**: Sanitização de dados

## 📝 Usuários Padrão (Seed)

Após executar o seed, os seguintes usuários estarão disponíveis:

```
Admin:
- Email: admin@cide.com.br
- Senha: admin123

Gestor:
- Email: gestor@cide.com.br  
- Senha: gestor123

Operador:
- Email: operador@cide.com.br
- Senha: operador123
```

## 🛠️ Scripts Disponíveis

```bash
npm run dev          # Desenvolvimento com hot reload
npm run build        # Build para produção
npm start            # Executar produção
npm run db:generate  # Gerar cliente Prisma
npm run db:push      # Aplicar schema ao banco
npm run db:migrate   # Criar migrações
npm run db:seed      # Executar seed
npm test             # Executar testes
```

## 📂 Estrutura do Projeto

```
src/
├── config/
│   └── database.ts          # Configuração Prisma
├── controllers/
│   ├── authController.ts    # Autenticação e usuários
│   ├── estagiarioController.ts
│   ├── jovemAprendizController.ts
│   ├── empresaController.ts
│   ├── instituicaoEnsinoController.ts
│   └── supervisorController.ts
├── middleware/
│   └── auth.ts              # Autenticação JWT
├── routes/
│   ├── auth.ts
│   ├── estagiarios.ts
│   ├── jovensAprendizes.ts
│   ├── empresas.ts
│   ├── instituicoesEnsino.ts
│   ├── supervisores.ts
│   └── index.ts
├── scripts/
│   └── seed.ts              # Dados iniciais
├── utils/
│   └── validators.ts        # Validadores
├── app.ts                   # Configuração Express
└── server.ts                # Servidor principal

prisma/
└── schema.prisma            # Schema do banco
```

## 🐛 Tratamento de Erros

O sistema implementa tratamento robusto de erros:

- **Validação de entrada**: Dados inválidos retornam 400
- **Autenticação**: Tokens inválidos retornam 401
- **Autorização**: Permissões insuficientes retornam 403
- **Recursos não encontrados**: Retornam 404
- **Conflitos**: Duplicatas retornam 409
- **Erros do servidor**: Logs detalhados, resposta genérica em produção

## 📈 Próximos Passos

### Fase 2 - Contratos
- [ ] Sistema completo de contratos de estágio
- [ ] Geração de PDFs com templates
- [ ] Termos aditivos
- [ ] Controle de vencimentos
- [ ] Assinaturas eletrônicas

### Fase 3 - Relatórios
- [ ] Dashboard com métricas
- [ ] Relatórios personalizáveis
- [ ] Exportação Excel/PDF
- [ ] Gráficos e indicadores

### Fase 4 - Notificações
- [ ] Sistema de emails
- [ ] Notificações push
- [ ] Alertas automáticos
- [ ] Templates de comunicação

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 📞 Suporte

Para dúvidas ou suporte, entre em contato:
- Email: suporte@cide.com.br
- GitHub Issues: [Abrir Issue](https://github.com/seu-usuario/sistema-gestao-estagios/issues)

---

**Sistema de Gestão de Estágios e Aprendizagem** - Desenvolvido com ❤️ para o CIDE