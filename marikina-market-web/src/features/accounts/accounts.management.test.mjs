import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import test from "node:test";
import vm from "node:vm";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import ts from "typescript";

const require = createRequire(import.meta.url);
const root = path.resolve(
  path.dirname(new URL(import.meta.url).pathname.replace(/^\/(\w:)/, "$1")),
  "../..",
);
function load(relative, overrides = {}, cache = new Map()) {
  const file = path.resolve(root, relative);
  if (cache.has(file)) return cache.get(file);
  const module = { exports: {} };
  cache.set(file, module.exports);
  const output = ts.transpileModule(fs.readFileSync(file, "utf8"), {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
      jsx: ts.JsxEmit.ReactJSX,
      esModuleInterop: true,
    },
  }).outputText;
  vm.runInNewContext(
    output,
    {
      module,
      exports: module.exports,
      URL,
      Error,
      Date,
      window: { requestAnimationFrame: (fn) => fn() },
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
          `${base}/index.tsx`,
        ].find((p) => fs.existsSync(p) && fs.statSync(p).isFile());
        assert.ok(resolved, `Cannot resolve ${id}`);
        return load(path.relative(root, resolved), overrides, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

const account = {
  id: 2,
  userId: 2,
  firstName: "Juan",
  middleName: null,
  lastName: "Reyes",
  username: "HAD0002-test",
  role: "HeadAdmin",
  status: "Active",
  email: "juan@example.invalid",
  phoneNumber: "09171234567",
  profileUrl: null,
  dateOfBirth: "1990-01-01",
  houseNumber: "12",
  street: "Sampaguita",
  barangay: "Santa Elena",
  city: "Marikina",
  version: 5,
};
const apiErrors = load("utils/apiErrors.ts");

test("Total Users uses the all-user metric and the Manage button is enabled", () => {
  const Overview = load(
    "features/accounts/components/AccountOverview.tsx",
  ).default;
  const html = renderToStaticMarkup(
    React.createElement(Overview, {
      model: {
        counts: {
          totalUsers: 13,
          totalStaffUsers: 12,
          totalActiveAccounts: 12,
          totalAdministrators: 12,
          totalMarketVendorUsers: 1,
        },
        countsLoading: false,
      },
    }),
  );
  assert.match(html, /<dd>13<\/dd>\s*<dt>Total Users<\/dt>/);
  const Row = load("features/accounts/components/AccountRow.tsx").default;
  const row = renderToStaticMarkup(
    React.createElement(Row, { account, onManage() {} }),
  );
  assert.doesNotMatch(row, /<button[^>]*disabled/);
});

test("signed-in account card identifies the current user without a Manage action", () => {
  const Card = load(
    "features/accounts/components/CurrentAccountCard.tsx",
  ).default;
  const html = renderToStaticMarkup(
    React.createElement(Card, { user: account }),
  );
  assert.match(html, /Your account/);
  assert.match(html, /Signed in/);
  assert.match(html, /Juan Reyes/);
  assert.doesNotMatch(html, /<button|Manage/);
});

function editHarness() {
  const states = [],
    refs = [],
    calls = [],
    invalidations = [];
  let stateCursor = 0,
    refCursor = 0,
    response = account,
    loadFailure,
    loadPending,
    failure,
    pending;
  const store = Object.assign(
    (select) => select({ user: { userId: 1, role: "HeadAdmin" } }),
    { getState: () => ({ user: { userId: 1, role: "HeadAdmin" } }) },
  );
  const { useManageAccount } = load(
    "features/accounts/hooks/useManageAccount.ts",
    {
      react: {
        useState(initial) {
          const i = stateCursor++;
          if (!(i in states))
            states[i] = typeof initial === "function" ? initial() : initial;
          return [
            states[i],
            (value) => {
              states[i] =
                typeof value === "function" ? value(states[i]) : value;
            },
          ];
        },
        useRef(initial) {
          return (refs[refCursor++] ??= { current: initial });
        },
        useEffect() {},
      },
      "@/store/store": { useAuthStore: store },
      "@/utils/apiErrors": apiErrors,
      "@/api/endpoints/accounts.api": {
        accountsApi: {
          async getAccount(id) {
            calls.push(["get", id]);
            if (loadPending) await loadPending;
            if (loadFailure) throw loadFailure;
            return response;
          },
          async updateAccount(id, body) {
            calls.push(["put", id, body]);
            if (pending) await pending;
            if (failure) throw failure;
            return response;
          },
        },
      },
      "@tanstack/react-query": {
        useQueryClient: () => ({
          invalidateQueries: async (query) =>
            invalidations.push(query.queryKey),
        }),
      },
      "@/components/ui/Toast/useToast": {
        useToast: () => ({ showToast() {} }),
      },
    },
  );
  return {
    calls,
    invalidations,
    render() {
      stateCursor = 0;
      refCursor = 0;
      return useManageAccount();
    },
    fail(value) {
      failure = value;
    },
    failLoad(value) {
      loadFailure = value;
    },
    deferLoad(value) {
      loadPending = value;
    },
    defer(value) {
      pending = value;
    },
  };
}

test("Manage loads full fields, submits the loaded version once and refreshes account data", async () => {
  const h = editHarness();
  await h.render().show(2);
  let model = h.render();
  assert.equal(model.form.street, "Sampaguita");
  assert.equal(model.form.firstName, "Juan");
  model.change("firstName", " Juana ");
  let finish;
  h.defer(
    new Promise((resolve) => {
      finish = resolve;
    }),
  );
  const first = h.render().submit({ preventDefault() {} });
  await h.render().submit({ preventDefault() {} });
  finish();
  await first;
  const puts = h.calls.filter(([method]) => method === "put");
  assert.equal(puts.length, 1);
  assert.equal(puts[0][2].version, 5);
  assert.equal(puts[0][2].firstName, "Juana");
  assert.equal("role" in puts[0][2], false);
  assert.equal("username" in puts[0][2], false);
  assert.equal(h.render().open, false);
  assert.equal(h.invalidations.length, 2);
});

function renderModal(model) {
  const Modal = load("features/accounts/components/AddStaffAccountModal.tsx", {
    "@/components/ui/Modal": {
      default: ({ children, footer }) =>
        React.createElement("section", null, children, footer),
    },
  }).default;
  return renderToStaticMarkup(React.createElement(Modal, { model }));
}

test("failed account loads show recovery without a blank form, then retry once with progress", async () => {
  const h = editHarness();
  h.failLoad(new Error("Offline"));
  await h.render().show(2);
  let html = renderModal(h.render());
  assert.match(html, /Unable to load account/);
  assert.match(html, /Try again/);
  assert.doesNotMatch(html, /<fieldset/);
  h.failLoad(undefined);
  let finish;
  h.deferLoad(
    new Promise((resolve) => {
      finish = resolve;
    }),
  );
  const retry = h.render().reload();
  h.render().reload();
  html = renderModal(h.render());
  assert.match(html, /Loading account details/);
  assert.doesNotMatch(html, /<fieldset/);
  assert.equal(h.calls.filter(([method]) => method === "get").length, 2);
  finish();
  await retry;
  assert.match(renderModal(h.render()), /<fieldset/);
});

test("conflict notice stays above preserved edits and reload replaces them only on success", async () => {
  const h = editHarness();
  await h.render().show(2);
  h.render().change("firstName", "Juana");
  h.fail(
    new apiErrors.ApiRequestError(
      "Account changed. Reload before saving.",
      409,
    ),
  );
  await h.render().submit({ preventDefault() {} });
  h.render().change("street", "New street");
  assert.match(h.render().error, /Account changed/);
  let html = renderModal(h.render());
  assert.ok(html.indexOf('role="alert"') < html.indexOf("<fieldset"));
  assert.match(html, /Reloading replaces your unsaved changes/);
  h.failLoad(new Error("Offline"));
  await h.render().reload();
  assert.equal(h.render().form.firstName, "Juana");
  assert.equal(h.render().canSave, false);
  h.failLoad(undefined);
  let finish;
  h.deferLoad(
    new Promise((resolve) => {
      finish = resolve;
    }),
  );
  const reload = h.render().reload();
  html = renderModal(h.render());
  assert.match(html, /Reloading account/);
  assert.equal(h.render().form.firstName, "Juana");
  finish();
  await reload;
  assert.equal(h.render().form.firstName, "Juan");
  assert.equal(h.render().canSave, true);
});

test("stale saves retain form content and block another save until details reload", async () => {
  const h = editHarness();
  await h.render().show(2);
  const failure = new apiErrors.ApiRequestError(
    "Refresh this account before saving again.",
    409,
  );
  h.fail(failure);
  await h.render().submit({ preventDefault() {} });
  const model = h.render();
  assert.equal(model.stale, true);
  assert.equal(model.form.firstName, "Juan");
  await model.submit({ preventDefault() {} });
  assert.equal(h.calls.filter(([method]) => method === "put").length, 1);
  h.fail(undefined);
  await h.render().show(2);
  assert.equal(h.render().stale, false);
  await h.render().submit({ preventDefault() {} });
  assert.equal(h.calls.filter(([method]) => method === "put").length, 2);
});
