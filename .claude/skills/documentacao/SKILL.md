---
name: documentacao
description: Manter e atualizar a documentação (.MD) do sistema Acervus/CIDE. Usar ao criar features, alterar rotas da API, mudar telas do frontend ou quando o usuário pedir para atualizar/gerar documentação.
---

# Documentação do projeto Acervus

## Mapa da documentação

| Arquivo | Conteúdo | Quando atualizar |
|---|---|---|
| `sistema-acervus/README.MD` | Visão geral, stack, instalação, endpoints principais | Mudança de stack, novos módulos, novos comandos |
| `sistema-acervus/backend/README.MD` | Documentação do backend | Novas rotas, mudanças de env, migrations |
| `sistema-acervus/backend/docs/main.yaml` | Swagger/OpenAPI servido em `/docs` | SEMPRE que criar/alterar rota da API |
| `sistema-acervus/frontend/README.md` | Doc do frontend (hoje é boilerplate Flutter — precisa ser reescrito) | Novas telas, mudanças de configuração |

## Fatos reais do projeto (o README raiz está DESATUALIZADO)

- **Backend**: Node.js **JavaScript puro** (não TypeScript), Express 5, Prisma 6, PostgreSQL. Entry point: `backend/index.js`, porta via `process.env.PORT` (default 3000, produção usa 6001).
- **`backend/package.json` NÃO tem scripts** — não existe `npm run dev`. Rodar com `node index.js` ou `npx nodemon index.js`.
- Env: `backend/.env` (local) e `backend/prd.env` (produção). Contém `DATABASE_URL`, `DB_*`, `PORT`.
- **Frontend**: Flutter Web (Dart 3, Provider, GoRouter, Material 3). URLs de API em `frontend/lib/utils/app_config.dart` — atenção: `devBaseUrl` aponta para produção (`https://acervus.api.customitech.com`).
- Há um subprojeto separado: `sistema-acervus/editor_contrato_projeto/` (editor de contratos + servidor Node próprio).
- Não existe docker-compose/Makefile no repo apesar do README raiz mencionar — não documente comandos `make` como se funcionassem.

## Regras ao documentar

1. Documente o que EXISTE no código, não o que o README antigo afirma. Verifique antes de escrever.
2. Rotas novas: atualizar o Swagger (`backend/docs/main.yaml`) e a seção de endpoints do README raiz.
3. Escreva em português brasileiro, mantendo o estilo dos READMEs existentes (títulos com emoji).
4. Arquivos de correção pontuais (`correcoes_*.md`, `test_update_lists.md` no frontend) são notas históricas — não os trate como doc oficial; incorpore o que for permanente ao README e proponha remoção.
