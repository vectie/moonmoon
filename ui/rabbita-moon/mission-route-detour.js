// Sampled digital draft assistance only. No hazard, energy or simulation assessment.
const key = cell => cell.join(',')
const validCell = cell => Array.isArray(cell) && cell.length === 2 && cell.every(n => Number.isSafeInteger(n) && n >= 0 && n <= 1000000)

export function parseAvoidCells(text) {
  if (typeof text !== 'string' || text.length > 16384) throw new Error('Avoid list must be at most 16 KiB')
  if (!text.trim()) return []
  const cells = text.trim().split(/\r?\n/).map(line => {
    const parts = line.split(',').map(part => part.trim())
    if (parts.length !== 2 || parts.some(part => !/^\d+$/.test(part))) throw new Error('Avoid cells need nonnegative row,column pairs')
    return parts.map(Number)
  })
  if (cells.length > 256 || cells.some(cell => !validCell(cell))) throw new Error('Avoid list needs at most 256 valid cells')
  return cells
}

export function planRouteDetour(terrain, cells, from, to, avoid = [], constraint = { mode: 'unrestricted' }) {
  if (!terrain?.available) throw new Error('Exact frozen terrain is unavailable')
  if (!Array.isArray(cells) || cells.length < 2 || cells.length > 256 || cells.some(cell => !validCell(cell))) throw new Error('Correct the current route first')
  if (!Number.isInteger(from) || !Number.isInteger(to) || from < 0 || to >= cells.length || from >= to) throw new Error('Choose a start occurrence before the end occurrence')
  if (!Array.isArray(avoid) || avoid.length > 256 || avoid.some(cell => !validCell(cell))) throw new Error('Invalid avoid cells')
  if (!(terrain.byCell instanceof Map)) throw new Error('Exact frozen terrain samples are unavailable')
  if (terrain.byCell.size > 4096) throw new Error('Terrain exceeds the 4096-sample planner limit')
  if (!constraint || !['unrestricted', 'grade-limited'].includes(constraint.mode)) throw new Error('Choose unrestricted or grade-limited routing explicitly')
  const limited = constraint.mode === 'grade-limited'
  if (limited && (!Number.isFinite(constraint.maxAbsGrade) || constraint.maxAbsGrade < 0)) throw new Error('Maximum absolute sampled edge grade must be a finite nonnegative m/m value')
  if (!limited && constraint.maxAbsGrade !== undefined) throw new Error('Unrestricted routing cannot carry a grade bound')
  // Copy only the declared frozen inputs used by this proposal. No interpolated
  // sample or native feasibility result supplies an edge elevation.
  const elevations = new Map()
  if (limited) {
    if (!Number.isFinite(terrain.cellSize) || terrain.cellSize <= 0) throw new Error('Grade-limited routing needs a finite positive declared cell size')
    for (const [id, sample] of terrain.byCell) {
      if (!Number.isFinite(sample?.elevation)) throw new Error('Grade-limited routing needs finite frozen sample elevations')
      elevations.set(id, sample.elevation)
    }
  }
  const edgeGrade = (a, b) => {
    const delta = Math.abs(elevations.get(b) - elevations.get(a)), grade = delta / terrain.cellSize
    if (!Number.isFinite(grade) || (delta > 0 && grade === 0)) throw new Error('Sampled edge grade arithmetic is outside the finite supported range')
    return grade
  }
  const blocked = new Set(avoid.map(key)), start = key(cells[from]), end = key(cells[to])
  if (start === end) throw new Error('Choose endpoints at different cells; closed loops are not rewritten')
  if (blocked.has(start) || blocked.has(end)) throw new Error('An endpoint is in the avoid list; choose different endpoints')
  if (!terrain.byCell.has(start) || !terrain.byCell.has(end)) throw new Error('Both endpoints need exact frozen samples')
  // Breadth-first search minimizes index steps. Fixed neighbor order makes ties
  // reproducible; sparse holes and excluded cells never become graph vertices.
  const queue = [cells[from]], previous = new Map([[start, null]])
  for (let head = 0; head < queue.length && !previous.has(end); head++) {
    const [row, col] = queue[head]
    for (const next of [[row - 1, col], [row, col - 1], [row, col + 1], [row + 1, col]]) {
      const id = key(next)
      if (!validCell(next) || previous.has(id) || blocked.has(id) || !terrain.byCell.has(id)) continue
      if (limited && edgeGrade(key(queue[head]), id) > constraint.maxAbsGrade) continue
      previous.set(id, key(queue[head])); queue.push(next)
    }
  }
  if (!previous.has(end)) throw new Error('No four-neighbor path through known samples meets the avoid list' + (limited ? ' and sampled edge grade bound' : '') + '; no gap was filled')
  const path = []
  for (let id = end; id !== null; id = previous.get(id)) path.push(id.split(',').map(Number))
  path.reverse()
  const route = [...cells.slice(0, from), ...path, ...cells.slice(to + 1)].map(cell => [...cell])
  if (route.length > 256) throw new Error('Detour would exceed the 256-occurrence route limit')
  const gradeConstraint = limited ? { mode: 'grade-limited', maxAbsGrade: constraint.maxAbsGrade, cellSize: terrain.cellSize, peakAbsGrade: Math.max(...path.slice(1).map((cell, i) => edgeGrade(key(path[i]), key(cell)))) } : { mode: 'unrestricted' }
  return { route, path, constraint: gradeConstraint, replaced: to - from + 1, unchanged: JSON.stringify(route) === JSON.stringify(cells), outsideAvoid: route.filter((cell, n) => (n < from || n >= from + path.length) && blocked.has(key(cell))).length }
}

export function bindRouteDetour(document, host, { cells, terrain, live, commit }) {
  const element = (tag, suffix, text) => {
    const node = document.createElement(tag); node.id = 'study-draft-map-detour-' + suffix
    if (text !== undefined) node.textContent = text
    host.appendChild(node); return node
  }
  element('h4', 'title', 'Plan a known-cell detour')
  element('p', 'help', 'Replace a route span with the fewest eligible four-neighbor index steps on this frozen source. Optional sampled edge grade is |elevation difference| / declared cell size, in m/m (0.1 means 10%). It applies only to the replacement span, including its endpoints. Intermediate waypoints in the span are replaced; prefix and suffix stay exact and are not assessed. Avoid cells are designer exclusions, not verified hazards. This digital sampled constraint does not assess terrain between samples, roughness, energy, robot limits or physical feasibility. Run digital mission separately.')
  const from = element('select', 'from'), to = element('select', 'to')
  for (const [control, label] of [[from, 'Detour start occurrence'], [to, 'Detour end occurrence']]) {
    control.setAttribute('aria-label', label)
    cells.forEach((cell, index) => { const option = document.createElement('option'); option.value = String(index); option.textContent = `${index + 1}. [${cell}]`; control.appendChild(option) })
  }
  from.value = '0'; to.value = String(cells.length - 1)
  const mode = element('select', 'mode'); mode.setAttribute('aria-label', 'Detour sampled edge grade mode')
  for (const [value, label] of [['unrestricted', 'Unrestricted sampled edge grade'], ['grade-limited', 'Limit maximum absolute sampled edge grade']]) {
    const option = document.createElement('option'); option.value = value; option.textContent = label; mode.appendChild(option)
  }
  mode.value = 'unrestricted'
  const bound = element('input', 'grade'); bound.type = 'number'; bound.min = '0'; bound.step = 'any'; bound.value = ''; bound.disabled = true
  bound.setAttribute('aria-label', 'Maximum absolute sampled edge grade in m/m'); bound.placeholder = 'Required in limited mode, e.g. 0.1'
  const avoid = element('textarea', 'avoid'); avoid.value = ''; avoid.setAttribute('aria-label', 'Cells to avoid, one row,column pair per line'); avoid.placeholder = 'Optional: row,column per line'
  const status = element('p', 'status', terrain.available ? `Frozen source: ${terrain.source.artifact_ref} · ${terrain.source.digest}. Choose endpoints and exclusions, then preview.` : 'Planner unavailable: ' + terrain.reason)
  status.setAttribute('role', 'status'); status.setAttribute('aria-live', 'polite')
  const preview = element('pre', 'preview')
  const plan = element('button', 'plan', 'Preview detour'); plan.type = 'button'; plan.disabled = !terrain.available
  const apply = element('button', 'apply', 'Apply previewed span'); apply.type = 'button'; apply.disabled = true
  const cancel = element('button', 'cancel', 'Clear detour preview'); cancel.type = 'button'
  let staged = null, stamp = null
  const inputs = () => JSON.stringify([from.value, to.value, avoid.value, mode.value, bound.value])
  const clear = message => { staged = null; stamp = null; apply.disabled = true; preview.textContent = ''; status.textContent = message }
  for (const control of [from, to, avoid, mode, bound]) for (const event of ['input', 'change']) control.addEventListener(event, () => { if (live()) { bound.disabled = mode.value !== 'grade-limited'; clear('Planner inputs changed; preview again. Current route unchanged.') } })
  cancel.addEventListener('click', () => { if (live()) clear('Preview cleared. Current route unchanged.') })
  plan.addEventListener('click', () => {
    if (!live() || plan.disabled) return
    clear('Planning…')
    try {
      if (!/^\d+$/.test(from.value) || !/^\d+$/.test(to.value)) throw new Error('Select valid endpoint occurrences')
      if (mode.value === 'grade-limited' && !/^(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/.test(bound.value.trim())) throw new Error('Enter an explicit nonnegative maximum absolute sampled edge grade in m/m')
      const constraint = mode.value === 'grade-limited' ? { mode: mode.value, maxAbsGrade: Number(bound.value) } : { mode: mode.value }
      staged = planRouteDetour(terrain, cells, Number(from.value), Number(to.value), parseAvoidCells(avoid.value), constraint); stamp = inputs()
      preview.textContent = staged.path.map((cell, i) => `${i + 1}. ${cell.join(',')}`).join('\n')
      const gradeStatus = staged.constraint.mode === 'grade-limited' ? `Replacement span only: maximum absolute sampled edge grade ≤ ${staged.constraint.maxAbsGrade} m/m; proposed peak ${staged.constraint.peakAbsGrade} m/m; frozen cell size ${staged.constraint.cellSize} m.` : 'Unrestricted sampled edge grade; elevations do not constrain this proposal.'
      status.textContent = `${staged.replaced} span occurrences → ${staged.path.length}; ${staged.route.length} total. ${gradeStatus} ${staged.outsideAvoid} excluded occurrences remain outside this span. ${staged.unchanged ? 'Route already matches; no edit needed.' : 'Review the replacement, then apply. Original route is unchanged until Apply.'} This is an unvalidated geometric proposal; all native blockers remain unresolved. Planner mode and bound are temporary; export retains the applied route in the existing draft contract.`
      apply.disabled = staged.unchanged
    } catch (error) { clear('No detour staged: ' + error.message + '. Current route unchanged.') }
  })
  apply.addEventListener('click', () => {
    if (!live() || !staged || apply.disabled) return
    if (stamp !== inputs()) { clear('Planner inputs changed; preview again. Current route unchanged.'); return }
    const route = staged.route; staged = null; apply.disabled = true; commit(route)
  })
}
