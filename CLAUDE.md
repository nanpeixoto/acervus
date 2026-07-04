# Acervus — Sistema de Gestão de Estágios (CIDE)

## Regra obrigatória: RTK

TODO comando de terminal deve usar RTK: `rtk git ...` para comandos com filtro, `rtk proxy <cmd>` para o resto. Detalhes na skill `usar-rtk`.

## Estrutura

- `sistema-acervus/backend` — API Node.js (JavaScript puro, Express 5, Prisma 6, PostgreSQL). Entry: `index.js`. **Sem scripts npm** — rodar com `node index.js`.
- `sistema-acervus/frontend` — Flutter Web (Provider, GoRouter, Material 3). URLs de API em `lib/utils/app_config.dart`.
- `sistema-acervus/editor_contrato_projeto` — subprojeto independente do editor de contratos (Node).

## Skills do projeto

- `usar-rtk` — regra do RTK.
- `rodar-app` — como rodar backend e frontend localmente para validação.
- `documentacao` — mapa dos .MD e regras para mantê-los (o README raiz está desatualizado em vários pontos).

## Cuidados

- `devBaseUrl` do frontend aponta para a API de PRODUÇÃO — nunca commitar alteração temporária para localhost.
- `backend/prd.env` é ambiente de produção — não modificar.
- Idioma da documentação e da UI: português brasileiro.
