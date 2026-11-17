import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

function load(file, mocks) {
  const module = { exports: {} };
  const code = ts.transpileModule(
    fs.readFileSync(new URL(file, import.meta.url), "utf8"),
    {
      compilerOptions: {
        module: ts.ModuleKind.CommonJS,
        target: ts.ScriptTarget.ES2022,
        jsx: ts.JsxEmit.ReactJSX,
        esModuleInterop: true,
      },
    },
  ).outputText;
  vm.runInNewContext(code, {
    module,
    exports: module.exports,
    require: (id) => {
      assert.ok(id in mocks, id);
      return { __esModule: true, ...mocks[id] };
    },
  });
  return module.exports;
}

// JSX becomes plain { type, props } objects so the rendered options can be read.
const element = (type, props) => ({ type, props });
const jsxRuntime = { jsx: element, jsxs: element, Fragment: "Fragment" };

function options(tree, found = []) {
  if (Array.isArray(tree)) tree.forEach((child) => options(child, found));
  else if (tree && typeof tree === "object") {
    if (tree.type === RecoveryOption) found.push(tree.props);
    options(tree.props?.children, found);
  }
  return found;
}

function RecoveryOption() {}
const RecoveryOptionsPage = load(
  "./components/recovery/RecoveryOptionsPage.tsx",
  {
    "react/jsx-runtime": jsxRuntime,
    "lucide-react": { AtSign: "AtSign", LockKeyhole: "LockKeyhole" },
    "./RecoveryOption": { default: RecoveryOption },
    "./RecoveryOptionsSkeleton": {
      default: function RecoveryOptionsSkeleton() {},
    },
    "./RecoveryOptionsPage.module.css": { default: {} },
  },
).default;

function renderOptions() {
  const selected = [];
  let backToLogin = 0;
  const tree = RecoveryOptionsPage({
    loading: false,
    error: "",
    // The server's lookup still returns a masked phone number.
    account: {
      maskedEmail: "e***@example.com",
      maskedPhoneNumber: "091****3309",
    },
    onSelect: (channel) => selected.push(channel),
    onBackToLogin: () => backToLogin++,
    onTryAgain: () => {},
  });
  return { found: options(tree), selected, backToLogin: () => backToLogin };
}

test("the options page offers email and password only, even when the account has a phone number", () => {
  const { found } = renderOptions();
  assert.deepEqual(
    found.map((option) => option.title),
    ["Reset via Email", "Continue with password"],
  );
});

test("choosing email selects the email channel", () => {
  const view = renderOptions();
  view.found.find((o) => o.title === "Reset via Email").onSelect();
  assert.deepEqual(view.selected, ["email"]);
});

test("continue with password goes back to login", () => {
  const view = renderOptions();
  view.found.find((o) => o.title === "Continue with password").onSelect();
  assert.equal(view.backToLogin(), 1);
});

function recoveryAt(step, state) {
  const usePasswordRecovery = load("./hooks/usePasswordRecovery.ts", {
    "@tanstack/react-query": {
      useQuery: () => ({
        data: undefined,
        isError: false,
        isPending: false,
        isFetching: false,
      }),
    },
    react: { useEffect: () => {}, useRef: (current) => ({ current }) },
    "react-router-dom": {
      useParams: () => ({ step }),
      useLocation: () => ({ state }),
      useNavigate: () => () => {},
    },
    "@/api/endpoints/auth.api": { authApi: {} },
    "@/routes/routePaths": {
      ROUTES: {
        forgotPassword: "/admin/forgot-password",
        adminLogin: "/admin/login",
      },
    },
    "@/utils/apiErrors": { getApiErrorMessage: () => "" },
  }).usePasswordRecovery;
  return usePasswordRecovery();
}

test("a code page opened with the old sms channel is not accepted", () => {
  const view = recoveryAt("verify", {
    username: "ENF0001-2026",
    channel: "sms",
  });
  assert.equal(view.invalidFlow, true);
});

test("the code page for email is titled Check your email", () => {
  const view = recoveryAt("verify", {
    username: "ENF0001-2026",
    channel: "email",
  });
  assert.equal(view.invalidFlow, false);
  assert.equal(view.title, "Check your email");
});
