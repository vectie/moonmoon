import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile } from 'node:fs/promises'
import { readStudy, sha256, StudyStore, bindMissionStudy } from './mission-study.js'
import { compareStudyRevision } from './mission-study-revision.js'

const previousText = await readFile(new URL('./fixtures/mission-study-local.json', import.meta.url), 'utf8')
const currentText = await readFile(new URL('./fixtures/mission-study-revised.json', import.meta.url), 'utf8')
const previous = await readStudy(previousText), current = await readStudy(currentText)
const pair = (old = previous, now = current) => compareStudyRevision(old, now, 'q11-b', 'q11-c')
async function changed(text, change) {
  const envelope = JSON.parse(text), dossier = JSON.parse(envelope.dossier_json)
  await change(dossier)
  envelope.dossier_json = JSON.stringify(dossier); envelope.dossier_digest = await sha256(envelope.dossier_json)
  return JSON.stringify(envelope)
}
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
  async fire(name) { if (this.disabled) return; for (const fn of this.events.get(name) || []) await fn({ preventDefault() {} }) }
}
const walk = node => [node, ...node.children.flatMap(walk)]
function ui(storage = new Storage()) {
  const panel = new Element(); panel.id = 'mission-study-panel'
  for (const id of ['file', 'status', 'comparison', 'sensitivity-matrix', 'id', 'revision', 'reviewer', 'choice', 'rationale', 'reopen', 'discard', 'save', 'reconcile', 'export', 'export-session']) {
    const node = new Element(); node.id = 'study-' + id; panel.appendChild(node)
  }
  const document = { getElementById: id => walk(panel).find(node => node.id === id), createElement: tag => new Element(tag) }
  const calls = [], client = new Proxy({}, { get: (_, name) => () => { calls.push(name); throw Error('Execution not expected') } })
  const bind = () => bindMissionStudy(document, () => storage, client); bind()
  const get = id => document.getElementById('study-' + id)
  const upload = async (id, text, reader = async () => text) => { get(id).files = [{ size: Buffer.byteLength(text), text: reader }]; await get(id).fire('change') }
  const select = async (a = 'q11-b', b = 'q11-c') => { get('revision-previous-session').value = a; await get('revision-previous-session').fire('change'); get('revision-current-session').value = b; await get('revision-current-session').fire('change') }
  return { panel, document, get, storage, calls, bind, select, upload,
    text: () => walk(get('revision-output')).map(node => node.textContent).join('\n'),
  }
}

test('native-producer revisions expose exact paired inputs, evidence and retained one-Wh change without ranking', () => {
  const before = JSON.stringify([previous, current]), comparison = pair()
  assert.equal(comparison.comparable, true)
  assert.deepEqual(comparison.metrics.find(row => row.label === 'Energy margin'), { label: 'Energy margin', unit: 'Wh', before: -622.3333333333334, after: -621.3333333333334, delta: 1 })
  assert.deepEqual(comparison.baselineChanges, []); assert.deepEqual(comparison.sourceChanges, [])
  assert.ok(comparison.inputChanges.some(row => row.key === 'environment' && row.before.path_cells.length === 5 && row.after.path_cells.length === 4))
  assert.ok(comparison.retained[0].blockers.includes('path cell 4,3 is absent from terrain source'))
  assert.ok(comparison.retained.every(row => row.decision === 'rejected' && row.blockers.some(b => b.includes('energy margin'))))
  assert.equal(comparison.evidence.current.result_ref.digest, current.alternatives[1].result_digest)
  assert.equal(JSON.stringify([previous, current]), before)
})

test('session pairing is explicit even when the same ID exists in both dossiers', () => {
  assert.throws(() => compareStudyRevision(previous, current), /Choose an exact/)
  assert.throws(() => compareStudyRevision(previous, current, 'q11-a', 'q11-b'), /Choose an exact/)
  const reference = compareStudyRevision(previous, current, 'q11-a', 'q11-a')
  assert.ok(reference.metrics.every(row => row.delta === 0)); assert.deepEqual(reference.inputChanges, [])
})

test('changed source-bound site revision with valid hashes withholds all cross-revision deltas', async () => {
  const text = await changed(currentText, async dossier => {
    dossier.site.revision = 'survey-r2'; dossier.site.uncertainty = 'New coverage requires independent review'
    for (const alternative of dossier.alternatives) {
      const baseline = JSON.parse(alternative.baseline_json); baseline.site = dossier.site
      alternative.baseline_json = JSON.stringify(baseline); alternative.baseline_digest = await sha256(alternative.baseline_json)
    }
  })
  const comparison = pair(previous, await readStudy(text))
  assert.equal(comparison.comparable, false); assert.deepEqual(comparison.baselineChanges.map(row => row.key), ['site'])
  assert.ok(comparison.metrics.every(row => row.delta === null))
  assert.equal(comparison.metrics[3].after, current.alternatives[1].result.energy.margin_wh)
})

test('supporting evidence additions and changed bytes prevent misleading common-baseline comparisons', async () => {
  const withSource = async text => changed(text, async dossier => { dossier.sources.push({ artifact_ref: 'evidence/dataset-note.txt', text: 'Updated source limits', digest: await sha256('Updated source limits') }) })
  const withAdded = await readStudy(await withSource(currentText)), addition = pair(previous, withAdded)
  assert.equal(addition.comparable, false); assert.deepEqual(addition.sourceChanges.map(row => row.key), ['evidence/dataset-note.txt'])
  const old = await readStudy(await withSource(previousText))
  assert.equal(pair(old, withAdded).comparable, true)
  const updated = await readStudy(await changed(withAdded.text, async dossier => {
    const source = dossier.sources.find(row => row.artifact_ref === 'evidence/dataset-note.txt'); source.text = 'More uncertain coverage'; source.digest = await sha256(source.text)
  }))
  assert.equal(pair(old, updated).comparable, false)
})

test('revision lineage is reported only by exact parent digest and conflicting same-identity evidence is incomparable', async () => {
  const linked = await readStudy(await changed(currentText, dossier => { dossier.parent_digest = previous.envelope.dossier_digest }))
  assert.equal(pair(previous, linked).directParent, true)
  const conflict = await readStudy(await changed(currentText, dossier => { dossier.revision = 'r1' }))
  assert.equal(pair(previous, conflict).identityConflict, true); assert.ok(pair(previous, conflict).metrics.every(row => row.delta === null))
  const same = compareStudyRevision(previous, previous, 'q11-a', 'q11-b')
  assert.equal(same.sameDossier, true); assert.equal(same.directParent, false)
})

test('actual study-panel handlers compare while review edits remain unsaved and never write or execute', async () => {
  const screen = ui(); screen.bind(); screen.bind()
  assert.equal(walk(screen.panel).filter(node => node.id === 'study-revision-comparison').length, 1)
  assert.equal(screen.get('revision-file').disabled, true)
  await screen.upload('file', currentText)
  screen.get('reviewer').value = 'Pending reviewer'; await screen.get('reviewer').fire('input')
  screen.get('rationale').value = 'Keep both energy blockers'; await screen.get('rationale').fire('input')
  const before = screen.get('comparison').textContent
  await screen.upload('revision-file', previousText)
  assert.match(screen.text(), /Choose both sessions explicitly/)
  assert.equal(screen.get('revision-previous-session').value, '')
  await screen.select()
  assert.match(screen.text(), /\+1 Wh/); assert.match(screen.text(), /path cell 4,3 is absent/)
  assert.match(screen.text(), /-621.3333333333334 Wh/); assert.match(screen.text(), /No new native replay/)
  assert.equal(screen.get('comparison').textContent, before)
  assert.equal(screen.get('reviewer').value, 'Pending reviewer'); assert.equal(screen.get('rationale').value, 'Keep both energy blockers')
  assert.deepEqual(screen.storage.writes, []); assert.deepEqual(screen.calls, [])
  await screen.get('revision-clear').fire('click')
  assert.equal(screen.text(), ''); assert.equal(screen.get('reviewer').value, 'Pending reviewer')
})

test('failed and oversized prior imports preserve the existing pair and reject before file reads where possible', async () => {
  const screen = ui(); await screen.upload('file', currentText); await screen.upload('revision-file', previousText); await screen.select()
  const before = screen.text()
  await screen.upload('revision-file', '{broken')
  assert.equal(screen.text(), before); assert.match(screen.get('revision-status').textContent, /unavailable/)
  let reads = 0; screen.get('revision-file').files = [{ size: 8388609, text: async () => { reads++; return previousText } }]
  await screen.get('revision-file').fire('change'); assert.equal(reads, 0); assert.equal(screen.text(), before)
  const tampered = JSON.parse(previousText); tampered.dossier_json += ' '
  await screen.upload('revision-file', JSON.stringify(tampered)); assert.match(screen.get('revision-status').textContent, /digest changed/)
  assert.equal(screen.text(), before); assert.deepEqual(screen.storage.writes, [])
})

test('clear and newer file selections supersede pending reads without reopening stale comparisons', async () => {
  const screen = ui(); await screen.upload('file', currentText)
  let release; const pending = screen.upload('revision-file', previousText, () => new Promise(resolve => { release = resolve }))
  await screen.get('revision-clear').fire('click'); release(previousText); await pending
  assert.equal(screen.text(), ''); assert.match(screen.get('revision-status').textContent, /cleared/)
  let oldRelease; const old = screen.upload('revision-file', previousText, () => new Promise(resolve => { oldRelease = resolve }))
  await screen.upload('revision-file', currentText); oldRelease(previousText); await old
  await screen.select('q11-a', 'q11-c')
  assert.match(screen.text(), /Both selections use the same exact dossier/)
  assert.equal(screen.get('revision-previous-session').children.some(node => node.value === 'q11-b'), false)
})

test('opening another current revision resets pair choices and prevents delayed prior reads attaching to it', async () => {
  const storage = new Storage(), store = new StudyStore(storage)
  await store.save(previous, null, null); await store.save(current, null, null); storage.writes = []
  const screen = ui(storage)
  const open = async revision => { screen.get('id').value = 'local-study'; screen.get('revision').value = revision; await screen.get('reopen').fire('click') }
  await open('r2'); await screen.upload('revision-file', previousText); await screen.select()
  let release; const pending = screen.upload('revision-file', previousText, () => new Promise(resolve => { release = resolve }))
  await open('r1'); release(previousText); await pending
  assert.equal(screen.text(), ''); assert.equal(screen.get('revision-previous-session').value, '')
  assert.match(screen.get('revision-status').textContent, /Current dossier changed/)
  assert.equal(screen.get('revision').value, 'r1'); assert.deepEqual(storage.writes, [])
})

test('untrusted study limits render as inert text and rejected current imports preserve comparison', async () => {
  const hostile = await changed(previousText, dossier => { dossier.limitations.push('<img src=x onerror=alert(1)>') })
  const screen = ui(); await screen.upload('file', currentText); await screen.upload('revision-file', hostile); await screen.select()
  assert.match(screen.text(), /<img src=x onerror=alert\(1\)>/)
  assert.ok(walk(screen.get('revision-output')).every(node => node.innerHTML === undefined))
  const before = screen.text(); await screen.upload('file', '{broken')
  assert.equal(screen.text(), before); assert.equal(screen.get('revision').value, 'r2')
})

test('incomparable prior sources show separate retained observations and saving still binds only the current review', async () => {
  const different = await changed(previousText, async dossier => {
    dossier.sources.push({ artifact_ref: 'evidence/old-coverage.txt', text: 'Prior uncertainty', digest: await sha256('Prior uncertainty') })
  })
  const screen = ui(); await screen.upload('file', currentText); await screen.upload('revision-file', different); await screen.select()
  assert.match(screen.text(), /Incomparable: common baseline or supporting source identities changed/)
  assert.match(screen.text(), /numeric deltas are withheld/); assert.doesNotMatch(screen.text(), /\+1 Wh/)
  assert.match(screen.text(), /-622.3333333333334 Wh/); assert.match(screen.text(), /-621.3333333333334 Wh/)
  screen.get('reviewer').value = 'Current reviewer'; screen.get('choice').value = 'none'; screen.get('rationale').value = 'Both runs remain rejected'
  await screen.get('save').fire('click')
  const loaded = await new StudyStore(screen.storage).open('local-study', 'r2')
  assert.equal(loaded.review.dossierDigest, current.envelope.dossier_digest)
  assert.equal(loaded.review.reviewer, 'Current reviewer')
  assert.equal(screen.storage.values.has('moonmoon.study.v1/local-study/r1'), false)
  const comparison = screen.text(); await screen.get('reopen').fire('click')
  assert.equal(screen.text(), comparison, 'same exact current evidence keeps the inspected pair')
})
