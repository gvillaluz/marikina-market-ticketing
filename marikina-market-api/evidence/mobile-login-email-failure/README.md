# Mobile login — SMTP delivery failure and retry

Status: implemented with passing automated checks; live delivery and device login remain unverified. This task changes only the approved API areas and this evidence directory. No commit, push, schema change, migration, package installation or credential change.

## Problem and resulting behavior

`POST /api/Auth/login-mobile` previously let SMTP connection failures escape as generic 500 errors. The OTP had already been persisted, so a later request could return `Code already sent.` even though that attempt's email failed.

Mobile login now passes a 15-second cancellation token through SMTP connect, authentication, send and disconnect. It awaits the operation's cancellation and invalidates the generated OTP by its own row ID. Recognized transport, timeout, cancellation, TLS, SMTP and authentication failures become a safe handled 503. No access/refresh tokens are issued by the code-delivery endpoint. OTP verification remains required.

Generation returns the code and its corresponding record together for mobile login. This avoids selecting a different, newer record between generation and cleanup. Cleanup updates only the requested ID; a newer concurrent code, another user's code and a password-reset code are preserved. Unknown programming/configuration errors retain existing generic 500 behavior, but the failed mobile attempt's code is still invalidated before rethrowing. If cleanup itself fails, success/503 is not falsely reported; that underlying failure remains an error.

Web login and password recovery retain their existing code-generation entry point, cooldown/error behavior and default (uncancelled) email calls. The shared email interface adds an optional cancellation token with a default value; no global SMTP timeout or retry policy was added. The 15-second budget applies to SMTP work, not to unrelated database/audit latency.

## Files changed

Paths are relative to `marikina-market-api`.

| File | Change |
| --- | --- |
| `MarikinaMarket.API/Application/Services/AuthService.cs` | Selects the new behavior only for mobile login, keeps the generated code/record together, cancels SMTP after 15 seconds, invalidates the exact failed attempt and translates known delivery failures. |
| `Application/Services/EmailService.cs` | Passes cancellation into each existing MailKit operation; existing safe email outcome audits remain. |
| `Application/Interfaces/Services/IEmailService.cs` | Adds an optional cancellation token; existing callers still use the default. |
| `Application/Services/OtpService.cs` | Returns generation's code and record together, retaining the existing generation transaction; exposes targeted invalidation. The original string-returning method delegates to that same generation implementation. |
| `Application/Interfaces/Services/IOtpService.cs` | Declares those two internal operations. |
| `Application/Interfaces/Repositories/IOtpRepository.cs` | Declares invalidation by OTP row ID. |
| `Infrastructure/Repositories/OtpRepository.cs` | Marks only the matching row used and saves; missing IDs are harmless. No schema changes. |
| `Application/Exceptions.cs` | Adds `LoginCodeDeliveryException` with a fixed, user-safe message. |
| `Presentation/Middleware/ExceptionHandlingMiddleware.cs` | Maps that exception to 503 using the existing JSON `message` envelope and handled-warning logging. |
| `MarikinaMarket.Tests/MobileLoginEmailFailureTests.cs` | Adds 16 HTTP/service/transport regression cases with real AuthService/OtpService, synthetic persistence and SMTP boundaries, a real repository invalidation check, and a stalled local TCP SMTP connection. |
| `MarikinaMarket.Tests/AuthAuditTests.cs` | Updates existing test doubles for the new internal OTP/email signatures; existing audit assertions are preserved. |
| `MarikinaMarket.Tests/ReportsLiveVerificationTests.cs` | Updates only the mailbox test double's email signature. The live test was not enabled. |
| `evidence/mobile-login-email-failure/` | Raw results, bounded runner, safe connectivity probe and preservation evidence. |

API source paths abbreviated after the first entry share its `MarikinaMarket.API/` prefix.

## Independent expected outcomes

- Each simulated socket/IO/timeout/cancellation/SMTP/authentication failure must produce 503 with exactly `Unable to send your sign-in code. Please try again shortly.` Provider details and tokens must be absent.
- If failed OTP ID 1 exists with newer ID 99, another user's ID 100 and reset-purpose ID 101, only ID 1 becomes used. A newer record introduced before sending must also survive.
- The failed code cannot verify. After delivery recovers, retry sends again rather than returning `Code already sent.` Both enforcer and vendor roles are covered. Only successful verification issues tokens.
- Successful delivery followed by another request within 30 seconds must still send once and return the existing cooldown response.
- A stalled mobile SMTP operation must observe cancellation at approximately 15 seconds and stop before the HTTP failure is returned.
- A real MailKit connection to a loopback listener that never sends an SMTP greeting must abort on cancellation, close its socket and record a safe failed-email audit. No external email is sent by this test.
- Existing web-login SMTP failure behavior and uncancelled email token must remain unchanged.

## Verification evidence

| Check | Result | Artifact |
| --- | --- | --- |
| Pre-change behavior | 13 expected failures, 2 existing-behavior passes | `red.log`, `red-result.json` |
| First implementation check | 14 passed; MailKit's distinct authentication exception still returned 500 | `focused-intermediate.log`, `focused-intermediate-result.json` |
| Final focused checks | 16 passed, including real cancellation/socket closure and both concurrency timings | `focused.log`, `focused-result.json` |
| API solution build | Passed, 0 errors; 4 existing package advisory warnings | `build.log`, `build-result.json` |
| Full API tests | 568 passed, 2 opt-in live tests skipped, 0 failures | `full.log`, `full-result.json` |
| Whitespace | `git diff --check` passed for approved files | Final terminal checks |
| Prior working changes | 63 of 64 existing changed files hash-identical; reversing only this task's changes in memory reproduces the entire original shared AuthAuditTests content (newline-normalized), including its four prior added assertions | `preserved-before.json`, `preserved-after.json`, `baseline/AuthAuditTests.cs.txt`, `verification-summary.json` |

The initial test harness needed required synthetic User fields (`test-harness-compile.log`). The first implementation check identified MailKit's authentication exception separately from the framework's authentication exception; that mapping was corrected without weakening any assertions. One additional record-identity race case was added after the first check.

Tests use synthetic persistence at the database boundary. The real invalidation repository runs against the existing in-memory test query provider; those checks are not proof of live PostgreSQL persistence. The TCP cancellation test is local-only and does not send a message or test provider credentials. Known existing build warnings include System.Security.Cryptography.Pkcs advisories; a recompilation also reports existing migration-name/Firebase obsolescence warnings. None were changed.

Reproduce from the workspace root using `node marikina-market-api/evidence/mobile-login-email-failure/run-check.cjs focused`, `build` or `full`. All checks use installed dependencies with `--no-restore`. Output goes to each project's ignored `bin/MobileLoginEmailVerification/` so the existing running API's normal output is not replaced. TEMP/TMP/BACKUP_TEST_TEMP_ROOT are process-local and evidence-local; opt-in live E2E variables are removed. No running user API was stopped or restarted.

Disposable test files were cleaned after verification, except compiler analyzer-cache DLLs still held open by the SDK compiler server. `test-temp/` is ignored locally so those generated cache files are not staged with evidence. The shared compiler server was left running; no user processes were terminated.

## SMTP diagnosis and limits

`smtp-connectivity.json` records a successful DNS lookup and TCP connection to the locally configured `smtp.gmail.com:587`. From-address and password presence were checked as booleans only. No credentials were printed, SMTP authentication attempted, message sent, database accessed or config changed.

The probe combines local Development files, User Secrets and its own process environment. Environment/command-line overrides in an already running API are not established. A reachable port at the probe time does not prove TLS/authentication/delivery or rule out an intermittent network timeout. This code fix handles failure correctly; it does not repair provider/network availability. The 15-second budget may reject genuinely slow delivery, intentionally keeping the SMTP wait below the mobile client's existing 30-second receive timeout.

## API contract and consumers

- Route: `POST /api/Auth/login-mobile`, anonymous endpoint; request remains `{ "username": "...", "password": "..." }`.
- Successful response remains `SendCodeResponse`: `message`, `masked_email`, `resend_cooldown_seconds`, `code_expiry_seconds`. Existing cooldown rules remain. No login tokens are returned here.
- New handled delivery failure: HTTP 503 with `{ "message": "Unable to send your sign-in code. Please try again shortly." }`.
- Existing validation/credential/role/lock errors remain 400/403/423 as applicable. Unknown server/configuration/cleanup failures retain generic 500 handling; no raw SMTP errors enter the response.
- `POST /api/Auth/verify-login-mobile` retains its existing request/response and token issuance after successful OTP verification. A code invalidated after failed delivery is rejected.
- Mobile's existing `_throwLoginError` reads the server `message`, converts 503 to ServerException, and the repository preserves it as ServerFailure. These consumers were inspected read-only; no client updates are necessary for this error envelope. Actual on-device rendering has not been verified. Web does not call login-mobile, and its shared-service behavior has regression coverage.
- No schema or migration is required.

## Manual checks still required

Once a disposable database/schema and an authorized test mailbox are confirmed:

1. Restart/rebuild the API normally to load the fix, then request mobile login using synthetic enforcer and vendor accounts. Confirm delivery, masked address/cooldown and successful code verification.
2. In an isolated test environment, make SMTP unreachable or use a deliberately failing test transport. Expect a stopped email operation, handled 503, visible safe message, no login tokens and invalidation of that attempt's OTP.
3. Restore SMTP and retry immediately. Confirm a genuine send attempt, acceptance of the new code, rejection of the invalidated code, and no false `Code already sent.` for the failed attempt.
4. Confirm normal web login and password recovery still behave as before. Check safe success/failure audits without recording codes, passwords or tokens in evidence.

No live API/login/database story or real mailbox delivery ran in this task. Those checks remain outstanding; do not mark the live issue fully verified from automated tests alone.
