# Deployment guide: updating the demo

This guide is for **putting a new version of the system on the demo** on Azure. Follow the steps in order. Each step says what it does, what to type or click, and what you should see.

- For setting up a new computer to work on the project, see the [setup guide](environment-setup.md).
- For getting data back from a backup, see the [recovery guide](recovery-guide.md).

Written 2026-11-20 from the steps used and checked on 2026-11-16 to 2026-11-20. Two steps have not yet been done exactly as written; they are marked **(not yet tried)**. Check them carefully the first time.

## The demo at a glance

The demo has five parts. All of them are in the Azure resource group **`marikina-market-rg`**: in the [Azure portal](https://portal.azure.com), type the name in the search bar at the top.

| Part | What it is | Name in Azure | Address |
| --- | --- | --- | --- |
| Database | Stores all the data | `marikina-market-db` (PostgreSQL 18, Southeast Asia) | — |
| Server | The program the website and phone app talk to | `marikina-market-server` (App Service, East Asia) | `https://marikina-market-server.azurewebsites.net` |
| Website | What administrators open in the browser | `market-ticketing` (Static Web App) | `https://ashy-mud-0d9f37900.6.azurestaticapps.net` |
| Phone app | What enforcers install on their phones | not on Azure: an installable file (APK) | — |
| Daily recommendations | Refreshes the Recommended Actions page every day at 4:00 AM | `marikina-market-recommendations` (Container Apps job) | — |

Two more things in the same resource group support them:

- **`marikinamarketregistry`**, the package store. The server and the daily job are kept there as **packages**: ready-to-run copies of the program, each labelled with the code version it was built from.
- **`marikina-market-logs`**, where the daily job writes what it did (kept 30 days).

**The old server `marikina-market-api`** is the server used before 2026-11-19. Nothing uses it any more except phone apps built before that date. It is kept only as a way back until it is deleted (see "If something goes wrong").

## The order, and why

Always update in this order, skipping the parts that did not change:

**1. Backup → 2. Database → 3. Server → 4. Website → 5. Phone app**

- The **backup** comes first, so you can go back if something fails.
- The **database** comes before the server, because a new server may need new tables or columns.
- The **server** comes before the website and phone app, because they may use something new on the server.
- **6. Daily recommendations** only needs updating when the recommendation model or its connector (`description-model/connector`) changes.
- Finish with **7. Checks after updating**.

## Before you start

You need these on your computer (once):

| Tool | Needed for | How to check it is there |
| --- | --- | --- |
| Docker Desktop (running) | Steps 3 and 6 | `docker info` prints the version. Install: [setup guide](environment-setup.md), section 12.1 |
| Azure CLI (`az`) | Steps 3 and 6 | `az version` |
| Flutter and Android tools | Step 5 | `flutter --version`; the phone app's setup is in the [setup guide](environment-setup.md), section 8 |
| VS Code with the PostgreSQL extension | Step 2 | — |
| Access to the GitHub repository | Step 4 | You can open its **Actions** tab |

**Use the main project folder, on the latest `main`.** Your work copies do not have the git-ignored files that steps 5 and 6 need (the phone app's Firebase files and the recommendation model). In the project folder:

```powershell
git switch main
git pull
```

**Sign in to Azure** in the PowerShell window you will use (once per window):

```powershell
az login
```

If it answers that multi-factor sign-in is required, use `az login --tenant <directory id>`. The directory id is in the Azure portal: **Microsoft Entra ID → Overview → Tenant ID**.

If PowerShell says `az` or `docker` "is not recognized", the window was opened before the tool was installed: close it and open a new one.

## 1. Backup

1. On the demo website, sign in as Head Admin and open **Backups**.
2. Click **Back Up Now** and wait until the new backup shows **Completed**.
3. Click **Download** on it and keep the file somewhere safe outside the project.

To check that a downloaded backup opens, or to restore one, see the [recovery guide](recovery-guide.md).

## 2. Database (only when the server's code has database changes)

The server's database changes are files in `marikina-market-api/MarikinaMarket.API/Infrastructure/Migrations/`. Each has a name that starts with a date and time.

1. **See which changes the demo already has.** In VS Code's PostgreSQL extension, connect to the demo database and run this. It only reads:

   ```sql
   SELECT migration_id FROM "__EFMigrationsHistory" ORDER BY migration_id DESC LIMIT 5;
   ```

   Compare the newest name it shows with the newest file in the `Migrations` folder. If they are the same, the database is up to date: go to step 3. If the query fails because the table does not exist, stop and ask: the next step needs a separate decision.
2. **Get one SQL file for each missing change.** Ask Claude to write them. Each file is checked line by line against its change and skips itself if that change is already on the database. Claude never connects to the demo database.
3. **Run each file on your local test database first**, then on the demo database in VS Code, oldest first. Running a file twice does nothing the second time.
4. Run the query from step 1 again. The newest name must now match the newest file.

**Never run `dotnet ef database update` against the demo database.**

## 3. Server

This builds a new server package from `main`, uploads it to the package store, and tells the server to use it. The label is the code version (for example `f146f76`), so you always know which version is running.

1. **Build the package.** In the `marikina-market-api` folder (Docker Desktop must be running):

   ```powershell
   $tag = git rev-parse --short HEAD
   docker build -t marikinamarketregistry.azurecr.io/marikina-market-api:$tag .
   ```

   You should see it finish without errors (about 2 minutes the first time).
2. **Upload it** to the package store:

   ```powershell
   az acr login --name marikinamarketregistry
   docker push marikinamarketregistry.azurecr.io/marikina-market-api:$tag
   ```

   You should see `Login Succeeded`, then the upload ends with a line containing `digest: sha256:`. If it says "no such host", wait a minute and try again.
3. **Tell the server to use it** **(not yet tried)**. The server fetches the new package and restarts by itself:

   ```powershell
   az webapp config set -g marikina-market-rg -n marikina-market-server --linux-fx-version "DOCKER|marikinamarketregistry.azurecr.io/marikina-market-api:$tag"
   ```

4. **Check it**, after 1–2 minutes: open `https://marikina-market-server.azurewebsites.net/api/does-not-exist` in the browser. It must show `{"message":"The requested resource was not found."}`. That means the server is running. (A page that does not load means it is still starting; wait and refresh.)

**The server's settings** (database connection, keys, email account and so on) stay on the server across updates. You only change them when a value itself changes: Azure portal → `marikina-market-server` → **Settings → Environment variables**. Their names, never their values:

| Setting name | What it is |
| --- | --- |
| `ConnectionStrings__DefaultConnection` | How the server reaches the database |
| `Jwt__Secret` | The key that signs sign-ins |
| `Email__FromAddress`, `Email__AppPassword` | The email account that sends sign-in codes and reset emails |
| `BackBlazeB2__General__KeyId`, `BackBlazeB2__General__ApplicationKey`, and the same for `Documents`, `Evidence`, `Backups` | File storage keys |
| `Backups__EncryptionKey` | The backup key. Keep a copy outside Azure (see the recovery guide) |
| `Firebase__ServiceAccountJson` | The Firebase key, for phone notifications: the whole Firebase service-account file's content |
| `Cors__AllowedOrigins__0` | The website's address, exactly `https://ashy-mud-0d9f37900.6.azurestaticapps.net` (no slash at the end). Only this address may use the server from a browser. If it is wrong, the website cannot sign in. |
| `WEBSITES_PORT` | `8080`, the port the server package listens on |

Keep the server's own **CORS** page in Azure **empty** (portal → `marikina-market-server` → type `CORS` in its left menu's search box). If addresses are listed there, the server's own rule above is ignored and the website signs users out on every refresh.

## 4. Website

The website is built and uploaded by GitHub when you press a button. It always uses the code on `main`.

1. Open the repository on GitHub → **Actions** → **Deploy website** (left list; if it is not there, use [this link](https://github.com/gvillaluz/marikina-market-ticketing/actions/workflows/deploy-website.yml)).
2. Click **Run workflow**, keep branch `main`, and click the green **Run workflow**.
3. Wait about 2 minutes, until the run shows a green tick. A red cross means it stopped before uploading, so the live website did not change; open the run to see why.

The website's settings are in `.github/workflows/deploy-website.yml`: the server's address (`VITE_API_BASE_URL`). If the server's address ever changes, change it there and press the button again. The upload password is the GitHub secret `AZURE_STATIC_WEB_APPS_API_TOKEN` (repository **Settings → Secrets and variables → Actions**). If it is ever reset in Azure (`market-ticketing` → **Overview → Manage deployment token**), paste the new one there.

**Known limit:** the website and the server have different addresses, so browsers treat the sign-in cookie as coming from another site. Chrome and Edge keep it (a refresh keeps you signed in). Safari (iPhone, iPad, Mac) and private windows block it, so a refresh signs you out there and you log in again.

If GitHub is not available, build and upload it from your computer instead: see [Appendix A](#appendix-a-website-from-your-computer).

## 5. Phone app

The phone app is not on Azure. You build an installable file (an **APK**) on your computer, copy it to each phone and install it. The server's address is built into the file.

1. **Build it.** In the `marikina-market-mobile` folder of the main project folder:

   ```powershell
   flutter build apk --release --dart-define-from-file=firebase.local.json --dart-define=API_BASE_URL=https://marikina-market-server.azurewebsites.net/api
   ```

   - `firebase.local.json` gives the Firebase keys (your local file; it is not changed).
   - `API_BASE_URL` gives the demo server's address, with `/api` at the end. Without it, the app would try an old development address and could not sign in.

   It takes a few minutes. The file is `marikina-market-mobile/build/app/outputs/flutter-apk/app-release.apk`.
2. **Copy it to the phone**: by USB cable, Google Drive, or a messaging app. Keep a copy of each version you share, in case you need to go back.
3. **Install it** on the phone: open the file, and allow "install unknown apps" for the app you opened it with when Android asks.
   - **If Android says the app "conflicts" or will not install,** the phone has a copy built on a different computer. Uninstall the old app first, then install. Each computer signs the app with its own key, and the project has no shared key yet. Uninstalling only signs the user out; the data is on the server.
4. **Check it** on the phone: sign in as an enforcer, open the inspections list, and issue a test record if needed.

Phones with an app built before 2026-11-19 still point at the old server. They must get the new file before the old server is deleted.

## 6. Daily recommendations (only when the model or connector changes)

The daily job runs the recommendation model every day at 4:00 AM Manila: it reads the warnings and tickets of the last 30 days and updates the Recommended Actions page. It only needs updating when `description-model/` changes.

1. **Build and upload the model package** from the main project folder (it holds the model, which is not in Git). It takes about 5 minutes the first time and is about 3 GB:

   ```powershell
   $tag = git rev-parse --short HEAD
   docker build -t marikinamarketregistry.azurecr.io/marikina-market-model:$tag --build-context model="description-model/New Training Model/evaluation/frozen-final-v4" description-model
   az acr login --name marikinamarketregistry
   docker push marikinamarketregistry.azurecr.io/marikina-market-model:$tag
   ```

2. **Tell the job to use it** **(not yet tried)**:

   ```powershell
   az containerapp job update -g marikina-market-rg -n marikina-market-recommendations --image marikinamarketregistry.azurecr.io/marikina-market-model:$tag
   ```

3. **Run it once now** instead of waiting for 4:00 AM:

   ```powershell
   az containerapp job start -g marikina-market-rg -n marikina-market-recommendations
   ```

   After a minute or two, see whether it worked:

   ```powershell
   az containerapp job execution list -g marikina-market-rg -n marikina-market-recommendations -o table
   ```

   The newest line must say `Succeeded`.
4. **See what it found**: Azure portal → `marikina-market-recommendations` → **Monitoring → Logs**, a few minutes after the run. Look for the line "Run N: … records, … with findings, … section recommendations." A warning about an "incorrect regex pattern" is normal. Then the website's **Recommended Actions** page shows the new "Last updated" time.

**Why the page can have no cards:** a card needs **at least 2 records with the same problem in the same street** within the last 30 days, and the model only finds a problem when the description clearly says what was seen.

The job's database password is kept as a secret in the job itself. If the database password changes: Azure portal → `marikina-market-recommendations` → **Settings → Secrets** → `pgpassword`.

## 7. Checks after updating

On the website (sign in as Head Admin):

1. Sign in works, including the email code.
2. Refresh the page (Chrome or Edge): you stay signed in.
3. **Tickets** and **Dashboard** load with their data.
4. If the server was updated: **Backups → Back Up Now** completes.

On a phone (if the phone app was updated): sign in, open the inspections list.

## If something goes wrong

| Part | How to go back |
| --- | --- |
| Data | Restore the backup from step 1: [recovery guide](recovery-guide.md) |
| Server | Point it back at the previous label (step 3, part 3, with the old label). The labels in the store: `az acr repository show-tags -n marikinamarketregistry --repository marikina-market-api -o table`. Until it is deleted, the old server `marikina-market-api` also still runs the version from before 2026-11-19 |
| Website | On GitHub, revert the change that broke it (the pull request's **Revert** button), merge, and press **Deploy website** again |
| Phone app | Install the previous APK you kept (uninstall first if Android refuses) |
| Daily job | Point it back at the previous label (step 6, part 2), with the labels from `az acr repository show-tags -n marikinamarketregistry --repository marikina-market-model -o table` |

To see what the server is doing, Azure portal → `marikina-market-server` → **Monitoring → Log stream**.

## Costs

| Part | Cost |
| --- | --- |
| Server plan (Basic B1, shared by both servers) | About US$13 a month |
| Database (B1ms) | Free for the first 12 months of the account, then charged |
| Package store (Standard) | Free for the first 12 months of the account, then charged |
| Daily job and its logs | Inside the monthly free amounts (a run takes about a minute; logs: first 5 GB a month free) |
| Website (Static Web Apps, Free plan) | Free |

**The Azure account is a free trial. Upgrade it to pay-as-you-go before about 11 December 2026,** or Azure switches off the whole demo. The free 12-month amounts continue after the upgrade.

## Appendix A: website from your computer

Use this only when the **Deploy website** button cannot be used. It does the same as the button, on your computer.

1. In the `marikina-market-web` folder, install its packages and build it with the server's address:

   ```powershell
   npm ci
   $env:VITE_API_BASE_URL = 'https://marikina-market-server.azurewebsites.net'
   npm run build
   Remove-Item Env:VITE_API_BASE_URL
   ```

   The result is in `marikina-market-web/dist`. It includes `staticwebapp.config.json`, which makes refreshing a page such as `/tickets` load the website instead of "not found".
2. Get the upload password: Azure portal → `market-ticketing` → **Overview → Manage deployment token**. It is a secret: put it in the PowerShell window without typing it on a command line, then upload from the project folder:

   ```powershell
   $secure = Read-Host 'Deployment token' -AsSecureString
   $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
   $env:SWA_CLI_DEPLOYMENT_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
   [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr); $secure = $null
   npx @azure/static-web-apps-cli deploy ./marikina-market-web/dist --env production
   Remove-Item Env:SWA_CLI_DEPLOYMENT_TOKEN
   ```

   The tool reads the password from `SWA_CLI_DEPLOYMENT_TOKEN` ([swa deploy documentation](https://azure.github.io/static-web-apps-cli/docs/cli/swa-deploy/), checked 2026-11-18). Do not use `--deployment-token <TOKEN>`: it leaves the password in PowerShell's history.
3. **If the password was ever shown, pasted or shared,** reset it on the same page (**Reset token**), then update the GitHub secret `AZURE_STATIC_WEB_APPS_API_TOKEN` too.

## Appendix B: setting up the daily job again

Only needed on a new Azure account, or if the job is deleted. In this order:

1. Turn on Container Apps once: `az provider register --namespace Microsoft.App --wait`.
2. Install the Azure CLI add-on: `az extension add --name containerapp`.
3. Create the log store (Log Analytics workspace), then the Container Apps environment that sends its logs there.
4. Create an identity and give it the **AcrPull** permission on the package store, so it can fetch packages without a password.
5. Create the job: schedule `0 20 * * *` (Azure schedules are in UTC; this is 4:00 AM Manila), 1 CPU, 2 GB, 1 run at a time, retried once, stopped after 1800 seconds, fetching the package with that identity. Its settings are `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` (from the server's `ConnectionStrings__DefaultConnection`), `PGPASSWORD` as the secret `pgpassword`, and `PGSSLMODE` = `require`.

Write the job's description in a file and pass it with `--yaml`, so the database password never appears on a command line. The script used on 2026-11-19 is `evidence/docker-d3-model/Create-Job.ps1` (evidence folder, not in Git).
