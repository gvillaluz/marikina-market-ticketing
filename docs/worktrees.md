# Worktrees: how to create, set up and clean up

A worktree is a second copy of the project folder on its own branch. We use it so a slice can be built and checked without touching the main folder's uncommitted work.

Sources: the worktrees used so far (`mmt-revision-web-ticket-tables`, `mmt-a2b-copy-to-paper`, `mmt-ticket-history`, `mmt-control-number-part2-web`) and the evidence files for those slices. The create and remove commands below follow that pattern; the old sessions did not record the exact commands.

## Rule

**Always create a worktree beside the project, set up only the packages that slice needs, and ask before each install or secret copy, because a new worktree has no installed packages or git-ignored files, the main folder must stay clean, and the user approves installs per task.**

## Create

1. Pick a name: folder `mmt-<task>` and branch `<task>`, for example `mmt-a2b-copy-to-paper` on branch `a2b-copy-to-paper`.
2. Put the folder next to the project, not inside it and not under `.claude/worktrees/`. The user chose this on 2026-11-07 so the main folder's git status stays clean. Example location: `C:\Users\Admin\Documents\Projects\mmt-<task>`.
3. Start it from the commit the slice is based on (usually the latest `main`). Command from the main folder:
   `git worktree add ../mmt-<task> -b <task> <commit>`
4. A worktree holds only committed work. Uncommitted changes in the main folder are not in it. If the slice needs those, say so at the gate.

## Set up packages (only what the slice needs)

Ask the user before each step, every task. Approval for one task does not carry to the next.

| Part | What a new worktree is missing | What was done before |
| --- | --- | --- |
| Website (`marikina-market-web`) | Installed packages. The main folder has none either. | `npm ci` inside the worktree's web folder (exact versions from the lock file). |
| Phone (`marikina-market-mobile`) | `.dart_tool` (needed even for `flutter test --no-pub`). | `flutter pub get --offline` inside the worktree's mobile folder. |
| Phone, building the APK | `android/app/google-services.json` (git-ignored, holds keys). The build fails at `processDebugGoogleServices` without it. | Copy it from the main folder. Ask each time. |
| Phone, running the APK | `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` (git-ignored). Without Windows Developer Mode, `pub get` skips it and the app crashes on start (ClassNotFoundException). | Copy it from the main folder when the plugin list is the same. |
| Server (`MarikinaMarket.API`) | Only needed when the server changes live in the worktree. | `dotnet restore` in the worktree. Start the worktree's DLL by its full path while the working directory stays the main API folder (the Firebase path is relative). See `evidence/ticket-change-history-live/Start-Api.ps1`. |

Do not copy secrets or connection strings anywhere else. Do not install anything not listed here without asking (see "Dependencies and Secrets" in `CLAUDE.md`).

## Live checks from a worktree

- Use only the disposable `marikina_market_e2e` database.
- The API ports (5000, 5001) are fixed. Before starting, check the ports and `pg_stat_activity`. Never stop a server you did not start; ask the user.
- For the phone, use `adb reverse tcp:5000 tcp:5000` and build with `--dart-define=API_BASE_URL=http://127.0.0.1:5000/api`. A tunnel was refused by the safety rules.
- Put evidence in the main folder's `evidence/` as before.

## Clean up

Do this only after the user closes the slice. Ask before removing anything.

1. In the worktree, check `git status`. It must be clean, and the commits must be pushed or merged. If not, stop and ask.
2. Stop any dev server or API you started from it.
3. From the main folder: `git worktree remove ../mmt-<task>`. Do not use `--force` without asking. This also deletes the worktree's installed packages and any copied `google-services.json` or `GeneratedPluginRegistrant.java`.
4. Run `git worktree prune`, then `git worktree list` to confirm only the main folder is left.
5. Delete the branch only after the user says so, and only when it is merged: `git branch -d <task>`. Never delete an unmerged branch.

## Current state (2026-11-07)

- Only the main folder is registered; the beside-the-project worktree folders are gone.
- Branches left locally: `revision-web-ticket-tables` (merged as PR #1) and `control-number-part2-web` (its work was not merged under that branch name; check before deleting).
