import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
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
  username: "reports.test",
  firstName: "Test",
  lastName: "Administrator",
  role: "HeadAdmin",
  status: "Active",
  email: "test@example.com",
  profileUrl: null,
  mustChangedPassword: false,
};
const metric = (total_records, assessed_penalties) => ({
  total_records,
  assessed_penalties,
});
function summary(type) {
  const warnings = {
    total: metric(3, 0),
    resolved: metric(3, 0),
    pending: metric(0, 0),
  };
  const tickets = {
    total: metric(4, 1200),
    resolved: metric(2, 700),
    pending: metric(2, 500),
  };
  const base =
    type === "Warning"
      ? warnings
      : type === "Ticket"
        ? tickets
        : {
            total: metric(7, 1200),
            resolved: metric(5, 700),
            pending: metric(2, 500),
          };
  return {
    ...base,
    warnings_issued: type === "Ticket" ? null : warnings,
    tickets_issued: type === "Warning" ? null : tickets,
  };
}
const saved = (
  id,
  type = "Warning & Ticket",
  from = "2026-10-01",
  to = "2026-10-12",
) => ({
  id,
  type,
  date_range: { from, to },
  date_generated: "2026-10-12T01:00:00Z",
  generated_by: {
    id: 7,
    name: id === 12 ? "Search Beyond First Page" : "Juan Dela Cruz",
  },
  summary: summary(type),
});

test(
  "reports generation, preview, saved details, paging, search, exports, failures, roles and responsive layout",
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
      page.setDefaultTimeout(12000);
      const runtimeErrors = [],
        requests = [];
      let records = Array.from({ length: 12 }, (_, i) =>
        saved(i + 1, ["Warning & Ticket", "Warning", "Ticket"][i % 3]),
      );
      let missingDetail = false,
        generationFailure = false,
        malformedPreview = false,
        historyFailure = false;
      page.on("pageerror", (error) => runtimeErrors.push(error.message));
      // All API traffic stays at this boundary; no requests reach the configured remote API.
      await page.route(`${baseUrl}/api/**`, async (route) => {
        const request = route.request(),
          url = new URL(request.url());
        if (!url.pathname.startsWith("/api/admin/reports"))
          return route.fulfill({
            json: url.pathname.endsWith("/user/me") ? profile : {},
          });
        assert.ok(request.headers().authorization?.startsWith("Bearer "));
        requests.push({
          method: request.method(),
          path: url.pathname,
          params: url.searchParams,
          body: request.postDataJSON(),
        });
        if (request.method() === "POST") {
          if (generationFailure)
            return route.fulfill({
              status: 400,
              json: { message: "This reporting period is unavailable." },
            });
          const { from, to, type } = request.postDataJSON();
          const report = saved(100 + records.length, type, from, to);
          records.unshift(report);
          await new Promise((resolve) => setTimeout(resolve, 100));
          return route.fulfill({ json: report });
        }
        if (url.pathname.endsWith("/preview")) {
          const type = url.searchParams.get("type"),
            date = url.searchParams.get("date");
          return route.fulfill({
            json: malformedPreview
              ? { type, date_range: { from: date, to: date }, summary: null }
              : {
                  type,
                  date_range: { from: date, to: date },
                  summary: summary(type),
                },
          });
        }
        if (url.pathname === "/api/admin/reports") {
          if (historyFailure)
            return route.fulfill({
              status: 500,
              json: { message: "Report history is temporarily unavailable." },
            });
          const offset = Number(url.searchParams.get("offset"));
          assert.ok(offset >= 0 && offset % 10 === 0);
          return route.fulfill({
            json: {
              items: records
                .slice(offset, offset + 10)
                .map(({ summary, ...item }) => item),
              total: records.length,
              has_more: offset + 10 < records.length,
            },
          });
        }
        const record = records.find(
          (item) => item.id === Number(url.pathname.split("/").pop()),
        );
        return route.fulfill(
          missingDetail || !record
            ? { status: 404, json: { message: "Report not found." } }
            : { json: record },
        );
      });
      await page.goto(`${baseUrl}/login`);
      await page.getByRole("button", { name: "LOGIN", exact: true }).waitFor();
      async function navigateAs(role, path = "/admin/reports") {
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
          { user: { ...profile, role }, path },
        );
      }
      await navigateAs("HeadAdmin");
      const history = page.getByRole("region", {
        name: "Generated reports",
        exact: true,
      });
      const preview = page.getByRole("region", {
        name: "Report Preview",
        exact: true,
      });
      await history
        .getByRole("button", { name: "View report 1", exact: true })
        .waitFor();
      assert.equal(
        await page
          .getByRole("button", { name: "Download PDF", exact: true })
          .isDisabled(),
        true,
      );
      await page.screenshot({
        path: join(tmpdir(), "reports-desktop-before.png"),
        fullPage: true,
      });
      await page
        .getByRole("button", { name: "Generate Report", exact: true })
        .click();
      await page
        .getByText("Choose a valid From and To date.", { exact: true })
        .waitFor();
      assert.equal(
        requests.filter((request) => request.method === "POST").length,
        0,
      );
      await page.getByLabel("From", { exact: true }).fill("2026-10-01");
      await preview
        .getByRole("article", { name: "Unsaved report preview" })
        .waitFor();
      assert.equal(
        requests.filter((request) => request.method === "POST").length,
        0,
      );
      await page.getByLabel("To", { exact: true }).fill("2026-10-12");
      await page
        .getByRole("button", { name: "Generate Report", exact: true })
        .click();
      await preview
        .getByRole("article", { name: "Saved report 112" })
        .waitFor();
      assert.deepEqual(
        requests.find((request) => request.method === "POST").body,
        { from: "2026-10-01", to: "2026-10-12", type: "Warning & Ticket" },
      );
      assert.equal(await preview.locator("tbody tr").count(), 9);
      const total = preview.getByRole("row", { name: /^Total / });
      assert.match(await total.innerText(), /7/);
      assert.match(await total.innerText(), /1,200.00/);
      await history
        .getByRole("button", { name: "View report 112", exact: true })
        .waitFor();
      await page.evaluate(() => scrollTo(0, 0));
      await page.screenshot({
        path: join(tmpdir(), "reports-desktop-after.png"),
        fullPage: true,
      });
      const csvDownload = page.waitForEvent("download");
      await page
        .getByRole("button", { name: "Export CSV", exact: true })
        .click();
      const csv = await csvDownload;
      assert.match(csv.suggestedFilename(), /Report-112.*\.csv$/);
      assert.match(
        await readFile(await csv.path(), "utf8"),
        /"Total","7","1200"/,
      );
      const pdfDownload = page.waitForEvent("download");
      await page
        .getByRole("button", { name: "Download PDF", exact: true })
        .click();
      const pdf = await pdfDownload;
      assert.match(pdf.suggestedFilename(), /Report-112.*\.pdf$/);
      assert.equal(
        (await readFile(await pdf.path())).subarray(0, 4).toString(),
        "%PDF",
      );
      await history
        .getByRole("button", { name: "Go to page 2", exact: true })
        .click();
      await history
        .getByRole("button", { name: "View report 12", exact: true })
        .waitFor();
      await history
        .getByRole("button", { name: "View report 12", exact: true })
        .click();
      await preview.getByRole("article", { name: "Saved report 12" }).waitFor();
      assert.equal(await preview.locator("tbody tr").count(), 6);
      await page
        .getByRole("searchbox", { name: "Search reports" })
        .fill("Search Beyond");
      await history
        .getByRole("button", { name: "View report 12", exact: true })
        .waitFor();
      assert.equal(await history.locator("tbody tr").count(), 1);
      await page
        .getByRole("searchbox", { name: "Search reports" })
        .fill("nothing-matches");
      await history.getByText("No matching reports", { exact: true }).waitFor();
      await page.getByRole("searchbox", { name: "Search reports" }).fill("");
      await history
        .getByRole("button", { name: "View report 1", exact: true })
        .waitFor();
      await page
        .getByRole("combobox", { name: "Filter report type", exact: true })
        .selectOption("Warning");
      await history
        .getByRole("button", { name: "View report 2", exact: true })
        .waitFor();
      assert.equal(await history.locator("tbody tr").count(), 4);
      await page
        .getByRole("combobox", { name: "Filter report type", exact: true })
        .selectOption("all");
      await history
        .getByRole("button", { name: "View report 1", exact: true })
        .waitFor();
      missingDetail = true;
      await history
        .getByRole("button", { name: "View report 1", exact: true })
        .click();
      await preview.getByText("Report not found.", { exact: true }).waitFor();
      missingDetail = false;
      await preview
        .getByRole("button", { name: "Try again", exact: true })
        .click();
      await preview.getByRole("article", { name: "Saved report 1" }).waitFor();
      generationFailure = true;
      await page
        .getByRole("button", { name: "Generate Report", exact: true })
        .click();
      await page
        .getByText("This reporting period is unavailable.", { exact: true })
        .waitFor();
      generationFailure = false;
      malformedPreview = true;
      await page.getByLabel("From", { exact: true }).fill("2026-10-02");
      await page.getByLabel("To", { exact: true }).fill("2026-10-02");
      await preview
        .getByText("Unable to load this report. Please try again.", {
          exact: true,
        })
        .waitFor();
      malformedPreview = false;
      await preview
        .getByRole("button", { name: "Try again", exact: true })
        .click();
      await preview
        .getByRole("article", { name: "Unsaved report preview" })
        .waitFor();
      await page.setViewportSize({ width: 390, height: 844 });
      await page.evaluate(() => scrollTo(0, 0));
      assert.equal(
        await page.evaluate(
          () => document.documentElement.scrollWidth > innerWidth,
        ),
        false,
      );
      await page.screenshot({
        path: join(tmpdir(), "reports-mobile.png"),
        fullPage: true,
      });
      await page.emulateMedia({ reducedMotion: "reduce" });
      assert.equal(
        await preview
          .getByRole("article")
          .evaluate((element) => getComputedStyle(element).animationName),
        "none",
      );
      await navigateAs("AdminOfficer");
      await page
        .getByRole("heading", { name: "Reports", exact: true })
        .waitFor();
      await navigateAs("MarketEnforcer", "/inspections");
      await page.waitForURL(`${baseUrl}/inspections`);
      assert.equal(
        await page.getByRole("link", { name: "Reports", exact: true }).count(),
        0,
      );
      await navigateAs("HeadAdmin");
      historyFailure = true;
      await page
        .getByRole("button", { name: "Go to page 2", exact: true })
        .click();
      await history
        .getByText("Report history is temporarily unavailable.", {
          exact: true,
        })
        .waitFor();
      historyFailure = false;
      await history
        .getByRole("button", { name: "Try again", exact: true })
        .click();
      await history
        .getByRole("button", { name: "View report 12", exact: true })
        .waitFor();
      assert.deepEqual(runtimeErrors, []);
    } finally {
      await browser.close();
    }
  },
);
