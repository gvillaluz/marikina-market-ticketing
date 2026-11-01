# Mobile rules (Marikina Market, Flutter)

## Workflow

- Before any feature work, read `../feature-workflow.md` and follow it.
- Commands for this repo: format `dart format` on changed files, analyze `flutter analyze`, tests `flutter test`.
- Don't add a package, state management library, or navigation library without asking first.
- Run the app with `flutter run` only when I ask or when a visual check is needed. Stop it afterward. Never leave background processes running.

## Architecture

- Feature-based structure: `lib/features/<feature>/` with `data/`, `domain/`, and `presentation/`. Shared code lives in `lib/core/`.
- Dependencies point inward: presentation → domain ← data. Presentation never imports data. Domain never imports Flutter or data.
- Shared code goes in `lib/core/` only when two or more features use it. Don't move feature code into core speculatively.
- Each feature exposes only what others need. Don't import another feature's internal files.
- Follow the existing patterns in the feature you're touching for naming, folder layout, and paging (offset, hasMore, total).
- Don't add new patterns, folders, or packages without asking first.

### data/

- `data_sources/`: remote (API calls) and local (storage). Only these talk to the network or device storage.
- `models/`: one model per file, with `fromJson` and `toEntity`. Models never leak into domain or presentation.
- `repositories/`: implementations of the domain repository interfaces. Keep them fat: fetching, mapping, caching, and converting exceptions into failures. No business rules here.

### domain/

- `entities/`: plain Dart classes, one per file. No JSON, no Flutter, no logic beyond simple derived values.
- `repositories/`: abstract interfaces only, one per file.
- `use_cases/`: thin. Each use case, one per file, calls one repository method and returns its result. No branching business logic beyond what the feature requires.

### presentation/

- `pages/`: one page per file. Pages compose widgets and read state from bloc. No API calls, no business logic.
- `widgets/`: widgets extracted from a page, used by that page or the feature. Shared widgets go in `core/`.
- `bloc/`: one folder per bloc, with separate event, state, and bloc files. Blocs call use cases, never data sources or repositories directly.

## Security

- Never trust the user. Treat form fields, deep link parameters, uploaded files, and anything stored on the device as untrusted. Validate and sanitize them.
- Never trust the UI for authorization. Hiding a screen or button is convenience only. The backend enforces access.
- Keep role-based UI (routes, menu items, actions) consistent with the roles the backend allows.
- Never hardcode secrets, API keys, tokens, or passwords. Use the project's existing config approach, and only for values safe to ship in the app.
- Store tokens only through the secure storage in `core/storage`. Don't put tokens or sensitive personal data (ID numbers, addresses) in plain preferences, logs, or persisted state.
- Don't print sensitive data with `print` or `debugPrint`. Remove debug logs before finishing.
- Validate form input for good UX, but the server validates again.

## Error handling

- Convert exceptions into domain failures in the repository implementation. Presentation never sees raw exceptions, stack traces, or network errors.
- If the failure carries a server error message, show it. If it doesn't, show a fallback message written in the UI.
- Every screen driven by data handles loading, empty, and error states in the bloc state, not in widgets.

## Code style

- Simple code: small functions, clear names, no speculative abstractions, no duplicated logic. Follow the pattern of the existing files in the feature.
- Don't overengineer. Be highly confident before adding abstraction.
- One class per file. Name files in snake_case after their class. The only exception: a `StatefulWidget` and its `State` class may share one file.
- Extract any widget that is part of a page into `widgets/`. Extract any repeated UI into a widget.
- No `dynamic`. Type all models, entities, bloc events, and bloc states.
- Use the theme in `core/theme` for colors, text styles, and spacing. Don't hardcode values when a theme value exists.
- If a theme value is missing, add it to `core/theme` and tell me, instead of repeating a one-off value.

## Styling

- Styling comes from the theme in `core/theme`. Don't style widgets with hardcoded values when a theme value exists.
- Don't add a styling package without asking first. Don't do project-wide style refactors.
- Keep widgets small and readable. Extract a widget once it has its own layout logic or is repeated.
- Support the device sizes the app already targets. Check the layout on a narrow screen before finishing.
- Keep pressed, disabled, and loading states for every interactive element.

## Finishing

- Run `dart format`, `flutter analyze`, and `flutter test` before saying the task is done. Fix any new issues.
- Summarize changes per file and list what I should test manually.
- List unrelated bugs at the end. Don't fix them.
