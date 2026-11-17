import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import test from "node:test";
import vm from "node:vm";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { StaticRouter } from "react-router-dom/server.js";
import ts from "typescript";

const require = createRequire(import.meta.url);
const realRouter = require("react-router-dom");
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

function load(relative, overrides = {}, cache = new Map()) {
  const file = path.resolve(root, relative);
  if (cache.has(file)) return cache.get(file);
  const module = { exports: {} };
  cache.set(file, module.exports);
  const code = ts.transpileModule(fs.readFileSync(file, "utf8"), {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
      jsx: ts.JsxEmit.ReactJSX,
      esModuleInterop: true,
    },
  }).outputText;
  vm.runInNewContext(
    code,
    {
      module,
      exports: module.exports,
      Date,
      require(id) {
        if (id in overrides) return { __esModule: true, ...overrides[id] };
        if (id.endsWith(".css"))
          return {
            __esModule: true,
            default: new Proxy({}, { get: (_, key) => key }),
          };
        if (!id.startsWith(".") && !id.startsWith("@/")) return require(id);
        const base = id.startsWith("@/")
          ? path.resolve(root, id.slice(2))
          : path.resolve(path.dirname(file), id);
        const resolved = [
          base,
          `${base}.ts`,
          `${base}.tsx`,
          `${base}/index.ts`,
        ].find(
          (candidate) =>
            fs.existsSync(candidate) && fs.statSync(candidate).isFile(),
        );
        assert.ok(resolved, `Cannot resolve ${id}`);
        const alias = `@/${path
          .relative(root, resolved)
          .replaceAll("\\", "/")
          .replace(/\.tsx?$/, "")}`;
        if (alias in overrides)
          return { __esModule: true, ...overrides[alias] };
        return load(path.relative(root, resolved), overrides, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

// ---------------------------------------------------------------------------
// The website's address list
// ---------------------------------------------------------------------------

function pageStub(name) {
  const Page = () => React.createElement("div", { "data-page": name });
  return {
    default: Page,
    DashboardPage: Page,
    InspectionsPage: Page,
    ReportsPage: Page,
    AdminPersonsPage: Page,
  };
}

const pageModules = [
  "features/auth/pages/LoginPage",
  "features/auth/pages/AdminLoginPage",
  "features/auth/pages/LoginVerificationPage",
  "features/auth/pages/ForgotPasswordPage",
  "features/auth/pages/ChangePasswordPage",
  "features/dashboard/pages/DashboardPage",
  "features/tickets/pages/TicketsPage",
  "features/tickets/pages/TicketDetailPage",
  "features/vendors/pages/VendorPage",
  "features/vendors/pages/VendorDetailPage",
  "features/vendors/pages/VendorRegistrationPage",
  "features/inspections/pages/InspectionsPage",
  "features/enforcers/pages/EnforcersPage",
  "features/enforcers/pages/EnforcerPerformancePage",
  "features/vendors/pages/AdminVendorsPage",
  "features/vendors/pages/AdminVendorInspectionPage",
  "features/vendors/pages/AdminVendorRegistrationsPage",
  "features/vendors/pages/AdminVendorRegistrationReviewPage",
  "features/vendors/pages/AdminVendorRegistrationApprovePage",
  "features/vendors/pages/AdminVendorRegistrationDeclinePage",
  "features/vendors/pages/AdminVendorRegistrationInformationPage",
  "features/analytics/pages/AdminAnalyticsPage",
  "features/recommendations/pages/RecommendationsPage",
  "features/configuration/pages/SystemConfigurationPage",
  "features/market-section/pages/MarketSectionPage",
  "features/ordinances/pages/OrdinancesPage",
  "features/backups/pages/BackupsPage",
  "features/accounts/pages/AccountsPage",
  "features/profile/pages/ProfilePage",
  "features/audit/pages/AuditLogsPage",
  "features/reports",
  "features/persons",
];

function renderRoutesAt(location) {
  const overrides = {
    "react-router-dom": {
      ...realRouter,
      Navigate: ({ to }) => React.createElement("div", { "data-redirect": to }),
    },
    "@/components/layout/DashboardLayout": { default: realRouter.Outlet },
    "./ProtectedRoute": {
      default: ({ children }) => children,
    },
  };
  for (const module of pageModules)
    overrides[`@/${module}`] = pageStub(module.split("/").pop());
  const { default: AppRoutes } = load("routes/AppRoutes.tsx", overrides);
  return renderToStaticMarkup(
    React.createElement(
      StaticRouter,
      { location },
      React.createElement(AppRoutes),
    ),
  );
}

test("old vendor sign-up and vendor login addresses lead to the administrator login", () => {
  for (const address of [
    "/register",
    "/vendor/register",
    "/login",
    "/forgot-password/find-account",
    "/admin/vendor-registrations",
    "/admin/vendor-registrations/review/5",
    "/admin/vendor-registrations/review/5/approve",
    "/admin/vendor-registrations/review/5/decline",
    "/admin/vendor-registrations/review/5/request-information",
  ]) {
    const html = renderRoutesAt(address);
    assert.match(html, /data-redirect="\/admin\/login"/, address);
    assert.doesNotMatch(html, /data-page=/, address);
  }
});

test("the home address opens the login page, with no landing page left", () => {
  const html = renderRoutesAt("/");
  assert.match(html, /data-redirect="\/admin\/login"/);
  assert.doesNotMatch(html, /data-page=/);
  assert.ok(
    !fs.existsSync(path.resolve(root, "features/landing")),
    "the landing page folder must be gone",
  );
});

test("the administrator pages that stay still open at their addresses", () => {
  const expected = {
    "/admin/login": "AdminLoginPage",
    "/admin/forgot-password/find-account": "ForgotPasswordPage",
    "/auth/verify-login": "LoginVerificationPage",
    "/dashboard": "DashboardPage",
    "/admin/vendors": "AdminVendorsPage",
    "/admin/persons": "persons",
    "/tickets": "TicketsPage",
  };
  for (const [address, page] of Object.entries(expected))
    assert.match(
      renderRoutesAt(address),
      new RegExp(`data-page="${page}"`),
      address,
    );
});

test("the address list has no sign-up, vendor login or review addresses left", () => {
  const { ROUTES } = load("routes/routePaths.ts");
  for (const key of [
    "home",
    "login",
    "register",
    "vendorRegister",
    "adminVendorRegistrations",
    "adminVendorRegistration",
    "adminVendorRegistrationApprove",
    "adminVendorRegistrationDecline",
    "adminVendorRegistrationInformation",
  ])
    assert.ok(!(key in ROUTES), `ROUTES.${key} must be gone`);
  assert.equal(ROUTES.forgotPassword, "/admin/forgot-password");
  assert.equal(ROUTES.adminLogin, "/admin/login");
});

// ---------------------------------------------------------------------------
// Home page and login form
// ---------------------------------------------------------------------------

function renderLoginPage() {
  const sealOverride = {
    "@/assets/icons/Marikina_City_Seal.svg (1).webp": { default: "seal.webp" },
  };
  const { default: AuthLayout } = load(
    "features/auth/components/AuthLayout.tsx",
    sealOverride,
  );
  const { default: LoginForm } = load("features/auth/components/LoginForm.tsx");
  return renderToStaticMarkup(
    React.createElement(
      StaticRouter,
      null,
      React.createElement(
        AuthLayout,
        null,
        React.createElement(LoginForm, {
          submit: async () => {},
          loading: false,
          error: null,
        }),
      ),
    ),
  );
}

test("the login page's navy panel says what the system is for and tells staff how to get an account", () => {
  const html = renderLoginPage();
  assert.match(html, /MARIKINA CITY · PUBLIC MARKET/);
  assert.match(html, /Market inspections, tickets and records in one place\./);
  assert.match(html, /Inspections and tickets recorded in the field/);
  assert.match(html, /Business and person records kept together/);
  assert.match(html, /Reports, analytics and a full audit trail/);
  assert.match(
    html,
    /Need an account\? Ask your Head Admin to add one for you\./,
  );
  assert.doesNotMatch(
    html,
    /Business owner|do not have (system )?login accounts/,
  );
  assert.doesNotMatch(html, /Admin Access/);
});

test("the login form says Log in, explains the emailed code and keeps Forgot password", () => {
  const html = renderLoginPage();
  assert.match(html, /<h2[^>]*>Log in<\/h2>/);
  assert.match(
    html,
    /Administrator access\. Use your staff username and password\./,
  );
  assert.match(html, /<button type="submit"[^>]*>Log in<\/button>/);
  assert.match(
    html,
    /Next, we email you a 6-digit code to finish logging in\./,
  );
  assert.match(html, />Forgot password\?<\/button>/);
  assert.doesNotMatch(html, /LOGIN/);
});

test("the login form offers no account creation", () => {
  const { default: LoginForm } = load("features/auth/components/LoginForm.tsx");
  const html = renderToStaticMarkup(
    React.createElement(
      StaticRouter,
      null,
      React.createElement(LoginForm, {
        submit: async () => {},
        loading: false,
        error: null,
      }),
    ),
  );
  assert.match(html, /Forgot password\?/);
  assert.doesNotMatch(html, /Create one|have an account/);
});

// ---------------------------------------------------------------------------
// Forgot-password steps in the login frame
// ---------------------------------------------------------------------------

function stepStub(step) {
  return { default: () => React.createElement("div", { "data-step": step }) };
}

function renderForgotPasswordAt(step, state) {
  const overrides = {
    "@/assets/icons/Marikina_City_Seal.svg (1).webp": { default: "seal.webp" },
    "@tanstack/react-query": {
      useQuery: () => ({
        data: undefined,
        isError: false,
        isPending: false,
        isFetching: false,
      }),
    },
    "@/api/endpoints/auth.api": { authApi: {} },
    "@/features/auth/components/recovery/AccountLookupPage":
      stepStub("find-account"),
    "@/features/auth/components/recovery/RecoveryOptionsPage":
      stepStub("options"),
    "@/features/auth/components/recovery/VerifyCodePage": stepStub("verify"),
    "@/features/auth/components/recovery/ResetPasswordPage": stepStub("reset"),
  };
  const { default: ForgotPasswordPage } = load(
    "features/auth/pages/ForgotPasswordPage.tsx",
    overrides,
  );
  return renderToStaticMarkup(
    React.createElement(
      StaticRouter,
      { location: { pathname: `/admin/forgot-password/${step}`, state } },
      React.createElement(
        realRouter.Routes,
        null,
        React.createElement(realRouter.Route, {
          path: "/admin/forgot-password/:step",
          element: React.createElement(ForgotPasswordPage),
        }),
      ),
    ),
  );
}

test("the forgot-password page uses the login frame: navy panel, Head Admin note, no Admin Access", () => {
  const html = renderForgotPasswordAt("find-account", null);
  assert.match(html, /MARIKINA CITY · PUBLIC MARKET/);
  assert.match(html, /Market inspections, tickets and records in one place\./);
  assert.match(
    html,
    /Need an account\? Ask your Head Admin to add one for you\./,
  );
  assert.doesNotMatch(html, /Admin Access/);
  assert.match(html, /<a[^>]*href="\/admin\/login"[^>]*>.*Back to log in<\/a>/);
  assert.match(html, /data-step="find-account"/);
});

test("each forgot-password step shows in the frame with a heading in the Log in style", () => {
  const steps = [
    ["find-account", null, "Find your account"],
    ["options", { username: "ADM9012-2026" }, "Forgot password"],
    [
      "verify",
      { username: "ADM9012-2026", channel: "email", maskedEmail: "a***@x.com" },
      "Check your email",
    ],
    [
      "reset",
      { username: "ADM9012-2026", resetToken: "token-123" },
      "Create new password",
    ],
  ];
  for (const [step, state, heading] of steps) {
    const html = renderForgotPasswordAt(step, state);
    assert.match(html, new RegExp(`data-step="${step}"`), step);
    assert.match(html, new RegExp(`<h2[^>]*>${heading}</h2>`), step);
    assert.doesNotMatch(html, new RegExp(heading.toUpperCase()), step);
    assert.match(html, /MARIKINA CITY · PUBLIC MARKET/, step);
  }
});

// ---------------------------------------------------------------------------
// Code page, change-password page and sidebar headings
// ---------------------------------------------------------------------------

const seal = {
  "@/assets/icons/Marikina_City_Seal.svg (1).webp": { default: "seal.webp" },
};
const noop = () => {};

function renderInRouter(element) {
  return renderToStaticMarkup(
    React.createElement(StaticRouter, { location: "/dashboard" }, element),
  );
}

test("the 6-digit code page heading is in the Log in style, without the shield icon", () => {
  const { default: LoginVerificationPage } = load(
    "features/auth/pages/LoginVerificationPage.tsx",
    {
      ...seal,
      "@/features/auth/components/OtpCodeInput": {
        default: () => React.createElement("div", { "data-otp": true }),
      },
      "@/features/auth/hooks/useTwoFactorLogin": {
        useTwoFactorLogin: () => ({
          isAuthenticated: false,
          loginChallenge: { maskedEmail: "a***@example.invalid" },
          cancel: noop,
          verify: noop,
          resend: noop,
          verifying: false,
          resending: false,
          canVerify: false,
          canResend: false,
          resendLabel: "Resend",
          expired: false,
          notice: "",
          error: "",
          otp: {},
        }),
      },
    },
  );
  const html = renderInRouter(React.createElement(LoginVerificationPage));
  assert.match(html, /<h2[^>]*>Sign-in verification<\/h2>/);
  assert.doesNotMatch(html, /SIGN-IN VERIFICATION/);
  assert.doesNotMatch(html, /lucide-shield-check/);
  assert.match(html, /a\*\*\*@example\.invalid/);
});

test("the change-password page heading is in the Log in style", () => {
  const { default: ChangePasswordPage } = load(
    "features/auth/pages/ChangePasswordPage.tsx",
    {
      ...seal,
      "@/features/auth/hooks/useMandatoryChangePassword": {
        useMandatoryChangePassword: () => ({
          backToSignIn: noop,
          submit: async () => null,
          change: noop,
          toggleShown: noop,
          loading: false,
          error: "",
          fieldErrors: {},
          shown: {},
          values: {
            currentPassword: "",
            newPassword: "",
            confirmNewPassword: "",
          },
        }),
      },
    },
  );
  const html = renderInRouter(React.createElement(ChangePasswordPage));
  assert.match(html, /<h2[^>]*>Change password<\/h2>/);
  assert.doesNotMatch(html, /CHANGE PASSWORD/);
  assert.match(html, /change the temporary password you were given/);
});

test("the sidebar shows the system name without Admin Access", () => {
  const { default: Sidebar } = load("components/layout/Sidebar/Sidebar.tsx", {
    ...seal,
    "@/components/ui/UrlImage": { default: () => null },
    "@/context/AuthContext": {
      useAuth: () => ({
        user: {
          role: "HeadAdmin",
          firstName: "Test",
          lastName: "Admin",
          username: "ADM9014-2026",
        },
        logout: noop,
      }),
    },
  });
  const html = renderInRouter(
    React.createElement(Sidebar, { open: false, collapsed: false, onClose: noop }),
  );
  assert.match(html, /Marikina Public Market Inspection System/);
  assert.match(html, /Accounts/);
  assert.doesNotMatch(html, /Admin Access/);
});
