import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

const ROUTES = {
  adminLogin: "/admin/login",
  loginVerification: "/auth/verify-login",
  changePassword: "/admin/change-password",
  dashboard: "/dashboard",
};

function authenticatedPath(redirectTo, mustChangePassword = false) {
  const module = { exports: {} };
  const code = ts.transpileModule(
    fs.readFileSync(new URL("./useTwoFactorLogin.ts", import.meta.url), "utf8"),
    {
      compilerOptions: {
        module: ts.ModuleKind.CommonJS,
        target: ts.ScriptTarget.ES2022,
        esModuleInterop: true,
      },
    },
  ).outputText;
  const mocks = {
    react: {
      useEffect: () => {},
      useRef: (initial) => ({ current: initial }),
      useState: (initial) => [initial, () => {}],
    },
    "react-router-dom": {
      useLocation: () => ({ state: { redirectTo } }),
      useNavigate: () => () => {},
    },
    "@/context/AuthContext": {
      useAuth: () => ({
        loginChallenge: null,
        verifyLogin: async () => {},
        resendLogin: async () => {},
        cancelLogin: () => {},
        isAuthenticated: true,
        user: { role: "HeadAdmin" },
        mustChangePassword,
      }),
    },
    "@/api/types/common.types": {
      STAFF_ROLES: ["HeadAdmin", "AdminOfficer", "MarketEnforcer"],
    },
    "@/routes/routePaths": { ROUTES },
    "@/utils/roles": { roleHomePath: () => ROUTES.dashboard },
    "@/utils/apiErrors": { getApiErrorMessage: (_e, fallback) => fallback },
    "./useOtpInput": {
      useOtpInput: () => ({ code: [], reset() {}, focusFirst() {} }),
    },
  };
  vm.runInNewContext(code, {
    module,
    exports: module.exports,
    Date,
    Math,
    Number,
    String,
    Boolean,
    require: (id) => {
      assert.ok(id in mocks, id);
      return { __esModule: true, ...mocks[id] };
    },
  });
  return module.exports.useTwoFactorLogin().authenticatedPath;
}

test("signing in never returns to the change-password page once no change is required", () => {
  assert.equal(authenticatedPath(ROUTES.changePassword), ROUTES.dashboard);
});

test("signing in still returns to another page the person was on", () => {
  assert.equal(authenticatedPath("/profile"), "/profile");
});

test("an account that must change its password is still sent to the change-password page", () => {
  assert.equal(authenticatedPath("/profile", true), ROUTES.changePassword);
});
