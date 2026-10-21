import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

const require = createRequire(import.meta.url);
const { chromium } = require(
  process.env.AUDIT_PLAYWRIGHT_MODULE || "playwright",
);
const baseUrl = process.env.AUDIT_TEST_URL || "http://127.0.0.1:5189";
const profile = {
  userId: 7,
  username: "configuration.test",
  firstName: "Test",
  lastName: "Administrator",
  role: "HeadAdmin",
  status: "Active",
  mustChangedPassword: false,
};
const records = [
  { id: 50, module: "Users", action: "EditUserInformation" },
  { id: 49, module: "Security", action: "Login" },
  {
    id: 23,
    module: "Backups",
    action: "AutomaticBackupCompleted",
    system: true,
  },
  { id: 22, module: "Ordinances", action: "Update", result: "Failed" },
  { id: 21, module: "MarketSections", action: "UpdateActiveStatus" },
  ...Array.from({ length: 9 }, (_, index) => ({
    id: 20 - index,
    module: "MarketSections",
    action: "Create",
  })),
].map(({ system, ...record }) => ({
  timestamp: "2026-10-21T01:00:00Z",
  user_id: system ? null : 7,
  first_name: system ? null : "Juan",
  last_name: system ? null : "Dela Cruz",
  role: system ? null : "HeadAdmin",
  result: "Success",
  ...record,
}));

test(
  "configuration recent changes and scoped audit history preserve audit display and request states",
  { timeout: 120000 },
  async () => {
    const browser = await chromium.launch({
      channel: "msedge",
      headless: true,
    });
    try {
      const page = await browser.newPage({
        viewport: { width: 1440, height: 1000 },
      });
      page.setDefaultTimeout(10000);
      const errors = [],
        requests = [];
      let responseMode = "normal";
      page.on("pageerror", (error) => errors.push(error.message));
      await page.route("**/*", async (route) => {
        const url = new URL(route.request().url());
        if (url.origin !== baseUrl) return route.abort();
        if (!url.pathname.startsWith("/api/")) return route.continue();
        if (url.pathname === "/api/user/me")
          return route.fulfill({ json: profile });
        if (url.pathname.endsWith("/count"))
          return route.fulfill({ json: { count: 3 } });
        if (!url.pathname.startsWith("/api/admin/audit-logs"))
          return route.fulfill({ json: {} });
        requests.push(url);
        const modules = url.searchParams.getAll("modules");
        const matches = records.filter(
          (record) => !modules.length || modules.includes(record.module),
        );
        if (url.pathname.endsWith("/counts"))
          return route.fulfill({
            json: {
              recorded_activities: matches.length,
              successful_actions: matches.filter(
                (record) => record.result === "Success",
              ).length,
              security_events: matches.filter(
                (record) => record.module === "Security",
              ).length,
            },
          });
        if (url.pathname !== "/api/admin/audit-logs") {
          const record = records.find(
            (item) => item.id === Number(url.pathname.split("/").pop()),
          );
          return route.fulfill({
            json: {
              ...record,
              target_id: null,
              details: "Synthetic audit detail.",
            },
          });
        }
        await new Promise((resolve) => setTimeout(resolve, 400));
        if (responseMode === "error")
          return route.fulfill({
            status: 500,
            json: {
              message: "Configuration history is temporarily unavailable.",
            },
          });
        if (responseMode === "fallback")
          return route.fulfill({ status: 500, json: {} });
        if (responseMode === "empty")
          return route.fulfill({
            json: { items: [], total: 0, has_more: false },
          });
        const offset = Number(url.searchParams.get("offset") || 0);
        return route.fulfill({
          json: {
            items: matches.slice(offset, offset + 10),
            total: matches.length,
            has_more: offset + 10 < matches.length,
          },
        });
      });
      await page.goto(`${baseUrl}/login`, {
        waitUntil: "domcontentloaded",
        timeout: 60000,
      });
      await page.getByRole("button", { name: "LOGIN", exact: true }).waitFor();
      async function navigate(path, role = "HeadAdmin") {
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
      await navigate("/system/configuration");
      await page
        .getByText("Loading recent changes…", { exact: true })
        .waitFor();
      const section = page.locator("section").filter({
        has: page.getByRole("heading", {
          name: "Recent Changes",
          exact: true,
        }),
      });
      await section
        .getByText("Automatic Backup Completed", { exact: true })
        .waitFor();
      const latestRequest = requests.at(-1);
      assert.deepEqual(latestRequest.searchParams.getAll("modules"), [
        "Backups",
        "MarketSections",
        "Ordinances",
      ]);
      assert.equal(latestRequest.searchParams.get("offset"), "0");
      assert.equal(latestRequest.searchParams.has("results"), false);
      assert.equal(
        await section.getByText("System", { exact: true }).count(),
        1,
      );
      assert.equal(
        await section.getByText("Juan Dela Cruz", { exact: true }).count(),
        2,
      );
      assert.equal(
        await section.getByText("Failed", { exact: true }).count(),
        1,
      );
      assert.equal(
        await section.getByText("Success", { exact: true }).count(),
        2,
      );
      assert.equal(
        await section
          .getByText("Oct 21, 2026, 9:00 AM", { exact: true })
          .count(),
        3,
      );
      assert.equal(
        await section
          .getByText("Edit User Information", { exact: true })
          .count(),
        0,
      );
      assert.equal(
        await section.getByText("Create", { exact: true }).count(),
        0,
      );
      assert.equal(
        await section
          .getByText("Update Active Status", { exact: true })
          .count(),
        1,
      );
      const labels = await section
        .locator("time")
        .evaluateAll((nodes) =>
          nodes.map((node) => node.getAttribute("dateTime")),
        );
      assert.deepEqual(labels, [
        "2026-10-21T01:00:00Z",
        "2026-10-21T01:00:00Z",
        "2026-10-21T01:00:00Z",
      ]);
      await section.screenshot({
        path: path.join(tmpdir(), "configuration-recent-changes-desktop.png"),
      });
      await page.setViewportSize({ width: 390, height: 844 });
      assert.ok(
        await section.evaluate((node) => node.scrollWidth <= node.clientWidth),
      );
      await section.screenshot({
        path: path.join(tmpdir(), "configuration-recent-changes-mobile.png"),
      });
      await section.getByRole("link", { name: "View audit log" }).click();
      const footer = page.locator(
        "section[aria-labelledby='audit-history-title'] footer p",
      );
      await footer
        .filter({ hasText: "Showing 1–10 of 12 activities" })
        .waitFor();
      assert.equal(
        await page
          .getByRole("button", { name: "Filter by module", exact: true })
          .innerText(),
        "3 modules",
      );
      const list = requests
        .filter((url) => url.pathname === "/api/admin/audit-logs")
        .at(-1);
      const counts = requests
        .filter((url) => url.pathname.endsWith("/counts"))
        .at(-1);
      assert.deepEqual(list.searchParams.getAll("modules"), [
        "Backups",
        "MarketSections",
        "Ordinances",
      ]);
      assert.deepEqual(counts.searchParams.getAll("modules"), [
        "Backups",
        "MarketSections",
        "Ordinances",
      ]);
      await page
        .getByRole("button", { name: "Export Log", exact: true })
        .waitFor({ state: "visible" });
      const downloadPending = page.waitForEvent("download");
      await page
        .getByRole("button", { name: "Export Log", exact: true })
        .click();
      const download = await downloadPending;
      const stream = await download.createReadStream();
      let csv = "";
      for await (const chunk of stream) csv += chunk.toString();
      assert.ok(csv.includes("AutomaticBackupCompleted"));
      assert.ok(csv.includes("MarketSections"));
      assert.ok(!csv.includes("EditUserInformation"));
      await page
        .getByRole("button", { name: "Clear filters", exact: true })
        .click();
      await footer
        .filter({ hasText: "Showing 1–10 of 14 activities" })
        .waitFor();
      assert.equal(new URL(page.url()).searchParams.has("modules"), false);
      await navigate("/system/configuration");
      await section
        .getByText("Automatic Backup Completed", { exact: true })
        .waitFor();
      await navigate("/admin/audit-logs");
      await footer
        .filter({ hasText: "Showing 1–10 of 14 activities" })
        .waitFor();
      for (const mode of ["empty", "error", "fallback"]) {
        responseMode = mode;
        await navigate("/system/configuration");
        const message =
          mode === "empty"
            ? "No recent configuration changes."
            : mode === "error"
              ? "Configuration history is temporarily unavailable."
              : "Unable to load recent changes. Please try again.";
        await section.getByText(message, { exact: true }).waitFor();
        assert.equal(
          await section
            .getByText("Automatic Backup Completed", { exact: true })
            .count(),
          0,
        );
        if (mode !== "empty") {
          responseMode = "normal";
          await section
            .getByRole("button", { name: "Retry", exact: true })
            .click();
          await section
            .getByText("Automatic Backup Completed", { exact: true })
            .waitFor();
        }
        await navigate("/admin/audit-logs");
        await page
          .getByRole("heading", { name: "Audit Logs", exact: true })
          .waitFor();
      }
      responseMode = "normal";
      await navigate("/system/configuration", "AdminOfficer");
      await section
        .getByText("Automatic Backup Completed", { exact: true })
        .waitFor();
      assert.equal(
        await section.getByText("System", { exact: true }).count(),
        1,
      );
      assert.deepEqual(errors, []);
    } finally {
      await browser.close();
    }
  },
);
