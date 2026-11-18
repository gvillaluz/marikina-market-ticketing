# User secrets list

The names of the secret settings the server needs, what each one is, and where to set it. **Names only. Never write a value into this file or anywhere in the project.** Keep the values in a password manager.

Checked 2026-11-18 against the code, `marikina-market-api/MarikinaMarket.API/user-secrets.example.json`, and the names (not the values) in the project owner's own User Secrets.

## Where they go

| Where the server runs | How the values get there |
| --- | --- |
| **Your computer** | By hand, once per computer: copy `user-secrets.example.json` to `user-secrets.local.json`, fill it in, and import it (setup guide, section 3). Cloning the project never brings them. |
| **Azure (the demo)** | By hand, once, in the Azure portal: App Service → **Settings → Environment variables**, using the **Azure name** below. They stay there across deploys. Your computer's User Secrets are never sent to Azure. |

## Settings the server needs

| Name on your computer | Name on Azure | What it is | Where to get it |
| --- | --- | --- | --- |
| `ConnectionStrings:DefaultConnection` | `ConnectionStrings__DefaultConnection` | Database connection (server, database, login, password) | Your local PostgreSQL; on Azure, the Azure Database for PostgreSQL connection |
| `Jwt:Secret` | `Jwt__Secret` | Key that signs sign-ins | Generate a new random one (setup guide, section 3). Changing it signs everyone out |
| `Email:FromAddress` | `Email__FromAddress` | Email account that sends sign-in codes and reset emails | The project's email account |
| `Email:AppPassword` | `Email__AppPassword` | That account's app password | The email provider's app-password page |
| `BackBlazeB2:General:KeyId` | `BackBlazeB2__General__KeyId` | Storage key ID, General bucket | Backblaze → Application Keys |
| `BackBlazeB2:General:ApplicationKey` | `BackBlazeB2__General__ApplicationKey` | Storage key, General bucket | Shown once when the key is created |
| `BackBlazeB2:Documents:KeyId` | `BackBlazeB2__Documents__KeyId` | Storage key ID, Documents bucket | Backblaze → Application Keys |
| `BackBlazeB2:Documents:ApplicationKey` | `BackBlazeB2__Documents__ApplicationKey` | Storage key, Documents bucket | Shown once when the key is created |
| `BackBlazeB2:Evidence:KeyId` | `BackBlazeB2__Evidence__KeyId` | Storage key ID, Evidence (photo) bucket | Backblaze → Application Keys |
| `BackBlazeB2:Evidence:ApplicationKey` | `BackBlazeB2__Evidence__ApplicationKey` | Storage key, Evidence bucket | Shown once when the key is created |
| `BackBlazeB2:Backups:KeyId` | `BackBlazeB2__Backups__KeyId` | Storage key ID, Backups bucket | Backblaze → Application Keys |
| `BackBlazeB2:Backups:ApplicationKey` | `BackBlazeB2__Backups__ApplicationKey` | Storage key, Backups bucket | Shown once when the key is created |
| `Backups:EncryptionKey` | `Backups__EncryptionKey` | Key that locks every backup. **Without it no backup can be opened** | Keep the existing one safe (recovery guide, section 1). Only generate a new one for a brand-new system |
| `Backups:PgDumpPath` | `Backups__PgDumpPath` | Where `pg_dump.exe` is (not secret, but differs per computer) | Your PostgreSQL install folder, for example `C:\Program Files\PostgreSQL\18\bin\pg_dump.exe` |
| `Cors:AllowedOrigins:0` | `Cors__AllowedOrigins__0` | Website address allowed to call the server (not secret) | On Azure: the Static Web Apps address. Not in your computer's User Secrets today (local development goes through the website's `/api` forwarding) |

## Not a setting: the Firebase Admin key file

The server also needs the file `Keys/marikina-market-firebase-adminsdk-fbsvc-d28eb0ee73.json` beside it (in `marikina-market-api/MarikinaMarket.API/Keys/` on your computer, in `publish-api/Keys/` for Azure). It holds a private key: copy it by hand, never commit it. Git already leaves it out.

## Test-only settings (your computer only, never Azure)

Your computer's User Secrets also hold settings used only by the automated live tests against the throwaway database `marikina_market_e2e`. The app itself does not need them, and they must never be put on Azure.

| Name | What it is |
| --- | --- |
| `E2E:Runtime:ConnectionString` | Connection to the throwaway test database |
| `E2E:Accounts:marikina_market_e2e:headadmin:Username`, `...:Password` | Test Head Admin account |
| `E2E:Accounts:marikina_market_e2e:enforcer1:Username`, `...:Password` | Test enforcer account |
| `E2E:Email:FromAddress`, `E2E:Email:AppPassword`, `E2E:Email:SmtpHost`, `E2E:Email:SmtpPort`, `E2E:Email:Recipient`, `E2E:Email:ConfiguredSenderAuthorized` | Email settings for the email tests |

## Moving to another computer

1. Clone the project from GitHub.
2. Bring the values over from your password manager (not by copying files through chat or email), fill `user-secrets.local.json`, import it (setup guide, section 3), then delete `user-secrets.local.json`.
3. Copy the Firebase Admin key file into `Keys/`.
4. Nothing changes on Azure: its settings stay where they are.
