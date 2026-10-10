import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import ts from "typescript";

const source = await readFile(
  new URL("./profile.validation.ts", import.meta.url),
  "utf8",
);
const compiled = ts.transpileModule(source, {
  compilerOptions: {
    module: ts.ModuleKind.ESNext,
    target: ts.ScriptTarget.ES2020,
  },
}).outputText;
const { validateProfileForm, validatePasswordForm, profilePayload, todayDate } =
  await import(
    `data:text/javascript;base64,${Buffer.from(compiled).toString("base64")}`
  );
const validProfile = {
  firstName: "Juan",
  middleName: "",
  lastName: "Dela Cruz",
  dateOfBirth: "1995-05-20",
  email: "juan@example.com",
  phoneNumber: "09171234567",
  houseNumber: "12",
  street: "J.P. Rizal",
  barangay: "Sto. Nino",
  city: "Marikina",
};

test("accepts six-character passwords without number or symbol requirements", () => {
  assert.deepEqual(
    validatePasswordForm({
      currentPassword: "current",
      newPassword: "abcdef",
      confirmNewPassword: "abcdef",
    }),
    {},
  );
});
test("rejects missing current password, short new password, and mismatch", () => {
  assert.deepEqual(
    Object.keys(
      validatePasswordForm({
        currentPassword: "",
        newPassword: "short",
        confirmNewPassword: "other",
      }),
    ),
    ["currentPassword", "newPassword", "confirmNewPassword"],
  );
});
test("requires confirmation and preserves password whitespace", () => {
  assert.ok(
    validatePasswordForm({
      currentPassword: "current",
      newPassword: "abcdef",
      confirmNewPassword: "",
    }).confirmNewPassword,
  );
  assert.deepEqual(
    validatePasswordForm({
      currentPassword: " current ",
      newPassword: " abcde",
      confirmNewPassword: " abcde",
    }),
    {},
  );
});
test("allows an optional middle name, leap dates, and formatted phones", () => {
  assert.deepEqual(validateProfileForm(validProfile), {});
  assert.deepEqual(
    validateProfileForm({
      ...validProfile,
      dateOfBirth: "2000-02-29",
      phoneNumber: "+63 917 123 4567",
    }),
    {},
  );
});
test("rejects every missing required profile field", () => {
  for (const field of Object.keys(validProfile).filter(
    (field) => field !== "middleName",
  )) {
    assert.ok(
      validateProfileForm({ ...validProfile, [field]: "  " })[field],
      field,
    );
  }
});
test("username is excluded from profile validation", () => {
  assert.deepEqual(validateProfileForm({ ...validProfile, username: "" }), {});
});
test("rejects impossible, malformed, and future dates; accepts today", () => {
  for (const dateOfBirth of [
    "2025-02-29",
    "2000-02-30",
    "bad",
    "9999-01-01",
    "0000-01-01",
  ]) {
    assert.ok(
      validateProfileForm({ ...validProfile, dateOfBirth }).dateOfBirth,
      dateOfBirth,
    );
  }
  assert.equal(
    validateProfileForm({ ...validProfile, dateOfBirth: todayDate() })
      .dateOfBirth,
    undefined,
  );
});
test("rejects invalid email and phone inputs", () => {
  assert.ok(validateProfileForm({ ...validProfile, email: "juan@" }).email);
  for (const phoneNumber of ["abc09171234567", "123", "09171234567890123"]) {
    assert.ok(
      validateProfileForm({ ...validProfile, phoneNumber }).phoneNumber,
    );
  }
});
test("payload trims editable fields, nulls middle name, and excludes immutable fields", () => {
  const result = profilePayload({
    ...validProfile,
    firstName: " Juan ",
    middleName: "  ",
    role: "HeadAdmin",
    userId: 99,
    profileUrl: "https://example.com",
    username: "edited.username",
  });
  assert.deepEqual(result, { ...validProfile, middleName: null });
  assert.equal(Object.hasOwn(result, "userId"), false);
  assert.equal(Object.hasOwn(result, "role"), false);
  assert.equal(Object.hasOwn(result, "profileUrl"), false);
  assert.equal(Object.hasOwn(result, "username"), false);
});
