# MarikinaMarketTicketing: product rules

These rules cover the whole system. Layer details live in `marikina-market-api/AGENTS.md`, `marikina-market-web/AGENTS.md`, and `marikina-market-mobile/AGENTS.md`. If a layer file and this file conflict, the layer file wins for its own layer. Layer rules never expand the user's approved scope; surface conflicts before dependent work.

## Workspace and instructions

- API repository: `marikina-market-api`; application: `MarikinaMarket.API`; tests: `MarikinaMarket.Tests`.
- React repository: `marikina-market-web`. Flutter repository: `marikina-market-mobile`.
- This is one Git repository with three application directories. Preserve each application's existing architecture, dependencies and deployment boundaries. Do not initialize nested Git repositories.
- Read this file and each affected repository's `AGENTS.md` before working.
- When starting inside a repository, explicitly read the workspace rules; do not assume the parent workspace instructions were loaded.

## Scope and approval

- Build only what I approved for the current task. If a request is outside it, stop and ask.
- Give a plan and wait for my approval before coding a feature. Skip the plan only for trivial single-file edits.
- Stay inside the files and areas I name. If something outside needs changing, stop and ask.
- Unrelated bugs: list them at the end, don't fix them.
- Don't refactor, clean up, or add features beyond the request.
- Write the simplest code that meets the approved acceptance criteria; do not add speculative abstractions, configuration, flags, or generalization for unapproved requirements; follow existing patterns before introducing new ones.
- Before asking for approval, explain the acceptance criteria and the tests in plain language, including what each test proves. I approve only when I can explain them myself.
- Approval applies to the named slice, repositories, files/areas, and acceptance criteria. Reopen the gate for material scope changes; do not re-request unchanged approval.
- Preserve all existing uncommitted work. Never overwrite, reset, discard, or clean up someone else's changes.

## Keep backend and clients in sync

- The clients are `marikina-market-web` and `marikina-market-mobile`. Both consume the API in `marikina-market-api`.
- If an API endpoint, request, or response changes, update every client that uses it in the same task.
- Identify all affected consumers before the gate. If a required consumer is outside the approved scope, stop and ask to expand the scope before making the contract change.
- Backend first when a feature changes the API. The web and mobile apps build against the agreed contract.
- End every backend task with the API contract: route, request, response, and error cases.
- Use the same terms for the same things across code, UI, and API (for example "vendor" and "stall").

## Data

- Describe schema changes. Never run migrations or touch the real database.
- Don't store sensitive data in the apps or in logs.
- E2E verification uses an explicitly identified disposable local database, never production or the real operational database. The user provisions or updates its schema separately; agents never execute migrations.
- Use only the explicitly confirmed user-provisioned disposable `marikina_market_e2e` database; never run migrations or touch operational data. Prior 35-migration/four-role setup is historical, not a current schema guarantee. Recheck prerequisites per slice and reuse valid evidence without repeating unrelated checks. Details: `evidence/local-e2e-database/`.
- Use sanitized captured data or realistic fixtures. Do not copy sensitive real records into source, test artifacts, or logs.

## Dependencies and secrets

- Ask before adding a package to any part of the system.
- Never commit secrets, connection strings, or API keys.
- Follow existing configuration and secret-storage mechanisms; do not introduce new packages or patterns without approval.

## Parent and subagent coordination

- The parent owns planning, scope approval, API contract coordination, integration verification, and the final report.
- Default to one agent for small tasks. Delegate selectively, only within explicitly approved tasks and only when delegation helps the slice.
- Keep four intended specialists: API development, Flutter development, React development, and code review. Do not add orchestration or further specialist roles without approval.
- Each delegation specifies the approved objective, allowed paths, agreed contract, acceptance criteria, dependencies, verification commands, and prohibited actions.
- Parallel work requires independent tasks and disjoint write ownership. Agree on API contracts before dependent client implementation.
- Subagents must not expand scope, spawn further agents, modify shared workflow files, install dependencies, run migrations, or commit/push.
- Subagents report changed files, checks and results, blockers, and risks. The reviewer reports findings without editing.
- The parent verifies the integrated result. Subagent reports alone do not establish completion.
- Before creating custom agent definitions, confirm their format against the installed Codex documentation or help. If it cannot be confirmed, create no agent files and report the blocker.

## Done means verified

- Don't say a task is done without evidence: run the builds and tests, read the output, and report the result.
- If something can't be verified, say so and say how I can check it.
- End with a summary of changes per file and the manual steps I should test.
- Track implementation, automated checks, and E2E evidence separately. Files, endpoints, historical logs, and passing mocked tests do not establish feature completion.
- Mark a feature slice complete only when its approved acceptance criteria and required verification pass. Otherwise report implemented/unverified or blocked, with the remaining steps.
- Record pre-existing failures separately from failures introduced by the task.
- Wait for approval before starting the next task.

## Tests and Checks

- A test that has never failed proves nothing. If a test still passes after I break the code on purpose, rewrite or delete it.
- Use captured or realistic data, not arbitrary fixtures, when possible. Sanitize captured local data before use; never copy sensitive real records into source, artifacts, or logs. Use realistic synthetic fixtures when safe captures are unavailable.
- Mock only at the outer boundary, such as external services. Don't mock the code under test.
- Hand-derive every expected value. Don't copy the output into the expected value.
- Don't weaken or delete a test just to make it pass.
- Each application's build and test commands are in its own `AGENTS.md`.
- Use existing installed dependencies. If restore/install or a missing SDK is required, report it and propose a small approved prerequisite task. Do not install packages automatically.
- Workflow/documentation-only changes use file/content validation; application builds and live E2E are not applicable when application behavior is unchanged.
- For live end-to-end checks, use the `live-check` skill.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in gvillaluz/marikina-market-ticketing (public repo: no secrets or personal data in issues). See `docs/agents/issue-tracker.md`.

### Triage labels

Default labels: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root, created only when needed. See `docs/agents/domain.md`.

## Learned rules

When I correct you or reject your approach, fix it first, then propose
a one-line rule: `N. [CATEGORY] Always/Never X, because Y.` Add it
below only after I confirm. Before proposing, check whether an existing
rule already covers it; if so, propose superseding it. Rules specific
to one app go in that app's AGENTS.md. Newer rules win conflicts.

<!-- Rules below this line -->