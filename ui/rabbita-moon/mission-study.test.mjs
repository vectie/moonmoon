import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile } from 'node:fs/promises'
import { webcrypto } from 'node:crypto'
import { readStudy, sha256, StudyStore, bindMissionStudy, sensitivityRows } from './mission-study.js'

if (!globalThis.crypto) globalThis.crypto = webcrypto
const fixtureText = await readFile(new URL('./fixtures/mission-study-local.json', import.meta.url), 'utf8')
const revisedText = await readFile(new URL('./fixtures/mission-study-revised.json', import.meta.url), 'utf8')
const fixture = await readStudy(fixtureText)
const key = 'moonmoon.study.v1/local-study/r1'
const localReview = { dossierDigest: fixture.envelope.dossier_digest, reviewer: 'Local reviewer', choice: 'none', rationale: 'Digital evidence only', authority: 'digital-only' }

class Storage {
  constructor() { this.values = new Map(); this.mode = ''; this.once = false }
  getItem(key) { if (this.mode === 'read-blocked') throw new Error('SecurityError'); return this.values.get(key) ?? null }
  setItem(key, value) {
    if (this.mode === 'quota' || this.mode === 'before-record' && !key.endsWith('/pending')) throw new Error('QuotaExceededError')
    this.values.set(key, value)
    if (this.mode === 'after-record' && !key.endsWith('/pending')) throw new Error('Acknowledgement lost')
  }
  removeItem(key) { if (this.mode === 'cleanup-blocked') throw new Error('Cleanup unavailable'); this.values.delete(key) }
}

async function revise(change) {
  const envelope = JSON.parse(fixtureText)
  const dossier = JSON.parse(envelope.dossier_json)
  await change(dossier)
  envelope.dossier_json = JSON.stringify(dossier)
  envelope.dossier_digest = await sha256(envelope.dossier_json)
  return JSON.stringify(envelope)
}

test('native-produced frozen dossier compares same baseline and retains negative energy', () => {
  assert.equal(fixture.alternatives.length, 2)
  assert.equal(fixture.alternatives[0].baseline_digest, fixture.alternatives[1].baseline_digest)
  assert.ok(fixture.alternatives[1].result.energy.margin_wh < 0)
  assert.equal(fixture.alternatives[1].result.result, 'rejected')
  assert.ok(fixture.alternatives[1].result.blockers.some(blocker => blocker.includes('absent from terrain source')))
  assert.equal(fixture.dossier.physical_readiness, false)
  assert.equal(fixture.alternatives[0].design.environment.calibration.qualified, false)
})

test('native result text survives browser persistence and fresh store exactly', async () => {
  const storage = new Storage()
  const store = new StudyStore(storage)
  const review = { dossierDigest: fixture.envelope.dossier_digest, reviewer: 'Local reviewer', choice: 'none', rationale: 'Negative energy remains blocked', authority: 'digital-only' }
  const raw = await store.save(fixture, review, null)
  const reopened = await new StudyStore(storage).open('local-study', 'r1')
  assert.equal(reopened.observed, raw)
  assert.equal(reopened.study.alternatives[1].resultText, fixture.alternatives[1].resultText)
  assert.equal(await sha256(reopened.study.alternatives[1].resultText), reopened.study.alternatives[1].result_digest)
  assert.deepEqual(reopened.review, review)
  await store.save(fixture, { ...review, rationale: 'Retain both digital alternatives' }, raw)
  assert.deepEqual((await store.open('local-study', 'r1')).reviewHistory, [review])
})

test('unknown post-write outcome blocks reopen and replacement until exact reconciliation', async () => {
  const storage = new Storage(), store = new StudyStore(storage)
  storage.mode = 'after-record'
  await assert.rejects(store.save(fixture, null, null), /Acknowledgement lost/)
  await assert.rejects(store.open('local-study', 'r1'), /outcome unknown/)
  await assert.rejects(store.save(fixture, null, null), /outcome unknown/)
  storage.mode = ''
  assert.match(await store.reconcile('local-study', 'r1'), /Exact save confirmed/)
  assert.equal((await store.open('local-study', 'r1')).study.envelope.dossier_digest, fixture.envelope.dossier_digest)
})

test('pre-write failure retains last confirmed bytes and allows explicit retry after reconcile', async () => {
  const storage = new Storage(), store = new StudyStore(storage)
  const previous = await store.save(fixture, null, null)
  storage.mode = 'before-record'
  await assert.rejects(store.save(fixture, localReview, previous), /QuotaExceeded/)
  assert.equal(storage.values.get(key), previous)
  storage.mode = ''
  assert.match(await store.reconcile('local-study', 'r1'), /not applied/)
  assert.equal((await store.open('local-study', 'r1')).observed, previous)
})

test('conflicting stored bytes and stale writers are never silently replaced', async () => {
  const storage = new Storage(), store = new StudyStore(storage)
  const raw = await store.save(fixture, null, null)
  await assert.rejects(store.save(fixture, null, null), /another tab|already saved/)
  storage.mode = 'after-record'
  await assert.rejects(store.save(fixture, localReview, raw))
  storage.mode = ''
  storage.values.set(key, 'unexpected bytes')
  await assert.rejects(store.reconcile('local-study', 'r1'), /Conflicting/)
  assert.ok(storage.values.has(key + '/pending'))
})

test('tampering, unsafe sources, physical claims and incomparable baselines are rejected', async () => {
  const envelope = JSON.parse(fixtureText); envelope.dossier_json += ' '
  await assert.rejects(readStudy(JSON.stringify(envelope)), /digest changed/)
  await assert.rejects(readStudy(await revise(dossier => { dossier.physical_readiness = true })), /digital-only/)
  await assert.rejects(readStudy(await revise(dossier => { dossier.sources[0].artifact_ref = 'https://example.com/x' })), /local source/)
  await assert.rejects(readStudy(await revise(dossier => { dossier.sources[0].text += 'changed' })), /digest changed/)
  await assert.rejects(readStudy(await revise(dossier => { dossier.alternatives[1].baseline_digest = 'sha256:' + '0'.repeat(64) })), /baseline digest changed/)
  await assert.rejects(readStudy(await revise(dossier => { dossier.site.elevation_unit = 'unknown' })), /units/)
})

test('rehashed stale evaluation and baseline metadata are rejected', async () => {
  await assert.rejects(readStudy(await revise(dossier => { dossier.site.frame = 'unrelated-frame' })), /baseline does not match/)
  const stale = await revise(async dossier => {
    const source = dossier.sources.find(item => item.artifact_ref === dossier.alternatives[1].evaluation_ref)
    const evaluation = JSON.parse(source.text)
    evaluation.uncertainty.route_coverage = 'fully-measured-no-gaps'
    source.text = JSON.stringify(evaluation)
    source.digest = await sha256(source.text)
  })
  await assert.rejects(readStudy(stale), /Evaluation does not match/)
  const wrongSeed = await revise(async dossier => {
    const source = dossier.sources.find(item => item.artifact_ref === dossier.alternatives[0].result_ref)
    const result = JSON.parse(source.text); result.seed += 1
    source.text = JSON.stringify(result); source.digest = await sha256(source.text)
  })
  await assert.rejects(readStudy(wrongSeed), /Design\/result identity mismatch/)
  const wrongGrid = await revise(async dossier => {
    const source = dossier.sources.find(item => item.artifact_ref === dossier.alternatives[0].result_ref)
    const result = JSON.parse(source.text); result.whole_grid_status = 'verified'
    source.text = JSON.stringify(result); source.digest = await sha256(source.text)
  })
  await assert.rejects(readStudy(wrongGrid), /grid or scenario binding mismatch/)
  const loweredReplays = await revise(async dossier => {
    const source = dossier.sources.find(item => item.artifact_ref === dossier.alternatives[0].replay_ref)
    const replay = JSON.parse(source.text); replay.required_replays = 1
    source.text = JSON.stringify(replay); source.digest = await sha256(source.text)
  })
  await assert.rejects(readStudy(loweredReplays), /Replay count does not match/)
})

test('rehashed refused or physical integration receipt and misleading bridge are rejected', async () => {
  const physical = await revise(async dossier => {
    const integrationRef = JSON.parse(dossier.sources.find(item => item.artifact_ref === dossier.alternatives[0].provenance_ref).text).moonrobo_integration_receipt_ref
    const integrationSource = dossier.sources.find(item => item.artifact_ref === integrationRef)
    const receipt = JSON.parse(integrationSource.text)
    receipt.physical_execution_performed = true
    integrationSource.text = JSON.stringify(receipt)
    integrationSource.digest = await sha256(integrationSource.text)
    for (const alternative of dossier.alternatives) {
      const source = dossier.sources.find(item => item.artifact_ref === alternative.provenance_ref)
      const provenance = JSON.parse(source.text); provenance.source_digests[0] = integrationSource.digest
      source.text = JSON.stringify(provenance); source.digest = await sha256(source.text)
    }
  })
  await assert.rejects(readStudy(physical), /integration receipt is incompatible/)
  const misleading = await revise(async dossier => {
    const source = dossier.sources.find(item => item.artifact_ref.endsWith('/bridge/bridge.json'))
    source.text = JSON.stringify({ mode: 'physical', physical_transport_enabled: true, design_id: 'test-rover', prior: { mode: 'simulation-only', physical_transport_enabled: false } })
    source.digest = await sha256(source.text)
  })
  await assert.rejects(readStudy(misleading), /bridge is not simulation-only/)
})

class Element {
  constructor() { this.dataset = {}; this.value = ''; this.textContent = ''; this.events = new Map(); this.files = []; this.children = [] }
  replaceChildren(...children) { this.children = children }
  appendChild(child) { this.children.push(child) }
  addEventListener(name, fn) { this.events.set(name, fn) }
  async fire(name) { return this.events.get(name)?.({ preventDefault() {} }) }
}
function ui(storage = new Storage()) {
  const ids = new Map(['mission-study-panel', ...['file','status','comparison','sensitivity-matrix','id','revision','reviewer','choice','rationale','reopen','discard','save','reconcile','export','export-session'].map(id => 'study-' + id)].map(id => [id, new Element()]))
  const downloads = []
  const document = { getElementById: id => ids.get(id), createElement: tag => Object.assign(new Element(), { tag, click() { downloads.push(this) } }) }
  bindMissionStudy(document, () => storage)
  const get = id => ids.get('study-' + id)
  const importText = async text => { get('file').files = [{ size: Buffer.byteLength(text), text: async () => text }]; await get('file').fire('change') }
  return { storage, get, downloads, importText }
}

test('actual control handlers import, save, reopen, review and export without physical authority', async () => {
  const f = ui()
  await f.importText(fixtureText)
  assert.match(f.get('comparison').textContent, /energy margin -/)
  assert.match(f.get('comparison').textContent, /No physical authority/)
  f.get('reviewer').value = 'Local reviewer'; await f.get('reviewer').fire('input')
  f.get('choice').value = 'none'; f.get('rationale').value = 'Energy blocker remains'
  await f.get('save').fire('click')
  assert.match(f.get('status').textContent, /Saved and read back/)
  const restarted = ui(f.storage)
  restarted.get('id').value = 'local-study'; restarted.get('revision').value = 'r1'
  await restarted.get('reopen').fire('click')
  assert.match(restarted.get('comparison').textContent, /Local reviewer: none/)
  restarted.get('export-session').value = 'q11-b'
  await restarted.get('export').fire('click')
  assert.equal(restarted.downloads.length, 1)
  assert.match(restarted.get('status').textContent, /acknowledgement remain pending/)
})

test('sensitivity matrix renders actual native values deltas assumptions blockers and accessible headers', async () => {
  const f = ui(); await f.importText(fixtureText)
  const rows = sensitivityRows(fixture), reference = fixture.alternatives[0].result
  assert.equal(rows[0].name, 'Reference')
  assert.equal(rows[0].delta.energy_margin_wh, 0)
  assert.equal(rows[1].delta.energy_margin_wh, fixture.alternatives[1].result.energy.margin_wh - reference.energy.margin_wh)
  assert.equal(rows[1].delta.duration_s, fixture.alternatives[1].result.duration_s - reference.duration_s)
  const table = f.get('sensitivity-matrix').children[0]
  assert.equal(table.tag, 'table'); assert.match(table.children[0].textContent, /Native sensitivity results/)
  assert.equal(table.children[1].children[0].children.length, 8)
  assert.ok(table.children[1].children[0].children.every(cell => cell.scope === 'col'))
  assert.equal(table.children[2].children.length, 2)
  assert.equal(table.children[2].children[0].children[0].scope, 'row')
  assert.match(table.children[2].children[1].children[5].textContent, /Δ/)
  assert.match(table.children[2].children[1].children[7].textContent, /absent from terrain source/)
  const authored = await readStudy(await readFile(new URL('./fixtures/mission-authored-local.json', import.meta.url), 'utf8'))
  authored.dossier.limitations.push('Authored variant: ' + JSON.stringify({ variant_id: 'alternative', name: '<script>Low energy</script>', assumption_note: 'Bounded available energy assumption' }))
  const named = sensitivityRows(authored)[1]
  assert.equal(named.name, '<script>Low energy</script>')
  assert.equal(named.assumption, 'Bounded available energy assumption')
  assert.equal(named.result, authored.alternatives[1].result)
})

test('unsaved review survives failed import, reopen and storage denial', async () => {
  const f = ui()
  await f.importText(fixtureText); await f.get('save').fire('click')
  f.get('reviewer').value = 'Unsaved reviewer'; await f.get('reviewer').fire('input')
  await f.importText(await revise(dossier => { dossier.revision = 'r2' }))
  assert.match(f.get('status').textContent, /current edits/)
  assert.equal(f.get('reviewer').value, 'Unsaved reviewer')
  await f.get('reopen').fire('click')
  assert.match(f.get('status').textContent, /Save edits first/)
  f.get('choice').value = 'none'; f.get('rationale').value = 'Keep draft'
  f.storage.mode = 'quota'
  await f.get('save').fire('click')
  assert.match(f.get('status').textContent, /draft is still open/)
  assert.equal(f.get('rationale').value, 'Keep draft')
  f.storage.mode = ''
  await f.get('reconcile').fire('click'); await f.get('save').fire('click')
  assert.match(f.get('status').textContent, /Saved and read back/)
})

test('new revision resets review and preserves previous revision', async () => {
  const f = ui()
  await f.importText(fixtureText)
  f.get('reviewer').value = 'Reviewer'; f.get('choice').value = 'none'; f.get('rationale').value = 'r1 only'
  await f.get('save').fire('click')
  await f.importText(revisedText)
  assert.equal(f.get('reviewer').value, '')
  assert.match(f.get('comparison').textContent, /Required for this exact revision/)
  assert.match(f.get('comparison').textContent, /revised-energy-assumption/)
  await f.get('save').fire('click')
  assert.ok(f.storage.values.has(key))
  assert.ok(f.storage.values.has('moonmoon.study.v1/local-study/r2'))
})

test('corrupted current review, history and reconciliation review cannot become reviewed context', async () => {
  const storage = new Storage(), store = new StudyStore(storage)
  const raw = await store.save(fixture, localReview, null)
  for (const change of [record => { record.review.authority = 'physical' }, record => { record.review.choice = 'not-a-session' }, record => { record.review.reviewer = ' ' }, record => { record.reviewHistory = [{ ...localReview, authority: 'physical' }] }, record => { record.reviewHistory = 'corrupt' }]) {
    const record = JSON.parse(raw); change(record); storage.values.set(key, JSON.stringify(record))
    await assert.rejects(store.open('local-study', 'r1'), /Saved review|review history/)
  }
  storage.values.set(key, raw)
  await assert.rejects(store.save(fixture, { ...localReview, authority: 'physical' }, raw), /Saved review/)
  const bad = JSON.stringify({ envelopeText: fixtureText, review: { ...localReview, authority: 'physical' }, reviewHistory: [] })
  storage.values.set(key + '/pending', JSON.stringify({ previous: raw, next: bad, digest: await sha256(bad) }))
  await assert.rejects(store.reconcile('local-study', 'r1'), /Saved review/)
  assert.equal(storage.values.get(key), raw)
  assert.ok(storage.values.has(key + '/pending'))
})
