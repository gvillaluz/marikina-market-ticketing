import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import test from "node:test";
import vm from "node:vm";
import { randomUUID } from "node:crypto";
import { setImmediate as nextTurn } from "node:timers/promises";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { MemoryRouter } from "react-router-dom";
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

const section = {
  id: 2,
  name: "Fresh Produce",
  description: "Fruit and vegetable stalls",
  isActive: true,
  vendorCount: 12,
};
const apiErrors = load("utils/apiErrors.ts");

function harness(role = "HeadAdmin") {
  const states = [],
    refs = [],
    mutations = [],
    requests = [],
    invalidations = [],
    toasts = [];
  let stateCursor = 0,
    refCursor = 0,
    mutationCursor = 0,
    failure,
    gate;
  let list = [section];
  let queryState = {
    data: list,
    isPending: false,
    isFetching: false,
    isError: false,
  };
  const store = Object.assign(
    (select) => select({ user: { userId: 1, role } }),
    { getState: () => ({ user: { userId: 1, role } }) },
  );
  async function write(method, url, body) {
    requests.push([method, url, body]);
    if (gate) await gate;
    if (failure) throw failure;
    return { data: { ...section, id: method === "post" ? 3 : 2, ...body } };
  }
  const overrides = {
    react: {
      useState(initial) {
        const i = stateCursor++;
        if (!(i in states))
          states[i] = typeof initial === "function" ? initial() : initial;
        return [
          states[i],
          (value) => {
            states[i] = typeof value === "function" ? value(states[i]) : value;
          },
        ];
      },
      useRef(initial) {
        return (refs[refCursor++] ??= { current: initial });
      },
    },
    "@/store/store": { useAuthStore: store },
    "@/utils/apiErrors": apiErrors,
    "@/components/ui/Toast/useToast": {
      useToast: () => ({ showToast: (value) => toasts.push(value) }),
    },
    "@/api/client": {
      default: {
        get: async () => ({ data: list }),
        post: (...args) => write("post", ...args),
        put: (...args) => write("put", ...args),
        patch: (...args) => write("patch", ...args),
      },
    },
    "@tanstack/react-query": {
      useQuery: () => ({ ...queryState, refetch() {} }),
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
        const i = mutationCursor++;
        const slot = (mutations[i] ??= { pending: false });
        return {
          isPending: slot.pending,
          mutate(variables) {
            slot.pending = true;
            slot.promise = Promise.resolve()
              .then(() => options.mutationFn(variables))
              .then((response) => options.onSuccess(response, variables))
              .catch((error) => options.onError(error))
              .finally(() => {
                slot.pending = false;
                options.onSettled();
              });
          },
        };
      },
    },
  };
  const { useMarketSectionEditor } = load(
    "features/market-section/hooks/useMarketSectionEditor.ts",
    overrides,
  );
  const { useMarketSections } = load(
    "features/market-section/hooks/useMarketSections.ts",
    overrides,
  );
  return {
    requests,
    invalidations,
    toasts,
    render() {
      stateCursor = refCursor = mutationCursor = 0;
      return useMarketSectionEditor();
    },
    directory() {
      stateCursor = 0;
      return useMarketSections();
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
      await Promise.all(mutations.map((slot) => slot.promise));
    },
    get list() {
      return list;
    },
  };
}

test("both administrators can manage and navigate to market sections without broader configuration access", () => {
  for (const role of [
    "HeadAdmin",
    "AdminOfficer",
    "MarketEnforcer",
    "MarketVendor",
  ]) {
    const allowed = ["HeadAdmin", "AdminOfficer"].includes(role);
    const h = harness(role);
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
    assert.equal(html.includes('href="/system/market-section"'), allowed);
    if (role === "AdminOfficer")
      assert.equal(html.includes('href="/system/configuration"'), false);
  }
});

test("blank and overlength section drafts cannot make requests", async () => {
  const h = harness();
  h.render().launch();
  h.render().submit();
  assert.match(h.render().error, /required/);
  h.render().setName("a".repeat(151));
  h.render().setDescription("Produce stalls");
  h.render().submit();
  await h.settle();
  assert.equal(h.requests.length, 0);
  assert.match(h.render().error, /150/);
  h.render().setName("Produce");
  h.render().setDescription("a".repeat(501));
  h.render().submit();
  await h.settle();
  assert.equal(h.requests.length, 0);
  assert.match(h.render().error, /500/);
});

test("create and edit preserve errors, save once and refresh list/count caches", async () => {
  const h = harness("AdminOfficer");
  h.render().launch();
  h.render().setName(" Bakery ");
  h.render().setDescription(" Bread stalls ");
  let finish;
  h.defer(
    new Promise((resolve) => {
      finish = resolve;
    }),
  );
  h.render().submit();
  h.render().submit();
  // Let cancelQueries and the request start before releasing the HTTP boundary.
  await nextTurn();
  assert.equal(h.requests.length, 1);
  h.render().close();
  assert.equal(h.render().open, true);
  finish();
  await h.settle();
  assert.equal(h.list.at(-1).name, "Bakery");
  assert.equal(h.list.at(-1).description, "Bread stalls");
  assert.equal(h.render().open, false);
  assert.ok(
    h.invalidations.some((key) => key.join("/") === "market_sections/list"),
  );
  assert.ok(
    h.invalidations.some(
      (key) => key.join("/") === "market_sections/configurations",
    ),
  );
  h.render().launch(section);
  h.render().setName("Bakery");
  h.fail(
    new apiErrors.ApiRequestError(
      "A market section with this name already exists.",
      400,
    ),
  );
  h.render().submit();
  await h.settle();
  assert.equal(h.render().open, true);
  assert.equal(h.render().name, "Bakery");
  assert.match(h.render().error, /already exists/);
  h.fail(undefined);
  h.render().setName("Fresh produce stalls");
  h.render().submit();
  await h.settle();
  assert.equal(h.list[0].name, "Fresh produce stalls");
});

test("status toggles send an object, preserve the old status on failure and recover", async () => {
  const h = harness();
  h.render().toggle(section);
  h.render().toggle(section);
  await h.settle();
  assert.equal(h.requests.length, 1);
  assert.equal(typeof h.requests[0][2], "object");
  assert.equal(h.requests[0][2].isActive, false);
  assert.equal(h.list[0].isActive, false);
  assert.ok(
    h.invalidations.some(
      (key) => key.join("/") === "market_sections/configurations",
    ),
  );
  h.fail(new apiErrors.ApiRequestError("Status update unavailable.", 500));
  h.render().toggle(h.list[0]);
  await h.settle();
  assert.equal(h.list[0].isActive, false);
  assert.equal(h.render().pendingId, null);
  assert.match(h.toasts.at(-1).description, /Status update unavailable/);
  h.fail(undefined);
  h.render().toggle(h.list[0]);
  await h.settle();
  assert.equal(h.list[0].isActive, true);
  assert.equal(h.requests.at(-1)[2].isActive, true);
});

test("directory search handles empty/loading/error states and malformed lists become errors", async () => {
  const h = harness();
  h.directory().setSearch("vegetable");
  assert.equal(h.directory().sections.length, 1);
  h.directory().setSearch("bakery");
  assert.equal(h.directory().sections.length, 0);
  h.query({ data: [], isPending: false, isFetching: false, isError: false });
  assert.equal(h.directory().hasData, true);
  assert.equal(h.directory().total, 0);
  h.query({ isPending: true, isFetching: true, isError: false });
  assert.equal(h.directory().isLoading, true);
  h.query({
    isPending: false,
    isFetching: false,
    isError: true,
    error: new apiErrors.ApiRequestError("Sections unavailable."),
  });
  assert.equal(h.directory().errorMessage, "Sections unavailable.");
  const { marketSectionApi } = load("api/endpoints/marketSection.api.ts", {
    "@/api/client": { default: { get: async () => ({ data: {} }) } },
  });
  await assert.rejects(marketSectionApi.getAll(), /market sections/i);
});
