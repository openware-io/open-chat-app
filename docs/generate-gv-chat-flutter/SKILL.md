---
name: generate-gv-chat-flutter
description: Enforce GV Chat's existing Flutter architecture, localization, responsive layout, reusable UI, list performance, state management, and validation conventions. Use whenever generating or modifying Dart/Flutter frontend code for gv_chat_app from backend requirements, API changes, UI requests, bug fixes, or AI-produced patches.
---

# Generate GV Chat Flutter Code

Generate the smallest production-ready change that fits the existing project. Preserve current behavior outside the requested scope and follow nearby code style.

Before editing, read [references/project-conventions.md](references/project-conventions.md). Inspect the relevant existing screen, widget, provider, repository, API client, tests, and shared helpers before creating anything new.

## Workflow

1. Locate existing implementations with `rg` and reuse them.
2. Trace the required data flow from UI to its boundary.
3. Make a minimal change without unrelated refactoring or cleanup.
4. Regenerate only the artifacts affected by source changes.
5. Format, analyze, test, and inspect the final diff.

## Preserve Architecture

Keep this direction:

```text
Widget -> Provider/ViewModel -> Repository/Service -> API/Socket/Storage
```

- Never call HTTP, socket, database, or shared-preference APIs directly from a widget.
- Put app-wide construction in `lib/app/app_injection_module.dart` and startup wiring in `lib/app/app_dependencies.dart`.
- Reuse existing repositories, providers, coordinators, routes, models, and helpers before adding new abstractions.
- Keep raw `Map`/JSON parsing at API or model boundaries. Prefer typed models inside providers and widgets.
- Do not add a dependency, architectural layer, or broad abstraction without explicit approval.

## Build Performant Collections

- Use `ListView.builder`, `GridView.builder`, `SliverList.builder`, or equivalent lazy builders for dynamic, paginated, remote, or potentially long collections.
- Use `Column`, `Wrap`, or literal `children` only for small, fixed collections.
- Never render a server collection with `SingleChildScrollView` plus a large `Column`.
- Preserve pagination, loading-more, empty, error, and retry states.
- Avoid sorting, parsing, filtering, media decoding, or other expensive work inside `build` or an item builder.
- Keep rebuild scope small. Use focused widgets, `Selector`, or `context.select` when the surrounding screen need not rebuild.
- Add stable keys when list item identity affects state, animations, text fields, or media playback.

## Use Responsive Project Dimensions

- Do not scatter hard-coded pixel values for page padding, gaps, radii, typography, navigation heights, card widths, or desktop constraints.
- Use `GvSpacing`, `GvRadii`, `GvLayout`, `GvTypography`, existing theme styles, and nearby reusable components.
- Use `LayoutBuilder`, constraints, `MediaQuery.sizeOf`, `GvBreakpoints`, `context.gvWindowClass`, or `GvAdaptiveBuilder` for layout decisions.
- Compose compact, medium, and expanded layouts instead of multiplying every size by screen width.
- Allow fixed logical sizes only when semantically fixed, such as icon size, minimum touch target, avatar size, divider thickness, or bounded media thumbnails. Reuse an existing constant or define one named local constant with a clear purpose.
- Support safe areas, keyboard insets, text scaling, narrow phones, tablets, desktop widths, light mode, and dark mode.

## Reuse UI And Theme

- Search `packages/gv_ui`, `lib/widgets`, and adjacent screens before creating a widget.
- Use `AppColors.*.resolveFrom(context)` and `GvTypography`; do not introduce isolated colors or text styles when a semantic token exists.
- Use shared loading, empty, error, dialog, navigation, input, card, and toast components where available.
- Use `CachedNetworkImage`, existing media URL resolution, and existing authenticated media headers for remote media.
- Keep user-facing interactions accessible with meaningful labels, tooltips, semantics, and adequate touch targets.

## Localize Every User-Facing String

- Never hard-code visible text in widgets, dialogs, toasts, validation messages, empty states, tooltips, or route errors.
- Add every string to both `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`.
- Read strings through `AppLocalizations.of(context)!`.
- Reuse an existing localization key when its meaning matches; do not create near-duplicate wording.
- Regenerate localization output after ARB changes. Never edit generated localization Dart files as the source of truth.

## Handle State And Async Work Safely

- Do not perform network or storage work from `build`.
- Guard UI updates and navigation after `await` with `mounted` or `context.mounted`.
- Cancel timers, subscriptions, controllers, and listeners in `dispose`.
- Keep account- and server-scoped data isolated. Do not introduce global cache keys for user data.
- Preserve deduplication, ordering, watermarks, retries, and atomic persistence in message flows.
- Do not swallow failures with an empty `catch`. Log, surface, retry, or intentionally map the failure according to the surrounding pattern.

## Respect Generated Code

- Change Retrofit declarations, Drift schemas, injectable modules, ARB files, or other source definitions first.
- Regenerate matching `*.g.dart`, localization, database, or dependency-injection outputs with the project's existing generators.
- Do not hand-edit a generated file unless the repository explicitly treats it as maintained source and the user approves.
- Keep generated artifacts in the same change when this repository commits them.

## Validate Before Handoff

Run checks proportional to the change, with this as the default minimum:

```text
dart format <changed Dart files>
dart analyze lib test
flutter test
git diff --check
```

Also run the affected generator and targeted widget/database/provider tests when applicable. Report any remaining warning separately and do not claim success if a new analyzer error, failing test, unresolved generated output, or merge marker remains.

## Prohibited Shortcuts

- Do not replace a typed implementation with raw dynamic maps merely to make compilation easier.
- Do not resolve a semantic Git conflict by blindly choosing an entire side.
- Do not remove existing product behavior while implementing an adjacent feature unless explicitly requested.
- Do not perform unrelated optimization, renaming, extraction, reformatting, or architecture migration.
- Do not silently invent backend fields, routes, permissions, business rules, or default values.
- When the contract or product behavior is genuinely ambiguous, stop and ask one focused question.
