# ACERVUS — Sistema de Controle de Obras, Livros e Acervo Pessoal

![Flutter](https://img.shields.io/badge/Flutter-Web-blue)
![Node.js](https://img.shields.io/badge/Node.js-Backend-green)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue)

Sistema para gestão de acervo pessoal: obras, livros, autores, assuntos, editoras, localização física (salas/estantes) e relatórios.

## 🛠 Tecnologias

### Backend (`backend/`)
- **Node.js (JavaScript)** + **Express 5**
- **PostgreSQL** com **pg** (pool) e **Prisma 6** (client)
- **JWT** para autenticação, **bcrypt** para senhas
- **Swagger** (`/docs`), **PDFKit**/**Puppeteer** para documentos
- Entry point: `index.js` — **não há scripts npm** (`npm run dev` não existe)

### Frontend (`frontend/`)
- **Flutter Web** (Dart 3, Material 3)
- **Provider** (estado) + **GoRouter** (rotas)
- **Design system Acervus**: Inter (google_fonts), primária índigo `#4F46E5` — tokens em `lib/theme/acervus_colors.dart`, tema em `lib/theme/app_theme.dart`
- **fl_chart** (gráficos), **flutter_quill** (editor), exportações CSV/Excel/PDF

### Subprojeto
- `editor_contrato_projeto/` — editor de contratos com servidor Node próprio (independente do sistema principal)

## ⚡ Como rodar localmente

### Backend
```bash
cd backend
npm install
npx prisma generate
node index.js          # porta = PORT do .env (default 3000)
```
- Env: `backend/.env` (o `prd.env` é de produção — não alterar)
- Teste de vida: `GET /ping` → `{"mensagem":"API rodando! 2.0"}`
- Swagger: `http://localhost:<PORT>/docs`
- ⚠️ O `.env` atual aponta o banco (`DB_HOST`) para o servidor remoto de produção

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```
- ⚠️ As URLs de API ficam em `lib/utils/app_config.dart`; o `devBaseUrl` aponta para a **API de produção**. Para usar backend local, altere temporariamente para `http://localhost:<PORT>` e **não commite**.
- Build de produção: `flutter build web --release` (sai em `build/web`)

## 📁 Estrutura do frontend

```
frontend/lib/
├── main.dart            # App + temas (AppTheme)
├── theme/               # Design system (acervus_colors, app_theme)
├── routes/app_router.dart
├── screens/             # Dashboard, Obras, Autores, Assuntos, etc.
├── widgets/             # AdminLayout (sidebar), CrudPage, CrudPagination...
├── providers/           # AuthProvider, ThemeProvider
├── services/            # Comunicação com a API
├── models/
└── utils/               # app_config.dart (URLs), validators
```

## 🎯 Funcionalidades

- **Dashboard**: totais do acervo, gráficos por assunto/subtipo, destaques com capas
- **Obras**: CRUD completo com abas (Cadastro/Resumo/Inf. Complementares), galeria de imagens, movimentações, ficha em PDF
- **Cadastros**: Autores, Assuntos, Editoras, Idiomas, Materiais, Estado de Conservação, Tipos e Subtipos de Obra
- **Localização**: Salas e Estantes
- **Relatórios**: Lista Resumida com filtros e exportação PDF

## 🎨 Design System

Baseado no mockup "Telas Acervus": Inter (títulos SemiBold), primária `#4F46E5`, sucesso `#10B981`, alerta `#F59E0B`, perigo `#EF4444`, fundo `#F8F9FB`, bordas `#E5E7EB`, cards raio 12. Sempre usar os tokens de `AcervusColors` — nunca cores hardcoded.

## 👥 Equipe

- **Desenvolvedor**: WF Soluções Inteligentes

---

**ACERVUS** © 2026
