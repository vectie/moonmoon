// Browser boundary for MoonBit-produced dossiers. Scientific calculation stays
// in the native runner; the local host is the only execution transport.
import { bindMissionAuthoring } from './mission-authoring.js'
import { bindMissionOutcome } from './mission-outcome.js'
import { bindStudyRouteMap } from './mission-study-map.js'
import { bindStudyLibrary } from './mission-study-library.js'
import { bindStudyScreen } from './mission-study-screen.js'
import { bindStudyRevisionComparison } from './mission-study-revision.js'
import { bindStudyArchive, createStudyArchive, readStudyArchive } from './mission-study-archive.js'
const encoder = new TextEncoder()
const need = (ok, message) => { if (!ok) throw new Error(message) }
const localRef = value => typeof value === 'string' && value.length > 0 && !/[\\:]/.test(value) && !value.startsWith('/') && value.split('/').every(part => part && part !== '.' && part !== '..')
const component = value => typeof value === 'string' && /^[A-Za-z0-9_-]{1,100}$/.test(value)
const digest = value => typeof value === 'string' && /^sha256:[a-f0-9]{64}$/.test(value)
const stable = value => JSON.stringify(value, function (key, item) {
  return item && !Array.isArray(item) && typeof item === 'object'
    ? Object.fromEntries(Object.keys(item).sort().map(name => [name, item[name]])) : item
})
export async function sha256(text) {
  return 'sha256:' + [...new Uint8Array(await globalThis.crypto.subtle.digest('SHA-256', encoder.encode(text)))].map(byte => byte.toString(16).padStart(2, '0')).join('')
}

export async function readStudy(text) {
  need(typeof text === 'string' && encoder.encode(text).length <= 8388608, 'Dossier must be at most 8 MiB')
  const envelope = JSON.parse(text)
  need(envelope.contract_id === 'moonmoon.mission-study-envelope.v1' && typeof envelope.dossier_json === 'string', 'Unsupported dossier envelope')
  need(await sha256(envelope.dossier_json) === envelope.dossier_digest, 'Dossier digest changed')
  const dossier = JSON.parse(envelope.dossier_json)
  need(dossier.contract_id === 'moonmoon.mission-study.v1' && component(dossier.study_id) && component(dossier.revision), 'Unsupported study identity')
  need(dossier.parent_digest === '' || digest(dossier.parent_digest), 'Invalid parent revision digest')
  need(dossier.physical_readiness === false && dossier.review_required === true, 'Dossier must remain digital-only and reviewable')
  const site = dossier.site
  need(site && ['site_id', 'revision', 'frame', 'coverage', 'uncertainty'].every(key => typeof site[key] === 'string' && site[key].trim()) && site.distance_unit === 'm' && site.elevation_unit === 'm', 'Site metadata or units are missing')
  need(Array.isArray(dossier.sources) && dossier.sources.length <= 64 && Array.isArray(dossier.alternatives) && dossier.alternatives.length >= 2 && dossier.alternatives.length <= 8, 'Use 2–8 alternatives and at most 64 frozen sources')
  const sources = new Map()
  let size = 0
  for (const source of dossier.sources) {
    need(localRef(source.artifact_ref) && !sources.has(source.artifact_ref) && typeof source.text === 'string', 'Invalid or repeated local source')
    const bytes = encoder.encode(source.text).length
    size += bytes
    need(bytes <= 1048576 && size <= 4194304, 'Frozen sources exceed the 1 MiB/file or 4 MiB/study limit')
    need(await sha256(source.text) === source.digest, 'Frozen source digest changed: ' + source.artifact_ref)
    sources.set(source.artifact_ref, source)
  }
  const source = ref => { need(sources.has(ref), 'Missing frozen source: ' + ref); return sources.get(ref) }
  const parse = ref => JSON.parse(source(ref).text)
  for (const alternative of dossier.alternatives) need(typeof alternative.baseline_json === 'string' && await sha256(alternative.baseline_json) === alternative.baseline_digest, 'Common baseline digest changed')
  const sessions = new Set()
  let baseline
  const alternatives = dossier.alternatives.map(item => {
    need(component(item.session_id) && !sessions.has(item.session_id), 'Invalid or duplicate session')
    sessions.add(item.session_id)
    const design = parse(item.design_ref)
    const result = parse(item.result_ref)
    const provenance = parse(item.provenance_ref)
    const replay = parse(item.replay_ref)
    const evaluation = parse(item.evaluation_ref)
    need(design.contract_id === 'moonsuite.robot-design.v1' && result.contract_id === 'moonmoon.robot-mission-result.v1' && result.authority === 'digital-only' && result.physical_readiness === false && design.mission.authority === 'digital-only' && design.robot_artifact.physical_transport_enabled === false, 'Unsupported or non-digital simulation')
    need(result.design_id === design.design_id && result.revision === design.revision && result.robot_id === design.robot_artifact.robot_id && result.robot_revision === design.robot_artifact.robot_revision && result.route_id === design.mission.route_id && result.scenario_id === design.scenario.scenario_id && result.seed === design.scenario.seed, 'Design/result identity mismatch')
    need(Number.isSafeInteger(result.seed) && result.terrain_source_path === design.environment.terrain_source_path && result.whole_grid_status === design.environment.whole_grid_status && result.whole_grid_max_neighbor_grade_deg === design.environment.whole_grid_max_neighbor_grade_deg && result.scenario_kind === design.scenario.scenario_kind && stable(result.injected_faults) === stable(design.scenario.injected_faults), 'Result terrain, grid or scenario binding mismatch')
    const terrain = source(design.environment.terrain_source_path)
    const integration = source(provenance.moonrobo_integration_receipt_ref)
    need(provenance.contract_id === 'moonmoon.mission-provenance.v1' && provenance.session_id === item.session_id && provenance.mission_design_ref === item.design_ref && provenance.result_ref === item.result_ref && provenance.replay_receipt_ref === item.replay_ref && provenance.terrain_ref === terrain.artifact_ref, 'Provenance identity mismatch')
    need(stable(provenance.source_digests.slice(0, 4)) === stable([integration.digest, source(item.design_ref).digest, terrain.digest, source(item.result_ref).digest]), 'Source provenance digest mismatch')
    for (const ref of provenance.source_refs) source(ref)
    for (const entry of provenance.dataset_evidence) need(source(entry.evidence_ref).digest === entry.digest, 'Dataset digest changed')
    const binding = design.robot_artifact
    const integrationReceipt = JSON.parse(integration.text)
    const output = integrationReceipt.output
    need(integrationReceipt.contract_id === 'moonrobo.digital-model-integration-receipt.v1' && integrationReceipt.adapter_id === 'moonrobo-local-v1' && integrationReceipt.operation_id === 'robot.integrate-digital-model' && integrationReceipt.status === 'succeeded' && integrationReceipt.physical_execution_performed === false && output?.accepted === true && output.robobook_ref === binding.artifact_root && output.model_ref === binding.artifact_root + '/' + binding.robot_urdf_path && output.validation_receipt_ref === binding.artifact_root + '/' + binding.validation_receipt_path && Array.isArray(integrationReceipt.evidence_refs) && integrationReceipt.evidence_refs.includes(output.model_ref) && integrationReceipt.evidence_refs.includes(output.validation_receipt_ref), 'MoonRobo integration receipt is incompatible, refused or mismatched')
    if (design.environment.calibration.qualified) source(design.environment.calibration.authoritative_source)
    for (const [path, hash] of [[binding.robot_json_path, binding.robot_json_sha256], [binding.robot_urdf_path, binding.robot_urdf_sha256], [binding.validation_receipt_path, binding.validation_receipt_sha256]]) need(source(binding.artifact_root + '/' + path).digest === 'sha256:' + hash, 'Robot artifact digest mismatch')
    const bridge = parse(binding.artifact_root + '/' + binding.bridge_config_path)
    need(bridge.mode === 'simulation-only' && bridge.physical_transport_enabled === false && bridge.design_id === binding.robot_id, 'Robot bridge is not simulation-only')
    need(replay.contract_id === 'moonmoon.mission-replay-receipt.v1' && replay.session_id === item.session_id && replay.design_id === design.design_id && replay.scenario_id === design.scenario.scenario_id && replay.seed === design.scenario.seed && replay.byte_equivalent === true && replay.completed_replays >= Math.max(2, replay.required_replays) && replay.first_result_ref === item.result_ref && replay.first_result_digest === source(item.result_ref).digest && replay.replay_result_digest === item.result_digest && source(replay.replay_result_ref).text === source(item.result_ref).text && item.result_digest === source(item.result_ref).digest, 'Replay receipt is incomplete or changed')
    need(Number.isSafeInteger(replay.required_replays) && Number.isSafeInteger(replay.completed_replays) && replay.required_replays === result.replay_count && replay.required_replays === design.verification_criteria.replay.required_runs, 'Replay count does not match the frozen design')
    need(evaluation.contract_id === 'moonmoon.mission-evaluation-report.v1' && evaluation.session_id === item.session_id && evaluation.physical_readiness === false && evaluation.review_required === true, 'Evaluation is not digital review evidence')
    const datasetCoverage = !provenance.dataset_evidence.length ? 'conditional-not-declared' : provenance.dataset_evidence.every(entry => localRef(entry.evidence_ref) && typeof entry.dataset_id === 'string' && entry.dataset_id.trim() && typeof entry.license_class === 'string' && entry.license_class.trim() && entry.status === 'available' && digest(entry.digest)) ? 'declared-available' : 'conditional-incomplete'
    const routeCoverage = result.whole_grid_status === 'verified' ? 'enumerated-path-with-declared-grid-verification' : 'enumerated-path-only'
    need(evaluation.design_id === result.design_id && evaluation.revision === result.revision && evaluation.scenario_id === result.scenario_id && evaluation.seed === result.seed && evaluation.decision === result.result && evaluation.result_claim === result.evidence_claim && evaluation.result_ref === item.result_ref && evaluation.provenance_ref === item.provenance_ref && evaluation.replay_receipt_ref === item.replay_ref && evaluation.replay_verified === true && stable(evaluation.blockers) === stable(result.blockers) && evaluation.uncertainty?.route_coverage === routeCoverage && evaluation.uncertainty?.external_dataset_coverage === datasetCoverage && evaluation.uncertainty?.calibration_claim === result.evidence_claim, 'Evaluation does not match frozen result/provenance')
    const current = stable({ site, terrain_digest: terrain.digest, robot_artifact: binding, calibration: design.environment.calibration, cell_size_m: design.environment.cell_size_m, whole_grid_status: design.environment.whole_grid_status, whole_grid_max_neighbor_grade_deg: design.environment.whole_grid_max_neighbor_grade_deg })
    need(stable(JSON.parse(item.baseline_json)) === current, 'Common baseline does not match the frozen site, terrain and robot')
    if (baseline === undefined) baseline = current
    need(current === baseline && digest(item.baseline_digest) && item.baseline_digest === dossier.alternatives[0].baseline_digest, 'Different source/robot baselines: alternatives are incomparable')
    need(Number.isFinite(result.energy?.margin_wh) && Number.isFinite(result.distance_m) && Number.isFinite(result.duration_s) && Number.isFinite(result.maximum_measured_segment_slope_deg) && Array.isArray(result.blockers), 'Invalid numeric simulation evidence')
    return { ...item, design, result, evaluation, resultText: source(item.result_ref).text }
  })
  return { text, envelope, dossier, alternatives }
}

export function sensitivityRows(study) {
  const metadata = new Map()
  for (const line of study.dossier.limitations) if (line.startsWith('Authored variant: ')) {
    try {
      const item = JSON.parse(line.slice('Authored variant: '.length))
      if (typeof item.variant_id === 'string' && typeof item.name === 'string' && typeof item.assumption_note === 'string') metadata.set(item.variant_id, item)
    } catch { /* Non-structured legacy limitations remain visible below. */ }
  }
  const reference = study.alternatives[0].result
  return study.alternatives.map((item, index) => {
    const authored = metadata.get(item.design.scenario.scenario_id.replace(/^authored-/, ''))
    return { session: item.session_id, name: index === 0 ? 'Reference' : authored?.name || item.session_id,
      assumption: index === 0 ? 'Frozen reference mission inputs' : authored?.assumption_note || 'See retained study limitations',
      result: item.result, coverage: item.evaluation.uncertainty.route_coverage,
      delta: { distance_m: item.result.distance_m - reference.distance_m, duration_s: item.result.duration_s - reference.duration_s, maximum_measured_segment_slope_deg: item.result.maximum_measured_segment_slope_deg - reference.maximum_measured_segment_slope_deg, energy_margin_wh: item.result.energy.margin_wh - reference.energy.margin_wh },
    }
  })
}

const measured = (value, delta, unit) => `${value} ${unit} (Δ ${delta > 0 ? '+' : ''}${Number(delta.toPrecision(12))} ${unit})`
function renderSensitivityMatrix(document, study) {
  const container = document.getElementById('study-sensitivity-matrix')
  if (!container?.replaceChildren) return
  if (!study) { container.replaceChildren(); return }
  const element = (tag, text) => { const node = document.createElement(tag); if (text !== undefined) node.textContent = text; return node }
  const table = element('table'); table.className = 'study-sensitivity-matrix'
  table.appendChild(element('caption', 'Native sensitivity results · deltas versus reference · digital review required'))
  const head = element('thead'), headers = element('tr')
  for (const title of ['Variant / session', 'Outcome', 'Distance', 'Duration', 'Maximum measured slope', 'Energy margin', 'Assumptions', 'Coverage / blockers']) { const cell = element('th', title); cell.scope = 'col'; headers.appendChild(cell) }
  head.appendChild(headers); table.appendChild(head)
  const body = element('tbody')
  for (const row of sensitivityRows(study)) {
    const tr = element('tr')
    const values = [row.name + '\n' + row.session, row.result.result,
      measured(row.result.distance_m, row.delta.distance_m, 'm'), measured(row.result.duration_s, row.delta.duration_s, 's'),
      measured(row.result.maximum_measured_segment_slope_deg, row.delta.maximum_measured_segment_slope_deg, 'degrees'), measured(row.result.energy.margin_wh, row.delta.energy_margin_wh, 'Wh'),
      row.assumption, row.coverage + '\n' + (row.result.blockers.join('; ') || 'none in this bounded simulation')]
    values.forEach((value, index) => { const cell = element(index === 0 ? 'th' : 'td', value); if (index === 0) cell.scope = 'row'; tr.appendChild(cell) })
    body.appendChild(tr)
  }
  table.appendChild(body); container.replaceChildren(table)
}

const keyFor = (id, revision) => {
  need(component(id) && component(revision), 'Enter a study ID and revision using letters, digits, hyphens or underscores')
  return `moonmoon.study.v1/${id}/${revision}`
}

function validateReview(review, study) {
  if (review === null) return
  need(review && typeof review === 'object' && !Array.isArray(review) && review.authority === 'digital-only' && review.dossierDigest === study.envelope.dossier_digest && typeof review.reviewer === 'string' && review.reviewer.trim() && typeof review.rationale === 'string' && review.rationale.trim() && (review.choice === 'none' || study.alternatives.some(item => item.session_id === review.choice)), 'Saved review must name a reviewer, reason and supported digital-only choice for this exact dossier')
}
function validateReviewRecord(record, study) {
  validateReview(record.review, study)
  need(Array.isArray(record.reviewHistory), 'Invalid saved review history')
  for (const review of record.reviewHistory) { need(review !== null, 'Invalid saved review history'); validateReview(review, study) }
}

// Validate exactly the captured bytes. Discovery budgets this snapshot before
// parsing; never reread storage between the size check and JSON decoding.
export async function readStudyRecord(raw) {
  need(typeof raw === 'string', 'Saved study record must contain exact JSON text')
  const record = JSON.parse(raw)
  const study = await readStudy(record.envelopeText)
  validateReviewRecord(record, study)
  return { study, review: record.review, reviewHistory: record.reviewHistory, observed: raw }
}
async function readSavedRecord(raw, id, revision) {
  const loaded = await readStudyRecord(raw)
  need(loaded.study.dossier.study_id === id && loaded.study.dossier.revision === revision, 'Saved study identity mismatch')
  return loaded
}

// Readback-confirmed revision storage with an explicit interrupted-write journal.
// One record per study/revision avoids replacing another study or earlier revision.
export const STUDY_LIBRARY_LIMITS = Object.freeze({ keys: 512, records: 32, recordBytes: 24 * 1024 * 1024, totalBytes: 32 * 1024 * 1024 })
export class StudyStore {
  constructor(storage) { this.storage = storage }
  async catalogue() {
    const length = this.storage.length
    need(Number.isSafeInteger(length) && length >= 0 && typeof this.storage.key === 'function', 'Browser storage cannot enumerate saved studies')
    need(length <= STUDY_LIBRARY_LIMITS.keys, `Browser storage exceeds the ${STUDY_LIBRARY_LIMITS.keys}-key inspection limit; use exact study IDs`)
    const identities = new Map(), inventory = []
    let invalidKeys = 0
    for (let index = 0; index < length; index++) {
      const key = this.storage.key(index)
      need(typeof key === 'string', 'Browser storage changed during discovery; refresh the library')
      inventory.push(key)
      if (!key.startsWith('moonmoon.study.v1/')) continue
      const match = /^moonmoon\.study\.v1\/([A-Za-z0-9_-]{1,100})\/([A-Za-z0-9_-]{1,100})(?:\/pending)?$/.exec(key)
      if (!match) { invalidKeys++; continue }
      identities.set(keyFor(match[1], match[2]), { id: match[1], revision: match[2] })
    }
    const entries = []
    const keys = [...identities.keys()].sort()
    let bytes = 0, truncated = keys.length > STUDY_LIBRARY_LIMITS.records
    for (const key of keys.slice(0, STUDY_LIBRARY_LIMITS.records)) {
      const identity = identities.get(key)
      let entry = { ...identity, state: 'unavailable', message: 'Saved revision could not be inspected' }
      let validating = false
      try {
        const pending = this.storage.getItem(key + '/pending'), raw = this.storage.getItem(key)
        if (pending !== null) entry = { ...identity, state: 'interrupted', message: 'An unresolved save journal is present. Reconcile this exact identity explicitly before reopening; all bytes were retained.' }
        else if (raw === null) entry = { ...identity, state: 'missing', message: 'This revision disappeared during discovery. Refresh before continuing.' }
        else {
          const size = raw.length > STUDY_LIBRARY_LIMITS.recordBytes ? raw.length : encoder.encode(raw).length
          if (size > STUDY_LIBRARY_LIMITS.recordBytes || bytes + size > STUDY_LIBRARY_LIMITS.totalBytes) {
            truncated = true
            entry = { ...identity, state: 'limited', message: 'Saved record exceeds the bounded library inspection budget. Use the exact-ID controls; bytes were not changed.' }
          } else {
            bytes += size
            validating = true
            const loaded = await readSavedRecord(raw, identity.id, identity.revision)
            if (loaded.observed !== raw || this.storage.getItem(key) !== raw || this.storage.getItem(key + '/pending') !== null) entry = { ...identity, state: 'changed', message: 'Saved revision changed during inspection. Refresh before opening; no stored data was changed.' }
            else entry = { ...identity, state: 'verified', observed: raw,
                message: `${loaded.study.envelope.dossier_digest}\n${loaded.review ? `Digital review by ${loaded.review.reviewer.slice(0, 160)}: ${loaded.review.choice}` : 'No named digital review saved'}. ${loaded.reviewHistory.length} prior review(s) retained. Digital-only; no new simulation or physical readiness.` }
          }
        }
      } catch (error) { entry.state = validating ? 'invalid' : 'unavailable'; entry.message = `Cannot open this revision: ${String(error.message).slice(0, 500)}. Stored evidence was left untouched.` }
      entries.push(entry)
    }
    // Validation awaits digests, so another tab can change the inventory. A
    // second bounded key-only pass detects additions, removals and replacements.
    let inventoryChanged = this.storage.length !== length || new Set(inventory).size !== length
    if (!inventoryChanged) {
      const current = []
      for (let index = 0; index < length; index++) current.push(this.storage.key(index))
      inventoryChanged = this.storage.length !== length || current.some(key => typeof key !== 'string') || JSON.stringify(current.sort()) !== JSON.stringify(inventory.sort())
    }
    return { entries, invalidKeys, truncated: truncated || inventoryChanged, inventoryChanged }
  }
  async open(id, revision, expectedObserved) {
    const key = keyFor(id, revision)
    need(!this.storage.getItem(key + '/pending'), 'Save outcome unknown. Reconcile this revision before reopening or replacing it')
    const raw = this.storage.getItem(key)
    need(raw, 'No confirmed saved revision with this identity')
    need(expectedObserved === undefined || raw === expectedObserved, 'Saved revision changed since discovery; refresh the library before opening it')
    return readSavedRecord(raw, id, revision)
  }
  async save(study, review, observed) {
    const checked = await readStudy(study.text)
    const key = keyFor(checked.dossier.study_id, checked.dossier.revision)
    need(!this.storage.getItem(key + '/pending'), 'Save outcome unknown. Reconcile before another save')
    const current = this.storage.getItem(key)
    need(current === observed, 'This revision changed in another tab or is already saved. Reopen it before editing; keep this draft')
    validateReview(review, checked)
    const previous = current ? JSON.parse(current) : null
    if (previous) validateReviewRecord(previous, checked)
    const reviewHistory = [...(previous?.reviewHistory || [])]
    if (previous?.review && stable(previous.review) !== stable(review)) reviewHistory.push(previous.review)
    const next = JSON.stringify({ envelopeText: checked.text, review, reviewHistory })
    return this.commitRecord(key, current, next)
  }
  async restoreArchive(text) {
    const loaded = await readStudyArchive(text, readStudyRecord, sha256)
    const key = keyFor(loaded.study.dossier.study_id, loaded.study.dossier.revision)
    need(this.storage.getItem(key) === null, 'This study/revision already exists; archives never replace or merge saved evidence')
    need(this.storage.getItem(key + '/pending') === null, 'This study/revision has an unresolved save journal; reconcile it before restoring')
    return this.commitRecord(key, null, loaded.observed)
  }
  async commitRecord(key, current, next) {
    const journal = JSON.stringify({ previous: current, next, digest: await sha256(next) })
    need(this.storage.getItem(key + '/pending') === null && this.storage.getItem(key) === current, 'This revision changed while preparing the save; keep this draft and reopen')
    this.storage.setItem(key + '/pending', journal)
    need(this.storage.getItem(key + '/pending') === journal, 'Save outcome unknown: journal readback failed')
    this.storage.setItem(key, next)
    need(this.storage.getItem(key) === next, 'Save outcome unknown: record readback failed')
    this.storage.removeItem(key + '/pending')
    need(!this.storage.getItem(key + '/pending'), 'Save outcome unknown: confirmation cleanup failed')
    return next
  }
  async reconcile(id, revision) {
    const key = keyFor(id, revision)
    const raw = this.storage.getItem(key + '/pending')
    if (!raw) return 'No unresolved save; reopen the confirmed revision'
    const journal = JSON.parse(raw)
    need(await sha256(journal.next) === journal.digest, 'Journal changed; preserve this revision for investigation')
    const next = JSON.parse(journal.next)
    const study = await readStudy(next.envelopeText)
    validateReviewRecord(next, study)
    need(study.dossier.study_id === id && study.dossier.revision === revision, 'Journal belongs to another study')
    const current = this.storage.getItem(key)
    need(current === journal.next || current === journal.previous, 'Conflicting persisted bytes; preserve both and investigate')
    this.storage.removeItem(key + '/pending')
    need(!this.storage.getItem(key + '/pending'), 'Storage remains unavailable; save outcome unknown')
    return current === journal.next ? 'Exact save confirmed. Reopen to inspect it' : 'Save was not applied. Your current draft is still unsaved'
  }
}

export function bindMissionStudy(document, storageFactory = () => globalThis.localStorage, runClient) {
  const panel = document.getElementById('mission-study-panel')
  if (!panel || panel.dataset.bound) return
  panel.dataset.bound = 'true'
  const byId = id => document.getElementById('study-' + id)
  let active = null, review = null, observed = null, dirty = false, busy = false, unknown = false, editVersion = 0
  const status = message => { byId('status').textContent = message }
  const store = () => new StudyStore(storageFactory())
  const renderMap = bindStudyRouteMap(document)
  const renderScreen = bindStudyScreen(document, panel, { getCurrent: () => active, readStudy, hash: sha256 })
  const renderRevision = bindStudyRevisionComparison(document, panel, { getCurrent: () => active, readStudy })
  const render = () => {
    byId('comparison').textContent = active ? [
      `${active.dossier.study_id} / ${active.dossier.revision} · ${active.envelope.dossier_digest}`,
      `Site ${active.dossier.site.site_id} (${active.dossier.site.frame}); coverage: ${active.dossier.site.coverage}; uncertainty: ${active.dossier.site.uncertainty}`,
      `Common frozen baseline: ${active.alternatives[0].baseline_digest}`,
      ...sensitivityRows(active).map(row => `${row.name} (${row.session}): ${row.result.result}; route ${row.result.route_id}; distance ${measured(row.result.distance_m, row.delta.distance_m, 'm')}; duration ${measured(row.result.duration_s, row.delta.duration_s, 's')}; maximum slope ${measured(row.result.maximum_measured_segment_slope_deg, row.delta.maximum_measured_segment_slope_deg, 'degrees')}; energy margin ${measured(row.result.energy.margin_wh, row.delta.energy_margin_wh, 'Wh')}. Assumptions: ${row.assumption}. Coverage: ${row.coverage}. Blockers: ${row.result.blockers.join('; ') || 'none in this bounded simulation'}`),
      `Review: ${review ? `${review.reviewer}: ${review.choice}. ${review.rationale}` : 'Required for this exact revision'}`,
      'Reviewer names, including restored reviews, are unauthenticated digital claims. Integrity checks do not verify identity or grant authority.',
      ...active.dossier.limitations,
      'Hazard comparison is limited to measured segment slope. Obstacle, slip, sinkage and other unmodeled hazards remain unknown. Integrity checked locally. Scientific replay is performed by the native mission_study inspect command. No physical authority. Optional E1 assembly is unavailable. Manual export has no receiver acknowledgement.',
    ].join('\n\n') : 'Import a dossier made by the native mission_study command, or reopen a saved study and revision'
    renderSensitivityMatrix(document, active)
    renderScreen(active)
    renderMap(active)
    renderRevision(active)
  }
  const run = action => async event => {
    event?.preventDefault?.()
    if (busy) return
    busy = true
    try { await action() } catch (error) { status(error.message + (dirty ? ' · Your draft is still open' : '')) } finally { busy = false; render() }
  }
  byId('file').addEventListener('change', run(async () => {
    need(!dirty && !unknown, 'Save or explicitly discard current edits before importing another revision')
    const file = byId('file').files?.[0]
    need(file && file.size <= 8388608, 'Choose a local dossier JSON file of at most 8 MiB')
    const version = editVersion
    const loaded = await readStudy(await file.text())
    need(editVersion === version && !dirty && !unknown, 'Current edits changed during import; keep this draft and retry after saving')
    active = loaded; review = null; observed = null; dirty = true
    byId('id').value = active.dossier.study_id; byId('revision').value = active.dossier.revision
    byId('reviewer').value = ''; byId('choice').value = ''; byId('rationale').value = ''
    status('Imported frozen digital evidence. Review is reopened; save to keep this revision in this browser')
  }))
  const open = async (discard, selection = null) => {
    need(!dirty || discard, 'Save edits first, or use Discard edits and reopen')
    need(!unknown, 'Reconcile the unknown save first')
    const version = editVersion
    const id = selection?.id || byId('id').value, revision = selection?.revision || byId('revision').value
    const selectedStore = store()
    const loaded = await selectedStore.open(id, revision, selection?.observed)
    need(editVersion === version, 'Edits changed during reopen; keep this draft')
    if (selection) need(loaded.observed === selection.observed && selectedStore.storage.getItem(keyFor(id, revision)) === selection.observed && selectedStore.storage.getItem(keyFor(id, revision) + '/pending') === null, 'Saved revision changed since discovery; refresh the library before opening it')
    active = loaded.study; review = loaded.review; observed = loaded.observed; dirty = false
    byId('id').value = id; byId('revision').value = revision
    byId('reviewer').value = review?.reviewer || ''; byId('choice').value = review?.choice || ''; byId('rationale').value = review?.rationale || ''
    status('Reopened the exact confirmed revision and its digital review')
  }
  byId('reopen').addEventListener('click', run(() => open(false)))
  byId('discard').addEventListener('click', run(() => open(true)))
  for (const name of ['id', 'revision']) byId(name).addEventListener('input', () => { editVersion += 1 })
  bindStudyLibrary(document, panel, {
    catalogue: () => store().catalogue(),
    open: async entry => {
      need(!busy, 'Wait for the current study operation before opening another revision')
      busy = true
      try { await open(false, entry); render() } finally { busy = false }
    },
  })
  for (const name of ['reviewer', 'choice', 'rationale']) byId(name).addEventListener('input', () => { editVersion += 1; if (active) { dirty = true; review = null; status('Review edits are unsaved') } })
  byId('save').addEventListener('click', run(async () => {
    need(active, 'Import or reopen a dossier first')
    need(!unknown, 'Reconcile the unknown save first')
    const reviewer = byId('reviewer').value.trim(), choice = byId('choice').value.trim(), rationale = byId('rationale').value.trim()
    need(!reviewer && !choice && !rationale || reviewer && rationale && (choice === 'none' || active.alternatives.some(item => item.session_id === choice)), 'For a digital review, enter your name, an exact session ID or none, and a reason')
    review = reviewer ? { dossierDigest: active.envelope.dossier_digest, reviewer, choice, rationale, authority: 'digital-only' } : null
    const version = editVersion
    try { observed = await store().save(active, review, observed); dirty = editVersion !== version; if (dirty) review = null; status(dirty ? 'Earlier review was saved; newer edits are still unsaved' : 'Saved and read back exact evidence and digital review in this browser') }
    catch (error) { unknown = true; throw error }
  }))
  byId('reconcile').addEventListener('click', run(async () => {
    status(await store().reconcile(active?.dossier.study_id || byId('id').value, active?.dossier.revision || byId('revision').value))
    unknown = false
  }))
  byId('export').addEventListener('click', run(async () => {
    need(active && !dirty && !unknown, 'Save and confirm this revision before exporting')
    const version = editVersion, selected = active
    const loaded = await store().open(active.dossier.study_id, active.dossier.revision)
    need(editVersion === version && active === selected && !dirty && !unknown, 'Edits changed during export; save the current review before exporting')
    need(loaded.observed === observed, 'Saved evidence changed; reopen it before export')
    const item = loaded.study.alternatives.find(item => item.session_id === byId('export-session').value.trim())
    need(item, 'Enter the exact session ID to export')
    const url = URL.createObjectURL(new Blob([item.resultText], { type: 'application/json' }))
    const link = document.createElement('a'); link.href = url; link.download = `${active.dossier.study_id}-${active.dossier.revision}-${item.session_id}-digital-result.json`
    link.click(); URL.revokeObjectURL(url)
    status(`Prepared exact digital result download ${item.result_digest}. MoonFlow delivery and MoonRobo acknowledgement remain pending; no physical authority`)
  }))
  bindStudyArchive(document, panel, {
    inspect: text => readStudyArchive(text, readStudyRecord, sha256),
    export: async () => {
      need(active && !dirty && !unknown && !busy, 'Save and confirm the open study before exporting its archive')
      busy = true
      try {
        const selected = active, version = editVersion, selectedStore = store()
        const id = selected.dossier.study_id, revision = selected.dossier.revision, key = keyFor(id, revision)
        need(selectedStore.storage.getItem(key + '/pending') === null, 'Reconcile the unresolved save before exporting')
        const loaded = await selectedStore.open(id, revision, observed)
        const text = await createStudyArchive(loaded.observed, readStudyRecord, sha256)
        need(selected === active && version === editVersion && !dirty && !unknown, 'Review edits changed during export; save them before trying again')
        need(selectedStore.storage.getItem(key) === observed && selectedStore.storage.getItem(key + '/pending') === null, 'Saved review changed during export; reopen before trying again')
        return { text, filename: `${id}-${revision}-reviewed-study.json` }
      } finally { busy = false }
    },
    restore: async text => {
      need(!dirty && !unknown && !busy, 'Save or explicitly discard current edits and reconcile unknown saves before restoring an archive')
      busy = true
      try {
        const version = editVersion, selected = active, checked = await readStudyArchive(text, readStudyRecord, sha256)
        need(version === editVersion && selected === active && !dirty && !unknown, 'Current edits changed during archive checking; keep this draft and retry')
        // Restore writes a separate unused identity. It never replaces the open
        // panel, even if the operator starts typing while persistence awaits.
        await store().restoreArchive(text)
        return `${checked.study.dossier.study_id} / ${checked.study.dossier.revision}`
      } finally { busy = false }
    },
  })
  bindMissionAuthoring(document, () => active, {
    storageFactory, ...(runClient ? { client: runClient } : {}),
    context: () => [editVersion, dirty, unknown, busy],
    deliver: async checked => {
      need(!dirty && !unknown && !busy, 'Save or explicitly discard current study edits before opening the retained run result')
      busy = true
      try {
        const version = editVersion, selected = active, storage = storageFactory()
        const key = keyFor(checked.dossier.study_id, checked.dossier.revision)
        need(!storage.getItem(key + '/pending'), 'Target result has an interrupted save. Reconcile it before opening the retained result')
        const saved = storage.getItem(key) ? await new StudyStore(storage).open(checked.dossier.study_id, checked.dossier.revision) : null
        need(!saved || saved.study.text === checked.text, 'Different local evidence already uses this study/revision; preserve both and choose a new revision')
        need(version === editVersion && selected === active && !dirty && !unknown, 'Current review changed while importing; retained result remains available')
        active = checked; review = saved?.review || null; observed = saved?.observed || null; dirty = !saved
        byId('id').value = checked.dossier.study_id; byId('revision').value = checked.dossier.revision
        byId('reviewer').value = review?.reviewer || ''; byId('choice').value = review?.choice || ''; byId('rationale').value = review?.rationale || ''
        status(saved ? 'Reopened actual native result and its own saved digital review' : 'Imported actual native result automatically. Inspect the comparison, then save a new digital review before authoring a Book outcome')
      } finally { busy = false; render() }
    },
  })
  bindMissionOutcome(document, async () => {
    need(active && !dirty && !unknown && !busy, 'Save and confirm the study and named digital review first')
    const selected = active, version = editVersion
    const loaded = await store().open(active.dossier.study_id, active.dossier.revision)
    need(selected === active && editVersion === version && !dirty && !unknown && loaded.observed === observed, 'Study changed during outcome export; reopen and save before retrying')
    return loaded
  }, async received => {
    need(!dirty && !unknown && !busy, 'Save or explicitly discard current study edits before reopening a received outcome')
    busy = true
    try {
      const version = editVersion, selected = active
      const checked = await readStudy(received.text), storage = storageFactory()
      const key = keyFor(checked.dossier.study_id, checked.dossier.revision)
      need(!storage.getItem(key + '/pending'), 'Target study has an interrupted save. Reconcile it before reopening this received outcome')
      const raw = storage.getItem(key)
      const saved = raw ? await new StudyStore(storage).open(checked.dossier.study_id, checked.dossier.revision) : null
      need(!saved || saved.study.text === checked.text, 'A different local study uses this identity; keep both files and resolve explicitly')
      need(version === editVersion && selected === active && !dirty && !unknown, 'Current study changed during reopen; your edits were kept')
      active = checked; review = saved?.review || null; observed = saved?.observed || null; dirty = !saved
      byId('id').value = checked.dossier.study_id; byId('revision').value = checked.dossier.revision
      byId('reviewer').value = review?.reviewer || ''; byId('choice').value = review?.choice || ''; byId('rationale').value = review?.rationale || ''
      status(saved ? 'Reopened original source study and its independently saved digital review' : 'Reopened original source study from Book receipt. Save this local study when ready; Book review was not copied into digital reviewer controls')
    } finally { busy = false; render() }
  })
  render()
}
