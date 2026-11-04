# Revision: local recognition feasibility

Date: 2026-10-30 (Asia/Manila).

Status (updated 2026-11-02): criterion 1 trial approved; Stage B (isolated runner and scorer) built and checked on V2529 with practice images only. Completed handwritten samples, answer key, tuning, frozen evaluation, timing study and report are outstanding. No scored accuracy, checkbox or timing result exists. Criterion remains open. No application integration or roadmap closure is implied.

## Confirmed scope and decisions

- Evaluate the first exit criterion under roadmap.md, Scanning, calculation and verification. Use existing pretrained recognition; citations first, warnings second.
- User approved the plan including actual recognition, device timing, independent scoring and comparison with manual recording.
- User confirmed processing must run on the V2529 phone, rather than on a computer. Computer results cannot satisfy device acceptance.
- User agreed the numerical targets below before evaluation.
- Real beneficiary tickets are unavailable. User will create sample tickets with fictional details and varied writing and formatting. Real operational records are unnecessary.
- User supplied real blank citation and warning photographs; both originals were visually inspected on 2026-10-30. The field inventory below comes from those photographs, not an app preview.
- User first confirmed the business name in the empty bottom part of the ticket (below the officer/signature area on the citation, below Tinanggap on the warning). Superseded 2026-11-02 for citations: see the business-name decision below. This records placement for the trial; it does not establish criterion-2 recognition acceptance.
- User permits researching internet handwriting samples where useful to preparation. Keep public handwriting diagnostics separate from completed-ticket acceptance evidence.
- Package/model downloads require explicit approval under the criterion and workspace rules. On 2026-11-01 the user approved Stage B: the isolated runner, the ML Kit `text-recognition:16.0.1` download (with its resolved transitive libraries) and installation on V2529.
- 2026-11-01: the handwritten text in the bottom blank strip is the **business name** on both forms. Changed 2026-11-02: on the **citation** the business name is written on the **CITATION TICKET** row, to the right of the printed label; the bottom strip is no longer read. **Warning** business-name placement is deferred: warning samples carry no business name, the answer key marks it blank, and this trial checks only that nothing is filled in. Reading a written warning business name needs its own later test and approval; criterion 2 stays open for warnings until then.
- 2026-11-01: the **issue date must not be empty in the system**. A blank paper date is scored as blank handling before correction; the timed entry screens do not finish without a date, and the answer key gives the intended date as the final value.
- 2026-11-01, capture phone revised 2026-11-02: scored samples are pen-written paper tickets photographed normally with a phone camera, unedited and copied straight from the phone by USB. Scanner-app images, gallery-edited images and photographs of screens are practice only; the existing scanned sample counts toward no set.
- 2026-11-02: in the real app, enforcers will photograph tickets and run recognition on their own phones, mainly Android, as part of submitting a citation. Trial photos may therefore come from any Android phone; the phone model is recorded per photo and accuracy is reported per phone as well as overall. Recognition in this trial still runs on V2529, so speed and offline results apply to V2529 only, not to every enforcer's phone. iPhones are not covered by this Android-only trial. Checking speed on the slowest phone enforcers actually carry belongs before production integration and needs its own approval.
- 2026-11-01: in assisted timing the operator corrects every value to match the paper; the recognizer's pre-correction values are stored separately.

## Agreed targets

| Measure | Target | Calculation |
| --- | --- | --- |
| Handwritten field accuracy | At least 90% for each field separately | Exactly correct field values / applicable readable field values |
| Selected checkbox detection | At least 95% | Correctly detected selections / actual selections |
| False checkbox selections | At most 2% | Unselected boxes reported selected / actual unselected boxes |
| Recognition latency | At least 95% of images complete within 5 seconds | Count meeting limit / all timed images; crashes/timeouts fail the limit |
| Practical recording time | Median capture, recognition, review and correction time at least 20% below manual recording | (Manual median - assisted median) / manual median |
| Final corrected information | All final values correct | Independently compare completed entries with the answer key |

Accuracy applies before human correction; final correctness applies after correction. Report numerators, denominators, missing fields and incorrect values. Do not average fields to conceal a failing field. Missing or abstained answers on readable fields count as incorrect. Printed labels do not count as handwriting successes. Freeze case, spacing, punctuation and date-comparison rules before scoring; retain original outputs. Reference leading zeros must remain significant.

These are pilot acceptance targets, not claims about an engine's capability or operational reliability. Timing and accuracy for citations and warnings must be reported separately.

## Sample preparation proposal

Use fictional names, places, business names and reference values on the correct blank citation and warning forms. Have people fill them in by hand. Printed handwriting fonts and generated handwriting images may exercise tooling but cannot establish performance on human handwriting.

Confirmed sample set (user, 2026-11-02), all on printed copies of the supplied forms at actual size (original ticket stock optional and recorded in conditions):

| Set | Citations | Warnings | Use |
| --- | --- | --- | --- |
| Tick tickets | 2 minimum, 4 recommended | — | Development only: all 9 boxes marked, one style per ticket (check, cross; other styles only if enforcers use them) |
| Development (practice) | 10 | 10 | Tuning extraction, region and checkbox rules |
| Final evaluation (test) | 50 | 50 | Scored once after settings are frozen; written in two batches of 25 and scored only after all 50 per type are photographed |
| Timing | reused from evaluation | reused from evaluation | 10 + 10 evaluation tickets the timing operator never wrote, keyed or checked; one method per ticket; after freeze |

Total to write: 122–124 tickets. At least 3 writers across development and evaluation; all tickets of at least one writer go to evaluation. With 50 evaluation tickets per type, a field with at most one error still demonstrates the 90% target at roughly 95% confidence; this remains a feasibility pilot, not an operational reliability study. Additional evaluation tickets may be added later only as a pre-planned, representative batch scored with the same frozen settings.

Split procedure (agreed 2026-11-02): the user writes 60 citations and 60 warnings and supplies photos, the writer of each ticket and optional condition notes; the agent splits before any recognition run. The test-only writer's tickets go to evaluation; 10 citations and 10 warnings are drawn at random for development from the rest with a recorded seed; the remainder is evaluation. One redraw with a new recorded seed is allowed only before any results exist. The split is per ticket, not per photo: retakes of a ticket stay in its group. Split, writer, phone model, conditions and SHA-256 per photo are recorded in `samples.csv`, then frozen.

Include the following distinct categories; tag each form and photograph before evaluation:

1. Clear handwriting and ordinary field placement.
2. Difficult but independently readable handwriting, including joined letters and uneven size.
3. Formatting problems: text near/over field boundaries, irregular spacing and corrections. Define the intended field and value in advance.
4. Capture problems: moderate tilt, shadows and blur. Rephotograph the same forms where useful, but keep every version of a form in the same development/evaluation split.
5. Unreadable or ambiguous negative examples, scored separately: missing/cropped fields, irrecoverable blur and ambiguous checkbox marks. Do not invent an intended answer to ambiguous marks.

Include both marked and unmarked boxes wherever the real forms have them; include tick and cross marks if valid for those forms. Report actual selected/unselected counts. A form without relevant boxes is not evidence for checkbox acceptance. If the sample count is too small to assess a target, report that limit rather than a broad pass.

Citation business name is written on the CITATION TICKET row (2026-11-02), without printing a new field label or covering existing fields/signatures. Warning business name is deferred (see decisions). Actual extraction and correction remain to be tested.

Samples received 2026-11-02/03: 59 citations (control numbers 12252–12311; 12292 not photographed), 57 with a business name; 57 warnings. Re-photographed tickets use only their newest photos (the paper changed); gallery-edited photos without originals can be used for development only. Three writers, one per photo batch (user-confirmed); each writer used a different phone, so per-phone and per-writer results cannot be separated.

Split frozen 2026-11-03 (record: `evidence/revision-ocr-feasibility-2026-10-30/split/README.md`): first draw (seed 20261103) redrawn once because practice warnings had 1 ticket from one practice writer; final draw (seed 20261104) made writer B test-only. Citations: 10 development + 49 evaluation. Warnings: 10 development + 45 evaluation; 2 gallery-edited writer-B warnings excluded. With 45–49 evaluation tickets a field with at most one error still demonstrates the 90% target at roughly 95% confidence.

## Supplied blank-form visual inspection

This is manual visual inspection by the assistant, not measured OCR output from V2529. The main field labels and printed citation reference are readable. Entry areas are blank; the citation reference is the exception. Photographs show perspective distortion, uneven light and some soft print, so preserve these as blank-layout examples rather than assuming scanner-quality input. Small seal lettering is not part of the field transcription.

Citation original: `C:/Users/berna/Downloads/f4446bb4-2e33-4fb3-b1a3-7bee3fcb40a0.jfif`, SHA-256 `6A8EE9D12EFF2D81FF638AC6AEC80A98B5E5DFD30450D2428385415702C3CA7B`.

| Field/region | Visible content and state |
| --- | --- |
| Form identity | CITY OF MARIKINA / Marikina Public Market Office / CITATION TICKET |
| Control No. | Printed/stamped `12251`, readable; preserve as literal paper-reference text |
| NAME | Blank, label readable; paper violator name under established rules |
| ADDRESS | Blank, label readable; do not assume this means business address from the label alone |
| Ordinance checkbox 1 | Ord. # 149 series of 1999 / Market Code; unchecked |
| Ordinance checkbox 2 | Ord. # 145 series of 2006 / Peace & Order Code; unchecked |
| Ordinance checkbox 3 | Ord. # 104 series of 2007 / Market I.D.; unchecked |
| Ordinance checkbox 4 | OTHERS; unchecked, two blank writing lines |
| Fine/penalties checkbox 1 | Php 1,500.00; unchecked |
| Fine/penalties checkbox 2 | Php 1,000.00; unchecked |
| Fine/penalties checkbox 3 | OTHERS; unchecked, blank writing line |
| Fine/penalties checkbox 4 | Blood Donation; unchecked |
| Fine/penalties checkbox 5 | Community Service; unchecked, blank numeric line followed by hrs |
| PLACE | Blank, label readable |
| DATE / TIME | Blank, label readable; this is paper text, not authority to change server timestamp behavior |
| NAME & SIGNATURE OF APPREHENDING OFFICER | Label readable; entry area blank; signature pixels are evidence, not a name-recognition/identity guarantee |
| Bottom blank strip | Below officer entry area; no longer the business-name location (moved to the CITATION TICKET row 2026-11-02) |

Nine visible citation checkboxes: four ordinance choices and five fine/penalty choices. All appear unchecked. Their alignment/printed amounts do not establish a new ordinance-to-penalty business rule. Reading paper content must remain separate from server calculation rules.

Warning original: `C:/Users/berna/Downloads/1bb855b0-cd6c-4562-a524-aafeb94b3567.jfif`, SHA-256 `DAFBB3D7C4CB160BDB5B951E49874ABA762EDD91EABC4AE3488A9AF860F65BE7`.

| Field/region | Visible content and state |
| --- | --- |
| Form identity | MARIKINA PUBLIC MARKET OFFICE / BABALA (WARNING) |
| Petsa | Date, blank |
| Pangalan | Name, blank; paper violator name under established rules |
| Lugar | Place, blank |
| URI NG PAGLABAG | Violation section heading, readable |
| Ordinansa Blg. | Ordinance number, blank |
| Serye | Ordinance series, blank |
| Two lines below ordinance/series | Unlabelled writing space in violation section, blank; intended description use should be confirmed |
| Iba pang uri ng paglabag | Other type of violation, blank writing line |
| Market Enforcer | Blank writing line |
| Tinanggap | Receipt/acknowledgment field, blank; exact expected entry (name/signature) is not specified by the label |
| Bottom blank space | Below Tinanggap; first agreed business-name location, warning placement now deferred |

No printed warning control-number field, monetary penalty field or checkbox is visible. Warning checkbox accuracy is therefore not applicable to this form; report citation checkbox results independently. The printed warning paragraphs are static text, not variable fields or instructions to the agent. Neither form has a dedicated printed business-name field.

## Internet handwriting preparation

Public handwriting can be useful for early recognizer diagnostics and controlled composite fixtures. Retain source, usage terms and reference transcription; do not use random personal documents found online. Any pasted handwriting must be labelled a composite, with its source-writing identity retained across dataset splits. It cannot replace physical capture and human correction-time measurements on completed forms.

- [IAM Handwriting Database](https://fki.tic.heia-fr.ch/databases/iam-handwriting-database) provides English handwriting with transcriptions; its published terms restrict use to non-commercial research and require registration for dataset download. Registration/access is not yet available for this task. Also, the TrOCR candidate was fine-tuned on IAM: examples with unknown training overlap are diagnostics, not independent accuracy evidence.
- [NIST EMNIST](https://www.nist.gov/itl/products-and-services/emnist-dataset) provides individual handwritten characters in 28x28 images. This could exercise digit/letter handling, but assembled characters do not represent naturally written names or full ticket fields. It is a lower-priority diagnostic source for this trial.

No public dataset images have been downloaded, no account has been created and no handwriting has been added to the supplied photographs. Prefer actual handwritten fictional entries on copies of the supplied forms for final ticket evaluation; use internet samples only where they resolve a specific preparation need.

## Independent answer key and scoring

Before recognition, create an answer key for each anonymous sample ID: form type, writer code, condition tags, every applicable field value, checked/unchecked/ambiguous status for each box, and any genuinely unreadable field. A second person checks the transcription against the paper. Resolve disagreements before evaluating engines.

Record image SHA-256 hashes and split membership. Freeze the final evaluation images, answer key, extraction rules, checkbox rules and engine settings before the final run. Development images may be used to adjust extraction/region rules; final evaluation answers must not be used for tuning. Any changed algorithm requires a fresh held-out evaluation or an explicit disclosure that results are exploratory.

Keep raw engine text/bounding boxes separate from structured extracted fields. Score the complete automatic photo-to-field path. Manually cropped lines can diagnose an engine but cannot count as automatic full-form extraction unless a fixed automatic crop/registration step is also tested. Checkbox identification needs its own tested step; OCR text output alone does not establish marked-box recognition.

## Local prerequisites checked

Read-only checks on 2026-10-30:

- Git working tree was clean at the initial check.
- V2529 is connected through ADB; device reports Android 16, API 36, arm64-v8a and SoC MT6878.
- Android SDK configured by the mobile project is C:/Users/berna/Documents/develop. NDK 28.2.13676358, CMake 3.22.1 and platforms 34/35/36 are present. Presence alone does not prove an OCR runtime builds.
- Existing Flutter dependencies include image capture and barcode scanning. No ticket text-recognition dependency or OCR implementation was found in the searched application paths.
- Inspected ML Kit cache contains barcode-scanning/common vision components; a text-recognition artifact was not found there.
- `python --version` resolves to a Windows Store alias and reports no Python runtime. This is not a blocker for a native Android trial and does not justify installing Python automatically.
- Searched workspace evidence contains app screenshots and synthetic photo-upload checks. No usable completed handwritten evaluation set was identified. Prior warning-device evidence explicitly used a covered-lens photograph and does not establish OCR feasibility.

No app data, device settings, database, API services or storage records were changed.

## Recognition candidates and approval boundary

Documentation research is evidence of supported interfaces, not measured ticket accuracy.

| Candidate | Potential trial role | Known constraints / prerequisites |
| --- | --- | --- |
| Google ML Kit Text Recognition v2, bundled Latin Android artifact `com.google.mlkit:text-recognition:16.0.1` | Small first on-phone baseline for text from camera images | Handwriting and field/checkbox accuracy on these forms remain unproven. Requires approved Maven artifact/model and transitive dependency downloads, a separate trial runner, automatic field mapping and checkbox processing. Bundled model avoids a runtime model-fetch prerequisite. |
| PaddleOCR PP-OCRv5_mobile with the official Paddle Lite Android shell demo | Alternative local text detector/recognizer to evaluate if selected | Official demo documents an Android CPU path; requires approved demo source, inference libraries, model/dictionary assets and build. Installed NDK/CMake compatibility must be demonstrated. Ticket handwriting, checkbox behavior and speed remain unproven. Pin demo revision/assets and check licenses before requesting download approval. |
| Microsoft TrOCR handwritten | Possible diagnostic comparison on cropped handwriting lines | Model documentation describes single text-line images, not full forms. Requires additional detection/segmentation and a verified Android runtime/export path; not selected for the first phone trial. A desktop run would not establish the approved device result. |

Exclude ML Kit Digital Ink Recognition from this photo trial: it consumes captured pen/touch strokes rather than photographs of paper.

Proposed first runnable baseline: an isolated native Android trial using the bundled ML Kit Latin artifact. This is an experiment with uncertain handwriting performance, not a commitment to the production engine. Do not add a Flutter wrapper or alter the production app to run it. If the baseline fails, report the failure and decide whether the alternative merits its prerequisite work; do not expand to custom training.

Implemented 2026-11-01 under the approved Stage B gate: isolated Kotlin project `evidence/revision-ocr-feasibility-2026-10-30/android-trial/` (git-ignored, machine-local), package `ph.marikina.ocrtrial` installed beside the unchanged operational app, no network permission in the merged manifest, no nested Git repository. It contains the automatic field-mapping and checkbox steps, a batch recognition runner, timed manual and assisted entry screens, and a scorer with 54 independently specified self-checks. Build commands, practice-run results and resolved dependencies are recorded in that folder's `README.md`. If the ML Kit baseline fails, any alternative engine requires its own gate.

## Actual verification procedure

1. Confirm blank forms, sample inventory, field definitions, answer key, scoring rules and manual-entry procedure. Obtain the specific dependency/setup approval. Build and install the separate runner without changing the operational app.
2. Validate scorer and extraction behavior using independently specified examples: a wrong field value fails; a missed checked box reduces recall; a false mark increases the false-selection rate; timeouts fail timing; a deliberately wrong final correction fails final correctness. Never derive expected answers from OCR output.
3. Run development citation samples on V2529, retaining engine/configuration versions and outputs. Freeze settings, then run the held-out citation set. Run the warning development and held-out sets afterward; preserve separate results.
4. Record full-image preprocessing, field mapping and checkbox processing as part of recognition latency, using a monotonic device timer. Report first-use/cold-start timings separately from repeat warmed runs; retain every failure. Do not use transfer/build time as inference time, or hide preprocessing cost.
5. Demonstrate recognition with its network access disabled after installation/model preparation. Preserve the user's wireless ADB connection/device settings. Use a runner without network permission or equivalent verified isolation; do not silently toggle airplane mode. Cold relaunch and repeat recognition, including an unreadable input and recovery to a readable input.
6. Have a human operator perform both manual entry and assisted capture/review/correction to the same independently checked final information. Use the same field set and comparable controls, counterbalance method order, and use different matched forms to reduce remembering previous answers. Report participants, assignment, per-form timings, median and difficult cases. Include retakes and corrections in assisted time. This measures a trial interface, not production app performance.
7. Compare actual numerators/denominators and timings to the agreed targets. Record pass/fail/blocked per target and form type, excluded ambiguous cases, errors and any sample-size limits. Save sanitized raw outputs, scored results and timing records for inspection.
8. Report whether to proceed, restrict recognition to useful fields, or defer. Obtain user agreement on the result before proposing criterion closure or dependent integration.

No ticket submission, offense/fine calculation, identity linking, registry change, settlement action, production integration, custom training, cloud recognition, API contract/schema change or database access is required for this isolated feasibility trial. Product E2E tests and full application builds do not substitute for this trial. Trial runner build/scoring checks and physical device/human measurements are required once implemented.

## Current evidence and remaining work

| Item | Status |
| --- | --- |
| Overall criterion trial plan | Approved |
| V2529 as processing target | Confirmed by user; speed/offline results apply to V2529 only (enforcers' own phones run recognition in the real app) |
| Capture phones | Any Android phone, model recorded per photo (user, 2026-11-02) |
| Numerical targets | Agreed by user before evaluation |
| Fictional completed samples instead of beneficiary tickets | Confirmed by user |
| Exact blank forms, fields and checkbox map | Both supplied originals visually inspected; field inventory recorded; 9 citation checkboxes, none on warning |
| Business-name location | Citation: CITATION TICKET row (user, 2026-11-02); warning: deferred, not tested in this trial |
| Internet handwriting sources | IAM/EMNIST researched; no samples downloaded; diagnostics only |
| Handwritten sample creation and checked answer key | Needed (user preparing; 122–124 tickets) |
| Exact sample count, split and scoring details | Confirmed 2026-11-02 (see Sample preparation); scoring rules implemented in the scorer |
| Exact runner/dependency/model setup | Approved and implemented 2026-11-01 |
| Runner build and scorer checks | Passed: build succeeds, 55/55 self-checks (`trial-2`, citation business name from the CITATION TICKET row, 2026-11-03) |
| Real recognition, offline/restart and device timing | Practice images only: offline, cold 1.3–1.5 s, warm 0.2–0.6 s, unreadable-file recovery shown. Not acceptance evidence |
| Checkbox step | Rebuilt 2026-11-03 on practice tickets only (`trial-9`): boxes placed by fitting the option labels to a template practice ticket, snapped to the printed border, inside ink measured. Practice: 18/19 ticks found, 2/71 false (alternative setting 15/19, 0/71). Not frozen; not acceptance evidence |
| Handwritten field reading (practice) | ML Kit baseline reads about 1 exact value in ~30 on practice citations; far below the 90% per-field target. Orientation handling added (sideways/upside-down photos). Evaluation not run |
| Second engine (2026-11-03) | User chose free, unlimited on-phone reading (online and AI services declined) and approved a practice-only TrOCR small (handwritten, MIT) trial with ONNX Runtime Android 1.30.0. Built and run on the 20 practice tickets (`trial-14`; ML Kit still finds labels, turns photos upright, reads checkboxes; TrOCR reads cut-out handwritten lines). Against the agent's draft practice key (not yet checked against paper): exact values TrOCR 12/141 vs ML Kit 1/141; exact or within 2 letters TrOCR 24/141 vs ML Kit 10/141; writer A 10/80, writer C 2/61. TrOCR path 2.1–6.7 s per photo (warm median 3.2 s citations, 3.9 s warnings) vs ML Kit 0.4–0.7 s. Far below 90% per field. Test tickets untouched. Awaiting user decision |
| ML Kit image filters (2026-11-04) | User approved a practice-only test of image filters before ML Kit (phone-only, no new packages). `trial-16`: ML Kit reads each cut-out handwritten line (same cutting as TrOCR) as v1 unchanged, v2 enlarged to 100 px line height, v3 + white margin, v4 + black and white, v5 + strokes 1 px thicker, v6 + tilt levelled, v7 + look-alike letters to digits on number fields. Against the same draft practice key: exact values v1 0/141, v2 1, v3 1, v4 1, v5 0, v6 0, v7 0 (whole-photo ML Kit 1/141, TrOCR 12/141 in the same run); exact or within 2 letters best v3 15/141 (10.6%) vs whole photo 10/141, TrOCR 24/141. Per version: median 1.5–2.0 s per photo (whole-photo ML Kit steps + that version), slowest 3.3 s. Filters do not make ML Kit read handwriting; not pursued further. First attempt (`trial-15`) failed on 4 warnings because ML Kit refuses pictures under 32 px; fixed by centring small cut-outs on white paper. Test tickets untouched |
| Timed manual/assisted screens | Built; exercised once by the user with a practice ticket |
| Human manual-versus-assisted time comparison | Not run |
| Criterion closure | Open |

## Primary sources checked 2026-10-30

- [ML Kit image text recognition: Android setup and bundled artifact](https://developers.google.com/ml-kit/vision/text-recognition/v2/android).
- [ML Kit Digital Ink input requirements](https://developers.google.com/ml-kit/vision/digital-ink-recognition).
- [ML Kit terms and privacy](https://developers.google.com/ml-kit/terms). Review applicable SDK terms before adopting the dependency; local inference does not itself establish absence of SDK telemetry.
- [PaddleOCR Android on-device deployment](https://www.paddleocr.ai/v3.6.0/en/version3.x/inference_deployment/cross_platform/on_device_deployment.html).
- [PaddleOCR repository license](https://github.com/PaddlePaddle/PaddleOCR/blob/main/LICENSE). Exact runtime/model distribution terms remain to be checked if this candidate is selected.
- [Microsoft TrOCR handwritten model page](https://huggingface.co/microsoft/trocr-base-handwritten). This model card is hosted under Microsoft but states it was written by Hugging Face; its documented input is a single text line and it lists an MIT license.
