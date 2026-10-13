import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { join } from "node:path";
import { tmpdir } from "node:os";
import test from "node:test";

const require = createRequire(import.meta.url);
const { chromium } = require(
  process.env.REPORTS_PLAYWRIGHT_MODULE || "playwright",
);
const baseUrl = process.env.REPORTS_TEST_URL || "http://127.0.0.1:5175";
const profile = {
  userId: 7,
  username: "registry.test",
  firstName: "Test",
  lastName: "Administrator",
  role: "HeadAdmin",
  status: "Active",
  email: "test@example.com",
  profileUrl: null,
  mustChangedPassword: false,
};
const section = {
  id: 1,
  name: "Fish Section",
  description: "Fresh fish and seafood vendors",
  is_active: true,
  vendor_count: 7,
};
const ordinance = {
  id: 1,
  ordinance_no: "2026-001",
  series: "2026",
  market_code: "MM",
  title: "Market sanitation",
  description: "Keep vendor areas clean.",
  category: "Sanitation",
  created_at: "2026-10-01T00:00:00Z",
  updated_at: "2026-10-12T00:00:00Z",
  is_active: true,
  severity: "Minor",
  penalty_tier_count: 1,
};
const backup = {
  id: 1,
  date_time: "2026-10-12T01:00:00Z",
  type: "Manual",
  size: 2048,
  status: "Completed",
  completed_at: "2026-10-12T01:01:00Z",
  expires_at: null,
  error_message: null,
  can_download: true,
  download_route: "/api/admin/backups/1/download",
};
const surfaces = [
  {
    name: "sections",
    path: "/system/market-section",
    region: "Market sections table",
    endpoint: "/api/marketsection",
    headers: ["Section Name", "Description", "Vendors", "Status", "Actions"],
    empty: "No market sections configured yet.",
    loading: "Loading market sections…",
    search: "Search market sections",
    noMatch: "No sections match your search.",
  },
  {
    name: "ordinances",
    path: "/system/ordinance",
    region: "Ordinance registry table",
    endpoint: "/api/ordinance",
    headers: [
      "Ordinance",
      "Category",
      "Penalty Tiers",
      "Last Updated",
      "Status",
      "Actions",
    ],
    empty: "No ordinances configured yet.",
    loading: "Loading ordinances…",
    search: "Search ordinances by code or title",
    noMatch: "No ordinances match your search.",
  },
  {
    name: "backups",
    path: "/configuration/backups",
    region: "Backup history",
    endpoint: "/api/admin/backups",
    headers: ["Date & Time", "Type", "Size", "Status", "Actions"],
    empty: "No backups have been recorded yet.",
    loading: "Loading backup history…",
  },
];

test(
  "registry pages preserve headers, states, actions and keyboard scrolling",
  { timeout: 180000 },
  async () => {
    const browser = await chromium.launch({
      channel: "msedge",
      headless: true,
    });
    try {
      for (const surface of surfaces) {
        for (const mode of ["data", "empty", "error"]) {
          const page = await browser.newPage({
            viewport: { width: 1440, height: 1000 },
            reducedMotion: "reduce",
          });
          page.setDefaultTimeout(15000);
          const runtimeErrors = [];
          page.on("pageerror", (error) => runtimeErrors.push(error.message));
          let release;
          const ready = new Promise((resolve) => {
            release = resolve;
          });
          // Intercept every API request; no requests reach the configured remote API.
          await page.route(`${baseUrl}/api/**`, async (route) => {
            const url = new URL(route.request().url());
            if (url.pathname === surface.endpoint) {
              await ready;
              if (mode === "error")
                return route.fulfill({
                  status: 500,
                  json: { message: "Registry temporarily unavailable." },
                });
              const items =
                mode === "empty"
                  ? []
                  : [
                      surface.name === "sections"
                        ? section
                        : surface.name === "ordinances"
                          ? ordinance
                          : backup,
                    ];
              return route.fulfill({
                json:
                  surface.name === "backups"
                    ? { items, has_more: false, total: items.length }
                    : items,
              });
            }
            if (url.pathname === "/api/ordinance/1")
              return route.fulfill({
                json: {
                  ...ordinance,
                  penalty_tiers: [
                    {
                      id: 1,
                      offense_number: 1,
                      severity: "Minor",
                      penalty_amount: 100,
                    },
                  ],
                },
              });
            if (url.pathname.endsWith("/download"))
              return route.fulfill({
                contentType: "application/octet-stream",
                body: "test backup",
                headers: {
                  "Content-Disposition": 'attachment; filename="backup-1.enc"',
                },
              });
            if (url.pathname.endsWith("/schedule"))
              return route.fulfill({
                json: {
                  enabled: true,
                  frequency: "Daily",
                  day_of_week: null,
                  time: "02:00",
                  retention_days: 30,
                  time_zone: "Asia/Manila",
                  time_zone_display: "Philippine Standard Time",
                },
              });
            if (url.pathname.endsWith("/health"))
              return route.fulfill({
                json: {
                  latest_attempt: backup,
                  latest_successful_backup: backup,
                  is_running: false,
                  enabled: true,
                  retention_days: 30,
                  next_scheduled_at: null,
                  time_zone: "Asia/Manila",
                  time_zone_display: "Philippine Standard Time",
                },
              });
            return route.fulfill({
              json: url.pathname.endsWith("/user/me") ? profile : {},
            });
          });
          try {
            await page.goto(`${baseUrl}/login`);
            await page
              .getByRole("button", { name: "LOGIN", exact: true })
              .waitFor();
            await page.evaluate(
              async ({ user, path }) => {
                const { useAuthStore } = await import("/src/store/store.ts");
                useAuthStore
                  .getState()
                  .setAuth(
                    user,
                    `test.${btoa(JSON.stringify({ exp: Math.floor(Date.now() / 1000) + 3600 }))}.test`,
                  );
                history.pushState({}, "", path);
                dispatchEvent(new PopStateEvent("popstate"));
              },
              { user: profile, path: surface.path },
            );
            const region = page.getByRole("region", {
              name: surface.region,
              exact: true,
            });
            await region.getByText(surface.loading, { exact: true }).waitFor();
            assert.deepEqual(
              await region.getByRole("columnheader").allTextContents(),
              surface.headers,
            );
            release();
            if (mode === "error") {
              await page
                .getByText("Registry temporarily unavailable.", { exact: true })
                .waitFor();
              assert.equal(
                await page
                  .getByRole("button", { name: "Try again", exact: true })
                  .count(),
                1,
              );
            } else if (mode === "empty") {
              await region.getByText(surface.empty, { exact: true }).waitFor();
              assert.equal(
                await region.locator("tbody td").getAttribute("colspan"),
                String(surface.headers.length),
              );
            } else {
              await region.getByRole("button").first().waitFor();
              assert.equal(await region.locator("tbody tr").count(), 1);
              const alignment = await region
                .getByRole("table")
                .evaluate((table) => {
                  const headers = [...table.querySelectorAll("thead th")];
                  const cells = [
                    ...table.querySelectorAll(
                      "tbody tr:first-child > :is(th,td)",
                    ),
                  ];
                  return headers.map((header, index) => {
                    const heading = getComputedStyle(header),
                      cell = getComputedStyle(cells[index]);
                    return {
                      heading: heading.textAlign,
                      cell: cell.textAlign,
                      headingPadding: [
                        heading.paddingLeft,
                        heading.paddingRight,
                      ],
                      cellPadding: [cell.paddingLeft, cell.paddingRight],
                    };
                  });
                });
              for (const column of alignment) {
                assert.equal(column.heading, column.cell);
                assert.deepEqual(column.headingPadding, column.cellPadding);
              }
              const expectedAlignment =
                surface.name === "sections"
                  ? ["left", "left", "center", "center", "center"]
                  : surface.name === "ordinances"
                    ? ["left", "left", "center", "left", "center", "center"]
                    : ["left", "center", "center", "left", "right"];
              assert.deepEqual(
                alignment.map((column) => column.heading),
                expectedAlignment,
              );
              if (surface.name === "backups") {
                const actionOffset = await region
                  .locator("tbody td:last-child")
                  .evaluate((cell) => {
                    const actions =
                        cell.firstElementChild.getBoundingClientRect(),
                      bounds = cell.getBoundingClientRect();
                    return Math.abs(
                      bounds.right -
                        parseFloat(getComputedStyle(cell).paddingRight) -
                        actions.right,
                    );
                  });
                assert.ok(
                  actionOffset < 1,
                  "Backup actions must align with the right edge of their column",
                );
              }
              if (surface.name === "sections")
                assert.equal(alignment.at(-1).heading, "center");
              assert.equal(
                await region.locator("tbody tr > :is(th,td)").count(),
                surface.headers.length,
              );
              await page.screenshot({
                path: join(tmpdir(), `registry-${surface.name}-desktop.png`),
                fullPage: true,
                animations: "disabled",
              });
              await page.setViewportSize({ width: 390, height: 844 });
              await region.focus();
              await page.keyboard.press("ArrowRight");
              await page.waitForFunction(
                (label) =>
                  document.querySelector(`[aria-label="${label}"]`)
                    ?.scrollLeft > 0,
                surface.region,
              );
              assert.equal(
                await page.evaluate(
                  () => document.documentElement.scrollWidth > innerWidth,
                ),
                false,
                JSON.stringify(
                  await page.evaluate(() =>
                    [...document.querySelectorAll("main *")]
                      .filter(
                        (element) =>
                          !element.closest('[role="region"]') &&
                          element.getBoundingClientRect().right > innerWidth,
                      )
                      .map((element) => ({
                        tag: element.tagName,
                        className: element.className,
                        width: element.getBoundingClientRect().width,
                        right: element.getBoundingClientRect().right,
                      })),
                  ),
                ),
              );
              await region.evaluate((element) => {
                element.scrollTo({ left: 0, behavior: "instant" });
              });
              await page.evaluate(() =>
                scrollTo({ top: 0, behavior: "instant" }),
              );
              await page.screenshot({
                path: join(tmpdir(), `registry-${surface.name}-mobile.png`),
                fullPage: true,
                animations: "disabled",
              });
              await page.setViewportSize({ width: 1440, height: 1000 });
              if (surface.search) {
                await page
                  .getByRole("searchbox", { name: surface.search, exact: true })
                  .fill("no-matching-record");
                await region
                  .getByText(surface.noMatch, { exact: true })
                  .waitFor();
                await page
                  .getByRole("searchbox", { name: surface.search, exact: true })
                  .fill("");
                await region.getByRole("button").first().click();
                await page.getByRole("dialog").waitFor();
              } else {
                assert.equal(
                  await region
                    .getByRole("button", { name: "Restore", exact: true })
                    .isDisabled(),
                  true,
                );
                const download = page.waitForEvent("download");
                await region
                  .getByRole("button", {
                    name: "Download backup 1",
                    exact: true,
                  })
                  .click();
                assert.equal(
                  (await download).suggestedFilename(),
                  "backup-1.enc",
                );
              }
            }
            assert.deepEqual(runtimeErrors, []);
          } finally {
            release();
            await page.close();
          }
        }
      }
    } finally {
      await browser.close();
    }
  },
);
