# Acervus — Frontend (Flutter Web)

Portal web do sistema Acervus (controle de obras, livros e acervo pessoal).

## Rodar em desenvolvimento

```bash
flutter pub get
flutter run -d chrome --web-port 3000
```

⚠️ `lib/utils/app_config.dart` → `devBaseUrl` aponta para a **API de produção**. Para desenvolver contra backend local, altere temporariamente para `http://localhost:<PORT>` e não commite.

## Build de produção

```bash
flutter build web --release   # sai em build/web
```

## Arquitetura

- **Estado**: Provider (`AuthProvider`, `ThemeProvider`)
- **Rotas**: GoRouter (`lib/routes/app_router.dart`) — `/login` + ShellRoute `/admin/*` dentro do `AdminLayout` (sidebar)
- **Design system**: tokens em `lib/theme/acervus_colors.dart`, tema Material 3 + Inter em `lib/theme/app_theme.dart`. Use sempre `AcervusColors.*`; não hardcode cores.
- **Componentes CRUD**: `CrudPage`, `CrudHeader`, `CrudFormContainer`, `CrudPagination` (paginação numerada em pills), `CustomTextField`, `CustomDropdown`
- **Serviços**: `lib/services/*` fazem as chamadas HTTP à API

## Padrão de tela (mockup "Telas Acervus")

1. Cabeçalho de página: título 22/SemiBold + subtítulo + botão primário à direita ("+ Novo ...")
2. Card branco (raio 12, borda `#E5E7EB`) com stats/busca/filtros
3. Lista em cards brancos com pills de status/ID
4. Paginação numerada (`CrudPagination`)
