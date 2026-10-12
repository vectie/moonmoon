// Presentation and input handling only. All numerical evidence comes from the
// compiled MoonBit analyzer shared with cmd/terrain_import.
export const exampleAnalysisAscii = 'ncols 7\nnrows 5\nxllcorner 1000\nyllcorner 2000\ncellsize 10\nNODATA_value -9999\n104 105 107 115 107 105 104\n103 104 106 114 106 104 103\n102 103 105 113 105 103 102\n101 102 104 112 104 -9999 101\n100 101 103 111 103 101 100\n'

export function analysisState() {
  return { axis: 'row', index: '0', threshold: '15', result: null }
}

export function calculateAnalysis(bundle, state, analyze) {
  const index = Number(state.index), threshold = Number(state.threshold)
  if (!state.index.trim() || !Number.isSafeInteger(index) || index < 0 || index >= (state.axis === 'row' ? bundle.rows : bundle.cols)) throw new Error('Choose a zero-based transect index within the raster')
  if (!state.threshold.trim() || !Number.isFinite(threshold) || threshold < 0 || threshold >= 90) throw new Error('Choose a screening threshold from 0 to less than 90 degrees')
  const checked = JSON.parse(analyze(JSON.stringify(bundle), state.axis, index, threshold))
  if (!checked.ok) throw new Error(checked.error || 'Terrain analysis failed')
  return checked.analysis
}

// Nulls split the trace rather than inventing an interpolated crossing.
export function profileRuns(points) {
  const runs = []; let current = []
  for (const point of points) {
    if (point.elevation_m === null) {
      if (current.length) runs.push(current)
      current = []
    } else current.push(point)
  }
  if (current.length) runs.push(current)
  return runs
}

export function renderTerrainAnalysis({ document, output, bundle, analyze, state, download, active, selectCell, selected }) {
  const el = (tag, text, attrs = {}) => {
    const node = document.createElement(tag)
    if (text !== undefined) node.textContent = text
    for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, value)
    return node
  }
  const section = el('section', undefined, { class: 'terrain-analysis', 'aria-label': 'Metric terrain analysis' })
  output.appendChild(section)
  section.appendChild(el('h3', 'Analyze slopes, roughness and a terrain profile'))
  section.appendChild(el('p', 'A local 3×3 plane estimates slope and RMS vertical roughness. Boundary cells and incomplete neighborhoods remain unknown. Row/column profiles use adjacent known elevations only. Screening is exploratory and is not a rover limit or safety certification.'))
  if (bundle.horizontal_unit !== 'm') {
    section.appendChild(el('p', 'Analysis unavailable for degree grids. Reproject externally into a documented metre frame before importing again. Elevation inspection and source export remain available.', { role: 'status' }))
    return
  }
  const axis = el('select', undefined, { id: 'terrain-analysis-axis' })
  for (const [value, text] of [['row', 'Row: increasing source x'], ['column', 'Column: decreasing source y']]) {
    const option = el('option', text); option.value = value; axis.appendChild(option)
  }
  axis.value = state.axis
  const index = el('input', undefined, { id: 'terrain-analysis-index', type: 'number', min: '0', step: '1' })
  index.value = state.index
  const threshold = el('input', undefined, { id: 'terrain-analysis-threshold', type: 'number', min: '0', max: '89.999999', step: 'any' })
  threshold.value = state.threshold
  for (const [control, label] of [[axis, 'Transect direction'], [index, 'Row/column index (zero-based)'], [threshold, 'Slope screening threshold (degrees)']]) {
    const wrapper = el('label', label); wrapper.appendChild(control); section.appendChild(wrapper)
  }
  const status = el('p', 'Choose a transect and screening threshold, then calculate.', { id: 'terrain-analysis-status', role: 'status', 'aria-live': 'polite' })
  const refreshIndex = () => index.setAttribute('max', String((state.axis === 'row' ? bundle.rows : bundle.cols) - 1))
  refreshIndex()
  axis.addEventListener('change', () => { if (!active()) return; state.axis = axis.value; refreshIndex(); status.textContent = 'Inputs changed. Calculate to update the evidence. Existing exports still describe the last calculation.' })
  for (const [control, key] of [[index, 'index'], [threshold, 'threshold']]) control.addEventListener('input', () => { if (!active()) return; state[key] = control.value; status.textContent = 'Inputs changed. Calculate to update the evidence. Existing exports still describe the last calculation.' })
  const calculate = el('button', 'Calculate terrain analysis', { id: 'terrain-analysis-calculate', type: 'button' })
  section.appendChild(calculate); section.appendChild(status)
  const results = el('div', undefined, { id: 'terrain-analysis-results' }); section.appendChild(results)
  const render = () => {
    results.replaceChildren()
    const result = state.result
    if (!result) return
    const params = result.parameters, summary = result.profile_summary, grid = result.grid_summary
    results.appendChild(el('h4', `Calculated ${params.axis} ${params.index}; screening above ${params.slope_threshold_deg}°`))
    results.appendChild(el('p', `${grid.estimated_cells} local estimates; ${grid.unknown_cells} unknown cells; ${grid.threshold_exceeded_cells} above threshold. A below-threshold estimate is not a safety finding.`))
    results.appendChild(el('p', `${summary.known_samples}/${summary.sample_count} known profile elevations. Horizontal span ${summary.horizontal_span_m} m; measured adjacent distance ${summary.measured_segment_distance_m} m; ${summary.unknown_segments} unknown segments. Observed ascent ${summary.observed_ascent_m} m; descent ${summary.observed_descent_m} m${summary.complete_elevation_coverage ? '' : ' (partial coverage)'}.`))
    const current = result.cells[selected]
    results.appendChild(el('p', `Selected cell [${current.row},${current.col}]: ${current.estimate_status}; slope ${current.slope_deg ?? 'unknown'}°; roughness RMS ${current.roughness_rms_m ?? 'unknown'} m; ${current.slope_screening}.`, { id: 'terrain-analysis-cell-detail' }))
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
    svg.setAttribute('viewBox', `0 0 ${bundle.cols} ${bundle.rows}`); svg.setAttribute('class', 'terrain-import-map')
    svg.setAttribute('role', 'img'); svg.setAttribute('aria-label', 'Slope screening map. Red exceeds threshold, blue is within threshold, crossed gray is unknown. Cell selector above gives textual estimates.')
    for (const cell of result.cells) {
      const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect')
      for (const [key, value] of Object.entries({ x: cell.col, y: cell.row, width: 1, height: 1, fill: cell.slope_screening === 'unknown' ? '#666' : cell.slope_screening === 'threshold-exceeded' ? '#d2533e' : '#247b9e', stroke: cell.row * bundle.cols + cell.col === selected ? '#fff' : '#222', 'stroke-width': .04 })) rect.setAttribute(key, String(value))
      rect.addEventListener('click', () => { if (active()) selectCell(cell.row * bundle.cols + cell.col) }); svg.appendChild(rect)
      if (cell.slope_screening === 'unknown') {
        const cross = document.createElementNS('http://www.w3.org/2000/svg', 'path')
        for (const [key, value] of Object.entries({ d: `M ${cell.col + .2} ${cell.row + .2} l .6 .6 M ${cell.col + .8} ${cell.row + .2} l -.6 .6`, stroke: '#ddd', 'stroke-width': .06, 'pointer-events': 'none' })) cross.setAttribute(key, String(value))
        svg.appendChild(cross)
      }
    }
    results.appendChild(svg)
    results.appendChild(el('p', 'Slope screening: red exceeds threshold; blue is within threshold; gray × is unknown. Roughness is a separate vertical RMS residual, not used in the slope screening.'))
    const profile = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
    profile.setAttribute('viewBox', '0 0 640 200'); profile.setAttribute('class', 'terrain-analysis-profile'); profile.setAttribute('role', 'img'); profile.setAttribute('aria-label', 'Elevation profile. Gaps are not connected. Exact coordinates and signed grades are in the table below.')
    const known = result.profile.filter(point => point.elevation_m !== null)
    if (known.length) {
      const low = Math.min(...known.map(p => p.elevation_m)), high = Math.max(...known.map(p => p.elevation_m))
      const x = p => 30 + 580 * p.distance_m / (summary.horizontal_span_m || 1)
      const scale = Math.max(Math.abs(low), Math.abs(high), 1)
      const y = p => 170 - 140 * (p.elevation_m / scale - low / scale) / ((high / scale - low / scale) || 1)
      for (const run of profileRuns(result.profile)) {
        const path = document.createElementNS('http://www.w3.org/2000/svg', 'polyline')
        path.setAttribute('points', run.map(p => `${x(p)},${y(p)}`).join(' ')); path.setAttribute('fill', 'none'); path.setAttribute('stroke', '#5bbfdd'); path.setAttribute('stroke-width', '2'); profile.appendChild(path)
        for (const point of run) {
          const dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle')
          dot.setAttribute('cx', String(x(point))); dot.setAttribute('cy', String(y(point))); dot.setAttribute('r', '3'); dot.setAttribute('fill', '#fff'); profile.appendChild(dot)
        }
      }
      results.appendChild(el('p', `Profile axes: horizontal distance 0–${summary.horizontal_span_m} m; elevation ${low}–${high} m. Dots are cell-center samples; lines are visual guides only.`))
    } else results.appendChild(el('p', 'No known elevations in this transect. No profile line can be drawn.'))
    results.appendChild(profile)
    const table = el('table'); table.appendChild(el('caption', 'Exact transect samples; grade describes the segment ending at that sample'))
    const heading = el('tr')
    for (const text of ['Row/col', 'Distance (m)', 'Elevation (m)', 'Segment', 'Rise (m)', 'Grade (%)', 'Grade (°)']) heading.appendChild(el('th', text, { scope: 'col' }))
    table.appendChild(heading)
    for (const point of result.profile) {
      const row = el('tr')
      for (const value of [`${point.row}/${point.col}`, point.distance_m, point.elevation_m ?? 'NODATA', point.segment_status, point.rise_m ?? 'unknown', point.grade_percent ?? 'unknown', point.grade_deg ?? 'unknown']) row.appendChild(el('td', String(value)))
      table.appendChild(row)
    }
    const scroll = el('div', undefined, { class: 'terrain-import-table' }); scroll.appendChild(table); results.appendChild(scroll)
    results.appendChild(el('p', result.analysis_digest, { class: 'terrain-import-digest' }))
    for (const [name, label, text, suffix, type] of [
      ['profile-csv', 'Download profile CSV', result.profile_csv, '-profile.csv', 'text/csv'],
      ['cells-csv', 'Download slope/roughness CSV', result.cells_csv, '-cells.csv', 'text/csv'],
      ['report', 'Download readable analysis report', result.report_markdown, '-analysis.md', 'text/markdown'],
      ['evidence', 'Download complete analysis evidence', JSON.stringify(result, null, 2) + '\n', '-analysis.json', 'application/json'],
    ]) {
      const button = el('button', label, { id: 'terrain-analysis-' + name, type: 'button' })
      button.addEventListener('click', () => { if (active() && state.result === result) download(text, bundle.tile_id + suffix, type) }); results.appendChild(button)
    }
    results.appendChild(el('p', 'Evidence includes the verified source bundle, method, parameters, null estimates and CSV digests. Recompute revised assumptions as new evidence. Source frame, units and truth remain unverified; no mission acceptance or physical readiness.'))
  }
  calculate.addEventListener('click', () => {
    if (!active()) return
    try {
      state.result = calculateAnalysis(bundle, state, analyze)
      render(); status.textContent = 'Analysis calculated for the imported source. Unknown coverage remains explicit.'
    } catch (error) { status.textContent = `${error.message}. ${state.result ? 'Previous calculation remains available.' : ''}` }
  })
  render()
}
