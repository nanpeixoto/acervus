---
name: usar-rtk
description: Uso obrigatório do RTK (Rust Token Killer) para todos os comandos de terminal neste projeto. Consultar sempre que for executar git, npm, flutter, docker, find, ls ou qualquer comando shell.
---

# Usar RTK sempre

Neste projeto, TODO comando de terminal deve passar pelo RTK para economizar tokens (60–90% de economia).

## Regra geral

- Prefixe comandos com `rtk` quando houver filtro dedicado: `rtk git status`, `rtk git diff`, `rtk git log`.
- Para comandos sem filtro dedicado, use `rtk proxy <cmd>`: `rtk proxy ls`, `rtk proxy find ...`, `rtk proxy flutter doctor`.
- NUNCA execute comandos crus sem RTK, exceto se o RTK falhar (fallback permitido com aviso ao usuário).

## Comandos meta

```bash
rtk gain              # Analytics de economia de tokens
rtk gain --history    # Histórico de uso
rtk discover          # Oportunidades perdidas
rtk proxy <cmd>       # Executa comando cru (sem filtro)
```

## Verificação

Se `rtk gain` falhar com "command not found", pode haver colisão de nome com outro binário `rtk` (Rust Type Kit). Verifique com `rtk --version`.

## Observação

Um hook do Claude Code pode reescrever comandos automaticamente (`git status` → `rtk git status`). Mesmo assim, escreva os comandos já com `rtk` explicitamente para garantir.
