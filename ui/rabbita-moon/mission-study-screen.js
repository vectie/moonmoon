// Reviewer-defined screening of existing dossier observations. No simulation,
// automatic recommendation, review persistence or physical authority.
const need = (ok, message) => { if (!ok) throw Error(message) }
const encoder = new TextEncoder()
const contract = 'moonmoon.alternative-screen.v1'
export const SCREEN_LIMIT_BYTES = 2 * 1024 * 1024
const stable = value => JSON.stringify(value, (_key, item) => item && !Array.isArray(item) && typeof item === 'object'
  ? Object.fromEntries(Object.keys(item).sort().map(key => [key, item[key]])) : item)
const numeric = [
  ['min_energy_margin_wh', 'Minimum retained energy margin', 'Wh', 'at-least'],
  ['max_duration_s', 'Maximum retained duration', 's', 'at-most'],
  ['max_segment_slope_deg', 'Maximum measured segment slope', 'degrees', 'at-most'],
]
const coverage = [
  ['require_declared_grid', 'Declared whole-grid verification', 'enumerated-path-with-declared-grid-verification'],
  ['require_declared_dataset', 'Declared available dataset evidence', 'declared-available'],
]

export function normalizeScreenCriteria(input) {
  const keys = [...numeric.map(row => row[0]), ...coverage.map(row => row[0]), 'note']
  need(input && typeof input === 'object' && !Array.isArray(input) && Object.keys(input).every(key => keys.includes(key)), 'Use only the supported screening criteria')
  const result = {}
  for (const [key, label] of numeric) {
    const value = input[key] ?? null
    need(value === null || (typeof value === 'number' && Number.isFinite(value) && value >= 0), `${label} must be a finite nonnegative number, or unselected`)
    need(key !== 'max_segment_slope_deg' || value === null || value <= 90, 'Maximum measured segment slope must be at most 90 degrees')
    result[key] = value
  }
  for (const [key] of coverage) {
    need(input[key] === undefined || typeof input[key] === 'boolean', 'Coverage requirements must be true or false')
    result[key] = input[key] ?? false
  }
  need(typeof (input.note ?? '') === 'string' && (input.note ?? '').length <= 2000, 'Screening note must be at most 2000 characters')
  result.note = input.note ?? ''
  need(numeric.some(([key]) => result[key] !== null) || coverage.some(([key]) => result[key]), 'Select at least one numeric or coverage criterion')
  return result
}

// The caller supplies a readStudy-verified dossier. Public file workflows below
// always re-run that reader before building or reopening any exported report.
export function screenAlternatives(study, input) {
  const criteria = normalizeScreenCriteria(input)
  const rows = study.alternatives.map(item => {
    const values = [item.result.energy?.margin_wh, item.result.duration_s, item.result.maximum_measured_segment_slope_deg]
    const checks = numeric.map(([key, label, unit, relation], index) => {
      const observed = Number.isFinite(values[index]) ? values[index] : null, threshold = criteria[key]
      const status = threshold === null ? 'not-selected' : observed === null ? 'unknown'
        : (relation === 'at-least' ? observed >= threshold : observed <= threshold) ? 'pass' : 'fail'
      return { criterion: key, label, observed, threshold, relation, unit, status }
    })
    const uncertainty = item.evaluation.uncertainty
    const declarations = [uncertainty.route_coverage, uncertainty.external_dataset_coverage]
    for (const [index, [key, label, required]] of coverage.entries()) {
      const observed = declarations[index] ?? null
      checks.push({ criterion: key, label, observed, required, status: !criteria[key] ? 'not-selected' : observed === required ? 'pass' : 'unknown' })
    }
    const blockers = [...item.result.blockers]
    if (item.result.result !== 'accepted') blockers.unshift(`Retained native decision: ${item.result.result}`)
    if (values[0] < 0) blockers.push('Retained energy margin is negative; screening cannot remove this blocker')
    const status = blockers.length || checks.some(check => check.status === 'fail') ? 'excluded'
      : checks.some(check => check.status === 'unknown') ? 'needs-evidence' : 'matches-review-criteria'
    return { session_id: item.session_id, route_id: item.result.route_id, status,
      retained_decision: item.result.result, blockers, checks,
      uncertainty: structuredClone(uncertainty), result_limitations: structuredClone(item.result.limitations),
      evidence: Object.fromEntries(['design_ref', 'result_ref', 'provenance_ref', 'replay_ref', 'evaluation_ref'].map(key => {
        const source = study.dossier.sources.find(source => source.artifact_ref === item[key])
        return [key, { path: source.artifact_ref, digest: source.digest }]
      })),
    }
  })
  return { contract_id: contract, method: 'retained-observation-screen-v1', authority: 'digital-only', physical_readiness: false,
    review_required: true, selection_performed: false,
    study_id: study.dossier.study_id, revision: study.dossier.revision, dossier_digest: study.envelope.dossier_digest,
    baseline_digest: study.alternatives[0].baseline_digest, site: structuredClone(study.dossier.site),
    criteria, alternatives: rows,
    summary: Object.fromEntries(['matches-review-criteria', 'excluded', 'needs-evidence'].map(status => [status, rows.filter(row => row.status === status).length])),
    study_limitations: [...study.dossier.limitations],
    limitations: [
      'Reviewer-defined comparisons of retained observations only; thresholds are not calibrated safety limits.',
      'Matching criteria is not a recommendation, approval, new simulation, scientific replay or physical readiness.',
      'Unselected criteria are not assessed. Missing coverage remains unknown, including when it is not selected as a requirement.',
      'Slope is measured segment slope only. Unmodeled obstacles, slip, sinkage and other hazards remain unknown.',
      'Dataset and grid statuses are retained declarations, not verified source truth or authentication.',
      'Keep the exact original dossier with this report; sources and review history are not embedded.',
    ],
  }
}

export async function createAlternativeScreen(studyText, criteria, readStudy, hash) {
  const report = screenAlternatives(await readStudy(studyText), criteria)
  const reportText = JSON.stringify(report)
  const text = JSON.stringify({ contract_id: 'moonmoon.alternative-screen-envelope.v1', report_json: reportText, report_digest: await hash(reportText) })
  need(encoder.encode(text).length <= SCREEN_LIMIT_BYTES, 'Screening report exceeds the 2 MiB limit')
  return { report, text }
}

export async function readAlternativeScreen(text, studyText, readStudy, hash) {
  need(typeof text === 'string' && encoder.encode(text).length <= SCREEN_LIMIT_BYTES, 'Choose a screening report of at most 2 MiB')
  const envelope = JSON.parse(text)
  need(envelope?.contract_id === 'moonmoon.alternative-screen-envelope.v1' && typeof envelope.report_json === 'string', 'Unsupported screening report')
  need(await hash(envelope.report_json) === envelope.report_digest, 'Screening report digest changed')
  const report = JSON.parse(envelope.report_json), study = await readStudy(studyText)
  need(report.dossier_digest === study.envelope.dossier_digest && report.study_id === study.dossier.study_id && report.revision === study.dossier.revision, 'Screening report belongs to a different exact dossier; open its original study first')
  const recomputed = screenAlternatives(study, report.criteria)
  need(stable(recomputed) === stable(report), 'Screening report differs from recomputed criteria and retained evidence')
  return { report: recomputed, text }
}

export function bindStudyScreen(document, panel, { getCurrent, readStudy, hash }) {
  const element = (tag, text, suffix) => {
    const node = document.createElement(tag)
    if (text !== undefined) node.textContent = text
    if (suffix) node.id = 'study-screen-' + suffix
    return node
  }
  const host = element('section', undefined, 'panel')
  host.appendChild(element('h3', 'Screen alternatives against review criteria'))
  host.appendChild(element('p', 'Choose your own limits, inspect every alternative and retain why a candidate matched or was excluded. Blank numeric limits are unselected. Native blockers remain. Matching criteria never selects or approves a mission.'))
  const inputs = {}
  for (const [key, label, unit] of numeric) {
    const holder = element('label', `${label} (${unit})`), input = element('input', undefined, key)
    input.type = 'text'; input.inputMode = 'decimal'; input.maxLength = 64; holder.appendChild(input); host.appendChild(holder); inputs[key] = input
  }
  for (const [key, label] of coverage) {
    const holder = element('label', `Require ${label.toLowerCase()}`), input = element('input', undefined, key)
    input.type = 'checkbox'; input.checked = false; holder.appendChild(input); host.appendChild(holder); inputs[key] = input
  }
  const noteLabel = element('label', 'Why these review criteria? (optional, 2000 characters)')
  const note = element('textarea', undefined, 'note'); note.maxLength = 2000; noteLabel.appendChild(note); host.appendChild(noteLabel); inputs.note = note
  const apply = element('button', 'Apply review criteria', 'apply'), clear = element('button', 'Clear screening', 'clear'), download = element('button', 'Download screening report', 'download')
  for (const button of [apply, clear, download]) { button.type = 'button'; host.appendChild(button) }
  const fileLabel = element('label', 'Reopen screening report for this dossier (JSON, up to 2 MiB)')
  const file = element('input', undefined, 'file'); file.type = 'file'; file.accept = '.json,application/json'; fileLabel.appendChild(file); host.appendChild(fileLabel)
  const status = element('p', '', 'status'); status.role = 'status'; status.ariaLive = 'polite'; host.appendChild(status)
  const output = element('div', undefined, 'output'); host.appendChild(output); panel.appendChild(host)
  let activeDigest, report = null, generation = 0, busy = false
  const enable = () => { apply.disabled = !getCurrent() || busy; file.disabled = !getCurrent(); download.disabled = !report || busy }
  const reset = () => {
    generation++; report = null; output.replaceChildren(); file.value = ''
    for (const [key] of numeric) inputs[key].value = ''
    for (const [key] of coverage) inputs[key].checked = false
    note.value = ''; enable()
  }
  const edit = () => { generation++; report = null; output.replaceChildren(); status.textContent = 'Criteria changed. Apply review criteria to inspect this exact dossier.'; enable() }
  for (const [key, input] of Object.entries(inputs)) input.addEventListener(key.startsWith('require_') ? 'change' : 'input', edit)
  const values = () => {
    const result = { note: note.value }
    for (const [key, label] of numeric) {
      const text = inputs[key].value.trim()
      need(!text || (text.length <= 64 && /^(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/.test(text)), `${label}: enter a nonnegative decimal number or leave blank`)
      const number = text ? Number(text) : null
      need(number !== 0 || !/[1-9]/.test(text.split(/[eE]/)[0]), `${label} is too small to represent`)
      result[key] = number
    }
    for (const [key] of coverage) result[key] = inputs[key].checked
    return normalizeScreenCriteria(result)
  }
  const draw = report => {
    output.replaceChildren()
    output.appendChild(element('p', `${report.study_id} / ${report.revision} · ${report.dossier_digest}\n${report.summary['matches-review-criteria']} match review criteria; ${report.summary.excluded} excluded; ${report.summary['needs-evidence']} need evidence. Every alternative is shown, in original order. No ranking or selection.`))
    output.appendChild(element('p', `Criteria note: ${report.criteria.note || '(none)'}\nSite/frame/coverage: ${JSON.stringify(report.site)}`))
    for (const row of report.alternatives) {
      const section = element('section'); section.appendChild(element('h4', `${row.session_id}: ${row.status}`))
      section.appendChild(element('p', `Retained decision: ${row.retained_decision}; route: ${row.route_id}\nBlockers: ${row.blockers.join('; ') || 'none in retained evidence'}`))
      const table = element('table'); table.className = 'study-sensitivity-matrix'
      table.appendChild(element('caption', 'Selected criteria compare retained observations; equality passes'))
      const head = element('tr'); for (const label of ['Criterion', 'Observed', 'Requested', 'Status']) { const cell = element('th', label); cell.scope = 'col'; head.appendChild(cell) } table.appendChild(head)
      for (const check of row.checks) {
        const tr = element('tr'), label = element('th', check.label); label.scope = 'row'; tr.appendChild(label)
        for (const value of [check.observed === null ? 'unknown' : `${check.observed}${check.unit ? ' ' + check.unit : ''}`,
          check.status === 'not-selected' ? 'not selected' : check.unit ? `${check.relation} ${check.threshold} ${check.unit}` : check.required, check.status]) tr.appendChild(element('td', value))
        table.appendChild(tr)
      }
      section.appendChild(table)
      section.appendChild(element('pre', `Uncertainty: ${JSON.stringify(row.uncertainty, null, 2)}\nRetained limits: ${JSON.stringify(row.result_limitations, null, 2)}`))
      output.appendChild(section)
    }
    output.appendChild(element('pre', [...report.study_limitations, ...report.limitations].join('\n')))
  }
  apply.addEventListener('click', () => {
    generation++
    try { need(getCurrent(), 'Open a study first'); report = screenAlternatives(getCurrent(), values()); draw(report); status.textContent = 'Review criteria applied. Inspect the retained uncertainty and blockers before writing any named digital review.' }
    catch (error) { report = null; output.replaceChildren(); status.textContent = `Screening unavailable: ${error.message}` }
    enable()
  })
  clear.addEventListener('click', () => { reset(); status.textContent = 'Screening cleared. The study and review edits are unchanged.' })
  download.addEventListener('click', async () => {
    if (!report || busy) return
    const selected = getCurrent(), selectedReport = report, token = generation
    busy = true; enable()
    try {
      const result = await createAlternativeScreen(selected.text, selectedReport.criteria, readStudy, hash)
      if (token !== generation || selected.envelope.dossier_digest !== getCurrent()?.envelope.dossier_digest) return
      const url = URL.createObjectURL(new Blob([result.text], { type: 'application/json' }))
      try { const link = document.createElement('a'); link.href = url; link.download = `${result.report.study_id}-${result.report.revision}-screening.json`; link.click() }
      finally { URL.revokeObjectURL(url) }
      status.textContent = 'Prepared screening report download. Keep its exact original dossier separately. Browser file saving is not confirmed; this is no review or approval.'
    } catch (error) { if (token === generation) status.textContent = `Screening download unavailable: ${error.message}` }
    finally { busy = false; enable() }
  })
  file.addEventListener('change', async () => {
    const token = ++generation, selected = getCurrent(), chosen = file.files?.[0]
    try {
      need(selected, 'Open the report’s original dossier first')
      need(chosen && chosen.size <= SCREEN_LIMIT_BYTES, 'Choose a screening report of at most 2 MiB')
      status.textContent = 'Checking report identity and recomputing its criteria…'
      const loaded = await readAlternativeScreen(await chosen.text(), selected.text, readStudy, hash)
      if (token !== generation || selected.envelope.dossier_digest !== getCurrent()?.envelope.dossier_digest) return
      report = loaded.report
      for (const [key] of numeric) inputs[key].value = report.criteria[key] === null ? '' : String(report.criteria[key])
      for (const [key] of coverage) inputs[key].checked = report.criteria[key]
      note.value = report.criteria.note; draw(report)
      status.textContent = 'Reopened and recomputed screening for this exact dossier. Your study and named review are unchanged.'
    } catch (error) { if (token === generation) status.textContent = `Screening report unavailable: ${error.message}. Current screening and review edits were kept.` }
    finally { if (token === generation) file.value = ''; enable() }
  })
  return current => {
    const digest = current?.envelope.dossier_digest ?? null
    if (activeDigest !== digest) { activeDigest = digest; reset(); status.textContent = current ? 'Choose review criteria for this exact dossier.' : 'Open a frozen study to screen its alternatives.' }
    enable()
  }
}
