import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile, writeFile, mkdtemp, mkdir } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { execFileSync } from 'node:child_process'
import { webcrypto } from 'node:crypto'
import { readStudy, sha256, StudyStore, bindMissionStudy } from './mission-study.js'
import { forkMission, exportDraft, readDraft, readRobotInput } from './mission-authoring.js'

if (!globalThis.crypto) globalThis.crypto = webcrypto
const parentText = await readFile(new URL('./fixtures/mission-study-local.json', import.meta.url), 'utf8')
const robotText = await readFile(new URL('./fixtures/moonrobo-simulation-input.json', import.meta.url), 'utf8')
const parent = await readStudy(parentText)
const valid = () => { const draft = forkMission(parent, 'q11-a', { version: 1 }); draft.edits.assumption_note = 'Inert source fixture: lower assumed energy'; return draft }

test('mission fork preserves frozen parent and review boundary and roundtrips runnable inputs', async () => {
  const before = JSON.stringify(parent)
  const draft = valid()
  draft.edits.path_cells.reverse(); draft.edits.terrain_available_energy_wh = 1
  draft.edits.commanded_speed_mps = 0.05; draft.edits.seed = 2026
  draft.edits.injected_faults = ['unknown-wheel-fault']
  const frozen = await exportDraft(draft), reopened = await readDraft(frozen)
  assert.deepEqual(reopened.draft, draft)
  assert.equal(reopened.parent.text, parentText)
  assert.equal(JSON.stringify(parent), before)
  assert.equal(draft.review_required, true)
  assert.equal(draft.physical_execution_allowed, false)
  assert.equal(draft.result, undefined)
  assert.equal(draft.review, undefined)
})

test('default sensitivity fork freezes 2–4 independent named variants with version-matched envelopes', async () => {
  const draft = forkMission(parent, 'q11-a'), before = JSON.stringify(parent)
  assert.equal(draft.contract_id, 'moonmoon.mission-draft.v2')
  assert.equal(draft.edits, undefined); assert.equal(draft.variants.length, 2)
  draft.variants[0].name = 'Low energy'; draft.variants[0].edits.terrain_available_energy_wh = 1
  draft.variants[0].edits.path_cells.reverse()
  assert.notDeepEqual(draft.variants[0].edits.path_cells, draft.variants[1].edits.path_cells)
  draft.variants.push({ ...structuredClone(draft.variants[1]), variant_id: 'Case', name: 'Case-sensitive identity' }, { ...structuredClone(draft.variants[1]), variant_id: 'case', name: 'Fourth variant' })
  const text = await exportDraft(draft)
  assert.equal(JSON.parse(text).contract_id, 'moonmoon.mission-draft-envelope.v2')
  assert.deepEqual((await readDraft(text)).draft, draft)
  assert.equal(JSON.stringify(parent), before)
  const mismatch = JSON.parse(text); mismatch.contract_id = 'moonmoon.mission-draft-envelope.v1'
  await assert.rejects(readDraft(JSON.stringify(mismatch)), /version mismatch/)
  for (const mutate of [
    d => { d.variants.pop(); d.variants.pop(); d.variants.pop() },
    d => { d.variants.push(structuredClone(d.variants[0])) },
    d => { d.variants[1].variant_id = d.variants[0].variant_id },
    d => { d.variants[0].variant_id = 'reference' }, d => { d.variants[0].variant_id = '../escape' },
    d => { d.variants[0].variant_id = 'x'.repeat(65) }, d => { d.variants[0].name = '  ' },
    d => { d.variants[0].name = 'x'.repeat(121) }, d => { d.variants[3].edits.seed = 0 },
    d => { d.variants[3].edits.assumption_note = '' }, d => { d.edits = d.variants[0].edits },
  ]) { const invalid = structuredClone(draft); mutate(invalid); await assert.rejects(exportDraft(invalid)) }
})

test('actual native MoonRobo package is consumed with exact binding and no terrain or mission invented', async () => {
  const loaded = await readRobotInput(robotText)
  assert.equal(loaded.robot.design_id, 'excavation-haul')
  assert.equal(loaded.robot.revision, 'r1')
  assert.equal(loaded.robot.robot_artifact.physical_transport_enabled, false)
  const draft = valid(); draft.robot_envelope_json = robotText
  assert.equal((await readDraft(await exportDraft(draft))).draft.robot_envelope_json, robotText)
  assert.equal(loaded.robot.terrain, undefined)
  assert.equal(loaded.robot.mission, undefined)
})

test('changed digests, unsafe or physical robot input and refused integration are blocked', async () => {
  const envelope = JSON.parse(robotText); envelope.package_json += ' '
  await assert.rejects(readRobotInput(JSON.stringify(envelope)), /digest/)
  const change = async fn => { const e = JSON.parse(robotText), p = JSON.parse(e.package_json); await fn(p); e.package_json = JSON.stringify(p); e.package_digest = await sha256(e.package_json); return JSON.stringify(e) }
  await assert.rejects(readRobotInput(await change(p => { p.physical_execution_allowed = true })), /physical/)
  await assert.rejects(readRobotInput(await change(p => { p.sources[0].artifact_ref = '../escape' })), /Unsafe/)
  await assert.rejects(readRobotInput(await change(async p => {
    const source = p.sources.find(s => s.artifact_ref === p.integration_receipt_ref), receipt = JSON.parse(source.text)
    receipt.output.accepted = false; source.text = JSON.stringify(receipt); source.digest = await sha256(source.text)
  })), /integration receipt/)
})

test('invalid supported inputs, identity reuse and authority escalation cannot export', async () => {
  for (const mutate of [
    d => { d.revision = 'r1' }, d => { d.parent_digest = 'sha256:' + '0'.repeat(64) },
    d => { d.physical_execution_allowed = true }, d => { d.edits.assumption_note = '' },
    d => { d.edits.path_cells = [[0, 0]] }, d => { d.edits.path_cells[0] = [-1, 0] },
    d => { d.edits.terrain_available_energy_wh = NaN }, d => { d.edits.terrain_available_energy_wh = -1 },
    d => { d.edits.commanded_speed_mps = 0 }, d => { d.edits.seed = 2147483648 },
    d => { d.edits.injected_faults = ['fault', 'fault'] },
  ]) { const d = valid(); mutate(d); await assert.rejects(exportDraft(d)) }
  const e = JSON.parse(await exportDraft(valid())); e.draft_json += ' '
  await assert.rejects(readDraft(JSON.stringify(e)), /digest/)
})

class Element {
  constructor() { this.dataset = {}; this.value = ''; this.textContent = ''; this.events = new Map(); this.files = []; this.children = [] }
  appendChild(child) { this.children.push(child) }
  replaceChildren(...children) { this.children = children }
  addEventListener(name, fn) { this.events.set(name, fn) }
  async fire(name) { return this.events.get(name)?.({ preventDefault() {} }) }
}
class Storage {
  constructor() { this.values = new Map() }
  getItem(key) { return this.values.get(key) ?? null }
  setItem(key, value) { this.values.set(key, value) }
  removeItem(key) { this.values.delete(key) }
}
function ui(storage = new Storage()) {
  const names = ['file','status','comparison','id','revision','reviewer','choice','rationale','reopen','discard','save','reconcile','export','export-session']
  const draftNames = ['fork','discard','file','parent-session','baseline','id','revision','route','cells','energy','speed','seed','faults','note','robot','original-robot','robot-status','export','command','status','variant','variant-id','variant-name','variant-add','variant-duplicate','variant-remove','variants-status']
  const elements = new Map(['mission-study-panel', ...names.map(n => 'study-' + n), ...draftNames.map(n => 'study-draft-' + n)].map(n => [n, new Element()]))
  const downloads = []
  const doc = { getElementById: n => elements.get(n), createElement: () => Object.assign(new Element(), { click() { downloads.push(this) } }) }
  bindMissionStudy(doc, () => storage)
  const get = n => elements.get('study-' + n), d = n => get('draft-' + n)
  const importParent = async () => { get('file').files = [{ size: Buffer.byteLength(parentText), text: async () => parentText }]; await get('file').fire('change'); await get('save').fire('click') }
  return { get, d, downloads, storage, importParent }
}

test('real handlers fork edit export reopen and adopt robot without changing saved review', async () => {
  const f = ui(); await f.importParent()
  f.get('reviewer').value = 'Digital reviewer'; f.get('choice').value = 'none'; f.get('rationale').value = 'Original revision only'
  await f.get('save').fire('click')
  const key = 'moonmoon.study.v1/local-study/r1', original = f.storage.getItem(key)
  f.d('parent-session').value = 'q11-a'; await f.d('fork').fire('click')
  assert.match(f.d('status').textContent, /Fork opened/)
  assert.match(f.d('baseline').textContent, /constraints stay frozen/)
  f.d('energy').value = '1'; await f.d('energy').fire('input'); f.d('note').value = 'Low-energy design assumption'
  await f.d('fork').fire('click'); assert.match(f.d('status').textContent, /Export this draft/)
  f.d('robot').files = [{ size: Buffer.byteLength(robotText), text: async () => robotText }]; await f.d('robot').fire('change')
  assert.match(f.d('robot-status').textContent, /incomparable/)
  await f.d('export').fire('click')
  assert.equal(f.downloads.length, 1)
  assert.match(f.d('command').textContent, /moon run --target native cmd\/mission_study -- run-draft/)
  assert.match(f.d('status').textContent, /No simulation has run/)
  assert.equal(f.storage.getItem(key), original)
  const reopenedReview = await new StudyStore(f.storage).open('local-study', 'r1')
  assert.equal(reopenedReview.review.rationale, 'Original revision only')
  await f.d('discard').fire('click')
  const frozen = await exportDraft(valid()); f.d('file').files = [{ size: Buffer.byteLength(frozen), text: async () => frozen }]; await f.d('file').fire('change')
  assert.equal(f.d('seed').value, '1101')
  assert.match(f.d('status').textContent, /unrun draft/)
})

test('invalid edits and delayed imports preserve active draft and cannot silently export stale bytes', async () => {
  const f = ui(); await f.importParent(); f.d('parent-session').value = 'q11-a'; await f.d('fork').fire('click')
  f.d('note').value = 'Keep my work'; f.d('cells').value = '0,\n1,3'
  await f.d('export').fire('click'); assert.match(f.d('status').textContent, /row,column/); assert.equal(f.downloads.length, 0)
  f.d('cells').value = '0,3\n1,3\n2,3\n3,3'
  let finish; f.d('robot').files = [{ size: Buffer.byteLength(robotText), text: () => new Promise(resolve => { finish = resolve }) }]
  const loading = f.d('robot').fire('change'); f.d('energy').value = '15'; await f.d('energy').fire('input'); finish(robotText); await loading
  assert.match(f.d('status').textContent, /Inputs changed/)
  assert.equal(f.d('energy').value, '15')
  assert.equal(f.d('note').value, 'Keep my work')
})

test('variant controls preserve raw edits across switch duplicate remove export and reopen', async () => {
  const f = ui(); await f.importParent(); f.d('parent-session').value = 'q11-a'; await f.d('fork').fire('click')
  assert.match(f.d('variants-status').textContent, /2 named variants/)
  f.d('variant-name').value = 'Low power'; f.d('energy').value = '1'; f.d('note').value = 'Low-energy assumption'
  f.d('cells').value = '0,\n1,3' // Invalid unfinished text must survive switching.
  f.d('variant').value = '1'; await f.d('variant').fire('change')
  assert.notEqual(f.d('energy').value, '1')
  f.d('variant-name').value = 'Slow'; f.d('speed').value = '0.05'
  f.d('variant').value = '0'; await f.d('variant').fire('change')
  assert.equal(f.d('variant-name').value, 'Low power'); assert.equal(f.d('cells').value, '0,\n1,3')
  f.d('cells').value = '0,3\n1,3\n2,3\n3,3'
  await f.d('variant-duplicate').fire('click')
  assert.equal(f.d('energy').value, '1'); assert.equal(f.d('variant-name').value, 'Low power (copy)')
  f.d('energy').value = '12'; await f.d('variant-add').fire('click')
  assert.match(f.d('variants-status').textContent, /4 named variants/)
  assert.notEqual(f.d('energy').value, '12')
  await f.d('variant-add').fire('click'); assert.match(f.d('status').textContent, /At most four/)
  await f.d('variant-remove').fire('click'); assert.match(f.d('variants-status').textContent, /3 named variants/)
  const originalCreate = URL.createObjectURL, originalRevoke = URL.revokeObjectURL
  let blob
  URL.createObjectURL = value => { blob = value; return 'blob:sensitivity-test' }; URL.revokeObjectURL = () => {}
  try {
    await f.d('export').fire('click'); assert.equal(f.downloads.length, 1)
    const text = await blob.text(), loaded = await readDraft(text)
    assert.deepEqual(loaded.draft.variants.map(item => item.name), ['Low power', 'Slow', 'Low power (copy)'])
    assert.deepEqual(loaded.draft.variants.map(item => item.edits.terrain_available_energy_wh), [1, parent.alternatives[0].design.environment.illumination.terrain_available_energy_wh, 12])
    assert.equal(loaded.draft.variants[1].edits.commanded_speed_mps, 0.05)
    await f.d('discard').fire('click'); f.d('file').files = [{ size: Buffer.byteLength(text), text: async () => text }]; await f.d('file').fire('change')
    f.d('variant').value = '2'; await f.d('variant').fire('change'); assert.equal(f.d('energy').value, '12')
    await f.d('variant-remove').fire('click'); await f.d('variant-remove').fire('click'); assert.match(f.d('status').textContent, /at least two/)
  } finally { URL.createObjectURL = originalCreate; URL.revokeObjectURL = originalRevoke }
})

test('native-produced draft and result fixtures reopen as comparable digital evidence', async () => {
  for (const suffix of ['local', 'robot']) {
    const input = await readDraft(await readFile(new URL(`./fixtures/mission-draft-${suffix}.json`, import.meta.url), 'utf8'))
    const result = await readStudy(await readFile(new URL(`./fixtures/mission-authored-${suffix}.json`, import.meta.url), 'utf8'))
    assert.equal(result.dossier.parent_digest, input.draft.parent_digest)
    assert.equal(result.alternatives[0].baseline_digest, result.alternatives[1].baseline_digest)
    assert.equal(result.alternatives[1].result.result, 'rejected')
    assert.ok(result.alternatives[1].result.energy.margin_wh < 0)
    assert.equal(result.alternatives[1].result.duration_s, 1200)
    if (suffix === 'robot') {
      assert.notEqual(result.alternatives[0].baseline_digest, parent.alternatives[0].baseline_digest)
      assert.match(result.dossier.limitations.join(' '), /Prior calibration was cleared/)
    }
  }
})

test('browser-exported draft crosses actual native CLI and reimports with original review intact', { skip: !process.env.MOONMOON_NATIVE_CLI }, async () => {
  const directory = await mkdtemp(join(tmpdir(), 'moonmoon-browser-native-'))
  const draft = valid(); draft.robot_envelope_json = robotText
  draft.edits.path_cells.reverse(); draft.edits.terrain_available_energy_wh = 1; draft.edits.commanded_speed_mps = 0.05; draft.edits.seed = 2026
  const draftText = await exportDraft(draft), draftPath = join(directory, 'browser-draft.json'), workspace = join(directory, 'native-run')
  await writeFile(draftPath, draftText)
  const stdout = execFileSync(process.env.MOONMOON_NATIVE_CLI, ['run-draft', draftPath, workspace], { encoding: 'utf8', timeout: 30000 })
  const dossierPath = stdout.split('\n')[0], dossierText = await readFile(dossierPath, 'utf8'), checked = await readStudy(dossierText)
  assert.equal(checked.alternatives[1].result.robot_id, 'excavation-haul')
  assert.equal(checked.alternatives[1].result.duration_s, 1200)
  assert.ok(checked.alternatives[1].result.energy.margin_wh < 0)
  assert.equal(checked.alternatives[1].result.result, 'rejected')
  execFileSync(process.env.MOONMOON_NATIVE_CLI, ['inspect', dossierPath], { encoding: 'utf8', timeout: 30000 })
  assert.throws(() => execFileSync(process.env.MOONMOON_NATIVE_CLI, ['run-draft', draftPath, workspace], { encoding: 'utf8', timeout: 30000, stdio: 'pipe' }), error => {
    assert.notEqual(error.status, 0)
    assert.match(String(error.stdout) + String(error.stderr), /must not exist/)
    return true
  })
  const f = ui(); await f.importParent()
  f.get('reviewer').value = 'Original reviewer'; f.get('choice').value = 'none'; f.get('rationale').value = 'Only the parent'
  await f.get('save').fire('click'); const original = f.storage.getItem('moonmoon.study.v1/local-study/r1')
  f.get('file').files = [{ size: Buffer.byteLength(dossierText), text: async () => dossierText }]; await f.get('file').fire('change')
  assert.match(f.get('comparison').textContent, /energy margin -/)
  assert.match(f.get('comparison').textContent, /Required for this exact revision/)
  assert.equal(f.get('reviewer').value, '')
  await f.get('save').fire('click')
  assert.equal(f.storage.getItem('moonmoon.study.v1/local-study/r1'), original)
  if (process.env.MOONMOON_JOURNEY_DIR) {
    await mkdir(process.env.MOONMOON_JOURNEY_DIR, { recursive: true })
    await writeFile(join(process.env.MOONMOON_JOURNEY_DIR, 'browser-exported-draft.json'), draftText)
    await writeFile(join(process.env.MOONMOON_JOURNEY_DIR, 'native-returned-dossier.json'), dossierText)
    await writeFile(join(process.env.MOONMOON_JOURNEY_DIR, 'journey-result.json'), JSON.stringify({ native_cli: process.env.MOONMOON_NATIVE_CLI, input_digest: JSON.parse(draftText).draft_digest, dossier_digest: checked.envelope.dossier_digest, original_review_preserved: true, new_review_required: true, output: checked.alternatives[1].result, limitations: checked.dossier.limitations }, null, 2))
  }
})
