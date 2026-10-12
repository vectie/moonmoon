import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile } from 'node:fs/promises'
import { readStudy, sha256, StudyStore, bindMissionStudy } from './mission-study.js'
import { normalizeScreenCriteria, screenAlternatives, createAlternativeScreen, readAlternativeScreen, SCREEN_LIMIT_BYTES } from './mission-study-screen.js'

const fixtureText = await readFile(new URL('./fixtures/mission-study-local.json', import.meta.url), 'utf8')
const revisedText = await readFile(new URL('./fixtures/mission-study-revised.json', import.meta.url), 'utf8')
const fixture = await readStudy(fixtureText), revised = await readStudy(revisedText)
const make = (criteria, text = fixtureText) => createAlternativeScreen(text, criteria, readStudy, sha256)
const inspect = (text, dossier = fixtureText) => readAlternativeScreen(text, dossier, readStudy, sha256)
const criteria = { min_energy_margin_wh: 100, max_duration_s: 600, max_segment_slope_deg: 15, note: 'Bounded route review; broader terrain remains uncertain.' }
class Storage {
  values = new Map(); writes = []
  getItem(key) { return this.values.get(key) ?? null }
  setItem(key, value) { this.writes.push(key); this.values.set(key, value) }
  removeItem(key) { this.writes.push(key); this.values.delete(key) }
}
class Element {
  constructor(tag = 'div') { this.tag = tag; this.id = ''; this.dataset = {}; this.value = ''; this.textContent = ''; this.events = new Map(); this.files = []; this.children = []; this.disabled = false }
  appendChild(child) { this.children.push(child); return child }
  replaceChildren(...children) { this.children = children }
  addEventListener(name, fn) { this.events.set(name, [...(this.events.get(name) || []), fn]) }
  async fire(name) { if (name === 'click' && this.disabled) return; for (const fn of this.events.get(name) || []) await fn({ preventDefault() {} }) }
  click() { this.clicked?.(this) }
}
const walk = node => [node, ...node.children.flatMap(walk)]
function ui(storage = new Storage()) {
  const panel = new Element(); panel.id = 'mission-study-panel'
  for (const id of ['file', 'status', 'comparison', 'sensitivity-matrix', 'id', 'revision', 'reviewer', 'choice', 'rationale', 'reopen', 'discard', 'save', 'reconcile', 'export', 'export-session']) {
    const node = new Element(); node.id = 'study-' + id; panel.appendChild(node)
  }
  const downloads = [], calls = []
  const document = { getElementById: id => walk(panel).find(node => node.id === id), createElement: tag => { const node = new Element(tag); node.clicked = link => downloads.push({ href: link.href, filename: link.download }); return node } }
  const client = new Proxy({}, { get: (_, name) => () => { calls.push(name); throw Error('No mission execution expected') } })
  const bind = () => bindMissionStudy(document, () => storage, client); bind()
  const get = id => document.getElementById('study-' + id)
  const upload = async (id, text, reader = async () => text) => { get(id).files = [{ size: Buffer.byteLength(text), text: reader }]; await get(id).fire('change') }
  const set = async (key, value) => { const input = get('screen-' + key); if (typeof value === 'boolean') input.checked = value; else input.value = value; await input.fire(typeof value === 'boolean' ? 'change' : 'input') }
  const apply = async values => { for (const [key, value] of Object.entries(values)) await set(key, value); await get('screen-apply').fire('click') }
  return { panel, get, storage, calls, bind, downloads, upload, set, apply,
    text: () => walk(get('screen-output')).map(node => node.textContent).join('\n'),
  }
}

test('reviewer screens actual native-produced alternatives together, preserving excluded energy and coverage evidence', () => {
  const before = JSON.stringify(fixture), report = screenAlternatives(fixture, criteria)
  assert.deepEqual(report.summary, { 'matches-review-criteria': 1, excluded: 1, 'needs-evidence': 0 })
  assert.deepEqual(report.alternatives.map(row => row.session_id), ['q11-a', 'q11-b'])
  assert.equal(report.alternatives[0].checks[1].status, 'pass', '600-second equality passes')
  assert.equal(report.alternatives[1].checks[0].observed, -622.3333333333334)
  assert.ok(report.alternatives[1].blockers.includes('path cell 4,3 is absent from terrain source'))
  assert.equal(report.alternatives[0].uncertainty.route_coverage, 'enumerated-path-only')
  assert.equal(report.alternatives[0].evidence.result_ref.digest, fixture.alternatives[0].result_digest)
  assert.equal(report.dossier_digest, fixture.envelope.dossier_digest)
  assert.equal(report.selection_performed, false); assert.equal(report.review_required, true); assert.equal(report.physical_readiness, false)
  assert.equal(JSON.stringify(fixture), before)
})

test('changing criteria explains why no route matches without hiding alternatives or treating blanks as zero', () => {
  const tight = screenAlternatives(fixture, { ...criteria, max_duration_s: 599 })
  assert.equal(tight.summary.excluded, 2)
  assert.equal(tight.alternatives[0].checks[1].status, 'fail')
  const durationOnly = screenAlternatives(fixture, { max_duration_s: 600 })
  assert.equal(durationOnly.alternatives[0].checks[0].status, 'not-selected')
  assert.equal(durationOnly.alternatives[1].status, 'excluded', 'a disabled energy criterion cannot remove a native energy blocker')
  const equality = screenAlternatives(fixture, { min_energy_margin_wh: fixture.alternatives[0].result.energy.margin_wh, max_segment_slope_deg: fixture.alternatives[0].result.maximum_measured_segment_slope_deg })
  assert.equal(equality.alternatives[0].status, 'matches-review-criteria')
})

test('required coverage remains missing evidence, rather than fabricated failure or a pass', () => {
  for (const key of ['require_declared_grid', 'require_declared_dataset']) {
    const report = screenAlternatives(fixture, { [key]: true })
    assert.equal(report.alternatives[0].status, 'needs-evidence')
    assert.equal(report.alternatives[0].checks.find(check => check.criterion === key).status, 'unknown')
    assert.equal(report.alternatives[1].status, 'excluded')
  }
  const missing = structuredClone(fixture); missing.alternatives[0].result.duration_s = null
  const report = screenAlternatives(missing, { max_duration_s: 600 })
  assert.equal(report.alternatives[0].checks[1].observed, null)
  assert.equal(report.alternatives[0].status, 'needs-evidence')
})

test('report round trip recomputes exact criteria and source identities, and changed criteria have a distinct digest', async () => {
  const first = await make(criteria), again = await make(criteria)
  assert.equal(first.text, again.text)
  const loaded = await inspect(first.text)
  assert.deepEqual(loaded.report, first.report)
  assert.notEqual(JSON.parse((await make({ ...criteria, max_duration_s: 599 })).text).report_digest, JSON.parse(first.text).report_digest)
  await assert.rejects(inspect(first.text, revisedText), /different exact dossier/)
  const forged = JSON.parse(first.text), report = JSON.parse(forged.report_json)
  report.alternatives[1].status = 'matches-review-criteria'; report.alternatives[1].blockers = []
  forged.report_json = JSON.stringify(report); forged.report_digest = await sha256(forged.report_json)
  await assert.rejects(inspect(JSON.stringify(forged)), /recomputed criteria/)
  const altered = JSON.parse(first.text); altered.report_json += ' '
  await assert.rejects(inspect(JSON.stringify(altered)), /digest changed/)
})

test('invalid requested limits fail with actionable messages before producing a report', async () => {
  assert.throws(() => normalizeScreenCriteria({}), /at least one/)
  assert.throws(() => normalizeScreenCriteria({ max_duration_s: '600' }), /finite nonnegative/)
  assert.throws(() => normalizeScreenCriteria({ min_energy_margin_wh: -10 }), /finite nonnegative/)
  assert.throws(() => normalizeScreenCriteria({ max_duration_s: Infinity }), /finite nonnegative/)
  assert.throws(() => normalizeScreenCriteria({ max_segment_slope_deg: 91 }), /at most 90/)
  assert.throws(() => normalizeScreenCriteria({ max_duration_s: 600, automatic_approval: true }), /supported/)
  const tampered = JSON.parse(fixtureText); tampered.dossier_json += ' '
  await assert.rejects(make(criteria, JSON.stringify(tampered)), /digest changed/)
})

test('production study panel applies criteria while preserving unsaved review edits and making no writes or execution calls', async () => {
  const screen = ui(); screen.bind(); screen.bind()
  assert.equal(walk(screen.panel).filter(node => node.id === 'study-screen-panel').length, 1)
  assert.equal(screen.get('screen-apply').disabled, true); assert.equal(screen.get('screen-download').disabled, true)
  await screen.upload('file', fixtureText)
  screen.get('reviewer').value = 'Named reviewer'; await screen.get('reviewer').fire('input')
  screen.get('rationale').value = 'My review is still a draft'; await screen.get('rationale').fire('input')
  await screen.apply({ min_energy_margin_wh: '100', max_duration_s: '600', max_segment_slope_deg: '15', note: '<img src=x> review criteria' })
  assert.match(screen.text(), /1 match review criteria; 1 excluded/)
  assert.match(screen.text(), /path cell 4,3 is absent/); assert.match(screen.text(), /-622.3333333333334 Wh/)
  assert.match(screen.text(), /conditional-not-declared/); assert.match(screen.text(), /<img src=x>/)
  assert.ok(walk(screen.get('screen-output')).every(node => node.innerHTML === undefined))
  assert.equal(screen.get('choice').value, '', 'screening never selects a review choice')
  assert.equal(screen.get('reviewer').value, 'Named reviewer'); assert.equal(screen.get('rationale').value, 'My review is still a draft')
  assert.deepEqual(screen.storage.writes, []); assert.deepEqual(screen.calls, [])
  await screen.set('max_duration_s', '599'); assert.equal(screen.get('screen-download').disabled, true); assert.equal(screen.text(), '')
  await screen.get('screen-apply').fire('click'); assert.match(screen.text(), /0 match review criteria; 2 excluded/)
  await screen.set('require_declared_dataset', true); await screen.set('max_duration_s', '600'); await screen.get('screen-apply').fire('click')
  assert.match(screen.text(), /1 need evidence/)
})

test('actual downloaded Blob reopens into a fresh panel and reconstructs criteria, rows and original exclusions', async () => {
  const source = ui(); await source.upload('file', fixtureText); await source.apply({ min_energy_margin_wh: '100', max_duration_s: '600' })
  let blob; const create = URL.createObjectURL, revoke = URL.revokeObjectURL, revoked = []
  URL.createObjectURL = value => { blob = value; return 'blob:screen-download' }; URL.revokeObjectURL = value => revoked.push(value)
  try {
    await source.get('screen-download').fire('click')
    assert.equal(source.downloads[0].filename, 'local-study-r1-screening.json'); assert.deepEqual(revoked, ['blob:screen-download'])
    const text = await blob.text(), imported = await inspect(text)
    assert.equal(imported.report.alternatives[1].status, 'excluded')
    const destination = ui(); await destination.upload('file', fixtureText); await destination.upload('screen-file', text)
    assert.equal(destination.get('screen-min_energy_margin_wh').value, '100'); assert.equal(destination.get('screen-max_duration_s').value, '600')
    assert.equal(destination.text(), source.text()); assert.deepEqual(destination.storage.writes, [])
    assert.match(destination.get('screen-status').textContent, /Reopened and recomputed/)
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke }
})

test('invalid or wrong-dossier report keeps current screening; edits, clear and replacement supersede pending imports', async () => {
  const text = (await make(criteria)).text, screen = ui()
  await screen.upload('file', fixtureText); await screen.upload('screen-file', text); const before = screen.text()
  await screen.upload('screen-file', '{broken'); assert.equal(screen.text(), before)
  await screen.upload('screen-file', (await make(criteria, revisedText)).text); assert.equal(screen.text(), before)
  let reads = 0; screen.get('screen-file').files = [{ size: SCREEN_LIMIT_BYTES + 1, text: async () => { reads++; return text } }]
  await screen.get('screen-file').fire('change'); assert.equal(reads, 0)
  let release; const pending = screen.upload('screen-file', text, () => new Promise(resolve => { release = resolve }))
  await screen.set('max_duration_s', '599'); release(text); await pending
  assert.equal(screen.get('screen-max_duration_s').value, '599'); assert.equal(screen.text(), '')
  let next; const cleared = screen.upload('screen-file', text, () => new Promise(resolve => { next = resolve }))
  await screen.get('screen-clear').fire('click'); next(text); await cleared
  assert.equal(screen.text(), ''); assert.equal(screen.get('screen-max_duration_s').value, '')
})

test('opening another revision resets criteria and prevents an old pending report from attaching; same dossier saves preserve screening', async () => {
  const storage = new Storage(), store = new StudyStore(storage)
  await store.save(fixture, null, null); await store.save(revised, null, null); storage.writes = []
  const screen = ui(storage), open = async revision => { screen.get('id').value = 'local-study'; screen.get('revision').value = revision; await screen.get('reopen').fire('click') }
  await open('r1'); await screen.apply({ max_duration_s: '600' }); const before = screen.text()
  await screen.get('save').fire('click'); assert.equal(screen.text(), before)
  const text = (await make(criteria)).text; let release
  const pending = screen.upload('screen-file', text, () => new Promise(resolve => { release = resolve }))
  await open('r2'); release(text); await pending
  assert.equal(screen.get('screen-max_duration_s').value, ''); assert.equal(screen.text(), '')
  assert.equal(screen.get('screen-download').disabled, true); assert.equal(screen.get('revision').value, 'r2')
})

test('criteria edits while asynchronous export verifies the dossier suppress the outdated download', async () => {
  const screen = ui(); await screen.upload('file', fixtureText); await screen.apply({ max_duration_s: '600' })
  const exporting = screen.get('screen-download').fire('click')
  await screen.set('max_duration_s', '599'); await exporting
  assert.deepEqual(screen.downloads, []); assert.equal(screen.get('screen-max_duration_s').value, '599')
  await screen.apply({ max_duration_s: 'bad' }); assert.match(screen.get('screen-status').textContent, /nonnegative decimal/)
  assert.equal(screen.get('screen-download').disabled, true)
  await screen.apply({ max_duration_s: '0' }); assert.match(screen.text(), /0 match review criteria; 2 excluded/)
})
