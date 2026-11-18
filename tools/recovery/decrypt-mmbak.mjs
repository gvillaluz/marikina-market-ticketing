// Turns a downloaded backup (.mmbak) back into a PostgreSQL dump that pg_restore can read.
//
//   In your own terminal (not a recorded or shared one), put the Base64 backup key in MMBAK_KEY
//   for this window only, without typing it on a command line (PowerShell keeps a history):
//     see "Restore from a backup" in docs/recovery-guide.md
//   then:
//     node tools/recovery/decrypt-mmbak.mjs <backup.mmbak> <output.dump>
//   and afterwards:
//     PowerShell:  Remove-Item Env:MMBAK_KEY
//
// Layout (from BackupService.EncryptDumpAsync): 5-byte header "MMBK"+0x01 (also the authenticated
// extra data), 12-byte nonce, 16-byte tag, then AES-256-GCM ciphertext of a PostgreSQL dump.
// Nothing is written unless every check passes. The key is never printed. An existing output
// file is never overwritten.
import { createDecipheriv } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';

const HEADER = Buffer.from([0x4d, 0x4d, 0x42, 0x4b, 0x01]);
const PREFIX = HEADER.length + 12 + 16;

function refuse(message) {
  console.error(`decrypt-mmbak: ${message}`);
  process.exit(1);
}

const [input, output] = process.argv.slice(2);
if (!input || !output) refuse('usage: node decrypt-mmbak.mjs <backup.mmbak> <output.dump>');

const key = Buffer.from(process.env.MMBAK_KEY ?? '', 'base64');
if (key.length !== 32) refuse('set MMBAK_KEY to the Base64 backup encryption key (32 bytes).');

let file;
try {
  file = readFileSync(input);
} catch {
  refuse('the backup file could not be read.');
}
if (file.length <= PREFIX) refuse('the file is too short to be a backup.');
if (!file.subarray(0, HEADER.length).equals(HEADER)) refuse('this is not a version 1 backup file.');

let plain;
try {
  const decipher = createDecipheriv('aes-256-gcm', key, file.subarray(5, 17), { authTagLength: 16 });
  decipher.setAAD(HEADER);
  decipher.setAuthTag(file.subarray(17, PREFIX));
  plain = Buffer.concat([decipher.update(file.subarray(PREFIX)), decipher.final()]);
} catch {
  refuse('decryption failed: the key is wrong or the file was changed.');
}
if (plain.subarray(0, 5).toString('ascii') !== 'PGDMP') refuse('decrypted data is not a PostgreSQL dump.');

try {
  writeFileSync(output, plain, { flag: 'wx' });
} catch {
  refuse('the output file could not be created (it may already exist).');
}
console.log(`decrypt-mmbak: wrote ${plain.length} bytes.`);
