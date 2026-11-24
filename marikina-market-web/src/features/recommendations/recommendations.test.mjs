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

// Each tile as [label, value, caption].
function tiles(html) {
  return html
    .split('<div class="tile')
    .slice(1)
    .map((tile) =>
      [...tile.matchAll(/<d[td][^>]*>(.*?)<\/d[td]>/g)]
        .slice(0, 3)
        .map(([, inner]) => text(inner)),
    );
}

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

test("W1: the Fish and Seafood card shows its numbers as four tiles", () => {
  const html = renderCard(fishAndSeafood);
  const words = text(html);
  assert.ok(words.includes("Fish and Seafood"));
  // 4 of the section's 6 records; peak 08:00 plus three hours; confidence as sent.
  assert.deepEqual(tiles(html), [
    ["Found in", "4 of 6", "records, last 30 days"],
    ["Peak time", "08:00–11:00", "busiest 3 hours"],
    ["Confidence", "Moderate", "based on 6 records"],
    ["Last detected", "8 Nov 2026", "2:05 PM"],
  ]);
  assert.match(
    html,
    /<strong[^>]*>Timbang at Sukat \(Weights and Measures\)<\/strong>/,
  );
  assert.ok(words.includes("Check scales at the start of the morning rush."));
  assert.ok(words.includes("Moderate risk"), words);
  assert.doesNotMatch(html, /<footer/);
  assert.doesNotMatch(words, /flagged/i);
});

test("C1: the card fills its column and puts the two essays side by side when it is wide enough", () => {
  const html = renderCard(fishAndSeafood);
  const essays = html.split('<div class="essays">')[1];
  assert.ok(essays, "the two essays share one wrapper");
  assert.ok(
    essays.indexOf("Prominent violation") < essays.indexOf("Recommended action"),
  );
  assert.ok(essays.indexOf("Recommended action") < essays.indexOf("Records by hour"));
  const css = (file) =>
    fs.readFileSync(
      path.resolve(root, "features/recommendations/components", file),
      "utf8",
    );
  const card = css("RecommendationCard.module.css");
  assert.doesNotMatch(card.match(/\.card \{[^}]*\}/)[0], /max-width/);
  assert.match(card.match(/\.card \{[^}]*\}/)[0], /container-type: inline-size/);
  assert.match(
    card,
    /@container \(min-width: 45rem\) \{\s*\.essays \{\s*grid-template-columns: repeat\(2, minmax\(0, 1fr\)\);/,
  );
  assert.match(
    css("RecommendationTiles.module.css"),
    /@container \(min-width: 34rem\) \{\s*\.tiles \{\s*grid-template-columns: repeat\(4, minmax\(0, 1fr\)\);/,
  );
});

test("C2: every hour with records takes the risk color, the peak strongest, and empty hours stay gray", () => {
  const { default: HourlyBars } = load(
    "features/recommendations/components/HourlyBars.tsx",
  );
  const counts = Array(24).fill(0);
  counts[8] = 3;
  counts[9] = 2;
  counts[15] = 1;
  const html = renderToStaticMarkup(
    React.createElement(HourlyBars, {
      hourlyCounts: counts,
      peakStartHour: 8,
      tone: "moderate",
    }),
  );
  const bars = [...html.matchAll(/<span class="([^"]*)"/g)]
    .map((match) => match[1].split(" ").filter(Boolean))
    .filter((classes) => classes.includes("bar"));
  const hoursWith = (name) =>
    bars.flatMap((classes, hour) => (classes.includes(name) ? [hour] : []));
  assert.deepEqual(hoursWith("filled"), [8, 9, 15]);
  assert.deepEqual(hoursWith("peak"), [8, 9, 10]);
  const rules = fs.readFileSync(
    path.resolve(root, "features/recommendations/components/HourlyBars.module.css"),
    "utf8",
  );
  for (const [tone, color] of [
    ["high", "--danger"],
    ["moderate", "--warning"],
    ["neutral", "--text-muted"],
  ]) {
    assert.match(
      rules,
      new RegExp(`^\\.${tone} \\.filled \\{\\s*background: color-mix\\(in srgb, var\\(${color}\\)`, "m"),
      `${tone} tint`,
    );
    assert.match(
      rules,
      new RegExp(`^\\.${tone} \\.peak\\.filled \\{\\s*background: var\\(${color}\\);`, "m"),
      `${tone} peak`,
    );
  }
});

// ---- Essay-style card text ---------------------------------------------------

test("E1: the prominent violation reads as a paragraph built from the card's own numbers", () => {
  const words = text(renderCard(fishAndSeafood));
  assert.ok(
    words.includes(
      "Timbang at Sukat (Weights and Measures) is the leading concern on Fish and Seafood, " +
        "appearing in 4 of the 6 warnings and tickets recorded in the last 30 days. " +
        "The busiest period for detected violations was 08:00–11:00, and the latest was on 8 Nov 2026. " +
        "Risk is rated Moderate. Confidence is Moderate because this pattern is based on 6 records.",
    ),
    words,
  );
  assert.doesNotMatch(words, /most common/i);
});

test("E1: the paragraph follows a different card's risk, confidence, hours and date", () => {
  const words = text(
    renderCard({
      ...fishAndSeafood,
      marketSectionName: "Meat",
      categoryNameEnglish: "Sanitation",
      categoryNameFilipino: "Kalinisan",
      categoryRecordCount: 7,
      sectionRecordCount: 9,
      riskLevel: "High",
      patternConfidence: "High",
      peakStartHour: 22,
      // 16:30 UTC on 13 Nov is 00:30 on 14 Nov in Manila.
      lastFlaggedAt: "2026-11-13T16:30:00Z",
    }),
  );
  assert.ok(
    words.includes(
      "Kalinisan (Sanitation) is the leading concern on Meat, " +
        "appearing in 7 of the 9 warnings and tickets recorded in the last 30 days. " +
        "The busiest period for detected violations was 22:00–01:00, and the latest was on 14 Nov 2026. " +
        "Risk is rated High. Confidence is High because this pattern is based on 9 records.",
    ),
    words,
  );
});

test("E2: the recommended action keeps the model's sentence first, then timing, what to record and follow-up", () => {
  const words = text(
    renderCard({
      ...fishAndSeafood,
      categoryCode: "Sanitation",
      recommendedAction:
        "Inspect the affected stall and require correction of food handling or waste and hygiene issues before follow-up.",
    }),
  );
  assert.ok(
    words.includes(
      "Inspect the affected stall and require correction of food handling or waste and hygiene issues before follow-up. " +
        "For any on-site check, go around 08:00–11:00, the busiest period for detected violations on this street. " +
        "Record the specific hygiene or food-safety problem seen and the vendor responsible for it. " +
        "Follow up afterward to confirm the problem has been corrected.",
    ),
    words,
  );
});

test("E2: a category the website does not know leaves out only the what-to-record sentence", () => {
  const words = text(
    renderCard({ ...fishAndSeafood, categoryCode: "Not A Known Category" }),
  );
  assert.ok(
    words.includes(
      "Check scales at the start of the morning rush. " +
        "For any on-site check, go around 08:00–11:00, the busiest period for detected violations on this street. " +
        "Follow up afterward to confirm the problem has been corrected.",
    ),
    words,
  );
});

test("E3: each of the model's 29 categories has its own what-to-record sentence", () => {
  const { whatToRecord } = load(
    "features/recommendations/recommendations.text.ts",
  );
  const codes = [
    "Vendor Identification", "Permit & Licensing", "Sanitation", "WeightMeasures",
    "Lighting & Energy", "Stall Occupancy", "Stall Management", "Stall Construction",
    "Utilities", "Stall Rental", "Illegal Vendor", "Public Order", "Liquor",
    "Market Conduct", "Obstruction", "DressCode", "Bladed Instruments", "Traffic",
    "Porter Regulation", "Promotions", "Advertising", "Signage & Streamers",
    "Entertainment Activities", "Lighting Facilities", "Market Rules",
    "Price Monitoring", "Market Fees & Surcharges", "Resisting Authority",
    "General Penalties",
  ];
  assert.equal(codes.length, 29);
  const sentences = codes.map((code) => whatToRecord(code));
  for (const [index, sentence] of sentences.entries())
    assert.match(sentence ?? "", /^Record .+\.$/, codes[index]);
  assert.equal(new Set(sentences).size, 29);
});

test("W1: a section with one record says record, not records", () => {
  const html = renderCard({
    ...fishAndSeafood,
    categoryRecordCount: 1,
    sectionRecordCount: 1,
  });
  assert.deepEqual(tiles(html)[0], ["Found in", "1 of 1", "record, last 30 days"]);
  assert.deepEqual(tiles(html)[2], ["Confidence", "Moderate", "based on 1 record"]);
});

test("W1: the risk badge uses the shared badge: amber for Moderate, red for High, neutral for Low and unknown", () => {
  const { default: RiskBadge } = load(
    "features/recommendations/components/RiskBadge.tsx",
  );
  const badge = (riskLevel) =>
    renderToStaticMarkup(React.createElement(RiskBadge, { riskLevel }));
  const badgeClass = (riskLevel) =>
    badge(riskLevel).match(/^<span class="([^"]*)"/)[1].split(" ");
  assert.deepEqual(badgeClass("Moderate"), ["badge", "warning"]);
  assert.deepEqual(badgeClass("High"), ["badge", "danger"]);
  assert.deepEqual(badgeClass("Low"), ["badge", "neutral"]);
  assert.deepEqual(badgeClass("Unexpected"), ["badge", "neutral"]);
  assert.equal(text(badge("High")), "High risk");
  const tilesClass = (riskLevel) =>
    renderCard({ ...fishAndSeafood, riskLevel }).match(/<dl class="([^"]*)"/)[1];
  assert.deepEqual(tilesClass("High").split(" "), ["tiles", "high"]);
  assert.deepEqual(tilesClass("Low").split(" "), ["tiles", "neutral"]);
});

test("W1: every risk style the card and bars use exists in their CSS files", () => {
  const rulesIn = (file) =>
    fs.readFileSync(
      path.resolve(root, "features/recommendations/components", file),
      "utf8",
    );
  const tileRules = rulesIn("RecommendationTiles.module.css");
  const bars = rulesIn("HourlyBars.module.css");
  for (const tone of ["high", "moderate", "neutral"]) {
    assert.match(
      tileRules,
      new RegExp(`^\\.${tone} \\.found \\{`, "m"),
      `tiles .${tone}`,
    );
    assert.match(bars, new RegExp(`^\\.${tone} \\.peak\\.filled \\{`, "m"), `bars .${tone}`);
  }
});

test("W1: a peak starting at 22:00 wraps past midnight", () => {
  const html = renderCard({ ...fishAndSeafood, peakStartHour: 22 });
  assert.equal(tiles(html)[1][1], "22:00–01:00");
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
  const bars = [...html.matchAll(/<span class="([^"]*)"/g)]
    .map((match) => match[1].split(" "))
    .filter((classes) => classes.includes("bar"));
  assert.equal(bars.length, 24);
  assert.deepEqual(
    [...html.matchAll(/<span class="tick">([^<]*)</g)].map((match) => match[1]),
    ["12 AM", "6 AM", "12 PM", "6 PM", "12 AM"],
  );
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
  const html = renderToStaticMarkup(
    React.createElement(
      StaticRouter,
      { location: "/recommendations" },
      React.createElement(RecommendationsPage),
    ),
  );
  return raw ? html : text(html);
}

// finishedAt 12:49 UTC is 20:49 Manila; the window starts 13:11 Manila on
// 12 Oct and ends 13:11 Manila on 11 Nov.
const run = {
  finishedAt: "2026-11-11T12:49:00Z",
  windowStart: "2026-10-12T05:11:17Z",
  windowEnd: "2026-11-11T05:11:17Z",
  recordCount: 21,
  detectedRecordCount: 3,
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
  assert.ok(words.includes("No recommendations yet"), words);
  assert.ok(
    words.includes("They appear after the model's first daily run."),
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
    words.includes("No street has a recommendation for this period."),
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
  assert.doesNotMatch(words, /No recommendation for|No street has/);
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
    label: tag.match(/aria-label="([^"]+)"/)[1].replaceAll("&amp;", "&"),
    to: tag.match(/href="([^"]+)"/)[1],
  }));
}

test("W4: Head Admin and Admin Officer see Insights & Recommendations directly after Analytics", () => {
  for (const role of ["HeadAdmin", "AdminOfficer"]) {
    const items = sidebarLabels(role);
    const labels = items.map((item) => item.label);
    const analytics = labels.indexOf("Analytics");
    assert.ok(analytics >= 0, `${role} must see Analytics`);
    assert.equal(labels[analytics + 1], "Insights & Recommendations", role);
    assert.equal(
      items.find((item) => item.label === "Insights & Recommendations").to,
      "/recommendations",
    );
  }
});

test("W4: a Market Enforcer does not see Insights & Recommendations", () => {
  const labels = sidebarLabels("MarketEnforcer").map((item) => item.label);
  assert.ok(labels.includes("Dashboard"));
  assert.ok(!labels.includes("Insights & Recommendations"));
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

// ---- List and detail layout --------------------------------------------------

// Each list row as [section, records, risk, status]; the open row is marked.
function listRows(html) {
  return html
    .split("<li>")
    .slice(1)
    .map((row) => ({
      open: /aria-current="true"/.test(row),
      words: [
        ...["name", "meta"].map((part) =>
          text(row.match(new RegExp(`<span class="${part}[^"]*">(.*?)</span>`))[1]),
        ),
        ...[...row.matchAll(/<span class="badge[^"]*">(.*?)<\/span>/g)]
          .slice(0, 2)
          .map(([, inner]) => text(inner)),
      ],
    }));
}

function openCardTitle(html) {
  const cards = html.split("<article").slice(1);
  assert.equal(cards.length, 1, "exactly one card is open");
  return text(cards[0].match(/<h2[^>]*>(.*?)<\/h2>/)[1]);
}

test("L1: the list shows every section with its records, risk and status, dismissed last", () => {
  const html = renderPage(
    () =>
      openData(
        { ...fishAndSeafood, review: dismissedByMaria },
        dryGoodsCard,
        { ...fishAndSeafood, id: 13, marketSectionName: "Meat", review: reviewedByJuan },
      ),
    undefined,
    true,
  );
  assert.deepEqual(
    listRows(html).map((row) => row.words),
    [
      ["Dry Goods", "4 of 6 records", "Low risk", "Needs review"],
      ["Meat", "4 of 6 records", "Moderate risk", "Reviewed"],
      ["Fish and Seafood", "4 of 6 records", "Moderate risk", "Dismissed"],
    ],
  );
  assert.ok(
    text(html).includes("1 needs review · 1 reviewed · 1 dismissed"),
    text(html),
  );
});

test("L1: every status uses the shared badge with its words and color", () => {
  const { default: StatusTag } = load(
    "features/recommendations/components/StatusTag.tsx",
  );
  const tag = (review) =>
    renderToStaticMarkup(React.createElement(StatusTag, { review }));
  for (const [review, words, tone] of [
    [null, "Needs review", "info"],
    [reviewedByJuan, "Reviewed", "success"],
    [dismissedByMaria, "Dismissed", "neutral"],
  ]) {
    const html = tag(review);
    assert.equal(text(html), words);
    assert.match(html, new RegExp(`^<span class="badge ${tone}"`));
  }
});

test("L2: the page opens on the first section that still needs review", () => {
  const html = renderPage(
    () => openData({ ...fishAndSeafood, review: reviewedByJuan }, dryGoodsCard),
    undefined,
    true,
  );
  assert.equal(openCardTitle(html), "Dry Goods");
  assert.deepEqual(
    listRows(html).map((row) => row.open),
    [false, true],
  );
  // Only the open card's buttons are in the card.
  assert.deepEqual(buttonLabels(html.split("<article")[1]), [
    "Mark as reviewed",
    "Dismiss",
  ]);
});

test("L2: when nothing needs review the first section in the list is open", () => {
  const html = renderPage(
    () =>
      openData(
        { ...fishAndSeafood, review: dismissedByMaria },
        { ...dryGoodsCard, review: reviewedByJuan },
      ),
    undefined,
    true,
  );
  assert.equal(openCardTitle(html), "Dry Goods");
});

test("L2: a chosen section stays open; an unknown choice falls back", () => {
  const { sectionToOpen, inListOrder } = load(
    "features/recommendations/recommendations.format.ts",
  );
  const sections = inListOrder([
    { ...fishAndSeafood, review: dismissedByMaria },
    dryGoodsCard,
  ]);
  assert.deepEqual(
    Array.from(sections, (card) => card.id),
    [12, 11],
  );
  assert.equal(sectionToOpen(sections, 11).id, 11);
  assert.equal(sectionToOpen(sections, null).id, 12);
  assert.equal(sectionToOpen(sections, 999).id, 12);
  assert.equal(sectionToOpen([], null), null);
});

test("L3: with nothing dismissed no row says Dismissed", () => {
  const html = renderPage(() => openData(fishAndSeafood, dryGoodsCard), undefined, true);
  assert.deepEqual(
    listRows(html).map((row) => row.words[3]),
    ["Needs review", "Needs review"],
  );
  assert.ok(text(html).includes("2 need review · 0 reviewed · 0 dismissed"), text(html));
});

test("L3: when every section is dismissed the list and the card still show them", () => {
  const html = renderPage(
    () => openData({ ...fishAndSeafood, review: dismissedByMaria }),
    undefined,
    true,
  );
  const words = text(html);
  assert.doesNotMatch(words, /Every recommendation has been dismissed/);
  assert.doesNotMatch(words, /No street has a recommendation/);
  assert.equal(openCardTitle(html), "Fish and Seafood");
  assert.ok(words.includes("Dismissed by Maria Santos"), words);
  assert.deepEqual(buttonLabels(html.split("<article")[1]), []);
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

test("W5: the open card's buttons are disabled only while that card is being saved", () => {
  // Fish and Seafood (id 11) is the open card.
  const openCard = (savingId) =>
    renderPage(
      () => openData(fishAndSeafood, dryGoodsCard),
      () => ({ isPending: true, variables: { id: savingId, action: "review" } }),
      true,
    ).split("<article")[1];
  assert.doesNotMatch(openCard(12), /<button[^>]*disabled/);
  assert.match(openCard(11), /<button[^>]*disabled/);
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

// ---- Detected violations page ---------------------------------------------------

// 16:30 UTC on 13 Nov is 00:30 on 14 Nov in Manila.
const detectedTicket = {
  ticketId: 31,
  controlNumber: "P-31",
  type: "Ticket",
  marketSectionName: "Sample Street",
  description: "Madumi ang puwesto at nakaharang ang mga kahon sa daanan.",
  issuedAt: "2026-11-13T16:30:00Z",
  categoryCodes: ["Obstruction", "Sanitation"],
};

function renderDetected(queryResult) {
  const cache = new Map();
  const errors = load("utils/apiErrors.ts", {}, cache);
  const overrides = {
    "@tanstack/react-query": {
      keepPreviousData: undefined,
      useQuery: ({ queryKey }) =>
        queryKey[0] === "market_sections"
          ? {
              data: [{ id: 1, name: "Sample Street", isActive: true }],
              isPending: false,
              isError: false,
            }
          : {
              data: undefined,
              error: null,
              isPending: false,
              isPlaceholderData: false,
              isFetching: false,
              isError: false,
              refetch() {},
              ...queryResult(errors),
            },
    },
    "@/api/endpoints/recommendations.api": {
      recommendationsApi: { getDetectedViolations: async () => undefined },
    },
    "@/api/endpoints/marketSection.api": {
      marketSectionApi: { getAll: async () => [] },
    },
    "@/components/ui/TicketModal/TicketModal": { TicketModal: () => null },
  };
  const { default: DetectedViolationsPage } = load(
    "features/recommendations/pages/DetectedViolationsPage.tsx",
    overrides,
    cache,
  );
  return renderToStaticMarkup(
    React.createElement(
      StaticRouter,
      { location: "/recommendations/detected" },
      React.createElement(DetectedViolationsPage),
    ),
  );
}

const detectedPage = (items, total = items.length) => () => ({
  data: { items, hasMore: total > items.length, total },
});

test("D1: a row shows the number, type, date, street, every violation and description, with a View button", () => {
  const html = renderDetected(detectedPage([detectedTicket]));
  const words = text(html);
  assert.ok(words.includes("Detected violations"), words);
  assert.ok(words.includes("1 records"), words);
  for (const part of [
    "P-31",
    "Ticket",
    "14 Nov 2026",
    "Sample Street",
    "Sagabal sa Daanan (Obstruction), Kalinisan (Sanitation)",
    "Madumi ang puwesto at nakaharang ang mga kahon sa daanan.",
  ])
    assert.ok(words.includes(part), part);
  assert.match(html, /aria-label="View ticket P-31"/);
  assert.match(html, /<tr class="clickable"/);
});

test("D1: rows stay in the server's order", () => {
  const words = text(
    renderDetected(
      detectedPage([
        detectedTicket,
        { ...detectedTicket, ticketId: 12, controlNumber: "W-12", type: "Warning" },
      ]),
    ),
  );
  assert.ok(words.indexOf("P-31") < words.indexOf("W-12"), words);
});

test("D2: a record with no number says so, and an unknown violation shows its saved name", () => {
  const words = text(
    renderDetected(
      detectedPage([
        { ...detectedTicket, controlNumber: null, categoryCodes: ["Not Known"] },
      ]),
    ),
  );
  assert.ok(words.includes("No control number"), words);
  assert.ok(words.includes("Not Known"), words);
});

test("D2: a description containing markup is shown as plain text", () => {
  const html = renderDetected(
    detectedPage([{ ...detectedTicket, description: "<b>Madumi</b>" }]),
  );
  assert.doesNotMatch(html, /<b>Madumi/);
  assert.match(html, /&lt;b&gt;Madumi/);
});

test("D3: no detected records shows a plain message", () => {
  const words = text(renderDetected(detectedPage([])));
  assert.ok(words.includes("No violations were detected in the latest check."), words);
});

test("D3: loading shows the table's loading state and no empty message", () => {
  const words = text(renderDetected(() => ({ isPending: true, isFetching: true })));
  assert.ok(words.includes("Loading"), words);
  assert.doesNotMatch(words, /No violations were detected/);
});

test("D3: an error shows the server's message, or the written fallback, with Try again", () => {
  const withMessage = text(
    renderDetected((errors) => ({
      isError: true,
      error: new errors.ApiRequestError("The list is unavailable.", 500),
    })),
  );
  assert.ok(withMessage.includes("The list is unavailable."), withMessage);
  assert.ok(withMessage.includes("Try again"), withMessage);
  const fallback = text(
    renderDetected((errors) => ({
      isError: true,
      error: new errors.ApiRequestError(undefined, 500),
    })),
  );
  assert.ok(fallback.includes("Couldn't load detected violations."), fallback);
  assert.doesNotMatch(fallback, /No violations were detected/);
});

test("D4: 23 records at 10 per page show 3 pages and the range", () => {
  const html = renderDetected(detectedPage([detectedTicket], 23));
  const words = text(html);
  assert.ok(words.includes("23 records"), words);
  assert.ok(words.includes("Showing 1–1 of 23 records"), words);
  assert.match(html, /aria-label="Go to page 3"/);
  assert.doesNotMatch(html, /aria-label="Go to page 4"/);
});

test("D4: the page has search and street, type and violation filters", () => {
  const html = renderDetected(detectedPage([detectedTicket]));
  assert.match(html, /aria-label="Search detected violations"/);
  assert.match(html, /placeholder="Search control number or description"/);
  const words = text(html);
  for (const label of ["All types", "All Streets", "All violations"])
    assert.ok(words.includes(label), label);
});

test("D5: the list asks the agreed route with its page and filters", async () => {
  const calls = [];
  const client = {
    default: {
      get: async (url, config) => {
        calls.push([url, config]);
        return { data: { items: [], hasMore: false, total: 0 } };
      },
      post: async () => ({ data: undefined }),
    },
  };
  const { recommendationsApi } = load("api/endpoints/recommendations.api.ts", {
    "@/api/client": client,
  });
  const params = {
    offset: 20,
    search: "basura",
    type: "Warning",
    marketSectionId: 2,
    categoryCode: "Sanitation",
  };
  await recommendationsApi.getDetectedViolations(params);
  assert.equal(calls[0][0], "/admin/recommendations/findings");
  assert.deepEqual({ ...calls[0][1].params }, params);
});

test("D6: Recommended Actions shows only the count and the shared View list button, even with no cards", () => {
  const html = renderPage(
    () => ({
      data: {
        run,
        recommendations: [],
        sectionsWithoutRecommendation: ["Meat"],
      },
    }),
    undefined,
    true,
  );
  assert.ok(text(html).includes("Detected violations: 3"), text(html));
  assert.match(html, /<button class="button outline sm"[^>]*><span>View list<\/span><\/button>/);
  assert.doesNotMatch(html, /Search detected violations/);
});

// ---- Matching the rest of the system ----------------------------------------------

const cssFile = (relative) =>
  fs.readFileSync(path.resolve(root, relative), "utf8");
const cssRule = (css, selector) => {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return css.match(new RegExp(`(?:^|\\n)${escaped} \\{([^}]*)\\}`))?.[1] ?? "";
};

test("A1: the selected street uses a full border, with no side stripe", () => {
  const selected = cssRule(
    cssFile("features/recommendations/components/SectionListItem.module.css"),
    ".selected",
  );
  assert.match(selected, /background: var\(--bg-surface\)/);
  assert.match(selected, /box-shadow: inset 0 0 0 1px var\(--button-primary\)/);
  assert.doesNotMatch(selected, /inset 4px/);
  // Badges keep their own status colors on the selected street.
  const css = cssFile("features/recommendations/components/SectionListItem.module.css");
  assert.doesNotMatch(css, /\.selected \.labels/);
});

test("A2: the summary and card use the same panel shape as the record pages", () => {
  for (const [file, selector] of [
    ["RunSummary.module.css", ".summary"],
    ["RecommendationCard.module.css", ".card"],
  ]) {
    const rule = cssRule(cssFile(`features/recommendations/components/${file}`), selector);
    assert.match(rule, /border-radius: var\(--radius-lg\)/, file);
    assert.doesNotMatch(rule, /box-shadow/, file);
  }
});

test("A3: the street list sits in the shared records panel", () => {
  const html = renderPage(() => openData(fishAndSeafood, dryGoodsCard), undefined, true);
  assert.match(html, /<section class="panel" aria-label="Streets"/);
  assert.ok(text(html).includes("2 need review · 0 reviewed · 0 dismissed"), text(html));
});

test("A4: error and empty messages use the shared records message", () => {
  const noRun = renderPage(
    () => ({ data: { run: null, recommendations: [], sectionsWithoutRecommendation: [] } }),
    undefined,
    true,
  );
  assert.match(noRun, /<div class="state "[^>]*role="status"/);
  const noCards = renderPage(
    () => ({ data: { run, recommendations: [], sectionsWithoutRecommendation: [] } }),
    undefined,
    true,
  );
  assert.match(noCards, /<div class="state "[^>]*role="status"/);
  const failed = renderPage(
    (errors) => ({ isError: true, error: new errors.ApiRequestError("Unavailable.", 500) }),
    undefined,
    true,
  );
  assert.match(failed, /<div class="state error"[^>]*role="alert"/);
  assert.ok(text(failed).includes("Unable to load recommended actions"), text(failed));
});

test("A5: Detected violations uses the shared breadcrumb and a short subtitle", () => {
  const html = renderDetected(detectedPage([detectedTicket]));
  assert.match(html, /<nav[^>]*aria-label="Breadcrumb"/);
  assert.match(html, /<a [^>]*href="\/recommendations"[^>]*>Recommended Actions<\/a>/);
  const words = text(html);
  assert.ok(words.includes("Records the model matched to a violation in its latest daily check."), words);
  assert.ok(words.includes("A record that is not listed may still have a violation."), words);
  assert.doesNotMatch(words, /Back to Recommended Actions/);
});

test("A6: shared buttons have steady heights, are 44 pixels on phones, and show their spinner on any color", () => {
  const css = cssFile("components/ui/Button/Button.module.css");
  assert.match(cssRule(css, ".sm"), /min-height: var\(--records-compact-control-size\)/);
  assert.match(cssRule(css, ".md"), /min-height: var\(--button-height-md\)/);
  assert.match(cssRule(css, ".lg"), /min-height: var\(--form-control-height\)/);
  assert.match(
    css,
    /@media \(max-width: 700px\) \{\s*(?:\/\*[^*]*\*\/\s*)?\.button\.button\.button \{\s*min-height: var\(--form-control-height\);/,
  );
  const spinner = cssRule(css, ".spinner");
  assert.match(spinner, /border-top-color: currentColor/);
  assert.doesNotMatch(spinner, /#fff|255, 255, 255/);
  assert.match(cssFile("styles/globals.css"), /--button-height-md: 2\.25rem;/);
});

test("A7: shared badges keep their natural size on phone tables", () => {
  const css = cssFile("components/ui/Records/RecordBadge.module.css");
  assert.match(cssRule(css, ".badge"), /justify-self: start/);
  assert.match(cssRule(css, ".info"), /color: var\(--records-info-text\)/);
});

test("H1: the bar graph is taller, rises on arrival and moves smoothly between streets", () => {
  const css = cssFile("features/recommendations/components/HourlyBars.module.css");
  const bars = cssRule(css, ".bars");
  assert.match(bars, /height: 5rem/);
  assert.match(bars, /contain: layout/);
  const bar = cssRule(css, ".bar");
  assert.match(bar, /transform-origin: bottom/);
  assert.match(bar, /animation: bar-rise 520ms cubic-bezier\(0\.16, 1, 0\.3, 1\) backwards/);
  assert.match(bar, /height 280ms cubic-bezier\(0\.16, 1, 0\.3, 1\)/);
  assert.match(bar, /background-color 200ms ease/);
  assert.match(css, /@keyframes bar-rise \{\s*from \{\s*transform: scaleY\(0\);/);
  // Six groups of four hours sweep from morning to night, 30ms apart, 150ms at most.
  for (const [start, delay] of [[5, 30], [9, 60], [13, 90], [17, 120], [21, 150]])
    assert.match(cssRule(css, `.bar:nth-child(n + ${start})`), new RegExp(`animation-delay: ${delay}ms`));
  assert.match(
    css,
    /@media \(prefers-reduced-motion: reduce\) \{\s*\.bar \{\s*animation: none;\s*transition: none;/,
  );
});

test("A7: Paid uses the same blue everywhere a status badge shows it", () => {
  const { RecordBadge } = load("components/ui/Records/RecordBadge.tsx");
  const paid = renderToStaticMarkup(React.createElement(RecordBadge, { value: "Paid" }));
  assert.match(paid, /^<span class="badge paid"/);
  const globals = cssFile("styles/globals.css");
  assert.match(globals, /--status-paid-text: #3b82f6;/);
  assert.match(globals, /--status-paid-surface: #dbeafe;/);
  for (const file of [
    "components/ui/Records/RecordBadge.module.css",
    "components/ui/StatusBadge/StatusBadge.module.css",
  ]) {
    const rule = cssRule(cssFile(file), ".paid");
    assert.match(rule, /color: var\(--status-paid-text\)/, file);
    assert.match(rule, /background(?:-color)?: var\(--status-paid-surface\)/, file);
  }
  const detail = cssFile("features/tickets/components/detail/StatusPill.module.css");
  assert.match(detail, /\.paid \{ color: #3B82F6; background-color: #DBEAFE;/);
  for (const [value, tone] of [
    ["Pending", "warning"],
    ["Cleared", "success"],
    ["Overdue", "danger"],
    ["Waived", "violet"],
  ]) {
    const html = renderToStaticMarkup(React.createElement(RecordBadge, { value }));
    assert.match(html, new RegExp(`^<span class="badge ${tone}"`), value);
  }
});

test("A8: the sidebar keeps the parent page highlighted on its inner pages", () => {
  const { isNavItemActive } = load("components/layout/Sidebar/navActive.ts");
  assert.equal(isNavItemActive("/recommendations", "/recommendations"), true);
  assert.equal(isNavItemActive("/recommendations/detected", "/recommendations"), true);
  assert.equal(isNavItemActive("/tickets/41", "/tickets"), true);
  assert.equal(isNavItemActive("/admin/vendors/3/inspections", "/admin/vendors"), true);
  assert.equal(isNavItemActive("/enforcer/performance/4", "/enforcers", ["/enforcer"]), true);
  assert.equal(isNavItemActive("/system/ordinance", "/system/configuration", ["/system", "/configuration"]), true);
  assert.equal(isNavItemActive("/configuration/backups", "/system/configuration", ["/system", "/configuration"]), true);
  assert.equal(isNavItemActive("/enforcers", "/enforcer"), false);
  assert.equal(isNavItemActive("/recommendations-old", "/recommendations"), false);
  assert.equal(isNavItemActive("/admin/reports", "/admin/vendors"), false);
  const sidebar = fs.readFileSync(path.resolve(root, "components/layout/Sidebar/Sidebar.tsx"), "utf8");
  assert.match(sidebar, /to: "\/enforcers",[\s\S]{0,120}innerPaths: \["\/enforcer"\]/);
  assert.match(sidebar, /to: "\/system\/configuration",[\s\S]{0,140}innerPaths: \["\/system", "\/configuration"\]/);
  assert.match(sidebar, /isNavItemActive\(\s*location\.pathname,\s*item\.to,\s*item\.innerPaths,?\s*\)/);
});

test("A9: the sidebar profile text is readable and its initials have enough contrast", () => {
  const css = cssFile("components/layout/Sidebar/Sidebar.module.css");
  assert.match(css, /\.userRole \{\s*overflow: hidden;[\s\S]*?font-size: var\(--market-font-size-small\);/);
  assert.doesNotMatch(css, /font-size: 0\.68rem/);
  assert.match(cssRule(css, ".userAvatar"), /background-color: var\(--records-warning-text\)/);
});

test("D6: the count is hidden before the first daily run", () => {
  const words = renderPage(() => ({
    data: { run: null, recommendations: [], sectionsWithoutRecommendation: [] },
  }));
  assert.doesNotMatch(words, /Detected violations/);
});

test("D6: the page has an admin-only route", () => {
  const routes = fs.readFileSync(path.resolve(root, "routes/AppRoutes.tsx"), "utf8");
  assert.match(
    routes,
    /path=\{ROUTES\.detectedViolations\}\s*element=\{\s*<ProtectedRoute roles=\{ADMIN_ROLES\}>\s*<DetectedViolationsPage \/>/,
  );
  const { ROUTES } = load("routes/routePaths.ts");
  assert.equal(ROUTES.detectedViolations, "/recommendations/detected");
});

test("D7: the violation filter offers all 29 violations after All violations, A to Z", () => {
  const { VIOLATION_OPTIONS } = load(
    "features/recommendations/recommendations.text.ts",
  );
  assert.equal(VIOLATION_OPTIONS.length, 30);
  assert.equal(VIOLATION_OPTIONS[0].label, "All violations");
  const labels = Array.from(VIOLATION_OPTIONS.slice(1), (option) => option.label);
  assert.deepEqual(labels, [...labels].sort((a, b) => a.localeCompare(b)));
  assert.equal(
    VIOLATION_OPTIONS.find((option) => option.value === "WeightMeasures").label,
    "Timbang at Sukat (Weights and Measures)",
  );
});

test("D7: each of the model's 29 categories has its Filipino and English name", () => {
  const { violationName } = load(
    "features/recommendations/recommendations.text.ts",
  );
  const expected = {
    "Vendor Identification": "Pagkakakilanlan ng Tindero (Vendor Identification)",
    "Permit & Licensing": "Permit at Lisensya (Permit & Licensing)",
    Sanitation: "Kalinisan (Sanitation)",
    WeightMeasures: "Timbang at Sukat (Weights and Measures)",
    "Lighting & Energy": "Ilaw at Paggamit ng Kuryente (Lighting & Energy)",
    "Stall Occupancy": "Pag-okupa sa Puwesto (Stall Occupancy)",
    "Stall Management": "Pamamahala ng Puwesto (Stall Management)",
    "Stall Construction": "Konstruksiyon ng Puwesto (Stall Construction)",
    Utilities: "Tubig at Iba Pang Serbisyo ng Pamilihan (Utilities)",
    "Stall Rental": "Upa sa Puwesto (Stall Rental)",
    "Illegal Vendor": "Di-awtorisadong Pagtitinda (Illegal Vendor)",
    "Public Order": "Kaayusan sa Publiko (Public Order)",
    Liquor: "Alak (Liquor)",
    "Market Conduct": "Asal sa Pamilihan (Market Conduct)",
    Obstruction: "Sagabal sa Daanan (Obstruction)",
    DressCode: "Kasuotan sa Pamilihan (Dress Code)",
    "Bladed Instruments": "Mga Matalim na Kagamitan (Bladed Instruments)",
    Traffic: "Trapiko sa Pamilihan (Traffic)",
    "Porter Regulation": "Regulasyon sa Kargador (Porter Regulation)",
    Promotions: "Mga Promosyon (Promotions)",
    Advertising: "Paanunsiyo (Advertising)",
    "Signage & Streamers": "Mga Karatula at Banderola (Signage & Streamers)",
    "Entertainment Activities": "Mga Gawaing Pangkaaliwan (Entertainment Activities)",
    "Lighting Facilities": "Mga Pasilidad ng Ilaw (Lighting Facilities)",
    "Market Rules": "Mga Tuntunin sa Pamilihan (Market Rules)",
    "Price Monitoring": "Pagsubaybay sa Presyo (Price Monitoring)",
    "Market Fees & Surcharges": "Mga Bayarin at Dagdag-Singil sa Pamilihan (Market Fees & Surcharges)",
    "Resisting Authority": "Pagsalungat sa Awtoridad (Resisting Authority)",
    "General Penalties": "Pangkalahatang Parusa (General Penalties)",
  };
  assert.equal(Object.keys(expected).length, 29);
  for (const [code, name] of Object.entries(expected))
    assert.equal(violationName(code), name);
  assert.equal(violationName("Not Known"), "Not Known");
});
