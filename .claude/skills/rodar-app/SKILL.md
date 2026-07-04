---
name: rodar-app
description: Como rodar o backend (Node/Express) e o frontend (Flutter Web) do sistema Acervus localmente para validação antes de commit. Usar quando pedirem para rodar, iniciar, testar ou validar o sistema.
---

# Rodar o sistema Acervus localmente

## Backend (Node.js + Express + Prisma)

Diretório: `sistema-acervus/backend`

```bash
cd sistema-acervus/backend
rtk proxy npm install            # só na primeira vez ou após mudar package.json
rtk proxy npx prisma generate    # gera o client do Prisma
rtk proxy node index.js          # inicia a API (porta = PORT do .env, default 3000)
```

- **Não existe `npm run dev`** — o package.json não tem scripts.
- Env: usa `backend/.env` (dotenv). Produção usa `prd.env` (não tocar).
- Teste de vida: `curl http://localhost:<PORT>/ping` → `{"mensagem":"API rodando! 2.0"}`.
- Swagger disponível em `http://localhost:<PORT>/docs`.
- Requer PostgreSQL acessível conforme `DATABASE_URL` do `.env`.

## Frontend (Flutter Web)

Diretório: `sistema-acervus/frontend`

```bash
cd sistema-acervus/frontend
rtk proxy flutter pub get
rtk proxy flutter run -d chrome --web-port 3000
```

⚠️ **ATENÇÃO**: `lib/utils/app_config.dart` tem `devBaseUrl` apontando para a API de PRODUÇÃO (`https://acervus.api.customitech.com`). Para validar contra o backend local, alterar temporariamente `devBaseUrl` para `http://localhost:<PORT>` e NÃO commitar essa alteração (ou combinar com o usuário uma solução via `--dart-define`).

Build de produção: `rtk proxy flutter build web --release` (sai em `build/web`).

## Editor de contratos (subprojeto separado)

`sistema-acervus/editor_contrato_projeto/editor-contrato-server` — servidor Node independente; só rodar se a validação envolver o editor de contratos.

## Checklist de validação antes do commit

1. Backend responde em `/ping` e `/docs` carrega.
2. Frontend abre no Chrome, login funciona, telas alteradas renderizam sem erro no console.
3. `rtk git status` / `rtk git diff` para conferir que nenhuma alteração temporária (ex.: baseUrl local) vai para o commit.
