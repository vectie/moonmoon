// UI adapter only: routes and all distances/grades come from the shared
// MoonBit route engine. Selection never edits source terrain or a mission.
export function terrainRouteState() {
  return { start: null, goal: null, grade: '20', uphill: '0', result: null }
}

export function calculateTerrainRoute(bundle, state, route) {
  if (bundle.horizontal_unit !== 'm') throw new Error('Routes require a declared metre grid; reproject degree grids separately')
  for (const [label, index] of [['Start', state.start], ['Goal', state.goal]]) {
    if (!Number.isInteger(index) || index < 0 || index >= bundle.samples.length) throw new Error(`Choose a ${label.toLowerCase()} cell first`)
    if (bundle.samples[index].elevation_m === null) throw new Error(`${label} cell is NODATA; choose a known elevation`)
  }
  const grade = Number(state.grade), uphill = Number(state.uphill)
  if (!state.grade.trim() || !Number.isFinite(grade) || grade < 0 || grade >= 90) throw new Error('Maximum adjacent grade must be from 0 to less than 90 degrees')
  if (!state.uphill.trim() || !Number.isFinite(uphill) || uphill < 0) throw new Error('Uphill preference must be finite and nonnegative')
  if (typeof route !== 'function') throw new Error('The terrain route engine is unavailable in this build')
  const start = bundle.samples[state.start], goal = bundle.samples[state.goal]
  const response = JSON.parse(route(JSON.stringify(bundle), start.row, start.col, goal.row, goal.col, grade, uphill))
  if (!response.ok) throw new Error(response.error || 'Route calculation failed')
  const result = response.route, p = result?.parameters
  if (result?.contract_id !== 'moonmoon.terrain-route.v1' || !['candidate-found', 'no-path'].includes(result.status) || !Array.isArray(result.path) || result.source_bundle?.source_digest !== bundle.source_digest || !p || p.start_row !== start.row || p.start_col !== start.col || p.goal_row !== goal.row || p.goal_col !== goal.col || p.max_grade_deg !== grade || p.uphill_weight !== uphill) throw new Error('Route response does not match the selected source and preferences')
  return result
}

export function renderTerrainRoute({ document, output, bundle, state, route, selected, selectCell, active, map }) {
  const el = (tag, text, attrs = {}) => {
    const node = document.createElement(tag)
    if (text !== undefined) node.textContent = text
    for (const [name, value] of Object.entries(attrs)) node.setAttribute(name, value)
    return node
  }
  const section = el('section', undefined, { 'aria-label': 'Explore a terrain route' }); output.appendChild(section)
  section.appendChild(el('h3', 'Explore a route between selected cells'))
  section.appendChild(el('p', 'Select a cell on the map or with the cell selector, then set Start or Goal. The shared terrain engine searches known four-neighbor cell centers. This does not change mission inputs or establish physical readiness.'))
  if (bundle.horizontal_unit !== 'm') { section.appendChild(el('p', 'Routing unavailable for degree grids. Reproject externally into a documented metre frame first.', { id: 'terrain-route-status', role: 'status' })); return }
  const endpoints = el('p', '', { id: 'terrain-route-endpoints' }); section.appendChild(endpoints)
  const status = el('p', '', { id: 'terrain-route-status', role: 'status', 'aria-live': 'polite' })
  const resultView = el('div', undefined, { id: 'terrain-route-result' })
  const overlay = document.createElementNS('http://www.w3.org/2000/svg', 'g'); overlay.setAttribute('pointer-events', 'none'); map.appendChild(overlay)
  const marker = (tag, attrs) => { const node = document.createElementNS('http://www.w3.org/2000/svg', tag); for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, String(value)); overlay.appendChild(node); return node }
  const label = index => index === null ? 'not set' : `[${bundle.samples[index].row},${bundle.samples[index].col}] (${bundle.samples[index].elevation_m ?? 'NODATA'} m)`
  const refresh = (message = '') => {
    resultView.replaceChildren(); overlay.replaceChildren()
    endpoints.textContent = `Start ${label(state.start)}; Goal ${label(state.goal)}. Green S and orange G mark endpoints; white line marks the calculated candidate.`
    for (const [index, letter, color] of [[state.start, 'S', '#47ee97'], [state.goal, 'G', '#ffb347']]) {
      if (index === null) continue
      const cell = bundle.samples[index]
      marker('circle', { cx: cell.col + .5, cy: cell.row + .5, r: .34, fill: color, stroke: '#111', 'stroke-width': .04 })
      marker('text', { x: cell.col + .5, y: cell.row + .64, 'text-anchor': 'middle', 'font-size': .4, fill: '#111' }).textContent = letter
    }
    if (state.start === state.goal && state.start !== null) endpoints.textContent += ' Start and goal are the same cell.'
    status.textContent = message || (state.result ? 'Calculated for these endpoints and preferences.' : 'Choose endpoints and preferences, then calculate. Previous route results clear when these inputs change.')
    const result = state.result
    if (!result) return
    if (result.status === 'no-path') {
      resultView.appendChild(el('p', 'No path connects these endpoints under this grade cap and known-cell coverage. No distance or ascent total is available. Try different endpoints or preferences; this is not proof that no real-world route exists.'))
    } else {
      const summary = result.summary
      resultView.appendChild(el('p', `Candidate: ${summary.cell_count} cells; ${summary.horizontal_distance_m} m horizontal distance; ${summary.ascent_m} m ascent; ${summary.descent_m} m descent; maximum adjacent grade ${summary.max_absolute_grade_deg}°. Objective ${summary.objective_cost_m} metre-equivalent units, not energy.`))
      marker('polyline', { points: result.path.map(point => `${point.col + .5},${point.row + .5}`).join(' '), fill: 'none', stroke: '#fff', 'stroke-width': .12 })
      const list = el('ol', undefined, { id: 'terrain-route-steps' })
      for (const point of result.path) {
        const row = el('li'), button = el('button', `Step ${point.step}: [${point.row},${point.col}] x ${point.x_m}, y ${point.y_m} m; elevation ${point.elevation_m} m; distance ${point.distance_m} m; segment grade ${point.grade_deg ?? 'start'}°`, { type: 'button' })
        button.addEventListener('click', () => { if (active() && state.result === result) selectCell(point.row * bundle.cols + point.col) }); row.appendChild(button); list.appendChild(row)
      }
      resultView.appendChild(list)
    }
    resultView.appendChild(el('p', `Source ${bundle.source_digest}; frame ${bundle.coordinate_frame}; route ${result.route_digest}.`))
    resultView.appendChild(el('p', 'NODATA is excluded, never filled. Adjacent-center grade is not surface slope. No footprint, clearance, roughness, energy, illumination or rover safety is assessed. Source declarations remain unverified.'))
  }
  for (const [name, text] of [['start', 'Use selected cell as Start'], ['goal', 'Use selected cell as Goal']]) {
    const button = el('button', text, { id: 'terrain-route-' + name, type: 'button' })
    button.addEventListener('click', () => { if (!active()) return; state[name] = selected; state.result = null; refresh() }); section.appendChild(button)
  }
  for (const [key, title] of [['grade', 'Maximum adjacent-center grade (degrees)'], ['uphill', 'Uphill preference (dimensionless)']]) {
    const input = el('input', undefined, { id: 'terrain-route-' + key, type: 'number', min: '0', step: 'any' }); input.value = state[key]
    if (key === 'grade') input.setAttribute('max', '89.999999')
    const wrapper = el('label', title); wrapper.appendChild(input); section.appendChild(wrapper)
    input.addEventListener('input', () => { if (!active()) return; state[key] = input.value; state.result = null; refresh('Preferences changed. Calculate to inspect a new candidate.') })
  }
  const swap = el('button', 'Swap start and goal', { id: 'terrain-route-swap', type: 'button' }); section.appendChild(swap)
  swap.addEventListener('click', () => { if (!active()) return; [state.start, state.goal] = [state.goal, state.start]; state.result = null; refresh('Endpoints reversed. Recalculate because uphill preference is directional.') })
  const calculate = el('button', 'Calculate candidate route', { id: 'terrain-route-calculate', type: 'button' }); section.appendChild(calculate)
  calculate.addEventListener('click', () => { if (!active()) return; state.result = null; try { state.result = calculateTerrainRoute(bundle, state, route); refresh() } catch (error) { refresh(error.message + '. Source terrain and mission are unchanged.') } })
  const clear = el('button', 'Clear route selection', { id: 'terrain-route-clear', type: 'button' }); section.appendChild(clear)
  clear.addEventListener('click', () => { if (!active()) return; state.start = state.goal = null; state.result = null; refresh('Route selection cleared. Imported terrain remains available.') })
  section.appendChild(status); section.appendChild(resultView); refresh()
}
