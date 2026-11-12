import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import test from "node:test";
import vm from "node:vm";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { StaticRouter } from "react-router-dom/server.js";
import ts from "typescript";

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
    .replace(/<[^>]+>/g, "")
    .replaceAll("&#x27;", "'")
    .replaceAll("&amp;", "&")
    .replace(/\s+/g, " ")
    .trim();
}

// The Fish and Seafood card from step 2's run 1 (spec, live check item 1).
// lastFlaggedAt 06:05 UTC is 14:05 in Manila (UTC+8), so 2:05 PM on 8 Nov.
const fishAndSeafood = {
  marketSectionId: 3,
  marketSectionName: "Fish and Seafood",
  categoryCode: "weights_and_measures",
  categoryNameEnglish: "Weights and Measures",
  categoryNameFilipino: "Timbang at Sukat",
  recommendedAction: "Check scales at the start of the morning rush.",
  categoryRecordCount: 4,
  sectionRecordCount: 6,
  riskScore: 10.5,
  riskLevel: "Moderate",
  patternConfidence: "Moderate",
  peakStartHour: 8,
  hourlyCounts: [
    0, 0, 0, 0, 0, 0, 0, 0, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ],
  lastFlaggedAt: "2026-11-08T06:05:00Z",
};

function renderCard(recommendation) {
  const { default: RecommendationCard } = load(
    "features/recommendations/components/RecommendationCard.tsx",
  );
  return renderToStaticMarkup(
    React.createElement(RecommendationCard, { recommendation }),
  );
}

test("W1: the Fish and Seafood card turns the numbers into the agreed words", () => {
  const html = renderCard(fishAndSeafood);
  const words = text(html);
  assert.ok(words.includes("Fish and Seafood"));
  assert.ok(
    words.includes(
      "Timbang at Sukat (Weights and Measures) found in 4 of 6 records in the last 30 days.",
    ),
    words,
  );
  assert.match(
    html,
    /<strong[^>]*>Timbang at Sukat \(Weights and Measures\)<\/strong>/,
  );
  assert.ok(words.includes("Check scales at the start of the morning rush."));
  assert.ok(words.includes("Peak time: 08:00–11:00"), words);
  assert.ok(words.includes("Moderate risk"), words);
  assert.ok(
    words.includes("Pattern confidence: Moderate — based on 6 records"),
    words,
  );
  assert.ok(words.includes("Last flagged: 8 Nov 2026, 2:05 PM"), words);
});

test("W1: a Moderate card uses the amber style, High red, Low and unknown the neutral one", () => {
  const cardClass = (riskLevel) =>
    renderCard({ ...fishAndSeafood, riskLevel }).match(
      /<article class="([^"]*)"/,
    )[1];
  assert.deepEqual(cardClass("Moderate").split(" "), ["card", "moderate"]);
  assert.deepEqual(cardClass("High").split(" "), ["card", "high"]);
  assert.deepEqual(cardClass("Low").split(" "), ["card", "neutral"]);
  assert.deepEqual(cardClass("Unexpected").split(" "), ["card", "neutral"]);
});

test("W1: every risk style the card and bars use exists in their CSS files", () => {
  const rulesIn = (file) =>
    fs.readFileSync(
      path.resolve(root, "features/recommendations/components", file),
      "utf8",
    );
  const card = rulesIn("RecommendationCard.module.css");
  const bars = rulesIn("HourlyBars.module.css");
  for (const tone of ["high", "moderate", "neutral"]) {
    assert.match(card, new RegExp(`^\\.${tone} \\{`, "m"), `card .${tone}`);
    assert.match(bars, new RegExp(`^\\.${tone} \\.peak \\{`, "m"), `bars .${tone}`);
  }
});

test("W1: a peak starting at 22:00 wraps past midnight", () => {
  const words = text(renderCard({ ...fishAndSeafood, peakStartHour: 22 }));
  assert.ok(words.includes("Peak time: 22:00–01:00"), words);
  const { formatPeakWindow } = load(
    "features/recommendations/recommendations.format.ts",
  );
  assert.equal(formatPeakWindow(23), "23:00–02:00");
  assert.equal(formatPeakWindow(0), "00:00–03:00");
});

test("W2: a peak starting at 23:00 highlights hours 23, 0 and 1 only", () => {
  const { default: HourlyBars } = load(
    "features/recommendations/components/HourlyBars.tsx",
  );
  const html = renderToStaticMarkup(
    React.createElement(HourlyBars, {
      hourlyCounts: [
        2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4,
      ],
      peakStartHour: 23,
      tone: "high",
    }),
  );
  assert.match(html, /^<div[^>]*aria-hidden="true"/);
  const bars = [...html.matchAll(/<span class="([^"]*)"/g)].map((match) =>
    match[1].split(" "),
  );
  assert.equal(bars.length, 24);
  const highlighted = bars
    .map((classes, hour) => (classes.includes("peak") ? hour : -1))
    .filter((hour) => hour >= 0);
  assert.deepEqual(highlighted, [0, 1, 23]);
  const heights = [...html.matchAll(/height:([\d.]+)%/g)].map((match) =>
    Number(match[1]),
  );
  assert.equal(heights[23], 100);
  assert.equal(heights[0], 50);
  assert.equal(heights[1], 25);
  assert.equal(heights[5], 0);
});

// The page uses the real hook; only React Query (the outer fetching library)
// is replaced so each state can be shown without a server.
function renderPage(queryResult) {
  const cache = new Map();
  const errors = load("utils/apiErrors.ts", {}, cache);
  const overrides = {
    "@tanstack/react-query": {
      useQuery: () => ({
        data: undefined,
        error: null,
        isLoading: false,
        isFetching: false,
        isError: false,
        refetch() {},
        ...queryResult(errors),
      }),
    },
    "@/api/endpoints/recommendations.api": {
      recommendationsApi: { getRecommendations: async () => undefined },
    },
  };
  const { default: RecommendationsPage } = load(
    "features/recommendations/pages/RecommendationsPage.tsx",
    overrides,
    cache,
  );
  return text(renderToStaticMarkup(React.createElement(RecommendationsPage)));
}

// finishedAt 12:49 UTC is 20:49 Manila; the window starts 13:11 Manila on
// 12 Oct and ends 13:11 Manila on 11 Nov.
const run = {
  finishedAt: "2026-11-11T12:49:00Z",
  windowStart: "2026-10-12T05:11:17Z",
  windowEnd: "2026-11-11T05:11:17Z",
  recordCount: 21,
};

test("W3: loading shows the loading state and no message", () => {
  const cache = new Map();
  const overrides = {
    "@tanstack/react-query": {
      useQuery: () => ({
        isLoading: true,
        isFetching: true,
        isError: false,
        error: null,
        refetch() {},
      }),
    },
    "@/api/endpoints/recommendations.api": {
      recommendationsApi: { getRecommendations: async () => undefined },
    },
  };
  const { default: RecommendationsPage } = load(
    "features/recommendations/pages/RecommendationsPage.tsx",
    overrides,
    cache,
  );
  const html = renderToStaticMarkup(React.createElement(RecommendationsPage));
  assert.match(html, /role="status"[^>]*aria-label="Loading recommended actions"/);
  assert.doesNotMatch(html, /No recommendations yet|Couldn/);
});

test("W3: no run yet shows the first-run message", () => {
  const words = renderPage(() => ({
    data: { run: null, recommendations: [], sectionsWithoutRecommendation: [] },
  }));
  assert.ok(words.includes("Recommended Actions"));
  assert.ok(
    words.includes(
      "No recommendations yet. They appear after the model's first daily run.",
    ),
    words,
  );
  assert.doesNotMatch(words, /Last updated|No recommendation for/);
});

test("W3: a run with no cards shows the summary, the plain message and the no-recommendation line", () => {
  const words = renderPage(() => ({
    data: {
      run,
      recommendations: [],
      sectionsWithoutRecommendation: ["Dry Goods Annex", "Meat", "Vegetables"],
    },
  }));
  assert.ok(words.includes("Last updated: 11 Nov 2026, 8:49 PM"), words);
  assert.ok(words.includes("Period: 12 Oct 2026 – 11 Nov 2026"), words);
  assert.ok(words.includes("Records read: 21"), words);
  assert.ok(
    words.includes("No section has a recommendation for this period."),
    words,
  );
  assert.ok(
    words.includes("No recommendation for: Dry Goods Annex, Meat, Vegetables."),
    words,
  );
  assert.doesNotMatch(words, /No recommendations yet/);
});

test("W3: cards keep the server order and the empty no-recommendation line is left out", () => {
  const dryGoods = {
    ...fishAndSeafood,
    marketSectionId: 1,
    marketSectionName: "Dry Goods",
    riskLevel: "Low",
  };
  const words = renderPage(() => ({
    data: {
      run,
      recommendations: [fishAndSeafood, dryGoods],
      sectionsWithoutRecommendation: [],
    },
  }));
  assert.ok(words.indexOf("Fish and Seafood") < words.indexOf("Dry Goods"));
  assert.doesNotMatch(words, /No recommendation for|No section has/);
});

test("W3: an error shows the server's message with Try again", () => {
  const words = renderPage((errors) => ({
    isError: true,
    error: new errors.ApiRequestError(
      "Recommendations are unavailable right now.",
      500,
    ),
  }));
  assert.ok(words.includes("Recommendations are unavailable right now."));
  assert.ok(words.includes("Try again"));
  assert.doesNotMatch(words, /Couldn't load recommended actions/);
});

test("W3: an error without a message shows the written fallback with Try again", () => {
  const words = renderPage((errors) => ({
    isError: true,
    error: new errors.ApiRequestError(undefined, 500),
  }));
  assert.ok(words.includes("Couldn't load recommended actions."), words);
  assert.ok(words.includes("Try again"));
});

function sidebarLabels(role) {
  const { default: Sidebar } = load(
    "components/layout/Sidebar/Sidebar.tsx",
    {
      "@/context/AuthContext": {
        useAuth: () => ({
          user: { role, firstName: "Verification", status: "Active" },
          logout() {},
        }),
      },
      "@/assets/icons/Marikina_City_Seal.svg (1).webp": { default: "seal" },
      "@/components/ui/UrlImage": { default: () => null },
    },
  );
  const html = renderToStaticMarkup(
    React.createElement(
      StaticRouter,
      { location: "/dashboard" },
      React.createElement(Sidebar, {
        open: false,
        collapsed: false,
        onClose() {},
      }),
    ),
  );
  return [...html.matchAll(/<a\b[^>]*>/g)].map(([tag]) => ({
    label: tag.match(/aria-label="([^"]+)"/)[1],
    to: tag.match(/href="([^"]+)"/)[1],
  }));
}

test("W4: Head Admin and Admin Officer see Recommended Actions directly after Analytics", () => {
  for (const role of ["HeadAdmin", "AdminOfficer"]) {
    const items = sidebarLabels(role);
    const labels = items.map((item) => item.label);
    const analytics = labels.indexOf("Analytics");
    assert.ok(analytics >= 0, `${role} must see Analytics`);
    assert.equal(labels[analytics + 1], "Recommended Actions", role);
    assert.equal(
      items.find((item) => item.label === "Recommended Actions").to,
      "/recommendations",
    );
  }
});

test("W4: a Market Enforcer does not see Recommended Actions", () => {
  const labels = sidebarLabels("MarketEnforcer").map((item) => item.label);
  assert.ok(labels.includes("Dashboard"));
  assert.ok(!labels.includes("Recommended Actions"));
});
