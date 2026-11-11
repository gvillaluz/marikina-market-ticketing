import assert from "node:assert/strict";
import { createRequire } from "node:module";
import test from "node:test";

const require = createRequire(import.meta.url);
const { chromium } = require(
  process.env.REPORTS_PLAYWRIGHT_MODULE || "playwright",
);
const baseUrl = process.env.BUSINESS_PAGE_TEST_URL || "http://127.0.0.1:5175";
const browserPath =
  process.env.BUSINESS_PAGE_BROWSER ||
  "C:/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe";

const profile = {
  userId: 7,
  username: "business.test",
  firstName: "Test",
  lastName: "Administrator",
  role: "HeadAdmin",
  status: "Active",
  email: "test@example.com",
  profileUrl: null,
  mustChangedPassword: false,
};

// Invented businesses. Row 1 has no warnings, row 2 has a very long name and
// no tickets, row 3 has one of each.
const businesses = [
  {
    vendorId: 4,
    businessAccountNumber: "0012345",
    vendorName: "Juan Reyes",
    businessName: "Reyes Fresh Meats",
    marketSectionName: "Meat",
    type: "Public",
    complianceScore: 92,
    warningCount: 0,
    ticketCount: 2,
  },
  {
    vendorId: 5,
    businessAccountNumber: "0012399",
    vendorName: "Maria Concepcion Dela Cruz-Santos",
    businessName: "Dela Cruz and Sons Wholesale Dried Fish and Seafood Trading",
    marketSectionName: "Dried Fish",
    type: "Private",
    complianceScore: 64,
    warningCount: 3,
    ticketCount: 0,
  },
  {
    vendorId: 6,
    businessAccountNumber: "0012400",
    vendorName: "Pedro Santos",
    businessName: "Santos Sari-Sari",
    marketSectionName: "Vegetables",
    type: "Public",
    complianceScore: 45,
    warningCount: 1,
    ticketCount: 1,
  },
];

const hoursAgo = (hours) =>
  new Date(Date.now() - hours * 3600 * 1000).toISOString();
const daysFromNow = (days) =>
  new Date(Date.now() + days * 86400 * 1000).toISOString();

const overview = {
  vendorsWithWarningsThisWeek: 3,
  vendorsWithTicketsThisWeek: 5,
  activities: [
    {
      ticketId: 101,
      controlNumber: "2026-0101",
      businessAccountNumber: "0012345",
      vendorName: "Juan Reyes",
      type: "Warning",
      issuedAt: hoursAgo(2),
    },
    {
      ticketId: 102,
      controlNumber: "2026-0102",
      businessAccountNumber: "0012399",
      vendorName: "Maria Concepcion Dela Cruz-Santos",
      type: "Ticket",
      issuedAt: hoursAgo(30),
    },
  ],
};

const settlements = [
  {
    ticketId: 201,
    controlNumber: "2026-0201",
    businessAccountNumber: "0012399",
    vendorName: "Maria Concepcion Dela Cruz-Santos",
    marketSectionName: "Dried Fish",
    status: "Pending",
    penaltyType: "CashFine",
    totalPaymentAmount: 500,
    communityServiceHours: null,
    issuedAt: hoursAgo(24 * 20),
    dueDate: daysFromNow(-3),
  },
  {
    ticketId: 202,
    controlNumber: "2026-0202",
    businessAccountNumber: "0012400",
    vendorName: "Pedro Santos",
    marketSectionName: "Vegetables",
    status: "Pending",
    penaltyType: "CashFine",
    totalPaymentAmount: 300,
    communityServiceHours: null,
    issuedAt: hoursAgo(24 * 5),
    dueDate: daysFromNow(9),
  },
];

const businessRecord = {
  id: 4,
  businessAccountNumber: "0012345",
  businessName: "Reyes Fresh Meats",
  ownerFirstName: "Juan",
  ownerLastName: "Reyes",
  houseNumber: "12",
  street: "Shoe Avenue",
  barangay: "Sto. Nino",
  city: "Marikina",
  phoneNumber: null,
  email: null,
  marketSectionId: 1,
  businessType: "Public",
  stallNumber: null,
  marketSectionName: "Meat",
  createdAt: "2026-10-01T00:00:00Z",
  status: "Active",
};

const page_ = (items) => ({ items, hasMore: false, total: items.length });
const WIDTHS = [1440, 1024, 768, 390, 320];
const HEADERS = [
  "Business",
  "Registered Owner",
  "Section & Type",
  "Compliance Score",
  "Warnings",
  "Tickets",
  "Action",
];

// mode: "data" | "empty" | "error". Every API request is answered here; none
// reaches a real server.
async function openPage(browser, width, mode, hold) {
  const page = await browser.newPage({
    viewport: { width, height: 900 },
    reducedMotion: "reduce",
  });
  page.setDefaultTimeout(45000);
  page.on("pageerror", (error) => {
    throw new Error(`Page error: ${error.message}`);
  });
  await page.route(`${baseUrl}/api/**`, async (route) => {
    const path = new URL(route.request().url()).pathname;
    const fail = (message) =>
      route.fulfill({ status: 500, json: { message } });
    if (path === "/api/admin/vendors") {
      if (hold) await hold;
      if (mode === "error") return fail("Businesses are unavailable.");
      return route.fulfill({
        json: page_(mode === "empty" ? [] : businesses),
      });
    }
    if (path === "/api/admin/vendors/compliance-overview") {
      if (mode === "error") return fail("Compliance is unavailable.");
      return route.fulfill({
        json:
          mode === "empty"
            ? {
                vendorsWithWarningsThisWeek: 0,
                vendorsWithTicketsThisWeek: 0,
                activities: [],
              }
            : overview,
      });
    }
    if (path === "/api/admin/vendors/pending-settlements") {
      if (mode === "error") return fail("Settlements are unavailable.");
      return route.fulfill({
        json: page_(mode === "empty" ? [] : settlements),
      });
    }
    if (path === "/api/admin/vendors/community-service-logs")
      return route.fulfill({ json: page_([]) });
    if (path === "/api/admin/businesses/4")
      return route.fulfill({ json: businessRecord });
    // The inspections page that "Inspections" opens.
    if (path === "/api/admin/vendors/4/profile")
      return route.fulfill({
        json: {
          name: "Juan Reyes",
          businessAccountNumber: "0012345",
          businessName: "Reyes Fresh Meats",
          phoneNumber: null,
          email: null,
          createdAt: "2026-10-01T00:00:00Z",
          lastViolationIssuedAt: null,
        },
      });
    if (path === "/api/admin/vendors/4/compliance-score")
      return route.fulfill({
        json: {
          complianceScore: 92,
          standing: "Good",
          violationFrequency: 0,
          ticketsInWindow: 0,
          violationFrequencyLevel: "Low",
          recency: 0,
          daysSinceLastTicket: null,
          categorySeverity: 0,
          averageSeverityPoints: null,
          categorySeverityLevel: "Low",
          penaltyPaymentHistory: 0,
          paymentHistoryTickets: 0,
          calculatedAt: hoursAgo(1),
        },
      });
    if (path === "/api/admin/vendors/4/inspections")
      return route.fulfill({ json: page_([]) });
    return route.fulfill({
      json: path.endsWith("/user/me") ? profile : {},
    });
  });
  await page.goto(`${baseUrl}/login`);
  await page.getByRole("button", { name: "LOGIN", exact: true }).waitFor();
  await page.evaluate(async (user) => {
    const { useAuthStore } = await import("/src/store/store.ts");
    useAuthStore
      .getState()
      .setAuth(
        user,
        `test.${btoa(JSON.stringify({ exp: Math.floor(Date.now() / 1000) + 3600 }))}.test`,
      );
    history.pushState({}, "", "/admin/vendors");
    dispatchEvent(new PopStateEvent("popstate"));
  }, profile);
  return page;
}

const registryOf = (page) =>
  page.getByRole("region", { name: "Business registry", exact: true });
const panelOf = (page) => page.locator('section[class*="compliancePanel"]');

async function checkData(browser, width) {
  const page = await openPage(browser, width, "data");
  const registry = registryOf(page);
  const panel = panelOf(page);
  await registry.getByRole("row").nth(1).waitFor();
  await panel.getByText("Overdue").waitFor();
  const at = `at ${width}px`;

  // 1. The page itself never scrolls sideways.
  const overflow = await page.evaluate(() => ({
    scroll: document.documentElement.scrollWidth,
    view: document.documentElement.clientWidth,
  }));
  assert.ok(
    overflow.scroll <= overflow.view,
    `page scrolls sideways ${at}: ${overflow.scroll} > ${overflow.view}`,
  );

  // 2. Columns and cell contents.
  assert.deepEqual(
    (await registry.getByRole("columnheader").allTextContents()).map((text) =>
      text.trim(),
    ),
    HEADERS,
    `column headers ${at}`,
  );
  const cellLines = async (row, column) =>
    registry.locator("tbody tr").nth(row).locator("td").nth(column).evaluate(
      (cell) =>
        cell.innerText
          .split("\n")
          .map((line) => line.trim())
          .filter(Boolean),
    );
  assert.deepEqual(await cellLines(0, 0), ["Reyes Fresh Meats", "0012345"]);
  assert.deepEqual(await cellLines(0, 1), ["Juan Reyes"]);
  assert.deepEqual(await cellLines(0, 2), ["Meat", "Public"]);
  assert.deepEqual(await cellLines(0, 3), ["92%"]);
  assert.deepEqual(await cellLines(0, 4), ["\u2014"], "zero warnings");
  assert.deepEqual(await cellLines(0, 5), ["2"]);
  assert.deepEqual(await cellLines(1, 4), ["3"]);
  assert.deepEqual(await cellLines(1, 5), ["\u2014"], "zero tickets");

  // 3. The table never needs sideways scrolling, and every row button is fully
  // visible inside the table area, inside its cell, and does not overlap.
  const actionProblems = await registry.locator("tbody tr").evaluateAll(
    (rows, phone) =>
      rows.flatMap((row, index) => {
        const wrapper = row.closest('[class*="tableWrapper"]');
        const wrapperBox = wrapper.getBoundingClientRect();
        const cell = row.querySelector("td:last-child");
        const cellBox = cell.getBoundingClientRect();
        const boxes = [...cell.querySelectorAll("button")].map((button) => ({
          label: button.innerText.trim(),
          name: button.getAttribute("aria-label") ?? "",
          box: button.getBoundingClientRect(),
          clipped: button.scrollWidth > button.clientWidth + 1,
        }));
        const problems = [];
        if (index === 0 && wrapper.scrollWidth > wrapper.clientWidth + 1)
          problems.push(
            `table needs sideways scrolling (${wrapper.scrollWidth} > ${wrapper.clientWidth})`,
          );
        if (
          boxes.length !== 2 ||
          !boxes[0].name.startsWith("Edit ") ||
          !boxes[1].name.startsWith("View inspections for ")
        )
          problems.push(
            `row ${index}: button names are "${boxes.map((b) => b.name).join("|")}"`,
          );
        if (phone && boxes.map((b) => b.label).join("|") !== "Edit|Inspections")
          problems.push(
            `row ${index}: phone labels are "${boxes.map((b) => b.label).join("|")}"`,
          );
        boxes.forEach(({ name, box, clipped }) => {
          if (box.left < cellBox.left - 0.5 || box.right > cellBox.right + 0.5)
            problems.push(`row ${index}: ${name} sticks out of its cell`);
          if (
            box.left < wrapperBox.left - 0.5 ||
            box.right > wrapperBox.right + 0.5
          )
            problems.push(`row ${index}: ${name} is hidden by the table edge`);
          if (clipped) problems.push(`row ${index}: ${name} text is cut off`);
        });
        if (boxes.length === 2) {
          const [a, b] = boxes.map((x) => x.box);
          const apart =
            a.right <= b.left + 0.5 ||
            b.right <= a.left + 0.5 ||
            a.bottom <= b.top + 0.5 ||
            b.bottom <= a.top + 0.5;
          if (!apart) problems.push(`row ${index}: buttons overlap`);
        }
        return problems;
      }),
    width <= 700,
  );
  assert.deepEqual(actionProblems, [], `row buttons ${at}`);

  // 4. Touch size on phones: every control in the registry and panel.
  if (width <= 390) {
    const small = await page.evaluate(() => {
      const scopes = [
        document.querySelector('section[aria-label="Business registry"]'),
        document.querySelector('section[class*="compliancePanel"]'),
      ];
      return scopes.flatMap((scope) =>
        [...scope.querySelectorAll("button, a, input")]
          .filter((el) => el.offsetParent !== null)
          .map((el) => ({
            name: (el.innerText || el.getAttribute("aria-label") || el.tagName)
              .trim()
              .slice(0, 30),
            height: Math.round(el.getBoundingClientRect().height),
          }))
          .filter((item) => item.height < 44),
      );
    });
    assert.deepEqual(small, [], `controls shorter than 44px ${at}`);
  }

  // 5. Right panel: wording, text size and placement.
  const panelText = await panel.innerText();
  assert.ok(!/VENDORS/i.test(panelText), `panel still says VENDORS ${at}`);
  assert.ok(
    panelText.includes("3\nBusinesses with warnings this week"),
    `warnings tile ${at}: ${JSON.stringify(panelText.slice(0, 160))}`,
  );
  assert.ok(
    panelText.includes("5\nBusinesses with tickets this week"),
    `tickets tile ${at}`,
  );
  assert.ok(panelText.includes("Track market business activities."));
  const tiny = await panel.evaluate((root) => {
    const found = [];
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
      if (!node.textContent.trim()) continue;
      const size = parseFloat(getComputedStyle(node.parentElement).fontSize);
      if (size < 12)
        found.push(`${node.textContent.trim().slice(0, 24)} (${size}px)`);
    }
    return found;
  });
  assert.deepEqual(tiny, [], `panel text under 12px ${at}`);

  const boxes = await page.evaluate(() => {
    const rect = (el) => el.getBoundingClientRect();
    const registryBox = rect(
      document.querySelector('section[aria-label="Business registry"]'),
    );
    const panelEl = document.querySelector('section[class*="compliancePanel"]');
    const headings = [...panelEl.querySelectorAll("h3")];
    return {
      registry: registryBox,
      panel: rect(panelEl),
      activities: rect(headings.find((h) => h.innerText.includes("Activities"))),
      settlements: rect(headings.find((h) => h.innerText.includes("Settlements"))),
    };
  });
  if (width >= 1440) {
    assert.ok(
      boxes.panel.left >= boxes.registry.right - 1,
      `panel should sit beside the table ${at}`,
    );
  } else {
    assert.ok(
      boxes.panel.top >= boxes.registry.bottom - 1,
      `panel should sit under the table ${at}`,
    );
    if (width >= 768)
      assert.ok(
        Math.abs(boxes.activities.top - boxes.settlements.top) < 8,
        `panel sections should sit side by side ${at}`,
      );
    else
      assert.ok(
        boxes.settlements.top > boxes.activities.top,
        `panel sections should stack ${at}`,
      );
  }
  await page.close();
}

test(
  "businesses page layout, wording, touch size and states",
  { timeout: 300000 },
  async () => {
    const browser = await chromium.launch({
      executablePath: browserPath,
      headless: true,
    });
    try {
      for (const width of WIDTHS) await checkData(browser, width);

      // Loading state, then actions behave as before.
      let release;
      const hold = new Promise((resolve) => (release = resolve));
      const loading = await openPage(browser, 1440, "data", hold);
      await loading.getByText("Loading business records...").waitFor();
      release();
      const registry = registryOf(loading);
      await registry.getByRole("row").nth(1).waitFor();
      await registry
        .getByRole("button", { name: "Edit Reyes Fresh Meats" })
        .click();
      await loading.getByRole("dialog").getByText("Edit Business").waitFor();
      await loading.keyboard.press("Escape");
      await registry
        .getByRole("button", { name: "View inspections for Juan Reyes" })
        .click();
      await loading.waitForURL("**/admin/vendors/4/inspections");
      await loading.close();

      // Empty state.
      const empty = await openPage(browser, 1440, "empty");
      await registryOf(empty)
        .getByText("No businesses match these filters.")
        .waitFor();
      const emptyPanel = panelOf(empty);
      await emptyPanel.getByText("No recent business activity.").waitFor();
      await emptyPanel.getByText("No pending settlements.").waitFor();
      assert.ok(!/VENDORS/i.test(await emptyPanel.innerText()));
      await empty.close();

      // Error state.
      const error = await openPage(browser, 390, "error");
      await registryOf(error).getByText("Unable to load businesses").waitFor();
      await panelOf(error).getByText("Compliance is unavailable.").waitFor();
      await panelOf(error).getByText("Settlements are unavailable.").waitFor();
      await error.close();
    } finally {
      await browser.close();
    }
  },
);
