# GV Chat Coding Guidelines

## Reuse First

- Check existing helpers, widgets, providers, services, and theme tokens before
  creating new code.
- Extend reusable components with parameters, callbacks, or builders instead of
  copying implementations.
- Prefer project-owned capability over adding third-party dependencies.

## Layering

- Widgets should not call network APIs directly.
- Keep data flow traceable:

```text
Widget -> Provider/ViewModel -> UseCase/Repository/Service -> API/Socket/Storage
```

- Add abstract classes at boundaries, not for every small implementation.

## Dependency Injection

- Add new singletons/factories in `lib/app/app_injection_module.dart`.
- Run `dart run build_runner build` after changing DI annotations or module
  methods.
- Prefer constructor injection. Avoid reading the service locator inside widgets
  unless there is no reasonable Provider/context path.
- Register boundary abstractions such as storage, socket, repositories, and API
  clients in addition to concrete implementations.

## Naming

- Files: `snake_case`
- Classes and enums: `CamelCase`
- Methods, variables, fields, and parameters: `lowerCamelCase`
- Public APIs use `///` when behavior is not obvious.

## Performance

- Avoid expensive computation in `build`.
- Use `const` where possible.
- Use lazy builders for long lists.
- Keep rebuild scopes small with focused widgets or selectors.
- Remove unused imports, code, dependencies, and assets.

## UI

- Use `gv_ui` adaptive helpers for mobile/tablet/desktop layout decisions.
- Account for safe areas, keyboard insets, and bottom system indicators.
- Keep text localized through `AppLocalizations`.
