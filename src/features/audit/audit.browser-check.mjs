import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { createRequire } from "node:module";
import test from "node:test";

const require = createRequire(import.meta.url);
const { chromium } = require(
  process.env.AUDIT_PLAYWRIGHT_MODULE || "playwright",
);
const baseUrl = process.env.AUDIT_TEST_URL || "http://localhost:5174";
const profile = {
  userId: 7,
  username: "audit.test",
  firstName: "Test",
  middleName: null,
  lastName: "Administrator",
  dateOfBirth: "1995-05-20",
  email: "test@example.com",
  phoneNumber: "09171234567",
  houseNumber: "12",
  street: "Test Street",
  barangay: "Test",
  city: "Marikina",
  status: "Active",
  role: "HeadAdmin",
  createdAt: "2026-10-01T00:00:00Z",
  profileUrl: null,
  mustChangedPassword: false,
};
const modules = [
  "Users",
  "Vendors",
  "Tickets",
  "Ordinances",
  "MarketSections",
  "Security",
  "Reports",
  "Backups",
  "Notifications",
  "AuditLogs",
];
const now = Date.parse("2026-10-10T12:00:00Z");
const records = Array.from({ length: 24 }, (_, index) => ({
  id: 124 - index,
  timestamp: new Date(now - index * 6 * 3600000).toISOString(),
  user_id: index % 5 === 0 ? null : 7,
  first_name: index % 5 === 0 ? null : "Juan",
  last_name: index % 5 === 0 ? null : "Dela Cruz",
  role: index % 5 === 0 ? null : "HeadAdmin",
  action: index % 3 === 0 ? "ChangePassword" : "EditUserInformation",
  module: modules[index % modules.length],
  result: index % 4 === 0 || index === 5 ? "Failed" : "Success",
  target_id: `record-${index}`,
  details:
    index % 3 === 0
      ? "Password update completed successfully."
      : "Profile update completed successfully.",
}));

function matches(query) {
  const selectedModules = query.getAll("modules"),
    selectedResults = query.getAll("results"),
    search = (query.get("search") || "").toLowerCase();
  const day = query.get("dateRange") || "AllTime";
  const ranges = {
    Today: ["2026-10-10", "2026-10-10"],
    Yesterday: ["2026-10-09", "2026-10-09"],
    Last7Days: ["2026-10-04", "2026-10-10"],
    Last30Days: ["2026-09-11", "2026-10-10"],
    ThisMonth: ["2026-10-01", "2026-10-10"],
    LastMonth: ["2026-09-01", "2026-09-30"],
  };
  return records.filter((record) => {
    const date = new Date(Date.parse(record.timestamp) + 8 * 3600000)
      .toISOString()
      .slice(0, 10);
    return (
      (!selectedModules.length || selectedModules.includes(record.module)) &&
      (!selectedResults.length || selectedResults.includes(record.result)) &&
      (!ranges[day] || (date >= ranges[day][0] && date <= ranges[day][1])) &&
      (!search ||
        [record.action, record.details, record.target_id].some((value) =>
          value.toLowerCase().includes(search),
        ))
    );
  });
}

test(
  "live audit requests, matching counts, offset resets, multi-select, paging, details, export, errors, and responsive access",
  { timeout: 180000 },
  async () => {
    const browser = await chromium.launch({
      channel: "msedge",
      headless: true,
    });
    try {
      const page = await browser.newPage({
        viewport: { width: 1440, height: 1000 },
        acceptDownloads: true,
      });
      const runtimeErrors = [],
        requests = [];
      let listFailure = null,
        countsFailure = false,
        countsDelay = 40,
        missingDetail = false,
        malformedList = false,
        listDelay = 40,
        firstList = true;
      page.on("pageerror", (error) => runtimeErrors.push(error.message));
      await page.route(`${baseUrl}/api/**`, async (route) => {
        const request = route.request(),
          url = new URL(request.url());
        if (!url.pathname.startsWith("/api/admin/audit-logs"))
          return route.fulfill({
            json: url.pathname.endsWith("/user/me") ? profile : {},
          });
        assert.equal(request.method(), "GET");
        assert.equal(request.postData(), null);
        assert.ok(request.headers().authorization?.startsWith("Bearer "));
        for (const key of [
          "date_range",
          "user_id",
          "module",
          "result",
          "fromDate",
          "toDate",
        ])
          assert.equal(url.searchParams.has(key), false);
        requests.push(url);
        const data = matches(url.searchParams);
        if (url.pathname.endsWith("/counts")) {
          assert.equal(url.searchParams.has("offset"), false);
          await new Promise((resolve) => setTimeout(resolve, countsDelay));
          return route.fulfill(
            countsFailure
              ? { status: 500, json: {} }
              : {
                  json: {
                    recorded_activities: data.length,
                    successful_actions: data.filter(
                      (record) => record.result === "Success",
                    ).length,
                    security_events: data.filter(
                      (record) => record.module === "Security",
                    ).length,
                  },
                },
          );
        }
        if (url.pathname === "/api/admin/audit-logs") {
          const offset = Number(url.searchParams.get("offset"));
          assert.ok(offset >= 0 && offset % 10 === 0);
          const delay = firstList ? 800 : listDelay;
          firstList = false;
          await new Promise((resolve) => setTimeout(resolve, delay));
          if (listFailure)
            return route.fulfill({
              status: listFailure.status,
              json: { message: listFailure.message },
            });
          if (malformedList)
            return route.fulfill({
              json: { items: [], total: 1, has_more: true },
            });
          const items = data
            .slice(offset, offset + 10)
            .map(({ target_id, details, ...summary }) => summary);
          return route.fulfill({
            json: {
              items,
              total: data.length,
              has_more: offset + items.length < data.length,
            },
          });
        }
        const record = records.find(
          (record) => record.id === Number(url.pathname.split("/").pop()),
        );
        return route.fulfill(
          missingDetail || !record
            ? { status: 404, json: { message: "Audit log not found." } }
            : { json: record },
        );
      });
      await page.goto(`${baseUrl}/login`);
      await page.getByRole("button", { name: "LOGIN", exact: true }).waitFor();
      async function navigateAs(role) {
        await page.evaluate(
          async (user) => {
            const { useAuthStore } = await import("/src/store/store.ts");
            useAuthStore
              .getState()
              .setAuth(
                user,
                `test.${btoa(JSON.stringify({ exp: Math.floor(Date.now() / 1000) + 3600 }))}.test`,
              );
            history.pushState({}, "", "/admin/audit-logs");
            dispatchEvent(new PopStateEvent("popstate"));
          },
          { ...profile, role },
        );
      }
      const footer = () =>
        page.locator("section[aria-labelledby='audit-history-title'] footer p");
      async function settled(total, from = 1, to = Math.min(10, total)) {
        await footer()
          .filter({
            hasText: `Showing ${total ? from : 0}–${total ? to : 0} of ${total} activities`,
          })
          .waitFor();
        await page.waitForFunction(() => {
          const overview = document.querySelector(
            '[aria-label="Audit activity counts"]',
          );
          if (overview?.getAttribute("aria-busy") !== "false") return false;
          return [...overview.children].slice(0, 3).every((card) => {
            const value = card.querySelector("span")?.textContent?.trim();
            return value !== undefined && /^\d+$/.test(value);
          });
        });
      }
      async function assertCountsMatch() {
        const list = requests
            .filter((url) => url.pathname === "/api/admin/audit-logs")
            .at(-1),
          counts = requests
            .filter((url) => url.pathname.endsWith("/counts"))
            .at(-1);
        const listFilters = new URLSearchParams(list.search);
        listFilters.delete("offset");
        assert.equal(listFilters.toString(), counts.searchParams.toString());
        const data = matches(list.searchParams),
          values = [
            data.length,
            data.filter((record) => record.result === "Success").length,
            data.filter((record) => record.module === "Security").length,
          ];
        const cards = page
          .getByRole("region", { name: "Audit activity counts" })
          .locator(":scope > div");
        for (let index = 0; index < 3; index++)
          assert.equal(
            Number(
              await cards.nth(index).locator("span").first().textContent(),
            ),
            values[index],
          );
        return data.length;
      }
      async function moduleCheck(name) {
        await page
          .getByRole("button", { name: "Filter by module", exact: true })
          .click();
        await page.getByRole("checkbox", { name, exact: true }).check();
        await page.keyboard.press("Escape");
      }
      async function resultCheck(name) {
        await page
          .getByRole("button", { name: "Filter by result", exact: true })
          .click();
        await page.getByRole("checkbox", { name, exact: true }).check();
        await page.keyboard.press("Escape");
      }
      async function dateCheck(name) {
        await page
          .getByRole("button", { name: "Filter by date range", exact: true })
          .click();
        await page
          .getByRole("option", { name, exact: true })
          .getByRole("button")
          .click();
      }

      countsDelay = 900;
      await navigateAs("HeadAdmin");
      const skeletonCards = page.locator("[data-audit-skeleton]");
      await skeletonCards.first().waitFor();
      assert.equal(await skeletonCards.count(), 3);
      assert.equal(
        await page
          .getByRole("region", { name: "Audit activity counts" })
          .getAttribute("aria-busy"),
        "true",
      );
      const skeletonHeights = await skeletonCards.evaluateAll((cards) =>
        cards.map((card) => Math.round(card.getBoundingClientRect().height)),
      );
      assert.ok(skeletonHeights.every((height) => height >= 116));
      await page.emulateMedia({ reducedMotion: "reduce" });
      assert.equal(
        await skeletonCards
          .first()
          .locator("span")
          .first()
          .evaluate((element) => getComputedStyle(element).animationName),
        "none",
      );
      await page.emulateMedia({ reducedMotion: "no-preference" });
      countsDelay = 40;
      await page
        .locator("tbody")
        .getByText("Loading activities…", { exact: true })
        .waitFor();
      await settled(24);
      await assertCountsMatch();
      await page
        .locator("tbody")
        .getByText("Juan Dela Cruz", { exact: true })
        .first()
        .waitFor();
      await page
        .locator("tbody")
        .getByText("System", { exact: true })
        .first()
        .waitFor();
      await page
        .getByRole("button", { name: "View audit log 124", exact: true })
        .click();
      await page
        .getByRole("dialog")
        .getByText("System", { exact: true })
        .waitFor();
      await page.keyboard.press("Escape");
      await page
        .getByRole("button", { name: "View audit log 123", exact: true })
        .click();
      await page
        .getByRole("dialog")
        .getByText("Juan Dela Cruz", { exact: true })
        .waitFor();
      await page.keyboard.press("Escape");
      assert.equal(await page.locator("tbody tr").count(), 10);
      assert.equal(
        await page
          .getByRole("button", { name: "Filter by date range", exact: true })
          .textContent(),
        "All time",
      );
      await page
        .getByRole("button", { name: "Next page", exact: true })
        .click();
      await settled(24, 11, 20);
      await assertCountsMatch();
      await page
        .getByRole("button", { name: "Next page", exact: true })
        .click();
      await settled(24, 21, 24);
      await assertCountsMatch();
      assert.equal(
        await page
          .getByRole("button", { name: "Next page", exact: true })
          .isDisabled(),
        true,
      );
      await page
        .getByRole("button", { name: "Previous page", exact: true })
        .click();
      await settled(24, 11, 20);
      assert.equal(
        requests
          .filter((url) => url.pathname === "/api/admin/audit-logs")
          .at(-1)
          .searchParams.get("offset"),
        "10",
      );
      await moduleCheck("Users");
      await settled(3);
      await assertCountsMatch();
      assert.equal(
        requests
          .filter((url) => url.pathname === "/api/admin/audit-logs")
          .at(-1)
          .searchParams.get("offset"),
        "0",
      );
      await moduleCheck("Security");
      await settled(5);
      await assertCountsMatch();
      assert.deepEqual(
        requests
          .filter((url) => url.pathname === "/api/admin/audit-logs")
          .at(-1)
          .searchParams.getAll("modules"),
        ["Security", "Users"],
      );
      await resultCheck("Failed");
      await settled(3);
      await assertCountsMatch();
      await resultCheck("Success");
      await settled(5);
      await assertCountsMatch();
      assert.deepEqual(
        requests
          .filter((url) => url.pathname === "/api/admin/audit-logs")
          .at(-1)
          .searchParams.getAll("results"),
        ["Failed", "Success"],
      );
      await page
        .getByRole("button", { name: "Filter by module", exact: true })
        .click();
      await page
        .getByRole("checkbox", { name: "All modules", exact: true })
        .check();
      await page.keyboard.press("Escape");
      await settled(24);
      await assertCountsMatch();
      assert.equal(
        requests
          .filter((url) => url.pathname === "/api/admin/audit-logs")
          .at(-1)
          .searchParams.has("modules"),
        false,
      );
      await page
        .getByRole("button", { name: "Filter by result", exact: true })
        .click();
      await page
        .getByRole("checkbox", { name: "All results", exact: true })
        .check();
      await page.keyboard.press("Escape");
      await settled(24);
      await assertCountsMatch();
      assert.equal(
        requests
          .filter((url) => url.pathname === "/api/admin/audit-logs")
          .at(-1)
          .searchParams.has("results"),
        false,
      );
      await page
        .getByRole("button", { name: "Next page", exact: true })
        .click();
      await settled(24, 11, 20);
      await page
        .getByRole("searchbox", { name: "Search audit logs" })
        .fill("Password");
      await settled(8);
      await assertCountsMatch();
      assert.equal(
        requests
          .filter((url) => url.pathname === "/api/admin/audit-logs")
          .at(-1)
          .searchParams.get("offset"),
        "0",
      );
      await page
        .getByRole("searchbox", { name: "Search audit logs" })
        .fill("record-23");
      await settled(1);
      await assertCountsMatch();
      await page
        .getByRole("button", { name: "View audit log 101", exact: true })
        .click();
      await page
        .getByRole("dialog")
        .getByText("Profile update completed successfully.", { exact: true })
        .waitFor();
      await page.keyboard.press("Escape");
      missingDetail = true;
      await page
        .getByRole("button", { name: "View audit log 101", exact: true })
        .click();
      await page
        .getByRole("dialog")
        .getByText("Audit log not found.", { exact: true })
        .waitFor();
      missingDetail = false;
      await page
        .getByRole("dialog")
        .getByRole("button", { name: "Try again", exact: true })
        .click();
      await page
        .getByRole("dialog")
        .getByText("Profile update completed successfully.", { exact: true })
        .waitFor();
      await page.keyboard.press("Escape");
      await page
        .getByRole("button", { name: "Clear filters", exact: true })
        .click();
      await settled(24);
      for (const [value, label] of [
        ["Today", "Today"],
        ["Yesterday", "Yesterday"],
        ["Last7Days", "Last 7 days"],
        ["Last30Days", "Last 30 days"],
        ["ThisMonth", "This month"],
        ["LastMonth", "Last month"],
        ["AllTime", "All time"],
      ]) {
        await dateCheck(label);
        const query = new URLSearchParams(
          value === "AllTime" ? "" : `dateRange=${value}`,
        );
        await settled(matches(query).length);
        await assertCountsMatch();
        assert.equal(
          requests
            .filter((url) => url.pathname === "/api/admin/audit-logs")
            .at(-1)
            .searchParams.get("offset"),
          "0",
        );
      }
      listFailure = {
        status: 400,
        message:
          "Date range presets cannot be combined with fromDate or toDate.",
      };
      await dateCheck("Yesterday");
      await page
        .getByRole("alert")
        .filter({ hasText: listFailure.message })
        .waitFor();
      listFailure = null;
      await page
        .getByRole("alert")
        .getByRole("button", { name: "Try again", exact: true })
        .click();
      await settled(matches(new URLSearchParams("dateRange=Yesterday")).length);
      countsFailure = true;
      await dateCheck("Today");
      await page
        .getByRole("alert")
        .filter({ hasText: "Unable to load audit counts. Please try again." })
        .waitFor();
      countsFailure = false;
      await page
        .getByRole("alert")
        .getByRole("button", { name: "Try again", exact: true })
        .click();
      await settled(4);
      await assertCountsMatch();
      malformedList = true;
      await dateCheck("Yesterday");
      await page
        .getByRole("alert")
        .filter({ hasText: "Unable to load audit logs. Please try again." })
        .waitFor();
      malformedList = false;
      await page
        .getByRole("button", { name: "Clear filters", exact: true })
        .click();
      await settled(24);
      await assertCountsMatch();
      listDelay = 180;
      const exportStart = requests.length,
        downloadPromise = page.waitForEvent("download");
      await page
        .getByRole("button", { name: "Export Log", exact: true })
        .click();
      assert.equal(
        await page
          .getByRole("searchbox", { name: "Search audit logs" })
          .isDisabled(),
        true,
      );
      const download = await downloadPromise;
      assert.equal(download.suggestedFilename(), "audit-logs.csv");
      const csv = await readFile(await download.path(), "utf8");
      assert.equal(csv.split("\r\n").length, 25);
      assert.ok(csv.includes('"First name","Last name"'));
      assert.ok(csv.includes('"Juan","Dela Cruz"'));
      assert.deepEqual(
        requests
          .slice(exportStart)
          .filter((url) => url.pathname === "/api/admin/audit-logs")
          .map((url) => Number(url.searchParams.get("offset"))),
        [0, 10, 20],
      );
      await page
        .getByRole("button", { name: "Dismiss notification", exact: true })
        .click();
      listDelay = 40;
      await page.screenshot({
        path: "design-references/audit-log-desktop-check.png",
        fullPage: true,
      });
      await page.setViewportSize({ width: 390, height: 844 });
      await page
        .locator("aside")
        .first()
        .evaluate(async (element) => {
          getComputedStyle(element).transform;
          await Promise.all(
            element
              .getAnimations()
              .map((animation) => animation.finished.catch(() => {})),
          );
        });
      await page.screenshot({
        path: "design-references/audit-log-mobile-check.png",
        fullPage: true,
      });
      assert.equal(
        await page.evaluate(() => document.documentElement.scrollWidth),
        390,
      );
      await moduleCheck("Reports");
      await settled(2);
      await assertCountsMatch();
      await navigateAs("MarketEnforcer");
      await page.waitForURL("**/dashboard");
      await navigateAs("AdminOfficer");
      await settled(24);
      await assertCountsMatch();
      assert.deepEqual(runtimeErrors, []);
      console.log(
        "Verified GET/no-body/authentication, repeated filters, matching counts, offset resets, pagination, search, all presets, details/404, server errors, all-page export, mobile fit, and allowed roles.",
      );
    } finally {
      await browser.close();
    }
  },
);
