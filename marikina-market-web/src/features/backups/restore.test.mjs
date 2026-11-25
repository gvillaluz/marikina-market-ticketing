import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import test from "node:test";
import vm from "node:vm";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import ts from "typescript";

// Restore from the Backups page (step 2): the Restore button, the confirm window,
// the restore view, and the banner other staff see while the system is paused.

const require = createRequire(import.meta.url);
const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);

function load(relative, overrides = {}, cache = new Map()) {
  const file = path.resolve(root, relative);
  if (cache.has(file)) return cache.get(file);
  const module = { exports: {} };
  cache.set(file, module.exports);
  const code = ts.transpileModule(fs.readFileSync(file, "utf8"), {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
      jsx: ts.JsxEmit.ReactJSX,
      esModuleInterop: true,
    },
  }).outputText;
  vm.runInNewContext(
    code,
    {
      module,
      exports: module.exports,
      Date,
      Intl,
      require(id) {
        if (id in overrides) return { __esModule: true, ...overrides[id] };
        if (id.endsWith(".css"))
          return {
            __esModule: true,
            default: new Proxy({}, { get: (_, key) => key }),
          };
        if (!id.startsWith(".") && !id.startsWith("@/")) return require(id);
        const base = id.startsWith("@/")
          ? path.resolve(root, id.slice(2))
          : path.resolve(path.dirname(file), id);
        const resolved = [
          base,
          `${base}.ts`,
          `${base}.tsx`,
          `${base}/index.ts`,
        ].find(
          (candidate) =>
            fs.existsSync(candidate) && fs.statSync(candidate).isFile(),
        );
        assert.ok(resolved, `Cannot resolve ${id}`);
        const alias = `@/${path
          .relative(root, resolved)
          .replaceAll("\\", "/")
          .replace(/\.tsx?$/, "")}`;
        if (alias in overrides)
          return { __esModule: true, ...overrides[alias] };
        return load(path.relative(root, resolved), overrides, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

function text(html) {
  return html
    .replace(/<[^>]+>/g, " ")
    .replaceAll("&#x27;", "'")
    .replaceAll("&amp;", "&")
    .replace(/\s+/g, " ")
    .trim();
}

// Values made inside the test sandbox compare by content only.
const plain = (value) => JSON.parse(JSON.stringify(value));
const utils = () => load("features/backups/backups.utils.ts");
const steps = (states) =>
  [
    "CheckBackup",
    "SafetyBackup",
    "LoadBackup",
    "SignEveryoneOut",
    "CountRecords",
  ].map((step, i) => ({
    step,
    state: states[i],
  }));
const progress = (state, overrides = {}) => ({
  restoreId: "a".repeat(32),
  backupId: 7,
  backupDateTime: "2026-11-23T16:00:00Z",
  state,
  steps: steps(["Done", "Done", "Running", "Running", "Waiting"]),
  counts: [],
  safetyBackupId: 9,
  message: null,
  startedAt: "2026-11-25T02:00:00Z",
  finishedAt: null,
  ...overrides,
});

test("R1: the confirm button works only when RESTORE is typed exactly and a password is entered", () => {
  const { canConfirmRestore, restoreConfirmHint } = utils();
  assert.equal(canConfirmRestore("RESTORE", "secret-1"), true);
  for (const [confirmation, password] of [
    ["restore", "secret-1"],
    ["RESTORE ", "secret-1"],
    ["RESTOR", "secret-1"],
    ["", "secret-1"],
    ["RESTORE", ""],
  ])
    assert.equal(
      canConfirmRestore(confirmation, password),
      false,
      `${confirmation}/${password}`,
    );
  assert.equal(
    restoreConfirmHint("", ""),
    "Type RESTORE in capital letters, then enter your password.",
  );
  assert.equal(
    restoreConfirmHint("restore", "secret-1"),
    "Type RESTORE in capital letters.",
  );
  assert.equal(restoreConfirmHint("RESTORE", ""), "Enter your password.");
  assert.equal(restoreConfirmHint("RESTORE", "secret-1"), "");
});

test("R2: safety backups are called Before restore in the list", () => {
  const { backupTypeLabel } = utils();
  assert.equal(backupTypeLabel("BeforeRestore"), "Before restore");
  assert.equal(backupTypeLabel("Automatic"), "Automatic");
  assert.equal(backupTypeLabel("Manual"), "Manual");
});

function renderRow(row) {
  const { default: BackupHistoryRow } = load(
    "features/backups/components/BackupHistoryRow.tsx",
  );
  return renderToStaticMarkup(
    React.createElement(
      "table",
      null,
      React.createElement(
        "tbody",
        null,
        React.createElement(BackupHistoryRow, {
          backup: row,
          onDownload() {},
          onRestore() {},
        }),
      ),
    ),
  );
}
const row = (overrides = {}) => ({
  id: 7,
  dateLabel: "Nov 24, 2026, 12:00 AM",
  typeLabel: "Automatic",
  sizeLabel: "4.2 MB",
  status: "Completed",
  errorMessage: null,
  downloadDisabled: false,
  isDownloading: false,
  canDownload: true,
  restoreDisabled: false,
  ...overrides,
});

test("R3: a restorable backup has a working Restore button named after it", () => {
  const html = renderRow(row());
  const restore = html.match(
    /<button[^>]*aria-label="Restore backup from Nov 24, 2026, 12:00 AM"[^>]*>/,
  )?.[0];
  assert.ok(restore, html);
  assert.doesNotMatch(restore, /disabled/);
});

test("R4: a backup that can no longer be restored keeps a greyed-out Restore button with the reason", () => {
  const html = renderRow(
    row({
      status: "Failed",
      canDownload: false,
      downloadDisabled: true,
      restoreDisabled: true,
    }),
  );
  const restore = html.match(
    /<button[^>]*aria-label="Restore backup from[^"]*"[^>]*>/,
  )?.[0];
  assert.ok(restore, html);
  assert.match(restore, /disabled=""/);
  assert.match(restore, /title="This backup can no longer be restored."/);
});

test("R5: the Type column shows Before restore for a safety backup", () => {
  assert.ok(
    text(renderRow(row({ typeLabel: "Before restore" }))).includes(
      "Before restore",
    ),
  );
});

test("R6: the confirm window says what is lost, what is kept, and what happens to everyone", () => {
  const { default: RestoreConfirmDetails } = load(
    "features/backups/components/RestoreConfirmDetails.tsx",
  );
  const html = renderToStaticMarkup(
    React.createElement(RestoreConfirmDetails, {
      dateLabel: "Nov 24, 2026, 12:00 AM",
      confirmation: "resto",
      password: "",
      passwordVisible: false,
      hint: "Type RESTORE in capital letters.",
      error: "",
      disabled: false,
      onConfirmationChange() {},
      onPasswordChange() {},
      onTogglePassword() {},
    }),
  );
  const words = text(html);
  assert.ok(
    words.includes(
      "Everything recorded after Nov 24, 2026, 12:00 AM will be lost for everyone.",
    ),
    words,
  );
  assert.ok(
    words.includes(
      "Kept from today: the audit log, the backup list and the backup schedule.",
    ),
    words,
  );
  assert.ok(
    words.includes("A safety backup of today's data is made first."),
    words,
  );
  assert.ok(
    words.includes("Everyone is paused while it runs, then signed out."),
    words,
  );
  assert.ok(words.includes("Type RESTORE in capital letters."), words);
  assert.match(
    html,
    /<input[^>]*autoComplete="off"[^>]*>|<input[^>]*autocomplete="off"[^>]*>/i,
  );
  assert.match(
    html,
    /<input[^>]*type="password"[^>]*autocomplete="current-password"|<input[^>]*autocomplete="current-password"[^>]*type="password"/i,
  );
  assert.match(html, /aria-label="Show password"/);
});

test("R7: while it runs, the view shows the steps in order and which one is running", () => {
  const { getRestoreView } = utils();
  const view = getRestoreView(
    progress("Running"),
    "Nov 24, 2026, 12:00 AM",
    "ok",
  );
  assert.equal(view.title, "Restoring a backup");
  assert.equal(view.statusLine, "Step 3 of 5: Loading the backup");
  assert.equal(view.action, null);
  assert.deepEqual(
    view.steps.map((s) => [s.label, s.state]),
    [
      ["Checking the backup", "Done"],
      ["Making a safety backup of today's data", "Done"],
      ["Loading the backup", "Running"],
      ["Signing everyone out", "Running"],
      ["Counting the records", "Waiting"],
    ],
  );
});

test("R8: when it finishes, the view shows the server's result, the counts and Sign in again", () => {
  const { getRestoreView } = utils();
  const view = getRestoreView(
    progress("Finished", {
      steps: steps(["Done", "Done", "Done", "Done", "Done"]),
      message:
        "The backup was restored. Everyone has been signed out and must sign in again.",
      counts: [
        { records: "Tickets", before: 1284, after: 1271 },
        { records: "Accounts", before: 18, after: 18 },
      ],
    }),
    "Nov 24, 2026, 12:00 AM",
    "ok",
  );
  assert.equal(view.title, "Backup restored");
  assert.equal(view.tone, "success");
  assert.equal(
    view.message,
    "The backup was restored. Everyone has been signed out and must sign in again.",
  );
  assert.equal(view.action, "signIn");
  assert.deepEqual(plain(view.counts), [
    ["Tickets", "1,284", "1,271"],
    ["Accounts", "18", "18"],
  ]);
});

test("R9: when it fails, the view shows the server's reason and a way back to the backups", () => {
  const { getRestoreView } = utils();
  const view = getRestoreView(
    progress("Failed", {
      steps: steps(["Failed", "Waiting", "Waiting", "Waiting", "Waiting"]),
      message:
        "This backup is from a different version of the system, so it cannot be restored here. Ask the technical person to restore it with the recovery guide.",
    }),
    "Nov 24, 2026, 12:00 AM",
    "ok",
  );
  assert.equal(view.title, "Restore did not finish");
  assert.equal(view.tone, "failed");
  assert.equal(view.action, "back");
  assert.match(view.message, /different version/);
  assert.deepEqual(plain(view.counts), []);
});

test("R10: if the server no longer knows the restore, the view says so and offers Sign in again", () => {
  const { getRestoreView } = utils();
  const view = getRestoreView(
    progress("Running"),
    "Nov 24, 2026, 12:00 AM",
    "lost",
  );
  assert.equal(view.title, "Restore result unknown");
  assert.equal(view.action, "signIn");
  assert.match(view.message, /audit log/);
});

test("R11: if the server stops answering for a moment, the view keeps waiting and says so", () => {
  const { getRestoreView } = utils();
  const view = getRestoreView(
    progress("Running"),
    "Nov 24, 2026, 12:00 AM",
    "unreachable",
  );
  assert.equal(view.title, "Restoring a backup");
  assert.equal(
    view.note,
    "The server is not answering right now. Still checking…",
  );
  assert.equal(view.action, null);
});

test("R12: the restore view renders the steps, the counts table and its one button", () => {
  const { default: RestoreView } = load(
    "features/backups/components/RestoreView.tsx",
  );
  const { getRestoreView } = utils();
  const view = getRestoreView(
    progress("Finished", {
      steps: steps(["Done", "Done", "Done", "Done", "Done"]),
      message:
        "The backup was restored. Everyone has been signed out and must sign in again.",
      counts: [{ records: "Tickets", before: 3, after: 2 }],
    }),
    "Nov 24, 2026, 12:00 AM",
    "ok",
  );
  const html = renderToStaticMarkup(
    React.createElement(RestoreView, { view, onSignIn() {}, onBack() {} }),
  );
  const words = text(html);
  assert.ok(words.includes("Backup restored"), words);
  assert.match(html, /<ol[^>]*>/);
  assert.equal((html.match(/<li/g) || []).length, 5);
  assert.match(html, /<table[^>]*>.*Before.*After.*Tickets.*3.*2/s);
  assert.match(html, /<button[^>]*>.*Sign in again.*<\/button>/s);
  assert.doesNotMatch(words, /Back to backups/);
  assert.match(html, /role="status"/);
});

test("R13: the pause answer from the server is recognised, other answers are not", () => {
  const { isRestorePauseAnswer } = load("utils/apiErrors.ts");
  const body = {
    title: "System restore in progress",
    message: "The system is being restored. Try again in a few minutes.",
  };
  assert.equal(isRestorePauseAnswer(503, body), true);
  assert.equal(
    isRestorePauseAnswer(503, {
      message: "Unable to send your sign-in code. Please try again shortly.",
    }),
    false,
  );
  assert.equal(isRestorePauseAnswer(500, body), false);
  assert.equal(isRestorePauseAnswer(undefined, undefined), false);
});

test("R14: other staff see the pause banner across the page while the system is paused, and not otherwise", () => {
  // Rendering on the test side always shows the store's starting value, so the store is replaced here.
  const banner = (paused) => {
    const { default: RestorePauseBanner } = load(
      "components/layout/RestorePauseBanner/RestorePauseBanner.tsx",
      {
        "@/store/store": {
          useRestorePauseStore: (select) => select({ paused }),
        },
        "@/hooks/useRestorePauseCheck": { useRestorePauseCheck() {} },
      },
    );
    return renderToStaticMarkup(React.createElement(RestorePauseBanner));
  };
  assert.equal(banner(false), "");
  const html = banner(true);
  assert.match(html, /role="status"/);
  assert.ok(
    text(html).includes(
      "The system is being restored. Try again in a few minutes.",
    ),
    html,
  );
});

test("R15: the pause flag is set by the pause answer and cleared again", () => {
  const { useRestorePauseStore } = load("store/store.ts");
  assert.equal(useRestorePauseStore.getState().paused, false);
  useRestorePauseStore.getState().setPaused(true);
  assert.equal(useRestorePauseStore.getState().paused, true);
  useRestorePauseStore.getState().setPaused(false);
  assert.equal(useRestorePauseStore.getState().paused, false);
});
