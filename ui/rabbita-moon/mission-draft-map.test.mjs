import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile, writeFile, mkdir, mkdtemp } from 'node:fs/promises'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import { bindMissionStudy, readStudy } from './mission-study.js'
import { readDraft, exportDraft, forkMission } from './mission-authoring.js'
import { draftTerrain, parseDraftCells, bindDraftRouteMap } from './mission-draft-map.js'
import { createMissionHost } from './mission-run-host.js'
import { MissionRunClient } from './mission-run.js'

const parentText = await readFile(new URL('./fixtures/mission-study-local.json', import.meta.url), 'utf8')
const parent = await readStudy(parentText)

test('out-and-back alternative uses production duplicate, preview, cancel, apply, undo, export and reopen handlers', async () => {
  const calls = [], f = screen({ async start(text) { calls.push(text); throw new Error('Injected host unavailable') }, async get() {} }); await f.start()
  const original = f.get('draft-cells').value, saved = f.storage.getItem('moonmoon.study.v1/local-study/r1')
  await f.get('draft-variant-duplicate').fire('click')
  assert.equal(f.get('draft-variant').value, '2')
  f.get('draft-variant-name').value = 'Out and back'; await f.get('draft-variant-name').fire('input')
  const outbound = '0,0\n0,0\n1,0\n1,1', expected = outbound + '\n1,0\n0,0\n0,0'
  f.get('draft-cells').value = outbound; await f.get('draft-cells').fire('input')
  await f.get('draft-map-return-plan').fire('click')
  assert.equal(f.get('draft-cells').value, outbound)
  assert.match(f.get('draft-map-return-status').textContent, /Authored straight-segment estimated distance/)
  assert.equal(f.get('draft-map-return-preview').textContent, '5. 1,0\n6. 0,0\n7. 0,0')
  await f.get('draft-map-return-cancel').fire('click'); assert.equal(f.get('draft-map-return-apply').disabled, true)
  await f.get('draft-map-return-plan').fire('click'); const stale = f.get('draft-map-return-apply')
  await stale.fire('click'); assert.equal(f.get('draft-cells').value, expected)
  await stale.fire('click'); assert.equal(f.get('draft-cells').value, expected)
  await f.get('draft-map-undo').fire('click'); assert.equal(f.get('draft-cells').value, outbound)
  await f.get('draft-map-return-plan').fire('click'); await f.get('draft-map-return-apply').fire('click')
  assert.deepEqual(calls, [])
  const create = URL.createObjectURL, revoke = URL.revokeObjectURL; let blob
  URL.createObjectURL = value => { blob = value; return 'blob:return' }; URL.revokeObjectURL = () => {}
  try {
    await f.get('draft-export').fire('click'); const bytes = await blob.text(), loaded = await readDraft(bytes)
    assert.deepEqual(loaded.draft.variants[2].edits.path_cells, parseDraftCells(expected))
    assert.equal(loaded.draft.variants[2].name, 'Out and back')
    for (const v of loaded.draft.variants.slice(0, 2)) assert.deepEqual(v.edits.path_cells, parseDraftCells(original))
    await f.get('draft-discard').fire('click'); f.get('draft-file').files = [{ size: bytes.length, text: async () => bytes }]; await f.get('draft-file').fire('change')
    f.get('draft-variant').value = '2'; await f.get('draft-variant').fire('change')
    assert.equal(f.get('draft-cells').value, expected)
    await f.get('draft-export').fire('click'); assert.equal(await blob.text(), bytes)
    assert.equal(f.storage.getItem('moonmoon.study.v1/local-study/r1'), saved)
    await f.get('run-start').fire('click'); assert.equal(calls.length, 1)
    assert.deepEqual((await readDraft(calls[0])).draft.variants[2].edits.path_cells, parseDraftCells(expected))
    assert.match(f.get('run-status').textContent, /Injected host unavailable/)
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke }
})

test('return preview refuses stale variant, text, source and discard callbacks and oversized routes', async () => {
  const f = screen(); await f.start(); const original = f.get('draft-cells').value
  await f.get('draft-map-return-plan').fire('click'); const variant = f.get('draft-map-return-apply')
  f.get('draft-variant').value = '1'; await f.get('draft-variant').fire('change'); await variant.fire('click')
  assert.equal(f.get('draft-cells').value, original)
  await f.get('draft-map-return-plan').fire('click'); const edit = f.get('draft-map-return-apply')
  f.get('draft-cells').value = 'unfinished'; await edit.fire('click'); assert.equal(f.get('draft-cells').value, 'unfinished')
  await f.get('draft-cells').fire('input'); await edit.fire('click'); assert.equal(f.get('draft-cells').value, 'unfinished')
  f.get('draft-cells').value = Array(129).fill('0,0').join('\n'); await f.get('draft-cells').fire('input')
  await f.get('draft-map-return-plan').fire('click'); assert.equal(f.get('draft-map-return-apply').disabled, true)
  assert.match(f.get('draft-map-return-status').textContent, /256-occurrence/)
  let text = '999,999\n1000,1000', render
  render = bindDraftRouteMap(f.document, { readText: () => text, writeText: value => { text = value } })
  const context = { identity: {}, dossier: { sources: [] }, design: { environment: {} } }; render(context)
  await f.get('draft-map-return-plan').fire('click'); assert.match(f.get('draft-map-return-status').textContent, /distance unavailable/)
  const old = f.get('draft-map-return-apply'); render({ ...context, identity: {} }); await old.fire('click'); assert.equal(text, '999,999\n1000,1000')
  await f.get('draft-map-return-plan').fire('click'); const discarded = f.get('draft-map-return-apply'); render(null); await discarded.fire('click'); assert.equal(text, '999,999\n1000,1000')
})
class Element {
  constructor(tag = '') { this.tagName = tag; this.dataset = {}; this.value = ''; this.children = []; this.events = new Map(); this.files = []; this.attributes = {}; this.textContent = ''; this.isConnected = true }
  setAttribute(k, v) { this.attributes[k] = String(v) }
  appendChild(child) { this.children.push(child); return child }
  replaceChildren(...children) { this.children = children }
  addEventListener(k, fn) { this.events.set(k, fn) }
  async fire(k, extra = {}) { return this.events.get(k)?.({ preventDefault() {}, ...extra }) }
}
class Storage {
  values = new Map()
  getItem(k) { return this.values.get(k) ?? null }
  setItem(k, v) { this.values.set(k, v) }
  removeItem(k) { this.values.delete(k) }
}
function screen(client) {
  const nodes = new Map(), downloads = [], storage = new Storage()
  const find = (node, id) => node.id === id ? node : node.children.map(c => find(c, id)).find(Boolean)
  const document = {
    getElementById(id) { for (const node of nodes.values()) { const found = find(node, id); if (found) return found } if (!nodes.has(id)) { const node = new Element(); node.id = id; nodes.set(id, node) } return nodes.get(id) },
    createElement(tag) { const node = new Element(tag); node.click = () => downloads.push(node); return node },
    createElementNS(_, tag) { return new Element(tag) },
  }
  const get = n => document.getElementById('study-' + n)
  bindMissionStudy(document, () => storage, client)
  const start = async () => {
    get('file').files = [{ size: parentText.length, text: async () => parentText }]; await get('file').fire('change')
    get('reviewer').value = 'Original reviewer'; get('choice').value = 'none'; get('rationale').value = 'Original exact parent only'; await get('save').fire('click')
    get('draft-parent-session').value = 'q11-a'; await get('draft-fork').fire('click')
  }
  return { get, document, downloads, storage, start }
}

test('decoder is bounded, sparse, non-square and rejects ambiguous or absent samples', () => {
  const design = structuredClone(parent.alternatives[0].design), dossier = structuredClone(parent.dossier)
  const ref = design.environment.terrain_source_path, source = dossier.sources.find(s => s.artifact_ref === ref)
  source.text = 'tile_id,row,col,elevation_m\nx,0,0,2\nx,1,200,3\n'
  const model = draftTerrain(dossier, design)
  assert.equal(model.samples.length, 2); assert.equal(model.bounds.maxRow, 1); assert.equal(model.bounds.maxCol, 200)
  source.text += 'x,0,0,4\n'; assert.match(draftTerrain(dossier, design).reason, /Ambiguous/)
  source.text = 'tile_id,row,col,elevation_m\n'; assert.equal(draftTerrain(dossier, design).available, false)
  dossier.sources = dossier.sources.filter(s => s.artifact_ref !== ref); assert.match(draftTerrain(dossier, design).reason, /missing/)
  assert.throws(() => parseDraftCells('0,0'), /2–256/)
  assert.throws(() => parseDraftCells('0,\n1,2'))
  assert.throws(() => parseDraftCells(Array(257).fill('0,0').join('\n')))
  assert.deepEqual(parseDraftCells('0,0\n0,0\n1,0\n0,0\n1,0'), [[0,0],[0,0],[1,0],[0,0],[1,0]])
})

test('real draft controls preserve ordered repeats, undo, text equivalence and stale variant callbacks', async () => {
  const f = screen(); await f.start()
  const original = f.get('draft-cells').value, oldAppend = f.get('draft-map-append')
  await oldAppend.fire('click'); assert.equal(parseDraftCells(f.get('draft-cells').value).length, parseDraftCells(original).length + 1)
  const appended = f.get('draft-cells').value
  await oldAppend.fire('click'); assert.equal(f.get('draft-cells').value, appended)
  await f.get('draft-map-undo').fire('click'); assert.equal(f.get('draft-cells').value, original)
  f.get('draft-cells').value = '0,0\n0,0\n1,0\n0,0\n1,0'; await f.get('draft-cells').fire('input')
  f.get('draft-map-route').value = '2'; await f.get('draft-map-earlier').fire('click')
  assert.equal(f.get('draft-cells').value, '0,0\n1,0\n0,0\n0,0\n1,0')
  f.get('draft-map-route').value = '1'; await f.get('draft-map-later').fire('click')
  assert.equal(f.get('draft-cells').value, '0,0\n0,0\n1,0\n0,0\n1,0')
  f.get('draft-map-route').value = '1'; await f.get('draft-map-remove').fire('click')
  assert.equal(f.get('draft-cells').value, '0,0\n1,0\n0,0\n1,0')
  const stale = f.get('draft-map-append'), first = f.get('draft-cells').value
  f.get('draft-variant').value = '1'; await f.get('draft-variant').fire('change'); await stale.fire('click')
  assert.equal(f.get('draft-cells').value, original)
  f.get('draft-variant').value = '0'; await f.get('draft-variant').fire('change'); assert.equal(f.get('draft-cells').value, first)
  f.get('draft-cells').value = '0,\n1,0'; await f.get('draft-cells').fire('input')
  await stale.fire('click'); assert.equal(f.get('draft-cells').value, '0,\n1,0')
  await f.get('draft-map-undo').fire('click'); assert.equal(f.get('draft-cells').value, first)
})

test('keyboard sample append and actual export/discard/reopen preserve exact v1 and v2 drafts', async () => {
  const create = URL.createObjectURL, revoke = URL.revokeObjectURL
  let blob; URL.createObjectURL = b => { blob = b; return 'blob:draft-test' }; URL.revokeObjectURL = () => {}
  try {
    for (const version of [1, 2]) {
      const f = screen(); await f.start(); const saved = f.storage.getItem('moonmoon.study.v1/local-study/r1')
      if (version === 1) {
        await f.get('draft-discard').fire('click'); const draft = forkMission(parent, 'q11-a', { version: 1 }); draft.edits.assumption_note = 'Frozen route edit, digital only'
        const text = await exportDraft(draft); f.get('draft-file').files = [{ size: text.length, text: async () => text }]; await f.get('draft-file').fire('change')
      }
      const canvas = f.get('draft-map').children.find(n => n.tagName === 'svg'), dot = canvas.children.find(n => n.tagName === 'circle')
      assert.equal(dot.attributes.role, 'button'); assert.equal(dot.attributes.tabindex, '0')
      const before = parseDraftCells(f.get('draft-cells').value)
      await dot.fire('keydown', { key: 'Enter' }); const cells = parseDraftCells(f.get('draft-cells').value)
      assert.equal(cells.length, before.length + 1)
      await dot.fire('keydown', { key: ' ' }); assert.deepEqual(parseDraftCells(f.get('draft-cells').value), cells)
      await f.get('draft-export').fire('click'); const bytes = await blob.text(), loaded = await readDraft(bytes)
      assert.deepEqual(version === 1 ? loaded.draft.edits.path_cells : loaded.draft.variants[0].edits.path_cells, cells)
      await f.get('draft-discard').fire('click'); await dot.fire('click'); assert.equal(f.get('draft-cells').value, '')
      f.get('draft-file').files = [{ size: bytes.length, text: async () => bytes }]; await f.get('draft-file').fire('change')
      assert.deepEqual(parseDraftCells(f.get('draft-cells').value), cells)
      await f.get('draft-export').fire('click'); assert.equal(await blob.text(), bytes)
      assert.equal(f.storage.getItem('moonmoon.study.v1/local-study/r1'), saved)
    }
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke }
})

test('text bounds, unavailable terrain and late robot imports keep authoritative edits', async () => {
  const f = screen(); await f.start()
  f.get('draft-cells').value = '0,0\n1,0'; await f.get('draft-cells').fire('input')
  assert.equal(f.get('draft-map-remove').disabled, true)
  f.get('draft-cells').value = Array(256).fill('0,0').join('\n'); await f.get('draft-cells').fire('input')
  assert.equal(f.get('draft-map-append').disabled, true)
  const full = f.get('draft-cells').value; await f.get('draft-map-append').fire('click'); assert.equal(f.get('draft-cells').value, full)
  const robot = await readFile(new URL('./fixtures/moonrobo-simulation-input.json', import.meta.url), 'utf8')
  let finish
  f.get('draft-robot').files = [{ size: robot.length, text: () => new Promise(resolve => { finish = resolve }) }]
  const pending = f.get('draft-robot').fire('change')
  f.get('draft-cells').value = '0,0\n1,0'; await f.get('draft-cells').fire('input')
  await f.get('draft-map-append').fire('click'); const latest = f.get('draft-cells').value
  finish(robot); await pending
  assert.match(f.get('draft-status').textContent, /Inputs changed/); assert.equal(f.get('draft-cells').value, latest)
  const dossier = structuredClone(parent.dossier), design = parent.alternatives[0].design
  dossier.sources.push(dossier.sources.find(s => s.artifact_ref === design.environment.terrain_source_path))
  let text = '0,0\n1,0\n0,0', render
  render = bindDraftRouteMap(f.document, { readText: () => text, writeText: value => { text = value; render(context) } })
  const context = { dossier, design, identity: {} }; render(context)
  assert.ok(f.get('draft-map').children.some(n => /unavailable.*ambiguous/.test(n.textContent)))
  f.get('draft-map-route').value = '1'; await f.get('draft-map-remove').fire('click'); assert.equal(text, '0,0\n0,0')
})

test('edited route exports/reopens then explicitly runs through actual retained native host and reopens', { skip: !process.env.MOONMOON_NATIVE_CLI }, async () => {
  const directory = process.env.MOONMOON_ROUTE_JOURNEY_DIR || await mkdtemp(join(tmpdir(), 'moon-route-draft-'))
  await mkdir(join(directory, 'static'), { recursive: true }); await writeFile(join(directory, 'static/index.html'), '<title>Native route fixture</title>')
  const attempt = await mkdtemp(join(directory, 'attempt-'))
  const host = await createMissionHost({ cliPath: process.env.MOONMOON_NATIVE_CLI, root: join(attempt, 'runs'), staticRoot: join(directory, 'static'), port: 0 })
  const client = new MissionRunClient((url, options) => fetch(host.origin + url, options)), f = screen(client)
  const create = URL.createObjectURL, revoke = URL.revokeObjectURL; let blob
  URL.createObjectURL = b => { blob = b; return 'blob:native-route' }; URL.revokeObjectURL = () => {}
  try {
    await f.start(); const saved = f.storage.getItem('moonmoon.study.v1/local-study/r1')
    f.get('draft-revision').value = 'route-editor-r45'; await f.get('draft-revision').fire('input')
    // Exact frozen [0,0] exists but is disconnected from the route's final cell.
    f.get('draft-map-sample').value = '0'; await f.get('draft-map-append').fire('click')
    const cells = parseDraftCells(f.get('draft-cells').value)
    await f.get('draft-export').fire('click'); const bytes = await blob.text()
    await f.get('draft-discard').fire('click'); f.get('draft-file').files = [{ size: bytes.length, text: async () => bytes }]; await f.get('draft-file').fire('change')
    assert.deepEqual(parseDraftCells(f.get('draft-cells').value), cells); assert.deepEqual(await client.list(), [])
    await f.get('run-start').fire('click')
    const end = Date.now() + 60000
    let run
    while (Date.now() < end) { const runs = await client.list(); run = runs[0]; if (run && ['completed','failed'].includes(run.state)) break; await new Promise(resolve => setTimeout(resolve, 25)) }
    assert.equal(run.state, 'completed'); assert.equal(run.native_exit_observed, true)
    assert.equal(await client.draft(run.run_id), bytes)
    const resultText = await client.result(run.run_id), result = await readStudy(resultText)
    assert.deepEqual(result.alternatives[1].design.environment.path_cells, cells)
    assert.equal(result.alternatives[1].result.result, 'rejected')
    await f.get('run-open').fire('click'); assert.equal(f.get('revision').value, 'route-editor-r45')
    assert.equal(f.storage.getItem('moonmoon.study.v1/local-study/r1'), saved)
    assert.equal(f.get('reviewer').value, '')
    await writeFile(join(directory, 'edited-export.json'), bytes); await writeFile(join(directory, 'native-result.json'), resultText)
    await writeFile(join(directory, 'PROOF.json'), JSON.stringify({ actual_route_controls: true, exact_export_reopen: true, explicit_native_host_run: true, parent_review_preserved: true, result_reopened: true, native_rejected_disconnected_route: true, run_id: run.run_id, draft_digest: JSON.parse(bytes).draft_digest, dossier_digest: result.envelope.dossier_digest, cells }, null, 2))
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke; await host.close() }
})

test('route CSV stages review, replaces/appends ordered occurrences, undoes, and round trips the real draft', async () => {
  const f = screen(); await f.start()
  const original = f.get('draft-cells').value, saved = f.storage.getItem('moonmoon.study.v1/local-study/r1')
  const csv = '\uFEFFrow,column\r\n0,0\r\n1,0\r\n0,0\r\n999,999\r\n'
  const stage = async value => { f.get('draft-map-csv-file').files = [{ size: value.length, text: async () => value }]; await f.get('draft-map-csv-file').fire('change') }
  await stage(csv)
  assert.equal(f.get('draft-cells').value, original)
  assert.match(f.get('draft-map-csv-status').textContent, /4 imported occurrences/)
  assert.match(f.get('draft-map-csv-status').textContent, /lack an exact frozen terrain sample/)
  assert.match(f.get('draft-map-csv-preview').textContent, /4\. 999,999/)
  await f.get('draft-map-csv-apply').fire('click')
  const replacement = '0,0\n1,0\n0,0\n999,999'
  assert.equal(f.get('draft-cells').value, replacement)
  await f.get('draft-map-undo').fire('click'); assert.equal(f.get('draft-cells').value, original)
  await stage(csv); f.get('draft-map-csv-mode').value = 'append'; await f.get('draft-map-csv-mode').fire('change')
  await f.get('draft-map-csv-apply').fire('click'); assert.equal(f.get('draft-cells').value, original + '\n' + replacement)
  const combined = f.get('draft-cells').value
  const create = URL.createObjectURL, revoke = URL.revokeObjectURL; let blob
  URL.createObjectURL = value => { blob = value; return 'blob:route-csv' }; URL.revokeObjectURL = () => {}
  try {
    await f.get('draft-map-csv-export').fire('click'); const exported = await blob.text()
    assert.equal(exported, 'row,column\n' + combined + '\n')
    assert.equal(f.downloads.at(-1).download, 'moonmoon-draft-route.csv')
    f.get('draft-variant').value = '1'; await f.get('draft-variant').fire('change'); assert.equal(f.get('draft-cells').value, original)
    await stage(exported); await f.get('draft-map-csv-apply').fire('click'); assert.equal(f.get('draft-cells').value, combined)
    await f.get('draft-export').fire('click'); const full = await blob.text(), loaded = await readDraft(full)
    assert.deepEqual(loaded.draft.variants[0].edits.path_cells, parseDraftCells(combined))
    assert.deepEqual(loaded.draft.variants[1].edits.path_cells, parseDraftCells(combined))
    await f.get('draft-discard').fire('click')
    f.get('draft-file').files = [{ size: full.length, text: async () => full }]; await f.get('draft-file').fire('change')
    assert.equal(f.get('draft-cells').value, combined)
    assert.equal(f.storage.getItem('moonmoon.study.v1/local-study/r1'), saved)
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke }
})

test('route CSV handles append limits, invalid current text repair, stale selection and competing reads', async () => {
  const f = screen(); await f.start()
  const stage = async value => { f.get('draft-map-csv-file').files = [{ size: value.length, text: async () => value }]; await f.get('draft-map-csv-file').fire('change') }
  const csv = 'row,column\n0,0\n0,0\n'
  f.get('draft-cells').value = Array(256).fill('0,0').join('\n'); await f.get('draft-cells').fire('input')
  await stage(csv); f.get('draft-map-csv-mode').value = 'append'; await f.get('draft-map-csv-mode').fire('change')
  assert.equal(f.get('draft-map-csv-apply').disabled, true)
  await f.get('draft-map-csv-apply').fire('click'); assert.equal(parseDraftCells(f.get('draft-cells').value).length, 256)
  f.get('draft-cells').value = 'unfinished'; await f.get('draft-cells').fire('input')
  await stage(csv); assert.equal(f.get('draft-map-csv-export').disabled, true)
  f.get('draft-map-csv-mode').value = 'append'; await f.get('draft-map-csv-mode').fire('change'); assert.equal(f.get('draft-map-csv-apply').disabled, true)
  f.get('draft-map-csv-mode').value = 'replace'; await f.get('draft-map-csv-mode').fire('change'); await f.get('draft-map-csv-apply').fire('click')
  assert.equal(f.get('draft-cells').value, '0,0\n0,0'); await f.get('draft-map-undo').fire('click'); assert.equal(f.get('draft-cells').value, 'unfinished')
  await stage(csv); const staleApply = f.get('draft-map-csv-apply')
  f.get('draft-variant').value = '1'; await f.get('draft-variant').fire('change'); const original = f.get('draft-cells').value
  await staleApply.fire('click'); assert.equal(f.get('draft-cells').value, original)
  let finish
  const input = f.get('draft-map-csv-file'); input.files = [{ size: 20, text: () => new Promise(resolve => { finish = resolve }) }]
  const pending = input.fire('change')
  await stage(csv); finish('row,column\n2,2\n3,3'); await pending
  assert.match(f.get('draft-map-csv-preview').textContent, /1\. 0,0/)
  await f.get('draft-map-csv-apply').fire('click'); assert.equal(f.get('draft-cells').value, '0,0\n0,0')
  const later = f.get('draft-map-csv-file'); later.files = [{ size: 20, text: () => new Promise(resolve => { finish = resolve }) }]
  const delayed = later.fire('change'); f.get('draft-cells').value = '4,4\n5,5'; await f.get('draft-cells').fire('input')
  finish(csv); await delayed; assert.equal(f.get('draft-cells').value, '4,4\n5,5'); assert.equal(f.get('draft-map-csv-apply').disabled, true)
  for (const bad of ['column,row\n0,0\n1,1', 'row,column\n-1,0\n1,1', 'row,column\n0,0,2\n1,1', 'row,column\n0,0', 'row,column\n0,0\n1000001,0']) {
    await stage(bad); assert.equal(f.get('draft-map-csv-apply').disabled, true); assert.match(f.get('draft-map-csv-status').textContent, /CSV not staged/)
    assert.equal(f.get('draft-cells').value, '4,4\n5,5')
  }
})

test('route CSV works with v1 drafts and stages unknown coverage without manufacturing samples', async () => {
  const f = screen(); await f.start(); await f.get('draft-discard').fire('click')
  const draft = forkMission(parent, 'q11-a', { version: 1 }); draft.edits.assumption_note = 'CSV index exchange only'
  const bytes = await exportDraft(draft); f.get('draft-file').files = [{ size: bytes.length, text: async () => bytes }]; await f.get('draft-file').fire('change')
  const csv = 'row,column\n1000000,0\n0,1000000\n'
  f.get('draft-map-csv-file').files = [{ size: csv.length, text: async () => csv }]; await f.get('draft-map-csv-file').fire('change')
  assert.match(f.get('draft-map-csv-status').textContent, /2 imported occurrences lack/)
  await f.get('draft-map-csv-apply').fire('click'); assert.equal(f.get('draft-cells').value, '1000000,0\n0,1000000')
  const create = URL.createObjectURL, revoke = URL.revokeObjectURL; let blob
  URL.createObjectURL = b => { blob = b; return 'blob:csv-v1' }; URL.revokeObjectURL = () => {}
  try {
    await f.get('draft-export').fire('click'); const result = await readDraft(await blob.text())
    assert.deepEqual(result.draft.edits.path_cells, [[1000000,0],[0,1000000]])
    assert.equal(result.draft.contract_id, 'moonmoon.mission-draft.v1')
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke }
  let text = '0,0\n1,0', render
  const context = { identity: {}, dossier: { sources: [] }, design: parent.alternatives[0].design }
  render = bindDraftRouteMap(f.document, { readText: () => text, writeText: value => { text = value; render(context) } }); render(context)
  f.get('draft-map-csv-file').files = [{ size: csv.length, text: async () => csv }]; await f.get('draft-map-csv-file').fire('change')
  assert.match(f.get('draft-map-csv-status').textContent, /coverage unknown/)
  await f.get('draft-map-csv-apply').fire('click'); assert.equal(text, '1000000,0\n0,1000000')
})

test('detour stages, cancels, applies, undoes and exports through the real mission authoring controls', async () => {
  const f = screen(); await f.start()
  const original = f.get('draft-cells').value, saved = f.storage.getItem('moonmoon.study.v1/local-study/r1')
  f.get('draft-map-detour-avoid').value = '1,3'
  await f.get('draft-map-detour-plan').fire('click')
  assert.equal(f.get('draft-cells').value, original)
  assert.match(f.get('draft-map-detour-preview').textContent, /0,2/)
  assert.match(f.get('draft-map-detour-status').textContent, /unvalidated geometric/)
  await f.get('draft-map-detour-cancel').fire('click')
  assert.equal(f.get('draft-map-detour-apply').disabled, true); assert.equal(f.get('draft-cells').value, original)
  await f.get('draft-map-detour-plan').fire('click')
  const oldApply = f.get('draft-map-detour-apply')
  await oldApply.fire('click'); const detour = f.get('draft-cells').value
  assert.notEqual(detour, original); assert.ok(!detour.split('\n').includes('1,3'))
  await oldApply.fire('click'); assert.equal(f.get('draft-cells').value, detour)
  await f.get('draft-map-undo').fire('click'); assert.equal(f.get('draft-cells').value, original)
  f.get('draft-map-detour-avoid').value = '1,3'; await f.get('draft-map-detour-plan').fire('click'); await f.get('draft-map-detour-apply').fire('click')
  const create = URL.createObjectURL, revoke = URL.revokeObjectURL; let blob
  URL.createObjectURL = value => { blob = value; return 'blob:detour' }; URL.revokeObjectURL = () => {}
  try {
    await f.get('draft-export').fire('click'); const bytes = await blob.text(), loaded = await readDraft(bytes)
    assert.deepEqual(loaded.draft.variants[0].edits.path_cells, parseDraftCells(detour))
    assert.deepEqual(loaded.draft.variants[1].edits.path_cells, parseDraftCells(original))
    assert.equal(loaded.draft.physical_execution_allowed, false); assert.equal(loaded.draft.review_required, true)
    await f.get('draft-discard').fire('click'); f.get('draft-file').files = [{ size: bytes.length, text: async () => bytes }]; await f.get('draft-file').fire('change')
    assert.equal(f.get('draft-cells').value, detour)
    assert.equal(f.storage.getItem('moonmoon.study.v1/local-study/r1'), saved)
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke }
})

test('detour refuses stale previews after inputs, variant, route and source context change', async () => {
  const f = screen(); await f.start(); const original = f.get('draft-cells').value
  const stage = async () => { f.get('draft-map-detour-avoid').value = '1,3'; await f.get('draft-map-detour-plan').fire('click') }
  await stage(); f.get('draft-map-detour-avoid').value = '2,3'; await f.get('draft-map-detour-apply').fire('click')
  assert.equal(f.get('draft-cells').value, original); assert.match(f.get('draft-map-detour-status').textContent, /preview again/)
  await stage(); f.get('draft-map-detour-from').value = '2'; await f.get('draft-map-detour-from').fire('change')
  assert.equal(f.get('draft-map-detour-apply').disabled, true)
  f.get('draft-map-detour-from').value = '0'; await stage(); const staleVariant = f.get('draft-map-detour-apply')
  f.get('draft-variant').value = '1'; await f.get('draft-variant').fire('change'); await staleVariant.fire('click'); assert.equal(f.get('draft-cells').value, original)
  await stage(); const staleRoute = f.get('draft-map-detour-apply')
  f.get('draft-cells').value = '0,0\n0,1'; await f.get('draft-cells').fire('input'); await staleRoute.fire('click'); assert.equal(f.get('draft-cells').value, '0,0\n0,1')
  await f.get('draft-map-detour-plan').fire('click'); assert.equal(f.get('draft-map-detour-apply').disabled, true)
  let text = original, render
  render = bindDraftRouteMap(f.document, { readText: () => text, writeText: value => { text = value } })
  const context = { dossier: parent.dossier, design: parent.alternatives[0].design, identity: {} }; render(context)
  await stage(); const oldSource = f.get('draft-map-detour-apply')
  render({ ...context, dossier: { ...parent.dossier, sources: [] }, identity: {} })
  await oldSource.fire('click'); assert.equal(text, original); assert.equal(f.get('draft-map-detour-plan').disabled, true)
  assert.match(f.get('draft-map-detour-status').textContent, /unavailable/)
})

test('detour error states leave original route untouched and clear older successful previews', async () => {
  const f = screen(); await f.start(); const original = f.get('draft-cells').value
  f.get('draft-map-detour-avoid').value = '1,3'; await f.get('draft-map-detour-plan').fire('click')
  assert.equal(f.get('draft-map-detour-apply').disabled, false)
  f.get('draft-map-detour-avoid').value = '1,0\n1,1\n1,2\n1,3'; await f.get('draft-map-detour-plan').fire('click')
  assert.equal(f.get('draft-map-detour-apply').disabled, true); assert.equal(f.get('draft-map-detour-preview').textContent, '')
  assert.match(f.get('draft-map-detour-status').textContent, /No four-neighbor/)
  for (const cells of ['0,3\n0,3', '0,3\n999,999']) {
    f.get('draft-cells').value = cells; await f.get('draft-cells').fire('input'); await f.get('draft-map-detour-plan').fire('click')
    assert.equal(f.get('draft-map-detour-apply').disabled, true); assert.equal(f.get('draft-cells').value, cells)
  }
  f.get('draft-cells').value = original; await f.get('draft-cells').fire('input')
  f.get('draft-map-detour-avoid').value = '-1,0'; await f.get('draft-map-detour-plan').fire('click')
  assert.equal(f.get('draft-map-detour-apply').disabled, true); assert.equal(f.get('draft-cells').value, original)
})

test('legacy v1 drafts can adopt detours without schema promotion or inherited results', async () => {
  const f = screen(); await f.start(); await f.get('draft-discard').fire('click')
  const draft = forkMission(parent, 'q11-a', { version: 1 }); draft.edits.assumption_note = 'Known-cell detour, pending native assessment'
  const bytes = await exportDraft(draft)
  f.get('draft-file').files = [{ size: bytes.length, text: async () => bytes }]; await f.get('draft-file').fire('change')
  f.get('draft-map-detour-avoid').value = '1,3'; await f.get('draft-map-detour-plan').fire('click'); await f.get('draft-map-detour-apply').fire('click')
  const route = parseDraftCells(f.get('draft-cells').value)
  const create = URL.createObjectURL, revoke = URL.revokeObjectURL; let blob
  URL.createObjectURL = value => { blob = value; return 'blob:v1-detour' }; URL.revokeObjectURL = () => {}
  try {
    await f.get('draft-export').fire('click'); const loaded = await readDraft(await blob.text())
    assert.equal(loaded.draft.contract_id, 'moonmoon.mission-draft.v1'); assert.deepEqual(loaded.draft.edits.path_cells, route)
    assert.equal(loaded.draft.parent_digest, parent.envelope.dossier_digest); assert.equal(loaded.draft.physical_execution_allowed, false)
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke }
})

test('explicit grade-limited preview applies, undoes, exports and reopens an exact route without results', async () => {
  const f = screen(); await f.start()
  const original = f.get('draft-cells').value, saved = f.storage.getItem('moonmoon.study.v1/local-study/r1')
  const stage = async () => {
    assert.equal(f.get('draft-map-detour-mode').value, 'unrestricted')
    f.get('draft-map-detour-mode').value = 'grade-limited'; await f.get('draft-map-detour-mode').fire('change')
    assert.equal(f.get('draft-map-detour-grade').disabled, false)
    f.get('draft-map-detour-grade').value = '0.5'; f.get('draft-map-detour-avoid').value = '1,3'
    await f.get('draft-map-detour-plan').fire('click')
  }
  await stage()
  assert.equal(f.get('draft-cells').value, original)
  assert.match(f.get('draft-map-detour-status').textContent, /maximum absolute sampled edge grade ≤ 0.5 m\/m/)
  assert.match(f.get('draft-map-detour-status').textContent, /frozen cell size 20 m/)
  assert.match(f.get('draft-map-detour-status').textContent, /Replacement span only/)
  assert.equal(f.get('draft-map-detour-apply').disabled, false)
  await f.get('draft-map-detour-apply').fire('click'); const applied = f.get('draft-cells').value
  assert.notEqual(applied, original)
  await f.get('draft-map-undo').fire('click'); assert.equal(f.get('draft-cells').value, original)
  await stage(); await f.get('draft-map-detour-apply').fire('click')
  const create = URL.createObjectURL, revoke = URL.revokeObjectURL; let blob
  URL.createObjectURL = value => { blob = value; return 'blob:grade-detour' }; URL.revokeObjectURL = () => {}
  try {
    await f.get('draft-export').fire('click'); const bytes = await blob.text(), loaded = await readDraft(bytes)
    assert.deepEqual(loaded.draft.variants[0].edits.path_cells, parseDraftCells(applied))
    assert.deepEqual(loaded.draft.variants[1].edits.path_cells, parseDraftCells(original))
    assert.equal(loaded.draft.physical_execution_allowed, false); assert.equal(loaded.draft.review_required, true)
    await f.get('draft-discard').fire('click'); f.get('draft-file').files = [{size:bytes.length,text:async()=>bytes}]; await f.get('draft-file').fire('change')
    assert.equal(f.get('draft-cells').value, applied); assert.equal(f.get('draft-map-detour-mode').value, 'unrestricted')
    await f.get('draft-export').fire('click'); assert.equal(await blob.text(), bytes)
    assert.equal(f.storage.getItem('moonmoon.study.v1/local-study/r1'), saved)
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke }
})

test('grade controls require a bound, clear invalid previews, and guard cancel, mode and value staleness', async () => {
  const f = screen(); await f.start(); const original = f.get('draft-cells').value
  const stage = async () => {
    f.get('draft-map-detour-mode').value = 'grade-limited'; f.get('draft-map-detour-grade').value = '0.5'; f.get('draft-map-detour-avoid').value = '1,3'
    await f.get('draft-map-detour-plan').fire('click'); assert.equal(f.get('draft-map-detour-apply').disabled, false)
  }
  await stage(); f.get('draft-map-detour-grade').value = '0.6'; await f.get('draft-map-detour-apply').fire('click')
  assert.match(f.get('draft-map-detour-status').textContent, /preview again/)
  await stage(); f.get('draft-map-detour-mode').value = 'unrestricted'; await f.get('draft-map-detour-apply').fire('click')
  assert.match(f.get('draft-map-detour-status').textContent, /preview again/)
  await stage(); await f.get('draft-map-detour-grade').fire('input'); assert.equal(f.get('draft-map-detour-apply').disabled, true)
  await stage(); await f.get('draft-map-detour-cancel').fire('click'); await f.get('draft-map-detour-apply').fire('click'); assert.equal(f.get('draft-map-detour-preview').textContent, '')
  for (const bound of ['', ' ', '-1', 'Infinity', 'NaN', '1e309', '0x10', '0']) {
    await stage(); f.get('draft-map-detour-grade').value = bound; await f.get('draft-map-detour-plan').fire('click')
    assert.equal(f.get('draft-map-detour-apply').disabled, true); assert.equal(f.get('draft-map-detour-preview').textContent, '')
    assert.match(f.get('draft-map-detour-status').textContent, /No detour staged/)
  }
  assert.equal(f.get('draft-cells').value, original)
  f.get('draft-map-detour-mode').value = 'unrestricted'; await f.get('draft-map-detour-mode').fire('change')
  assert.equal(f.get('draft-map-detour-grade').disabled, true)
  await f.get('draft-map-detour-plan').fire('click'); assert.equal(f.get('draft-map-detour-apply').disabled, false)
  assert.match(f.get('draft-map-detour-status').textContent, /Unrestricted sampled edge grade/)
  await stage(); const stale = f.get('draft-map-detour-apply')
  f.get('draft-variant').value = '1'; await f.get('draft-variant').fire('change'); await stale.fire('click'); assert.equal(f.get('draft-cells').value, original)
})

test('grade-limited authoring calls the injected host seam only on explicit Run and preserves its failure', async () => {
  const submitted = [], receipt = { state: 'failed', message: 'Injected test host refused; no native assessment performed', run_id: 'run-' + 'a'.repeat(64), study_id: 'local-study', revision: 'r619-seam', draft_digest: 'test-only' }
  const f = screen({ async start(text) { submitted.push(text); return receipt }, async get() { return receipt } }); await f.start()
  f.get('draft-map-detour-mode').value = 'grade-limited'; f.get('draft-map-detour-grade').value = '0.5'; f.get('draft-map-detour-avoid').value = '1,3'
  await f.get('draft-map-detour-plan').fire('click'); await f.get('draft-map-detour-apply').fire('click')
  const route = parseDraftCells(f.get('draft-cells').value)
  assert.deepEqual(submitted, [])
  await f.get('run-start').fire('click'); assert.equal(submitted.length, 1)
  const draft = (await readDraft(submitted[0])).draft
  assert.deepEqual(draft.variants[0].edits.path_cells, route)
  assert.equal(draft.physical_execution_allowed, false); assert.equal(draft.review_required, true)
  assert.equal(draft.result, undefined)
  assert.match(f.get('run-status').textContent, /Injected test host refused/)
  assert.equal(f.get('run-open').disabled, true)
})
