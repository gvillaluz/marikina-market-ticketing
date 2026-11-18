import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

const SERVER = "https://mmt-api.azurewebsites.net";

function load(relativePath, mocks, viteSettings = {}) {
  const module = { exports: {} };
  const source = fs
    .readFileSync(new URL(relativePath, import.meta.url), "utf8")
    .replaceAll("import.meta.env", "__viteSettings");
  const code = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
      esModuleInterop: true,
    },
  }).outputText;
  vm.runInNewContext(code, {
    module,
    exports: module.exports,
    __viteSettings: viteSettings,
    require: (name) => {
      if (!(name in mocks)) throw new Error(`Unexpected import: ${name}`);
      return mocks[name];
    },
  });
  return module.exports;
}

const envMock = { __esModule: true, default: { apiBaseUrl: `${SERVER}/api` } };

test("with no server address set (development), the website calls /api on its own address", () => {
  const env = load("../config/env.ts", {}).default;
  assert.equal(env.apiBaseUrl, "/api");
});

test("with the server address set at build time, the website calls that server's /api", () => {
  const env = load("../config/env.ts", {}, { VITE_API_BASE_URL: SERVER }).default;
  assert.equal(env.apiBaseUrl, `${SERVER}/api`);
});

test("every request through the shared client goes to the server address and carries the sign-in cookie", () => {
  const created = [];
  const noInterceptor = { use: () => {} };
  load("./client.ts", {
    axios: {
      __esModule: true,
      default: {
        create: (config) => {
          created.push(config);
          return {
            interceptors: { request: noInterceptor, response: noInterceptor },
          };
        },
      },
    },
    "@/store/store": { useAuthStore: { getState: () => ({}) } },
    "snakecase-keys": { __esModule: true, default: (value) => value },
    "camelcase-keys": { __esModule: true, default: (value) => value },
    "@/features/auth/authSession": {},
    "@/utils/apiErrors": {},
    "@/config/env": envMock,
  });

  assert.equal(created.length, 1);
  assert.equal(created[0].baseURL, `${SERVER}/api`);
  assert.equal(created[0].withCredentials, true);
});

test("renewing after a page refresh posts to the server address and carries the sign-in cookie", async () => {
  const posts = [];
  const { authRefreshApi } = load("./endpoints/authRefresh.api.ts", {
    axios: {
      __esModule: true,
      default: {
        post: async (...args) => {
          posts.push(args);
          return {
            data: { accessToken: "renewed-pass", mustChangePassword: false },
          };
        },
      },
    },
    "camelcase-keys": { __esModule: true, default: (value) => value },
    "@/config/env": envMock,
  });

  await authRefreshApi.refreshWeb();

  assert.equal(posts.length, 1);
  assert.equal(posts[0][0], `${SERVER}/api/auth/refresh-web`);
  assert.equal(posts[0][2].withCredentials, true);
});
