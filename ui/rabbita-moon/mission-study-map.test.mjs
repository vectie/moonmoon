import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile } from 'node:fs/promises'
import { webcrypto } from 'node:crypto'
import { readStudy, bindMissionStudy, sha256 } from './mission-study.js'
import { studyRouteMap, projectStudyCell, bindStudyRouteMap, STUDY_MAP_LIMITS } from './mission-study-map.js'

if (!globalThis.crypto) globalThis.crypto = webcrypto
const fixtureText = await readFile(new URL('./fixtures/mission-study-local.json', import.meta.url), 'utf8')
const revisedText = await readFile(new URL('./fixtures/mission-study-revised.json', import.meta.url), 'utf8')
const fixture = await readStudy(fixtureText)
const clone = () => structuredClone(fixture)
const terrain = study => study.dossier.sources.find(source => source.artifact_ref === study.alternatives[0].design.environment.terrain_source_path)

test('exact frozen source, [row,column] axes, spacing and unknown endpoint extension', () => {
  const map = studyRouteMap(fixture)
  assert.equal(map.available, true)
  assert.equal(map.samples.length, 16)
  assert.equal(map.sourceRef, 'terrain/route.csv')
  assert.equal(map.sourceDigest, terrain(fixture).digest)
  assert.equal(map.frame, 'local-test-grid row/column')
  assert.equal(map.cellSize, 20)
  assert.deepEqual(map.bounds, { minRow: 0, maxRow: 4, minCol: 0, maxCol: 3 })
  const origin = projectStudyCell(map, { row: 0, col: 0 })
  const row = projectStudyCell(map, { row: 1, col: 0 }), col = projectStudyCell(map, { row: 0, col: 1 })
  assert.equal(row.x, origin.x); assert.ok(row.y > origin.y)
  assert.equal(col.y, origin.y); assert.ok(col.x > origin.x)
  assert.equal(row.y - origin.y, col.x - origin.x)
  assert.equal(map.routes[1].points.at(-1).row, 4)
  assert.equal(map.routes[1].points.at(-1).sample, null)
  assert.equal(map.routes[1].segments.at(-1).status, 'unknown')
  assert.equal(map.routes[1].segments.at(-1).evidence, null)
  assert.ok(projectStudyCell(map, map.routes[1].points.at(-1)).y > projectStudyCell(map, map.routes[1].points.at(-2)).y)
})

test('native segment values and acceptance are retained without recomputation', () => {
  const study = clone(), native = study.alternatives[0].result.segment_evidence[0]
  native.accepted = false; native.slope_deg = 123.456; native.distance_m = 901; native.elevation_delta_m = -9
  const before = JSON.stringify(study), map = studyRouteMap(study)
  assert.deepEqual(map.routes[0].segments[0].evidence, native)
  assert.equal(map.routes[0].segments[0].status, 'rejected')
  assert.equal(JSON.stringify(study), before)
  map.routes[0].segments[0].evidence.accepted = true
  assert.equal(native.accepted, false)
})

test('missing native edges never shift evidence by index or reverse directed edges', () => {
  const study = clone(), entries = study.alternatives[0].result.segment_evidence
  entries.splice(0, 1)
  const map = studyRouteMap(study)
  assert.equal(map.routes[0].segments[0].status, 'unknown')
  assert.deepEqual(map.routes[0].segments[1].evidence, entries[0])
  assert.deepEqual(map.routes[0].segments[2].evidence, entries[1])
  const entry = entries[0]
  ;[entry.from_row, entry.to_row] = [entry.to_row, entry.from_row]
  assert.equal(studyRouteMap(study).routes[0].segments[1].status, 'unknown')
})

test('repeated route occurrences and alternative overlaps are kept at exact coordinates', () => {
  const study = clone(), item = study.alternatives[0], native = item.result.segment_evidence[0]
  item.design.environment.path_cells = [[0, 3], [1, 3], [0, 3], [1, 3]]
  item.result.segment_evidence = [{ ...native }, { ...native, from_row: 1, to_row: 0 }, { ...native, accepted: false }]
  const map = studyRouteMap(study), route = map.routes[0]
  assert.equal(route.points.length, 4); assert.equal(route.segments.length, 3)
  assert.equal(route.segments[0].status, 'accepted'); assert.equal(route.segments[2].status, 'rejected')
  assert.deepEqual(projectStudyCell(map, route.points[0]), projectStudyCell(map, route.points[2]))
  assert.deepEqual(projectStudyCell(map, route.points[0]), projectStudyCell(map, map.routes[1].points[0]))
  item.result.segment_evidence.pop()
  assert.equal(studyRouteMap(study).routes[0].segments[0].status, 'unknown')
  assert.equal(studyRouteMap(study).routes[0].segments[2].status, 'unknown')
})

test('sparse negative and extreme integer coordinates require no dense grid allocation', () => {
  const study = clone()
  terrain(study).text = 'tile_id,row,col,elevation_m\na,-2147483648,-2147483648,-2.5\nb,2147483647,2147483647,3.5\n'
  for (const item of study.alternatives) item.design.environment.path_cells = [[-2147483648, -2147483648], [2147483647, 2147483647]]
  const map = studyRouteMap(study)
  assert.equal(map.available, true); assert.equal(map.samples.length, 2)
  assert.equal(map.routes[0].points.length, 2)
  assert.equal(map.routes[0].segments[0].status, 'unknown')
  for (const point of map.routes[0].points) assert.ok(Object.values(projectStudyCell(map, point)).every(Number.isFinite))
})

test('malformed, duplicate, unsupported and nonfinite CSV disable only the map', () => {
  const cases = [
    ['wrong,row,col,elevation_m\na,0,0,1', /header/],
    ['tile_id,row,col,elevation_m\na,0,0,1\nb,0,0,1', /duplicate/],
    ['tile_id,row,col,elevation_m\na,0,0,NaN', /nonfinite/],
    ['tile_id,row,col,elevation_m\na,0,0,Infinity', /nonfinite/],
    ['tile_id,row,col,elevation_m\na,0,0,1e999', /nonfinite/],
    ['tile_id,row,col,elevation_m\na,0,0,', /nonfinite/],
    ['tile_id,row,col,elevation_m\na,0.5,0,2', /Malformed/],
    ['tile_id,row,col,elevation_m\na,2147483648,0,2', /Malformed/],
    ['tile_id,row,col,elevation_m\n"a",0,0,2', /Unsupported/],
    ['tile_id,row,col,elevation_m\na,0,0,2,extra', /Unsupported/],
    ['tile_id,row,col,elevation_m\n', /no samples/],
  ]
  for (const [text, message] of cases) {
    const study = clone(); terrain(study).text = text
    const map = studyRouteMap(study)
    assert.equal(map.available, false); assert.match(map.reason, message)
    assert.equal(study.alternatives[0].result.result, 'accepted')
  }
  const study = clone(); terrain(study).text = 'tile_id,row,col,elevation_m\r\na, -1, +2, -1.5e2\r\n'
  assert.equal(studyRouteMap(study).samples[0].elevation, -150)
})

test('all map boundaries are inclusive and oversized inputs are never truncated', () => {
  const study = clone()
  terrain(study).text = 'tile_id,row,col,elevation_m\n' + Array.from({ length: 4096 }, (_, n) => `t,${n},0,${n}`).join('\n')
  for (const item of study.alternatives) item.design.environment.path_cells = Array.from({ length: 256 }, (_, n) => [n, 0])
  while (study.alternatives.length < 8) study.alternatives.push({ ...structuredClone(study.alternatives[0]), session_id: 'extra-' + study.alternatives.length })
  let map = studyRouteMap(study)
  assert.equal(map.available, true); assert.equal(map.samples.length, 4096); assert.equal(map.routes.length, 8); assert.equal(map.routes[0].points.length, 256)
  terrain(study).text += '\nt,4096,0,0'; assert.match(studyRouteMap(study).reason, /4096/)
  terrain(study).text = terrain(fixture).text
  study.alternatives[0].design.environment.path_cells.push([256, 0]); assert.match(studyRouteMap(study).reason, /2–256/)
  study.alternatives[0].design.environment.path_cells.pop(); study.alternatives.push(study.alternatives[0]); assert.match(studyRouteMap(study).reason, /8 alternatives/)
  assert.deepEqual(STUDY_MAP_LIMITS, { samples: 4096, routeCells: 256, alternatives: 8 })
})

test('malformed route, missing exact source, incompatible spacing and coordinate overflow fail closed', () => {
  for (const value of [null, [], [[0, 0]], [[0, 0, 1], [1, 0]], [[0, '0'], [1, 0]], [[NaN, 0], [1, 0]], [[Infinity, 0], [1, 0]]]) {
    const study = clone(); study.alternatives[0].design.environment.path_cells = value
    assert.equal(studyRouteMap(study).available, false)
  }
  for (const value of [0, -1, NaN, Infinity, '20', 1e308]) {
    const study = clone(); for (const item of study.alternatives) item.design.environment.cell_size_m = value
    assert.equal(studyRouteMap(study).available, false)
  }
  const study = clone(); study.alternatives[0].design.environment.terrain_source_path = 'missing.csv'
  assert.match(studyRouteMap(study).reason, /Exact frozen/)
  const mismatch = clone(); mismatch.alternatives[1].design.environment.cell_size_m = 21
  assert.match(studyRouteMap(mismatch).reason, /share the exact/)
})

test('missing, duplicate, malformed and nonfinite segment evidence remains unknown', () => {
  for (const value of [null, [], [null], Array(256).fill({})]) {
    const study = clone(); study.alternatives[0].result.segment_evidence = value
    assert.equal(studyRouteMap(study).routes[0].segments[0].status, 'unknown')
  }
  for (const [key, value] of [['accepted', 'true'], ['slope_deg', Infinity], ['distance_m', NaN], ['elevation_delta_m', null], ['from_row', 0.1]]) {
    const study = clone(); study.alternatives[0].result.segment_evidence[0][key] = value
    assert.equal(studyRouteMap(study).routes[0].segments[0].status, 'unknown')
  }
  const study = clone(); study.alternatives[0].result.segment_evidence.push(study.alternatives[0].result.segment_evidence[0])
  assert.equal(studyRouteMap(study).routes[0].segments[0].status, 'unknown')
  const missing = clone(); terrain(missing).text = terrain(missing).text.replace('tile,1,3,313.479\n', '')
  const segment = studyRouteMap(missing).routes[0].segments[0]
  assert.equal(segment.status, 'unknown'); assert.equal(segment.evidence.accepted, true)
  assert.match(segment.reason, /terrain cell missing/)
})

class Element {
  constructor(tag = 'div') { this.tag = tag; this.dataset = {}; this.value = ''; this.checked = false; this.textContent = ''; this.events = new Map(); this.files = []; this.children = []; this.attrs = {} }
  replaceChildren(...children) { this.children = children }
  appendChild(child) { this.children.push(child); return child }
  setAttribute(key, value) { this.attrs[key] = value }
  addEventListener(name, fn) { this.events.set(name, fn) }
  async fire(name, event = {}) { return this.events.get(name)?.({ preventDefault() {}, ...event }) }
}
class Storage {
  values = new Map()
  getItem(key) { return this.values.get(key) ?? null }
  setItem(key, value) { this.values.set(key, value) }
  removeItem(key) { this.values.delete(key) }
}
const descendants = node => [node, ...node.children.flatMap(descendants)]
const textOf = node => descendants(node).map(node => node.textContent).join('\n')
function ui(storage = new Storage()) {
  const ids = new Map(['mission-study-panel', ...['file','status','comparison','sensitivity-matrix','route-map','id','revision','reviewer','choice','rationale','reopen','discard','save','reconcile','export','export-session'].map(id => 'study-' + id)].map(id => [id, new Element()]))
  const downloads = [], calls = []
  const document = {
    getElementById: id => ids.get(id) || [...ids.values()].flatMap(descendants).find(node => node.id === id),
    createElement: tag => Object.assign(new Element(tag), { click() { downloads.push(this) } }),
    createElementNS: (_namespace, tag) => new Element(tag),
  }
  bindMissionStudy(document, () => storage, new Proxy({}, { get: (_, method) => () => { calls.push(method); throw new Error('Map invoked execution') } }))
  const get = id => document.getElementById('study-' + id)
  const importText = async text => { get('file').files = [{ size: Buffer.byteLength(text), text: async () => text }]; await get('file').fire('change') }
  return { storage, get, downloads, importText, document, calls }
}

test('actual panel selection, overlay, start/end, keyboard inspection and listing are read-only', async () => {
  const f = ui(); await f.importText(fixtureText); await f.get('save').fire('click')
  const saved = [...f.storage.values], status = f.get('status').textContent, comparison = f.get('comparison').textContent
  assert.match(textOf(f.get('route-map')), /Declared frame: local-test-grid row\/column/)
  f.get('map-session').value = '1'; await f.get('map-session').fire('change')
  f.get('map-overlay').checked = true; await f.get('map-overlay').fire('change')
  assert.match(f.get('map-legend').textContent, /q11-a/); assert.match(f.get('map-legend').textContent, /q11-b \(selected\)/)
  assert.match(textOf(f.get('map-list')), /Cell 5 END: \[4,3\].*UNKNOWN/)
  assert.match(textOf(f.get('map-list')), /Segment 4: \[3,3\] → \[4,3\].*UNKNOWN/)
  f.get('map-detail-selection').value = 'cell:4'; await f.get('map-detail-selection').fire('change')
  assert.match(f.get('map-detail').textContent, /END.*\[4,3\].*row offset 80 m.*UNKNOWN/)
  f.get('map-detail-selection').value = 'segment:3'; await f.get('map-detail-selection').fire('change')
  assert.match(f.get('map-detail').textContent, /acceptance unknown/)
  const nodes = descendants(f.get('route-map')), endpoint = nodes.find(node => node.tag === 'circle' && node.attrs['aria-label']?.includes('Cell 5'))
  assert.equal(endpoint.attrs.tabindex, '0'); await endpoint.fire('keydown', { key: 'Enter' })
  assert.match(f.get('map-detail').textContent, /Cell 5 END/)
  assert.ok(nodes.some(node => node.tag === 'text' && node.textContent === 'S2'))
  assert.ok(nodes.some(node => node.tag === 'text' && node.textContent === 'E2'))
  assert.ok(nodes.some(node => node.tag === 'line' && node.attrs['stroke-dasharray'] === '7 5'))
  f.get('map-sample-selection').value = '0'; await f.get('map-sample-selection').fire('change')
  assert.match(f.get('map-detail').textContent, /exact elevation 341.536 m/)
  assert.deepEqual([...f.storage.values], saved); assert.equal(f.get('status').textContent, status); assert.equal(f.get('comparison').textContent, comparison)
  assert.deepEqual(f.calls, [])
  f.get('export-session').value = 'q11-b'; await f.get('export').fire('click'); assert.equal(f.downloads.length, 1)
})

test('failed import and unsaved review keep the prior map; new revision resets all view state', async () => {
  const f = ui(); await f.importText(fixtureText); await f.get('save').fire('click')
  f.get('map-session').value = '1'; await f.get('map-session').fire('change')
  const prior = f.get('map-session'), oldDetail = f.get('map-detail'), oldHost = textOf(f.get('route-map'))
  await f.importText('{broken'); assert.equal(f.get('map-session'), prior); assert.equal(textOf(f.get('route-map')), oldHost)
  f.get('reviewer').value = 'Unsaved reviewer'; await f.get('reviewer').fire('input')
  await f.importText(revisedText); assert.equal(f.get('map-session'), prior); assert.equal(f.get('reviewer').value, 'Unsaved reviewer')
  await f.get('discard').fire('click'); assert.equal(f.get('map-session'), prior)
  await f.importText(revisedText); assert.notEqual(f.get('map-session'), prior); assert.equal(f.get('map-session').value, '0'); assert.equal(f.get('map-overlay').checked, false)
  assert.match(textOf(f.get('route-map')), /local-study \/ r2/)
  const revisedDetail = f.get('map-detail').textContent
  prior.value = '1'; await prior.fire('change'); assert.equal(f.get('map-detail').textContent, revisedDetail)
  assert.equal(oldDetail.textContent.includes('q11-b'), true)
  await f.get('save').fire('click')
  const reopened = ui(f.storage); reopened.get('id').value = 'local-study'; reopened.get('revision').value = 'r1'; await reopened.get('reopen').fire('click')
  assert.match(textOf(reopened.get('route-map')), /local-study \/ r1/); assert.equal(reopened.get('map-session').value, '0')
})

test('a delayed import cannot overwrite a newer review or carry old map selections into a revision', async () => {
  const f = ui(); await f.importText(fixtureText); await f.get('save').fire('click')
  let release
  f.get('file').files = [{ size: Buffer.byteLength(revisedText), text: () => new Promise(resolve => { release = resolve }) }]
  const pending = f.get('file').fire('change')
  f.get('map-session').value = '1'; await f.get('map-session').fire('change')
  f.get('reviewer').value = 'Newer review'; await f.get('reviewer').fire('input')
  release(revisedText); await pending
  assert.match(f.get('status').textContent, /edits changed during import/)
  assert.match(textOf(f.get('route-map')), /local-study \/ r1/)
  assert.equal(f.get('map-session').value, '1'); assert.equal(f.get('reviewer').value, 'Newer review')
  await f.get('discard').fire('click')
  f.get('file').files = [{ size: Buffer.byteLength(revisedText), text: () => new Promise(resolve => { release = resolve }) }]
  const retry = f.get('file').fire('change')
  f.get('map-overlay').checked = true; await f.get('map-overlay').fire('change')
  release(revisedText); await retry
  assert.match(textOf(f.get('route-map')), /local-study \/ r2/)
  assert.equal(f.get('map-session').value, '0'); assert.equal(f.get('map-overlay').checked, false)
})

async function unsupportedTerrainEnvelope() {
  const envelope = JSON.parse(fixtureText), dossier = JSON.parse(envelope.dossier_json)
  const source = dossier.sources.find(source => source.artifact_ref === 'terrain/route.csv')
  source.text = source.text.replace('tile_id', 'unsupported_header'); source.digest = await sha256(source.text)
  for (const item of dossier.alternatives) {
    const baseline = JSON.parse(item.baseline_json); baseline.terrain_digest = source.digest; item.baseline_json = JSON.stringify(baseline); item.baseline_digest = await sha256(item.baseline_json)
    const provenanceSource = dossier.sources.find(source => source.artifact_ref === item.provenance_ref)
    const provenance = JSON.parse(provenanceSource.text); provenance.source_digests[2] = source.digest
    provenanceSource.text = JSON.stringify(provenance); provenanceSource.digest = await sha256(provenanceSource.text)
  }
  envelope.dossier_json = JSON.stringify(dossier); envelope.dossier_digest = await sha256(envelope.dossier_json)
  return JSON.stringify(envelope)
}

test('unsupported map never blocks valid study import, review, save, reopen or exact export', async () => {
  const f = ui(), text = await unsupportedTerrainEnvelope()
  assert.equal((await readStudy(text)).alternatives.length, 2)
  await f.importText(text); assert.match(textOf(f.get('route-map')), /Map unavailable: Unsupported terrain CSV header/)
  assert.match(f.get('comparison').textContent, /q11-b/)
  f.get('reviewer').value = 'Reviewer'; f.get('choice').value = 'none'; f.get('rationale').value = 'Header requires investigation'
  await f.get('save').fire('click'); assert.match(f.get('status').textContent, /Saved and read back/)
  await f.get('reopen').fire('click'); assert.match(f.get('comparison').textContent, /Reviewer: none/)
  f.get('export-session').value = 'q11-a'; await f.get('export').fire('click'); assert.equal(f.downloads.length, 1)
})

test('no SVG support still exposes full exact text and injection-shaped labels stay text', async () => {
  const f = ui(), study = clone(); delete f.document.createElementNS
  study.dossier.site.frame = '<img src=x onerror=alert(1)>'
  const render = bindStudyRouteMap(f.document); render(study)
  assert.match(textOf(f.get('route-map')), /SVG unavailable/)
  assert.match(textOf(f.get('route-map')), /<img src=x onerror=alert\(1\)>/)
  assert.ok(!descendants(f.get('route-map')).some(node => node.tag === 'img'))
  assert.match(textOf(f.get('map-list')), /native accepted/)
})

test('native rejected segments have explicit red evidence and loop start/end labels remain distinct', () => {
  const f = ui(), study = clone(), item = study.alternatives[0]
  item.design.environment.path_cells = [[0, 3], [1, 3], [0, 3]]
  const first = { ...item.result.segment_evidence[0], accepted: false }
  item.result.segment_evidence = [first, { ...first, from_row: 1, to_row: 0 }]
  bindStudyRouteMap(f.document)(study)
  const nodes = descendants(f.get('route-map'))
  const lines = nodes.filter(node => node.tag === 'line')
  assert.equal(lines.length, 2); assert.ok(lines.every(node => node.attrs.stroke === '#f87171'))
  assert.match(textOf(f.get('map-list')), /native rejected.*accepted false/)
  const start = nodes.find(node => node.tag === 'text' && node.textContent === 'S1'), end = nodes.find(node => node.tag === 'text' && node.textContent === 'E1')
  assert.equal(start.attrs.x, end.attrs.x); assert.notEqual(start.attrs.y, end.attrs.y)
})
