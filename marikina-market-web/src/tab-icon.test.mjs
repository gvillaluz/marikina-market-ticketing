import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

// The browser tab: its title, and an icon that points at a picture file that really exists.

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

test("the browser tab icon points at a picture file that exists in the public folder", () => {
  const html = fs.readFileSync(path.join(root, "index.html"), "utf8");
  const link = html.match(/<link[^>]*rel="icon"[^>]*>/);
  assert.ok(link, "the page has a tab icon link");
  const href = link[0].match(/href="([^"]+)"/)?.[1];
  assert.equal(href, "/favicon.png");
  assert.match(link[0], /type="image\/png"/);
  const file = path.join(root, "public", href);
  assert.ok(fs.existsSync(file), "the icon file exists");
  const bytes = fs.readFileSync(file);
  assert.equal(
    bytes.subarray(0, 8).toString("hex"),
    "89504e470d0a1a0a",
    "the icon file is a real PNG picture",
  );
});

test("the browser tab title is Market Inspection System", () => {
  const html = fs.readFileSync(path.join(root, "index.html"), "utf8");
  assert.equal(html.match(/<title>([^<]*)<\/title>/)?.[1], "Market Inspection System");
});
