# Revision: local recognition feasibility

Date: 2026-10-30 (Asia/Manila).

Status: criterion 1 trial approved; preparation in progress. Recognition, accuracy, correction-time and offline-device checks have not run. Criterion remains open. No application integration or roadmap closure is implied.

## Confirmed scope and decisions

- Evaluate the first exit criterion under roadmap.md, Scanning, calculation and verification. Use existing pretrained recognition; citations first, warnings second.
- User approved the plan including actual recognition, device timing, independent scoring and comparison with manual recording.
- User confirmed processing must run on the V2529 phone, rather than on a computer. Computer results cannot satisfy device acceptance.
- User agreed the numerical targets below before evaluation.
- Real beneficiary tickets are unavailable. User will create sample tickets with fictional details and varied writing and formatting. Real operational records are unnecessary.
- User supplied real blank citation and warning photographs; both originals were visually inspected on 2026-10-30. The field inventory below comes from those photographs, not an app preview.
- User confirmed the business name will be handwritten in the empty bottom part of the ticket. Use the bottommost blank area below the officer/signature area on the citation, and below Tinanggap on the warning, keeping existing fields/signatures unobstructed. This records placement for the trial; it does not establish criterion-2 recognition acceptance.
- User permits researching internet handwriting samples where useful to preparation. Keep public handwriting diagnostics separate from completed-ticket acceptance evidence.
- Package/model downloads require explicit approval under the criterion and workspace rules. No such downloads or installations have occurred.

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

Proposed initial set per form type: 5 development forms and 20 separate final evaluation forms, from at least 3 writers. Keep at least one writer out of development. Agree the sample count once the form fields/checkboxes and available writers are confirmed. This is a modest feasibility pilot, not a statistical reliability study.

Include the following distinct categories; tag each form and photograph before evaluation:

1. Clear handwriting and ordinary field placement.
2. Difficult but independently readable handwriting, including joined letters and uneven size.
3. Formatting problems: text near/over field boundaries, irregular spacing and corrections. Define the intended field and value in advance.
4. Capture problems: moderate tilt, shadows and blur. Rephotograph the same forms where useful, but keep every version of a form in the same development/evaluation split.
5. Unreadable or ambiguous negative examples, scored separately: missing/cropped fields, irrecoverable blur and ambiguous checkbox marks. Do not invent an intended answer to ambiguous marks.

Include both marked and unmarked boxes wherever the real forms have them; include tick and cross marks if valid for those forms. Report actual selected/unselected counts. A form without relevant boxes is not evidence for checkbox acceptance. If the sample count is too small to assess a target, report that limit rather than a broad pass.

Business-name placement is now confirmed at the bottom blank space. Include it as a handwritten field in completed sample tickets, without printing a new field label or covering existing fields/signatures. Actual extraction and correction remain to be tested.

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
| Bottom blank strip | Agreed handwritten business-name location, below officer entry area |

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
| Bottom blank space | Agreed handwritten business-name location, below Tinanggap |

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

Before execution, present the exact trial files, build dependencies, model/download list, package identity and device install action for approval. Proposed isolated area: `evidence/revision-ocr-feasibility-2026-10-30/android-trial/`. Use a distinct Android package identity to preserve the existing installed application and its data. No nested Git repository. This proposed area/setup is not yet implemented or approved as a concrete dependency gate.

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
| V2529 as processing target | Confirmed by user |
| Numerical targets | Agreed by user before evaluation |
| Fictional completed samples instead of beneficiary tickets | Confirmed by user |
| Exact blank forms, fields and checkbox map | Both supplied originals visually inspected; field inventory recorded; 9 citation checkboxes, none on warning |
| Business-name location | User confirmed bottom blank space; recorded for both forms |
| Internet handwriting sources | IAM/EMNIST researched; no samples downloaded; diagnostics only |
| Handwritten sample creation and checked answer key | Needed |
| Exact sample count and scoring details | Proposed; awaiting form inventory |
| Exact runner/dependency/model setup | Proposed; specific approval needed |
| Runner build and scorer checks | Not run |
| Real recognition, offline/restart and device timing | Not run |
| Human manual-versus-assisted time comparison | Not run |
| Criterion closure | Open |

## Primary sources checked 2026-10-30

- [ML Kit image text recognition: Android setup and bundled artifact](https://developers.google.com/ml-kit/vision/text-recognition/v2/android).
- [ML Kit Digital Ink input requirements](https://developers.google.com/ml-kit/vision/digital-ink-recognition).
- [ML Kit terms and privacy](https://developers.google.com/ml-kit/terms). Review applicable SDK terms before adopting the dependency; local inference does not itself establish absence of SDK telemetry.
- [PaddleOCR Android on-device deployment](https://www.paddleocr.ai/v3.6.0/en/version3.x/inference_deployment/cross_platform/on_device_deployment.html).
- [PaddleOCR repository license](https://github.com/PaddlePaddle/PaddleOCR/blob/main/LICENSE). Exact runtime/model distribution terms remain to be checked if this candidate is selected.
- [Microsoft TrOCR handwritten model page](https://huggingface.co/microsoft/trocr-base-handwritten). This model card is hosted under Microsoft but states it was written by Hugging Face; its documented input is a single text line and it lists an MIT license.
