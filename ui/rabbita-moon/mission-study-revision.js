// Read-only comparison of two readStudy-verified snapshots. No simulation,
// persistence, review adoption, session matching or scientific ranking.
const stable = value => JSON.stringify(value, (_key, item) => item && !Array.isArray(item) && typeof item === 'object'
  ? Object.fromEntries(Object.keys(item).sort().map(key => [key, item[key]])) : item)
const need = (ok, message) => { if (!ok) throw Error(message) }
const display = value => value === undefined ? '(absent)' : JSON.stringify(value, null, 2)
const changedSections = (before, after) => [...new Set([...Object.keys(before), ...Object.keys(after)])].sort()
  .filter(key => stable(before[key]) !== stable(after[key]))
  .map(key => ({ key, before: before[key], after: after[key] }))

// Run products differ by design. Everything else stays in the supporting-input
// identity gate, including terrain, robot files, calibration and dataset evidence.
function supportingSources(study) {
  const excluded = new Set()
  for (const alternative of study.alternatives) {
    for (const field of ['design_ref', 'result_ref', 'provenance_ref', 'replay_ref', 'evaluation_ref']) excluded.add(alternative[field])
    const replay = study.dossier.sources.find(source => source.artifact_ref === alternative.replay_ref)
    excluded.add(JSON.parse(replay.text).replay_result_ref)
  }
  return Object.fromEntries(study.dossier.sources.filter(source => !excluded.has(source.artifact_ref))
    .map(source => [source.artifact_ref, source.digest]))
}
const identity = study => ({ study: study.dossier.study_id, revision: study.dossier.revision, digest: study.envelope.dossier_digest })
const evidence = (study, item) => Object.fromEntries(['design_ref', 'result_ref', 'provenance_ref', 'replay_ref', 'evaluation_ref'].map(field => {
  const source = study.dossier.sources.find(source => source.artifact_ref === item[field])
  return [field, { path: source.artifact_ref, digest: source.digest }]
}))

export function compareStudyRevision(previous, current, previousSession, currentSession) {
  const before = previous.alternatives.find(item => item.session_id === previousSession)
  const after = current.alternatives.find(item => item.session_id === currentSession)
  need(before && after, 'Choose an exact previous session and current session; sessions are never paired automatically')
  const baselineChanges = changedSections(JSON.parse(before.baseline_json), JSON.parse(after.baseline_json))
  const sourceChanges = changedSections(supportingSources(previous), supportingSources(current))
  const identityConflict = previous.dossier.study_id === current.dossier.study_id && previous.dossier.revision === current.dossier.revision && previous.envelope.dossier_digest !== current.envelope.dossier_digest
  const comparable = !identityConflict && !baselineChanges.length && !sourceChanges.length
  const metric = (label, unit, before, after) => ({ label, unit, before, after, delta: comparable && Number.isFinite(after - before) ? after - before : null })
  return {
    previous: identity(previous), current: identity(current), previousSession, currentSession,
    sameDossier: previous.envelope.dossier_digest === current.envelope.dossier_digest,
    directParent: current.dossier.parent_digest === previous.envelope.dossier_digest,
    identityConflict, comparable, baselineChanges, sourceChanges,
    inputChanges: changedSections(before.design, after.design),
    evidence: { previous: evidence(previous, before), current: evidence(current, after) },
    metrics: [metric('Distance', 'm', before.result.distance_m, after.result.distance_m),
      metric('Duration', 's', before.result.duration_s, after.result.duration_s),
      metric('Maximum measured segment slope', 'degrees', before.result.maximum_measured_segment_slope_deg, after.result.maximum_measured_segment_slope_deg),
      metric('Energy margin', 'Wh', before.result.energy.margin_wh, after.result.energy.margin_wh)],
    retained: [previous, current].map((study, index) => {
      const item = index ? after : before
      return { decision: item.result.result, blockers: item.result.blockers, uncertainty: item.evaluation.uncertainty,
        limitations: { study: study.dossier.limitations, result: item.result.limitations } }
    }),
  }
}

export function bindStudyRevisionComparison(document, panel, { getCurrent, readStudy }) {
  const element = (tag, text, suffix) => {
    const node = document.createElement(tag)
    if (text !== undefined) node.textContent = text
    if (suffix) node.id = 'study-revision-' + suffix
    return node
  }
  const host = element('section', undefined, 'comparison')
  host.appendChild(element('h3', 'Inspect changes from a previous dossier'))
  host.appendChild(element('p', 'Import a previous frozen dossier, then explicitly choose the two sessions to inspect. Your open study and review edits are kept. Comparison is page-local and read-only.'))
  const fileLabel = element('label', 'Previous dossier JSON (up to 8 MiB)')
  const file = element('input', undefined, 'file'); file.type = 'file'; file.accept = '.json,application/json'; fileLabel.appendChild(file); host.appendChild(fileLabel)
  const previousSelect = element('select', undefined, 'previous-session'), currentSelect = element('select', undefined, 'current-session')
  for (const [label, select] of [['Previous session', previousSelect], ['Current session', currentSelect]]) {
    const holder = element('label', label); holder.appendChild(select); host.appendChild(holder)
  }
  const clear = element('button', 'Clear comparison', 'clear'); clear.type = 'button'; host.appendChild(clear)
  const status = element('p', 'Open a current study first, then choose a previous dossier.', 'status'); status.role = 'status'; status.ariaLive = 'polite'; host.appendChild(status)
  const output = element('div', undefined, 'output'); host.appendChild(output); panel.appendChild(host)
  let previous = null, activeDigest, generation = 0
  const options = (select, study) => {
    const placeholder = element('option', 'Choose a session'); placeholder.value = ''
    select.replaceChildren(placeholder)
    for (const item of study?.alternatives || []) { const option = element('option', item.session_id); option.value = item.session_id; select.appendChild(option) }
    select.value = ''; select.disabled = !study
  }
  const details = (title, value) => {
    const node = element('details'); node.appendChild(element('summary', title)); node.appendChild(element('pre', display(value))); output.appendChild(node)
  }
  const changes = (title, rows) => details(`${title}: ${rows.length}`, rows.map(row => ({ field: row.key, previous: row.before === undefined ? '(absent)' : row.before, current: row.after === undefined ? '(absent)' : row.after })))
  const draw = () => {
    output.replaceChildren()
    const current = getCurrent()
    if (!previous || !current) return
    output.appendChild(element('p', `Previous: ${previous.dossier.study_id} / ${previous.dossier.revision} · ${previous.envelope.dossier_digest}\nCurrent: ${current.dossier.study_id} / ${current.dossier.revision} · ${current.envelope.dossier_digest}`))
    if (!previousSelect.value || !currentSelect.value) { output.appendChild(element('p', 'Choose both sessions explicitly. Matching names or list positions do not establish a pair.')); return }
    try {
      const comparison = compareStudyRevision(previous, current, previousSelect.value, currentSelect.value)
      output.appendChild(element('p', comparison.identityConflict ? 'Incomparable: different evidence uses the same study/revision identity. Preserve both files and resolve the conflict.'
        : comparison.comparable ? 'Common baseline and supporting source identities match. Deltas are current minus previous; they do not rank or approve a route.'
          : 'Incomparable: common baseline or supporting source identities changed. Values remain separate retained observations; numeric deltas are withheld.'))
      output.appendChild(element('p', comparison.sameDossier ? 'Both selections use the same exact dossier.' : comparison.directParent ? 'The current dossier explicitly names the previous digest as its direct parent.' : 'No direct parent relationship is asserted by the current dossier.'))
      const table = element('table'); table.className = 'study-sensitivity-matrix'
      const caption = element('caption', `${comparison.previousSession} → ${comparison.currentSession} · retained digital results`); table.appendChild(caption)
      const head = element('tr'); for (const title of ['Measure', 'Previous', 'Current', 'Delta']) { const cell = element('th', title); cell.scope = 'col'; head.appendChild(cell) } table.appendChild(head)
      for (const row of comparison.metrics) {
        const tr = element('tr')
        const label = element('th', row.label); label.scope = 'row'; tr.appendChild(label)
        for (const value of [`${row.before} ${row.unit}`, `${row.after} ${row.unit}`, row.delta === null ? 'Unavailable' : `${row.delta > 0 ? '+' : ''}${Number(row.delta.toPrecision(12))} ${row.unit}`]) tr.appendChild(element('td', value))
        table.appendChild(tr)
      }
      output.appendChild(table)
      // Blockers and uncertainty are always expanded, including negative energy.
      for (const [index, retained] of comparison.retained.entries()) {
        output.appendChild(element('h4', index ? 'Current retained decision and limits' : 'Previous retained decision and limits'))
        output.appendChild(element('pre', display(retained)))
      }
      changes('Changed common baseline fields', comparison.baselineChanges)
      changes('Changed supporting source identities', comparison.sourceChanges)
      changes('Changed mission input sections', comparison.inputChanges)
      details('Exact design, result, provenance, replay and evaluation identities', comparison.evidence)
      output.appendChild(element('p', 'Integrity-checked dossier snapshots only. No new native replay, scientific validation, review adoption, ranking or physical authority. A new recommendation requires its own named digital review.'))
    } catch (error) { output.appendChild(element('p', `Comparison unavailable: ${error.message}`)) }
  }
  const reset = () => { previous = null; options(previousSelect, null); options(currentSelect, getCurrent()); output.replaceChildren(); file.value = '' }
  previousSelect.addEventListener('change', draw); currentSelect.addEventListener('change', draw)
  clear.addEventListener('click', () => { generation++; reset(); status.textContent = 'Comparison cleared. Open study and review edits are unchanged.' })
  file.addEventListener('change', async () => {
    const token = ++generation, selected = getCurrent(), chosen = file.files?.[0]
    try {
      need(selected, 'Open a current study before choosing a previous dossier')
      need(chosen && chosen.size <= 8388608, 'Choose a local dossier JSON file of at most 8 MiB')
      status.textContent = 'Checking the previous dossier and exact frozen source identities…'
      const checked = await readStudy(await chosen.text())
      if (token !== generation || selected.envelope.dossier_digest !== getCurrent()?.envelope.dossier_digest) return
      previous = checked; options(previousSelect, previous); options(currentSelect, selected); draw()
      status.textContent = 'Previous dossier verified for inspection. Choose both sessions; no review or stored evidence was changed.'
    } catch (error) {
      if (token === generation) status.textContent = `Previous dossier unavailable: ${error.message}. Existing comparison, open study and review edits were kept.`
    } finally { if (token === generation) file.value = '' }
  })
  return current => {
    const digest = current?.envelope.dossier_digest || null
    if (activeDigest !== digest) {
      generation++; activeDigest = digest; reset()
      status.textContent = current ? 'Current dossier changed. Choose a previous dossier for this exact revision.' : 'Open a current study first, then choose a previous dossier.'
    }
    file.disabled = !current
  }
}
