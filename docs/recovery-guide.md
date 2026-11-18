# Recovery guide

For the person who looks after the Marikina Market Ticketing system. It covers what to do **before** trouble, how to **restore from a backup**, and what happens and what to do **when a service is down**.

Every step here comes from a test that was actually run, or is marked "not tested". The source of each step is in the table at the end. For setting the system up, see the [setup guide](environment-setup.md).

**Never** try a restore or an outage test on the real database. Practise on a throwaway copy.

## 1. Before trouble

- **Keep the backup key safe, and apart from the backups.** Backups are locked with the server setting `Backups:EncryptionKey` (on Azure: `Backups__EncryptionKey`). Without that exact key, no backup can ever be opened. Keep a copy somewhere safe that is not Azure and not the backup storage, for example a password manager. Do not replace the key casually: backups made with the old key can then no longer be opened.
- **Download a backup now and then and keep the file.** On the website: **Backups** → **Back Up Now**, then **Download**. The file ends in `.mmbak`. Keep it somewhere safe; it is locked with the key, but it holds all the data.
- **Know the tools you will need**: PostgreSQL's `psql` and `pg_restore`, and Node.js, on the computer you will restore from. The drill used PostgreSQL 18.6 on Windows; use the same main version as the database the backup came from.

## 2. Restore from a backup

The website's Restore button is switched off on purpose. A restore is done by hand, as below. These steps were run by the project owner on 2026-11-17 on a throwaway database, and worked.

Open PowerShell in the project folder. Set the tool folder and a new, empty work folder:

```powershell
$pg = 'C:\Program Files\PostgreSQL\18\bin'   # where psql.exe and pg_restore.exe are on your computer
$work = "$HOME\mmt-restore"                    # a new, empty folder
New-Item -ItemType Directory -Path $work       # fails if the folder exists: that is intended
```

In the commands below, replace `<host>` and `<user>` with your database server and login; `psql` asks for the password.

1. **Make sure nothing else is happening.** Sign in to the website as Head Admin and make sure no backup is running. Ask staff not to record anything until you finish.
2. **Count the records in the source** (only if the source database still exists). This read-only query counts every table:

   ```powershell
   $countQuery = @'
   select table_name,
          (xpath('/row/c/text()',
                 query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name), false, true, '')))[1]::text::bigint as row_count
   from information_schema.tables
   where table_schema = 'public' and table_type = 'BASE TABLE'
   order by table_name;
   '@
   $countQuery | Out-File "$work\count-rows.sql" -Encoding ascii
   & "$pg\psql.exe" -h <host> -U <user> -d <source database> -t -A -F "," -f "$work\count-rows.sql" | Out-File "$work\source-counts.csv" -Encoding utf8
   ```

3. **Get the backup file.** On the **Backups** page, **Back Up Now**, then **Download** into `$work`; or use a `.mmbak` file you kept. Note the size shown in the backup history: the downloaded file must be exactly that size.
4. **Unlock (decrypt) the file.** First put the backup key into this PowerShell window **without typing it on a command line** (PowerShell keeps a history of commands). Paste the key when asked; nothing is shown:

   ```powershell
   $secure = Read-Host 'Backup key' -AsSecureString
   $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
   $env:MMBAK_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
   [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr); $secure = $null
   ```

   Then unlock it, and remove the key from the window straight after:

   ```powershell
   node tools/recovery/decrypt-mmbak.mjs "$work\<downloaded file>.mmbak" "$work\restore.dump"
   echo "exit code: $LASTEXITCODE"
   Remove-Item Env:MMBAK_KEY
   ```

   Expect `decrypt-mmbak: wrote N bytes.` and `exit code: 0`. The tool refuses a wrong key, a changed or damaged file, a wrong file version and a file that is too short. When it refuses, it writes nothing. It never overwrites an existing file and never prints the key.

   **`restore.dump` is a full, unlocked copy of all the data.** Delete it in step 8.
5. **Create a new, empty database** for the restore (the command fails if the name already exists; that is intended):

   ```powershell
   $restoreDb = 'marikina_market_restore_20261118'   # use today's date
   & "$pg\psql.exe" -h <host> -U <user> -d postgres -c "CREATE DATABASE $restoreDb"
   ```

6. **Load the backup into it:**

   ```powershell
   & "$pg\pg_restore.exe" --exit-on-error --no-owner --no-privileges -h <host> -U <user> -d $restoreDb "$work\restore.dump"
   echo "exit code: $LASTEXITCODE"
   ```

   Expect `exit code: 0` and no error text.
7. **Count again and compare** (if you skipped step 2, still save `$countQuery` to `count-rows.sql` as in step 2, and skip the comparison):

   ```powershell
   & "$pg\psql.exe" -h <host> -U <user> -d $restoreDb -t -A -F "," -f "$work\count-rows.sql" | Out-File "$work\restored-counts.csv" -Encoding utf8
   Compare-Object (Get-Content "$work\source-counts.csv") (Get-Content "$work\restored-counts.csv")
   ```

   Every line shown is a difference. One difference is normal: the `backups` table has **one more** row in the restored copy, because each backup contains itself as an unfinished backup. Anything else needs checking before you go on.
8. **Clean up the unlocked copy:** delete `$work\restore.dump`. Keep the `.mmbak` file (see the warning below).
9. **Switch the system to the restored database.** Change the server's `ConnectionStrings:DefaultConnection` (on Azure: `ConnectionStrings__DefaultConnection`) to point at `$restoreDb`, start the server, sign in and check records you know exist and that a ticket photo opens.

> **Warning (finding F1): starting the system on a restored copy deletes the stored copy of the backup it came from.** Each backup contains itself as an unfinished backup. When the server starts on the restored copy, it marks that backup failed and deletes its file from backup storage within seconds. This was seen on 2026-11-17. The `.mmbak` file you downloaded is **not** affected, so **keep it** until a new backup has been made and downloaded from the restored system.

**Not tested:** restoring into an Azure database (the drill restored into local PostgreSQL 18.6 on Windows); typing the key with `Read-Host` as in step 4 (the drill read the key from the computer's saved secrets instead); switching an Azure server to the restored database (step 9; the drill started a separate local server on the restored copy).

## 3. When a service is down

What people see, what happens to the data, and what to do. Results from tests on 2026-11-17, where each service was made unreachable one at a time.

| Down | What people see | What happens to data | What to do |
| --- | --- | --- | --- |
| **Email** | Website sign-in and password reset fail with a general error ("login failed" or an error message), not a clear "email is down" message. | Nothing is sent and nothing is lost. | Check the email account and its app password (`Email:FromAddress`, `Email:AppPassword`). When email works again, sign-ins and reset emails work again with no other action. |
| **Backup/photo storage** (Backblaze B2) | A backup in progress waits, then ends **Failed** at its time limit (15 minutes by default) with "Backup was cancelled or exceeded its time limit." On the phone, submitting a ticket with photos shows "Submission could not be confirmed. Check this person's history before trying again." | The ticket is **not** saved; nothing half-saved is left. No leftover backup files. | Check the storage account and keys. When storage is back, leftover clean-up finishes by itself and the next backup works. Enforcers check the person's history, then submit again. (Re-submitting after storage returned was not tested.) |
| **Database** stopped for a short time | A running backup stops ("stopped after losing database ownership"). | The backup record is closed by itself; the server keeps running and needs no restart. | Start the database again. Then run **Back Up Now** once to be sure backups work. |
| **Server** stopped suddenly during a backup | Nothing until the server starts again. | On restart, the unfinished backup is marked Failed ("Backup was interrupted before completion.") and its leftover file is removed. | Start the server again; run **Back Up Now** once. |
| **Push notifications** (Firebase) | Phones may not get status notifications. | A failed push does not stop a ticket status change from saving (read in the code; **not tested** live). | No data action needed. |

Not tested: the whole internet off at once; the phone's sign-in-code message when email is down.

## Where each step comes from

| Guide part | Source |
| --- | --- |
| Keep the key safe; do not replace it casually | [setup guide](environment-setup.md), section 6, "Database dump and encryption" |
| Restore steps 1–8 | Restore drill of 2026-11-17: `docs/closed-work/phases/phase-4-restore-drill.md` and its runbook (steps 1–7, 10) |
| One extra `backups` row is normal | Same note, "Row counts, 30 tables" |
| Tool refuses wrong key / changed file / wrong version / short file | `tools/recovery/decrypt-mmbak.test.mjs` (9 tests) and the drill's failure-path step |
| Step 4, typing the key with `Read-Host` | New in this guide; not tested live |
| Step 9, switching to the restored database | Drill: restored copy opened in the app (a separate local server); Azure switch not tested |
| Warning F1 | Same note, "Finding F1" |
| Email, storage, push rows | `docs/closed-work/phases/phase-4-outage-and-restart-stories.md`, slice 2 (2b, 2a and 2d, 2c) |
| Database and server rows | Same note, slice 3 (3b, 3a) |
