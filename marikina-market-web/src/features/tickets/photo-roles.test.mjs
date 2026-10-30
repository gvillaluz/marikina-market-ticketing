import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import test from 'node:test';
import ts from 'typescript';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

const require = createRequire(import.meta.url);
const data = code => `data:text/javascript;base64,${Buffer.from(code).toString('base64')}`;
const react = pathToFileURL(require.resolve('react')).href;
let source = ts.transpileModule(await readFile(new URL('../../components/ui/TicketModal/modal/TicketPhotoEvidenceSection.tsx', import.meta.url), 'utf8'), {
  compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2020, jsx: ts.JsxEmit.ReactJSX },
}).outputText;
for (const match of [...source.matchAll(/from\s+["']([^"']+)["']/g)]) {
  const name = match[1];
  const target = name.endsWith('.css') ? data('export default {};')
    : name.includes('TicketEvidenceGallery') ? data(`import React from '${react}'; export default ({images})=>React.createElement('div',null,images.map(url=>React.createElement('img',{key:url,src:url,alt:url})));`)
    : pathToFileURL(require.resolve(name)).href;
  source = source.replaceAll(JSON.stringify(name), JSON.stringify(target));
}
const { default: Evidence } = await import(data(source));
const render = props => renderToStaticMarkup(React.createElement(Evidence, props));
test('citation roles stay distinct and supporting photos keep their order', () => {
  const html = render({images:['old-flat.jpg'], evidenceItems:[
    {id:3, role:'Supporting', sortOrder:1, url:'support-two.jpg'},
    {id:1, role:'PaperTicket', sortOrder:0, url:'paper.jpg'},
    {id:2, role:'Supporting', sortOrder:0, url:'support-one.jpg'},
  ]});
  assert.match(html,/Paper ticket photo/);
  assert.match(html,/Supporting evidence/);
  assert.ok(html.indexOf('support-one.jpg') < html.indexOf('support-two.jpg'));
  assert.doesNotMatch(html,/old-flat.jpg|Unclassified evidence/);
});
test('legacy photos remain explicitly unclassified without guessed roles', () => {
  const html = render({images:['legacy.jpg']});
  assert.match(html,/Unclassified evidence/);
  assert.match(html,/legacy.jpg/);
  assert.doesNotMatch(html,/Paper ticket photo|Supporting evidence/);
});
