# Feature workflow

Work one slice at a time. A slice is the smallest change that works end to end. If a feature is large, split it into slices and finish one before starting the next.

Use the build, test, and format commands listed in the `AGENTS.md` of each repo the feature touches. The command notes below clarify the existing runners without changing any repository rules.

## 1. Plan

- Re-read this file, the product `AGENTS.md`, `roadmap.md`, and all applicable workspace and repository instructions when beginning each task or resuming in a new session.
- Name the repos affected: `marikina-market-api`, `marikina-market-web`, `marikina-market-mobile`, or a combination.
- State whether the API contract changes. If it does, the backend goes first.
- For each web or mobile repo, list the style files that will change.
- If the feature is outside the current phase, stop and ask.
- Give a short plan: scope, files per repo, any API contract change, approach, and open questions.
- Wait for my OK before coding.
- Inspect actual execution paths, tests, documentation, and the existing working-tree changes. Distinguish known behavior from assumptions and missing evidence.
- State the user story, acceptance criteria, independently derived expected outcomes, schema prerequisites, risks, and verification commands.
- During Phase 0, first report missing or unconfirmed prerequisites. Treat each Phase 0 task as a separate plan-approve-execute cycle. Propose one small follow-up task for approval; do not provision an entire environment or silently resolve every prerequisite.

## 2. Cut Scope

- Check that the slice is small enough to finish and test in one go. If not, split it and propose the first slice for approval.
- State exclusions and deferred work explicitly. Include required consumers and relevant failure and authorization cases.
- Present the final reduced plan before the gate.

## 3. Gate

- The parent presents the final scope, allowed paths, acceptance criteria, expected results, contract changes, schema/deployment prerequisites, and exclusions.
- Include implementation order, selective subagent ownership when useful, automated checks, E2E steps, and any blockers.
- Wait for explicit user approval before implementation. Approval covers this slice only.
- Plan approval is a strict scope gate. Stop and request approval if any prerequisite, path, dependency, or change falls outside the approved plan. Do not ask again for unchanged approval.
- Missing prerequisites become separate small approved tasks. Do not claim readiness based on assumptions.
- Before asking for approval, explain the acceptance criteria and the tests in plain language, including what each test proves. I approve only when I can explain them myself.

## 4. Build

### Backend (if the API changes)

- Write a test for the behavior first and run it. It must fail.
- Implement until the test passes.
- Run the build and fix errors and new warnings.
- Write the API contract: route, request, response, and error cases.

### Client (web and/or mobile)

- Only build the repos named in the approved plan.
- Build against the agreed contract. Write a test for the behavior first and see it fail, then implement until it passes. If the repo has no test runner, ask me before adding one.
- Handle loading, empty, and error states.
- Preserve existing architectures, naming, paging, security, styling, and secret-storage patterns.
- Keep writes within approved paths. Preserve existing uncommitted work.
- Run targeted checks during implementation. Stop if an unapproved dependency, path, or prerequisite is required.

- If a check fails, find the root cause before changing more code. Do not patch symptoms or retry blindly.

## 5. End-to-end Verify

### Live story check

- Run the real system (API plus the client being tested) against a local database, never production.
- Start dev servers only for the repos in the plan, and stop them when done.
- Test one user story at a time.
- Before running, write down the expected results by hand. Compare the actual output to them.
- Use a disposable local database provisioned by the user; never execute migrations or touch the real operational database.
- Verify persistence, refresh/relogin, role ownership, and an important failure path for the slice.
- Simulated network, authentication, database, or storage tests are automated evidence, not proof of live E2E behavior. Verify external delivery separately when email, push, or storage matters.
- If prerequisites are absent, report the blocked checks and propose the smallest prerequisite task. Do not mark the feature complete.

### Repository checks and integration review

- Run the full set of builds and tests for each repo touched and read the output.
- Only then say the slice is done. If anything failed or couldn't run, say so.
- Record pre-existing failures separately from introduced failures. Do not silently weaken checks or fix unrelated failures.
- Use the reviewer selectively within the approved task. The parent checks the integrated result, fixes in-scope findings, and reruns affected checks.
- Require reviewable verification evidence appropriate to each task, such as actual command output, inspectable diffs or artifacts, and observed E2E results when applicable. The AI's own report is not verification. Completion requires the approved acceptance criteria and all required automated and E2E evidence.

## Report and stop

- Summarize changes per file.
- List the manual steps I should test.
- List unrelated bugs without fixing them.
- If this completes the current phase, tell me and propose a roadmap update.
- Stop. Don't start the next slice until I approve.
- Include verification commands/results, limitations, remaining checks, API contract and schema prerequisites when relevant. Report implemented/unverified or blocked when required evidence is outstanding.

## Test rules

- A test that has never failed proves nothing. If a test still passes after I break the code on purpose, rewrite or delete it.
- Use captured or realistic data, not arbitrary fixtures, when possible. Sanitize captured local data before use; never copy sensitive real records into source, artifacts, or logs. Use realistic synthetic fixtures when safe captures are unavailable.
- Mock only at the outer boundary, such as external services. Don't mock the code under test.
- Hand-derive every expected value. Don't copy the output into the expected value.
- Don't weaken or delete a test just to make it pass.

## Existing verification commands

- API, from `marikina-market-api`: `dotnet build MarikinaMarket.slnx --no-restore`, then `dotnet test MarikinaMarket.slnx --no-restore`.
- Web, from `marikina-market-web`: `npm run build`, and all existing `src/**/*.test.mjs` files through Node's built-in `node --test` runner. There is no `npm test` script. In PowerShell, enumerate the files with `rg --files src -g '*.test.mjs'` into an array and pass that array to `node --test`.
- Mobile, from `marikina-market-mobile`: `dart format` on changed files, `flutter analyze --no-pub`, and `flutter test --no-pub`. Build the approved device target when required by the slice.
- Use existing installed dependencies. If restore/install or a missing SDK is required, report it and propose a small approved prerequisite task. Do not install packages automatically.
- Workflow/documentation-only changes use file/content validation; application builds and live E2E are not applicable when application behavior is unchanged.

## Intended specialist responsibilities

- API developer: approved API paths and tests; server validation, JWT-derived identity, roles/ownership, contract and error cases, schema descriptions, and build/test evidence. Preserve Controller → Service → Repository.
- Flutter developer: approved mobile flows against the agreed API; data/domain/presentation and BLoC boundaries, secure storage, route access, paging, theme, narrow layouts, and format/analyze/test/device evidence.
- React developer: approved web flows against the agreed API; API → hooks → UI, typed contracts, CSS Modules, existing auth/paging patterns, Node tests, build and browser evidence.
- Code reviewer: read-only review of the approved plan, final diff, contracts, correctness, security/ownership, regressions, scope drift, and verification gaps. Return severity, location, behavior and reproduction evidence; distinguish pre-existing issues.
- These are the four intended custom roles. Definitions are gated on installed-version format verification. No additional agents are needed.
- The parent retains planning, scope approval, API contract coordination, integration verification, and the final report. Delegation is selective and restricted to approved tasks.
