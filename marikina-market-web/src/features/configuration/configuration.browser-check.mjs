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

test(
  "configuration stat cards show real counts and the real last successful backup",
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
        healthRequests = [];
      let healthMode = "success";
      page.on("pageerror", (error) => errors.push(error.message));
      await page.route("**/*", async (route) => {
        const url = new URL(route.request().url());
        if (url.origin !== baseUrl) return route.abort();
        if (!url.pathname.startsWith("/api/")) return route.continue();
        if (url.pathname === "/api/user/me")
          return route.fulfill({ json: profile });
        if (url.pathname.endsWith("/count"))
          return route.fulfill({ json: { count: 3 } });
        if (url.pathname === "/api/admin/backups/health") {
          healthRequests.push(url);
          if (healthMode === "error")
            return route.fulfill({
              status: 500,
              json: { message: "Backup status is temporarily unavailable." },
            });
          if (healthMode === "fallback")
            return route.fulfill({ status: 500, json: {} });
          return route.fulfill({
            json: {
              latestAttempt: null,
              latestSuccessfulBackup:
                healthMode === "none"
                  ? null
                  : {
                      id: 9,
                      dateTime: "2026-11-02T17:59:00Z",
                      type: "Automatic",
                      size: 2048,
                      status: "Completed",
                      completedAt: "2026-11-02T18:00:00Z",
                      expiresAt: null,
                      errorMessage: null,
                      canDownload: true,
                      downloadRoute: null,
                    },
              isRunning: false,
              enabled: true,
              retentionDays: 30,
              nextScheduledAt: null,
              timeZone: "Asia/Manila",
              timeZoneDisplay: "Philippine Time (UTC+8)",
            },
          });
        }
        return route.fulfill({
          json: { items: [], total: 0, has_more: false },
        });
      });
      // Each visit reloads the app, so no cached backup status carries over.
      async function navigate(role = "HeadAdmin") {
        await page.goto(`${baseUrl}/login`, {
          waitUntil: "domcontentloaded",
          timeout: 60000,
        });
        await page
          .getByRole("button", { name: "LOGIN", exact: true })
          .waitFor();
        await page.evaluate(
          async ({ user }) => {
            const { useAuthStore } = await import("/src/store/store.ts");
            useAuthStore
              .getState()
              .setAuth(
                user,
                `test.${btoa(JSON.stringify({ exp: Math.floor(Date.now() / 1000) + 3600 }))}.test`,
              );
            history.pushState({}, "", "/system/configuration");
            dispatchEvent(new PopStateEvent("popstate"));
          },
          { user: { ...profile, role } },
        );
        await page
          .getByRole("heading", { name: "System Configuration", exact: true })
          .waitFor();
      }
      const text = (value) => page.getByText(value, { exact: true });
      const placeholders = [
        "4 currently active",
        "1 draft for review",
        "Today",
        "Completed at 2:00 AM",
      ];

      // 18:00 UTC on Nov 2 is 2:00 AM on Nov 3 in Manila; completedAt wins over dateTime.
      await navigate();
      await text("Nov 3, 2026, 2:00 AM").waitFor();
      assert.equal(await text("Last data backup").count(), 1);
      assert.equal(await text("Last successful backup").count(), 1);
      assert.equal(await text("Nov 3, 2026, 1:59 AM").count(), 0);
      assert.equal(await text("3").count(), 2);
      assert.equal(await text("Currently in use").count(), 2);
      for (const placeholder of placeholders)
        assert.equal(await text(placeholder).count(), 0, placeholder);
      await page.screenshot({
        path: path.join(tmpdir(), "configuration-stats-desktop.png"),
      });
      await page.setViewportSize({ width: 390, height: 844 });
      assert.ok(
        await page.evaluate(
          () =>
            document.documentElement.scrollWidth <=
            document.documentElement.clientWidth,
        ),
      );
      await page.screenshot({
        path: path.join(tmpdir(), "configuration-stats-mobile.png"),
      });
      await page.setViewportSize({ width: 1440, height: 1000 });

      healthMode = "none";
      await navigate();
      await text("None yet").waitFor();
      assert.equal(await text("No successful backup recorded").count(), 1);

      for (const [mode, message] of [
        ["error", "Backup status is temporarily unavailable."],
        ["fallback", "Unable to load backup status. Please try again."],
      ]) {
        healthMode = mode;
        await navigate();
        // The app retries a failed request three times before showing the error.
        await text(message).waitFor({ timeout: 20000 });
        assert.equal(await text("Unavailable").count(), 1);
        assert.equal(await text("Nov 3, 2026, 2:00 AM").count(), 0);
      }

      healthMode = "success";
      const requestsBefore = healthRequests.length;
      await navigate("AdminOfficer");
      await text("Currently in use").first().waitFor();
      assert.equal(await text("Last data backup").count(), 0);
      assert.equal(await text("Currently in use").count(), 2);
      for (const placeholder of placeholders)
        assert.equal(await text(placeholder).count(), 0, placeholder);
      assert.equal(healthRequests.length, requestsBefore);
      assert.deepEqual(errors, []);
    } finally {
      await browser.close();
    }
  },
);

test(
  "configuration stat cards show skeletons while loading and recoverable unavailable cards",
  { timeout: 240000 },
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
      const errors = [];
      const modes = {
        sections: "normal",
        ordinances: "normal",
        health: "normal",
      };
      let delay = 0;
      page.on("pageerror", (error) => errors.push(error.message));
      async function reply(route, mode, message, json) {
        if (delay) await new Promise((resolve) => setTimeout(resolve, delay));
        if (mode === "error")
          return route.fulfill({ status: 500, json: { message } });
        if (mode === "fallback")
          return route.fulfill({ status: 500, json: {} });
        return route.fulfill({ json });
      }
      await page.route("**/*", async (route) => {
        const url = new URL(route.request().url());
        if (url.origin !== baseUrl) return route.abort();
        if (!url.pathname.startsWith("/api/")) return route.continue();
        if (url.pathname === "/api/user/me")
          return route.fulfill({ json: profile });
        if (url.pathname === "/api/marketSection/count")
          return reply(
            route,
            modes.sections,
            "Market sections are temporarily unavailable.",
            { count: 0 },
          );
        if (url.pathname === "/api/ordinance/count")
          return reply(
            route,
            modes.ordinances,
            "Ordinances are temporarily unavailable.",
            { count: 7 },
          );
        if (url.pathname === "/api/admin/backups/health")
          return reply(
            route,
            modes.health,
            "Backup status is temporarily unavailable.",
            {
              latestAttempt: null,
              latestSuccessfulBackup: null,
              isRunning: false,
              enabled: true,
              retentionDays: 30,
              nextScheduledAt: null,
              timeZone: "Asia/Manila",
              timeZoneDisplay: "Philippine Time (UTC+8)",
            },
          );
        return route.fulfill({
          json: { items: [], total: 0, has_more: false },
        });
      });
      async function navigate() {
        await page.goto(`${baseUrl}/login`, {
          waitUntil: "domcontentloaded",
          timeout: 60000,
        });
        await page
          .getByRole("button", { name: "LOGIN", exact: true })
          .waitFor();
        await page.evaluate(
          async ({ user }) => {
            const { useAuthStore } = await import("/src/store/store.ts");
            useAuthStore
              .getState()
              .setAuth(
                user,
                `test.${btoa(JSON.stringify({ exp: Math.floor(Date.now() / 1000) + 3600 }))}.test`,
              );
            history.pushState({}, "", "/system/configuration");
            dispatchEvent(new PopStateEvent("popstate"));
          },
          { user: profile },
        );
        await page
          .getByRole("heading", { name: "System Configuration", exact: true })
          .waitFor();
      }
      const stats = page.locator("[class*='statsRow']");
      const card = (label) =>
        stats.locator(":scope > *").filter({
          has: page.getByText(label, { exact: true }),
        });
      const skeletons = stats.locator("[data-config-stat-skeleton]");

      // Loading: three skeleton cards, never a stand-in number or text.
      delay = 1500;
      await navigate();
      await skeletons.first().waitFor();
      assert.equal(await skeletons.count(), 3);
      assert.equal(await stats.getAttribute("aria-busy"), "true");
      const loadingText = await stats.innerText();
      assert.ok(!/\b0\b/.test(loadingText), loadingText);
      assert.ok(!loadingText.includes("Loading"), loadingText);
      // A real zero is still shown as 0 once loaded.
      await card("Market sections").getByText("0", { exact: true }).waitFor();
      await card("Active ordinances").getByText("7", { exact: true }).waitFor();
      await card("Last data backup")
        .getByText("None yet", { exact: true })
        .waitFor();
      assert.equal(await skeletons.count(), 0);
      assert.equal(await stats.getAttribute("aria-busy"), "false");
      delay = 0;

      // Failures: each card fails on its own, with its own reason.
      modes.sections = "error";
      modes.ordinances = "fallback";
      await navigate();
      // The app retries a failed request three times before showing the error.
      const sections = card("Market sections");
      const ordinances = card("Active ordinances");
      const backup = card("Last data backup");
      await sections
        .getByText("Market sections are temporarily unavailable.", {
          exact: true,
        })
        .waitFor({ timeout: 20000 });
      await ordinances
        .getByText("Unable to load active ordinances. Please try again.", {
          exact: true,
        })
        .waitFor({ timeout: 20000 });
      assert.equal(
        await sections.getByText("Unavailable", { exact: true }).count(),
        1,
      );
      assert.equal(
        await ordinances.getByText("Unavailable", { exact: true }).count(),
        1,
      );
      assert.equal(await sections.getByRole("alert").count(), 1);
      assert.equal(
        await backup.getByText("None yet", { exact: true }).count(),
        1,
      );
      assert.equal(await backup.getByRole("button").count(), 0);
      assert.ok(!/\b0\b/.test(await sections.innerText()));
      await page.setViewportSize({ width: 390, height: 844 });
      await page.waitForTimeout(600);
      assert.ok(
        await page.evaluate(
          () =>
            document.documentElement.scrollWidth <=
            document.documentElement.clientWidth,
        ),
      );
      await stats.screenshot({
        path: path.join(tmpdir(), "configuration-unavailable-mobile.png"),
      });
      await page.setViewportSize({ width: 1440, height: 1000 });
      await stats.screenshot({
        path: path.join(tmpdir(), "configuration-unavailable-desktop.png"),
      });

      // Try again recovers only the card that was retried.
      modes.sections = "normal";
      await sections.getByRole("button", { name: "Try again" }).click();
      await sections.getByText("0", { exact: true }).waitFor();
      assert.equal(await sections.getByText("Unavailable").count(), 0);
      assert.equal(
        await ordinances.getByText("Unavailable", { exact: true }).count(),
        1,
      );
      modes.ordinances = "normal";
      await ordinances.getByRole("button", { name: "Try again" }).click();
      await ordinances.getByText("7", { exact: true }).waitFor();

      // Backup status failure leaves the counts alone and also recovers.
      modes.health = "error";
      await navigate();
      await backup
        .getByText("Backup status is temporarily unavailable.", {
          exact: true,
        })
        .waitFor({ timeout: 20000 });
      assert.equal(
        await backup.getByText("Unavailable", { exact: true }).count(),
        1,
      );
      assert.equal(
        await sections.getByText("0", { exact: true }).count(),
        1,
      );
      modes.health = "normal";
      await backup.getByRole("button", { name: "Try again" }).click();
      await backup.getByText("None yet", { exact: true }).waitFor();
      assert.deepEqual(errors, []);
    } finally {
      await browser.close();
    }
  },
);
