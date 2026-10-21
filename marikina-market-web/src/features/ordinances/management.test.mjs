import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import test from "node:test";
import vm from "node:vm";
import { randomUUID } from "node:crypto";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { MemoryRouter } from "react-router-dom";
import ts from "typescript";

const require = createRequire(import.meta.url);
const { QueryClient, QueryClientProvider } = require("@tanstack/react-query");
const root = path.resolve(
  path.dirname(new URL(import.meta.url).pathname.replace(/^\/(\w:)/, "$1")),
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
      Error,
      Date,
      URLSearchParams,
      crypto: { randomUUID },
      require(id) {
        if (id in overrides) return { __esModule: true, ...overrides[id] };
        if (id.endsWith(".css"))
          return {
            __esModule: true,
            default: new Proxy({}, { get: (_, key) => key }),
          };
        if (id.endsWith(".webp"))
          return { __esModule: true, default: "fixture.webp" };
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

const summary = {
  id: 7,
  ordinanceNo: "011",
  series: "2026",
  marketCode: "MKT-011",
  title: "Market sanitation",
  category: "Sanitation",
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
  isActive: true,
  severity: "Minor",
  penaltyTierCount: 2,
};
const detail = {
  ...summary,
  penaltyTiers: [
    { id: 71, offenseNumber: 1, severity: "Minor", penaltyAmount: 500 },
    { id: 72, offenseNumber: 2, severity: "Moderate", penaltyAmount: 1000 },
  ],
};
const errors = load("utils/apiErrors.ts");

function editorHarness(role = "HeadAdmin") {
  const states = [],
    refs = [],
    effects = [],
    pendingEffects = [],
    requests = [],
    invalidations = [];
  let stateCursor = 0,
    refCursor = 0,
    effectCursor = 0,
    mutationOptions,
    pending = false,
    savingPromise,
    detailPromise;
  let failure, gate;
  let queryState = {
    data: detail,
    isSuccess: true,
    isFetching: false,
    isError: false,
  };
  let list = [summary];
  const auth = { user: { userId: 1, role } };
  const store = Object.assign((select) => select(auth), {
    getState: () => auth,
  });
  const { useOrdinanceEditor } = load(
    "features/ordinances/hooks/useOrdinanceEditor.ts",
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
        useEffect(callback, deps) {
          const i = effectCursor++;
          if (
            !effects[i] ||
            deps.some((value, index) => !Object.is(value, effects[i][index]))
          ) {
            effects[i] = deps;
            pendingEffects.push(callback);
          }
        },
      },
      "@/store/store": { useAuthStore: store },
      "@/utils/apiErrors": errors,
      "@/components/ui/Toast/useToast": {
        useToast: () => ({ showToast() {} }),
      },
      "@/api/client": {
        default: {
          async get(url) {
            requests.push(["get", url]);
            return { data: detail };
          },
          async post(url, body) {
            requests.push(["post", url, body]);
            if (gate) await gate;
            if (failure) throw failure;
            return { data: { ...summary, id: 8, title: body.title } };
          },
          async put(url, body) {
            requests.push(["put", url, body]);
            if (gate) await gate;
            if (failure) throw failure;
            return { data: { ...summary, title: body.title } };
          },
        },
      },
      "@tanstack/react-query": {
        useQuery(options) {
          return {
            ...queryState,
            refetch() {
              detailPromise = options.queryFn({}).then((data) => {
                queryState = {
                  data,
                  isSuccess: true,
                  isFetching: false,
                  isError: false,
                };
                return { data };
              });
              return detailPromise;
            },
          };
        },
        useQueryClient: () => ({
          async cancelQueries() {},
          setQueryData(_key, update) {
            list = update(list);
          },
          async invalidateQueries({ queryKey }) {
            invalidations.push(queryKey);
          },
        }),
        useMutation(options) {
          mutationOptions = options;
          return {
            isPending: pending,
            reset() {},
            mutate(variables) {
              const callbacks = mutationOptions;
              pending = true;
              savingPromise = Promise.resolve()
                .then(() => callbacks.mutationFn(variables))
                .then((response) => callbacks.onSuccess(response, variables))
                .catch((error) => callbacks.onError(error))
                .finally(() => {
                  pending = false;
                  callbacks.onSettled();
                });
            },
          };
        },
      },
    },
  );
  return {
    requests,
    invalidations,
    render() {
      stateCursor = refCursor = effectCursor = 0;
      return useOrdinanceEditor();
    },
    flush() {
      while (pendingEffects.length) pendingEffects.shift()();
    },
    query(value) {
      queryState = value;
    },
    fail(value) {
      failure = value;
    },
    defer(value) {
      gate = value;
    },
    async settle() {
      await savingPromise;
    },
    async settleDetails() {
      await detailPromise;
    },
    get list() {
      return list;
    },
  };
}

test("only the known empty-list 404 becomes an empty registry", async () => {
  let response = { status: 404, data: "Ordinance list not found." };
  const { ordinanceApi } = load("api/endpoints/ordinance.api.ts", {
    "@/api/client": { default: { get: async () => response } },
  });
  assert.equal((await ordinanceApi.getAll()).length, 0);
  response = { status: 404, data: "Route not found." };
  await assert.rejects(ordinanceApi.getAll(), /Route not found/);
});

test("both administrators reach ordinances through Configurations without backup access expansion", () => {
  for (const role of [
    "HeadAdmin",
    "AdminOfficer",
    "MarketEnforcer",
    "MarketVendor",
  ]) {
    const allowed = ["HeadAdmin", "AdminOfficer"].includes(role);
    const h = editorHarness(role);
    assert.equal(h.render().canManage, allowed);
    h.render().launch();
    assert.equal(h.render().open, allowed);
    const Sidebar = load("components/layout/Sidebar/Sidebar.tsx", {
      "@/context/AuthContext": {
        useAuth: () => ({
          user: { firstName: "Juan", lastName: "Reyes", role },
          logout() {},
        }),
      },
      "@/features/vendors": { RegistrationCountBadge: () => null },
    }).default;
    const html = renderToStaticMarkup(
      React.createElement(
        MemoryRouter,
        null,
        React.createElement(Sidebar, {
          open: true,
          collapsed: false,
          onClose() {},
        }),
      ),
    );
    assert.equal(html.includes('href="/system/ordinance"'), false);
    assert.equal(html.includes('href="/system/configuration"'), allowed);
    const Configuration = load(
      "features/configuration/pages/SystemConfigurationPage.tsx",
      {
        "@/store/store": {
          useAuthStore: (select) => select({ user: { role } }),
        },
        "@/features/configuration/hooks/useMarketSectionCount": {
          useMarketSectionCount: () => ({ count: 2 }),
        },
        "@/features/configuration/hooks/useOrdinanceCount": {
          useOrdinanceCount: () => ({ count: 3 }),
        },
        "@/context/AuthContext": {
          useAuth: () => ({ user: { userId: 1, role } }),
        },
        "@/api/client": {
          default: {
            get() {
              throw new Error(
                "Unexpected request during static configuration rendering.",
              );
            },
          },
        },
      },
    ).default;
    if (allowed) {
      const configurationHtml = renderToStaticMarkup(
        React.createElement(
          MemoryRouter,
          null,
          React.createElement(
            QueryClientProvider,
            { client: new QueryClient() },
            React.createElement(Configuration),
          ),
        ),
      );
      assert.equal(
        configurationHtml.includes('href="/system/ordinance"'),
        true,
      );
      assert.equal(
        configurationHtml.includes('href="/configuration/backups"'),
        role === "HeadAdmin",
      );
    }
  }
});

test("ordinance validation matches numeric number, text limits and penalty precision", () => {
  const { buildOrdinanceRequest, validateOrdinance } = load(
    "features/ordinances/ordinances.utils.ts",
  );
  const fields = {
    ordinanceNumber: "011",
    series: "2026",
    marketCode: "MKT-011",
    title: "Market sanitation",
    category: "Sanitation",
  };
  const tiers = [{ key: "first", severity: "Minor", amount: "500.00" }];
  assert.equal(buildOrdinanceRequest(fields, tiers).ordinanceNumber, "011");
  for (const number of ["Ord. No. 011", "11.5", "-11", "١١", "1".repeat(101)]) {
    assert.equal(
      buildOrdinanceRequest({ ...fields, ordinanceNumber: number }, tiers),
      null,
    );
    assert.ok(
      validateOrdinance({ ...fields, ordinanceNumber: number }, tiers)
        .fieldErrors.ordinanceNumber,
    );
  }
  for (const [key, length] of [
    ["series", 101],
    ["title", 251],
  ])
    assert.equal(
      buildOrdinanceRequest({ ...fields, [key]: "a".repeat(length) }, tiers),
      null,
    );
  assert.equal(
    buildOrdinanceRequest(fields, [{ ...tiers[0], amount: "500.001" }]),
    null,
  );
  assert.equal(buildOrdinanceRequest(fields, []), null);
});

test("AdminOfficer creation submits once and refreshes list, details and count", async () => {
  const h = editorHarness("AdminOfficer");
  h.render().launch();
  for (const [key, value] of Object.entries({
    ordinanceNumber: "028",
    series: "2026",
    marketCode: "MKT-028",
    title: "Market identification",
    category: "Licensing",
  }))
    h.render().changeField(key, value);
  h.render().addTier();
  const key = h.render().tiers[0].key;
  h.render().changeTier(key, "amount", "500.00");
  assert.equal(h.render().canSave, true);
  let finish;
  h.defer(
    new Promise((resolve) => {
      finish = resolve;
    }),
  );
  h.render().submit();
  h.render().submit();
  await Promise.resolve();
  assert.equal(h.requests.filter(([method]) => method === "post").length, 1);
  assert.equal(h.render().isSaving, true);
  h.render().close();
  assert.equal(h.render().open, true);
  finish();
  await h.settle();
  assert.equal(h.render().open, false);
  assert.equal(h.list.at(-1).id, 8);
  assert.equal(h.invalidations.length, 3);
});

test("edit loads ordered tiers, undo restores them and failed saves preserve edits", async () => {
  const h = editorHarness();
  h.render().launch(summary);
  h.render();
  h.flush();
  let model = h.render();
  assert.equal(model.fields.title, "Market sanitation");
  assert.equal(model.tiers[1].amount, "1000");
  model.changeField("title", "Updated sanitation rule");
  h.render().changeTier(model.tiers[0].key, "amount", "750");
  h.render().undo();
  assert.equal(h.render().fields.title, "Market sanitation");
  assert.equal(h.render().tiers[0].amount, "500");
  h.render().changeField("title", "Updated sanitation rule");
  h.fail(new errors.ApiRequestError("Unable to save this ordinance.", 400));
  h.render().submit();
  await h.settle();
  assert.equal(h.render().open, true);
  assert.equal(h.render().fields.title, "Updated sanitation rule");
  assert.match(h.render().error, /Unable to save this ordinance/);
  h.fail(undefined);
  h.render().submit();
  await h.settle();
  assert.equal(h.render().open, false);
  assert.equal(h.list[0].title, "Updated sanitation rule");
});

test("failed detail loading blocks saving and retries the selected ordinance", async () => {
  const h = editorHarness();
  h.query({
    isError: true,
    isSuccess: false,
    isFetching: false,
    error: new errors.ApiRequestError("Details unavailable."),
  });
  h.render().launch(summary);
  assert.equal(h.render().isDetailError, true);
  assert.equal(h.render().canSave, false);
  h.render().submit();
  assert.equal(h.requests.length, 0);
  h.render().retryDetails();
  await h.settleDetails();
  h.render();
  h.flush();
  assert.equal(h.render().isDetailError, false);
  assert.equal(h.render().tiers.length, 2);
  assert.equal(h.requests[0][1], "/ordinance/7");
});
