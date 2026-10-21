import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

function load(file, dependencies) {
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
    Error,
    require: (id) => {
      assert.ok(id in dependencies, `Missing dependency: ${id}`);
      return { __esModule: true, ...dependencies[id] };
    },
  });
  return module.exports;
}

const errors = load("../../utils/apiErrors.ts", {
  axios: { default: { isAxiosError: () => false } },
});
const routes = load("../../routes/routePaths.ts", {});
const invalidVersions = [
  undefined,
  null,
  "1200",
  0,
  -1,
  1.5,
  NaN,
  Infinity,
  Number.MAX_SAFE_INTEGER + 1,
];
const registration = {
  registrationId: 42,
  version: 1200,
  status: "Pending",
  documents: [],
};

function apiHarness() {
  let response, failure;
  const calls = [];
  const { adminVendorsApi } = load("../../api/endpoints/adminVendors.api.ts", {
    "@/utils/apiErrors": errors,
    "@/api/client": {
      default: {
        get: async (...args) => {
          calls.push(args);
          return { data: response };
        },
        post: async (...args) => {
          calls.push(args);
          if (failure) throw failure;
          return { data: response };
        },
      },
    },
  });
  return {
    api: adminVendorsApi,
    calls,
    respond: (value) => {
      response = value;
    },
    fail: (error) => {
      failure = error;
    },
  };
}

test("list and details reject missing or invalid versions", async () => {
  const h = apiHarness();
  for (const version of invalidVersions) {
    h.respond({
      items: [{ ...registration, version }],
      hasMore: false,
      total: 1,
    });
    await assert.rejects(
      h.api.getRegistrationRequests({ offset: 0 }),
      /version/i,
    );
    h.respond({ ...registration, version });
    await assert.rejects(h.api.getRegistrationDetails(42), /version/i);
  }
});

test("GET preserves database versions and list filters", async () => {
  const h = apiHarness();
  const page = { items: [registration], hasMore: false, total: 1 };
  h.respond(page);
  assert.equal(
    await h.api.getRegistrationRequests({
      offset: 0,
      status: "Pending",
      vendorType: "Public",
    }),
    page,
  );
  assert.equal(h.calls[0][0], "/admin/vendors/registration-requests");
  assert.equal(h.calls[0][1].params.vendorType, "Public");
  h.respond({ ...registration, version: 1307 });
  assert.equal((await h.api.getRegistrationDetails(42)).version, 1307);
});

test("an empty registration list remains a valid empty state", async () => {
  const h = apiHarness();
  const page = { items: [], hasMore: false, total: 0 };
  h.respond(page);
  assert.equal(await h.api.getRegistrationRequests({ offset: 0 }), page);
});

test("all review endpoints reject invalid versions before sending requests", async () => {
  const h = apiHarness();
  for (const method of [
    "approveRegistration",
    "declineRegistration",
    "requestMoreInformation",
  ]) {
    for (const version of invalidVersions) {
      await assert.rejects(
        h.api[method]({
          vendorRegistrationId: 42,
          version,
          reviewReason: "Expired document",
          reviewRemarks: "Upload a current permit.",
        }),
        /version/i,
      );
    }
  }
  assert.equal(h.calls.length, 0);
});

function actionHarness(mode) {
  const states = [],
    refs = [],
    toasts = [],
    navigations = [];
  let stateCursor = 0,
    refCursor = 0,
    currentDetails = registration,
    reloads = 0,
    reloadSucceeded = true;
  const h = apiHarness();
  const { useAdminVendorRegistrationAction } = load(
    "./hooks/useAdminVendorRegistrationAction.ts",
    {
      react: {
        useState: (initial) => {
          const index = stateCursor++;
          if (!(index in states)) states[index] = initial;
          return [
            states[index],
            (value) => {
              states[index] = value;
            },
          ];
        },
        useRef: (initial) => {
          const index = refCursor++;
          return (refs[index] ??= { current: initial });
        },
      },
      "@tanstack/react-query": {
        useQueryClient: () => ({ invalidateQueries: async () => {} }),
      },
      "@/components/ui/Toast/useToast": {
        useToast: () => ({ showToast: (toast) => toasts.push(toast) }),
      },
      "react-router-dom": {
        useNavigate: () => (path) => navigations.push(path),
      },
      "@/api/endpoints/adminVendors.api": { adminVendorsApi: h.api },
      "@/routes/routePaths": routes,
      "@/utils/apiErrors": errors,
    },
  );
  const render = () => {
    stateCursor = 0;
    refCursor = 0;
    return useAdminVendorRegistrationAction(mode, currentDetails, async () => {
      reloads++;
      return reloadSucceeded;
    });
  };
  return {
    ...h,
    render,
    toasts,
    navigations,
    setDetails: (value) => {
      currentDetails = value;
    },
    setReloadSucceeded: (value) => {
      reloadSucceeded = value;
    },
    reloads: () => reloads,
  };
}

test("each decision submits the GET version unchanged and handles email failure as success", async () => {
  for (const [mode, endpoint] of [
    ["approve", "/vendor/approve-registry"],
    ["decline", "/vendor/decline-registry"],
    ["information", "/vendor/request-more-information"],
  ]) {
    const h = actionHarness(mode);
    h.setDetails({ ...registration, version: 1307 });
    h.respond({ version: 1440, emailSent: false });
    let action = h.render();
    if (mode !== "approve") {
      action.setSelectedReason(
        mode === "decline"
          ? "Invalid or unverifiable government ID"
          : "Document is missing",
      );
      action.setRemarks("  Please upload a current document.  ");
      action = h.render();
    }
    assert.equal(await action.submit(), true);
    assert.equal(h.calls[0][0], endpoint);
    assert.equal(h.calls[0][1].vendorRegistrationId, 42);
    assert.equal(h.calls[0][1].version, 1307);
    if (mode !== "approve")
      assert.equal(
        h.calls[0][1].reviewRemarks,
        "Please upload a current document.",
      );
    assert.equal(h.toasts[0].variant, "success");
    assert.equal(h.toasts[1].variant, "warning");
    assert.equal(h.navigations.length, 1);
  }
});

test("409 preserves the server message and blocks another decision until explicit refresh", async () => {
  const h = actionHarness("approve");
  const message =
    "This registration was already reviewed by another admin. Please refresh and try again.";
  h.fail(new errors.ApiRequestError(message, 409));
  assert.equal(await h.render().submit(), false);
  let action = h.render();
  assert.equal(action.submitError, message);
  assert.equal(action.canSubmit, false);
  assert.equal(await action.submit(), false);
  h.setDetails({ ...registration, version: 1440 });
  action = h.render();
  assert.equal(action.canSubmit, false);
  await action.reloadLatestDetails();
  assert.equal(h.reloads(), 1);
  h.fail(undefined);
  h.respond({ version: 1500, emailSent: true });
  assert.equal(await h.render().submit(), true);
  assert.equal(h.calls[1][1].version, 1440);
});

test("a failed refresh cannot unblock a conflicted decision", async () => {
  const h = actionHarness("approve");
  h.fail(
    new errors.ApiRequestError("This request has already been processed.", 409),
  );
  await h.render().submit();
  h.setReloadSucceeded(false);
  await h.render().reloadLatestDetails();
  assert.equal(h.render().canSubmit, false);
  assert.equal(
    h.render().submitError,
    "This request has already been processed.",
  );
  assert.equal(h.navigations.length, 0);
});

test("missing versions and processed records cannot be submitted from actions", async () => {
  const h = actionHarness("approve");
  for (const details of [
    undefined,
    ...invalidVersions.map((version) => ({ ...registration, version })),
    { ...registration, status: "Approved" },
    { ...registration, status: "Rejected" },
  ]) {
    h.setDetails(details);
    assert.equal(h.render().canSubmit, false);
    assert.equal(await h.render().submit(), false);
  }
  assert.equal(h.calls.length, 0);
});

test("approval and rejection can decide Needs Information after an in-person submission", async () => {
  for (const mode of ["approve", "decline"]) {
    const h = actionHarness(mode);
    if (mode === "decline") {
      h.render().setSelectedReason("Invalid or unverifiable government ID");
      h.render().setRemarks("The submitted document could not be verified.");
    }
    h.setDetails({ ...registration, status: "NeedsInformation" });
    h.respond({ version: 1300, emailSent: true });
    const action = h.render();
    assert.equal(action.canSubmit, true);
    action.openConfirmation();
    assert.equal(h.render().showConfirmationModal, true);
    assert.equal(await h.render().submit(), true);
    assert.equal(h.calls.length, 1);
    assert.equal(
      h.calls[0][0],
      mode === "approve"
        ? "/vendor/approve-registry"
        : "/vendor/decline-registry",
    );
  }
});

test("rejection and information requests show field errors before confirmation", async () => {
  for (const mode of ["decline", "information"]) {
    const h = actionHarness(mode);
    let action = h.render();
    const focused = [];
    action.reasonInputRef.current = { focus: () => focused.push("reason") };
    action.remarksInputRef.current = { focus: () => focused.push("remarks") };
    assert.equal(action.reasonError, "");
    assert.equal(action.remarksError, "");
    action.openConfirmation();
    assert.equal(focused[0], "reason");
    action = h.render();
    assert.match(action.reasonError, /select/i);
    assert.match(action.remarksError, /enter/i);
    assert.equal(action.showConfirmationModal, false);
    assert.equal(await action.submit(), false);
    assert.equal(h.calls.length, 0);
    assert.equal(h.render().submitError, "");

    action.setSelectedReason(
      mode === "decline"
        ? "Invalid or unverifiable government ID"
        : "Document is missing",
    );
    action.setRemarks(" \n\t ");
    action = h.render();
    assert.equal(action.reasonError, "");
    assert.match(action.remarksError, /enter/i);
    action.openConfirmation();
    assert.equal(focused.at(-1), "remarks");
    action.setRemarks("Please upload a readable government ID.");
    action = h.render();
    assert.equal(action.remarksError, "");
    action.openConfirmation();
    assert.equal(h.render().showConfirmationModal, true);
    assert.equal(h.calls.length, 0);
    h.render().closeConfirmation();
    assert.equal(h.render().showConfirmationModal, false);
    assert.equal(h.render().remarks, "Please upload a readable government ID.");
  }
});

test("confirmation blocks duplicate submission and closing while preserving a failed draft", async () => {
  for (const mode of ["decline", "information"]) {
    const h = actionHarness(mode);
    h.render().setSelectedReason(
      mode === "decline"
        ? "Invalid or unverifiable government ID"
        : "Document is missing",
    );
    h.render().setRemarks("Upload a readable government ID.\u0000");
    h.render().openConfirmation();
    assert.equal(h.render().showConfirmationModal, true);
    h.fail(
      new errors.ApiRequestError(
        "The notification service is unavailable.",
        503,
      ),
    );
    const pending = h.render().submit();
    h.render().closeConfirmation();
    assert.equal(h.render().showConfirmationModal, true);
    assert.equal(await h.render().submit(), false);
    h.render().setRemarks("Changed while submitting");
    assert.equal(await pending, false);
    assert.equal(h.calls.length, 1);
    assert.equal(h.render().showConfirmationModal, false);
    assert.equal(h.render().remarks, "Upload a readable government ID.");
    assert.equal(
      h.render().submitError,
      "The notification service is unavailable.",
    );
  }
});

test("blur validates remarks and invalid reasons or overlong messages never reach the API", async () => {
  for (const mode of ["decline", "information"]) {
    const h = actionHarness(mode);
    h.render().validateRemarks();
    assert.match(h.render().remarksError, /enter/i);
    h.render().setSelectedReason("Unrecognized reason");
    h.render().setRemarks("x".repeat(2001));
    assert.equal(await h.render().submit(), false);
    assert.match(h.render().reasonError, /select/i);
    assert.match(h.render().remarksError, /2,000/);
    assert.equal(h.calls.length, 0);
    h.render().setSelectedReason(
      mode === "decline"
        ? "Invalid or unverifiable government ID"
        : "Document is missing",
    );
    h.render().setRemarks("a".repeat(2000));
    h.respond({ emailSent: true });
    assert.equal(await h.render().submit(), true);
    assert.equal(h.calls[0][1].reviewRemarks.length, 2000);
  }
});
