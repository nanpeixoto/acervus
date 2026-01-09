# Sistema de Gestão de Estágios e Aprendizagem - CIDE

![Sistema CIDE](https://img.shields.io/badge/CIDE-Sistema%20de%20Estágios-blue)
![Flutter](https://img.shields.io/badge/Flutter-Web-blue)
![Node.js](https://img.shields.io/badge/Node.js-Backend-green)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue)
![Docker](https://img.shields.io/badge/Docker-Containerized-blue)

Sistema completo para gerenciamento de estágios, jovens aprendizes, empresas e instituições de ensino. Desenvolvido para o **Centro de Integração e Desenvolvimento Educacional (CIDE)**.

## 📋 Índice

- [Características](#-características)
- [Tecnologias](#-tecnologias)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação Rápida](#-instalação-rápida)
- [Configuração Manual](#-configuração-manual)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Funcionalidades](#-funcionalidades)
- [API Documentation](#-api-documentation)
- [Uso do Sistema](#-uso-do-sistema)
- [Deploy](#-deploy)
- [Contribuição](#-contribuição)
- [Licença](#-licença)

## 🚀 Características

- **Sistema Unificado**: Portal único com acesso interno (administrativo) e externo (público)
- **Multi-perfil**: Suporte para estagiários, jovens aprendizes, empresas, instituições e administradores
- **Gestão Completa de Contratos**: Criação, edição, termos aditivos e geração de PDFs
- **Dashboard Administrativo**: Relatórios e métricas em tempo real
- **Validações Automáticas**: CPF, CNPJ, integração com Receita Federal
- **Responsivo**: Interface adaptável para desktop, tablet e mobile
- **Segurança**: Autenticação JWT, controle de permissões por perfil

## 🛠 Tecnologias

### Backend
- **Node.js** + **TypeScript** + **Express**
- **PostgreSQL** com **Prisma ORM**
- **JWT** para autenticação
- **bcrypt** para hash de senhas
- **PDFKit** para geração de documentos
- **Joi** para validação de dados

### Frontend
- **Flutter Web** com **Dart**
- **Provider** para gerenciamento de estado
- **GoRouter** para navegação
- **HTTP** para comunicação com API
- **Material Design 3**

### DevOps & Deploy
- **Docker** + **Docker Compose**
- **Nginx** como proxy reverso
- **GitHub Actions** para CI/CD (configurável)

## 📦 Pré-requisitos

### Para executar com Docker (Recomendado)
- **Docker** 20.10+
- **Docker Compose** 2.0+
- **Git**

### Para desenvolvimento local
- **Node.js** 18+
- **PostgreSQL** 13+
- **Flutter** 3.10+
- **Dart** 3.0+

## ⚡ Instalação Rápida

### 1. Clone o repositório
```bash
git clone https://github.com/seu-usuario/sistema-estagio-cide.git
cd sistema-estagio-cide
```

### 2. Configure e inicie o sistema
```bash
# Usando nosso script automatizado
make setup

# Ou executando diretamente
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 3. Acesse o sistema
- **Frontend**: http://localhost
- **Backend API**: http://localhost:3001
- **Banco de dados**: localhost:5432

### 4. Login administrativo padrão
- **Email**: admin@cide.com.br
- **Senha**: admin123

## 🔧 Configuração Manual

### Backend

1. **Navegue para o diretório do backend**
```bash
cd backend
```

2. **Instale as dependências**
```bash
npm install
```

3. **Configure o banco de dados**
```bash
# Copie o arquivo de ambiente
cp .env.example .env

# Configure suas variáveis no .env
# DATABASE_URL="postgresql://usuario:senha@localhost:5432/sistema_estagio"
# JWT_SECRET="seu_jwt_secret_aqui"
```

4. **Execute as migrations**
```bash
npx prisma migrate deploy
npx prisma generate
```

5. **Execute o seed inicial**
```bash
npm run seed
```

6. **Inicie o servidor**
```bash
npm run dev
```

### Frontend

1. **Navegue para o diretório do frontend**
```bash
cd frontend
```

2. **Instale as dependências**
```bash
flutter pub get
```

3. **Execute o aplicativo**
```bash
flutter run -d chrome --web-port 3000
```

## 📁 Estrutura do Projeto

```
sistema-estagio-cide/
├── backend/                 # API Node.js + TypeScript
│   ├── src/
│   │   ├── controllers/     # Controladores das rotas
│   │   ├── middleware/      # Middlewares (auth, error handling)
│   │   ├── models/          # Modelos TypeScript
│   │   ├── routes/          # Definição das rotas
│   │   ├── services/        # Lógica de negócio
│   │   ├── utils/           # Utilitários e validações
│   │   └── server.ts        # Servidor principal
│   ├── prisma/
│   │   ├── schema.prisma    # Schema do banco
│   │   └── migrations/      # Migrations
│   ├── uploads/             # Arquivos enviados
│   └── package.json
├── frontend/                # App Flutter Web
│   ├── lib/
│   │   ├── models/          # Modelos de dados
│   │   ├── providers/       # Gerenciamento de estado
│   │   ├── screens/         # Telas do aplicativo
│   │   ├── services/        # Comunicação com API
│   │   ├── widgets/         # Widgets reutilizáveis
│   │   ├── routes/          # Configuração de rotas
│   │   ├── theme/           # Tema e estilos
│   │   └── main.dart        # App principal
│   └── pubspec.yaml
├── scripts/                 # Scripts de configuração
│   ├── setup.sh            # Setup automatizado
│   └── init-db.sql         # Inicialização do banco
├── docker-compose.yml       # Orquestração dos containers
├── Makefile                # Comandos úteis
└── README.md               # Esta documentação
```

## 🎯 Funcionalidades

### Sistema Público (Sem Login)
- ✅ **Portal de Acesso**: Página inicial com informações do CIDE
- ✅ **Cadastro de Estagiários**: Formulário completo multi-etapas
- ✅ **Cadastro de Jovens Aprendizes**: Registro com validações específicas
- ✅ **Cadastro de Empresas**: Integração com CNPJ da Receita Federal
- ✅ **Cadastro de Instituições**: Registro de escolas e universidades
- ✅ **Busca de Vagas**: Visualização de oportunidades disponíveis

### Sistema Administrativo (Com Login)
- ✅ **Dashboard**: Métricas e indicadores em tempo real
- ✅ **Gestão de Usuários**: CRUD completo de todos os perfis
- ✅ **Gestão de Contratos**: Criação, edição e controle de vigência
- ✅ **Termos Aditivos**: Alterações contratuais com histórico
- ✅ **Geração de Documentos**: PDFs automáticos dos contratos
- ✅ **Controle de Vagas**: Publicação e gerenciamento
- ✅ **Relatórios**: Exportação de dados e estatísticas
- ✅ **Alertas**: Notificações de contratos a vencer

### Funcionalidades por Perfil

#### 👤 Estagiário/Jovem Aprendiz
- Visualizar perfil e contratos
- Atualizar dados pessoais
- Acessar documentos
- Candidatar-se a vagas

#### 🏢 Empresa
- Gerenciar vagas
- Visualizar candidatos
- Acompanhar contratos ativos
- Cadastrar supervisores

#### 🎓 Instituição de Ensino
- Visualizar alunos em estágio
- Acompanhar contratos
- Cadastrar cursos
- Designar orientadores

#### 👨‍💼 Administrador/Colaborador
- Acesso completo ao sistema
- Gestão de todos os módulos
- Relatórios e dashboards
- Configurações do sistema

## 📚 API Documentation

### Principais Endpoints

#### Autenticação
```http
POST /api/auth/login
POST /api/auth/registro/estagiario
POST /api/auth/registro/empresa
```

#### Estagiários
```http
GET    /api/estagiarios          # Listar com filtros
GET    /api/estagiarios/:id      # Buscar por ID
PUT    /api/estagiarios/:id      # Atualizar
DELETE /api/estagiarios/:id      # Deletar
```

#### Contratos
```http
GET  /api/contratos             # Listar contratos
POST /api/contratos             # Criar contrato
GET  /api/contratos/:id/pdf     # Gerar PDF
PUT  /api/contratos/:id         # Atualizar
```

#### Empresas
```http
GET  /api/empresas              # Listar empresas
POST /api/empresas/registro     # Registro público
PUT  /api/empresas/:id          # Atualizar
```

### Autenticação
```bash
# Todas as rotas protegidas requerem header:
Authorization: Bearer {jwt_token}
```

## 💡 Uso do Sistema

### Para Administradores

1. **Acesse o painel administrativo**
   - URL: http://localhost/login
   - Use as credenciais padrão ou crie um novo usuário

2. **Gerencie cadastros**
   - Visualize e edite estagiários, empresas e instituições
   - Aprove ou rejeite novos cadastros

3. **Crie contratos**
   - Selecione empresa, estudante e instituição
   - Defina termos, valores e vigência
   - Gere documentos automaticamente

4. **Acompanhe métricas**
   - Dashboard com indicadores
   - Relatórios de performance
   - Alertas de vencimento

### Para Usuários Finais

1. **Cadastre-se pelo portal público**
   - Acesse http://localhost
   - Escolha seu perfil (estagiário, empresa, etc.)
   - Preencha o formulário completo

2. **Gerencie seu perfil**
   - Faça login após aprovação
   - Atualize dados quando necessário
   - Acompanhe contratos ativos

## 🚀 Deploy

### Deploy com Docker (Produção)

1. **Configure variáveis de ambiente**
```bash
# Copie e configure o .env para produção
cp backend/.env.example backend/.env
# Configure DATABASE_URL, JWT_SECRET, etc.
```

2. **Execute o deploy**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Deploy Manual

1. **Backend (Node.js)**
```bash
cd backend
npm ci --only=production
npm run build
npm run migrate
npm start
```

2. **Frontend (Flutter Web)**
```bash
cd frontend
flutter build web --release
# Servir pasta build/web com nginx ou servidor de sua escolha
```

## 🛠 Comandos Úteis

```bash
# Iniciar todos os serviços
make start

# Parar todos os serviços
make stop

# Ver logs em tempo real
make logs

# Resetar banco de dados (CUIDADO!)
make reset-db

# Fazer backup do banco
make backup-db

# Rebuild completo
make rebuild

# Executar migrations
make migrate

# Executar seed
make seed

# Ver status dos serviços
make status

# Ver todos os comandos disponíveis
make help
```

## 🔍 Troubleshooting

### Problemas Comuns

**1. Erro de conexão com banco**
```bash
# Verifique se o PostgreSQL está rodando
make status

# Recrie o container do banco
docker-compose restart postgres
```

**2. Erro de migração**
```bash
# Execute as migrations manualmente
make migrate

# Se necessário, resete o banco
make reset-db
```

**3. Problemas de permissão**
```bash
# Dê permissão aos scripts
chmod +x scripts/*.sh

# Execute como administrador se necessário
sudo make setup
```

**4. Frontend não carrega**
```bash
# Verifique se o backend está rodando
curl http://localhost:3001/health

# Rebuild do frontend
docker-compose build frontend
```

## 📊 Monitoramento

### Logs
```bash
# Logs gerais
docker-compose logs -f

# Logs específicos
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres
```

### Health Checks
- **Backend**: http://localhost:3001/health
- **Frontend**: http://localhost (deve carregar a página)
- **Banco**: `psql -h localhost -U sistema_estagio -d sistema_estagio`

## 🤝 Contribuição

1. **Fork o projeto**
2. **Crie uma branch para sua feature**
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit suas mudanças**
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. **Push para a branch**
   ```bash
   git push origin feature/AmazingFeature
   ```
5. **Abra um Pull Request**

### Padrões de Código

- **Backend**: Siga os padrões ESLint configurados
- **Frontend**: Use as convenções do Dart/Flutter
- **Commits**: Use Conventional Commits
- **Documentação**: Mantenha README e comentários atualizados

## 📋 Roadmap

### Próximas Funcionalidades
- [ ] Sistema de notificações por email
- [ ] Integração com WhatsApp Business
- [ ] App mobile nativo (iOS/Android)
- [ ] Relatórios avançados com gráficos
- [ ] Sistema de avaliação de estagiários
- [ ] Integração com sistemas externos (ERP)
- [ ] Assinatura digital de contratos
- [ ] Portal do candidato com status de processo seletivo

### Melhorias Técnicas
- [ ] Testes automatizados (Jest + Flutter Test)
- [ ] CI/CD com GitHub Actions
- [ ] Monitoramento com Grafana
- [ ] Cache com Redis
- [ ] Upload de arquivos para S3
- [ ] Logs estruturados
- [ ] Documentação OpenAPI/Swagger

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 📞 Suporte

Para suporte técnico ou dúvidas sobre o sistema:

- **Email**: 
- **Issues**: [GitHub Issues](https://github.com/seu-usuario/sistema-estagio-cide/issues)
- **Documentação**: Este README e comentários no código

## 👥 Equipe

- **Desenvolvedor Principal**: WF Soluções Inteligentes
- **CIDE**: Centro de Integração e Desenvolvimento Educacional

---

**Sistema de Gestão de Estágios - CIDE** © 2025. Desenvolvido com ❤️ para conectar talentos às oportunidades.