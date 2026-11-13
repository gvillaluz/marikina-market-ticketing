# Recommended actions: model plan

**Status (2026-11-13):** step 1 ran and passed. Step 2 is closed (2026-11-11, user decision): built and checked live on the test database. Step 3 is closed (2026-11-12, user decision): built and checked live on the test database; committed with steps 1 and 2 on the `recommended-actions` branch for a pull request. Step 4 is closed (2026-11-13, user decision): merged as PR #49. Step 5 is not approved.

This file records what the review of the `description-model` folder found, what has been decided, and what is still open. It does not authorize any work. Each step needs its own approval, as `feature-workflow.md` requires.

The review was done by reading the files. The model has not been run on this PC.

## What the model does

1. **Reads the note.** It takes the description the enforcer types on each ticket or warning. The phone app already requires this field.
2. **Sorts it.** It decides which of 29 violation categories the note describes (Sanitation, Weights and Measures, Obstruction and so on). It uses word patterns, a small language model that handles Filipino, English and Taglish, and number checks such as "sold as 1 kg, measured 850 g".
3. **Stays silent when unsure.** Notes that say "no violation", ask a question, or use "baka" or "pakicheck" produce nothing.
4. **Rolls up by market section.** Over the last 30 days it picks each section's main problem and gives a risk level. Serious categories count more, and warnings count half as much as tickets.
5. **Attaches an action.** The action sentence comes from a fixed list of 29, one per category. The AI does not write it.

## What the review found

- **Never tested on real Marikina tickets.** It was trained on made-up example notes. Its own notes say the final independent test is still pending.
- **Two usable versions are in the folder.**

| | Older (3.3) | Newer, marked "final" (v4) |
| --- | --- | --- |
| Can read tickets from the database | Yes | No, it only has a grading tool |
| Its own test results | Found about 21% of violations; suggested an action on 11 of 20 clean notes | Right about 98.6% of the time when it flags; catches about 70%; no suggestions on clean notes |

- **Does not fit the current database as shipped.** Its setup file points to the old vendor table (now businesses) and would add about ten new tables. It expects a log of every inspection visit, including clean ones, which the system does not keep.
- **Cannot run on this PC yet.** It needs Python 3.11 or 3.12 and its packages. The PC has Python 3.13 and none of the packages.
- **Conflicts with the roadmap on review.** The model publishes automatically. The roadmap says recommended actions need administrator review and must show their basis.
- **Size.** The folder is 2.6 GB, but the final version is about 0.5 GB. The rest is duplicate copies and files from rejected experiments. About 82% of the model file is a word list covering roughly 100 languages.
- **Must not go into git.** The folder is not currently ignored.
- **Privacy.** Ticket text stays inside the system's own computers and database. It is not sent to any outside AI service.

## Decisions so far

| Date | Decision | Source |
| --- | --- | --- |
| 2026-11-11 | The page gets a sidebar link directly below Analytics. | User's request |
| 2026-11-11 | The card image `recommended-action.png` is a reference for how the model's output is used. It is not an exact design or wording to copy. | User |
| 2026-11-11 | The model runs once a day. | User |
| 2026-11-11 | Hosting is in the cloud, on Azure. | User |
| 2026-11-11 | The model runs as an Azure scheduled job beside the server. Running it inside the server is kept only as an alternative. | User confirmed Claude's recommendation |
| 2026-11-11 | Use the newer model version marked "final" (v4). Step 2 includes writing a small connector so it can read tickets. | User |
| 2026-11-11 | Card gaps: the prominent violation sentence is built from real counts; "inspections sampled" counts the section's warnings and tickets in the last 30 days; the connector saves hourly counts for the bars; the "Street Name" line is left out. Pattern confidence levels are High (8 or more), Moderate (5 to 7) and Low (fewer). | User accepted Claude's four proposals and changed "Medium" to "Moderate" |
| 2026-11-11 | Look: the card keeps the image's layout but uses the website's own colours and font. The left stripe and badge are red for High, amber for Moderate and a calm neutral for Low. No new fonts are added. | User accepted Claude's recommendation |
| 2026-11-11 | Recommended action wording: the model's own 29 sentences are used as they are, in English. | User |
| 2026-11-11 | A recommendation is shown only when at least 2 records in the same section show the same category in the last 30 days. | User accepted Claude's recommendation |
| 2026-11-11 | Every submitted warning and ticket counts, whatever its status, including records for unregistered vendors. This matches how the Analytics page counts. | User accepted Claude's recommendation |
| 2026-11-11 | Only Head Admin and Admin Officer can see the page, the same as Analytics. The server enforces this. Showing it to enforcers is held until administrator review exists (step 4). | User accepted Claude's recommendation |
| 2026-11-11 | The daily job runs at 4:00 AM Manila time. This is a setting in Azure, made at the deployment step, and can be changed later. The page shows a "Last updated" time. | User accepted Claude's recommendation |
| 2026-11-11 | The page shows cards only for sections that have a recommendation, highest risk first, plus one line naming the sections with none. If no section has a recommendation, the page shows a plain message with the "Last updated" time. | User accepted Claude's recommendation |
| 2026-11-11 | Administrator review (step 4), general shape: each card has "Mark as reviewed" and "Dismiss". Reviewed cards stay and show who and when. Dismissed cards move to a "Dismissed" list with who and when. Head Admin and Admin Officer can both do it, and each action goes into the audit log. A review lasts while the same recommendation continues; if the problem goes away and comes back, it needs review again. Details are settled at step 4's own approval. Assigning actions to enforcers and tracking completion is left for later. | User accepted Claude's recommendation |
| 2026-11-11 | Installs for step 1, once step 1 itself is approved: Python 3.12 alongside the existing 3.13, and the model's packages (the versions the final version was checked with, processor-only edition) in a private folder inside `description-model`. Claude shows the exact command before each install. | User accepted Claude's recommendation |
| 2026-11-11 | The delivered model folder (`description-model/New Training Model/`) is kept out of git by one line in `.gitignore`, made on the `recommended-actions` branch. The connector written in step 2 lives outside that folder and stays in git; its exact home is decided at step 2's approval. | User accepted Claude's recommendation |
| 2026-11-11 | Rule 5 added to CLAUDE.md (explain in plain language, propose a plan, wait for approval, also for install/run-only steps). | User approved Claude's proposal |
| 2026-11-11 | Step 1 is approved as written under "Step 1: approved scope". It must not be run yet. Claude waits for the user's go-ahead before installing or running anything. | User |

Why the scheduled job was chosen over running inside the server:

- **Cost:** paid only for the minutes it runs each day; the server can stay on a smaller plan.
- **Safety:** if the model fails or runs out of memory, the ticketing system is not affected. The page keeps showing the previous day's recommendations.
- **Reliability:** Azure starts it on time, even if the server is asleep.
- **No shrinking needed:** the model can be used exactly as it is locked, so its test results stay valid.

Working assumptions that are Claude's and not yet confirmed by the user:

- Only the safe size cuts are made: ship the final version alone, and install the processor-only edition of the main package. Leaving out the training-only packages may not be possible, because the model's main package pulls some of them in by itself.
- The page shows one card per market section, for the last 30 days.
- The ui-ux-pro-max and design-taste-frontend skills are used for layout, spacing, wording and accessibility, inside the website's existing styling rules (no new styling library).

## Proposed steps

Each step has its own approval gate.

1. **Prove the model runs on this PC.** No app change. Run its self-check, its own tests, and six sample notes with answers written down beforehand. Also measure memory, disk and run time.
2. **Connect it to tickets.** A small connector reads submitted tickets and warnings and saves the model's findings in its own tables. Claude writes the corrected database setup; the user runs it on the disposable database.
3. **Server route, page and sidebar link.** For Head Admin and Admin Officer. The phone app is not affected.
4. **Administrator review.** Mark a suggestion reviewed or dismissed, with who and when. The roadmap item can only be ticked after this.
5. **Later, separately approved: set up the daily job on Azure.** This is a deployment task and is not part of steps 1 to 4. During development the model is started by hand.

## Step 1: approved scope (on hold)

Approved by the user on 2026-11-11. Not started. Claude waits for the user's go-ahead before installing or running anything.

**Work**

1. Install Python 3.12 alongside the existing Python 3.13. Claude shows the command first.
2. Install the model's packages into a private folder inside `description-model/New Training Model/`. Claude shows the command first. They are the versions the final version was checked with, using the processor-only edition of the main package: Python 3.12.14, setfit 1.1.3, torch 2.7.1+cpu, transformers 4.57.6, sentence-transformers 4.1.0, scikit-learn 1.9.1 and numpy 2.5.4.
3. Run the checks below and save the raw output in the main folder's `evidence/recommended-actions-step-1/`, which git ignores.

**Checks and what each proves**

| Check | Passes when | What it proves |
| --- | --- | --- |
| The model's self-check, run at the start and again at the end | It reports the final version as verified both times | The locked files are complete, and the work did not alter them |
| The model's own tests | All pass, matching its recorded 39 | It behaves on this PC as its authors recorded |
| Three example notes from the model's own guide, with the guide's answers written down first | All three match | It gives its documented answers here |
| Three new notes Claude writes, with expected answers written down first | Reported only, not pass or fail | A first look at how it handles wording it has not seen |

Memory, disk size and run time are also measured. They are reported as numbers, for choosing the Azure plan later.

**Not touched**

- No database, no app code, no connector, no shrinking and nothing on Azure.
- No commits or pushes.

**Limits and risks**

- **Time limit:** one working session. If it is not finished by then, Claude stops and reports what is blocking it.
- **Package versions:** an exact version may not be available for this PC. If so, Claude stops and asks before using a different one.
- **Trust:** the model includes one file of a kind that can run code when it is opened. That is safe only if the folder came from a trusted source. Claude stated the assumption that the folder came from the user's own team; the user approved without objecting.

**Done means:** the first three checks pass, and the output and measurements are shown to the user. If any of them fails, it is reported as failed and the step is not called done.

## The card (step 3)

| On the card | Does the model provide it? |
| --- | --- |
| Section name | Yes |
| "Street Name" line | No. A section only has a name and a description in the system |
| Risk badge (High / Moderate / Low) | Yes |
| Prominent violation | Only the category name. It does not write a sentence |
| Recommended action | Yes, from its fixed list of 29. The model's wording is used as it is |
| Peak time | Yes |
| Small hourly bars | No. It saves only the peak window, not the count per hour |
| "Pattern confidence — N inspections sampled" | Not as shown. Without a log of clean visits it would always say "Unknown" |
| Last flagged | Yes |

How the gaps are filled (all confirmed by the user on 2026-11-11):

- **Prominent violation sentence:** built from real counts, for example "Timbang at Sukat (Weights and Measures) found in 6 of 10 inspection records in the last 30 days".
- **Inspections sampled:** the warnings and tickets recorded in that section in the last 30 days. Confidence uses the model's own cut-offs: 8 or more is High, 5 to 7 is Moderate, fewer is Low. This count shows how many records the pattern is drawn from; it does not show how often inspectors visited.
- **Hourly bars:** the connector also saves the count per hour.
- **"Street Name" line:** left out.
- **Look:** the card's layout in the website's own colours and font. The left stripe and badge are red for High, amber for Moderate and a calm neutral for Low.

## Open questions

1. Which model version: the newer "final" one or the older one? **Answered 2026-11-11: the newer "final" one.**
2. Are the proposals for the card gaps acceptable? **Answered 2026-11-11: all four accepted, with "Medium" changed to "Moderate".**
3. Look: the website's own style, or the image's exact fonts and colours? **Answered 2026-11-11: the website's own style.**
4. Recommended action wording: the model's fixed list as it is, or reworded? **Answered 2026-11-11: the model's sentences as they are.**
5. How many records must support a pattern before a recommendation is shown? **Answered 2026-11-11: at least 2 in the same section for the same category.**
6. Which records count (all submitted warnings and tickets, or some statuses left out)? **Answered 2026-11-11: all submitted warnings and tickets, whatever their status.**
7. Who can see the page? **Answered 2026-11-11: Head Admin and Admin Officer only.**
8. What time of day does the daily job run? **Answered 2026-11-11: 4:00 AM Manila time.**
9. Sections with nothing to recommend: shown or hidden? **Answered 2026-11-11: no card; one line names them.**
10. Administrator review: what exactly do "reviewed" and "dismissed" do? (step 4) **Answered 2026-11-11: two buttons, "Mark as reviewed" and "Dismiss"; details at step 4's approval.**
11. Installs on this PC for step 1: Python 3.12 and the model's packages. **Answered 2026-11-11: both, once step 1 is approved.**
12. May `description-model/` be added to `.gitignore`? **Answered 2026-11-11: yes, for the delivered model folder only. Done on the `recommended-actions` branch.**
13. Approval of step 1. **Answered 2026-11-11: approved, but not to be run until the user says so.**

## Not yet measured or checked

- How much memory, disk and time one run needs.
- Whether the model's own tests pass on this PC.
- How the model behaves on real ticket descriptions.
- Azure plan, cost and setup. The project notes say deployment has not been tested.
- Where the model file (about 470 MB) is kept for the Azure job. It is too big for normal git (GitHub refuses files over 100 MB). Claude's suggestion, not yet decided: keep it in file storage and keep only its fingerprint in git. To be decided at the deployment step.

## Rules that apply

- Agents never run migrations or touch a real database. The user applies database changes to the disposable `marikina_market_e2e` database.
- Ask before each install.
- No secrets, connection strings or keys in git.
- Evidence photos uploaded during live checks are locked in storage for 365 days, so live checks should reuse existing records where possible.

## Step 1 go-ahead (2026-11-11)

The user re-approved step 1 as planned and confirmed the model folder comes from a trusted source. Claude still shows the exact command and waits for the user's OK before each install (Learned Rule 3).

## Step 1 result (2026-11-11)

Run on Python 3.12.10 (3.12.14 is not available through winget). Packages exactly as recorded: setfit 1.1.3, torch 2.7.1+cpu, transformers 4.57.6, sentence-transformers 4.1.0, scikit-learn 1.9.1, numpy 2.5.4. Raw output is in the main folder's `evidence/recommended-actions-step-1/` (git ignores it).

| Check | Result |
| --- | --- |
| Self-check at start and end | Passed both times ("Verified v4 + six accepted targeted add-ons") |
| Final version's own tests | 39 of 39 passed. The older 3.3 version's top-level tests (25) also pass, kept as extra evidence |
| Three guide examples | All three matched. Abstain and clear both show as "no finding" in the evaluator; it reported 0 false actions on both |
| Three new notes (reported only) | Sanitation and Obstruction notes were each flagged correctly; the no-violation note gave no finding |

Measurements: one model run takes about 1,275 MB of memory at peak. The first run took 174 s (first load), the second 23.6 s. The environment is 1.81 GB and the final version's files 0.46 GB.

Observation: loading the model prints a warning that its word-splitting file has an "incorrect regex pattern" that "will lead to incorrect tokenization" (a known issue with some Hugging Face files). Results still matched, but it is not yet known whether it changes results on other notes.


## Step 2: approved scope (closed 2026-11-11)

Proposed by Claude and approved by the user ("proceed") on 2026-11-11. See "Step 2 result" below.

**What it does, in plain words.** A small program (the "connector") is started by hand. It reads every warning and ticket from the last 30 days in the test database, runs the final (v4) model on each description, works out each section's recommendation, and saves the results in new tables in one go. It never changes a warning or ticket. If anything fails, nothing is saved and the previous results stay.

**Work**

1. Connector: a small Python program in git, outside the model folder. It calls the model exactly the way the model's own grading tool does, after the same self-check, so the locked files are used unchanged.
2. Section summary: worked out with the model's own rules: serious categories count more, warnings count half, High from 14 points, Moderate from 8, else Low; the busiest 3-hour window; last flagged. Plus the agreed rules: a category needs at least 2 records in the section; "X of Y records"; confidence High (8 or more records), Moderate (5 to 7), Low (fewer); counts per hour for the bars.
3. New tables (Claude writes them; the user applies them to `marikina_market_e2e`): one row per run (when, model version, how many records; gives the page its "Last updated"), one row per record and category the model found (the basis behind each card), and one row per section recommendation with everything the card needs, including the category's English and Filipino names and the model's action sentence.
4. Automatic tests for the section summary, with hand-worked numbers, written first and seen to fail.

**Not in this step:** server route, page, sidebar link, reviewing or dismissing, Azure, any change to the model files, any change to the phone app. The model's "same vendor, same day, same text" duplicate removal is not used, because every record counts (decision of 2026-11-11).

**Install needed:** one package so the connector can talk to the database (psycopg 3, "binary" edition) into the model's private environment. Claude shows the exact command first.

**Choices made (2026-11-11, user accepted Claude's recommendations)**

- The connector lives in `description-model/connector/`, in git. Only `description-model/New Training Model/` stays out of git.
- The new tables are a normal server database change (EF entities and a migration in `marikina-market-api`), applied by the user to `marikina_market_e2e`. No route or API contract changes in this step.

**Allowed paths (worktree `mmt-recommended-actions`)**

- `description-model/connector/` (new): the connector and its tests.
- `marikina-market-api/MarikinaMarket.API/Domain/Entities/`, `Infrastructure/Persistence/Configurations/`, `Infrastructure/Persistence/AppDbContext.cs`, `Infrastructure/Migrations/`: new tables only.
- `docs/recommended-actions-model-plan.md`.
- Evidence in the main folder's `evidence/recommended-actions-step-2/` (git ignores it).

**Order**

1. `dotnet restore` in the worktree (ask first).
2. Server tables and migration; server build and existing server tests.
3. The user applies the migration to `marikina_market_e2e`.
4. Connector tests written first and seen to fail.
5. Connector built until they pass.
6. psycopg install into the model's private environment (ask first, exact command shown).
7. Read-only look at the test database; expected results written by hand. If there are too few suitable records, ask before adding any.
8. Live run and comparison; fingerprints of warnings and tickets before and after; one deliberately failed run; model self-check at the end.

**Done means:** the server builds and its existing tests still pass, the connector tests pass after being seen to fail, and the live run matches the hand-written expected results with warnings and tickets unchanged. Otherwise it is reported as unfinished.

## Step 2 result (closed 2026-11-11 by user decision)

Approvals given by the user during the step: `dotnet restore` and `dotnet tool restore` in the worktree; copying the Firebase key file into the worktree twice, each time for one command and deleted straight after (writing the migration and its SQL file); installing psycopg 3.2.10 into the model's private environment; adding 9 made-up records (RA-TEST-01 to 09, no photos) to `marikina_market_e2e` and keeping them. The user applied the new tables to `marikina_market_e2e` with `psql`.

During the step the project rules changed so that server code comes from the server specialist. The server tables had already been written by Claude; at the user's choice the server specialist checked them and took ownership (only line endings changed). The connector, which no specialist covers, was written by Claude at the user's choice. The code reviewer checked everything.

| Check | Result |
| --- | --- |
| Server build and tests | Builds; same 8 old warnings. Same 22 old backup test failures before and after; nothing new |
| Connector tests | 7 tests, seen to fail first, now pass. Deliberately breaking the 2-record rule and the High cut-off each made tests fail |
| Live run against the test database | 21 records, 7 findings, 2 cards. Every value matched the results written by hand beforehand (Fish and Seafood: Weights and Measures, 4 of 6, Moderate risk 10.5, Moderate confidence, peak 08:00; Dry Goods: Obstruction, 2 of 2, Low 3.0, Low confidence, peak 06:00). The record older than 30 days was left out |
| Warnings and tickets unchanged | Fingerprint of every ticket row identical before and after |
| Failures save nothing | Model that cannot load: nothing saved. Save that breaks halfway (database refusal): all tables unchanged. Empty run: saves cleanly |
| Model files unchanged | Self-check passed after the run |

Measurements: one run of 21 records took 83 s, including loading the model.

Still open or for later:
- The roadmap asks for backups to be rechecked after database changes. Backups copy the whole database, so the new tables should be included, but this has not been checked.
- The model's own notes say the frozen v4 copy is meant for final evaluation and a separate copy should be made for development. The user chose v4 for this work; using it unchanged inside the connector is a deliberate departure from that note.
- For the card in step 3: peak time, hourly bars, last flagged and risk use every flagged record in the section, not only the main category (as the model does). When hours tie, the earliest window wins, so Dry Goods shows 06:00 although its records were around 08:00.
- The 30 days are the 720 hours before the run starts, not 30 Manila calendar days.
- Not yet measured: memory and time with a realistic number of records.
- The tokenizer warning from step 1 is still unexplained; the live results matched anyway.
- The 9 test records and run 1 stay in the test database and will appear in later live checks of the dashboard, reports and analytics.


## Step 3: approved scope (2026-11-12)

The full scope is in the spec `spec-recommended-actions-step-3.md` in the main project folder. The user approved it on 2026-11-12 ("approved and your recommended").

| Date | Decision | Source |
| --- | --- | --- |
| 2026-11-12 | Pattern confidence reads "based on N records", not "N inspections sampled", because ticket counts don't show how often inspectors visited. | User accepted Claude's recommendation |
| 2026-11-12 | The worktree was fast-forwarded to main 5084abe before step 3. The uncommitted step 1 and 2 files were kept. | User approved with the spec |
| 2026-11-12 | Added one line to the existing test `vendor-signup-removal.test.mjs` (the new page joins its stand-in list) and removed a subtitle the website specialist had added. | User |
| 2026-11-12 | The main folder's own server (ports 5000/5001) was stopped for the live check and left stopped. | User |
| 2026-11-12 | Step 3 is closed, and steps 1 to 3 go into one pull request. | User |

## Step 3 result (closed 2026-11-12 by user decision)

Built in the worktree. The server specialist wrote the new address and the website specialist wrote the page. Claude made the two approved small changes and fixed one review finding. The code reviewer (Opus) found no blocking problems.

| Check | Result |
| --- | --- |
| Server build | Builds; same 8 old warnings |
| Server tests | 867 passed, 0 failed, 2 skipped (full run). The 6 new tests are listed by name in the evidence |
| Website build | Builds; only the old large-file warning |
| Website tests | 189 of 189 pass (176 before the step; 13 new) |
| Live check on the test database | 20 of 20 matched the results written by hand beforehand: the two cards with every value, the summary, the no-recommendation line, the sidebar link, phone width, signing in again, 401 without sign-in, 403 for an enforcer, and tickets and recommendation tables unchanged |

The live check ran three times. Run 1 stopped partway because Claude's script expected camelCase names in the server's raw answer. The server uses underscore names, like every other route, and the website converts them; the values were right. Run 1 also found a real defect: a Low-risk card carried a style named "undefined". A new test was seen to fail, then the style was fixed. Runs 2 and 3 passed every check. The evidence is in the main folder's `evidence/recommended-actions-step-3/`.

Limits and open points:
- Admin Officer was not checked live, because the test database has no such account. It is covered by the server role test and the sidebar test only.
- The contract text in the spec was corrected: the field names are sent with underscores.
- The live check added 7 sign-in code rows to the test database.
- Review notes not acted on: the latest-run test would not notice if the cards stopped loading (the live check covers this); the loading test sets both loading flags together; a few one-off sizes (2px, 4px, 2.5rem) are typed in the bar and card styles; the market-section lookup also loads every business record (existing code).
- "Recommended Actions" stays open on the roadmap until step 4 (administrator review).

## Step 4 result (2026-11-13, closed by user decision 2026-11-13)

- Built: review table `recommendation_reviews` (applied to `marikina_market_e2e` by the user), `POST /api/admin/recommendations/{id}/review` and `/dismiss`, a `review` line on each card, and on the website the two buttons, the "Reviewed by" line, the Dismissed list and the "Are you sure" box. The phone app is unchanged.
- Automatic checks: server build 0 errors; recommendation tests 48/48; full server run 887 passed, 22 failed (all the known old backup tests), 2 skipped. Website build passes; 203/203 website tests (189 before step 4). One website test had a wrong comparison and was corrected.
- Live check on `marikina_market_e2e` (evidence in `evidence/recommended-actions-step-4/`, expected results in `expected.md`): 22 of 22 checks match after fixing one wrong search term in the check script, not the product. Marking reviewed and dismissing survived signing in again and a second connector run; the audit log has one Reports row per click with the Head Admin; an enforcer gets 403, no sign-in gets 401, an old-run card, a missing card, a repeat dismiss and a repeat review are refused with the agreed messages; tickets are unchanged.
- Not proved live (as planned): "review needed again after a gap" (server tests only) and Admin Officer (no such test account; role test only).
- Code review: done by Claude (main agent, no subagent); no blocking findings. Committed on `recommended-actions-review` (aabd2d3), merged as PR #49 (292efe0) on 2026-11-13.
