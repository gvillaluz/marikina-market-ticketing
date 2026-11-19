# Environment setup on a new computer

This guide applies to the sanitized monorepo. All credential values below are placeholders. Original repositories and local migration recovery bundles are not setup sources and must not be published. Configure your own development services or obtain authorized credentials through your team's secure channel.

## 1. Install prerequisites and clone

Install Git, .NET SDK 10, Node.js with npm (the verification machine uses Node 26), Flutter with Dart compatible with the checked-in `sdk: ^3.11.5`, and PostgreSQL client/server tools. Android development needs Android Studio/SDK and JDK 17; iOS needs macOS/Xcode and its native dependency tools. Run `flutter doctor` to identify platform prerequisites. Respect the application's checked-in lockfiles; do not upgrade dependencies as part of setup.

On Windows, Flutter plugin setup also needs symlink permission. Enable Windows **Developer Mode** in Settings → System → For developers, subject to your organization's device policy, or use an authorized environment with the required symlink privileges. Fresh-clone dependency resolution on the verification computer succeeded, but Flutter's subsequent native plugin-link creation reported this prerequisite missing. Migration tooling did not change the OS setting. Pure Dart analysis/tests are checked separately from native readiness.

Clone the repository from GitHub (access is given by the project owner):

```powershell
git clone https://github.com/gvillaluz/marikina-market-ticketing.git
cd marikina-market-ticketing
```

Read root and application `AGENTS.md` files. API, web and mobile remain separate build/deployment units inside one Git repository.

## 2. What was sanitized from Git history

Paths in this table are relative to the named application directory. The migration inventory is [sanitization-inventory.json](docs/sanitization-inventory.json). It records file/key locations and classifications, never original values. Repeated historical revisions of the same key are grouped.

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

The historical database password and JWT signing default should be rotated wherever still used. JWT rotation invalidates tokens signed with the old secret. Sanitizing Git does not revoke credentials or erase existing clones. Original recovery bundles remain local and still contain the old history. Temporary import histories preserve commit authors, messages, dates and ancestry where possible; sanitized commits and descendants have new IDs. Commit maps are recorded in [history-migration.json](docs/history-migration.json). Existing signed tag signatures cannot remain valid after rewriting.

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
| API | `Firebase:ServiceAccountJson` (the whole Firebase Admin service-account JSON, including `private_key`) | `Firebase__ServiceAccountJson` or User Secrets | Obtain an authorized development service account or generate one through Firebase IAM; section 5. Until 2026-11-19 the server read it from the ignored file `Keys/marikina-market-firebase-adminsdk-fbsvc-d28eb0ee73.json`; that file is no longer read. |

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
3. Put the JSON's content into the setting `Firebase:ServiceAccountJson` (read by `Presentation/FirebaseKey.cs`). On your computer, from the repository root, replace `<path to the key file>` and run (nothing is printed; the Node wrapper keeps the JSON's quotes intact, which a PowerShell command line does not):

```powershell
node -e "const fs=require('fs'),{spawnSync}=require('child_process');const key=JSON.parse(fs.readFileSync(process.argv[1],'utf8').replace(/^﻿/,''));const r=spawnSync('dotnet',['user-secrets','set','Firebase:ServiceAccountJson',JSON.stringify(key),'--project','marikina-market-api/MarikinaMarket.API/MarikinaMarket.API.csproj'],{stdio:'ignore'});console.log(r.status===0?'Firebase:ServiceAccountJson set.':'Failed, exit code '+r.status);process.exit(r.status ?? 1);" "<path to the key file>"
```

   On Azure it is the App Service setting `Firebase__ServiceAccountJson` (section 11.2).
4. Keep the downloaded key file outside the repository or in the ignored `marikina-market-api/MarikinaMarket.API/Keys/` folder, restrict its permissions, and never put it in web/mobile bundles or the server package. `GOOGLE_APPLICATION_CREDENTIALS` is not read.
5. The private key is a server credential, unlike Firebase client API keys. Existing authorized service-account credentials can be configured securely; create a development credential if none is available. Rotate any service-account private key that has actually been exposed. No tracked service-account private key was found by this migration scan.

API startup initializes Firebase unconditionally, so the setting is required even for local API sessions where push is not being exercised; without it the server stops at start-up with "The setting Firebase:ServiceAccountJson is missing." Firebase project permissions and live delivery cannot be established by mocked tests.

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
2. Set `Backups:PgDumpPath` to its absolute path on this computer, such as `<YOUR_ABSOLUTE_PG_DUMP_PATH>`, or ensure `pg_dump` is on the API process PATH. Another developer's Windows installation path is not portable. The server package (section 12) has PostgreSQL 18's `pg_dump` on its PATH; do not set `Backups:PgDumpPath` there.
3. Set `Backups:EncryptionKey` to Base64 encoding of **exactly 32 random bytes**, as generated in section 3. Store it securely and independently of backups.
4. Configure the Backups bucket credential pair. Manual and automatic backups use the same database connection, dump executable, encryption key and B2 storage configuration.
5. Retain the authorized existing encryption key if existing encrypted archives need to remain decryptable. Do not regenerate it casually: replacing it without a recovery plan can make retained backups unusable. No key-rotation/multiple-key feature was added by this migration.
6. In the administrator UI, verify a manual backup, an automatic scheduled run/retry and a user-operated restore drill on a disposable database (steps in the [recovery guide](recovery-guide.md)). Application configuration alone does not establish any of these results. Scheduling/retention live in the database, not a new environment flag. Do not assume backups are disabled when starting a populated development database.

Temporary backup files are written beneath the API process temporary directory (`MarikinaMarket-backups`); ensure the process can create/write/delete there. No dump or restore was executed during migration verification.

## 7. Web setup

1. In `marikina-market-web`, run `npm ci` using the checked-in lockfile.
2. Copy `.env.example` to ignored `.env.local`. Keep the example placeholder-only. Configure:

| Variable | Purpose |
| --- | --- |
| `VITE_APP_NAME` | Optional non-sensitive display name. |
| `VITE_API_BASE_URL` | The server's address, without `/api` and without a slash at the end (for example `https://<app service address>`). Set it only when building for Azure (section 11.3). Leave it empty in development. |
| `API_PROXY_TARGET` | Development-only Vite proxy target, default `http://127.0.0.1:5000`. Browser requests stay under `/api`; no `/api` suffix on this target. |

With `VITE_API_BASE_URL` empty, the website calls `/api` on its own address and the development proxy forwards it to the server. With it set, the website calls `<VITE_API_BASE_URL>/api` and sends the sign-in cookie with every request (`src/config/env.ts`, `src/api/client.ts`). The website has no Firebase settings. For Azure, see section 11.

3. Run `npm run dev`; the configured port is 5173. The development proxy is same-origin from the browser's perspective. Restart Vite after changing env files.
4. Run `npm run build` for production output. `VITE_` values are built into browser code. Never put JWT signing secrets, database passwords, SMTP passwords, B2 application keys, backup encryption keys or Firebase Admin private keys in them. Env files do not make client-side secrets private. [Vite environment variables](https://vite.dev/guide/env-and-mode)

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

See [environment-verification.md](docs/environment-verification.md) for the actual migration/fresh-local-clone results and limitations. A placeholder-only checkout can be built/tested with restored dependencies, but cannot start the full live system without real authorized development configuration and a provisioned disposable database.

Repository checks after dependency restoration:

- API: `dotnet build MarikinaMarket.slnx --no-restore`, then `dotnet test MarikinaMarket.slnx --no-restore`. Give backup tests a task-specific disposable `BACKUP_TEST_TEMP_ROOT`; leave live-test variables unset unless the disposable environment is explicitly approved.
- Web: `npm run build`; enumerate existing `src/**/*.test.mjs` files and pass them to `node --test`.
- Mobile: `flutter analyze --no-pub`, `flutter test --no-pub`, and the approved native build/run target when platform prerequisites are supplied.

Manual requirements not established by source, sanitization or mocked tests: credential rotation at providers, SMTP delivery, Firebase IAM/APNs/browser/device push delivery, bucket permissions/version cleanup, database schema/data readiness and role accounts, device/network/TLS connectivity, real manual/automatic backups and restoration. No production or operational database is authorized for these checks.

## 11. Azure (demo hosting)

**Status: written 2026-11-18 from the project owner's description of how they deploy. Not yet followed step by step; it counts as checked only after the next demo update is done by following it.** Items marked *(confirm)* are to be checked during that update. To restore data, see the [recovery guide](recovery-guide.md).

The demo has four parts, each deployed from VS Code or the terminal:

| Part | Azure service | Deployed with |
| --- | --- | --- |
| Database | Azure Database for PostgreSQL | SQL files run in the VS Code PostgreSQL extension |
| Server | Azure App Service (`marikina-market-server`) | The server package, uploaded to the package store `marikinamarketregistry` (11.2, section 12) |
| Website | Azure Static Web Apps | The Static Web Apps command-line tool through `npx` |
| Recommended actions | Azure Container Apps job (`marikina-market-recommendations`) | The model package, uploaded to the same package store (11.5, section 13) |

Order for an update: **backup → database → server → website → phone app**. The server must understand the new database before the website uses it. The model package is only updated when the model or the connector (`description-model/connector`) changes.

### 11.1 Database

1. **Take a backup first**: on the website, **Backups** → **Back Up Now**, then **Download** and keep the file.
2. **See which schema changes the demo already has.** In the VS Code PostgreSQL extension, connected to the demo database, run this read-only query:

   ```sql
   SELECT migration_id FROM "__EFMigrationsHistory" ORDER BY migration_id DESC LIMIT 5;
   ```

   Compare the newest name with the newest migration files in `marikina-market-api/MarikinaMarket.API/Infrastructure/Migrations/` (the file names start with the same date and time). If the query fails because the table does not exist, stop: the demo database was not set up from migrations, and the next step needs a separate decision.
3. **Get one SQL file per missing migration.** Each file is written from the migration, reviewed against it line by line, and wrapped so that it skips itself if that migration is already recorded (the same pattern as the market-streets update of 2026-11-16). Agents write and review these files but **never connect to the demo database**.
4. **Run each file on the local throwaway database first**, then on the demo database in the VS Code PostgreSQL extension, oldest first. Running a file twice does nothing the second time.
5. Run the query from step 2 again: the newest migration name must now match the newest migration file.

Never run `dotnet ef database update` against the demo database.

### 11.2 Server

Since 2026-11-19 the demo server is **`marikina-market-server`**, an App Service that runs the **server package** (section 12) from the package store **`marikinamarketregistry`** (Azure Container Registry, Standard, resource group `marikina-market-rg`, East Asia). It fetches the package with its own managed identity (AcrPull role on the store), so no registry password is stored. Proof: `evidence/docker-d2-demo/results.md`. The earlier server `marikina-market-api` (files from `publish-api`) is kept only as the way back until the project owner deletes it: rebuild the website (11.3) with its address `https://marikina-market-api-e2drfvf7h5c5e9ak.eastasia-01.azurewebsites.net`.

1. **Build the package** from the current `main`, labelled with the commit. From `marikina-market-api`:

   ```powershell
   $tag = git rev-parse --short HEAD
   docker build -t marikinamarketregistry.azurecr.io/marikina-market-api:$tag .
   ```

2. **Upload it.** Sign in once per window with `az login` (if Azure answers that multi-factor sign-in is required, use `az login --tenant <directory id>`), then:

   ```powershell
   az acr login --name marikinamarketregistry
   docker push marikinamarketregistry.azurecr.io/marikina-market-api:$tag
   ```

3. **Point the server at the new label.** App Service fetches it and restarts *(confirm on the first package update after 2026-11-19)*:

   ```powershell
   az webapp config set -g marikina-market-rg -n marikina-market-server --linux-fx-version "DOCKER|marikinamarketregistry.azurecr.io/marikina-market-api:$tag"
   ```

   Check that `https://marikina-market-server.azurewebsites.net/api/does-not-exist` answers 404 with `{"message":"The requested resource was not found."}`, then sign in on the website. To go back to the previous version, run step 3 with the previous label.
4. The secrets are **settings on the App Service**, never files in the repository: Azure portal → the App Service → **Settings → Environment variables**. Names use `__` instead of `:`. **Your computer's User Secrets (section 3) are not sent to Azure**: they are stored in your Windows profile, not in the project, so publishing never copies them, and the server on Azure does not read User Secrets. Enter each value by hand once; it stays on the App Service across deploys, so you only change it when the value itself changes. Names only here; the values come from the project owner:

   | Setting name | What it is |
   | --- | --- |
   | `ConnectionStrings__DefaultConnection` | The demo database connection |
   | `Jwt__Secret` | Sign-in signing key |
   | `Email__FromAddress`, `Email__AppPassword` | The email account that sends sign-in codes and reset emails |
   | `BackBlazeB2__General__KeyId`, `BackBlazeB2__General__ApplicationKey` (and the same for `Documents`, `Evidence`, `Backups`) | Storage keys |
   | `Backups__EncryptionKey` | The backup key. Keep a copy outside Azure (see the recovery guide) |
   | `Firebase__ServiceAccountJson` | The Firebase Admin key: paste the whole service-account JSON file's content as the value (section 5) |
   | `WEBSITES_PORT` | `8080`, the port the server package listens on |
   | `Cors__AllowedOrigins__0` | The website's address on Static Web Apps, exactly as the browser shows it, without a slash at the end (for example `https://<name>.azurestaticapps.net`). Only this address may read the server's answers and send the sign-in cookie. If it is missing or different, the website cannot sign in. |

5. **Leave the App Service's own CORS page empty.** In the Azure portal, open the App Service and type `CORS` in the search box of its left menu. The list of allowed origins there must be empty. Microsoft: "If you try to use them together, App Service CORS takes precedence and your own CORS code has no effect" ([App Service CORS tutorial](https://learn.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-rest-api), checked 2026-11-18). If addresses are listed there, the server's own rule (`Cors__AllowedOrigins__0`) is ignored and the sign-in cookie is not allowed, so the website signs users out on every refresh or cannot sign in.

### 11.3 Website

The website runs on its own Static Web Apps address and calls the server on the App Service address. Two settings must point at each other:

| Where | Setting | Value |
| --- | --- | --- |
| Website build (step 1) | `VITE_API_BASE_URL` | The App Service address, for example `https://<app service address>` (no `/api`, no slash at the end) |
| App Service (section 11.2) | `Cors__AllowedOrigins__0` | The Static Web Apps address, for example `https://<name>.azurestaticapps.net` |

Known limit: the two addresses count as different sites to browsers, so the sign-in cookie is a "third-party" cookie. Chrome and Edge on Windows and Android are expected to keep it, so refreshing a page keeps the user signed in. Safari (iPhone, iPad, Mac) and private/incognito windows are expected to block it, so there a refresh signs the user out and they log in again. Removing this limit needs both parts on one bought domain.

1. In `marikina-market-web`: `npm ci`, then build with the server's address (the setting is built into the website, so build again whenever the address changes):

   ```powershell
   $env:VITE_API_BASE_URL = 'https://<app service address>'
   npm run build
   Remove-Item Env:VITE_API_BASE_URL
   ```

   The result is in `marikina-market-web/dist`. It includes `staticwebapp.config.json` (from `public/`), which makes refreshing a page such as `/tickets` load the website instead of "not found".
2. Get the deployment token: Azure portal → the Static Web App → **Overview → Manage deployment token**. It is a secret. Put it in this PowerShell window without typing it on a command line, then deploy from the project folder:

   ```powershell
   $secure = Read-Host 'Deployment token' -AsSecureString
   $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
   $env:SWA_CLI_DEPLOYMENT_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
   [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr); $secure = $null
   npx @azure/static-web-apps-cli deploy ./marikina-market-web/dist --env production
   Remove-Item Env:SWA_CLI_DEPLOYMENT_TOKEN
   ```

   The tool reads the token from `SWA_CLI_DEPLOYMENT_TOKEN` ([swa deploy documentation](https://azure.github.io/static-web-apps-cli/docs/cli/swa-deploy/), checked 2026-11-18). The form used before, `--deployment-token <TOKEN>`, leaves the token in PowerShell's history.
3. **If the token was ever shown, pasted or shared**, reset it on the same page (**Reset token**) before the next deploy.

### 11.4 Phone app

Build the phone app with the server's address in `firebase.local.json` (section 8): `API_BASE_URL` = `https://<app service address>/api`. Without it, the app falls back to an old development tunnel address.

### 11.5 Recommended actions: the daily job

Since 2026-11-19 the recommended actions are refreshed by **`marikina-market-recommendations`**, an Azure Container Apps job that runs the **model package** (section 13) every day at **4:00 AM Manila** (schedule `0 20 * * *`; Container Apps schedules are in UTC). Each run reads the warnings and tickets of the last 30 days, saves one recommendation run (the page's "Last updated") and stops; if anything fails, nothing is saved, so it is retried once. Proof: `evidence/docker-d3-model/results.md`. *(The first scheduled run, 2026-11-20 4:00 AM, is to be confirmed.)*

What it is made of (resource group `marikina-market-rg`, East Asia):

| Part | Name | Notes |
| --- | --- | --- |
| Job | `marikina-market-recommendations` | 1 CPU, 2 GB, stopped after 30 minutes, retried once |
| Environment | `marikina-market-jobs` | Consumption (paid per second of running; a run is inside the monthly free amount) |
| Run logs | `marikina-market-logs` (Log Analytics) | Kept 30 days; the first 5 GB a month are free |
| Identity | `marikina-market-jobs-identity` | May only fetch packages from `marikinamarketregistry` (AcrPull); no registry password |

Its settings are the standard PostgreSQL ones, taken from the demo server's `ConnectionStrings__DefaultConnection`: `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD` (stored as the job's secret `pgpassword`) and `PGSSLMODE` = `require`. If the database password changes, change it in the Azure portal: the job → **Settings → Secrets** → `pgpassword`.

1. **Build and upload the model package** (only when the model or the connector changes), from the project folder that holds the model (section 13):

   ```powershell
   $tag = git rev-parse --short HEAD
   docker build -t marikinamarketregistry.azurecr.io/marikina-market-model:$tag --build-context model="description-model/New Training Model/evaluation/frozen-final-v4" description-model
   az acr login --name marikinamarketregistry
   docker push marikinamarketregistry.azurecr.io/marikina-market-model:$tag
   ```

2. **Point the job at the new label** *(confirm on the first model package update after 2026-11-19)*:

   ```powershell
   az containerapp job update -g marikina-market-rg -n marikina-market-recommendations --image marikinamarketregistry.azurecr.io/marikina-market-model:$tag
   ```

3. **Run it once now** instead of waiting for 4:00 AM, then follow it until it says `Succeeded`:

   ```powershell
   az containerapp job start -g marikina-market-rg -n marikina-market-recommendations
   az containerapp job execution list -g marikina-market-rg -n marikina-market-recommendations -o table
   ```

   The run's summary line ("Run N: … records, … with findings, … section recommendations.") is in the Azure portal: the job → **Monitoring → Logs** (table `ContainerAppConsoleLogs_CL`), a few minutes after the run. The model's warning about an "incorrect regex pattern" is known (model plan step 1) and does not stop the run. Then check the Recommended Actions page's "Last updated". No cards means no street had two records of the same problem in the last 30 days.

**Setting it up again** (for example on another Azure account), in this order: register Container Apps once (`az provider register --namespace Microsoft.App --wait`); install the Azure CLI add-on (`az extension add --name containerapp`); create the Log Analytics workspace, then the Container Apps environment sending its logs there; create the identity and give it **AcrPull** on the package store; create the job with the settings above (schedule trigger `0 20 * * *`, parallelism 1, retry limit 1, timeout 1800 s, the package store with that identity). Write the job's description in a file and pass it with `--yaml`, so the database password never appears on a command line. The script used on 2026-11-19 is `evidence/docker-d3-model/Create-Job.ps1` (evidence folder, not in Git).

## 12. Docker: the server package

**Status: written 2026-11-19 (Docker slice D1, checked on the developer computer); running on the demo since 2026-11-19 (slice D2, `evidence/docker-d2-demo/results.md`).** The recipe `marikina-market-api/Dockerfile` turns the server into a **package** (a Docker image): the .NET 10 server plus PostgreSQL 18's `pg_dump`, which the Backups page runs. The same package runs the demo server on Azure (section 11.2). `marikina-market-api/.dockerignore` keeps the `Keys` folder, build output and tests out of it. No secret is inside the package: every setting in section 3 is given when it runs.

### 12.1 Install Docker Desktop (once per computer)

1. Download Docker Desktop for Windows from docker.com (free for personal use, education and small businesses).
2. Choose **All-users installation** and keep **WSL 2** ticked. It needs administrator rights, turns on the Windows feature "Virtual Machine Platform", and asks for a restart. (The per-user installation stops with "Docker Desktop requires the Virtual Machine Platform Windows feature" when that feature is off.)
3. Open Docker Desktop once and accept its terms. Check with `docker info` (prints the engine version).

### 12.2 Build

From `marikina-market-api`:

```powershell
docker build -t marikina-market-api .
```

The first build downloads Microsoft's .NET 10 images and PostgreSQL 18's client from PostgreSQL's package site (about 2 minutes); later builds reuse them. The package is about 560 MB.

### 12.3 Run on this computer

The package listens on port 8080 and starts in Production mode (no development certificate, no User Secrets, no Swagger). Give it its settings as environment variables with the Azure names (`__` instead of `:`, section 11.2), without `Backups__PgDumpPath`. Pass them by name only (`--env NAME`) after setting them in the current PowerShell window, so values never appear on a command line:

```powershell
docker run --detach --name mmt-server --publish 127.0.0.1:8090:8080 `
  --env ConnectionStrings__DefaultConnection --env Jwt__Secret --env Email__FromAddress --env Email__AppPassword `
  --env Backups__EncryptionKey --env Firebase__ServiceAccountJson --env Cors__AllowedOrigins__0 `
  --env BackBlazeB2__General__KeyId --env BackBlazeB2__General__ApplicationKey `
  --env BackBlazeB2__Documents__KeyId --env BackBlazeB2__Documents__ApplicationKey `
  --env BackBlazeB2__Evidence__KeyId --env BackBlazeB2__Evidence__ApplicationKey `
  --env BackBlazeB2__Backups__KeyId --env BackBlazeB2__Backups__ApplicationKey `
  marikina-market-api
```

- Port: `8090` on this computer because 8080 may be taken by another program; inside the package it is always 8080, as on Azure.
- Database on this computer: in the connection string use `Host=host.docker.internal` instead of `localhost`. Use only the disposable `marikina_market_e2e` database.
- Stop and remove it with `docker rm --force mmt-server`; read its log first with `docker logs mmt-server`.
- `docker inspect` shows the values given to a running package; remove it when done.

Running the server the usual way (`dotnet run`, section 4) is unchanged and does not need Docker.

## 13. Docker: the model package

**Status: written 2026-11-19 (Docker slice D3, checked on the developer computer and on Azure, `evidence/docker-d3-model/results.md`).** The recipe `description-model/Dockerfile` turns the recommended-actions model into a **package**: Python 3.12.10, the 59 add-ons in `description-model/requirements-lock.txt` (the exact versions proven in model plan step 1; `torch` without graphics-card support), the connector (`description-model/connector`) and the frozen final model. Each start does one recommendation run and stops. The daily Azure job runs it (section 11.5). No secret is inside: the database settings are given when it runs.

**The model is not in Git** (`description-model/New Training Model/` is ignored). The build takes it straight from that folder as a second input named `model`, so it only builds in a project folder that holds the model, and the model never enters Git. Only the final version's folder (`evaluation/frozen-final-v4`, 0.47 GB) is used; the model checks every one of its files against its recorded fingerprints when it starts and stops if anything differs. The connector reads that record's Windows-style file names (`\`) as `/` so the check also works on Linux.

### 13.1 Build

From the project folder (Docker Desktop, section 12.1):

```powershell
docker build -t marikina-market-model --build-context model="description-model/New Training Model/evaluation/frozen-final-v4" description-model
```

The first build downloads Python's image and the add-ons (about 4–5 minutes); later builds reuse them. The package is about 3.1 GB.

### 13.2 Check and run on this computer

- Connector tests inside the package: `docker run --rm --network none marikina-market-model python -B -m unittest -v test_recommendations` (7 tests).
- One run against the disposable `marikina_market_e2e` only: set `PGPORT`, `PGDATABASE`, `PGUSER` and `PGPASSWORD` in the current PowerShell window, then pass them by name, with the limits the Azure job has:

  ```powershell
  docker run --rm --cpus 1 --memory 2g --env PGHOST=host.docker.internal --env PGPORT --env PGDATABASE --env PGUSER --env PGPASSWORD marikina-market-model
  ```

  It prints "Run N: … records, … with findings, … section recommendations." On 2026-11-19 a run from the package and a run by hand on the same data gave the same findings and cards.

Running the model by hand with its own Python (`description-model/connector/run.py`) is unchanged and does not need Docker.
