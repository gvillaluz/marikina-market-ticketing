# Environment setup on a new computer

This guide applies to the sanitized monorepo. All credential values below are placeholders. Original repositories and local migration recovery bundles are not setup sources and must not be published. Configure your own development services or obtain authorized credentials through your team's secure channel.

## 1. Install prerequisites and clone

Install Git, .NET SDK 10, Node.js with npm (the verification machine uses Node 26), Flutter with Dart compatible with the checked-in `sdk: ^3.11.5`, and PostgreSQL client/server tools. Android development needs Android Studio/SDK and JDK 17; iOS needs macOS/Xcode and its native dependency tools. Run `flutter doctor` to identify platform prerequisites. Respect the application's checked-in lockfiles; do not upgrade dependencies as part of setup.

On Windows, Flutter plugin setup also needs symlink permission. Enable Windows **Developer Mode** in Settings → System → For developers, subject to your organization's device policy, or use an authorized environment with the required symlink privileges. Fresh-clone dependency resolution on the verification computer succeeded, but Flutter's subsequent native plugin-link creation reported this prerequisite missing. Migration tooling did not change the OS setting. Pure Dart analysis/tests are checked separately from native readiness.

After the repository is published, clone it using:

```powershell
git clone https://github.com/gvillaluz/marikina-market-ticketing.git
cd marikina-market-ticketing
```

The monorepo is adopted locally at the original workspace path. Until publication is separately approved, use that local repository; no push has been performed. Read root and application `AGENTS.md` files. API, web and mobile remain separate build/deployment units inside one Git repository.

## 2. What was sanitized from Git history

Paths in this table are relative to the named application directory. The migration inventory is [sanitization-inventory.json](sanitization-inventory.json). It records file/key locations and classifications, never original values. Repeated historical revisions of the same key are grouped.

| Application | Original file and key | Replacement / environment variable | New credential or secure reuse? |
| --- | --- | --- | --- |
| API | `MarikinaMarket.API/appsettings.json` → `ConnectionStrings:DefaultConnection` | ASP.NET User Secrets key of the same name; deployment variable `ConnectionStrings__DefaultConnection`; placeholder `<YOUR_DATABASE_CONNECTION_STRING>` | Generate a new local database login. Rotate the historical database password anywhere it remains valid. Follow section 4. |
| API | `MarikinaMarket.API/Properties/launchSettings.json` → `profiles:http:environmentVariables:Jwt__Secret` | Removed from launch profile; User Secrets `Jwt:Secret` or `Jwt__Secret` | Generate a new random signing secret. Do not reuse the historical default. Follow section 3. |
| API | Same file → `profiles:https:environmentVariables:Jwt__Secret` | Same replacement as HTTP profile | Same signing secret for one API environment; separate environments should use separate keys. |
| Web | `.env` → `VITE_FIREBASE_API_KEY` | Ignored `.env.local`, key `VITE_FIREBASE_API_KEY`; tracked `.env.example` contains a placeholder | Public Firebase web client key: authorized existing project configuration can be reused after reviewing API restrictions. Follow section 7. |
| Web | `.env` → `VITE_FIREBASE_KEY` | Legacy public VAPID-key alias; use `VITE_FIREBASE_VAPID_KEY` in `.env.local` | Obtain the public Web Push certificate key from Firebase; reuse the authorized public key or generate a project key pair if none exists. Never put its private key in the browser. |
| Web/design artifact | `figma_node.json` → `thumbnailUrl` | `<REGENERATE_FIGMA_THUMBNAIL_URL>`; no application environment variable | A signed asset URL, not a runtime AWS account secret. Regenerate the design export/link if needed. No AWS account credential is needed to run the product because of this artifact. |
| Mobile/Android | `android/app/google-services.json` → `client[0].api_key[0].current_key` | Tracked sanitized `google-services.example.json`; actual `google-services.json` is ignored | Download authorized Android Firebase client configuration, or register a development Firebase app. Follow section 8. |
| Mobile/iOS | `ios/Runner/GoogleService-Info.plist` → `API_KEY` | Tracked sanitized `GoogleService-Info.example.plist`; actual `GoogleService-Info.plist` is ignored | Download authorized iOS Firebase client configuration. Follow section 8. |
| Mobile | `lib/firebase_options.dart` → `android.apiKey` | Dart define `FIREBASE_ANDROID_API_KEY`, preferably from ignored `firebase.local.json` | Same Android public client key as the native JSON. |
| Mobile | `lib/firebase_options.dart` → `ios.apiKey` | Dart define `FIREBASE_IOS_API_KEY`, preferably from ignored `firebase.local.json` | Same iOS public client key as the native plist. |

Firebase client API keys and the web VAPID public key are client-visible configuration, not server authentication secrets. They were replaced to avoid redistributing the previous project's keys and to make machine setup explicit. Publication alone does not require rotating a correctly restricted Firebase client key. Review restrictions/usage with the project owner, and rotate or replace it if misused or unrestricted for unrelated APIs. [Firebase API-key guidance](https://firebase.google.com/docs/projects/api-keys)

The historical `.env.example` API-key entry was empty; it was not a removed credential. Its replacement example now provides an explicit placeholder. There are 10 actual file/key removal entries in the inventory.

The historical database password and JWT signing default should be rotated wherever still used. JWT rotation invalidates tokens signed with the old secret. Sanitizing Git does not revoke credentials or erase existing clones. Original recovery bundles remain local and still contain the old history. Temporary import histories preserve commit authors, messages, dates and ancestry where possible; sanitized commits and descendants have new IDs. Commit maps are recorded in [history-migration.json](history-migration.json). Existing signed tag signatures cannot remain valid after rewriting.

## 3. API configuration and ASP.NET Core User Secrets

The project is `marikina-market-api/MarikinaMarket.API/MarikinaMarket.API.csproj`. It already declares User Secrets ID `bfa5ed50-9a8a-49ec-954c-52201336ac24`; do not run `user-secrets init` to replace it. A new computer does not receive anyone else's User Secrets when cloning.

In Development, `WebApplication.CreateBuilder` loads appsettings, environment-specific appsettings, User Secrets, environment variables and command-line arguments, in increasing precedence. An environment variable can override User Secrets. Both launch profiles retain `ASPNETCORE_ENVIRONMENT=Development`, but their historical JWT secret defaults have been removed. [ASP.NET Core User Secrets](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets?view=aspnetcore-10.0)

User Secrets are a development convenience stored outside Git, not an encrypted production vault. On Windows they live under `%APPDATA%\Microsoft\UserSecrets\<UserSecretsId>\secrets.json`; on Linux/macOS under `~/.microsoft/usersecrets/<UserSecretsId>/secrets.json`. Restrict access to your user account. In deployments use the host's protected configuration/secret manager; `__` replaces `:` in environment-variable names.

From the repository root:

```powershell
Copy-Item marikina-market-api/MarikinaMarket.API/user-secrets.example.json `
  marikina-market-api/MarikinaMarket.API/user-secrets.local.json
```

1. Edit the ignored `user-secrets.local.json` in a private local editor. Replace placeholders with credentials obtained/generated as described below. Never put those values into the example or appsettings files.
2. For a new disposable environment, generate separate JWT and backup keys without displaying them. Run this only when creating new development keys; do not replace an existing backup key needed to decrypt retained backups:

```powershell
$localFile = 'marikina-market-api/MarikinaMarket.API/user-secrets.local.json'
$settings = Get-Content -Raw -LiteralPath $localFile | ConvertFrom-Json
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
foreach ($keyName in @('Jwt:Secret', 'Backups:EncryptionKey')) {
  $randomBytes = New-Object byte[] 32
  $rng.GetBytes($randomBytes)
  $settings.$keyName = [Convert]::ToBase64String($randomBytes)
  [Array]::Clear($randomBytes, 0, $randomBytes.Length)
}
$rng.Dispose()
$settings | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $localFile -Encoding UTF8
```

3. Import the local JSON over UTF-8 stdin, avoiding credential values in shell command arguments/history. The Node wrapper removes any UTF-8 BOM written by Windows PowerShell; a direct PowerShell pipe can cause the .NET CLI to reject the JSON:

```powershell
node -e "const fs=require('fs'),{spawnSync}=require('child_process');const input=fs.readFileSync('marikina-market-api/MarikinaMarket.API/user-secrets.local.json','utf8').replace(/^\uFEFF/,'');const result=spawnSync('dotnet',['user-secrets','set','--project','marikina-market-api/MarikinaMarket.API/MarikinaMarket.API.csproj'],{input,stdio:['pipe','inherit','inherit']});process.exit(result.status ?? 1);"
```

Do not print the file or run `dotnet user-secrets list` in recorded/shared terminals: those display values. An empty machine can be configured by this import; on an existing machine it updates matching keys. Securely retain only necessary credential material; the imported User Secrets remain after removing the temporary local JSON.

### Runtime credential inventory, including User Secrets

These runtime keys are read by the current code. SMTP, B2 application credentials, backup encryption keys and the Firebase Admin private key were **not found in the imported tracked configuration histories**. They still need to be provisioned securely. Existing developer User Secrets were not copied into the monorepo or this guide.

| Application | Configuration key / original location | Deployment environment variable or replacement location | Provisioning |
| --- | --- | --- | --- |
| API | `ConnectionStrings:DefaultConnection`, historically appsettings | `ConnectionStrings__DefaultConnection` or User Secrets | New local login; rotate exposed historical password; section 4. |
| API | `Jwt:Secret`, formerly launch-profile environment settings | `Jwt__Secret` or User Secrets | New cryptographically random key, at least 32 bytes of random input; procedure above. |
| API | `Email:FromAddress` | `Email__FromAddress` or User Secrets | Authorized test sender/login, or a new development sender; section 5. |
| API | `Email:AppPassword` | `Email__AppPassword` or User Secrets | Existing authorized SMTP app password can be configured securely; prefer a separate development credential. |
| API | `BackBlazeB2:General:KeyId` | `BackBlazeB2__General__KeyId` or User Secrets | Scoped application key ID for General bucket; section 6. |
| API | `BackBlazeB2:General:ApplicationKey` | `BackBlazeB2__General__ApplicationKey` or User Secrets | Corresponding secret application key. |
| API | `BackBlazeB2:Documents:KeyId` | `BackBlazeB2__Documents__KeyId` or User Secrets | Scoped application key ID for Documents bucket. |
| API | `BackBlazeB2:Documents:ApplicationKey` | `BackBlazeB2__Documents__ApplicationKey` or User Secrets | Corresponding secret application key. |
| API | `BackBlazeB2:Evidence:KeyId` | `BackBlazeB2__Evidence__KeyId` or User Secrets | Scoped application key ID for Evidence bucket. |
| API | `BackBlazeB2:Evidence:ApplicationKey` | `BackBlazeB2__Evidence__ApplicationKey` or User Secrets | Corresponding secret application key. |
| API | `BackBlazeB2:Backups:KeyId` | `BackBlazeB2__Backups__KeyId` or User Secrets | Scoped application key ID for Backups bucket. |
| API | `BackBlazeB2:Backups:ApplicationKey` | `BackBlazeB2__Backups__ApplicationKey` or User Secrets | Corresponding secret application key. |
| API | `Backups:EncryptionKey` | `Backups__EncryptionKey` or User Secrets | New 32-byte Base64-encoded key for a new development environment. Securely retain an authorized existing key to decrypt its existing backups; section 6. |
| API | `Backups:PgDumpPath` | `Backups__PgDumpPath` or User Secrets | Non-secret machine-specific executable path, or `pg_dump` available on PATH. |
| API | Firebase Admin service account JSON → `private_key`, `private_key_id`, `client_email`, project fields | Ignored file at `MarikinaMarket.API/Keys/marikina-market-firebase-adminsdk-fbsvc-d28eb0ee73.json` | Obtain an authorized development service account or generate one through Firebase IAM; section 5. The file was already ignored, not removed from tracked history. |

Non-sensitive configuration remains tracked: logging levels, allowed hosts, JWT issuer/audience, SMTP host/port, B2 endpoint/bucket mappings, application identifiers and launch URLs. Override environment-specific values using the same User Secrets JSON or environment variables; do not blindly ignore appsettings. For example, `Cors:AllowedOrigins:0` maps to `Cors__AllowedOrigins__0`. Add actual development browser origins such as `http://localhost:5173` and, if used, `http://127.0.0.1:5173` as separate entries.

`appsettings.Local.json` is ignored as a safeguard but is **not automatically loaded by this application**. Use User Secrets or normal ASP.NET environment variables instead. For Production, User Secrets are not loaded automatically. `Jwt:Issuer`, `Jwt:Audience`, `Email:SmtpHost`, `Email:SmtpPort`, `BackBlazeB2:Endpoint`, and `BackBlazeB2:Buckets:<bucket type>` can all be overridden with their `__` equivalents.

## 4. PostgreSQL and local API development

1. Install/start PostgreSQL locally, or obtain an explicitly disposable development database from the maintainer. Do not use the operational database for testing.
2. Use your database administration tool to create a dedicated development database and login. Grant only the access needed for this development database. The connection string must use that database/login, for example `Host=localhost;Port=5432;Database=<YOUR_LOCAL_DATABASE>;Username=<YOUR_DATABASE_USER>;Password=<YOUR_DATABASE_PASSWORD>`. Store the completed string only in User Secrets/protected environment configuration.
3. The user/maintainer provisions the schema from the checked-in EF Core migrations. Agents do not execute migrations. An authorized maintainer with a compatible EF Core 10 CLI can run the following **manually**, after confirming the connection targets the disposable database and Firebase startup prerequisites below are available:

```powershell
dotnet ef database update --project marikina-market-api/MarikinaMarket.API `
  --startup-project marikina-market-api/MarikinaMarket.API
```

Do not assume that merely building creates the database or supplies login accounts. Arrange synthetic test accounts and roles with the maintainer; do not copy real vendor records or use historical passwords.

4. Configure Firebase, JWT and any required integration credentials before running the API. Create/trust the development HTTPS certificate on the new machine with `dotnet dev-certs https --trust` where supported.
5. Restore/build from `marikina-market-api`: `dotnet restore MarikinaMarket.slnx`, then `dotnet build MarikinaMarket.slnx --no-restore`.
6. From the API directory, run `dotnet run --project MarikinaMarket.API --launch-profile https`. The code explicitly listens on HTTP 5000 and HTTPS 5001; changing `ASPNETCORE_URLS` alone does not replace those explicit Kestrel listeners. Development Swagger is at `https://localhost:5001/swagger`.

Background services include backup scheduling/cleanup, overdue-ticket processing and token cleanup. Start only against the disposable database. A successful build does not verify database connectivity, schema readiness or background-service behavior.

## 5. SMTP and Firebase Admin

### SMTP

1. Obtain an authorized test SMTP account supporting **STARTTLS and username/password authentication**. This is what `EmailService` implements; OAuth-only or unauthenticated mail servers are not supported by its current code.
2. Configure `Email:FromAddress` as the sender/login and `Email:AppPassword` as its application password. Set `Email:SmtpHost` and `Email:SmtpPort` for that server through User Secrets if they differ from tracked defaults.
3. Test login/OTP email delivery using a synthetic account whose inbox you control. Delivery, provider policy and credentials require a manual service check. Do not send real users test messages.

### Firebase Admin

1. Ask the project owner for access to the intended development Firebase project; use a separate development project where possible.
2. In Firebase Project settings → Service accounts, obtain/generate an authorized service-account JSON with the permissions needed for Firebase Cloud Messaging. Transfer it through a secure channel.
3. Create `marikina-market-api/MarikinaMarket.API/Keys/` locally and save that JSON using the **exact filename** `marikina-market-firebase-adminsdk-fbsvc-d28eb0ee73.json`. The basename is hardcoded in `Program.cs`; the file's own contents must belong to your actual project. Run the API with its application directory as the content/working directory, as `dotnet run --project ...` normally does.
4. Restrict local file permissions and confirm it is ignored by Git. Never put it in web/mobile bundles. `GOOGLE_APPLICATION_CREDENTIALS` alone does not replace this explicit `FromFile` call; this code currently requires the file at that path.
5. The private key is a server credential, unlike Firebase client API keys. Existing authorized service-account credentials can be configured securely; create a development credential if none is available. Rotate any service-account private key that has actually been exposed. No tracked service-account private key was found by this migration scan.

API startup currently initializes Firebase unconditionally, so the Admin JSON is required even for local API sessions where push is not being exercised. Firebase project permissions and live delivery cannot be established by mocked tests.

## 6. Storage and encrypted backups

### Backblaze B2 through the S3-compatible API

The API uses `AWSSDK.S3` with **explicit Backblaze B2 credentials and endpoint**, not an AWS default credential chain. An AWS account, `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` alone does not configure this implementation. No standalone AWS S3 integration was added. [Backblaze S3-compatible API](https://www.backblaze.com/docs/en/cloud-storage-call-the-s3-compatible-api)

1. Obtain a development B2 account/project or authorized access to development-only buckets. Configure bucket mappings for `General`, `Documents`, `Evidence` and `Backups` using `BackBlazeB2:Buckets:<type>`.
2. In B2 Application Keys, create scoped application keys for the intended bucket operations. Store each key ID and application key under the matching `BackBlazeB2:<type>:KeyId` / `ApplicationKey` pair. Prefer separate development keys; existing authorized keys can be configured securely. A privileged/master B2 key is not required.
3. Allow the operations used by `StorageService`: object upload/read/signing and deletion, plus listing/removing object versions for backup cleanup. Confirm effective permissions and bucket/version-retention policies with the storage owner.
4. Set `BackBlazeB2:Endpoint` to the bucket's S3 hostname **without `https://`**, because the code adds that scheme. The client currently hardcodes `AuthenticationRegion = "us-east-005"`; use a compatible B2 endpoint/region or obtain a separately reviewed code change before using another region. Existing tracked endpoint/bucket values are non-secret defaults, not permission to access those buckets.
5. Test a synthetic evidence upload/download and expired backup cleanup against development storage. Do not test deletion/retention using operational buckets.

### Database dump and encryption

1. Install PostgreSQL client tools; use `pg_dump` compatible with your server major version. Test the executable with `pg_dump --version` (this prints version only).
2. Set `Backups:PgDumpPath` to its absolute path on this computer, such as `<YOUR_ABSOLUTE_PG_DUMP_PATH>`, or ensure `pg_dump` is on the API process PATH. Another developer's Windows installation path is not portable.
3. Set `Backups:EncryptionKey` to Base64 encoding of **exactly 32 random bytes**, as generated in section 3. Store it securely and independently of backups.
4. Configure the Backups bucket credential pair. Manual and automatic backups use the same database connection, dump executable, encryption key and B2 storage configuration.
5. Retain the authorized existing encryption key if existing encrypted archives need to remain decryptable. Do not regenerate it casually: replacing it without a recovery plan can make retained backups unusable. No key-rotation/multiple-key feature was added by this migration.
6. In the administrator UI, verify a manual backup, an automatic scheduled run/retry and a user-operated restore drill on a disposable database. Application configuration alone does not establish any of these results. Scheduling/retention live in the database, not a new environment flag. Do not assume backups are disabled when starting a populated development database.

Temporary backup files are written beneath the API process temporary directory (`MarikinaMarket-backups`); ensure the process can create/write/delete there. No dump or restore was executed during migration verification.

## 7. Web setup

1. In `marikina-market-web`, run `npm ci` using the checked-in lockfile.
2. Copy `.env.example` to ignored `.env.local`. Keep the example placeholder-only. Configure:

| Variable | Purpose |
| --- | --- |
| `VITE_APP_NAME` | Optional non-sensitive display name. |
| `API_PROXY_TARGET` | Development-only Vite proxy target, default `http://127.0.0.1:5000`. Browser requests stay under `/api`; no `/api` suffix on this target. |
| `VITE_API_BASE_URL` | Production API **origin without `/api`**; the API client appends `/api`. Development uses the Vite proxy instead. Set your intended origin explicitly for production builds; the previous developer tunnel is only a legacy fallback in source. |
| `VITE_FIREBASE_API_KEY` | Firebase web app public client API key. |
| `VITE_FIREBASE_AUTH_DOMAIN` | Firebase web app auth domain. |
| `VITE_FIREBASE_PROJECT_ID` | Firebase project identifier. |
| `VITE_FIREBASE_MESSAGING_SENDER_ID` | Firebase messaging sender identifier. |
| `VITE_FIREBASE_APP_ID` | Firebase web app ID. |
| `VITE_FIREBASE_VAPID_KEY` | Public Web Push certificate key from Firebase Cloud Messaging. `VITE_FIREBASE_KEY` is a supported legacy fallback; prefer the explicit VAPID name. |

3. Obtain the public Firebase web configuration from Project settings → Your apps and the public VAPID key from Cloud Messaging → Web Push certificates. Use the same intended project as the API/mobile notifications. Set all Firebase fields to real public configuration to exercise push; leave all those Firebase values empty to leave push unconfigured. The placeholder strings in the example are not usable configuration and should not be left in a running build.
4. Run `npm run dev`; the configured port is 5173. Configure matching API CORS origins when calling the API directly; the development proxy is same-origin from the browser's perspective. Restart Vite after changing env files.
5. Run `npm run build` for production output. `VITE_` values are built into browser code. Never put JWT signing secrets, database passwords, SMTP passwords, B2 application keys, backup encryption keys or Firebase Admin private keys in them. Env files do not make client-side secrets private. [Vite environment variables](https://vite.dev/guide/env-and-mode)

Web push additionally needs browser permission, service-worker support and an eligible secure context (HTTPS or supported localhost behavior). Verify device registration and actual delivery separately.

## 8. Mobile setup

1. In `marikina-market-mobile`, run `flutter pub get`, then `flutter doctor`. Do not copy another computer's Android `local.properties`, SDK paths or signing keystore.
2. Obtain Firebase Android/iOS client configuration for your project. The checked-in Android application ID is `com.example.marikina_market_mobile`; register/download configuration for the exact application/bundle IDs in the platform projects. Keep project IDs, app IDs, sender IDs, bucket IDs and bundle IDs consistent with `lib/firebase_options.dart`. These non-sensitive identifiers were preserved by the migration.
3. For the existing authorized project, copy `android/app/google-services.example.json` to ignored `android/app/google-services.json` and `ios/Runner/GoogleService-Info.example.plist` to ignored `ios/Runner/GoogleService-Info.plist`, then populate the API-key placeholders from the authorized Firebase console downloads. Prefer replacing the entire local files with those official downloads. The examples retain the required non-sensitive structure.
4. If using a different development Firebase project, download new native configuration files and regenerate/update the non-sensitive `FirebaseOptions` identifiers consistently using the Firebase Flutter setup process. FlutterFire CLI, if chosen, is separate developer tooling and was not installed by this migration. It can generate concrete API keys into Dart; keep this repository's `String.fromEnvironment` API-key wiring rather than committing generated real keys. [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup)
5. Copy `firebase.example.json` to ignored `firebase.local.json`. Populate `FIREBASE_ANDROID_API_KEY` and `FIREBASE_IOS_API_KEY` with the corresponding **public client** keys, and set `API_BASE_URL` including `/api`. These Dart defines are compiled into the app and cannot protect server secrets.
6. For Android Emulator, `https://10.0.2.2:5001/api` reaches the host API; iOS Simulator commonly uses `https://localhost:5001/api`. A physical phone needs a reachable host/LAN address, firewall permission and appropriate certificate trust. The current debug certificate overrides are host-specific; do not assume they cover an arbitrary LAN address. Use a trusted development HTTPS endpoint when needed, rather than weakening production TLS. The source retains its previous tunnel fallback when no define is supplied, so **always supply your local file**.
7. Run:

```powershell
flutter run --dart-define-from-file=firebase.local.json
```

8. Firebase initialization runs before rendering the mobile UI. Client config and native files must therefore be valid even for a local session focused on inspections. Android/iOS are the configured Firebase targets; the generated options currently reject web and desktop targets. iOS/APNs entitlements, signing, notification permissions and physical-device delivery need platform/project-owner verification. Release signing remains the platform project's existing setup and is not established by this guide.

## 9. Ignore rules and safe examples

Tracked files intentionally include appsettings with non-sensitive defaults, launch profiles without JWT values, `.env.example`, `user-secrets.example.json`, `firebase.example.json`, `google-services.example.json`, and `GoogleService-Info.example.plist`.

Ignored local files include `.env`/`.env.local` and environment variants, `user-secrets.local.json`, `firebase.local.json`, Firebase Admin `Keys/*.json`, native `google-services.json` / `GoogleService-Info.plist`, Android `key.properties` / `local.properties`, private signing material, build/dependency caches, and migration/recovery artifacts. Root environment ignores explicitly allow safe `.env.example`; the web's old ignore of `.env.example` was removed. Ignore rules alone cannot protect a file already tracked, which is why history and tracked paths were sanitized too.

Check local paths without displaying contents:

```powershell
git check-ignore marikina-market-web/.env.local
git check-ignore marikina-market-api/MarikinaMarket.API/user-secrets.local.json
git check-ignore marikina-market-api/MarikinaMarket.API/Keys/marikina-market-firebase-adminsdk-fbsvc-d28eb0ee73.json
git check-ignore marikina-market-mobile/firebase.local.json
git check-ignore marikina-market-mobile/android/app/google-services.json
git check-ignore marikina-market-mobile/ios/Runner/GoogleService-Info.plist
git status --short
```

Safe examples must remain tracked; personal local files must not appear staged. Do not use `git add -f` on ignored credentials or copy the original migration safeguard directory into the monorepo.

## 10. Verification and remaining manual checks

See [environment-verification.md](environment-verification.md) for the actual migration/fresh-local-clone results and limitations. A placeholder-only checkout can be built/tested with restored dependencies, but cannot start the full live system without real authorized development configuration and a provisioned disposable database.

Repository checks after dependency restoration:

- API: `dotnet build MarikinaMarket.slnx --no-restore`, then `dotnet test MarikinaMarket.slnx --no-restore`. Give backup tests a task-specific disposable `BACKUP_TEST_TEMP_ROOT`; leave live-test variables unset unless the disposable environment is explicitly approved.
- Web: `npm run build`; enumerate existing `src/**/*.test.mjs` files and pass them to `node --test`.
- Mobile: `flutter analyze --no-pub`, `flutter test --no-pub`, and the approved native build/run target when platform prerequisites are supplied.

Manual requirements not established by source, sanitization or mocked tests: credential rotation at providers, SMTP delivery, Firebase IAM/APNs/browser/device push delivery, bucket permissions/version cleanup, database schema/data readiness and role accounts, device/network/TLS connectivity, real manual/automatic backups and restoration. No production or operational database is authorized for these checks.
