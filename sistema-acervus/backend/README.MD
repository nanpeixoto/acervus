# Acervus — Backend (Node.js + Express)

API REST do sistema Acervus (controle de obras, livros e acervo pessoal).

## Stack

- **Node.js (JavaScript)** + **Express 5**
- **PostgreSQL** via **pg** (`db.js` usa as variáveis `DB_*` do `.env`)
- **Prisma 6** (client) — schema em `prisma/`
- **JWT** (`auth.js`) + **bcrypt**
- **Swagger** em `/docs` (spec em `docs/main.yaml`)
- **PDFKit** / **Puppeteer** para geração de documentos, **Nodemailer** para e-mails

## Rodar localmente

```bash
npm install
npx prisma generate
node index.js        # porta = PORT do .env (default 3000)
```

- **Não existem scripts npm** — não há `npm run dev`; use `node index.js` (ou `npx nodemon index.js`).
- Env: `.env` (desenvolvimento) e `prd.env` (produção — não alterar).
- ⚠️ O `.env` atual aponta `DB_HOST` para o banco remoto de produção.

## Verificação

- `GET /ping` → `{"mensagem":"API rodando! 2.0"}`
- Swagger: `http://localhost:<PORT>/docs`

## Estrutura

```
backend/
├── index.js          # servidor Express e registro das rotas
├── auth.js           # middlewares JWT (verificarToken, tokenOpcional)
├── db.js             # pool PostgreSQL (variáveis DB_*)
├── routes/           # rotas da API (obras, autores, assuntos, ...)
├── services/         # lógica de negócio
├── docs/main.yaml    # spec OpenAPI servida em /docs
├── prisma/           # schema Prisma
├── uploads/          # arquivos enviados (servido em /uploads)
└── utils/            # logger e utilitários
```

## Regra de documentação

Ao criar/alterar rotas, atualize `docs/main.yaml` e a seção de funcionalidades do README raiz.
