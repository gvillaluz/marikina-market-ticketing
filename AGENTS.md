# Frontend rules (Marikina Market, React + TypeScript)

## Architecture

- Layers: api → hooks → UI. The api layer makes requests, hooks own data fetching and state, and UI components only render. No fetch or axios calls in components or hooks outside the api layer.
- Follow existing patterns for interface and type naming, folder structure, and paging (offset, hasMore, total).
- Feature-based folders: each feature owns its api, hooks, components, and pages, and exports only what others need through its `index.ts`. Features don't import another feature's internal files.
- Shared pieces used by two or more features go in the shared components folder.
- Don't add new patterns, folders, or libraries without asking first.
- Don't create api folder inside a feature folder. all api files should be in the api layer.
- All states of a page or component should be always extracted as a hook.

## Security

- Never trust the user. Treat everything that comes from them as untrusted: form fields, URL params, query strings, uploaded files, and anything stored in the browser (localStorage, cookies, state). A user can edit any of it, so validate and sanitize it, and don't make security decisions in the UI.
- Never trust the UI for authorization. Hiding a button or route is only a convenience, and the server enforces access. Don't skip a backend check because the UI hides something.
- Never hardcode secrets, API keys, tokens, or passwords. Use environment variables, and only for values that are safe to expose in a browser bundle.
- Don't store tokens or sensitive personal data (ID numbers, addresses) in localStorage, sessionStorage, or logs. Follow the existing auth pattern.
- Never use `dangerouslySetInnerHTML` or build HTML from user or API data. Render values as text.
- Don't log sensitive data with console.log, and remove debug logs before finishing.
- Validate user input in forms for good UX, but remember the server validates again.
- Keep role-based UI (routes, sidebar items, actions) consistent with the roles the backend allows.

## Error handling

- If the API response has an error message, display it.
- If it doesn't, display a fallback message written in the UI. Never show raw exceptions, stack traces, or an empty failure.
- Every request-driven screen handles loading, empty, and error states.

## Code style

- Simple code: small functions, clear names, no speculative abstractions, no duplicated logic.
- One component per file. Each file has one function that returns TSX.
- Extract any TSX that belongs to a file into its own component, and extract any repeated UI into a component.
- Each component has its own CSS Module file. Use existing CSS variables, and avoid inline styles.
- No `any`. Type API responses and props.
- Always format the file using the formatter.

## Workflow

- Before coding: read the relevant files, then give a short plan (files to change, approach, questions). Wait for my OK.
- For every feature, start with a plan and wait for my approval. Skip the plan only for trivial single-file edits.
- Run `npm run build` and fix errors and new warnings before finishing.
- Stay inside the files and areas I name. If something outside needs changing, stop and ask.
- Unrelated bugs: list them at the end, don't fix them.

## When finished

- Summarize changes per file and what I should test manually.

## Verification
- `npm run build` is required before finishing.
- Dev server: `npm run dev` (default port 5173, or whichever your project uses). Start it only when I ask or when a visual check is needed, and stop it afterward.
- Never leave background processes running.

## Styling
- This project uses CSS Modules with CSS variables from the global stylesheet. Don't introduce Tailwind or any other styling library, and don't convert existing components.
- Each component has its own CSS Module file, named after it (`Component.module.css`). Don't use inline styles except for values that must be computed at runtime.
- Global styles and design tokens live in one place (the global stylesheet). Colors, spacing, radius, shadows, and font sizes come from CSS variables. Don't hard-code hex values or magic numbers when a variable exists.
- Before writing new styles, check whether the same rules already exist. If a style appears in two or more places, extract it:
  - A repeated UI element becomes a shared component (preferred).
  - A repeated style on non-component elements moves to the global stylesheet or a shared CSS Module.
- Keep CSS Modules short and readable. Use class names that describe the role (`.card`, `.header`), not the look (`.blueBox`). Order properties consistently: layout, spacing, sizing, typography, color, state.
- Build mobile-first, and put breakpoints at the bottom of the file. Keep hover, focus, and disabled states for every interactive element.
- If a variable is missing, add it to the global stylesheet and tell me, instead of repeating a one-off value.
- Don't add a styling library or plugin without asking first.
- Don't do project-wide styling refactors or migrations. Stay inside the files I name.
