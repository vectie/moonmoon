import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile, writeFile, mkdir, mkdtemp, readdir } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import http from 'node:http'
import { createMissionHost, verifyDraftResult } from './mission-run-host.js'
import { MissionRunClient, MissionRunController } from './mission-run.js'
import { readStudy, sha256, StudyStore, bindMissionStudy } from './mission-study.js'
import { forkMission, exportDraft } from './mission-authoring.js'

const source = await readFile(new URL('./fixtures/mission-study-local.json', import.meta.url), 'utf8')
const parent = await readStudy(source)
const robot = await readFile(new URL('./fixtures/moonrobo-simulation-input.json', import.meta.url), 'utf8')
const native = process.env.MOONMOON_NATIVE_CLI
const frozen = async (revision = 'ui-run-r2', change = () => {}) => {
  const draft = forkMission(parent, 'q11-a', { version: 1 })
  draft.revision = revision; draft.edits.assumption_note = 'Synthetic deterministic fixture; changed assumed energy, no physical readiness'
  draft.edits.terrain_available_energy_wh = 1; change(draft)
  return exportDraft(draft)
}
const until = async predicate => {
  const end = Date.now() + 30000
  while (Date.now() < end) { const value = await predicate(); if (value) return value; await new Promise(ok => setTimeout(ok, 20)) }
  assert.fail('Timed out waiting for an observed fixture state')
}
async function fixture(cliPath = '/does-not-exist/mission_study', existing) {
  const directory = existing || await mkdtemp(join(tmpdir(), 'moonmoon-local-host-'))
  await mkdir(join(directory, 'dist'), { recursive: true })
  await writeFile(join(directory, 'dist/index.html'), '<!doctype html><title>Inert static-host fixture</title>')
  const host = await createMissionHost({ cliPath, root: join(directory, 'runs'), staticRoot: join(directory, 'dist'), port: 0 })
  const client = new MissionRunClient((path, options) => fetch(host.origin + path, options))
  return { host, client, directory }
}
const terminal = async (client, id) => until(async () => { const run = await client.get(id); return ['failed','cancelled','completed','interrupted'].includes(run.state) && run })
class Storage {
  constructor() { this.values = new Map() }
  getItem(key) { return this.values.get(key) ?? null }
  setItem(key, value) { this.values.set(key, value) }
  removeItem(key) { this.values.delete(key) }
}
class Element {
  setAttribute(name, value) { (this.attributes ||= {})[name] = String(value) }
  constructor(tagName = '') { this.tagName = tagName; this.dataset = {}; this.value = ''; this.children = []; this.textContent = ''; this.files = []; this.events = new Map(); this.isConnected = true }
  set textContent(value) { this.text = String(value); this.children = [] }
  get textContent() { return this.text + this.children.map(child => child.textContent).join(' ') }
  appendChild(child) { this.children.push(child); return child }
  replaceChildren(...children) { this.text = ''; this.children = children }
  addEventListener(name, fn) { this.events.set(name, fn) }
  async fire(name) { return this.events.get(name)?.({ preventDefault() {} }) }
}
function ui(client, storage = new Storage()) {
  const nodes = new Map(), downloads = []
  const document = {
    location: { href: 'http://127.0.0.1/mission' },
    getElementById(id) { if (!nodes.has(id)) nodes.set(id, new Element()); return nodes.get(id) },
    createElement(tagName) { const element = new Element(tagName); element.click = () => downloads.push(element); return element },
  }
  const get = name => document.getElementById('study-' + name)
  bindMissionStudy(document, () => storage, client)
  const importParent = async () => {
    get('file').files = [{ size: Buffer.byteLength(source), text: async () => source }]
    await get('file').fire('change')
    get('reviewer').value = 'Fixture original reviewer'; get('choice').value = 'none'; get('rationale').value = 'Original digital study only'
    await get('save').fire('click')
  }
  return { get, document, downloads, storage, importParent }
}

test('production host is loopback-only, serves assets, rejects cross-origin and arbitrary routes', async () => {
  const f = await fixture()
  try {
    assert.equal(f.host.server.address().address, '127.0.0.1')
    assert.match(await (await fetch(f.host.origin)).text(), /Inert static-host fixture/)
    assert.equal((await fetch(f.host.origin + '/api/mission-runs')).status, 400)
    assert.equal((await fetch(f.host.origin + '/api/mission-runs', { headers: { 'X-MoonMoon-Local': '1', Origin: 'https://untrusted.invalid' } })).status, 400)
    const wrongHost = await new Promise(ok => { http.get(f.host.origin + '/api/mission-runs', { headers: { 'X-MoonMoon-Local': '1', Host: 'evil.invalid' } }, response => { response.resume(); ok(response.statusCode) }) })
    assert.equal(wrongHost, 400)
    assert.equal((await fetch(f.host.origin + '/api/mission-runs/run-' + '0'.repeat(64) + '/execute', { headers: { 'X-MoonMoon-Local': '1' } })).status, 404)
    await assert.rejects(f.client.start('{}'), /digest/)
    assert.deepEqual(await f.client.list(), [])
    await assert.rejects(createMissionHost({ cliPath: '/bin/false', root: join(f.directory, 'runs'), staticRoot: join(f.directory, 'dist'), port: 0 }), /locked/)
  } finally { await f.host.close() }
})

test('host binds retained v1 output to every accepted input and frozen safety constraint', async () => {
  for (const suffix of ['local', 'robot']) {
    const text = await readFile(new URL(`./fixtures/mission-draft-${suffix}.json`, import.meta.url), 'utf8')
    const result = await readStudy(await readFile(new URL(`./fixtures/mission-authored-${suffix}.json`, import.meta.url), 'utf8'))
    assert.equal((await verifyDraftResult(text, result)).length, 2)
    for (const change of [
      value => { value.alternatives.reverse() },
      value => { value.alternatives[1].session_id += '-other' },
      value => { value.alternatives[1].design.environment.illumination.terrain_available_energy_wh += 1 },
      value => { value.alternatives[1].design.verification_criteria.path.commanded_speed_mps += 1 },
      value => { value.alternatives[1].design.environment.path_cells.reverse() },
      value => { value.alternatives[1].design.scenario.seed += 1 },
      value => { value.alternatives[1].design.scenario.injected_faults.push('unaccepted') },
      value => { value.alternatives[0].design.constraints.route_length_m.max += 1 },
      value => { value.alternatives[0].design.robot_artifact.robot_revision += '-other' },
      value => { const baseline = JSON.parse(value.alternatives[0].baseline_json); baseline.terrain_digest = 'sha256:' + 'a'.repeat(64); value.alternatives[0].baseline_json = JSON.stringify(baseline) },
    ]) { const forged = structuredClone(result); change(forged); await assert.rejects(verifyDraftResult(text, forged), /bind/) }
  }
})

test('v2 batch retains exact inputs through duplicate retry cancellation and reconnect', async () => {
  const draft = forkMission(parent, 'q11-a'); draft.revision = 'v2-retained'
  draft.variants[0].name = 'Low energy'; draft.variants[0].edits.terrain_available_energy_wh = 1
  draft.variants[1].name = 'Slow'; draft.variants[1].edits.commanded_speed_mps = 0.05
  const text = await exportDraft(draft), f = await fixture('/usr/bin/yes')
  const first = await f.client.start(text)
  await until(async () => (await f.client.get(first.run_id)).state === 'running')
  assert.equal((await f.client.start(text)).run_id, first.run_id)
  assert.equal(await f.client.draft(first.run_id), text)
  await f.host.close()
  const reopened = await fixture('/usr/bin/false', f.directory)
  try {
    assert.equal((await reopened.client.get(first.run_id)).state, 'interrupted')
    assert.equal(await reopened.client.draft(first.run_id), text)
    assert.equal((await reopened.client.start(text)).state, 'interrupted')
    assert.equal((await reopened.client.reconcile(first.run_id)).state, 'interrupted')
  } finally { await reopened.host.close() }
  const cancelled = await fixture('/usr/bin/yes')
  try {
    const run = await cancelled.client.start(text)
    await until(async () => (await cancelled.client.get(run.run_id)).state === 'running')
    await cancelled.client.cancel(run.run_id)
    assert.equal((await terminal(cancelled.client, run.run_id)).state, 'cancelled')
    await assert.rejects(cancelled.client.result(run.run_id), /No confirmed/)
  } finally { await cancelled.host.close() }
})

test('exact duplicate Run reuses retained identity, different bytes cannot overwrite it, missing dependency is honest', async () => {
  const f = await fixture(), text = await frozen()
  try {
    const [a, b] = await Promise.all([f.client.start(text), f.client.start(text)])
    assert.equal(a.run_id, b.run_id)
    const failed = await terminal(f.client, a.run_id)
    assert.equal(failed.state, 'failed'); assert.equal(failed.native_exit_observed, false)
    assert.match(failed.message, /ENOENT/)
    await assert.rejects(f.client.result(a.run_id), /No confirmed/)
    await assert.rejects(f.client.start(await frozen('ui-run-r2', d => { d.edits.seed = 9 })), /new revision/)
    assert.equal((await f.client.list()).length, 1)
    assert.equal(await f.client.draft(a.run_id), text)
    assert.equal((await f.client.start(text)).state, 'failed')
  } finally { await f.host.close() }
})

test('actual nonzero process exit and actual cancellation never produce fake results', async () => {
  const failure = await fixture('/usr/bin/false')
  try {
    const start = await failure.client.start(await frozen('failure-r2')), end = await terminal(failure.client, start.run_id)
    assert.equal(end.state, 'failed'); assert.equal(end.exit_code, 1); assert.equal(end.native_exit_observed, true)
  } finally { await failure.host.close() }
  // yes is an explicitly inert process-lifecycle fixture, never scientific execution.
  const cancel = await fixture('/usr/bin/yes')
  try {
    const start = await cancel.client.start(await frozen('cancel-r2'))
    await until(async () => (await cancel.client.get(start.run_id)).state === 'running')
    const queued = await cancel.client.start(await frozen('cancel-queued-r2'))
    assert.equal(queued.state, 'queued')
    assert.equal((await cancel.client.cancel(queued.run_id)).state, 'cancelled')
    assert.equal((await cancel.client.get(queued.run_id)).native_exit_observed, false)
    await Promise.all([cancel.client.cancel(start.run_id), cancel.client.cancel(start.run_id)])
    const end = await terminal(cancel.client, start.run_id)
    assert.equal(end.state, 'cancelled'); assert.equal(end.native_exit_observed, true)
    assert.ok(['SIGTERM', 'SIGKILL'].includes(end.exit_signal))
    await assert.rejects(cancel.client.result(start.run_id), /No confirmed/)
  } finally { await cancel.host.close() }
})

test('shutdown and fresh host reconnect preserve unconfirmed interruption without rerunning', async () => {
  const f = await fixture('/usr/bin/yes'), text = await frozen('interruption-r2')
  const start = await f.client.start(text)
  await until(async () => (await f.client.get(start.run_id)).state === 'running')
  await f.host.close()
  const reopened = await fixture('/usr/bin/false', f.directory)
  try {
    const run = await reopened.client.get(start.run_id)
    assert.equal(run.state, 'interrupted')
    assert.equal(await reopened.client.draft(run.run_id), text)
    const reconciled = await reopened.client.reconcile(run.run_id)
    assert.equal(reconciled.state, 'interrupted'); assert.match(reconciled.message, /unconfirmed/)
    assert.equal((await reopened.client.start(text)).state, 'interrupted')
  } finally { await reopened.host.close() }
})

test('controller guards duplicate clicks, stale route, edited review, lost reply and reload', async () => {
  const text = await frozen(), id = 'run-' + (await sha256(text)).slice(7)
  let calls = 0, release, context = 'route-a', delivered = 0
  const state = { run_id: id, state: 'running' }
  const client = { async start() { calls++; await new Promise(ok => { release = ok }); return state }, async get() { return state } }
  const storage = new Storage(), controller = new MissionRunController({ client, storage, context: () => context, deliver: async () => { delivered++ }, update() {} })
  const start = controller.start(text); await until(() => release); await controller.start(text); release(); await start
  assert.equal(calls, 1)
  const realText = await readFile(new URL('./fixtures/mission-authored-local.json', import.meta.url), 'utf8'), checked = await readStudy(realText)
  Object.assign(state, { state: 'completed', study_id: checked.dossier.study_id, revision: checked.dossier.revision, parent_digest: checked.dossier.parent_digest, dossier_digest: checked.envelope.dossier_digest })
  client.result = async () => realText
  context = 'route-b'; await controller.refresh(); assert.equal(delivered, 0)
  await controller.refresh({ explicitlyOpen: true }); assert.equal(delivered, 1)
  await controller.refresh(); assert.equal(delivered, 1)
  context = 'another-study-opened'
  await controller.refresh({ explicitlyOpen: true }); assert.equal(delivered, 2)
  await controller.refresh(); assert.equal(delivered, 2)
  const reloaded = new MissionRunController({ client, storage, context: () => context, deliver: async () => { delivered++ }, update() {} })
  await reloaded.reconnect(); await reloaded.refresh(); assert.equal(delivered, 2)
  await reloaded.refresh({ explicitlyOpen: true }); assert.equal(delivered, 3)
  const lost = new MissionRunController({ client: { async start() { throw new Error('connection lost') }, get: client.get }, storage, context: () => context, deliver() {}, update() {} })
  await assert.rejects(lost.start(text), /connection lost/)
  assert.equal(lost.lastId, id); await lost.reconnect(); assert.equal(lost.current.state, 'completed')
})

test('denied run-ID storage keeps Run and existing Book controls bound with honest in-memory fallback', async () => {
  const denied = { getItem() { throw new Error('SecurityError fixture') }, setItem() { throw new Error('SecurityError fixture') } }
  const screen = ui({}, denied)
  assert.ok(screen.get('run-start').events.has('click'))
  assert.ok(screen.get('outcome-receipt').events.has('change'))
  assert.match(screen.get('run-status').textContent, /Browser run-ID storage is unavailable/)
  const text = await frozen(), id = 'run-' + (await sha256(text)).slice(7)
  const state = { run_id: id, state: 'running' }
  const controller = new MissionRunController({ client: { async start() { return state }, async get() { return state } }, storage: denied, context: () => 'view', deliver() {}, update() {} })
  assert.equal(controller.persistenceAvailable, false)
  assert.equal((await controller.start(text)).run_id, id)
  assert.equal(controller.lastId, id)
  await controller.reconnect()
  assert.equal(controller.current.state, 'running')
})

test('actual production UI handlers → host → native simulation → compare/review → Book outcome', { skip: !native }, async () => {
  const f = await fixture(native), screen = ui(f.client)
  const originalCreate = URL.createObjectURL, originalRevoke = URL.revokeObjectURL, blobs = new Map()
  URL.createObjectURL = blob => { const id = 'blob:fixture-' + blobs.size; blobs.set(id, blob); return id }; URL.revokeObjectURL = () => {}
  try {
    await screen.importParent()
    const original = screen.storage.getItem('moonmoon.study.v1/local-study/r1')
    screen.get('draft-parent-session').value = 'q11-a'; await screen.get('draft-fork').fire('click')
    screen.get('draft-revision').value = 'host-r2'; screen.get('draft-energy').value = '1'; screen.get('draft-speed').value = '0.05'
    screen.get('draft-note').value = 'Fixture edited energy and speed; robot adoption clears calibration and inherits power assumptions'
    await screen.get('draft-note').fire('input')
    screen.get('draft-robot').files = [{ size: Buffer.byteLength(robot), text: async () => robot }]; await screen.get('draft-robot').fire('change')
    await Promise.all([screen.get('run-start').fire('click'), screen.get('run-start').fire('click')])
    await until(() => /Imported actual native result automatically/.test(screen.get('status').textContent))
    const runs = await f.client.list(); assert.equal(runs.length, 1)
    const run = runs[0], text = await f.client.result(run.run_id), result = await readStudy(text)
    assert.equal(run.state, 'completed'); assert.equal(run.physical_execution_allowed, false); assert.equal(run.native_exit_observed, true)
    assert.equal(result.alternatives.length, 3)
    assert.equal(JSON.parse(await f.client.draft(run.run_id)).contract_id, 'moonmoon.mission-draft-envelope.v2')
    assert.match(screen.get('comparison').textContent, /Variant 1/)
    assert.match(screen.get('comparison').textContent, /Δ/)
    assert.equal(result.alternatives[1].result.robot_id, 'excavation-haul')
    assert.equal(result.alternatives[1].result.result, 'rejected'); assert.ok(result.alternatives[1].result.energy.margin_wh < 0)
    assert.equal(result.alternatives[1].result.duration_s, 1200)
    assert.match(result.dossier.limitations.join(' '), /Prior calibration was cleared/)
    assert.match(screen.get('comparison').textContent, /energy margin -/)
    const matrix = screen.get('sensitivity-matrix')
    assert.equal(matrix.children[0].tagName, 'table')
    assert.equal(matrix.children[0].children[2].children.length, 3)
    assert.match(matrix.textContent, /Native sensitivity results/)
    assert.match(matrix.textContent, /Variant 1/)
    assert.match(matrix.textContent, /Variant 2/)
    assert.match(matrix.textContent, /Δ/)
    assert.match(matrix.textContent, /energy margin is below/)
    assert.equal(screen.get('reviewer').value, '')
    assert.equal(screen.storage.getItem('moonmoon.study.v1/local-study/r1'), original)
    screen.get('reviewer').value = 'Fixture child reviewer'; screen.get('choice').value = 'none'; screen.get('rationale').value = 'Reject the negative energy margin; synthetic digital evidence only'
    await screen.get('save').fire('click')
    const saved = await new StudyStore(screen.storage).open('local-study', 'host-r2')
    assert.equal(saved.study.text, text); assert.equal(saved.review.reviewer, 'Fixture child reviewer')
    screen.get('outcome-session').value = result.alternatives[1].session_id; screen.get('outcome-observed').value = '2026-10-07T00:00:00Z'
    screen.get('outcome-summary').value = 'Actual native fixture result rejects energy adequacy. No physical or customer claim'
    for (const gap of ['information','recognition','decisiveness']) { screen.get('outcome-' + gap + '-severity').value = '0'; screen.get('outcome-' + gap + '-summary').value = 'No additional gap asserted in this bounded synthetic fixture; qualification limits retained' }
    await screen.get('outcome-export').fire('click')
    assert.equal(screen.downloads.length, 1)
    const bookText = await blobs.get(screen.downloads[0].href).text(), payload = JSON.parse(JSON.parse(bookText).payload_json)
    assert.equal(payload.artifacts[0].text, text)
    assert.equal(payload.artifacts[1].text, result.alternatives[1].resultText)
    assert.equal(payload.submission.source_product, 'moonmoon')
    assert.equal(screen.storage.getItem('moonmoon.study.v1/local-study/r1'), original)
    screen.get('id').value = 'local-study'; screen.get('revision').value = 'r1'; await screen.get('reopen').fire('click')
    assert.equal(screen.get('reviewer').value, 'Fixture original reviewer')
    await screen.get('run-open').fire('click')
    assert.equal(screen.get('revision').value, 'host-r2')
    assert.equal(screen.get('reviewer').value, 'Fixture child reviewer')
    screen.get('reviewer').value = 'New unsaved reviewer'; await screen.get('reviewer').fire('input')
    await screen.get('run-open').fire('click')
    assert.equal(screen.get('reviewer').value, 'New unsaved reviewer')
    assert.match(screen.get('run-status').textContent, /Save or explicitly discard/)
    await screen.get('discard').fire('click')
    if (process.env.MOONMOON_RUN_JOURNEY_DIR) {
      const out = process.env.MOONMOON_RUN_JOURNEY_DIR; await mkdir(out, { recursive: true })
      await writeFile(join(out, 'host-accepted-draft.json'), await f.client.draft(run.run_id))
      await writeFile(join(out, 'host-returned-dossier.json'), text)
      await writeFile(join(out, 'book-outcome-package.json'), bookText)
      await writeFile(join(out, 'run-receipt.json'), JSON.stringify(run, null, 2) + '\n')
      await writeFile(join(out, 'ui-comparison.txt'), screen.get('comparison').textContent)
      await writeFile(join(out, 'ui-matrix.txt'), matrix.textContent)
    }
    // A reload asks to open the actual retained result; it never invents an active process.
    const reload = ui(f.client, screen.storage)
    await until(() => /completed/.test(reload.get('run-status').textContent))
    assert.equal(reload.get('id').value, '')
    await reload.get('run-open').fire('click')
    assert.equal(reload.get('reviewer').value, 'Fixture child reviewer')
    const cancellation = await f.client.cancel(run.run_id)
    assert.equal(cancellation.state, 'completed') // completed/cancel race preserves committed result
  } finally { URL.createObjectURL = originalCreate; URL.revokeObjectURL = originalRevoke; await f.host.close() }
})

test('actual retained native output can reconcile interrupted host state without rerunning', { skip: !native }, async () => {
  const f = await fixture(native), text = await frozen('recover-r2')
  const run = await f.client.start(text); const completed = await terminal(f.client, run.run_id)
  assert.equal(completed.state, 'completed')
  const result = await f.client.result(run.run_id); await f.host.close()
  const path = join(f.directory, 'runs', run.run_id, 'state.json')
  const state = JSON.parse(await readFile(path, 'utf8')); state.state = 'running'; state.native_exit_observed = false
  await writeFile(path, JSON.stringify(state))
  const reopened = await fixture(native, f.directory)
  try {
    assert.equal((await reopened.client.get(run.run_id)).state, 'interrupted')
    const recovered = await reopened.client.reconcile(run.run_id)
    assert.equal(recovered.state, 'completed'); assert.equal(recovered.recovered_from_interruption, true)
    assert.equal(recovered.native_exit_observed, false)
    assert.equal(await reopened.client.result(run.run_id), result)
  } finally { await reopened.host.close() }
})

test('actual native four-variant batch binds all sessions fields names and assumptions', { skip: !native }, async () => {
  const draft = forkMission(parent, 'q11-a'); draft.revision = 'four-variant-native'
  draft.variants[0].name = 'Low energy'; draft.variants[0].edits.terrain_available_energy_wh = 1
  draft.variants[0].edits.assumption_note = 'Low available energy sensitivity'
  draft.variants[1].name = 'Slow'; draft.variants[1].edits.commanded_speed_mps = 0.05
  draft.variants.push({ ...structuredClone(draft.variants[1]), variant_id: 'reverse', name: 'Reverse route' }, { ...structuredClone(draft.variants[0]), variant_id: 'fault', name: 'Unknown fault' })
  draft.variants[2].edits.path_cells.reverse(); draft.variants[2].edits.seed = 2003
  draft.variants[3].edits.injected_faults = ['unsupported-fault']; draft.variants[3].edits.seed = 2004
  const text = await exportDraft(draft), f = await fixture(native)
  try {
    const run = await f.client.start(text), completed = await terminal(f.client, run.run_id)
    assert.equal(completed.state, 'completed', completed.message)
    const result = await readStudy(await f.client.result(run.run_id))
    const expected = await verifyDraftResult(text, result)
    assert.equal(expected.length, 5)
    assert.deepEqual(result.alternatives.map(item => item.session_id), expected)
    assert.ok(result.alternatives[1].result.energy.margin_wh < 0)
    assert.equal(result.alternatives[4].result.result, 'rejected')
    assert.ok(result.alternatives[4].result.blockers.length > 0)
    assert.equal((await f.client.start(text)).run_id, run.run_id)
    assert.equal(await f.client.draft(run.run_id), text)
    for (const mutate of [
      value => { value.alternatives.splice(2, 1) },
      value => { value.alternatives[3].design.environment.path_cells.reverse() },
      value => { value.alternatives[4].design.scenario.seed++ },
      value => { const baseline = JSON.parse(value.alternatives[2].baseline_json); baseline.calibration.qualified = !baseline.calibration.qualified; value.alternatives[2].baseline_json = JSON.stringify(baseline) },
      value => { value.dossier.limitations = value.dossier.limitations.filter(line => !line.startsWith('Authored variant: ')) },
    ]) { const forged = structuredClone(result); mutate(forged); await assert.rejects(verifyDraftResult(text, forged), /bind/) }
    const retained = await f.client.result(run.run_id)
    await f.host.close()
    const path = join(f.directory, 'runs', run.run_id, 'state.json')
    const state = JSON.parse(await readFile(path, 'utf8')); state.state = 'running'; state.native_exit_observed = false
    await writeFile(path, JSON.stringify(state))
    const reopened = await fixture(native, f.directory)
    try {
      assert.equal((await reopened.client.get(run.run_id)).state, 'interrupted')
      const recovered = await reopened.client.reconcile(run.run_id)
      assert.equal(recovered.state, 'completed', recovered.message)
      assert.equal(recovered.recovered_from_interruption, true)
      assert.equal(await reopened.client.result(run.run_id), retained)
    } finally { await reopened.host.close() }
  } finally { if (f.host.server.listening) await f.host.close() }
})

test('real native invalid route remains rejected and completion/cancellation race stays terminal', { skip: !native }, async () => {
  const f = await fixture(native)
  try {
    const invalid = await f.client.start(await frozen('invalid-route-r2', d => { d.edits.path_cells = [[999, 998], [999, 999]] }))
    const rejected = await terminal(f.client, invalid.run_id)
    assert.equal(rejected.state, 'completed'); assert.equal(rejected.native_exit_observed, true)
    const result = await readStudy(await f.client.result(invalid.run_id))
    assert.equal(result.alternatives[1].result.result, 'rejected')
    assert.ok(result.alternatives[1].result.blockers.length > 0)
    const race = await f.client.start(await frozen('cancel-race-r2'))
    await f.client.cancel(race.run_id)
    const final = await terminal(f.client, race.run_id)
    assert.ok(['completed', 'cancelled'].includes(final.state))
    if (final.state === 'cancelled') await assert.rejects(f.client.result(race.run_id), /No confirmed/)
    else assert.equal((await readStudy(await f.client.result(race.run_id))).envelope.dossier_digest, final.dossier_digest)
  } finally { await f.host.close() }
})

test('production host serves actual built MoonMoon entry and run-controller asset', { skip: !process.env.MOONMOON_BUILD_DIST || !native }, async () => {
  const root = await mkdtemp(join(tmpdir(), 'moonmoon-built-host-'))
  const host = await createMissionHost({ cliPath: native, root, staticRoot: process.env.MOONMOON_BUILD_DIST, port: 0 })
  try {
    const response = await fetch(host.origin), html = await response.text()
    assert.equal(response.status, 200); assert.match(html, /MoonMoon Rabbita/)
    const entry = /src="([^"]+\.js)"/.exec(html)
    assert.ok(entry, 'Built production entry must be referenced')
    const script = await fetch(new URL(entry[1], host.origin + '/'))
    assert.equal(script.status, 200)
    const bundle = await script.text()
    assert.match(bundle, /\/api\/mission-runs/)
    for (const marker of ['Frozen study route map', 'study-map-session', 'study-map-overlay', 'study-map-detail-selection', 'Map unavailable:', 'Exact native segment evidence missing or ambiguous']) assert.ok(bundle.includes(marker), marker)
    for (const marker of ['Draft route on frozen terrain', 'Append selected frozen cell', 'Undo last route edit', 'Move selected occurrence', 'Route occurrence to remove or reorder']) assert.ok(bundle.includes(marker), marker)
    const rabbita = (await readdir(join(process.env.MOONMOON_BUILD_DIST, 'assets'))).find(name => name.startsWith('_rabbita_main-entry-') && name.endsWith('.js'))
    assert.ok(rabbita, 'Actual compiled Rabbita entry must exist')
    const rendered = await fetch(host.origin + '/assets/' + rabbita)
    assert.equal(rendered.status, 200)
    const compiled = await rendered.text()
    for (const selector of ['Run digital mission', 'study-draft-variant', 'study-draft-variant-add', 'study-draft-variant-duplicate', 'study-draft-variant-remove', 'study-sensitivity-matrix', 'study-route-map']) assert.ok(compiled.includes(selector), selector)
    assert.ok(compiled.includes('study-draft-map'))
    const client = new MissionRunClient((path, options) => fetch(host.origin + path, options))
    assert.deepEqual(await client.list(), [])
    if (process.env.MOONMOON_SERVED_PROOF) await writeFile(process.env.MOONMOON_SERVED_PROOF, JSON.stringify({
      origin: host.origin, index_status: response.status, index_digest: await sha256(html),
      entry: entry[1], entry_status: script.status, entry_digest: await sha256(bundle),
      compiled_entry: '/assets/' + rabbita, compiled_status: rendered.status, compiled_digest: await sha256(compiled),
      map_code_served: true, compiled_map_mount_served: true, draft_editor_code_served: true, compiled_draft_mount_served: true, empty_run_list: true,
    }, null, 2) + '\n')
  } finally { await host.close() }
})
