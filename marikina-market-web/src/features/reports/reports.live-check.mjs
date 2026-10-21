import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { createInterface } from "node:readline";
import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { preview } from "vite";

const require = createRequire(import.meta.url);
const { chromium } = require(
  process.env.REPORTS_PLAYWRIGHT_MODULE ||
    "C:/Users/Kian Gabriel/AppData/Local/npm-cache/_npx/9833c18b2d85bc59/node_modules/playwright",
);
const root = process.env.REPORTS_LIVE_ROOT;
if (!root) throw new Error("Explicit report verification root is required.");
const users = JSON.parse(process.env.REPORTS_TEST_USERS);
const volatileSecrets = [process.env.REPORTS_TEST_PASSWORD];
const lines = createInterface({ input: process.stdin });
const replies = lines[Symbol.asyncIterator]();
async function rpc(action, extra = {}) {
  process.stdout.write(`RPC:${JSON.stringify({ action, ...extra })}\n`);
  const reply = await replies.next();
  if (reply.done) throw new Error("Verification host disconnected.");
  return JSON.parse(reply.value);
}
const results = { status: "running", checks: [], runtimeErrors: [] };
async function check(name, fn) {
  await fn();
  results.checks.push(name);
  await save();
}
async function save() {
  await writeFile(
    path.join(root, "browser-result.json"),
    JSON.stringify(results, null, 2),
  );
}
async function progress(stage) {
  await writeFile(
    path.join(root, "browser-progress.json"),
    JSON.stringify({ stage, utc: new Date().toISOString() }),
  );
}
const server = await preview({
  root: process.cwd(),
  build: { outDir: path.join(root, "web-dist") },
  preview: {
    port: 5176,
    strictPort: true,
    open: false,
    proxy: { "/api": { target: "http://127.0.0.1:5076", changeOrigin: true } },
  },
  logLevel: "silent",
});
assert.equal(
  server.config.preview.proxy["/api"].target,
  "http://127.0.0.1:5076",
);
let browser;
let latestPage;
let stage = "startup";
try {
  browser = await chromium.launch({ channel: "msedge", headless: true });
  async function login(index, existingPage) {
    await progress(`login_${index}_context`);
    const context =
      existingPage?.context() ??
      (await browser.newContext({
        viewport: { width: 1440, height: 1000 },
        acceptDownloads: true,
      }));
    // No mocked API/authentication responses. Only nonlocal external resources are blocked.
    if (!existingPage)
      await context.route("**/*", (route) => {
        const url = new URL(route.request().url());
        return ["localhost", "127.0.0.1"].includes(url.hostname) ||
          ["data:", "blob:"].includes(url.protocol)
          ? route.continue()
          : route.abort();
      });
    const page = existingPage ?? (await context.newPage());
    latestPage = page;
    page.setDefaultTimeout(60000);
    page.on("pageerror", (error) => results.runtimeErrors.push(error.name));
    await progress(`login_${index}_navigation`);
    await page.goto("http://localhost:5176/admin/login", {
      waitUntil: "domcontentloaded",
      timeout: 60000,
    });
    await progress(`login_${index}_form`);
    await page.locator("#login-username").fill(users[index].username);
    await page
      .locator("#login-password")
      .fill(process.env.REPORTS_TEST_PASSWORD);
    const challenge = page.waitForResponse((r) =>
      r.url().endsWith("/api/auth/login"),
    );
    await page.getByRole("button", { name: /^log\s*in$/i }).click();
    assert.equal((await challenge).status(), 200);
    await progress(`login_${index}_otp`);
    const { code } = await rpc("otp", { index });
    volatileSecrets.push(code);
    await page.getByLabel("Verification digit 1", { exact: true }).fill(code);
    const verified = page.waitForResponse((r) =>
      r.url().endsWith("/api/auth/verify-login"),
    );
    await page
      .getByRole("button", { name: "Verify & sign in", exact: true })
      .click();
    const response = await verified;
    assert.equal(response.status(), 200);
    await progress(`login_${index}_verified`);
    const token = (await response.json()).access_token;
    volatileSecrets.push(token);
    assert.ok(token);
    await page.waitForURL((url) => !/login|verify/.test(url.pathname));
    await page.getByRole("link", { name: "Reports", exact: true }).click();
    await progress(`login_${index}_reports`);
    await page.locator("#report-from").waitFor();
    return { context, page, token };
  }
  const head = await login(0);
  const { page, context, token } = head;
  results.checks.push(
    "HeadAdmin real password/OTP login with in-memory email boundary",
  );
  const auth = { Authorization: `Bearer ${token}` };
  const api = async (suffix, options = {}) =>
    context.request.get(`http://localhost:5176/api/admin/reports${suffix}`, {
      headers: auth,
      ...options,
    });
  let original;
  stage = "generate";
  await check(
    "Manila boundaries and seven-record summary through real API/web",
    async () => {
      await page.locator("#report-from").fill("2026-10-01");
      await page.locator("#report-to").fill("2026-10-02");
      const response = page.waitForResponse(
        (r) =>
          r.url().endsWith("/api/admin/reports") &&
          r.request().method() === "POST",
      );
      await page
        .getByRole("button", { name: "Generate Report", exact: true })
        .click();
      const generated = await response;
      assert.equal(generated.status(), 200);
      const created = await generated.json();
      original = await (await api(`/${created.id}`)).json();
      // PostgreSQL stores microseconds; compare creation time at JS millisecond precision.
      assert.deepEqual(
        { ...created, date_generated: Date.parse(created.date_generated) },
        { ...original, date_generated: Date.parse(original.date_generated) },
      );
      await writeFile(
        path.join(root, "original-report.json"),
        JSON.stringify(original, null, 2),
      );
      assert.deepEqual(original.summary.total, {
        total_records: 7,
        assessed_penalties: 1200,
      });
      assert.deepEqual(original.summary.resolved, {
        total_records: 2,
        assessed_penalties: 700,
      });
      assert.deepEqual(original.summary.pending, {
        total_records: 2,
        assessed_penalties: 500,
      });
      assert.equal(original.summary.warnings_issued.total_records, 3);
      const paper = page.getByRole("article", {
        name: `Saved report ${original.id}`,
        exact: true,
      });
      await paper.waitFor();
      assert.match(await paper.innerText(), /1,200\.00/);
      assert.equal(
        await paper
          .getByRole("row")
          .filter({ hasText: "Warnings issued" })
          .getByRole("cell")
          .nth(0)
          .innerText(),
        "3",
      );
    },
  );
  await check(
    "Anonymous, denied-role, invalid-range and missing-report responses",
    async () => {
      const response = await context.request.get(
        "http://localhost:5176/api/admin/reports",
      );
      assert.equal(response.status(), 401);
      const tokens = await rpc("denialTokens");
      volatileSecrets.push(tokens.vendor, tokens.enforcer);
      for (const role of ["vendor", "enforcer"]) {
        for (const suffix of [
          "",
          "/preview?date=2026-10-01",
          `/${original.id}`,
        ])
          assert.equal(
            (
              await api(suffix, {
                headers: { Authorization: `Bearer ${tokens[role]}` },
              })
            ).status(),
            403,
          );
        assert.equal(
          (
            await context.request.post(
              "http://localhost:5176/api/admin/reports",
              {
                headers: { Authorization: `Bearer ${tokens[role]}` },
                data: {
                  from: "2026-10-01",
                  to: "2026-10-02",
                  type: "Warning & Ticket",
                },
              },
            )
          ).status(),
          403,
        );
      }
      assert.equal((await api("/2147483647")).status(), 404);
      assert.equal((await api("/preview?date=invalid")).status(), 400);
      assert.equal(
        (
          await context.request.post(
            "http://localhost:5176/api/admin/reports",
            {
              headers: auth,
              data: {
                from: "2026-10-02",
                to: "2026-10-01",
                type: "Warning & Ticket",
              },
            },
          )
        ).status(),
        400,
      );
    },
  );
  stage = "snapshot";
  await rpc("mutate");
  await check(
    "Saved snapshot survives source mutation, browser refresh and fresh login",
    async () => {
      await page.reload();
      // Existing web sessions are intentionally memory-only; reload requires real login again.
      await login(0, page);
      await page
        .getByRole("button", {
          name: `View report ${original.id}`,
          exact: true,
        })
        .click();
      await page
        .getByRole("article", {
          name: `Saved report ${original.id}`,
          exact: true,
        })
        .waitFor();
      assert.deepEqual(await (await api(`/${original.id}`)).json(), original);
    },
  );
  async function exportsFor(session, label) {
    const paper = session.page.getByRole("article", {
      name: `Saved report ${original.id}`,
      exact: true,
    });
    await paper.waitFor();
    const csvDownload = session.page.waitForEvent("download");
    await session.page
      .getByRole("button", { name: "Export CSV", exact: true })
      .click();
    const csv = await csvDownload;
    await csv.saveAs(path.join(root, `${label}.csv`));
    const content = await readFile(path.join(root, `${label}.csv`), "utf8");
    for (const row of [
      `"Report ID","${original.id}"`,
      '"From","2026-10-01"',
      '"To","2026-10-02"',
      '"Warnings issued","3","0"',
      '"Tickets issued","4","1200"',
      '"Resolved records","2","700"',
      '"Pending records","2","500"',
      '"Total","7","1200"',
      `"Generated by","${original.generated_by.name}"`,
      `"Date generated","${original.date_generated}"`,
    ])
      assert.ok(content.includes(row), "CSV metadata/summary mismatch");
    const pdfDownload = session.page.waitForEvent("download");
    await session.page
      .getByRole("button", { name: "Download PDF", exact: true })
      .click();
    const pdf = await pdfDownload;
    await pdf.saveAs(path.join(root, `${label}.pdf`));
    const bytes = await readFile(path.join(root, `${label}.pdf`));
    assert.equal(bytes.subarray(0, 5).toString(), "%PDF-");
    assert.ok(bytes.length > 10000);
    await session.page.screenshot({
      path: path.join(root, `${label}.png`),
      fullPage: true,
    });
    return content;
  }
  stage = "exports";
  const headCsv = await exportsFor(head, "headadmin-saved");
  results.checks.push(
    "HeadAdmin saved snapshot CSV metadata/all totals and PDF download",
  );
  stage = "request_recovery";
  await check(
    "Report failure disables both exports; real API retry recovers",
    async () => {
      // A fresh login clears the one-minute query cache so this exercises an actual request.
      await page.reload();
      await login(0, page);
      await page.route(`**/api/admin/reports/${original.id}`, (route) =>
        route.abort("failed"),
      );
      await page
        .getByRole("button", {
          name: `View report ${original.id}`,
          exact: true,
        })
        .click();
      await page.getByText("Report unavailable", { exact: true }).waitFor();
      assert.equal(
        await page
          .getByRole("button", { name: "Download PDF", exact: true })
          .isDisabled(),
        true,
      );
      assert.equal(
        await page
          .getByRole("button", { name: "Export CSV", exact: true })
          .isDisabled(),
        true,
      );
      await page.unroute(`**/api/admin/reports/${original.id}`);
      await page
        .getByRole("button", { name: /retry|try again/i })
        .last()
        .click();
      await page
        .getByRole("article", {
          name: `Saved report ${original.id}`,
          exact: true,
        })
        .waitFor();
      assert.equal(
        await page
          .getByRole("button", { name: "Export CSV", exact: true })
          .isEnabled(),
        true,
      );
    },
  );
  stage = "fresh_head_login";
  await context.close();
  const fresh = await login(0);
  await fresh.page
    .getByRole("button", { name: `View report ${original.id}`, exact: true })
    .click();
  await fresh.page
    .getByRole("article", { name: `Saved report ${original.id}`, exact: true })
    .waitFor();
  assert.deepEqual(
    await (
      await fresh.context.request.get(
        `http://localhost:5176/api/admin/reports/${original.id}`,
        { headers: { Authorization: `Bearer ${fresh.token}` } },
      )
    ).json(),
    original,
  );
  results.checks.push(
    "HeadAdmin fresh password/OTP login retains original snapshot",
  );
  stage = "regenerate";
  await check(
    "New report reflects current source values while old report remains unchanged",
    async () => {
      const generated = fresh.page.waitForResponse(
        (r) =>
          r.url().endsWith("/api/admin/reports") &&
          r.request().method() === "POST",
      );
      await fresh.page
        .getByRole("button", { name: "Generate Report", exact: true })
        .click();
      const response = await generated;
      assert.equal(response.status(), 200);
      const updated = await response.json();
      assert.deepEqual(updated.summary.total, {
        total_records: 7,
        assessed_penalties: 1200,
      });
      assert.deepEqual(updated.summary.resolved, {
        total_records: 3,
        assessed_penalties: 900,
      });
      assert.deepEqual(updated.summary.pending, {
        total_records: 1,
        assessed_penalties: 300,
      });
    },
  );
  await fresh.context.close();
  stage = "adminofficer";
  const officer = await login(1);
  await officer.page
    .getByRole("button", { name: `View report ${original.id}`, exact: true })
    .click();
  const officerCsv = await exportsFor(officer, "adminofficer-saved");
  assert.equal(officerCsv, headCsv);
  results.checks.push(
    "AdminOfficer real login/reopen and identical saved snapshot CSV/PDF export",
  );
  await officer.context.close();
  assert.deepEqual(results.runtimeErrors, []);
  results.status = "passed";
} catch (error) {
  if (latestPage && !latestPage.isClosed())
    await latestPage
      .screenshot({
        path: path.join(root, "browser-failure.png"),
        fullPage: true,
        mask: [
          latestPage.locator(
            'input[type="password"], input[aria-label^="Verification digit"]',
          ),
        ],
      })
      .catch(() => {});
  results.status = "failed";
  results.stage = stage;
  // Only assertion diagnostics; never serialize sessions, requests, credentials or OTPs.
  results.error = error.name;
  results.message = String(error.message);
  for (const secret of volatileSecrets.filter(Boolean))
    results.message = results.message.replaceAll(secret, "[redacted]");
  process.exitCode = 1;
} finally {
  await browser?.close();
  await server.close();
  lines.close();
  await save();
}
