// Tests for decrypt-mmbak.mjs. Run: node --test tools/recovery/decrypt-mmbak.test.mjs
// The envelope layout is written out by hand from BackupService.EncryptDumpAsync:
//   bytes 0-4   header "MMBK" + 0x01 (also the authenticated extra data)
//   bytes 5-16  nonce (12)
//   bytes 17-32 tag (16)
//   bytes 33-   AES-256-GCM ciphertext of a PostgreSQL custom-format dump ("PGDMP...")
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createCipheriv, randomBytes } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, readFileSync, existsSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const script = join(dirname(fileURLToPath(import.meta.url)), 'decrypt-mmbak.mjs');
const HEADER = Buffer.from([0x4d, 0x4d, 0x42, 0x4b, 0x01]);
const DUMP = Buffer.concat([Buffer.from('PGDMP'), Buffer.from('synthetic dump body 0123456789')]);

function envelope(key, plaintext = DUMP, header = HEADER) {
  const nonce = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, nonce);
  cipher.setAAD(HEADER);
  const body = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  return Buffer.concat([header, nonce, cipher.getAuthTag(), body]);
}

function refused({ result, out }) {
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /^decrypt-mmbak: /);
  assert.equal(out, null);
}

function run(input, key) {
  const dir = mkdtempSync(join(tmpdir(), 'mmbak-test-'));
  const inFile = join(dir, 'in.mmbak');
  const outFile = join(dir, 'out.dump');
  writeFileSync(inFile, input);
  const env = { ...process.env };
  delete env.MMBAK_KEY;
  if (key) env.MMBAK_KEY = key.toString('base64');
  const result = spawnSync(process.execPath, [script, inFile, outFile], { env, encoding: 'utf8' });
  const out = existsSync(outFile) ? readFileSync(outFile) : null;
  const cleanup = () => rmSync(dir, { recursive: true, force: true });
  return { result, out, cleanup };
}

test('correct key restores the exact original bytes', () => {
  const key = randomBytes(32);
  const { result, out, cleanup } = run(envelope(key), key);
  cleanup();
  assert.equal(result.status, 0);
  assert.deepEqual(out, DUMP);
});

test('wrong key fails and writes no file', () => {
  const { result, out, cleanup } = run(envelope(randomBytes(32)), randomBytes(32));
  cleanup();
  refused({ result, out });
});

test('one changed byte in the ciphertext fails and writes no file', () => {
  const key = randomBytes(32);
  const bytes = envelope(key);
  bytes[bytes.length - 1] ^= 0x01;
  const { result, out, cleanup } = run(bytes, key);
  cleanup();
  refused({ result, out });
});

test('one changed byte in the tag fails and writes no file', () => {
  const key = randomBytes(32);
  const bytes = envelope(key);
  bytes[20] ^= 0x01;
  const { result, out, cleanup } = run(bytes, key);
  cleanup();
  refused({ result, out });
});

test('wrong version byte in the header fails and writes no file', () => {
  const key = randomBytes(32);
  const bytes = envelope(key);
  bytes[4] = 0x02;
  const { result, out, cleanup } = run(bytes, key);
  cleanup();
  refused({ result, out });
});

test('a file shorter than the 33-byte envelope fails and writes no file', () => {
  const key = randomBytes(32);
  const { result, out, cleanup } = run(envelope(key).subarray(0, 32), key);
  cleanup();
  refused({ result, out });
});

test('a correct decryption that is not a PostgreSQL dump fails and writes no file', () => {
  const key = randomBytes(32);
  const { result, out, cleanup } = run(envelope(key, Buffer.from('not a database dump')), key);
  cleanup();
  refused({ result, out });
});

test('missing or wrong-length key fails and writes no file', () => {
  const key = randomBytes(32);
  const missing = run(envelope(key), null);
  const short = run(envelope(key), randomBytes(16));
  missing.cleanup();
  short.cleanup();
  refused(missing);
  refused(short);
});

test('the key never appears in the output', () => {
  const key = randomBytes(32);
  const wrongKey = randomBytes(32);
  const wrong = run(envelope(key), wrongKey);
  wrong.cleanup();
  refused(wrong);
  assert.ok(!(wrong.result.stdout + wrong.result.stderr).includes(wrongKey.toString('base64')));
  const own = run(envelope(key), key);
  own.cleanup();
  assert.ok(!(own.result.stdout + own.result.stderr).includes(key.toString('base64')));
});
