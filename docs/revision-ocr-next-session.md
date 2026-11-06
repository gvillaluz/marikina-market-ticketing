# Ticket entry: where we stopped (2026-11-04, new direction: faster entry instead of OCR)

Plain-language notes for picking up next session. **Read "Latest" first.** The OCR trial history below it is kept as a record.
Detailed records: `docs/revision-ocr-feasibility-plan.md` and `evidence/revision-ocr-feasibility-2026-10-30/README.md` (on this computer only).

## Latest (2026-11-06): A1 complete

New ticket flow, part A1 (find the business and the violator) is complete: all automatic tests pass, all six live checks on V2529 passed, and the user closed it on 2026-11-06. A2 has not started and needs its own plan and approval. Report: "A1 final report" in `docs/ticket-flow-slice-a-plan.md`. Nothing is committed. The throwaway database `marikina_market_e2e` was set up again on this computer (`evidence/local-e2e-database/`, files dated 2026-11-06).

## Your answers (2026-11-06)

1. **OCR is dropped.** Roadmap and OCR documents updated to say so. Ideas 1–4 are the first slice. A plan is still needed before any coding.
2. **Every business is already in the system.** New businesses come with records from the higher office. Enforcers never create businesses.
3. **The office has a list of private businesses** and will import it. The system has no import feature for business lists yet. That would be its own small slice, planned separately.
4. **Timing test:** explained in chat. Still to confirm who can do it.
5. **Documents updated:** roadmap (kept short, same format), `docs/revision-ocr-feasibility-plan.md`, this file and `revision-ocr-outcomes-plan.md`.
6. **Google key file:** you said delete it. It is not on this computer: `C:\Users\berna\...` doesn't exist here. Delete it on the computer that has it. Also delete the key and the Google Cloud project online.

## Recommendation (2026-11-04)

### What you told me

- **Google Vision: skipped.** It needs billing.
- **The capstone does not require OCR or scanning.** Reading the ticket was your own idea to save the enforcer work.
- **No school email** (only @gmail.com), so the free Azure student plan is not available either.
- **The market office can't make vendors do anything the law doesn't require**, like installing an app. QR stickers on stalls are unclear, so we don't plan on them.
- **Enforcers can fill in the app before or after writing the paper ticket.**

### My recommendation (not yet approved by you)

Stop trying to read handwriting. Make the app fast to fill in instead: **fill in the app first, then copy to paper.**

1. **One search box for the business.** Type any part of the business name, stall number, owner name, street/barangay or account number, then tap the match. Works for public stalls and private businesses.
2. **Place fills itself.** Public stall: section and stall number. Private business: its street address.
3. **Next control number suggested.** The app remembers the enforcer's last number and suggests the next one; the enforcer confirms.
4. **"Copy to paper" screen** after Verify, laid out like the paper ticket, showing what to write and which boxes to tick, with the right fine for a repeat offense.
5. Later: show people already recorded at this business as one-tap choices (needs a small server change).
6. Later: the enforcer's most-used violations shown first.
7. No code needed: tell enforcers about the microphone on the phone keyboard for typing new names.

Ideas 1–4 are the proposed first slice. Nothing has been planned in detail or coded yet.

### Things I found

- **Correction:** the current business search in the enforcer app finds a business **only by its account number** (even though it's named "stall"). Enforcers don't see the account number on the paper or the stall, so idea 1 fixes a real gap.
- The **account number never needs to be on the paper**. It comes from the business record the enforcer picks.
- The system already stores name, stall, owner and address for every business, public and private. Only the search needs to change.
- Dropping OCR leaves the real app untouched; the trial ran in a separate test app.

### Why it's defendable (for the panel)

- You tested OCR and have the numbers: about 1 in 12 values exactly right against a goal of 9 in 10.
- It fits the real limits: the paper ticket is required by law, and vendors don't have to do anything.
- It can be measured: time the same tickets the old way and the new way (target: at least 20% faster).
- Honest limit: the paper is still written. The app part becomes mostly taps, and the paper fine comes out right because the system worked it out first.

### Waiting on you

1. **Approve dropping OCR** and choose which ideas to build (my suggestion: 1–4 first).
2. **When a business isn't in the system yet** (especially private), what should happen?
   - The office adds it first.
   - The enforcer saves with just the business name, and the office links it later.
   - The enforcer adds a basic business record.
3. **Does the market office have a list of private businesses** (name, owner, address, account number) to load into the system?
4. **Can 2 or 3 enforcers or office staff** try it for the timing test?
5. **May I update the roadmap and the OCR plan document** to record that OCR is dropped? (Documents only; I'll show you the wording first.)
6. **May I delete the Google key file** at `C:\Users\berna\Documents\google-vision-key.txt.txt`? You'd also delete the key and the project in Google Cloud.

After your answers, I'll write the plan for the first slice for your approval before any coding.

---

# OCR trial history (kept as a record)

## The goal

Enforcers fill in paper tickets, then also type the same details into the app. We want the phone to read the photo of the ticket and fill in the app for them. It doesn't have to be perfect, because the enforcer checks and fixes it before submitting.

## What is done

1. **Sample tickets are ready and split.**
   - 59 citations and 57 warnings, written by 3 people (A, B, C). Each person used a different phone.
   - **Practice:** 10 citations and 10 warnings, used to adjust the app.
   - **Test:** 49 citations and 45 warnings. Not touched yet; they'll be used once, at the end, for a fair result.
   - Writer B's tickets are only in the test set.
   - Two edited warning photos (W35, W36) are left out.
   - Citation 12292 has no photo.
2. **Business name:**
   - **Citations:** written on the "CITATION TICKET" row.
   - **Warnings:** placement decided later; warnings are tested without a business name for now.
3. **The trial app now:**
   - turns sideways or upside-down photos the right way up
   - finds where each field is on the ticket
   - reads checkboxes well: on practice, it found 18 of 19 ticks and wrongly ticked 2 of 71 empty boxes
   - takes under 1 second per photo
4. **The problem:** the current reading tool (Google ML Kit) gets handwriting right only about **1 time in 30**. The goal is 9 times in 10.

## Decisions you made

- Photos can come from **any Android phone**, not just the V2529.
- At first: **no online services and no AI services**; a tool that is **free, has no limits, and runs on the phone**.
- Later (2026-11-03): you asked to also test **Google Cloud Vision** (online). Enforcers must be online when inspecting, so internet is not a problem. The remaining concerns are cost, real ticket photos going to Google, and keeping the key on the server.
- Building our own reading model: not recommended. It needs thousands of labelled samples, and a model on the phone makes the app heavy and slow.
- Try a better handwriting reader on the phone: **Microsoft TrOCR** (free, MIT licence). Test it on the practice tickets only.
- Added a project rule: **always explain things in plain language.**

## TrOCR test: done on the 20 practice tickets

TrOCR now runs inside the trial app on the phone. ML Kit still does what it is good at: turning the photo upright, finding the printed labels, the checkboxes and the printed control number. TrOCR reads only the cut-out handwriting.

Results on the same 20 photos, checked against my written-down answers (141 handwritten values):

| | ML Kit (before) | TrOCR (now) |
|---|---|---|
| Exactly right | 1 | 12 |
| Right or only 1–2 letters off | 10 | 24 |
| Citations exactly right | 0 of 71 | 8 of 71 (names: 5 of 10) |
| Warnings exactly right | 1 of 70 | 4 of 70 |
| Seconds per ticket | under 1 | about 3–4 (slowest 6.7) |

- **Better, but nowhere near the goal of 9 in 10.** TrOCR gets about 1 value in 12 exactly right.
- My earlier guess of "3 to 6 in 10" was too hopeful.
- Neat, clear writing (writer A) did much better than writer C (sideways, blurry photos on a busy background): 10 of 80 against 2 of 61.
- When a space is empty or messy, TrOCR sometimes makes up words.
- The 94 test tickets were not touched.

## ML Kit with image filters: done on the 20 practice tickets (2026-11-04)

You suggested cleaning up each cut-out before ML Kit reads it, like the filters used for digit recognition. We tried 7 versions on the phone, each adding one filter: enlarge, white space around, pure black and white, thicker strokes, level the tilted line, and turning letters that look like digits into digits on date, time and number fields.

| Reader | Exactly right | Right or 1–2 letters off |
|---|---|---|
| ML Kit, whole photo (before) | 1% (1 of 141) | 7% |
| ML Kit, best filter version | 1% (1 of 141) | 11% (with white space added) |
| TrOCR | 8.5% (12 of 141) | 17% |

- **The filters did not help.** No version got more than 1 value exactly right.
- Black and white and thicker strokes made blurry writing run together, so those made things worse.
- On date, time and number fields, ML Kit mostly returned **nothing at all** (about 40 of 47), so the number cleanup had almost nothing to fix.
- Conclusion: ML Kit is built for printed text. Cleaning the picture does not make it read handwriting.
- The 94 test tickets were not touched.

## Google Cloud Vision test: started, stopped at billing (2026-11-04)

- You created a Google Cloud project and an API key (restricted to Cloud Vision only).
- The key is saved at `C:\Users\berna\Documents\google-vision-key.txt.txt` (Notepad added a second ".txt"; that's fine, it's used as it is). It is outside the project folder, so it can't end up in git. Never paste it into chat.
- The first try was **refused by Google: billing isn't turned on** for the project (number 958317066178). Nothing was read and nothing was charged.
- To turn billing on, Google asks for a card. It shows a **temporary $50 hold** (a card check, normally released within a week). You also saw a **"one-time billing required"** message. We didn't confirm whether that's the same hold or a real prepayment.
- **My view:** worth it only if it's just the hold. If it's a real payment, skip it and choose option 1. I don't expect Google Vision to reach 9 in 10 on these tickets either.
- Ready to run as soon as billing is on: the script sends the same 163 practice cut-outs (well within the free 1,000 reads a month), then scores them like the other readers. Scripts: `evidence/revision-ocr-feasibility-2026-10-30/scripts/` (`vision.mjs`, `compare.mjs`).
- **If you skip Google Vision:** delete the key file (I can do it with your OK), delete the key under **APIs & Services → Credentials**, and delete the Google Cloud project so nothing is left behind.

## Earlier options (replaced by "Latest" above)

Before 2026-11-04 the choices were: option 1 (read checkboxes and control number only), option 2 (TrOCR as a suggestion) or option 3 (test more free readers). Google Vision was skipped because of billing. If OCR is dropped, these options, the practice answer check and the 94-ticket final test are no longer needed.

## Earlier to-do list

- [x] TrOCR test done (2026-11-03).
- [x] ML Kit image-filter test done (2026-11-04): no improvement.
- [x] Google Cloud Vision key created and saved (2026-11-04).
- [x] Google Vision: skipped (2026-11-04), billing required.
- [ ] Only if OCR continues: check the practice answers (`evidence/revision-ocr-feasibility-2026-10-30/answer-key/practice-answers-draft.csv`), write and second-check the 94 test-ticket answers, and choose the timing person.

## Things to remember

- Keep the phone screen on during real test runs. Once, the phone froze for about 4 minutes on one photo; a freeze counts as a failure.
- Nothing has been committed to git yet.
