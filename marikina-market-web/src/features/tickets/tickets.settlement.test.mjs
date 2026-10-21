import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import ts from "typescript";

async function compile(path, replacements = {}) {
  let source = ts.transpileModule(
    await readFile(new URL(path, import.meta.url), "utf8"),
    {
      compilerOptions: {
        module: ts.ModuleKind.ESNext,
        target: ts.ScriptTarget.ES2020,
      },
    },
  ).outputText;
  for (const [from, to] of Object.entries(replacements))
    source = source.replaceAll(JSON.stringify(from), JSON.stringify(to));
  return `data:text/javascript;base64,${Buffer.from(source).toString("base64")}`;
}

const utils = await compile("./tickets.utils.ts");
const { getTicketReceiptUrls, getTicketProofUrl } = await import(utils);
const { useTicketSettlement } = await import(
  await compile("./hooks/useTicketSettlement.ts", { "../tickets.utils": utils })
);
const receipt = "https://storage.example.com/receipt.png?signed=example";
const base = {
  type: "Ticket",
  penaltyType: "CommunityService",
  communityServiceHours: 8,
  hoursCompleted: 6,
  communityServiceLogs: [],
  proofUrls: [],
  ticketReceipts: [],
};

test("receipt URLs retain signed query strings and reject unsafe or malformed values", () => {
  assert.equal(getTicketProofUrl(receipt), receipt);
  for (const value of [
    null,
    undefined,
    "",
    "  ",
    "javascript:alert(1)",
    "data:image/png;base64,abc",
    "/receipt.png",
    12,
  ])
    assert.equal(getTicketProofUrl(value), null);
  assert.deepEqual(
    getTicketReceiptUrls({ proofUrls: [null, receipt, "bad"] }),
    [receipt],
  );
});

test("ticket receipts remain a fallback when proof_urls is absent", () => {
  assert.deepEqual(getTicketReceiptUrls({ ticketReceipts: [receipt] }), [
    receipt,
  ]);
  assert.deepEqual(getTicketReceiptUrls(undefined), []);
});

test("penalty type selects only the appropriate read-only settlement section", () => {
  for (const penaltyType of ["CashFine", "BloodDonation"])
    assert.equal(useTicketSettlement({ ...base, penaltyType }).kind, "receipt");
  assert.equal(useTicketSettlement(base).kind, "service");
  assert.equal(useTicketSettlement({ ...base, type: "Warning" }).kind, null);
  assert.equal(
    useTicketSettlement({ ...base, penaltyType: "Unsupported" }).kind,
    null,
  );
  assert.equal(useTicketSettlement(undefined).kind, null);
});

test("progress preserves fractional hours and stays within the progress-bar range", () => {
  assert.equal(useTicketSettlement(base).percentage, 75);
  assert.equal(
    useTicketSettlement({ ...base, hoursCompleted: 2.5 }).percentage,
    31.25,
  );
  assert.equal(
    useTicketSettlement({ ...base, hoursCompleted: 0 }).percentage,
    0,
  );
  assert.equal(
    useTicketSettlement({ ...base, hoursCompleted: 10 }).percentage,
    100,
  );
});

test("missing or invalid progress values never produce NaN or a misleading percentage", () => {
  for (const communityServiceHours of [
    undefined,
    null,
    0,
    -1,
    NaN,
    Infinity,
    "8",
  ])
    assert.equal(
      useTicketSettlement({ ...base, communityServiceHours }).percentage,
      null,
    );
  for (const hoursCompleted of [undefined, null, -1, NaN, Infinity, "6"])
    assert.equal(
      useTicketSettlement({ ...base, hoursCompleted }).percentage,
      null,
    );
});

test("logs preserve dates and decimal hours, and tolerate missing photos or invalid entries", () => {
  const model = useTicketSettlement({
    ...base,
    communityServiceLogs: [
      null,
      {
        serviceDate: "2026-10-06T00:00:00Z",
        hoursWorked: 2.5,
        proofUrl: receipt,
      },
      { serviceDate: "invalid", hoursWorked: -1, proofUrl: null },
    ],
  });
  assert.equal(model.logs.length, 2);
  assert.equal(model.logs[0].date, "2026-10-06T00:00:00Z");
  assert.equal(model.logs[0].hours, 2.5);
  assert.equal(model.logs[0].url, receipt);
  assert.equal(model.logs[1].date, null);
  assert.equal(model.logs[1].hours, null);
  assert.equal(model.logs[1].url, null);
  assert.deepEqual(
    useTicketSettlement({ ...base, communityServiceLogs: null }).logs,
    [],
  );
});
