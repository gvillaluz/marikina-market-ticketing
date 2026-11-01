# OCR feasibility: possible outcomes and next steps

Updated: 2026-10-30, Asia/Manila.

## Read first: next-session handoff

**Current result: NOT TESTED. Criterion 1 remains open.**

The active Revision Phase section is **Scanning, calculation and verification**, with goal **Scan -> Automatic check -> Review/edit -> Verify -> Submit** and eight exit criteria. Part 1, Business records, paper tickets and settlement, was closed on 2026-10-30 with recorded limits. Its closure does not establish OCR feasibility.

The user approved planning and execution of the isolated feasibility trial, subject to the exact tool/package/model download gate. The user subsequently deferred conducting the trial while preparing samples, possibly on 2026-10-31; that was an estimate, not a scheduled test. The latest instruction is to save this conditional plan in the workspace root for the next session. This document proposes future actions; it does not approve application integration, changed requirements or a new implementation slice.

Read the workspace `AGENTS.md`, `feature-workflow.md`, `roadmap.md` and affected application instructions before resuming. The detailed protocol, form inventory, source-image hashes and candidate research are in [docs/revision-ocr-feasibility-plan.md](docs/revision-ocr-feasibility-plan.md). Preserve that existing uncommitted document and all other work. If it is absent in another checkout, recover it or re-establish the missing protocol; do not assume tests passed.

## Confirmed decisions and prerequisites

- Recognition must execute locally on the **V2529 phone**. Desktop recognition cannot satisfy device acceptance.
- Evaluate citations first, then warnings, and report their results separately.
- Real completed beneficiary tickets are unavailable. Fictional information handwritten on printed copies of the supplied blank forms is acceptable for this initial feasibility trial. Original ticket stock is unnecessary for the pilot; its paper/print effects remain a later coverage limit.
- User supplied both real blank form photographs. Main labels were visually inspected; no recognition engine has evaluated them on V2529.
- Citation form: nine checkboxes, comprising four ordinance choices and five penalty choices. Its supplied printed reference is `12251`. Warning form: no visible checkboxes or printed control-number field. Checkbox targets apply to the citation form, with warning checkbox results recorded as not applicable.
- Business name goes in the bottom blank space: below the officer/signature entry area on the citation, below Tinanggap on the warning. Do not cover fields/signatures or add printed labels. Placement is agreed; recognition and correction behavior remain unverified.
- Digital/public handwriting can support preliminary diagnostics. It cannot by itself establish physical capture behavior or human recording time. Keep generated/composite samples and model-training overlap separate from independent ticket results.
- Completed handwritten samples, a checked answer key, exact sample allocation and the concrete runner/dependency approval are outstanding. The earlier proposal of five development and twenty evaluation forms per type with at least three writers is **not a confirmed sample-count requirement**.
- No recognition model/package has been downloaded for this trial, no runner has been built/installed, and no device-recognition or human correction-time results exist.

## Agreed acceptance targets

These targets were accepted before evaluation. They must not be lowered after seeing results to manufacture a pass.

| Measure | Target |
| --- | --- |
| Each applicable handwritten field, before human correction | At least 90% exact accuracy, reported separately for each field |
| Selected citation checkboxes | At least 95% of actual selections detected |
| Unselected citation checkboxes | At most 2% falsely reported selected |
| Recognition, including automatic preprocessing, mapping and checkbox steps | At least 95% of images complete within five seconds on V2529 |
| Capture + recognition + review + correction time | Median at least 20% faster than manual entry to the same correct final information |
| Final information after review/correction | All values correct against the independently checked answer key |

Also verify local execution, cold relaunch, unreadable-input handling and recovery as specified in the trial protocol. Preserve raw outputs, image/engine versions, scoring denominators, failures and cold/warm timings. Missing evidence is not a pass. Warning checkbox absence does not waive citation checkbox testing.

## Outcome decision table

| Outcome | Evidence needed | Proposed immediate next step |
| --- | --- | --- |
| **Pass** | Both form types meet every applicable agreed target, and required device/protocol checks are complete | Present the evidence for user acceptance and criterion-1 closure; prepare a small criterion-2 integration plan for approval |
| **Partial usefulness; overall targets unmet** | Some fields, form types or measures pass, but at least one applicable target fails | Identify precisely what is useful and what fails; propose one bounded improvement/retest or a reduced recognition scope for user decision |
| **Fail** | Trial is valid, but the tested approach does not meet the targets and offers insufficient practical benefit | Diagnose the failures; propose a bounded alternative local approach, or propose deferring OCR and revising the workflow requirements |
| **Incomplete / blocked** | Samples, answer key, approved tool, device measurements or human timing are missing, or a trial defect invalidates results | Complete the specific missing prerequisite/check; retain open status and avoid declaring the model feasible or infeasible |

One candidate failing does not establish that all local recognition approaches are infeasible. One form passing does not close the two-form criterion. Accurate recognition that fails the practical-time target is not an overall pass.

## If the trial passes

1. Present a short report comparing each measure with its target, with inspectable device results, scored examples, human timing and limitations. Seek user acceptance of criterion-1 closure and any corresponding roadmap update; do not mark it closed automatically.
2. Propose the smallest criterion-2 implementation slice: citation capture -> local recognition -> editable review, using the agreed bottom business-name location and preserving the paper photograph. Reuse existing reviewed-record and Verify/Submit paths after inspecting them; avoid rebuilding already implemented Part 1 behavior.
3. Define the slice before coding: exact allowed files, package/model versions, extraction-field contract, loading/cancel/error/manual-correction behavior, dependencies, device checks and time limit. Capture or recognition alone must not save a citation or add offense history.
4. The candidate starting point is the mobile ticket-capture/review area. Inspect actual consumers before the gate. If a request/response must change, agree the contract, include API and every affected web/mobile consumer, and implement backend first. An OCR pass does not authorize a contract or schema change.
5. Explain the planned checks in plain language: readable entries populate the correct fields; selected boxes map correctly; unreadable fields remain correctable; failed/cancelled recognition retains the photo and allows recovery; edits invalidate verification; submission stays gated. Required application builds/tests and live checks will be named in that implementation gate.
6. Start citations only after approval. Plan the warning integration separately afterward. Continue through remaining roadmap criteria in approved slices, checking existing behavior before proposing changes. Criterion 1 passing does not close criteria 2-8.

## If the trial is partially useful

Classify the failure using actual results. Examples:

- Names are inaccurate while dates/reference values are useful: consider recognition for only demonstrated fields, with manual entry for others.
- Text works but marked boxes fail: investigate the checkbox-processing step separately; do not claim text recognition covers it.
- Citations pass but warnings fail: preserve citation evidence and decide whether to improve warning recognition or propose citation-only integration as an explicitly reduced scope.
- Accuracy passes but runtime or correction time fails: inspect image preprocessing, model initialization and correction burden before proposing a smaller local model or extraction change.
- Only clear handwriting works: report the difficult-writing failure and its correction cost. Removing difficult cases changes the evaluated scope and cannot silently produce a broad pass.

Propose one specific improvement with approved paths, any additional downloads, expected benefit, evaluation data and a user-agreed time limit. Keep development/tuning separate from final evaluation. Use fresh evaluation examples when existing answers influenced the change; otherwise disclose results as exploratory.

If the user chooses reduced recognition scope, write the exact retained/manual fields and revised acceptance requirements for approval. The original criterion remains unmet until results satisfy it or the user explicitly approves an evidence-based revision/deferral. Manual correction alone does not erase a failed raw-accuracy target.

## If the trial fails

1. Separate a valid model result from a defective trial. Check image quality, field cropping/mapping, checkbox logic, runtime configuration and answer-key correctness. Record missing tests or invalid scoring as incomplete rather than an engine failure.
2. Report failures and human effort without promising another model will succeed. Freeze the evidence and propose one bounded next experiment only if it has a clear reason to help. Obtain approval for any new tool/model downloads, changed paths and time limit. Avoid indefinite model switching.
3. If acceptable local recognition cannot be demonstrated, propose deferring OCR and preserving paper-photo capture plus manual review/entry through the existing verification/submission workflow.
4. That manual workflow is a **proposed roadmap/requirement change** because recognition feasibility precedes dependent implementation in the current roadmap. Obtain explicit approval for the revised scope and exit criteria before coding or bypassing the prerequisite. Never mark failed OCR as passed or silently advance the phase.
5. Custom training, cloud recognition and different processing hardware are outside the current approved trial. Any proposed expansion requires its own scope/dependency/data decision. The user selected local processing on V2529.

## Immediate next-session checklist

1. Read this file and the required workspace documents. Check the working tree and preserve existing work.
2. Confirm whether completed handwritten samples are ready; no reminder, schedule or automatic trial start was created.
3. Confirm sample allocation, answer key, remaining ambiguous field meanings and scoring rules. Sample entries should use fictional details; blank labels alone cannot measure handwriting accuracy.
4. Present the exact isolated runner, dependencies/model downloads, file allowlist and V2529 installation action for approval if that gate is still outstanding. General trial approval persists; do not request it again unchanged.
5. Resume the approved feasibility trial only after its prerequisites are ready and the user resumes it. Do not implement a speculative post-test branch while awaiting results.
6. Select the appropriate outcome above from actual evidence, report it, and stop at the relevant decision/approval gate.

## Documentation scope and verification

This task creates only this root Markdown file. It changes no application code, styles, API contract, schema, dependencies or roadmap status. Validate the content and Git diff; application builds/tests and device E2E are not applicable to this documentation change. The trial itself remains unverified.
