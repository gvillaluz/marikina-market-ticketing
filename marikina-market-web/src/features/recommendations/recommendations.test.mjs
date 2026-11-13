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
  id: 11,
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
  review: null,
};

function renderCard(recommendation, props = {}) {
  const { default: RecommendationCard } = load(
    "features/recommendations/components/RecommendationCard.tsx",
  );
  return renderToStaticMarkup(
    React.createElement(RecommendationCard, {
      recommendation,
      isSaving: false,
      onReview() {},
      onDismiss() {},
      ...props,
    }),
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
function renderPage(queryResult, mutationResult = () => ({}), raw = false) {
  const cache = new Map();
  const errors = load("utils/apiErrors.ts", {}, cache);
  const overrides = {
    "@tanstack/react-query": {
      useQueryClient: () => ({ setQueryData() {} }),
      useMutation: () => ({
        isPending: false,
        isError: false,
        error: null,
        variables: undefined,
        mutate() {},
        ...mutationResult(errors),
      }),
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
  const html = renderToStaticMarkup(React.createElement(RecommendationsPage));
  return raw ? html : text(html);
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
      useQueryClient: () => ({ setQueryData() {} }),
      useMutation: () => ({ isPending: false, isError: false, mutate() {} }),
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

// ---- Step 4: administrator review ------------------------------------------

const reviewedByJuan = {
  decision: "Reviewed",
  reviewedByName: "Juan Dela Cruz",
  reviewedAt: "2026-11-11T12:49:00Z",
};
const dismissedByMaria = {
  decision: "Dismissed",
  reviewedByName: "Maria Santos",
  reviewedAt: "2026-11-12T01:30:00Z",
};
const dryGoodsCard = {
  ...fishAndSeafood,
  id: 12,
  marketSectionId: 1,
  marketSectionName: "Dry Goods",
  riskLevel: "Low",
};

function buttonLabels(html) {
  return [...html.matchAll(/<button\b[^>]*>(.*?)<\/button>/g)].map(([, inner]) =>
    text(inner),
  );
}

function openData(...recommendations) {
  return {
    data: { run, recommendations, sectionsWithoutRecommendation: [] },
  };
}

test("W5: a card nobody has looked at shows both buttons, enabled", () => {
  const html = renderCard(fishAndSeafood);
  assert.deepEqual(buttonLabels(html), ["Mark as reviewed", "Dismiss"]);
  assert.doesNotMatch(html, /<button[^>]*disabled/);
  assert.doesNotMatch(text(html), /Reviewed by|Dismissed by/);
});

test("W5: a reviewed card shows who and when, keeps Dismiss and drops Mark as reviewed", () => {
  const html = renderCard({ ...fishAndSeafood, review: reviewedByJuan });
  // 12:49 UTC is 20:49 in Manila.
  assert.ok(
    text(html).includes("Reviewed by Juan Dela Cruz on 11 Nov 2026, 8:49 PM"),
    text(html),
  );
  assert.deepEqual(buttonLabels(html), ["Dismiss"]);
});

test("W5: a dismissed card shows who and when and has no buttons", () => {
  const html = renderCard({ ...fishAndSeafood, review: dismissedByMaria });
  // 01:30 UTC on 12 Nov is 09:30 in Manila.
  assert.ok(
    text(html).includes("Dismissed by Maria Santos on 12 Nov 2026, 9:30 AM"),
    text(html),
  );
  assert.deepEqual(buttonLabels(html), []);
});

test("W5: the buttons are disabled while the click is being saved", () => {
  const html = renderCard(fishAndSeafood, { isSaving: true });
  const buttons = [...html.matchAll(/<button\b[^>]*>/g)].map(([tag]) => tag);
  assert.equal(buttons.length, 2);
  for (const tag of buttons) assert.match(tag, /disabled/);
  const reviewed = renderCard(
    { ...fishAndSeafood, review: reviewedByJuan },
    { isSaving: true },
  );
  assert.match(reviewed.match(/<button\b[^>]*>/)[0], /disabled/);
});

test("W5: a dismissed card appears only in the Dismissed list, below the open cards", () => {
  const words = renderPage(() =>
    openData({ ...fishAndSeafood, review: dismissedByMaria }, dryGoodsCard),
  );
  const count = (needle) => words.split(needle).length - 1;
  assert.equal(count("Fish and Seafood"), 1, words);
  assert.equal(count("Dry Goods"), 1, words);
  assert.equal(count("Dismissed by Maria Santos"), 1, words);
  const heading = words.search(/Dismissed\s*Fish and Seafood/);
  assert.ok(heading >= 0, words);
  assert.ok(words.indexOf("Dry Goods") < heading, words);
  // Only Dry Goods is still open, so only one "Mark as reviewed".
  assert.equal(count("Mark as reviewed"), 1, words);
});

test("W5: with nothing dismissed there is no Dismissed list", () => {
  const words = renderPage(() => openData(fishAndSeafood, dryGoodsCard));
  assert.doesNotMatch(words, /Dismissed/);
});

test("W5: when every card is dismissed the page says so and still lists them", () => {
  const words = renderPage(() =>
    openData({ ...fishAndSeafood, review: dismissedByMaria }),
  );
  assert.ok(words.includes("Every recommendation has been dismissed."), words);
  assert.doesNotMatch(words, /No section has a recommendation/);
  assert.ok(words.includes("Dismissed by Maria Santos"), words);
});

test("W5: a failed click shows the server's message", () => {
  const words = renderPage(
    () => openData(fishAndSeafood),
    (errors) => ({
      isError: true,
      error: new errors.ApiRequestError(
        "This recommendation was updated. Refresh the page.",
        400,
      ),
    }),
  );
  assert.ok(
    words.includes("This recommendation was updated. Refresh the page."),
    words,
  );
});

test("W5: a failed click without a message shows the written fallback", () => {
  const words = renderPage(
    () => openData(fishAndSeafood),
    (errors) => ({
      isError: true,
      error: new errors.ApiRequestError(undefined, 500),
    }),
  );
  assert.ok(words.includes("Couldn't save your decision."), words);
});

test("W5: no error message shows when nothing has failed", () => {
  const words = renderPage(() => openData(fishAndSeafood));
  assert.doesNotMatch(words, /Couldn't save your decision/);
});

test("W5: only the card being saved has disabled buttons", () => {
  const words = renderPage(
    () => openData(fishAndSeafood, dryGoodsCard),
    () => ({ isPending: true, variables: { id: 12, action: "review" } }),
    true,
  );
  const cards = words.split("<article").slice(1);
  assert.equal(cards.length, 2);
  // Fish and Seafood (id 11) is not saving; Dry Goods (id 12) is.
  assert.doesNotMatch(cards[0], /<button[^>]*disabled/);
  assert.match(cards[1], /<button[^>]*disabled/);
});

test("W5: the Are you sure box names the section and its problem, and is locked while saving", () => {
  const modal = {
    default: ({ open, title, children, footer }) =>
      open
        ? React.createElement("div", { role: "dialog" }, title, children, footer)
        : null,
  };
  const { default: DismissConfirm } = load(
    "features/recommendations/components/DismissConfirm.tsx",
    { "@/components/ui/Modal": modal },
  );
  const render = (props) =>
    renderToStaticMarkup(
      React.createElement(DismissConfirm, {
        recommendation: fishAndSeafood,
        isSaving: false,
        onConfirm() {},
        onCancel() {},
        ...props,
      }),
    );
  const words = text(render({}));
  assert.ok(words.includes("Are you sure you want to dismiss"), words);
  assert.ok(words.includes("Fish and Seafood"), words);
  assert.ok(words.includes("Timbang at Sukat (Weights and Measures)"), words);
  assert.ok(words.includes("cannot be undone"), words);
  assert.deepEqual(buttonLabels(render({})).slice(-2), ["Cancel", "Dismiss"]);
  assert.equal(render({ recommendation: null }), "");
  const saving = render({ isSaving: true });
  assert.ok(text(saving).includes("Dismissing…"), text(saving));
  for (const [tag] of saving.matchAll(/<button\b[^>]*>/g))
    assert.match(tag, /disabled/);
});

test("W5: the review and dismiss clicks post to the agreed routes and return the review", async () => {
  const calls = [];
  const client = {
    default: {
      get: async () => ({ data: undefined }),
      post: async (url, body) => {
        calls.push([url, body]);
        return { data: reviewedByJuan };
      },
    },
  };
  const { recommendationsApi } = load("api/endpoints/recommendations.api.ts", {
    "@/api/client": client,
  });
  assert.deepEqual(await recommendationsApi.review(11), reviewedByJuan);
  assert.deepEqual(await recommendationsApi.dismiss(12), reviewedByJuan);
  assert.deepEqual(calls, [
    ["/admin/recommendations/11/review", undefined],
    ["/admin/recommendations/12/dismiss", undefined],
  ]);
});

test("W5: a saved review is put on its own card and nothing else changes", () => {
  const { withReview } = load(
    "features/recommendations/recommendations.format.ts",
  );
  const before = {
    run,
    recommendations: [fishAndSeafood, dryGoodsCard],
    sectionsWithoutRecommendation: ["Meat"],
  };
  const after = withReview(before, 12, dismissedByMaria);
  assert.equal(after.recommendations[0], fishAndSeafood);
  assert.deepEqual(JSON.parse(JSON.stringify(after.recommendations[1])), {
    ...dryGoodsCard,
    review: dismissedByMaria,
  });
  assert.equal(after.run, run);
  assert.deepEqual(after.sectionsWithoutRecommendation, ["Meat"]);
  assert.equal(before.recommendations[1].review, null);
});
