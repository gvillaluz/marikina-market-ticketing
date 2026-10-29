import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import ts from 'typescript';
const moduleUrl = source => `data:text/javascript;base64,${Buffer.from(source).toString('base64')}`;
const clientUrl = moduleUrl(`export const calls = []; export default { get: async (route, config) => { calls.push({route, config}); return {data:{items:[], total:0, hasMore:false}}; } };`);
const errorsUrl = moduleUrl(`export class ApiRequestError extends Error { constructor(message,status) { super(message); this.status=status; } }`);
const source = ts.transpileModule(await readFile(new URL('../../api/endpoints/tickets.api.ts', import.meta.url), 'utf8'), {
  compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2020},
}).outputText.replaceAll(JSON.stringify('../client'), JSON.stringify(clientUrl))
  .replaceAll(JSON.stringify('@/utils/apiErrors'), JSON.stringify(errorsUrl));
const {ticketsApi} = await import(moduleUrl(source));
const {calls} = await import(clientUrl);

test('person history uses a distinct person ID and stable offset without a business filter', async () => {
  await ticketsApi.getPersonHistory(31, 10);
  assert.deepEqual(calls.at(-1), {route:'/persons/31/tickets', config:{params:{offset:10}}});
});
test('invalid person history keys and offsets are rejected before sending a request', async () => {
  const count = calls.length;
  for (const [id,offset] of [[0,0],[-1,0],[NaN,0],[31,-1],[31,1.5]]) {
    await assert.rejects(() => ticketsApi.getPersonHistory(id,offset));
  }
  assert.equal(calls.length,count);
});
