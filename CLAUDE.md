# MarikinaMarketTicketing: Product Rules

These rules cover the whole system. Layer-specific details live in `marikina-market-api/CLAUDE.md`, `marikina-market-web/CLAUDE.md`, and `marikina-market-mobile/CLAUDE.md`.

If a layer file and this file conflict, the layer file wins for its own layer. Layer rules never expand the user's approved scope. Surface conflicts before dependent work.

## Workspace and Instructions

- API repository: `marikina-market-api`; application: `MarikinaMarket.API`; tests: `MarikinaMarket.Tests`.
- React repository: `marikina-market-web`.
- Flutter repository: `marikina-market-mobile`.
- This is one Git repository with three application directories. Preserve each application's existing architecture, dependencies, and deployment boundaries. Do not initialize nested Git repositories.
- Read this file and each affected repository's `CLAUDE.md` before working.
- When starting inside a repository, explicitly read the workspace rules. Do not assume parent workspace instructions were loaded.
- Claude Code automatically loads applicable parent and nested `CLAUDE.md` instructions according to its instruction-loading behavior. Still verify that the required workspace and layer instructions have been considered before working.

## Scope and Approval

- Build only what I approved for the current task. If a request is outside it, stop and ask.
- Give a plan and wait for my approval before coding a feature. Skip the plan only for trivial single-file edits.
- Before asking for approval, explain the acceptance criteria and the tests in plain language, including what each test proves. I approve only when I can explain them myself.
- Stay inside the files and areas I name. If something outside needs changing, stop and ask.
- Unrelated bugs: list them at the end; do not fix them.
- Do not refactor, clean up, or add features beyond the request.
- Write the simplest code that meets the approved acceptance criteria. Do not add speculative abstractions, configuration, flags, or generalization for unapproved requirements. Follow existing patterns before introducing new ones.
- Approval applies to the named slice, repositories, files/areas, and acceptance criteria. Reopen the gate for material scope changes; do not request approval again for unchanged scope.
- Preserve all existing uncommitted work. Never overwrite, reset, discard, or clean up someone else's changes.

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
- Use only the explicitly confirmed user-provisioned disposable `marikina_market_e2e` database; never run migrations or touch operational data. Prior 35-migration/four-role setup is historical, not a current schema guarantee. Recheck prerequisites per slice and reuse valid evidence without repeating unrelated checks. Details: `evidence/local-e2e-database/`.
- Use sanitized captured data or realistic fixtures. Do not copy sensitive real records into source code, test artifacts, or logs.

## Dependencies and Secrets

- Ask before adding a package to any part of the system.
- Never commit secrets, connection strings, or API keys.
- Follow existing configuration and secret-storage mechanisms. Do not introduce new packages or patterns without approval.

## Agents and Delegation

- The main agent does all planning, scope approval, API contract coordination, building, review, verification, and the final report.
- Never start a subagent unless I explicitly ask for one. Do not decide to delegate on your own.
- When I do ask, the available specialists are:
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
- The main agent verifies the integrated result. Subagent reports alone do not establish completion.
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
- Wait for my approval before starting the next task.

## Tests and Checks

- A test that has never failed proves nothing. If a test still passes after I break the code on purpose, rewrite or delete it.
- Use captured or realistic data, not arbitrary fixtures, when possible. Sanitize captured local data before use; never copy sensitive real records into source, artifacts, or logs. Use realistic synthetic fixtures when safe captures are unavailable.
- Mock only at the outer boundary, such as external services. Don't mock the code under test.
- Hand-derive every expected value. Don't copy the output into the expected value.
- Don't weaken or delete a test just to make it pass.
- Each application's build and test commands are in its own `CLAUDE.md`.
- Use existing installed dependencies. If restore/install or a missing SDK is required, report it and propose a small approved prerequisite task. Do not install packages automatically.
- Workflow/documentation-only changes use file/content validation; application builds and live E2E are not applicable when application behavior is unchanged.
- For live end-to-end checks, use the `live-check` skill.

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

<!-- Rules below this line -->

1. [CODE] Always leave application code with no dead options, branches or flags after a change, because the user wants the resulting code simple, not just the edits small. Supersedes the "simplest code" line in Scope and Approval where they differ.

2. [COMMUNICATION] Always explain results, options and decisions in plain, non-technical language (technical detail only when asked or needed for a decision), because the user needs to understand and decide without a technical background.

3. [WORKFLOW] Always create a worktree beside the project, set up only the packages that slice needs, and ask before each install or secret copy, because a new worktree has no installed packages or git-ignored files, the main folder must stay clean, and the user approves installs per task. Steps for creating and cleaning up are in `docs/worktrees.md`.

4. [DOCS] Always put notes, evidence and limits for closed work in `docs/closed-work/` and keep parked or deferred work in `backlog.md`, because the roadmap was retired on 2026-11-26.

5. [WORKFLOW] Always explain a step in plain language, then propose its plan and wait for my approval before starting it, including steps that only install or run something and change no code, because the user must understand each step before deciding, and "before coding a feature" did not clearly cover those steps.

6. [ACCURACY] Always check the code before describing a risk or giving an example of something going wrong, because an unchecked example can push the user toward a decision built on a problem that does not exist.

7. [DESIGN] Always use both installed design skills when planning, building or reviewing any change to how a screen looks or works — ui-ux-pro-max for usability, readability and accessibility, and impeccable for visual quality and removing generic AI-looking design — because matching the existing screens is not enough on its own and the user expects design best practice checked.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in gvillaluz/marikina-market-ticketing (public repo: no secrets or personal data in issues). See `docs/agents/issue-tracker.md`.

### Triage labels

Default labels: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root, created only when needed. See `docs/agents/domain.md`.
