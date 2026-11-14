import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

function load(relativePath, mocks, globals = {}) {
  const module = { exports: {} };
  const code = ts.transpileModule(
    fs.readFileSync(new URL(relativePath, import.meta.url), "utf8"),
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
    Date,
    ...globals,
    require: (name) => {
      if (!(name in mocks)) throw new Error(`Unexpected import: ${name}`);
      return mocks[name];
    },
  });
  return module.exports;
}

const toCamel = (data) =>
  Object.fromEntries(
    Object.entries(data).map(([key, value]) => [
      key.replace(/_([a-z])/g, (_match, letter) => letter.toUpperCase()),
      value,
    ]),
  );

test("renewing posts to /api/auth/refresh-web with no pass in the body, so the server uses the cookie", async () => {
  const posts = [];
  const { authRefreshApi } = load("../../api/endpoints/authRefresh.api.ts", {
    axios: {
      __esModule: true,
      default: {
        post: async (...args) => {
          posts.push(args);
          return {
            data: { access_token: "renewed-pass", must_change_password: false },
          };
        },
      },
    },
    "camelcase-keys": { __esModule: true, default: toCamel },
  });

  const refreshed = await authRefreshApi.refreshWeb();

  assert.equal(posts.length, 1);
  assert.equal(posts[0][0], "/api/auth/refresh-web");
  assert.equal(posts[0][1], undefined);
  assert.equal(refreshed.accessToken, "renewed-pass");
  assert.equal(refreshed.mustChangePassword, false);
});

function sessionHarness(serverReplies) {
  const refreshCalls = [];
  const storeCalls = [];
  const store = {
    setAccessToken: (token) => storeCalls.push(["setAccessToken", token]),
    setMustChangePassword: (value) =>
      storeCalls.push(["setMustChangePassword", value]),
    logout: () => storeCalls.push(["logout"]),
  };
  const session = load(
    "./authSession.ts",
    {
      axios: {
        __esModule: true,
        default: { isAxiosError: (error) => error?.isAxiosError === true },
      },
      "jwt-decode": {
        jwtDecode: () => ({ exp: Math.floor(Date.now() / 1000) + 900 }),
      },
      "@/store/store": { useAuthStore: { getState: () => store } },
      "@/api/endpoints/authRefresh.api": {
        InvalidAccessTokenError: class InvalidAccessTokenError extends Error {},
        authRefreshApi: {
          refreshWeb: async (...args) => {
            refreshCalls.push(args);
            const reply = serverReplies.shift();
            if (reply instanceof Error) throw reply;
            return reply;
          },
        },
      },
    },
    { sessionStorage: { removeItem: () => {} } },
  );
  return { session, refreshCalls, storeCalls };
}

const isExpiredSession = (error) => error.name === "RefreshSessionExpiredError";

test("after a page refresh, restoring asks the server (cookie only) and keeps the new pass in page memory", async () => {
  const { session, refreshCalls, storeCalls } = sessionHarness([
    { accessToken: "restored-pass", mustChangePassword: false },
  ]);
  assert.equal(session.getStoredAuthSession(), null);

  const restored = await session.restoreAuthSession();

  assert.deepEqual(refreshCalls, [[]]);
  assert.equal(restored.accessToken, "restored-pass");
  assert.equal(session.getStoredAuthSession().accessToken, "restored-pass");
  assert.deepEqual(storeCalls, [
    ["setAccessToken", "restored-pass"],
    ["setMustChangePassword", false],
  ]);
});

test("two restores at the same moment (React runs start-up twice in development) make one server request", async () => {
  const { session, refreshCalls } = sessionHarness([
    { accessToken: "restored-pass", mustChangePassword: false },
  ]);

  const [first, second] = await Promise.all([
    session.restoreAuthSession(),
    session.restoreAuthSession(),
  ]);

  assert.equal(refreshCalls.length, 1);
  assert.equal(first.accessToken, "restored-pass");
  assert.equal(second.accessToken, "restored-pass");
});

test("when the server refuses the cookie, restoring reports an expired session and keeps nobody signed in", async () => {
  const refused = Object.assign(new Error("Unauthorized"), {
    isAxiosError: true,
    response: { status: 401 },
  });
  const { session } = sessionHarness([refused]);

  await assert.rejects(session.restoreAuthSession(), isExpiredSession);
  assert.equal(session.getStoredAuthSession(), null);
});

test("once signed out, background renewal stays off and never asks the server", () => {
  const { session, refreshCalls } = sessionHarness([]);

  assert.throws(() => session.refreshAccessToken(), isExpiredSession);
  assert.equal(refreshCalls.length, 0);
});

test("while signed in, background renewal sends no pass and keeps the renewed one", async () => {
  const { session, refreshCalls } = sessionHarness([
    { accessToken: "renewed-pass", mustChangePassword: false },
  ]);
  session.storeAuthSession("current-pass");

  await session.refreshAccessToken();

  assert.deepEqual(refreshCalls, [[]]);
  assert.equal(session.getStoredAuthSession().accessToken, "renewed-pass");
});
