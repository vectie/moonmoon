// Explicit file handoff of completed digital work. This does not send to Book,
// accept an outcome, infer a business result, or grant hardware authority.
import { readStudy, sha256 } from './mission-study.js'
const need = (ok, text) => { if (!ok) throw new Error(text) }
const text = (value, name) => { need(typeof value === 'string' && value.trim() && value.length <= 4000, `Enter ${name} (up to 4000 characters)`); return value.trim() }
const encoder = new TextEncoder()
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b)

export async function exportOutcome(studyText, review, fields) {
  const study = await readStudy(studyText)
  const selected = study.alternatives.find(item => item.session_id === fields.session_id)
  need(selected, 'Choose an exact completed simulation session')
  need(['accepted', 'rejected'].includes(selected.result.result), 'The session has no completed simulation result')
  need(review?.authority === 'digital-only' && review.dossierDigest === study.envelope.dossier_digest &&
    typeof review.reviewer === 'string' && review.reviewer.trim() && typeof review.rationale === 'string' && review.rationale.trim() &&
    (review.choice === 'none' || study.alternatives.some(item => item.session_id === review.choice)), 'Save a named digital review of this exact dossier first; Book will make its own decision')
  need(Number.isSafeInteger(fields.observed_at) && fields.observed_at >= 0 && fields.observed_at <= 2147483647, 'Enter the observation time as UTC epoch seconds')
  const statement = {
    contract_version: 'moonmoon.digital-outcome-statement.v1',
    session_id: selected.session_id, dossier_digest: study.envelope.dossier_digest,
    dossier_artifact_digest: await sha256(study.text),
    result_digest: selected.result_digest, digital_review: review,
    outcome_summary: text(fields.outcome_summary, 'your digital outcome interpretation and limits'),
    observed_at: fields.observed_at,
    gaps: {},
  }
  for (const key of ['information', 'recognition', 'decisiveness']) {
    const gap = fields.gaps?.[key]
    need(Number.isSafeInteger(gap?.severity) && gap.severity >= 0 && gap.severity <= 5, `Choose ${key} gap severity 0–5 explicitly`)
    statement.gaps[key] = { present: gap.severity > 0, severity: gap.severity, summary: text(gap.summary, `${key} gap explanation, including an explicit reason when absent`) }
  }
  const hasGap = Object.values(statement.gaps).some(gap => gap.present)
  if (hasGap || fields.capability?.id || fields.capability?.version || fields.capability?.summary) {
    statement.capability = { id: text(fields.capability?.id, 'proposed capability ID'), version: text(fields.capability?.version, 'proposed capability version'), summary: text(fields.capability?.summary, 'proposed capability change') }
  }
  const statementText = JSON.stringify(statement, null, 2) + '\n'
  const make = async (id, bytes, provenance) => ({ reference: { reference_id: id, reference_version: '1', digest: await sha256(bytes), provenance_ref: provenance }, text: bytes, media_type: 'application/json' })
  const prefix = `moonmoon-${study.dossier.study_id}-${study.dossier.revision}-${selected.session_id}`
  const artifacts = [
    await make(prefix + '-dossier', study.text, 'moonmoon://digital-study/' + study.dossier.study_id + '/' + study.dossier.revision),
    await make(prefix + '-result', selected.resultText, 'moonmoon://digital-result/' + selected.session_id),
    await make(prefix + '-interpretation', statementText, 'moonmoon://operator-authored-digital-outcome'),
  ]
  const identity = await sha256(statementText)
  const submission = {
    contract_version: 'moonbook.bookkeeper.product_outcome_submission.v1',
    submission: { record_id: prefix + '-outcome-' + identity.slice(7), record_version: '1', record_digest: identity },
    source_product: 'moonmoon', deliverable_title: `Digital simulation · ${study.dossier.study_id} · ${selected.session_id}`,
    deliverable_summary: `Completed deterministic digital simulation: ${selected.result.result}. Retained robot, terrain, inputs, replay and source assumptions. No real-world performance or physical readiness claim.`,
    outcome_summary: statement.outcome_summary, owner_route: artifacts[0].reference.provenance_ref,
    evidence_refs: artifacts.map(item => item.reference), decision_evidence_id: artifacts[2].reference.reference_id,
    observed_at: fields.observed_at, recorded_at: fields.observed_at,
  }
  for (const key of ['information', 'recognition', 'decisiveness']) submission[key + '_gap'] = { ...statement.gaps[key], evidence_refs: artifacts.map(item => item.reference.reference_id) }
  if (statement.capability) Object.assign(submission, { capability_id: statement.capability.id, capability_version: statement.capability.version, capability_change_digest: await sha256(JSON.stringify(statement.capability)), capability_summary: statement.capability.summary })
  const payload_json = JSON.stringify({ submission, artifacts }, null, 2) + '\n'
  need(encoder.encode(payload_json).length <= 8388608, 'Retained outcome package exceeds 8 MiB')
  return JSON.stringify({ contract_version: 'moonbook.product-outcome-package.v1', package_digest: await sha256(payload_json), payload_json }, null, 2) + '\n'
}

export async function readOutcomeReceipt(raw) {
  need(typeof raw === 'string' && encoder.encode(raw).length <= 16777216, 'Choose a Book receipt up to 16 MiB')
  const receipt = JSON.parse(raw), pack = receipt.package
  need(receipt.contract_version === 'moonbook.product-outcome-readback.v1' && receipt.activation_authorized === false && receipt.external_side_effects_applied === false &&
    pack?.contract_version === 'moonbook.product-outcome-package.v1' && typeof pack.payload_json === 'string' && await sha256(pack.payload_json) === pack.package_digest && receipt.package_digest === pack.package_digest, 'Book receipt has changed source bytes or unsupported authority')
  const payload = JSON.parse(pack.payload_json), submission = payload.submission
  need(submission?.source_product === 'moonmoon' && same(receipt.progress?.submission, submission.submission), 'Receipt belongs to another submission')
  need(Array.isArray(payload.artifacts) && payload.artifacts.length === 3 && payload.artifacts.every(item => item?.media_type === 'application/json'), 'Receipt is missing retained MoonMoon evidence')
  for (const artifact of payload.artifacts) need(await sha256(artifact.text) === artifact.reference.digest && submission.evidence_refs.some(reference => same(reference, artifact.reference)), 'Retained evidence bytes changed')
  const [dossier, result, interpretation] = payload.artifacts
  const study = await readStudy(dossier.text), statement = JSON.parse(interpretation.text)
  const fields = { session_id: statement.session_id, outcome_summary: statement.outcome_summary, observed_at: statement.observed_at, gaps: statement.gaps, capability: statement.capability }
  const reconstructed = JSON.parse(await exportOutcome(study.text, statement.digital_review, fields))
  need(same(reconstructed, pack) && study.alternatives.some(item => item.session_id === statement.session_id && item.resultText === result.text), 'Receipt source and authored outcome do not match')
  need(['deliverable_review_required', 'deliverable_rejected', 'continue_required', 'assessment_review_required', 'assessment_rejected', 'reviewed_source_available'].includes(receipt.progress.state) && Array.isArray(receipt.reviews), 'Unsupported Book review progress')
  return { receipt, study, statement, resultText: result.text, raw }
}

export function bindMissionOutcome(document, getConfirmed, openReceived = null) {
  const node = id => document.getElementById('study-outcome-' + id)
  if (!node('export') || node('export').dataset.bound) return
  node('export').dataset.bound = 'true'
  let busy = false, version = 0, loaded = null
  const status = value => { node('status').textContent = value }
  const download = (value, name) => { const url = URL.createObjectURL(new Blob([value], { type: 'application/json' })); const link = document.createElement('a'); link.href = url; link.download = name; link.click(); URL.revokeObjectURL(url) }
  const run = fn => async () => { if (busy) return; busy = true; try { await fn() } catch (error) { status(error.message + ' · Current fields and previously loaded receipt were kept') } finally { busy = false } }
  const keys = ['session', 'summary', 'observed', 'information-severity', 'information-summary', 'recognition-severity', 'recognition-summary', 'decisiveness-severity', 'decisiveness-summary', 'capability-id', 'capability-version', 'capability-summary']
  keys.forEach(key => node(key).addEventListener('input', () => { version++ }))
  node('export').addEventListener('click', run(async () => {
    const stamp = version, current = await getConfirmed()
    const number = key => { need(node(key).value.trim(), 'Enter ' + key); return Number(node(key).value) }
    const gaps = Object.fromEntries(['information', 'recognition', 'decisiveness'].map(key => [key, { severity: number(key + '-severity'), summary: node(key + '-summary').value }]))
    const observed = node('observed').value.trim()
    need(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$/.test(observed) && Number.isFinite(Date.parse(observed)), 'Enter observation time in UTC, for example 2026-10-06T12:00:00Z')
    const value = await exportOutcome(current.study.text, current.review, { session_id: node('session').value.trim(), outcome_summary: node('summary').value, observed_at: Date.parse(observed) / 1000, gaps, capability: { id: node('capability-id').value, version: node('capability-version').value, summary: node('capability-summary').value } })
    const latest = await getConfirmed()
    need(stamp === version && latest.observed === current.observed && latest.study.text === current.study.text, 'Study or interpretation changed during export; retry after saving')
    download(value, 'moonmoon-digital-outcome.json')
    status('Exported retained digital result and your interpretation. Import this file in Book → Product outcomes. Book acceptance is still pending')
  }))
  node('receipt').addEventListener('change', run(async () => {
    const file = node('receipt').files?.[0]; need(file && file.size <= 16777216, 'Choose a Book receipt up to 16 MiB')
    const candidate = await readOutcomeReceipt(await file.text()); loaded = candidate
    node('readback').textContent = `Historical Book observation: ${candidate.receipt.progress.state}\n${candidate.receipt.progress.title}\n${candidate.statement.outcome_summary}\nBook reviews: ${candidate.receipt.reviews.map(review => `${review.reviewer?.reviewer_id || 'unknown'}: ${review.disposition} · ${review.summary}`).join('\n') || 'No completed Book decision in this receipt'}\nThe receipt is an unsigned local observation. Reopen Book and refresh for current status. Source review and Book authority remain separate.`
    status('Opened the received outcome and its original simulation. Choose Reopen original study below to inspect all source context; current edits are kept until that explicit action')
  }))
  node('reopen').addEventListener('click', run(async () => {
    need(loaded, 'Import a Book receipt first')
    if (openReceived) { await openReceived(loaded.study); status('Reopened the original study from this receipt. Book disposition remains in the receipt; existing digital reviews are preserved independently') }
    else { download(loaded.study.text, 'moonmoon-received-original-dossier.json'); status('Downloaded the original dossier; import it using Local dossier JSON to reopen') }
  }))
  node('result').addEventListener('click', () => { if (!loaded) return status('Import a Book receipt first'); download(loaded.resultText, 'moonmoon-received-original-result.json'); status('Downloaded the exact original digital result from this received outcome') })
}
