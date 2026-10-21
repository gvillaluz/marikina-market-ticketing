const fs = require('fs');
const path = require('path');
const {spawn, spawnSync} = require('child_process');
const tests = ['test', 'MarikinaMarket.slnx', '--no-restore', '--filter', 'FullyQualifiedName~MobileLoginEmailFailureTests'];
const checks = {
  red: {args: tests, limit: 120000},
  focused: {args: tests, limit: 120000},
  auth: {args: ['test', 'MarikinaMarket.slnx', '--no-restore', '--filter', 'FullyQualifiedName~AuthAuditTests|FullyQualifiedName~MobileLoginEmailFailureTests'], limit: 150000},
  build: {args: ['build', 'MarikinaMarket.slnx', '--no-restore'], limit: 120000},
  full: {args: ['test', 'MarikinaMarket.slnx', '--no-restore'], limit: 240000},
};
const name = process.argv[2];
if (!checks[name]) throw Error('Unknown approved check');
const check = checks[name];
const env = {...process.env};
const tempRoot = path.join(__dirname, 'test-temp');
fs.mkdirSync(tempRoot, {recursive: true});
env.TEMP = env.TMP = env.BACKUP_TEST_TEMP_ROOT = tempRoot;
for (const key of Object.keys(env)) {
  if (/^(E2E_|REPORT_E2E|BACKUP_E2E|FULL_BACKUP_E2E)/.test(key)) delete env[key];
}
const log = fs.openSync(path.join(__dirname, `${name}.log`), 'w');
const started = Date.now();
const args = [...check.args, '-p:OutputPath=bin/MobileLoginEmailVerification/'];
const child = spawn('cmd.exe', ['/d', '/s', '/c', 'dotnet', ...args], {
  cwd: path.resolve(__dirname, '../..'), stdio: ['ignore', log, log], windowsHide: true, env,
});
let timedOut = false;
const timer = setTimeout(() => {timedOut = true; spawnSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], {windowsHide: true, stdio: 'ignore'});}, check.limit);
child.on('error', error => {clearTimeout(timer); throw error;});
child.on('exit', (exitCode, signal) => {
  clearTimeout(timer); fs.closeSync(log);
  const result = {name, command: ['dotnet', ...args], exitCode, signal, timedOut, durationMs: Date.now() - started};
  fs.writeFileSync(path.join(__dirname, `${name}-result.json`), JSON.stringify(result, null, 2) + '\n');
  console.log(JSON.stringify(result)); process.exitCode = timedOut || exitCode !== 0 ? 1 : 0;
});
