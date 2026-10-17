// Editable inputs only. Real calculations and replay remain in the native runner.
import { readStudy, sha256 } from './mission-study.js'
import { bindMissionRun } from './mission-run.js'
import { bindDraftRouteMap, parseDraftCells } from './mission-draft-map.js'

const encoder = new TextEncoder()
const need = (value, message) => { if (!value) throw new Error(message) }
const component = value => typeof value === 'string' && /^[A-Za-z0-9_-]{1,100}$/.test(value)
const local = value => typeof value === 'string' && value === value.trim() && !/[\\:]/.test(value) && !value.startsWith('/') && value.split('/').every(part => part && part !== '.' && part !== '..')
const clone = value => JSON.parse(JSON.stringify(value))

export async function readRobotInput(text) {
  need(typeof text === 'string' && encoder.encode(text).length <= 8388608, 'Robot input must be at most 8 MiB')
  const envelope = JSON.parse(text)
  need(envelope.contract_id === 'moonrobo.simulation-input-envelope.v1' && typeof envelope.package_json === 'string' && await sha256(envelope.package_json) === envelope.package_digest, 'Robot package digest mismatch')
  const robot = JSON.parse(envelope.package_json), binding = robot.robot_artifact
  need(robot.contract_id === 'moonrobo.simulation-input.v1' && robot.review_required === true && robot.physical_execution_allowed === false && component(robot.design_id) && component(robot.revision), 'Unsupported or physical robot input')
  need(binding && binding.robot_id === robot.design_id && binding.robot_revision === robot.revision && binding.validation_status === 'accepted' && binding.physical_transport_enabled === false && local(binding.artifact_root), 'Robot identity or validation mismatch')
  need(Array.isArray(robot.sources) && robot.sources.length <= 64, 'Too many robot sources')
  const sources = new Map(); let size = 0
  for (const source of robot.sources) {
    need(local(source.artifact_ref) && !sources.has(source.artifact_ref) && typeof source.text === 'string', 'Unsafe or duplicate robot source')
    const bytes = encoder.encode(source.text).length; size += bytes
    need(bytes <= 1048576 && size <= 4194304 && await sha256(source.text) === source.digest, 'Robot source size or digest mismatch')
    sources.set(source.artifact_ref, source)
  }
  const source = ref => { need(sources.has(ref), 'Missing robot source: ' + ref); return sources.get(ref) }
  source(robot.design_ref)
  for (const [path, hash] of [[binding.robot_json_path, binding.robot_json_sha256], [binding.robot_urdf_path, binding.robot_urdf_sha256], [binding.validation_receipt_path, binding.validation_receipt_sha256]]) need(local(path) && source(binding.artifact_root + '/' + path).digest === 'sha256:' + hash, 'Robot artifact hash mismatch')
  need(local(binding.bridge_config_path), 'Unsafe robot bridge reference')
  const bridge = JSON.parse(source(binding.artifact_root + '/' + binding.bridge_config_path).text)
  need(bridge.mode === 'simulation-only' && bridge.physical_transport_enabled === false && bridge.design_id === binding.robot_id, 'Robot bridge must remain simulation-only')
  const receipt = JSON.parse(source(robot.integration_receipt_ref).text), output = receipt.output
  need(receipt.contract_id === 'moonrobo.digital-model-integration-receipt.v1' && receipt.adapter_id === 'moonrobo-local-v1' && receipt.operation_id === 'robot.integrate-digital-model' && receipt.status === 'succeeded' && receipt.physical_execution_performed === false && output?.accepted === true && output.robobook_ref === binding.artifact_root && output.model_ref === binding.artifact_root + '/' + binding.robot_urdf_path && output.validation_receipt_ref === binding.artifact_root + '/' + binding.validation_receipt_path && Array.isArray(receipt.evidence_refs) && receipt.evidence_refs.includes(output.model_ref) && receipt.evidence_refs.includes(output.validation_receipt_ref), 'Robot integration receipt is incompatible')
  receipt.evidence_refs.forEach(source)
  return { text, envelope, robot }
}

export function draftVariants(draft) {
  return draft.contract_id === 'moonmoon.mission-draft.v2' ? draft.variants : [{ variant_id: 'alternative', name: 'Edited mission', edits: draft.edits }]
}

export function forkMission(study, session, { version = 2 } = {}) {
  const base = study.alternatives.find(item => item.session_id === session)
  need(base, 'Select an exact parent session to fork')
  need(version === 1 || version === 2, 'Unsupported draft version')
  const edits = {
    route_id: base.design.mission.route_id,
    path_cells: clone(base.design.environment.path_cells),
    terrain_available_energy_wh: base.design.environment.illumination.terrain_available_energy_wh,
    commanded_speed_mps: base.design.verification_criteria.path.commanded_speed_mps,
    seed: base.design.scenario.seed, injected_faults: [...base.design.scenario.injected_faults], assumption_note: '',
  }
  return {
    contract_id: `moonmoon.mission-draft.v${version}`, study_id: study.dossier.study_id,
    revision: study.dossier.revision.slice(0, 94) + '-draft',
    parent_envelope_json: study.text, parent_digest: study.envelope.dossier_digest,
    base_session_id: session, robot_envelope_json: '', review_required: true, physical_execution_allowed: false,
    ...(version === 1 ? { edits } : { variants: [1, 2].map(index => ({ variant_id: `variant-${index}`, name: `Variant ${index}`, edits: { ...clone(edits), assumption_note: 'Unreviewed variant: verify route, energy, speed, faults and inherited limitations. No physical readiness is asserted.' } })) }),
  }
}

export async function validateDraft(draft) {
  need(draft && ['moonmoon.mission-draft.v1', 'moonmoon.mission-draft.v2'].includes(draft.contract_id) && component(draft.study_id) && component(draft.revision) && draft.review_required === true && draft.physical_execution_allowed === false, 'Unsupported or physical mission draft')
  const parent = await readStudy(draft.parent_envelope_json)
  need(parent.envelope.dossier_digest === draft.parent_digest, 'Draft parent digest mismatch')
  need(draft.study_id !== parent.dossier.study_id || draft.revision !== parent.dossier.revision, 'Fork requires a new study or revision; original review is preserved')
  need(parent.alternatives.some(item => item.session_id === draft.base_session_id), 'Unknown parent alternative')
  if (draft.contract_id === 'moonmoon.mission-draft.v2') {
    need(!Object.hasOwn(draft, 'edits') && Array.isArray(draft.variants) && draft.variants.length >= 2 && draft.variants.length <= 4, 'A sensitivity study needs 2–4 variants')
    const ids = new Set()
    for (const variant of draft.variants) {
      need(variant && typeof variant.variant_id === 'string' && /^[A-Za-z0-9_-]{1,64}$/.test(variant.variant_id) && variant.variant_id !== 'reference' && !ids.has(variant.variant_id), 'Variant IDs must be unique safe names up to 64 characters and cannot be reference')
      ids.add(variant.variant_id)
      need(typeof variant.name === 'string' && variant.name.trim() && variant.name.length <= 120, 'Give each variant a nonblank name up to 120 characters')
    }
  }
  for (const variant of draftVariants(draft)) validateEdits(variant.edits)
  need(typeof draft.robot_envelope_json === 'string', 'Missing robot-input selection')
  if (draft.robot_envelope_json) await readRobotInput(draft.robot_envelope_json)
  return { draft, parent }
}

function validateEdits(e) {
  need(e && component(e.route_id) && typeof e.assumption_note === 'string' && e.assumption_note.trim() && e.assumption_note.length <= 2000, 'Name the route and document the changed assumptions')
  need(Array.isArray(e.path_cells) && e.path_cells.length >= 2 && e.path_cells.length <= 256 && e.path_cells.every(cell => Array.isArray(cell) && cell.length === 2 && cell.every(value => Number.isSafeInteger(value) && value >= 0 && value <= 1000000)), 'Route needs 2–256 nonnegative row/column pairs')
  need(Number.isFinite(e.terrain_available_energy_wh) && e.terrain_available_energy_wh >= 0 && e.terrain_available_energy_wh <= 1e9 && Number.isFinite(e.commanded_speed_mps) && e.commanded_speed_mps > 0 && e.commanded_speed_mps <= 1000 && Number.isSafeInteger(e.seed) && e.seed > 0 && e.seed <= 2147483647, 'Invalid finite energy, speed or deterministic seed')
  need(Array.isArray(e.injected_faults) && e.injected_faults.length <= 16 && e.injected_faults.every(component) && new Set(e.injected_faults).size === e.injected_faults.length, 'Fault IDs must be unique safe names, at most 16')
}

export async function exportDraft(draft) {
  await validateDraft(draft)
  const draft_json = JSON.stringify(draft, null, 2) + '\n'
  const text = JSON.stringify({ contract_id: draft.contract_id.replace('mission-draft.', 'mission-draft-envelope.'), draft_digest: await sha256(draft_json), draft_json }, null, 2) + '\n'
  need(encoder.encode(text).length <= 16777216, 'Draft envelope must be at most 16 MiB; reduce the frozen input set')
  return text
}

export async function readDraft(text) {
  need(typeof text === 'string' && encoder.encode(text).length <= 16777216, 'Draft envelope must be at most 16 MiB')
  const envelope = JSON.parse(text)
  need(['moonmoon.mission-draft-envelope.v1', 'moonmoon.mission-draft-envelope.v2'].includes(envelope.contract_id) && typeof envelope.draft_json === 'string' && await sha256(envelope.draft_json) === envelope.draft_digest, 'Draft digest mismatch')
  const draft = JSON.parse(envelope.draft_json)
  need(draft.contract_id === envelope.contract_id.replace('mission-draft-envelope.', 'mission-draft.'), 'Draft envelope version mismatch')
  return validateDraft(draft)
}

export function bindMissionAuthoring(document, getActive, runOptions) {
  const byId = name => document.getElementById('study-draft-' + name)
  if (!byId('fork') || byId('fork').dataset.bound) return
  byId('fork').dataset.bound = 'true'
  let draft = null, changed = false, busy = false, version = 0, frozenVersion = 0, selected = 0, variantInputs = []
  const status = message => { byId('status').textContent = message }
  const fields = ['id','revision','route','cells','energy','speed','seed','faults','note']
  const editFields = ['route','cells','energy','speed','seed','faults','note']
  const routeMap = bindDraftRouteMap(document, {
    readText: () => byId('cells').value,
    writeText: text => { byId('cells').value = text; inputChanged('cells') },
  })
  const renderRoute = () => {
    if (!draft) { routeMap(null); return }
    const dossier = JSON.parse(JSON.parse(draft.parent_envelope_json).dossier_json)
    const source = dossier.alternatives.find(item => item.session_id === draft.base_session_id)
    const design = JSON.parse(dossier.sources.find(item => item.artifact_ref === source.design_ref).text)
    routeMap({ identity: draft.variants ? draft.variants[selected] : draft, dossier, design })
  }
  const inputChanged = name => {
    version++
    if (draft) {
      changed = true
      if (name === 'cells') {
        try { draftVariants(draft)[selected].edits.path_cells = parseDraftCells(byId('cells').value) } catch { /* Preserve unfinished authoritative text. */ }
        renderRoute()
      }
      status('Unsaved input draft. Duplicate a variant before adding a retraced return if you want to preserve the outbound alternative. Run this digital mission using the local host, or export frozen inputs')
    }
  }
  const valuesFor = e => ({ route: e.route_id, cells: e.path_cells.map(cell => cell.join(',')).join('\n'), energy: e.terrain_available_energy_wh, speed: e.commanded_speed_mps, seed: e.seed, faults: e.injected_faults.join('\n'), note: e.assumption_note })
  const stash = () => {
    if (!draft) return
    draft.study_id = byId('id').value.trim(); draft.revision = byId('revision').value.trim()
    variantInputs[selected] = Object.fromEntries(editFields.map(key => [key, byId(key).value]))
    if (draft.variants) {
      draft.variants[selected].variant_id = byId('variant-id').value
      draft.variants[selected].name = byId('variant-name').value
    }
  }
  const render = () => {
    if (!draft) return
    const variants = draftVariants(draft), variant = variants[selected]
    for (const [key, value] of Object.entries({ id: draft.study_id, revision: draft.revision, ...(variantInputs[selected] || valuesFor(variant.edits)) })) byId(key).value = String(value)
    if (byId('variant')) {
      const select = byId('variant')
      const options = variants.map((item, index) => { const option = document.createElement('option'); option.value = String(index); option.textContent = item.name + ' (' + item.variant_id + ')'; return option })
      if (select.replaceChildren) select.replaceChildren(...options)
      select.value = String(selected); select.disabled = !draft.variants
      byId('variant-id').value = variant.variant_id; byId('variant-name').value = variant.name
      byId('variant-id').disabled = byId('variant-name').disabled = !draft.variants
      byId('variant-add').disabled = byId('variant-duplicate').disabled = !draft.variants || variants.length >= 4
      byId('variant-remove').disabled = !draft.variants || variants.length <= 2
      byId('variants-status').textContent = draft.variants ? `${variants.length} named variants + one reference = ${variants.length + 1} native runs. Each variant keeps independent edits; one frozen batch shares the same source and robot baseline.` : 'Legacy v1 draft: one edited mission and one reference. Reopening and exporting preserves v1.'
    }
    const parent = JSON.parse(JSON.parse(draft.parent_envelope_json).dossier_json)
    const source = parent.alternatives.find(item => item.session_id === draft.base_session_id)
    const design = JSON.parse(parent.sources.find(item => item.artifact_ref === source.design_ref).text)
    byId('baseline').textContent = `Parent ${parent.study_id}/${parent.revision}, session ${draft.base_session_id}. Terrain and constraints stay frozen. Route length ${design.constraints.route_length_m.min}–${design.constraints.route_length_m.max} m; speed ${design.constraints.commanded_speed_mps.min}–${design.constraints.commanded_speed_mps.max} m/s. Calibrated fault IDs: ${draft.robot_envelope_json ? 'none (new robot)' : design.environment.calibration.fault_models.map(item => item.fault_id).join(', ') || 'none'}. Calibration qualified: ${draft.robot_envelope_json ? false : design.environment.calibration.qualified}. Energy is an author assumption; it does not change source truth. Unknown faults or unsupported routes are rejected by the native simulator.`
    byId('robot-status').textContent = draft.robot_envelope_json ? `Imported robot ${JSON.parse(JSON.parse(draft.robot_envelope_json).package_json).design_id}. New robot baseline: parent results are incomparable. The native runner reruns reference and every variant on this robot and clears prior calibration. Mission power assumptions remain inherited and must be reviewed.` : 'Using the original frozen robot and calibration'
    renderRoute()
  }
  const collect = () => {
    need(draft, 'Fork a mission or reopen an exported draft first')
    stash()
    const edits = (variant, index) => {
      const values = variantInputs[index] || valuesFor(variant.edits)
      const number = key => { need(String(values[key]).trim(), 'Enter ' + key + ' for ' + variant.name); return Number(values[key]) }
      return { route_id: values.route.trim(),
        path_cells: values.cells.trim().split('\n').map(line => { const parts = line.split(','); need(parts.every(part => part.trim()), 'Each route row needs row,column'); return parts.map(Number) }),
        terrain_available_energy_wh: number('energy'), commanded_speed_mps: number('speed'), seed: number('seed'),
        injected_faults: values.faults.split('\n').map(x => x.trim()).filter(Boolean), assumption_note: values.note.trim(),
      }
    }
    return { ...draft, ...(draft.variants ? { variants: draft.variants.map((variant, index) => ({ ...variant, edits: edits(variant, index) })) } : { edits: edits(draftVariants(draft)[0], 0) }) }
  }
  const run = fn => async () => { if (busy) return; busy = true; try { await fn() } catch (error) { status(error.message + (changed ? ' · Current draft remains open' : '')) } finally { busy = false } }
  for (const name of [...fields, 'variant-id', 'variant-name']) byId(name)?.addEventListener('input', () => inputChanged(name))
  byId('variant')?.addEventListener('change', () => {
    if (!draft || busy) { if (draft) byId('variant').value = String(selected); return }
    const next = Number(byId('variant').value)
    if (!Number.isInteger(next) || !draftVariants(draft)[next]) return
    stash(); selected = next; version++; render()
  })
  for (const action of ['add', 'duplicate', 'remove']) byId('variant-' + action)?.addEventListener('click', run(async () => {
    need(draft?.variants, 'Variant management is available on a new v2 fork')
    stash()
    if (action === 'remove') {
      need(draft.variants.length > 2, 'Keep at least two variants')
      draft.variants.splice(selected, 1); variantInputs.splice(selected, 1); selected = Math.min(selected, draft.variants.length - 1)
    } else {
      need(draft.variants.length < 4, 'At most four variants per sensitivity study')
      let index = 1
      while (draft.variants.some(item => item.variant_id === 'variant-' + index)) index++
      const stamp = version, parent = await readStudy(draft.parent_envelope_json)
      need(stamp === version, 'Inputs changed while adding a variant; retry without losing your current edits')
      const baseline = forkMission(parent, draft.base_session_id).variants[0].edits
      const current = draft.variants[selected]
      draft.variants.push({ variant_id: 'variant-' + index, name: action === 'duplicate' ? (current.name.slice(0, 113) + ' (copy)') : 'Variant ' + index, edits: clone(action === 'duplicate' ? current.edits : baseline) })
      variantInputs[draft.variants.length - 1] = action === 'duplicate' ? { ...variantInputs[selected] } : undefined
      selected = draft.variants.length - 1
    }
    changed = true; version++; render(); status('Variant ' + action + ' applied. All other variant edits are preserved; export or run the complete batch')
  }))
  byId('fork').addEventListener('click', run(async () => {
    need(!changed, 'Export this draft or explicitly discard it before starting another')
    const active = getActive(); need(active, 'Import or reopen a study first')
    draft = forkMission(active, byId('parent-session').value.trim()); selected = 0; variantInputs = []; changed = true; version++; render()
    status('Fork opened. Original dossier and review are unchanged. Edit supported inputs, describe assumptions, then run or export')
  }))
  byId('discard').addEventListener('click', () => { if (busy) return; draft = null; selected = 0; variantInputs = []; changed = false; version++; fields.forEach(key => { byId(key).value = '' }); for (const key of ['variant-id','variant-name','variant']) if (byId(key)) byId(key).value = ''; if (byId('variants-status')) byId('variants-status').textContent = ''; byId('baseline').textContent = ''; byId('robot-status').textContent = ''; renderRoute(); status('Discarded the input draft; original study and review remain available') })
  byId('file').addEventListener('change', run(async () => {
    need(!changed, 'Export or discard current draft before reopening another')
    const file = byId('file').files?.[0]; need(file && file.size <= 16777216, 'Choose a draft JSON file up to 16 MiB')
    const stamp = version, loaded = await readDraft(await file.text()); need(stamp === version && !changed, 'Draft changed during reopen; retry after exporting')
    draft = loaded.draft; selected = 0; variantInputs = []; changed = false; version++; render(); status('Reopened exact frozen inputs. This is still an unrun draft; no review is inherited')
  }))
  byId('robot').addEventListener('change', run(async () => {
    need(draft, 'Fork a mission first'); const stamp = version, file = byId('robot').files?.[0]
    need(file && file.size <= 8388608, 'Choose a MoonRobo robot-input JSON up to 8 MiB')
    const robot = await readRobotInput(await file.text()); need(stamp === version, 'Inputs changed during robot import; retry')
    draft = { ...collect(), robot_envelope_json: robot.text }; changed = true; version++; render(); status('Robot input adopted for every run in the comparable batch. Original study and review are preserved')
  }))
  byId('original-robot').addEventListener('click', run(async () => { draft = { ...collect(), robot_envelope_json: '' }; changed = true; version++; render(); status('Original robot baseline restored in this draft') }))
  byId('export').addEventListener('click', run(async () => {
    const stamp = version, candidate = collect(), text = await exportDraft(candidate)
    need(stamp === version, 'Inputs changed during export; export again to freeze the latest inputs')
    const filename = `${candidate.study_id}-${candidate.revision}-draft.json`, url = URL.createObjectURL(new Blob([text], { type: 'application/json' }))
    const link = document.createElement('a'); link.href = url; link.download = filename; link.click(); URL.revokeObjectURL(url)
    draft = candidate; changed = false
    byId('command').textContent = `Optional offline command from the MoonMoon repository:\nmoon run --target native cmd/mission_study -- run-draft "${filename}" "./${candidate.study_id}-${candidate.revision}-run"\nThe output directory must be new. The Run digital mission controls instead use the supported local host and import its actual returned dossier automatically.`
    status('Prepared frozen runnable inputs download. No simulation has run yet. Reopen this file to edit later; run the command below for real results')
  }))
  if (runOptions) bindMissionRun(document, {
    ...runOptions,
    context: () => [version, getActive()?.envelope.dossier_digest || '', runOptions.context()],
    freeze: async () => {
      const stamp = version, candidate = collect(), text = await exportDraft(candidate)
      need(stamp === version, 'Inputs changed while freezing the run; try again')
      frozenVersion = stamp
      return text
    },
    submitted: async text => {
      const loaded = await readDraft(text)
      if (version !== frozenVersion) { status('Earlier frozen inputs were accepted by the host. Your newer draft edits remain unsaved'); return }
      draft = loaded.draft; changed = false; status('Exact run inputs retained on the local host; later edits require another revision')
    },
    restore: async text => {
      need(!changed && !busy, 'Export or discard current input edits before restoring retained inputs')
      const stamp = version, loaded = await readDraft(text)
      need(stamp === version && !changed, 'Draft changed during restore; current edits were kept')
      draft = loaded.draft; selected = 0; variantInputs = []; changed = false; version++; render(); status('Reopened exact host-retained inputs. Use a new revision for changed inputs')
    },
  })
}
