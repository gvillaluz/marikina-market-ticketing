import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

// Change penalty (spec-change-penalty.md section 6). Every expected value below is written by hand from the spec.

function load(file, mocks) {
  const module = { exports: {} };
  const code = ts.transpileModule(
    fs.readFileSync(new URL(file, import.meta.url), "utf8"),
    {
      compilerOptions: {
        module: ts.ModuleKind.CommonJS,
        target: ts.ScriptTarget.ES2022,
        esModuleInterop: true,
      },
    },
  ).outputText;
  vm.runInNewContext(code, {
    module,
    exports: module.exports,
    Intl,
    require: (id) => {
      assert.ok(id in mocks, id);
      return { __esModule: true, ...mocks[id] };
    },
  });
  return module.exports;
}

// Values made inside the sandbox have the sandbox's own Array/Object, so compare plain copies.
const plain = (value) => JSON.parse(JSON.stringify(value));

const utils = load("./tickets.utils.ts", {});
const { canChangePenalty, PENALTY_CHANGE_REASONS } = utils;

const ticket = {
  type: "Ticket",
  status: "Pending",
  proofUrls: [],
  ticketReceipts: [],
  communityServiceLogs: [],
};

test("the Change penalty button shows only for open tickets with nothing recorded yet", () => {
  assert.equal(canChangePenalty(ticket), true);
  assert.equal(canChangePenalty({ ...ticket, status: "Overdue" }), true);
  for (const status of ["Paid", "Cleared", "Waived", "Contested", "InProgress"])
    assert.equal(canChangePenalty({ ...ticket, status }), false, status);
  assert.equal(canChangePenalty({ ...ticket, type: "Warning" }), false);
  assert.equal(
    canChangePenalty({ ...ticket, proofUrls: ["https://storage.example.com/receipt.png"] }),
    false,
  );
  assert.equal(
    canChangePenalty({
      ...ticket,
      communityServiceLogs: [{ serviceDate: "2026-11-20", hoursWorked: 1, proofUrl: null }],
    }),
    false,
  );
  assert.equal(canChangePenalty({ ...ticket, proofUrls: ["", "  "] }), true);
  assert.equal(canChangePenalty(undefined), false);
});

test("the three reasons are the exact labels from the spec, in order", () => {
  assert.deepEqual(
    plain(PENALTY_CHANGE_REASONS.map((reason) => [reason.value, reason.label])),
    [
      ["CannotPayCashFine", "Violator can't pay the cash fine"],
      ["RequestedDifferentPenalty", "Violator asked for a different penalty"],
      ["WrongPenaltyAtIssue", "Wrong penalty chosen when issuing"],
    ],
  );
});

const options = {
  ticketId: 42,
  currentPenaltyType: "CashFine",
  allowedPenaltyTypes: ["CashFine", "CommunityService"],
  cashFineAmount: 1500,
  communityServiceHours: null,
  version: 8812,
};

function selection(...args) {
  const penaltyOptions = args.length ? args[0] : options;
  const states = [];
  let cursor = 0;
  const { usePenaltyChangeSelection } = load("./hooks/usePenaltyChangeSelection.ts", {
    react: {
      useState: (initial) => {
        const i = cursor++;
        if (!(i in states)) states[i] = initial;
        return [
          states[i],
          (value) => {
            states[i] = typeof value === "function" ? value(states[i]) : value;
          },
        ];
      },
    },
    "../tickets.utils": utils,
  });
  return () => {
    cursor = 0;
    return usePenaltyChangeSelection(penaltyOptions);
  };
}

test("the window starts on the current penalty with no reason and cannot be confirmed", () => {
  const view = selection()();
  assert.equal(view.selectedPenalty, "CashFine");
  assert.equal(view.reason, null);
  assert.equal(view.canConfirm, false);
  assert.equal(view.summary, "Select a different penalty.");
});

test("a choice the market code does not allow cannot be picked", () => {
  const render = selection();
  render().selectPenalty("BloodDonation");
  assert.equal(render().selectedPenalty, "CashFine");
});

test("community service needs whole hours of at least 3", () => {
  const render = selection();
  render().selectPenalty("CommunityService");
  render().setReason("CannotPayCashFine");
  for (const hours of ["", "2", "3.5"]) {
    render().setHours(hours);
    assert.equal(render().hoursError, "Enter at least 3 whole hours.", hours);
    assert.equal(render().canConfirm, false, hours);
  }
  for (const hours of ["3", "10"]) {
    render().setHours(hours);
    assert.equal(render().hoursError, null, hours);
    assert.equal(render().canConfirm, true, hours);
  }
});

test("a valid different penalty still needs a reason; then the summary matches the spec", () => {
  const render = selection();
  render().selectPenalty("CommunityService");
  render().setHours("10");
  assert.equal(render().canConfirm, false);
  assert.equal(render().summary, "Select a reason for the change.");
  render().setReason("CannotPayCashFine");
  assert.equal(render().canConfirm, true);
  assert.equal(
    render().summary,
    "Cash fine → Community service (10 hours). This will be recorded in the ticket history.",
  );
  assert.deepEqual(plain(render().request()), {
    penaltyType: "CommunityService",
    communityServiceHours: 10,
    reason: "CannotPayCashFine",
    version: 8812,
  });
});

test("moving off community service drops the hours and pre-fills them when it is current", () => {
  const render = selection({
    ...options,
    currentPenaltyType: "CommunityService",
    communityServiceHours: 8,
  });
  assert.equal(render().hours, "8");
  render().selectPenalty("CashFine");
  render().setReason("WrongPenaltyAtIssue");
  assert.equal(render().hoursError, null);
  assert.equal(
    render().summary,
    "Community service → Cash fine. This will be recorded in the ticket history.",
  );
  assert.deepEqual(plain(render().request()), {
    penaltyType: "CashFine",
    communityServiceHours: null,
    reason: "WrongPenaltyAtIssue",
    version: 8812,
  });
});

test("reset goes back to the current penalty with no reason", () => {
  const render = selection();
  render().selectPenalty("CommunityService");
  render().setReason("CannotPayCashFine");
  render().reset();
  assert.equal(render().selectedPenalty, "CashFine");
  assert.equal(render().reason, null);
});

test("nothing can be confirmed before the options load", () => {
  const view = selection(undefined)();
  assert.equal(view.canConfirm, false);
  assert.equal(view.selectedPenalty, undefined);
});

class ApiRequestError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

function api() {
  const calls = [];
  const client = {
    get: async (path) => {
      calls.push(["get", path]);
      return { data: options };
    },
    patch: async (path, body) => {
      calls.push(["patch", path, body]);
      return { data: {} };
    },
  };
  const { ticketsApi } = load("../../api/endpoints/tickets.api.ts", {
    "../client": { default: client },
    "@/utils/apiErrors": { ApiRequestError },
  });
  return { ticketsApi, calls };
}

const change = {
  ticketId: 42,
  penaltyType: "CommunityService",
  communityServiceHours: 10,
  reason: "CannotPayCashFine",
  version: 8812,
};

test("a bad change is refused without calling the server", async () => {
  const { ticketsApi, calls } = api();
  for (const bad of [
    { ticketId: 0 },
    { penaltyType: "Jail" },
    { reason: undefined },
    { reason: "Other" },
    { communityServiceHours: 2 },
    { version: -1 },
  ])
    await assert.rejects(ticketsApi.changePenalty({ ...change, ...bad }), JSON.stringify(bad));
  await assert.rejects(ticketsApi.getPenaltyOptions(0));
  assert.deepEqual(calls, []);
});

test("a good change goes to the admin penalty routes; hours are sent only for community service", async () => {
  const { ticketsApi, calls } = api();
  await ticketsApi.getPenaltyOptions(42);
  await ticketsApi.changePenalty(change);
  await ticketsApi.changePenalty({ ...change, penaltyType: "CashFine", communityServiceHours: 10 });
  assert.deepEqual(plain(calls), [
    ["get", "/admin/tickets/42/penalty-options"],
    ["patch", "/admin/tickets/42/penalty", {
      penaltyType: "CommunityService",
      communityServiceHours: 10,
      reason: "CannotPayCashFine",
      version: 8812,
    }],
    ["patch", "/admin/tickets/42/penalty", {
      penaltyType: "CashFine",
      communityServiceHours: null,
      reason: "CannotPayCashFine",
      version: 8812,
    }],
  ]);
});
