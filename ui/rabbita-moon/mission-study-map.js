// Read-only presentation of already verified, frozen study evidence. No fetch,
// simulation, storage, authoring or geographic-coordinate conversion lives here.
export const STUDY_MAP_LIMITS = Object.freeze({ samples: 4096, routeCells: 256, alternatives: 8 })
const need = (ok, message) => { if (!ok) throw new Error(message) }
const integer = value => Number.isInteger(value) && value >= -2147483648 && value <= 2147483647
const cellKey = (row, col) => `${row},${col}`
const edgeKey = (from, to) => `${from.row},${from.col}>${to.row},${to.col}`
const numberText = /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/
const numeric = text => numberText.test(text) && Number.isFinite(Number(text))

export function terrainSamples(source) {
  need(source && typeof source.text === 'string', 'Exact frozen terrain source is missing')
  const lines = source.text.split(/\r?\n/)
  need(lines.shift().trim() === 'tile_id,row,col,elevation_m', 'Unsupported terrain CSV header; expected tile_id,row,col,elevation_m')
  const samples = [], byCell = new Map()
  for (const [index, line] of lines.entries()) {
    if (!line.trim()) continue
    need(samples.length < STUDY_MAP_LIMITS.samples, 'Terrain exceeds the 4096-sample map limit; no samples were truncated')
    const fields = line.split(',').map(value => value.trim())
    need(fields.length === 4 && fields[0] && !line.includes('"'), `Unsupported terrain CSV record on line ${index + 2}`)
    need(/^[+-]?\d+$/.test(fields[1]) && /^[+-]?\d+$/.test(fields[2]) && integer(Number(fields[1])) && integer(Number(fields[2])) && numeric(fields[3]), `Malformed or nonfinite terrain sample on line ${index + 2}`)
    const [row, col, elevation] = fields.slice(1).map(Number), key = cellKey(row, col)
    need(!byCell.has(key), `Ambiguous duplicate terrain cell [${row},${col}]; no sample was chosen`)
    const sample = { row, col, elevation, tile: fields[0] }
    byCell.set(key, sample); samples.push(sample)
  }
  need(samples.length > 0, 'Terrain CSV contains no samples')
  return { samples, byCell }
}

// This is a view model, not another integrity verifier. Its caller supplies only
// readStudy output. Missing/malformed map inputs cannot invalidate a study review.
export function studyRouteMap(study) {
  try {
    const alternatives = study.alternatives, site = study.dossier.site
    need(Array.isArray(alternatives) && alternatives.length > 0 && alternatives.length <= STUDY_MAP_LIMITS.alternatives, 'Map supports at most 8 alternatives')
    need(typeof site.frame === 'string' && site.frame.trim(), 'Declared site frame is missing')
    const environment = alternatives[0].design.environment, sourceRef = environment.terrain_source_path
    const sources = study.dossier.sources.filter(source => source.artifact_ref === sourceRef)
    need(sources.length === 1, 'Exact frozen terrain source is missing or ambiguous')
    const source = sources[0], { samples, byCell } = terrainSamples(source)
    const cellSize = environment.cell_size_m
    need(Number.isFinite(cellSize) && cellSize > 0, 'Map requires a finite positive declared cell_size_m')
    const routes = alternatives.map((item, index) => {
      const env = item.design.environment, cells = env.path_cells
      need(env.terrain_source_path === sourceRef && env.cell_size_m === cellSize, 'Map alternatives must share the exact frozen terrain and cell size')
      need(Array.isArray(cells) && cells.length >= 2 && cells.length <= STUDY_MAP_LIMITS.routeCells, `${item.session_id}: map requires 2–256 route cells; no route was truncated`)
      const points = cells.map((cell, ordinal) => {
        need(Array.isArray(cell) && cell.length === 2 && cell.every(integer), `${item.session_id}: malformed [row,column] at route cell ${ordinal + 1}`)
        const [row, col] = cell, sample = byCell.get(cellKey(row, col))
        return { row, col, ordinal, sample: sample || null }
      })
      const routeCounts = new Map(), evidence = new Map()
      for (let n = 1; n < points.length; n++) {
        const key = edgeKey(points[n - 1], points[n])
        routeCounts.set(key, (routeCounts.get(key) || 0) + 1)
      }
      const retained = item.result.segment_evidence
      const evidenceSupported = Array.isArray(retained) && retained.length <= STUDY_MAP_LIMITS.routeCells - 1
      if (evidenceSupported) for (const entry of retained) {
        if (!entry || ![entry.from_row, entry.from_col, entry.to_row, entry.to_col].every(integer)) continue
        const key = edgeKey({ row: entry.from_row, col: entry.from_col }, { row: entry.to_row, col: entry.to_col })
        if (!evidence.has(key)) evidence.set(key, [])
        evidence.get(key).push(entry)
      }
      const occurrences = new Map()
      const segments = points.slice(1).map((to, n) => {
        const from = points[n], key = edgeKey(from, to), entries = evidence.get(key) || []
        const occurrence = occurrences.get(key) || 0
        occurrences.set(key, occurrence + 1)
        // Native evidence omits missing/non-adjacent edges. Never zip by array
        // index, reuse one record for several traversals, or reverse an edge.
        const entry = entries.length === routeCounts.get(key) ? entries[occurrence] : null
        const valid = entry && ['elevation_delta_m', 'distance_m', 'slope_deg'].every(field => Number.isFinite(entry[field])) && typeof entry.accepted === 'boolean'
        const reason = !from.sample || !to.sample ? 'Exact terrain cell missing; coverage unknown'
          : !evidenceSupported ? 'Native segment evidence missing, unsupported or over limit'
            : entries.length !== routeCounts.get(key) ? 'Exact native segment evidence missing or ambiguous'
              : !valid ? 'Malformed or nonfinite native segment evidence' : ''
        return { from, to, ordinal: n, evidence: valid ? { ...entry } : null, status: reason ? 'unknown' : entry.accepted ? 'accepted' : 'rejected', reason }
      })
      return { session: item.session_id, routeId: item.result.route_id, result: item.result.result, index, points, segments }
    })
    const locations = [...samples, ...routes.flatMap(route => route.points)]
    need(locations.every(point => Number.isFinite(point.row * cellSize) && Number.isFinite(point.col * cellSize)), 'Declared coordinates overflow display metres')
    const rows = locations.map(point => point.row), cols = locations.map(point => point.col)
    const bounds = { minRow: Math.min(...rows), maxRow: Math.max(...rows), minCol: Math.min(...cols), maxCol: Math.max(...cols) }
    need(Number.isFinite((bounds.maxRow - bounds.minRow) * cellSize) && Number.isFinite((bounds.maxCol - bounds.minCol) * cellSize), 'Declared coordinate extent overflows display metres')
    return { available: true, frame: site.frame, coverage: site.coverage, uncertainty: site.uncertainty, cellSize, sourceRef, sourceDigest: source.digest, samples, routes, bounds }
  } catch (error) {
    return { available: false, reason: error.message }
  }
}

export function projectStudyCell(model, point) {
  const { minRow, maxRow, minCol, maxCol } = model.bounds
  const scale = Math.min(550 / Math.max(1, maxCol - minCol), 350 / Math.max(1, maxRow - minRow))
  return { x: 70 + (550 - (maxCol - minCol) * scale) / 2 + (point.col - minCol) * scale,
    y: 55 + (350 - (maxRow - minRow) * scale) / 2 + (point.row - minRow) * scale }
}

const colors = ['#67e8f9', '#f9a8d4', '#a5b4fc', '#fde047', '#6ee7b7', '#fdba74', '#d8b4fe', '#f8fafc']
const coordinates = (point, model) => `[${point.row},${point.col}] · column offset ${point.col * model.cellSize} m, row offset ${point.row * model.cellSize} m`
const cellDetail = (point, model) => `${coordinates(point, model)} · ${point.sample ? `exact elevation ${point.sample.elevation} m; tile ${point.sample.tile}` : 'UNKNOWN: exact terrain cell absent; no interpolation'}`
const segmentDetail = segment => `Segment ${segment.ordinal + 1}: [${segment.from.row},${segment.from.col}] → [${segment.to.row},${segment.to.col}] · ${segment.status === 'unknown' ? `UNKNOWN: ${segment.reason}` : `native ${segment.status}`}${segment.evidence ? ` · retained native slope ${segment.evidence.slope_deg} degrees; elevation delta ${segment.evidence.elevation_delta_m} m; distance ${segment.evidence.distance_m} m; accepted ${segment.evidence.accepted}` : '; slope, distance and acceptance unknown'}`

// View state belongs to one mounted panel and one dossier digest. No state is
// written to the dossier, the digital review, the draft, or browser storage.
export function bindStudyRouteMap(document) {
  const host = document.getElementById('study-route-map')
  if (!host?.replaceChildren) return () => {}
  let current = null
  const element = (tag, text) => { const node = document.createElement(tag); if (text !== undefined) node.textContent = text; return node }
  const attribute = (node, name, value) => node.setAttribute(name, String(value))
  const label = (text, input) => { const node = element('label', text); node.appendChild(input); return node }
  return study => {
    const identity = study?.envelope.dossier_digest || null
    if (current && current.identity === identity) return
    const state = { identity, selected: 0, overlay: false }
    current = state
    host.replaceChildren()
    host.appendChild(element('h3', 'Frozen study route map · read-only'))
    if (!study) { host.appendChild(element('p', 'Import or reopen a verified study to inspect its exact frozen route cells')); return }
    const model = studyRouteMap(study)
    if (!model.available) {
      host.appendChild(element('p', 'Map unavailable: ' + model.reason + '. Study comparison, review, save and exact export remain available'))
      return
    }
    host.appendChild(element('p', `${study.dossier.study_id} / ${study.dossier.revision} · ${identity}`))
    host.appendChild(element('p', `Declared frame: ${model.frame}. [row,column]; column increases right, row increases down. Offsets are indices × ${model.cellSize} m, relative to declared index zero, not latitude/longitude or a surveyed origin.`))
    host.appendChild(element('p', `Frozen terrain: ${model.sourceRef} · ${model.sourceDigest}. ${model.samples.length} exact samples; gaps and outside coverage unknown. ${model.coverage}. ${model.uncertainty}`))
    host.appendChild(element('p', 'S/E mark route start/end. Solid lines: exact native segment evidence; dashed amber: unknown; red: native rejected segment. The selected route is drawn last. Overlaps retain their exact coordinates; select each session or use the full text listing to distinguish them. Dots are sample locations, not surveyed cell footprints.'))
    host.appendChild(element('p', 'Digital-only. Native acceptance and slopes are displayed unchanged, never recomputed. Whole-grid status, unmodeled hazards and physical readiness are not inferred from this map.'))
    const selection = element('select'); selection.id = 'study-map-session'
    for (const route of model.routes) { const option = element('option', `${route.index + 1}. ${route.session} · ${route.routeId}`); option.value = String(route.index); selection.appendChild(option) }
    selection.value = '0'
    const overlay = element('input'); overlay.type = 'checkbox'; overlay.id = 'study-map-overlay'
    host.appendChild(label('Session to inspect', selection)); host.appendChild(label('Overlay all alternatives on the same frozen source', overlay))
    const legend = element('p'); legend.id = 'study-map-legend'; host.appendChild(legend)
    const graphic = element('div'); graphic.className = 'study-route-graphic'; host.appendChild(graphic)
    const detailSelect = element('select'); detailSelect.id = 'study-map-detail-selection'
    host.appendChild(label('Inspect route cell or exact native segment (keyboard accessible)', detailSelect))
    const sampleSelect = element('select'); sampleSelect.id = 'study-map-sample-selection'
    const placeholder = element('option', 'Choose an exact frozen sample'); placeholder.value = ''; sampleSelect.appendChild(placeholder)
    for (const [index, sample] of model.samples.entries()) { const option = element('option', `[${sample.row},${sample.col}] · ${sample.elevation} m`); option.value = String(index); sampleSelect.appendChild(option) }
    sampleSelect.value = ''
    host.appendChild(label('Inspect any frozen terrain sample (keyboard accessible)', sampleSelect))
    const detail = element('p'); detail.id = 'study-map-detail'; attribute(detail, 'role', 'status'); attribute(detail, 'aria-live', 'polite'); host.appendChild(detail)
    const listing = element('details'); listing.appendChild(element('summary', 'Full selected route text: all cells and native segments'))
    const list = element('ol'); list.id = 'study-map-list'; listing.appendChild(list); host.appendChild(listing)
    const live = () => current === state
    const inspectRoute = value => {
      if (!live()) return
      const route = model.routes[state.selected], [kind, raw] = value.split(':'), n = Number(raw)
      if (!Number.isInteger(n) || n < 0) return
      const point = route.points[n], segment = route.segments[n]
      if (kind === 'cell' && point) detail.textContent = `${route.session} · Cell ${n + 1}${n === 0 ? ' START' : ''}${n === route.points.length - 1 ? ' END' : ''}: ${cellDetail(point, model)}`
      else if (kind === 'segment' && segment) detail.textContent = `${route.session} · ${segmentDetail(segment)}`
      else return
      detailSelect.value = value; sampleSelect.value = ''
    }
    const inspectSample = n => {
      if (!live() || !Number.isInteger(n) || n < 0 || !model.samples[n]) return
      const sample = model.samples[n]
      detail.textContent = `Frozen terrain sample: ${cellDetail({ ...sample, sample }, model)}`
      sampleSelect.value = String(n)
    }
    const draw = () => {
      if (!live()) return
      const route = model.routes[state.selected]
      const visible = state.overlay ? [...model.routes.filter(item => item !== route), route] : [route]
      legend.textContent = visible.map(item => `${item.index + 1}. ${item.session}${item === route ? ' (selected)' : ''}: native mission ${item.result}; ${item.segments.filter(segment => segment.status === 'unknown').length} unknown segments`).join(' · ')
      detailSelect.replaceChildren(); list.replaceChildren(); sampleSelect.value = ''
      for (const [n, point] of route.points.entries()) {
        const name = `Cell ${n + 1}${n === 0 ? ' START' : ''}${n === route.points.length - 1 ? ' END' : ''}: ${cellDetail(point, model)}`
        const option = element('option', name); option.value = `cell:${n}`; detailSelect.appendChild(option)
        list.appendChild(element('li', name))
        if (route.segments[n]) {
          const text = segmentDetail(route.segments[n]), option = element('option', text); option.value = `segment:${n}`; detailSelect.appendChild(option)
          list.appendChild(element('li', text))
        }
      }
      inspectRoute('cell:0')
      graphic.replaceChildren()
      if (!document.createElementNS) { graphic.appendChild(element('p', 'SVG unavailable; complete cell and segment evidence is listed below')); return }
      const svg = (tag, attrs, text) => {
        const node = document.createElementNS('http://www.w3.org/2000/svg', tag)
        for (const [name, value] of Object.entries(attrs)) attribute(node, name, value)
        if (text !== undefined) node.textContent = text
        return node
      }
      const canvas = svg('svg', { viewBox: '0 0 700 480', role: 'group', 'aria-label': 'Frozen local row-column study map. All evidence is also available in the keyboard-accessible selectors and full text listing.' })
      canvas.appendChild(svg('rect', { x: 35, y: 25, width: 630, height: 410, fill: '#0f172a', stroke: '#64748b' }))
      canvas.appendChild(svg('text', { x: 45, y: 20, fill: '#cbd5e1' }, `row ↓ ${model.bounds.minRow} to ${model.bounds.maxRow}`))
      canvas.appendChild(svg('text', { x: 45, y: 460, fill: '#cbd5e1' }, `column → ${model.bounds.minCol} to ${model.bounds.maxCol} · ${model.cellSize} m / index`))
      for (const [n, sample] of model.samples.entries()) {
        const { x, y } = projectStudyCell(model, sample)
        const dot = svg('circle', { cx: x, cy: y, r: 3.5, fill: '#94a3b8' })
        dot.appendChild(svg('title', {}, `Frozen sample [${sample.row},${sample.col}]: ${sample.elevation} m`))
        dot.addEventListener('click', () => inspectSample(n)); canvas.appendChild(dot)
      }
      for (const item of visible) {
        const selected = item === route, color = colors[item.index]
        for (const segment of item.segments) {
          const from = projectStudyCell(model, segment.from), to = projectStudyCell(model, segment.to)
          const line = svg('line', { x1: from.x, y1: from.y, x2: to.x, y2: to.y,
            stroke: segment.status === 'unknown' ? '#fbbf24' : segment.status === 'rejected' ? '#f87171' : color,
            'stroke-width': selected ? 5 : 9, opacity: selected ? 1 : 0.4,
            'stroke-dasharray': segment.status === 'unknown' ? '7 5' : 'none' })
          line.appendChild(svg('title', {}, `${item.session} · ${segmentDetail(segment)}`))
          if (selected) {
            attribute(line, 'tabindex', 0); attribute(line, 'role', 'button'); attribute(line, 'aria-label', segmentDetail(segment))
            const inspect = () => inspectRoute(`segment:${segment.ordinal}`)
            line.addEventListener('click', inspect); line.addEventListener('focus', inspect)
            line.addEventListener('keydown', event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); inspect() } })
          }
          canvas.appendChild(line)
        }
        for (const point of item.points) {
          const { x, y } = projectStudyCell(model, point), n = point.ordinal
          const dot = svg('circle', { cx: x, cy: y, r: selected ? 6 : 8, fill: point.sample ? color : '#0f172a', stroke: point.sample ? color : '#fbbf24', 'stroke-width': 2, 'stroke-dasharray': point.sample ? 'none' : '2 2', opacity: selected ? 1 : 0.5 })
          const name = `${item.session} · Cell ${n + 1}: ${cellDetail(point, model)}`
          dot.appendChild(svg('title', {}, name))
          if (selected) {
            attribute(dot, 'tabindex', 0); attribute(dot, 'role', 'button'); attribute(dot, 'aria-label', name)
            const inspect = () => inspectRoute(`cell:${n}`)
            dot.addEventListener('click', inspect); dot.addEventListener('focus', inspect)
            dot.addEventListener('keydown', event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); inspect() } })
          }
          canvas.appendChild(dot)
          if (n === 0 || n === item.points.length - 1) canvas.appendChild(svg('text', { x: x + 10, y: y + (n === 0 ? -10 : 18) + (selected ? 0 : 12), fill: color }, `${n === 0 ? 'S' : 'E'}${item.index + 1}`))
        }
      }
      graphic.appendChild(canvas)
    }
    selection.addEventListener('change', () => { const n = Number(selection.value); if (live() && Number.isInteger(n) && model.routes[n]) { state.selected = n; draw() } })
    overlay.addEventListener('change', () => { if (live()) { state.overlay = overlay.checked; draw() } })
    detailSelect.addEventListener('change', () => inspectRoute(detailSelect.value))
    sampleSelect.addEventListener('change', () => { if (sampleSelect.value !== '') inspectSample(Number(sampleSelect.value)) })
    draw()
  }
}
