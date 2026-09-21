# GV Chat Flutter Project Conventions

Use this reference to map generated frontend work onto the current repository.

## Project Map

```text
lib/app/                     Dependency composition and startup wiring
lib/core/                    App colors, theme, configuration, shared helpers
lib/database/                Drift database and generated database code
lib/l10n/                    ARB sources and generated localizations
lib/models/                  Typed application and API models
lib/providers/               UI state and application orchestration
lib/repositories/            External-boundary abstractions and implementations
lib/screens/                 Feature screens and page composition
lib/services/                HTTP, generated API client, socket, push, platform services
lib/widgets/                 App-owned reusable widgets
packages/gv_core/            Reusable non-UI foundations and interfaces
packages/gv_ui/              Shared UI tokens, adaptive helpers, and primitives
test/                        Unit and widget tests
integration_test/            End-to-end Flutter tests
```

## Shared UI Sources

- Spacing: `GvSpacing` in `packages/gv_ui/lib/src/tokens/gv_tokens.dart`
- Radii: `GvRadii` in the same token file
- Navigation and desktop constraints: `GvLayout`
- Shadows: `GvShadows`
- Typography: `GvTypography` and `GvTypographyScale`
- Breakpoints: `GvBreakpoints` (`compact < 600`, `medium 600-1023`, `expanded >= 1024`)
- Adaptive context helpers: `context.gvIsCompact`, `gvIsMedium`, `gvIsExpanded`, `gvWindowClass`
- Adaptive composition: `GvAdaptiveBuilder`
- Semantic colors: `AppColors` in `lib/core/app_colors.dart`; resolve dynamic colors with `resolveFrom(context)`
- Shared components: search exports and implementations under `packages/gv_ui/lib` and `lib/widgets`

Prefer an existing token. If no token expresses the required semantic dimension, use constraints or a named feature-local constant. Do not add a global token for a one-off value.

## Localization

Source files:

```text
lib/l10n/app_en.arb
lib/l10n/app_zh.arb
```

Usage:

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.someKey)
```

After changing ARB files, run:

```text
flutter gen-l10n
```

Keep English and Chinese placeholders, descriptions, and parameter shapes aligned.

## Collection Selection

- Long or remote vertical list: `ListView.builder`
- List inside `CustomScrollView`: `SliverList.builder`
- Dynamic icon/media grid: `GridView.builder` or sliver grid
- Small fixed action set: `Row`, `Column`, or `Wrap`
- Paginated list: lazy builder plus explicit loading-more row and guarded fetch

Use `itemExtent` or `prototypeItem` only when row height is truly stable. Do not force a fixed height on variable localized text.

## State And Data Boundaries

- Access UI state with Provider using the narrowest practical watch scope.
- Put user intent and screen state in an existing Provider/ViewModel.
- Put API contracts behind a repository when that boundary already exists.
- Use `ImApi` and generated Retrofit declarations for IM HTTP operations.
- Use the socket abstraction rather than instantiating a new socket client.
- Use `LocalStorage` for preferences and `ChatDatabase`/Drift for durable chat data according to existing ownership.
- Register dependencies in `AppInjectionModule`; use `AppDependencies` for initialization and callback wiring.

## Media And Navigation

- Resolve backend media paths with the existing media URL helpers.
- Preserve authenticated media headers through the existing header helpers.
- Prefer `CachedNetworkImage` for remote thumbnails shown repeatedly.
- Reuse project routes and navigation helpers; do not duplicate route strings inside widgets.

## Generators

Run only what the change requires:

```text
flutter gen-l10n
dart run build_runner build
```

Typical triggers include:

- injectable annotations or module factories
- Retrofit declarations
- Drift tables or DAOs
- localization ARB changes

Inspect generated diffs. Unexpected large generated churn usually means the wrong SDK, generator version, or source file was used.

## Verification Checklist

- No visible string is hard-coded.
- No remote/dynamic collection eagerly builds all rows.
- No layout relies on arbitrary screen-specific pixel widths.
- No API/storage/socket call originates from a widget.
- No generated file is the only edited source of a behavior change.
- Async UI code checks lifecycle safety.
- Empty, loading, error, retry, and pagination states remain reachable.
- Light/dark and compact/expanded layouts remain usable.
- Relevant tests cover parsing, state transitions, persistence, or widget behavior.
- Formatter, analyzer, tests, and `git diff --check` pass.
