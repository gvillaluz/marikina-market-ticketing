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
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

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
        const resolved = [base, `${base}.ts`, `${base}.tsx`, `${base}/index.ts`].find(
          (candidate) => fs.existsSync(candidate) && fs.statSync(candidate).isFile(),
        );
        assert.ok(resolved, `Cannot resolve ${id}`);
        const alias = `@/${path
          .relative(root, resolved)
          .replaceAll("\\", "/")
          .replace(/\.tsx?$/, "")}`;
        if (alias in overrides) return { __esModule: true, ...overrides[alias] };
        return load(path.relative(root, resolved), overrides, cache);
      },
    },
    { filename: file },
  );
  return module.exports;
}

const seal = {
  "@/assets/icons/Marikina_City_Seal.svg (1).webp": { default: "seal.webp" },
};
const ADDRESSES = {
  login: "/admin/login",
  code: "/auth/verify-login",
  change: "/admin/change-password",
  find: "/admin/forgot-password/find-account",
  options: "/admin/forgot-password/options",
  verify: "/admin/forgot-password/verify",
  reset: "/admin/forgot-password/reset",
};

// ---------------------------------------------------------------------------
// Which way a page slides
// ---------------------------------------------------------------------------

test("the login journey is ordered: log in, code, change password; and the four forgot-password steps", () => {
  const { authStepRank } = load("features/auth/motion.ts");
  assert.ok(authStepRank(ADDRESSES.login) < authStepRank(ADDRESSES.code));
  assert.ok(authStepRank(ADDRESSES.code) < authStepRank(ADDRESSES.change));
  assert.ok(authStepRank(ADDRESSES.login) < authStepRank(ADDRESSES.find));
  assert.ok(authStepRank(ADDRESSES.find) < authStepRank(ADDRESSES.options));
  assert.ok(authStepRank(ADDRESSES.options) < authStepRank(ADDRESSES.verify));
  assert.ok(authStepRank(ADDRESSES.verify) < authStepRank(ADDRESSES.reset));
});

test("going to a later page is forward and going to an earlier page is back", () => {
  const { authStepRank, slideDirection } = load("features/auth/motion.ts");
  const dir = (from, to) =>
    slideDirection(authStepRank(from), authStepRank(to));
  assert.equal(dir(ADDRESSES.login, ADDRESSES.code), "forward");
  assert.equal(dir(ADDRESSES.code, ADDRESSES.change), "forward");
  assert.equal(dir(ADDRESSES.find, ADDRESSES.options), "forward");
  assert.equal(dir(ADDRESSES.options, ADDRESSES.find), "back");
  assert.equal(dir(ADDRESSES.reset, ADDRESSES.verify), "back");
  assert.equal(dir(ADDRESSES.code, ADDRESSES.login), "back");
  assert.equal(dir(ADDRESSES.find, ADDRESSES.login), "back");
  assert.equal(dir(ADDRESSES.login, ADDRESSES.find), "forward");
});

function useAuthSlideAt() {
  const refs = [];
  let cursor = 0;
  let pathname = ADDRESSES.login;
  const { useAuthSlide } = load("features/auth/hooks/useAuthSlide.ts", {
    react: {
      useRef(initial) {
        const i = cursor++;
        if (!(i in refs)) refs[i] = { current: initial };
        return refs[i];
      },
    },
    "react-router-dom": { useLocation: () => ({ pathname }) },
  });
  return (next) => {
    cursor = 0;
    if (next) pathname = next;
    return useAuthSlide();
  };
}

test("the first page has no slide of its own (the opening sequence plays instead); later pages slide the way you are going", () => {
  const at = useAuthSlideAt();
  assert.equal(at().direction, null);
  assert.equal(at().direction, null);
  let view = at(ADDRESSES.code);
  assert.equal(view.direction, "forward");
  assert.equal(view.pathname, ADDRESSES.code);
  view = at(ADDRESSES.login);
  assert.equal(view.direction, "back");
  view = at(ADDRESSES.find);
  assert.equal(view.direction, "forward");
  view = at(ADDRESSES.options);
  assert.equal(view.direction, "forward");
  view = at(ADDRESSES.find);
  assert.equal(view.direction, "back");
});

test("drawing the same page again keeps its slide", () => {
  const at = useAuthSlideAt();
  at();
  const first = at(ADDRESSES.code);
  const again = at();
  assert.equal(again.direction, first.direction);
  assert.equal(again.pathname, first.pathname);
});

// ---------------------------------------------------------------------------
// The shared frame
// ---------------------------------------------------------------------------

function renderFrameAt(address, element) {
  const { default: AuthLayout } = load(
    "features/auth/components/AuthLayout.tsx",
    seal,
  );
  return renderToStaticMarkup(
    React.createElement(
      StaticRouter,
      { location: address },
      React.createElement(
        realRouter.Routes,
        null,
        React.createElement(
          realRouter.Route,
          { element: React.createElement(AuthLayout) },
          React.createElement(realRouter.Route, { path: "*", element }),
        ),
      ),
    ),
  );
}

test("the frame holds the navy panel and the card once, and shows the page inside the card", () => {
  const html = renderFrameAt(
    ADDRESSES.login,
    React.createElement("div", { "data-page": "inside" }),
  );
  assert.equal(html.split('alt="Marikina City seal"').length - 1, 1);
  assert.match(html, /MARIKINA CITY · PUBLIC MARKET/);
  assert.match(
    html,
    /Need an account\? Ask your Head Admin to add one for you\./,
  );
  const card = html.indexOf("contentInner");
  assert.ok(card > 0, "the card is there");
  assert.ok(html.indexOf('data-page="inside"') > card, "page is inside the card");
});

test("the first page opens without a sideways slide", () => {
  const html = renderFrameAt(
    ADDRESSES.login,
    React.createElement("div", { "data-page": "inside" }),
  );
  assert.doesNotMatch(html, /data-direction=/);
});

test("the frame no longer takes the page as a child", () => {
  const source = fs.readFileSync(
    path.resolve(root, "features/auth/components/AuthLayout.tsx"),
    "utf8",
  );
  assert.match(source, /<Outlet \/>/);
  assert.doesNotMatch(source, /children/);
});

test("none of the four login pages builds its own frame any more", () => {
  for (const page of [
    "AdminLoginPage",
    "LoginVerificationPage",
    "ChangePasswordPage",
    "ForgotPasswordPage",
  ]) {
    const source = fs.readFileSync(
      path.resolve(root, `features/auth/pages/${page}.tsx`),
      "utf8",
    );
    assert.doesNotMatch(source, /AuthLayout/, page);
  }
});

// ---------------------------------------------------------------------------
// Motion turned off
// ---------------------------------------------------------------------------

test("with motion turned off, the opening sequence and the slides do not animate", () => {
  const css = fs.readFileSync(
    path.resolve(root, "features/auth/components/AuthLayout.module.css"),
    "utf8",
  );
  const start = css.indexOf("@media (prefers-reduced-motion: reduce)");
  assert.ok(start > 0, "there is a reduced-motion block");
  const block = css.slice(start);
  for (const selector of [
    ".brand",
    ".eyebrow",
    ".headline",
    ".feature",
    ".watermark",
    ".contentInner",
    // The slide rules name the direction, so the switch-off must be as specific.
    ".slide[data-direction]",
  ])
    assert.ok(block.includes(selector), `${selector} stops animating`);
  assert.match(block, /animation:\s*none/);
});

// ---------------------------------------------------------------------------
// Step counter on the forgot-password steps
// ---------------------------------------------------------------------------

test("the step counter says which step you are on and fills the bar to match", () => {
  const { default: StepProgress } = load(
    "features/auth/components/recovery/StepProgress.tsx",
  );
  const html = renderToStaticMarkup(
    React.createElement(StepProgress, { step: 2, total: 4 }),
  );
  assert.match(html, /Step 2 of 4/);
  assert.match(html, /width:50%/);
  const last = renderToStaticMarkup(
    React.createElement(StepProgress, { step: 4, total: 4 }),
  );
  assert.match(last, /Step 4 of 4/);
  assert.match(last, /width:100%/);
});

function recoveryAt(step, state) {
  const { usePasswordRecovery } = load(
    "features/auth/hooks/usePasswordRecovery.ts",
    {
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
      "@/utils/apiErrors": { getApiErrorMessage: () => "" },
    },
  );
  return usePasswordRecovery();
}

test("the four forgot-password steps are numbered 1 to 4 of 4", () => {
  const user = { username: "ADM9012-2026" };
  const steps = [
    [undefined, null, 1],
    ["find-account", null, 1],
    ["options", user, 2],
    ["verify", { ...user, channel: "email" }, 3],
    ["reset", { ...user, resetToken: "token-123" }, 4],
  ];
  for (const [step, state, number] of steps) {
    const view = recoveryAt(step, state);
    assert.equal(view.stepNumber, number, String(step));
    assert.equal(view.stepCount, 4, String(step));
  }
});

function stepStub(step) {
  return { default: () => React.createElement("div", { "data-step": step }) };
}

function renderForgotPasswordAt(step, state) {
  const { default: ForgotPasswordPage } = load(
    "features/auth/pages/ForgotPasswordPage.tsx",
    {
      "@tanstack/react-query": {
        useQuery: () => ({
          data: undefined,
          isError: false,
          isPending: false,
          isFetching: false,
        }),
      },
      "@/api/endpoints/auth.api": { authApi: {} },
      "@/features/auth/components/recovery/AccountLookupPage": stepStub("find-account"),
      "@/features/auth/components/recovery/RecoveryOptionsPage": stepStub("options"),
      "@/features/auth/components/recovery/VerifyCodePage": stepStub("verify"),
      "@/features/auth/components/recovery/ResetPasswordPage": stepStub("reset"),
    },
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

test("each forgot-password step shows its counter above the heading", () => {
  const user = { username: "ADM9012-2026" };
  const steps = [
    ["find-account", null, 1, "Find your account"],
    ["options", user, 2, "Forgot password"],
    ["verify", { ...user, channel: "email", maskedEmail: "a***@x.com" }, 3, "Check your email"],
    ["reset", { ...user, resetToken: "token-123" }, 4, "Create new password"],
  ];
  for (const [step, state, number, heading] of steps) {
    const html = renderForgotPasswordAt(step, state);
    assert.match(html, new RegExp(`Step ${number} of 4`), step);
    assert.ok(
      html.indexOf(`Step ${number} of 4`) < html.indexOf(heading),
      `${step}: the counter is above the heading`,
    );
    assert.match(html, new RegExp(`data-step="${step}"`), step);
    assert.doesNotMatch(html, /Marikina City seal/, `${step}: no frame of its own`);
  }
});
