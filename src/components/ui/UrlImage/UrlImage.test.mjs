import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import vm from "node:vm";
import ts from "typescript";

function compile(file, mocks) {
  const module = { exports: {} };
  const code = ts.transpileModule(
    fs.readFileSync(new URL(file, import.meta.url), "utf8"),
    {
      compilerOptions: {
        module: ts.ModuleKind.CommonJS,
        target: ts.ScriptTarget.ES2022,
      },
    },
  ).outputText;
  vm.runInNewContext(code, {
    module,
    exports: module.exports,
    URL,
    require: (id) => mocks[id],
  });
  return module.exports;
}

function harness(file, name, extra = {}) {
  const state = [],
    refs = [],
    effects = [],
    dependencies = [];
  let stateCursor = 0,
    refCursor = 0,
    effectCursor = 0;
  const effect = (callback, values) => {
    const index = effectCursor++;
    if (
      !dependencies[index] ||
      values.some((value, i) => value !== dependencies[index][i])
    ) {
      dependencies[index] = values;
      effects.push(callback);
    }
  };
  const react = {
    useState(initial) {
      const index = stateCursor++;
      if (!(index in state)) state[index] = initial;
      return [
        state[index],
        (value) => {
          state[index] =
            typeof value === "function" ? value(state[index]) : value;
        },
      ];
    },
    useRef(initial) {
      const index = refCursor++;
      return (refs[index] ??= { current: initial });
    },
    useLayoutEffect: effect,
    useEffect: effect,
  };
  const module = compile(file, { react, ...extra });
  return {
    render(...args) {
      stateCursor = 0;
      refCursor = 0;
      effectCursor = 0;
      return module[name](...args);
    },
    flush() {
      while (effects.length) effects.shift()();
    },
  };
}

const { getUrlImageSource } = compile("./useUrlImage.ts", { react: {} });
const first = "https://storage.example.com/first.png?signed=example";
const second = "https://storage.example.com/second.png";

test("signed, HTTP, and blob URLs are preserved; unsafe or missing URLs use a fallback", () => {
  assert.equal(getUrlImageSource(first), first);
  assert.equal(getUrlImageSource(`  ${first}  `), first);
  for (const value of [
    "http://localhost:5173/photo.png",
    "blob:http://localhost:5173/example",
    "/photos/one.png",
  ])
    assert.equal(getUrlImageSource(value), value);
  for (const value of [
    null,
    undefined,
    {},
    "",
    "  ",
    "javascript:alert(1)",
    "data:image/svg+xml,abc",
    "//example.com/image.png",
  ])
    assert.equal(getUrlImageSource(value), undefined);
});

test("images load successfully or end in a fallback instead of a permanent loader", () => {
  const h = harness("./useUrlImage.ts", "useUrlImage");
  const image = h.render(first),
    element = { complete: false, naturalWidth: 0 };
  image.imageRef.current = element;
  h.flush();
  assert.equal(image.status, "loading");
  image.onLoad({ currentTarget: element });
  assert.equal(h.render(first).status, "ready");
  image.onError({ currentTarget: element });
  assert.equal(h.render(first).status, "error");
  assert.equal(h.render(null).status, "error");
});

test("changing a URL starts loading again and ignores stale events from the old element", () => {
  const h = harness("./useUrlImage.ts", "useUrlImage");
  const old = h.render(first),
    oldElement = { complete: false, naturalWidth: 0 };
  old.imageRef.current = oldElement;
  h.flush();
  old.onLoad({ currentTarget: oldElement });
  assert.equal(h.render(first).status, "ready");
  const current = h.render(second),
    newElement = { complete: false, naturalWidth: 0 };
  current.imageRef.current = newElement;
  h.flush();
  assert.equal(current.status, "loading");
  current.onLoad({ currentTarget: newElement });
  old.onError({ currentTarget: oldElement });
  assert.equal(h.render(second).status, "ready");
});

test("cached images settle without waiting for another load event", () => {
  for (const [naturalWidth, status] of [
    [32, "ready"],
    [0, "error"],
  ]) {
    const h = harness("./useUrlImage.ts", "useUrlImage");
    h.render(first).imageRef.current = { complete: true, naturalWidth };
    h.flush();
    assert.equal(h.render(first).status, status);
  }
});

test("previews reject invalid and failed images while retaining the selected valid image", () => {
  const h = harness("./useImagePreview.ts", "useImagePreview", {
    "./useUrlImage": { getUrlImageSource },
  });
  const urls = [first, first, "javascript:alert(1)", second];
  let preview = h.render(urls);
  h.flush();
  assert.deepEqual(Array.from(preview.urls), [first, second]);
  preview.open(second);
  assert.equal(h.render(urls).index, 1);
  preview.onError(first);
  preview = h.render(urls);
  assert.equal(preview.isOpen, true);
  assert.equal(preview.index, 0);
  assert.equal(preview.isFailed(first), true);
  preview.onError(second);
  assert.equal(h.render(urls).isOpen, false);
});

test("changing the image list closes an obsolete preview", () => {
  const h = harness("./useImagePreview.ts", "useImagePreview", {
    "./useUrlImage": { getUrlImageSource },
  });
  let preview = h.render([first]);
  h.flush();
  preview.open(first);
  assert.equal(h.render([first]).isOpen, true);
  assert.equal(h.render([second]).isOpen, false);
  h.flush();
  preview = h.render([second]);
  preview.open(second);
  assert.equal(h.render([second]).isOpen, true);
  preview.close();
  assert.equal(h.render([second]).isOpen, false);
});
