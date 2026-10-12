// Draft-only authoring. No results, inferred slopes, interpolation or execution.
import { terrainSamples, projectStudyCell } from './mission-study-map.js'
import { bindRouteCSV } from './mission-route-csv.js'

export function parseDraftCells(text) {
  const cells = text.trim().split('\n').map(line => line.split(',').map(part => {
    if (!/^\d+$/.test(part.trim())) throw new Error('Use nonnegative integer row,column pairs')
    return Number(part.trim())
  }))
  if (cells.length < 2 || cells.length > 256 || cells.some(cell => cell.length !== 2 || cell.some(n => !Number.isSafeInteger(n) || n > 1000000))) throw new Error('Route needs 2–256 nonnegative row,column pairs')
  return cells
}

export function draftTerrain(dossier, design) {
  try {
    const env = design.environment, sources = dossier.sources.filter(s => s.artifact_ref === env.terrain_source_path)
    if (sources.length !== 1) throw new Error('Exact frozen terrain source is missing or ambiguous')
    const { samples, byCell } = terrainSamples(sources[0])
    if (!Number.isFinite(env.cell_size_m) || env.cell_size_m <= 0) throw new Error('Invalid declared cell size')
    const rows = samples.map(s => s.row), cols = samples.map(s => s.col)
    const bounds = { minRow: Math.min(...rows), maxRow: Math.max(...rows), minCol: Math.min(...cols), maxCol: Math.max(...cols) }
    if (![...rows, ...cols, bounds.maxRow - bounds.minRow, bounds.maxCol - bounds.minCol].every(n => Number.isFinite(n * env.cell_size_m))) throw new Error('Declared extent overflows display metres')
    return { available: true, samples, byCell, bounds, cellSize: env.cell_size_m, source: sources[0] }
  } catch (error) { return { available: false, reason: error.message } }
}

// Rendering returns fresh callbacks bound to one selected variant and one text
// generation. Removed DOM callbacks cannot change newer or different inputs.
export function bindDraftRouteMap(document, { readText, writeText }) {
  const host = document.getElementById('study-draft-map')
  if (!host?.replaceChildren) return () => {}
  let generation = 0, identity = null, history = [], lastText = null
  const element = (tag, text) => { const node = document.createElement(tag); if (text !== undefined) node.textContent = text; return node }
  return function render(context) {
    const stamp = ++generation
    host.replaceChildren()
    if (!context) { identity = null; history = []; lastText = null; return }
    if (identity !== context.identity) { identity = context.identity; history = []; lastText = null }
    const text = readText()
    // Direct textarea edits have their own history, including unfinished text.
    if (lastText !== null && lastText !== text) { history.push(lastText); if (history.length > 64) history.shift() }
    lastText = text
    const live = () => stamp === generation && readText() === text
    const button = (id, title, action, disabled = false) => {
      const node = element('button', title); node.id = 'study-draft-map-' + id; node.type = 'button'; node.disabled = disabled
      node.addEventListener('click', () => { if (live() && !node.disabled) action() }); host.appendChild(node); return node
    }
    const commit = cells => { writeText(cells.map(cell => cell.join(',')).join('\n')) }
    host.appendChild(element('h3', 'Draft route on frozen terrain'))
    host.appendChild(element('p', 'Unsaved selected variant only. Lines show authored order, not validated segments. No slopes, coverage, acceptance or physical readiness are calculated. Export or Run digital mission remains a separate explicit action.'))
    button('undo', 'Undo last route edit', () => {
      const previous = history.pop(); lastText = previous; writeText(previous)
    }, history.length === 0)
    bindRouteCSV(document, host, { text, live, commit, terrain: draftTerrain(context.dossier, context.design) })
    let cells
    try { cells = parseDraftCells(text) } catch (error) { host.appendChild(element('p', error.message + '. Correct the authoritative route textarea; no visual edit is applied.')); return }
    const route = element('select'); route.id = 'study-draft-map-route'; route.setAttribute('aria-label', 'Route occurrence to remove or reorder')
    for (const [n, cell] of cells.entries()) { const option = element('option', `${n + 1}. [${cell}]`); option.value = String(n); route.appendChild(option) }
    route.value = '0'; host.appendChild(route)
    const selected = () => { const n = Number(route.value); return Number.isInteger(n) && n >= 0 && n < cells.length ? n : -1 }
    button('remove', 'Remove selected occurrence', () => { const n = selected(); if (n < 0) return; commit(cells.filter((_, i) => i !== n)) }, cells.length <= 2)
    for (const [name, offset] of [['earlier', -1], ['later', 1]]) button(name, 'Move selected occurrence ' + name, () => {
      const n = selected(), next = n + offset; if (n < 0 || next < 0 || next >= cells.length) return
      const copy = cells.map(c => [...c]); [copy[n], copy[next]] = [copy[next], copy[n]]; commit(copy)
    })
    const model = draftTerrain(context.dossier, context.design)
    if (!model.available) { host.appendChild(element('p', 'Terrain map unavailable: ' + model.reason + '. Route textarea, occurrence controls and exact export remain available.')); return }
    host.appendChild(element('p', `Frozen source ${model.source.artifact_ref} · ${model.source.digest}. Row increases down, column right; ${model.cellSize} m/index. Gaps are unknown; no interpolation. ${context.dossier.site?.uncertainty || ''}`))
    const samples = element('select'); samples.id = 'study-draft-map-sample'; samples.setAttribute('aria-label', 'Exact frozen sample to append')
    const eligible = model.samples.filter(s => s.row >= 0 && s.col >= 0 && s.row <= 1000000 && s.col <= 1000000)
    for (const [n, s] of eligible.entries()) { const option = element('option', `[${s.row},${s.col}] · frozen elevation ${s.elevation} m`); option.value = String(n); samples.appendChild(option) }
    samples.value = '0'; host.appendChild(samples)
    const append = sample => { if (live() && cells.length < 256 && sample) commit([...cells, [sample.row, sample.col]]) }
    button('append', 'Append selected frozen cell', () => append(eligible[Number(samples.value)]), cells.length >= 256 || !eligible.length)
    const missing = cells.filter(([row, col]) => !model.byCell.has(`${row},${col}`))
    host.appendChild(element('p', `${cells.length} route occurrences; ${missing.length} without exact terrain samples. Repeated cells and segments remain distinct ordered occurrences. Native validation may reject disconnected or unsupported routes.`))
    if (!document.createElementNS) return
    const svg = (tag, attrs) => { const node = document.createElementNS('http://www.w3.org/2000/svg', tag); for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, String(v)); return node }
    // Include authored missing cells in the extent; never clamp them to terrain.
    const view = { ...model, bounds: { minRow: Math.min(model.bounds.minRow, ...cells.map(c => c[0])), maxRow: Math.max(model.bounds.maxRow, ...cells.map(c => c[0])), minCol: Math.min(model.bounds.minCol, ...cells.map(c => c[1])), maxCol: Math.max(model.bounds.maxCol, ...cells.map(c => c[1])) } }
    const canvas = svg('svg', { viewBox: '0 0 700 480', role: 'group', 'aria-label': 'Draft route; append exact samples with Enter or Space, or use the sample selector' })
    for (let n = 1; n < cells.length; n++) {
      const a = projectStudyCell(view, { row: cells[n - 1][0], col: cells[n - 1][1] }), b = projectStudyCell(view, { row: cells[n][0], col: cells[n][1] })
      canvas.appendChild(svg('line', { x1: a.x, y1: a.y, x2: b.x, y2: b.y, stroke: '#fbbf24', 'stroke-width': 3, 'stroke-dasharray': '6 4' }))
    }
    for (const sample of eligible) {
      const p = projectStudyCell(view, sample), label = `Append frozen cell [${sample.row},${sample.col}]`
      const dot = svg('circle', { cx: p.x, cy: p.y, r: 5, fill: '#67e8f9', tabindex: 0, role: 'button', 'aria-label': label, 'aria-disabled': cells.length >= 256 })
      const title = svg('title', {}); title.textContent = label; dot.appendChild(title)
      dot.addEventListener('click', () => append(sample))
      dot.addEventListener('keydown', event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); append(sample) } })
      canvas.appendChild(dot)
    }
    host.appendChild(canvas)
  }
}
