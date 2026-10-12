import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile, writeFile } from 'node:fs/promises'
import { webcrypto } from 'node:crypto'
import { readStudy, sha256, bindMissionStudy, StudyStore } from './mission-study.js'
import { exportOutcome, readOutcomeReceipt, bindMissionOutcome } from './mission-outcome.js'
if (!globalThis.crypto) globalThis.crypto = webcrypto
const source = await readFile(new URL('./fixtures/mission-authored-robot.json', import.meta.url), 'utf8')
const study = await readStudy(source)
const selected = study.alternatives[1]
const review = { authority: 'digital-only', dossierDigest: study.envelope.dossier_digest, reviewer: 'Fixture digital reviewer', choice: selected.session_id, rationale: 'Inspect the actual deterministic result and retain its synthetic terrain and unqualified calibration limits. Fixture review only.' }
const fields = () => ({ session_id: selected.session_id, observed_at: 1791302400, outcome_summary: 'Fixture interpretation: the authored digital mission completed with the recorded simulator decision. This says nothing about physical robot performance, customer acceptance or cash.', gaps: {
  information: { severity: 0, summary: 'No additional information gap is asserted within this bounded digital fixture. Retained synthetic terrain and unqualified calibration remain explicit limits.' },
  recognition: { severity: 0, summary: 'No additional recognition gap asserted: the fixture reviewer explicitly notes that the result is digital-only.' },
  decisiveness: { severity: 0, summary: 'No capability action is requested by this fixture. Book must independently decide whether to retain the interpretation.' },
} })
const pack = JSON.parse(await exportOutcome(source, review, fields()))
const payload = JSON.parse(pack.payload_json)
const receipt = state => ({ contract_version: 'moonbook.product-outcome-readback.v1', package_digest: pack.package_digest, package: pack, progress: { submission: payload.submission.submission, title: payload.submission.deliverable_title, state }, reviews: [], activation_authorized: false, external_side_effects_applied: false })

test('actual completed R8 robot mission exports original context and explicit operator statements deterministically', async () => {
  assert.equal(await exportOutcome(source, review, fields()), JSON.stringify(pack, null, 2) + '\n')
  assert.equal(payload.artifacts[0].text, source)
  assert.equal(payload.artifacts[1].text, selected.resultText)
  assert.equal(payload.submission.capability_id, undefined)
  assert.equal(payload.submission.source_product, 'moonmoon')
  assert.equal(payload.submission.submission.record_digest, await sha256(payload.artifacts[2].text))
  assert.equal(payload.submission.evidence_refs.length, 3)
  assert.match(payload.submission.deliverable_summary, /digital simulation/)
  assert.match(payload.submission.deliverable_summary, /No real-world/)
  const changed = fields(); changed.outcome_summary += ' A separate interpretation revision.'
  assert.notEqual(JSON.parse(JSON.parse(await exportOutcome(source, review, changed)).payload_json).submission.submission.record_id, payload.submission.submission.record_id)
  const reformattedSource = JSON.stringify(JSON.parse(source))
  assert.equal((await readStudy(reformattedSource)).envelope.dossier_digest, study.envelope.dossier_digest)
  const changedSource = JSON.parse(JSON.parse(await exportOutcome(reformattedSource, review, fields())).payload_json)
  assert.notEqual(changedSource.submission.submission.record_id, payload.submission.submission.record_id)
  assert.equal(changedSource.artifacts[0].text, reformattedSource)
  if (process.env.MOON_OUTCOME_PACKAGE_OUTPUT) await writeFile(process.env.MOON_OUTCOME_PACKAGE_OUTPUT, JSON.stringify(pack, null, 2) + '\n')
})

test('missing interpretations, source review, gap classification or proposal fail without inferring success', async () => {
  await assert.rejects(exportOutcome(source, null, fields()), /named digital review/)
  const empty = fields(); empty.outcome_summary = ''; await assert.rejects(exportOutcome(source, review, empty), /interpretation/)
  const invalid = fields(); invalid.gaps.information.severity = -1; await assert.rejects(exportOutcome(source, review, invalid), /severity/)
  const gap = fields(); gap.gaps.information.severity = 2; await assert.rejects(exportOutcome(source, review, gap), /capability ID/)
  gap.capability = { id: 'fixture.source-validation', version: '1', summary: 'Fixture proposal to qualify terrain separately before any future non-digital claim' }
  assert.equal(JSON.parse(JSON.parse(await exportOutcome(source, review, gap)).payload_json).submission.capability_id, gap.capability.id)
  const wrong = { ...review, dossierDigest: 'sha256:' + '0'.repeat(64) }; await assert.rejects(exportOutcome(source, wrong, fields()), /exact dossier/)
})

test('received pending, rejected and assessment dispositions reopen the same original result', async () => {
  for (const state of ['deliverable_review_required', 'deliverable_rejected', 'continue_required', 'assessment_review_required', 'assessment_rejected', 'reviewed_source_available']) {
    const loaded = await readOutcomeReceipt(JSON.stringify(receipt(state)))
    assert.equal(loaded.study.text, source)
    assert.equal(loaded.resultText, selected.resultText)
    assert.deepEqual(loaded.statement.digital_review, review)
  }
  const bad = receipt('continue_required'); bad.progress.submission = { ...bad.progress.submission, record_version: 'different' }; await assert.rejects(readOutcomeReceipt(JSON.stringify(bad)), /another submission/)
  const altered = receipt('deliverable_rejected'); altered.package = { ...pack, payload_json: pack.payload_json + ' ' }; await assert.rejects(readOutcomeReceipt(JSON.stringify(altered)), /changed source/)
  const activating = receipt('continue_required'); activating.activation_authorized = true; await assert.rejects(readOutcomeReceipt(JSON.stringify(activating)), /authority/)
})

class Node {
  constructor() { this.value = ''; this.dataset = {}; this.textContent = ''; this.events = new Map(); this.files = []; this.children = [] }
  appendChild(child) { this.children.push(child) }
  replaceChildren(...children) { this.children = children }
  addEventListener(key, fn) { this.events.set(key, fn) }
  async fire(key) { return this.events.get(key)?.() }
  click() { this.clicked = true }
}
function surface() {
  const nodes = new Map(), downloads = []
  const document = { getElementById(id) { if (!nodes.has(id)) nodes.set(id, new Node()); return nodes.get(id) }, createElement() { const node = new Node(); node.click = () => downloads.push(node); return node } }
  const get = id => document.getElementById('study-outcome-' + id)
  return { document, get, downloads }
}

test('real authoring controls export only after confirmation, retain drafts, and ignore duplicate pending clicks', async () => {
  const ui = surface(), value = fields(), pending = []
  let confirmations = 0
  const confirmed = { study, review, observed: 'confirmed saved fixture' }
  bindMissionOutcome(ui.document, async () => { confirmations++; if (pending.length) await pending.shift(); return confirmed })
  ui.get('session').value = value.session_id; ui.get('observed').value = new Date(value.observed_at * 1000).toISOString(); ui.get('summary').value = value.outcome_summary
  for (const key of Object.keys(value.gaps)) { ui.get(key + '-severity').value = '0'; ui.get(key + '-summary').value = value.gaps[key].summary }
  let release; pending.push(new Promise(resolve => { release = resolve }))
  const first = ui.get('export').fire('click'); await ui.get('export').fire('click'); release(); await first
  assert.equal(confirmations, 2); assert.equal(ui.downloads.length, 1)
  assert.match(ui.get('status').textContent, /Book acceptance is still pending/)
  ui.get('summary').value = ''; await ui.get('export').fire('click'); assert.equal(ui.downloads.length, 1); assert.equal(ui.get('session').value, value.session_id)
  ui.get('receipt').files = [{ size: 1000, text: async () => JSON.stringify(receipt('deliverable_rejected')) }]
  await ui.get('receipt').fire('change'); assert.match(ui.get('readback').textContent, /deliverable_rejected/)
  await ui.get('reopen').fire('click'); await ui.get('result').fire('click'); assert.equal(ui.downloads.length, 3)
  ui.get('receipt').files = [{ size: 10, text: async () => '{}' }]; await ui.get('receipt').fire('change'); assert.match(ui.get('readback').textContent, /deliverable_rejected/)
})

test('actual Book CLI receipt is validated against the original R8 producer result when supplied', { skip: !process.env.MOON_OUTCOME_BOOK_RECEIPT }, async () => {
  const loaded = await readOutcomeReceipt(await readFile(process.env.MOON_OUTCOME_BOOK_RECEIPT, 'utf8'))
  assert.equal(loaded.study.text, source); assert.equal(loaded.resultText, selected.resultText)
  assert.equal(loaded.receipt.progress.state, 'reviewed_source_available')
  assert.ok(loaded.receipt.reviews.length >= 2)
})

test('received original study reopens through real study controls preserving independent review and guarding pending or unsaved work', async () => {
  const ui = surface(), data = new Map(), storage = { getItem: key => data.get(key) ?? null, setItem: (key, value) => data.set(key, value), removeItem: key => data.delete(key) }
  const independent = { ...review, reviewer: 'Separately saved digital reviewer', rationale: 'This local review remains independent of the returned Book receipt' }
  await new StudyStore(storage).save(study, independent, null)
  const studyNode = name => ui.document.getElementById('study-' + name)
  bindMissionStudy(ui.document, () => storage)
  ui.get('receipt').files = [{ size: 1000, text: async () => JSON.stringify(receipt('deliverable_rejected')) }]
  await ui.get('receipt').fire('change')
  const key = `moonmoon.study.v1/${study.dossier.study_id}/${study.dossier.revision}`
  storage.setItem(key + '/pending', 'interrupted fixture')
  await ui.get('reopen').fire('click'); assert.match(ui.get('status').textContent, /interrupted save/)
  assert.equal(studyNode('id').value, '')
  storage.removeItem(key + '/pending')
  await ui.get('reopen').fire('click')
  assert.equal(studyNode('id').value, study.dossier.study_id)
  assert.equal(studyNode('reviewer').value, independent.reviewer)
  assert.match(studyNode('comparison').textContent, /Separately saved digital reviewer/)
  assert.match(ui.get('readback').textContent, /deliverable_rejected/)
  studyNode('reviewer').value = 'Unsaved reviewer'; await studyNode('reviewer').fire('input')
  await ui.get('reopen').fire('click'); assert.match(ui.get('status').textContent, /Save or explicitly discard/)
  assert.equal(studyNode('reviewer').value, 'Unsaved reviewer')
  assert.equal((await new StudyStore(storage).open(study.dossier.study_id, study.dossier.revision)).review.reviewer, independent.reviewer)
})
