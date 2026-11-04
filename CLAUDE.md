# MarikinaMarketTicketing: Product Rules

These rules cover the whole system. Layer-specific details live in `marikina-market-api/CLAUDE.md`, `marikina-market-web/CLAUDE.md`, and `marikina-market-mobile/CLAUDE.md`.

If a layer file and this file conflict, the layer file wins for its own layer. Layer rules never expand the user's approved scope. Surface conflicts before dependent work.

## Workspace and Instructions

- API repository: `marikina-market-api`; application: `MarikinaMarket.API`; tests: `MarikinaMarket.Tests`.
- React repository: `marikina-market-web`.
- Flutter repository: `marikina-market-mobile`.
- This is one Git repository with three application directories. Preserve each application's existing architecture, dependencies, and deployment boundaries. Do not initialize nested Git repositories.
- Read this file, `roadmap.md`, `feature-workflow.md`, and each affected repository's `CLAUDE.md` before working.
- When starting inside a repository, explicitly read the workspace rules. Do not assume parent workspace instructions were loaded.
- Claude Code automatically loads applicable parent and nested `CLAUDE.md` instructions according to its instruction-loading behavior. Still verify that the required workspace and layer instructions have been considered before working.

## Scope and Approval

- Build only what is in the current phase. If a request is outside it, stop and ask.
- Follow `feature-workflow.md` for every feature. It defines the required Plan → Cut Scope → Gate → Build → End-to-end Verify process.- Give a plan and wait for my approval before coding a feature. Skip the plan only for trivial single-file edits.
- Stay inside the files and areas I name. If something outside needs changing, stop and ask.
- Unrelated bugs: list them at the end; do not fix them.
- Do not refactor, clean up, or add features beyond the request.
- Write the simplest code that meets the approved acceptance criteria. Do not add speculative abstractions, configuration, flags, or generalization for unapproved requirements. Follow existing patterns before introducing new ones.
- Approval applies to the named slice, repositories, files/areas, and acceptance criteria. Reopen the gate for material scope changes; do not request approval again for unchanged scope.
- Preserve all existing uncommitted work. Never overwrite, reset, discard, or clean up someone else's changes.
- Phase 0 is incremental: identify and report missing or unconfirmed prerequisites first, then propose one small task at a time. Do not attempt to establish the entire E2E environment at once.

## Keep Backend and Clients in Sync

- The clients are `marikina-market-web` and `marikina-market-mobile`. Both consume the API in `marikina-market-api`.
- If an API endpoint, request, or response changes, update every client that uses it in the same task.
- Identify all affected consumers before the gate. If a required consumer is outside the approved scope, stop and ask to expand the scope before making the contract change.
- Backend first when a feature changes the API. The web and mobile apps build against the agreed contract.
- End every backend task with the API contract:
  - Route
  - Request
  - Response
  - Error cases
- Use the same terms for the same things across code, UI, and API (for example, "vendor" and "stall").

## Data

- Describe schema changes. Never run migrations or touch the real database.
- Do not store sensitive data in the apps or in logs.
- E2E verification uses an explicitly identified disposable local database, never production or the real operational database.
- The user provisions or updates the disposable database schema separately. Agents must never execute migrations.
- Use sanitized captured data or realistic fixtures. Do not copy sensitive real records into source code, test artifacts, or logs.

## Dependencies and Secrets

- Ask before adding a package to any part of the system.
- Never commit secrets, connection strings, or API keys.
- Follow existing configuration and secret-storage mechanisms. Do not introduce new packages or patterns without approval.

## Parent and Subagent Coordination

- The parent agent owns planning, scope approval, API contract coordination, integration verification, and the final report.
- Default to one agent for small tasks. Delegate selectively, only within explicitly approved tasks and only when delegation helps the slice.
- Keep four intended specialists:
  1. API development
  2. Flutter development
  3. React development
  4. Code review
- Do not add orchestration or further specialist roles without approval.
- Each delegation must specify:
  - Approved objective
  - Allowed paths
  - Agreed API contract
  - Acceptance criteria
  - Dependencies
  - Verification commands
  - Prohibited actions
- Parallel work requires independent tasks and disjoint write ownership.
- Agree on API contracts before dependent client implementation.
- Subagents must not expand scope, spawn further agents, modify shared workflow files, install dependencies, run migrations, or commit/push.
- Subagents report:
  - Changed files
  - Checks and results
  - Blockers
  - Risks
- The reviewer reports findings without editing.
- The parent verifies the integrated result. Subagent reports alone do not establish completion.
- Before creating custom Claude Code agent definitions, confirm their format against the installed Claude Code documentation or help. If the format cannot be confirmed, create no agent files and report the blocker.

## Done Means Verified

- Do not say a task is done without evidence. Run the builds and tests, read the output, and report the results.
- If something cannot be verified, say so and explain how I can check it.
- End with a summary of changes per file and the manual steps I should test.
- Track implementation, automated checks, and E2E evidence separately.
- Files, endpoints, historical logs, and passing mocked tests do not establish feature completion.
- Mark a feature slice complete only when its approved acceptance criteria and required verification pass.
- Otherwise, report it as implemented/unverified or blocked, with the remaining steps.
- Record pre-existing failures separately from failures introduced by the task.
- Propose roadmap completion or advancement only with evidence.
- Wait for my approval before starting the next slice or phase.

## Learned Rules

When I correct you or reject your approach:

1. Fix the issue first.
2. Check whether an existing rule already covers the correction.
3. If an existing rule covers it, propose superseding that rule.
4. Otherwise, propose a new rule using this exact one-line format:

   `N. [CATEGORY] Always/Never X, because Y.`

5. Add the proposed rule below only after I confirm.
6. Rules specific to one application belong in that application's `AGENTS.md`.
7. Newer rules win conflicts.

1. [CODE] Always leave application code with no dead options, branches or flags after a change, because the user wants the resulting code simple, not just the edits small. Supersedes the "simplest code" line in Scope and Approval where they differ.

<!-- Rules below this line --> 

2. [COMMUNICATION] Always explain results, options and decisions in plain, non-technical language (technical detail only when asked or needed for a decision), because the user needs to understand and decide without a technical background.

