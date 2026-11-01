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
  section: "53",
  specificCategory: null,
  title: "Market sanitation",
  category: "Sanitation",
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
  isActive: true,
  severity: "Minor",
  warningEligible: true,
  penaltyTierCount: 2,
};
const detail = {
  ...summary,
  penaltyTiers: [
    {
      id: 71, offenseNumber: 1, fineKind: "Fixed", penaltyAmount: 500, minimumFine: null, maximumFine: null,
      penaltyTerms: null, allowBloodDonation: true, allowCommunityService: false
    },
    {
      id: 72, offenseNumber: 2, fineKind: "Fixed", penaltyAmount: 1000, minimumFine: null, maximumFine: null,
      penaltyTerms: null, allowBloodDonation: false, allowCommunityService: false
    },
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
        useToast: () => ({ showToast() { } }),
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
          async cancelQueries() { },
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
            reset() { },
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
          logout() { },
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
          onClose() { },
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
    section: "53",
    specificCategory: "",
    title: "Market sanitation",
    category: "Sanitation",
    severity: "Minor",
    warningEligible: false,
  };
  const tiers = [fixedTier({ amount: "500.00" })];
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
    section: "12",
    title: "Market identification",
    category: "Others",
    specificCategory: "Market identification",
    severity: "Moderate",
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
  assert.equal(h.requests.find(([method]) => method === "post")[2].section, "12");
  assert.equal(h.requests.find(([method]) => method === "post")[2].specificCategory, "Market identification");
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

test("new category choices preserve historical numeric category identities", () => {
  const { CATEGORY_OPTIONS } = load("features/ordinances/ordinances.constants.ts");
  assert.deepEqual(Array.from(CATEGORY_OPTIONS, ({ value }) => value), [
    "Traffic", "Obstruction", "Sanitation", "WeightMeasures", "DressCode",
    "IllegalVendor", "NonSmoking", "Others",
  ]);
  const { normalizeCategory } = load("features/ordinances/ordinances.utils.ts");
  for (const [id, expected] of [[3, "Licensing"], [4, "Noise"], [5, "WeightMeasures"], [6, "DressCode"], [9, "Others"]])
    assert.equal(normalizeCategory(id), expected);
});

test("section and specific category are validated and sent using the revised contract", () => {
  const { buildOrdinanceRequest, validateOrdinance } = load("features/ordinances/ordinances.utils.ts");
  const fields = { ordinanceNumber: "11", series: "2014", section: " 53 ", title: "Restriction of public places", category: "Others", specificCategory: "  Public access  ", severity: "Minor", warningEligible: false };
  const tiers = [fixedTier()];
  const request = buildOrdinanceRequest(fields, tiers);
  assert.ok(request);
  assert.equal(request.section, "53");
  assert.equal(request.specificCategory, "Public access");
  assert.equal("marketCode" in request, false);
  assert.equal(buildOrdinanceRequest({ ...fields, specificCategory: " " }, tiers), null);
  assert.equal(buildOrdinanceRequest({ ...fields, section: " " }, tiers), null);
  assert.equal(buildOrdinanceRequest({ ...fields, specificCategory: "a".repeat(101) }, tiers), null);
  assert.ok(validateOrdinance({ ...fields, section: "a".repeat(101) }, tiers).fieldErrors.section);
  assert.equal(buildOrdinanceRequest({ ...fields, category: "DressCode" }, tiers).specificCategory, null);
  assert.equal(buildOrdinanceRequest({ ...fields, category: "Noise" }, tiers), null);
});

test("switching category clears specific text and legacy choices need recategorization", () => {
  const h = editorHarness();
  h.render().launch();
  h.render().changeField("category", "Others");
  h.render().changeField("specificCategory", "Public access");
  assert.equal(h.render().fields.specificCategory, "Public access");
  h.render().changeField("category", "DressCode");
  assert.equal(h.render().fields.specificCategory, "");
  h.render().changeField("category", "Licensing");
  assert.equal(h.render().fields.category, "");
  const legacy = editorHarness();
  legacy.query({ data: { ...detail, section: null, category: "Noise" }, isSuccess: true, isFetching: false, isError: false });
  legacy.render().launch({ ...summary, section: null, category: "Noise" });
  legacy.render();
  legacy.flush();
  assert.equal(legacy.render().fields.section, "");
  assert.equal(legacy.render().fields.category, "");
  assert.equal(legacy.render().canSave, false);
});

test("ordinance fields show specific category only for Others and label fines correctly", () => {
  const h = editorHarness();
  h.render().launch();
  h.render().changeField("category", "Others");
  const Fields = load("features/ordinances/components/OrdinanceDetailsFields.tsx").default;
  let html = renderToStaticMarkup(React.createElement(Fields, { editor: h.render() }));
  assert.match(html, /Section of ordinance/);
  assert.match(html, /Specific category/);
  h.render().changeField("category", "Traffic");
  html = renderToStaticMarkup(React.createElement(Fields, { editor: h.render() }));
  assert.doesNotMatch(html, /Specific category/);
  const Tier = load("features/ordinances/components/PenaltyTierRow.tsx").default;
  html = renderToStaticMarkup(React.createElement(Tier, { tier: fixedTier(), number: 1, errors: {}, touched: {}, onChange() { }, onBlur() { }, onRemove() { } }));
  assert.match(html, /Fine amount/);
  assert.doesNotMatch(html, /[Ff]ee amount/);
});

test("registry shows ordinance section, legacy unavailability and specific category", () => {
  const Row = load("features/ordinances/components/OrdinanceRegistryRow.tsx").default;
  const render = (ordinance) => renderToStaticMarkup(React.createElement(Row, { ordinance, disabled: false, onManage() { } }));
  let html = render({ ...summary, section: "53", category: "Others", specificCategory: "Public access" });
  assert.match(html, /Section 53/);
  assert.match(html, /Public access/);
  html = render({ ...summary, section: null, specificCategory: null });
  assert.match(html, /Section unavailable/);
  assert.doesNotMatch(html, /MKT-011/);
});

test("registry search matches sections and tolerates missing legacy sections", () => {
  const { useOrdinances } = load("features/ordinances/hooks/useOrdinances.ts", {
    react: { useState: () => ["53", () => { }] },
    "@/api/endpoints/ordinance.api": { ordinanceApi: { getAll: async () => [] } },
    "@tanstack/react-query": { useQuery: () => ({ data: [{ ...summary, section: "53" }, { ...summary, id: 8, section: null }] }) },
  });
  const result = useOrdinances();
  assert.equal(result.ordinances.length, 1);
  assert.equal(result.ordinances[0].section, "53");
});

const scoringFields = {
  ordinanceNumber: "11", series: "2014", section: "53", title: "Restriction of public places",
  category: "Obstruction", specificCategory: "", severity: "High", warningEligible: true,
};
const fixedTier = (changes = {}) => ({
  key: "first", fineKind: "Fixed", amount: "500", maximumFine: "", penaltyTerms: "",
  allowBloodDonation: false, allowCommunityService: false, ...changes,
});

test("slice 2 saves ordinance scoring and warning settings without tier severity", () => {
  const { buildOrdinanceRequest } = load("features/ordinances/ordinances.utils.ts");
  const request = buildOrdinanceRequest(scoringFields, [fixedTier({ allowBloodDonation: true })]);
  assert.ok(request);
  assert.equal(request.severity, "High");
  assert.equal(request.warningEligible, true);
  assert.equal(request.penaltyTiers[0].fineKind, "Fixed");
  assert.equal(request.penaltyTiers[0].penaltyAmount, 500);
  assert.equal(request.penaltyTiers[0].maximumFine, null);
  assert.equal(request.penaltyTiers[0].allowBloodDonation, true);
  assert.equal(request.penaltyTiers[0].allowCommunityService, false);
  assert.equal("severity" in request.penaltyTiers[0], false);
  assert.equal(buildOrdinanceRequest({ ...scoringFields, severity: "" }, [fixedTier()]), null);
});

test("slice 2 applies the minimum only to up-to caps and preserves fixed amounts", () => {
  const { buildOrdinanceRequest } = load("features/ordinances/ordinances.utils.ts");
  const upTo = fixedTier({ fineKind: "UpTo", amount: "", maximumFine: "1000" });
  const request = buildOrdinanceRequest(scoringFields, [upTo]);
  assert.ok(request);
  assert.equal(request.penaltyTiers[0].penaltyAmount, null);
  assert.equal(request.penaltyTiers[0].maximumFine, 1000);
  assert.equal("minimumFine" in request.penaltyTiers[0], false);
  for (const cap of ["99.99", "", "100.001", "-100"])
    assert.equal(buildOrdinanceRequest(scoringFields, [{ ...upTo, maximumFine: cap }]), null);
  assert.equal(buildOrdinanceRequest(scoringFields, [{ ...upTo, maximumFine: "100" }]).penaltyTiers[0].maximumFine, 100);
  assert.equal(buildOrdinanceRequest(scoringFields, [fixedTier({ amount: "50" })]).penaltyTiers[0].penaltyAmount, 50);
});

test("slice 2 unconfirmed terms stay unassessed and require meaningful text", () => {
  const { buildOrdinanceRequest } = load("features/ordinances/ordinances.utils.ts");
  const tier = fixedTier({ fineKind: "Unconfirmed", amount: "", penaltyTerms: "  Fine not stated; confirmation required.  " });
  const request = buildOrdinanceRequest(scoringFields, [tier]);
  assert.ok(request);
  assert.equal(request.penaltyTiers[0].penaltyAmount, null);
  assert.equal(request.penaltyTiers[0].maximumFine, null);
  assert.equal(request.penaltyTiers[0].penaltyTerms, "Fine not stated; confirmation required.");
  assert.equal(buildOrdinanceRequest(scoringFields, [{ ...tier, penaltyTerms: " " }]), null);
});

test("slice 2 rejects alternative flags on later tiers independently of severity", () => {
  const { buildOrdinanceRequest } = load("features/ordinances/ordinances.utils.ts");
  for (const flag of ["allowBloodDonation", "allowCommunityService"]) {
    assert.ok(buildOrdinanceRequest(scoringFields, [fixedTier({ [flag]: true })]));
    assert.equal(buildOrdinanceRequest(scoringFields, [fixedTier(), fixedTier({ key: "second", [flag]: true })]), null);
  }
  assert.ok(buildOrdinanceRequest({ ...scoringFields, severity: "Minor", warningEligible: false }, [fixedTier()]));
});

test("slice 2 normalizes fine kinds without requiring removed tier severity", () => {
  const { normalizeOrdinanceDetails } = load("features/ordinances/ordinances.utils.ts");
  const normalized = normalizeOrdinanceDetails({
    ...summary, severity: 2, warningEligible: true,
    penaltyTiers: [{
      id: 71, offenseNumber: 1, fineKind: 1, penaltyAmount: null, minimumFine: 100,
      maximumFine: 1000, penaltyTerms: "Up to PHP 1,000", allowBloodDonation: false, allowCommunityService: true
    }]
  });
  assert.equal(normalized.severity, "High");
  assert.equal(normalized.warningEligible, true);
  assert.equal(normalized.penaltyTiers[0].fineKind, "UpTo");
  assert.equal(normalized.penaltyTiers[0].penaltyAmount, null);
  assert.equal(normalized.penaltyTiers[0].allowCommunityService, true);
});

test("slice 2 tier controls show fine rules and first-offense alternatives without severity", () => {
  const Tier = load("features/ordinances/components/PenaltyTierRow.tsx").default;
  const render = (number, tier) => renderToStaticMarkup(React.createElement(Tier, {
    tier, number, disabled: false, errors: {}, touched: {}, onChange() { }, onBlur() { }, onRemove() { },
  }));
  let html = render(1, fixedTier({ fineKind: "UpTo", maximumFine: "1000" }));
  assert.match(html, /Maximum fine amount/);
  assert.match(html, /100/);
  assert.match(html, /Blood donation/);
  assert.match(html, /Community service/);
  assert.doesNotMatch(html, /Severity/);
  html = render(2, fixedTier());
  assert.doesNotMatch(html, /type="checkbox"/);
  html = render(1, fixedTier({ fineKind: "Unconfirmed", amount: "" }));
  assert.match(html, /Penalty terms/);
  assert.doesNotMatch(html, /type="number"/);
});

test("slice 2 editor uses explicit settings and clears stale money when the fine rule changes", () => {
  const h = editorHarness();
  h.render().launch();
  assert.equal(h.render().fields.severity, "");
  assert.equal(h.render().fields.warningEligible, false);
  h.render().changeField("severity", "High");
  h.render().changeField("warningEligible", true);
  h.render().addTier();
  const key = h.render().tiers[0].key;
  assert.equal(h.render().tiers[0].allowBloodDonation, false);
  h.render().changeTier(key, "amount", "500");
  h.render().changeTier(key, "fineKind", "UpTo");
  assert.equal(h.render().tiers[0].amount, "");
  assert.equal(h.render().tiers[0].maximumFine, "");
  h.render().changeTier(key, "maximumFine", "1000");
  h.render().changeTier(key, "allowCommunityService", true);
  h.render().addTier();
  const second = h.render().tiers[1].key;
  h.render().changeTier(second, "allowCommunityService", true);
  assert.equal(h.render().tiers[1].allowCommunityService, false);
  assert.equal(h.render().fields.severity, "High");
  assert.equal(h.render().fields.warningEligible, true);
  assert.equal(h.render().highestFee, 1000);
  h.render().changeTier(key, "fineKind", "Unconfirmed");
  assert.equal(h.render().highestFee, null);
});

test("slice 2 edit and undo restore scoring, warning, terms and independent first-tier flags", () => {
  const h = editorHarness();
  h.render().launch(summary);
  h.render();
  h.flush();
  const key = h.render().tiers[0].key;
  assert.equal(h.render().tiers[0].allowBloodDonation, true);
  h.render().changeField("severity", "High");
  h.render().changeField("warningEligible", false);
  h.render().changeTier(key, "allowBloodDonation", false);
  h.render().changeTier(key, "allowCommunityService", true);
  h.render().changeTier(key, "penaltyTerms", "Updated terms");
  assert.equal(h.render().hasChanges, true);
  h.render().undo();
  assert.equal(h.render().fields.severity, "Minor");
  assert.equal(h.render().fields.warningEligible, true);
  assert.equal(h.render().tiers[0].allowBloodDonation, true);
  assert.equal(h.render().tiers[0].allowCommunityService, false);
  assert.equal(h.render().tiers[0].penaltyTerms, "");
  assert.equal(h.render().hasChanges, false);
});

test("slice 2 optional terms and missing values are represented honestly", () => {
  const { buildOrdinanceRequest } = load("features/ordinances/ordinances.utils.ts");
  assert.equal(buildOrdinanceRequest(scoringFields, [fixedTier()]).penaltyTiers[0].penaltyTerms, null);
  assert.equal(buildOrdinanceRequest(scoringFields, [fixedTier({ penaltyTerms: "a".repeat(1001) })]), null);
  const Field = load("features/ordinances/components/OrdinanceField.tsx").default;
  const html = renderToStaticMarkup(React.createElement(Field, {
    label: "Penalty terms (optional)", value: "", multiline: true, required: false,
    disabled: false, onChange() { }, onBlur() { },
  }));
  assert.doesNotMatch(html, /required=/);
  const Fields = load("features/ordinances/components/OrdinanceDetailsFields.tsx").default;
  const h = editorHarness();
  h.render().launch();
  const fieldsHtml = renderToStaticMarkup(React.createElement(Fields, { editor: h.render() }));
  assert.match(fieldsHtml, /Scoring severity/);
  assert.match(fieldsHtml, /Severity affects compliance scoring only/);
  assert.match(fieldsHtml, /Include in the warning ordinance list/);
});
