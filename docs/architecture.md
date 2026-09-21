# GV Chat Flutter Architecture

## Direction

This repository uses a lightweight Flutter monorepo:

```text
lib/                  # Main app: startup, routing, providers, screens
packages/gv_core/     # Non-UI foundations
packages/gv_ui/       # Shared UI foundations and adaptive helpers
```

Keep the main app focused on composition. Move reusable, stable foundations into
packages only after the boundary is clear.

## Package Roles

### gv_core

Use `gv_core` for non-UI shared code:

- result and error types
- extensions
- constants and asset references
- repository, storage, socket, and platform-facing abstractions
- generated API/model code when the API contract is ready

`gv_core` must not depend on Flutter widgets, routes, or page state.

### gv_ui

Use `gv_ui` for reusable presentation foundations:

- design tokens and themes
- adaptive layout helpers
- shared widgets, dialogs, inputs, navigation primitives
- loading, empty, and error states

Feature-specific widgets should stay in the app until they are reused by more
than one area.

## Main App

The main app keeps:

- `main.dart`
- app dependency composition
- app routing
- provider registration
- screens and feature assembly
- platform startup behavior

Use `lib/app/app_dependencies.dart` as the composition root. Add dependencies
through the generated dependency injection module first.

## Dependency Injection

The app uses `get_it` as the runtime container and `injectable` +
`build_runner` to generate registration code.

```text
lib/app/app_service_locator.dart        # global container and generated init
lib/app/app_injection_module.dart       # dependency factory methods
lib/app/app_service_locator.config.dart # generated registration code
lib/app/app_dependencies.dart           # startup orchestration
```

Rules:

- Register app-wide dependencies in `AppInjectionModule`.
- Run code generation after changing the module.
- Keep `AppDependencies` focused on startup initialization and provider lists.
- Register concrete implementations and stable abstractions together when a
  dependency crosses a boundary.
- Keep Provider for widget rebuilds; use `get_it` for object construction and
  non-widget dependency lookup.

## Text And Localization

Do not hard-code user-facing text in pages, widgets, toasts, dialogs, or route
error states. Add text to:

```text
lib/l10n/app_en.arb
lib/l10n/app_zh.arb
```

Then consume it through:

```dart
AppLocalizations.of(context)!.someKey
```

If generated localization files are committed, update them together with the ARB
change or run Flutter localization generation before submitting.

## Adaptive Layout

Use the shared breakpoints from `gv_ui`:

```text
compact:  < 600
medium:   600 - 1023
expanded: >= 1024
```

Prefer adaptive composition over scattered width checks inside screens.

## Migration Rules

- Keep the current technology-type organization unless a module becomes too
  large to navigate.
- Move code to `gv_core` or `gv_ui` only when it is reusable or forms a stable
  boundary.
- Do not move large business modules only to make the folder tree look cleaner.
- Add abstractions at external boundaries: repository, socket, storage, API, and
  platform services.
- Keep Provider classes focused on UI state and user intent; move API, socket,
  cache, and paging orchestration into services or repositories over time.
