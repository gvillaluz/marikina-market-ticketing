---
name: live-check
description: Run a live end-to-end check of a Marikina Market feature against the real local system (API plus website in a browser, or API plus phone app on a device or emulator). Use when a task needs E2E or live verification, a browser or device check, or proof that a feature works beyond automated tests.
---

# Live check (end-to-end)

A live check proves one user story works in the real running system. Automated tests are not a live check, and a skipped live check is never counted as passed.

## Before starting

- Use only the explicitly confirmed user-provisioned disposable `marikina_market_e2e` database. Never run migrations, never touch production or the real operational database.
- Records that include photos (warnings, tickets) upload to the real evidence storage, where they are locked for 365 days and cannot be deleted. Tell the user this in plain words and ask before creating any.
- Signing in writes sign-in code rows to `marikina_market_e2e`. Ask the user first.
- The API ports (5000, 5001) are fixed. Check the ports and `pg_stat_activity` first. Other sessions may share the database or servers. Never stop a server you did not start; ask the user.
- Write the expected results by hand in `evidence/<task>/expected.md` before running. Hand-derive every value; never copy output into the expected value.
- If a prerequisite is missing, report the blocked check and propose the smallest task to fix it. Do not mark the feature complete.

## Running

- Run the real system (API plus the client being tested). Start dev servers only for the parts in the plan, and stop them when done.
- Test one user story at a time and compare the actual result to `expected.md`.
- Check that data is saved, that it survives a refresh or a new sign-in, that each role only sees what it owns, and one important failure path for the task.
- Simulated network, authentication, database or storage tests are automated evidence, not proof of live behavior. Check real email, push or storage delivery separately when it matters.
- Save results in `evidence/<task>/` in the main folder (`results.md`, screenshots, scripts), even when working in a worktree.

## Website (browser)

- Reuse the Chrome test window that is already open: check `http://127.0.0.1:<port>/json/list` and attach to an existing page. Start Chrome only when none exists. Close windows you opened when finished, unless the user wants to keep looking.
- Clear the reused window's session before signing in; a still-signed-in window makes the login fields time out.
- Pass all error text through a redact step before printing or saving it (remove credential values and `fill("...")` text). Playwright's error log quotes typed passwords. See `redact()` in `evidence/market-streets-slice-1/live-check.mjs`.
- The first page load in a fresh worktree can take over 30 seconds. Open the login page once before the scripted sign-in.
- Text styled uppercase (stat cards) comes back uppercase; compare case-insensitively.

## Phone (device or emulator)

- Build with `--dart-define=API_BASE_URL=http://127.0.0.1:5000/api` and run `adb reverse tcp:5000 tcp:5000`. Do not use a tunnel.
- Copy helper scripts from a previous check, for example `evidence/change-penalty-phone-live/{Device,Sql,Start-Api}.ps1`.
- `adb input text` drops characters: type two characters at a time with short pauses, and check what arrived before submitting.
- Privacy: the screen dump and screenshots show whatever is in front, including the notification shade and the keyboard's clipboard bar. Check the app has focus before reading the screen, close the shade with Back, hide the keyboard before any screenshot, and never save a screenshot of a live camera view. Never use or repeat personal content seen on screen.
- Emulator: start with `-read-only -no-snapshot -gpu swiftshader`, and build with `--target-platform android-x64`. Esc also closes bottom sheets; tap the sheet title instead.
- Stop the Gradle daemon you started when finished.

## Finishing

- Stop every server, browser window and process you started.
- If the check changed a test account (for example its password), restore it and confirm by comparison.
- Report pass or fail for each step against `expected.md`, plus anything not checked and why.
