import test from 'node:test'
import assert from 'node:assert/strict'
import { analysisState, calculateAnalysis, profileRuns, renderTerrainAnalysis } from './terrain-analysis.js'

class Node {
  constructor(tag) { this.tag = tag; this.children = []; this.attributes = {}; this.listeners = {}; this.textContent = ''; this.value = '' }
  setAttribute(key, value) { this.attributes[key] = value }
  appendChild(node) { this.children.push(node); return node }
  replaceChildren(...nodes) { this.children = nodes }
  addEventListener(name, handler) { this.listeners[name] = handler }
  fire(name) { this.listeners[name]?.() }
  find(id) { return this.attributes.id === id ? this : this.children.map(c => c.find(id)).find(Boolean) }
  all(tag) { return [...(this.tag === tag ? [this] : []), ...this.children.flatMap(c => c.all(tag))] }
  text() { return this.textContent + this.children.map(c => c.text()).join(' ') }
}
const document = { createElement: tag => new Node(tag), createElementNS: (_, tag) => new Node(tag) }
const bundle = { rows: 1, cols: 4, horizontal_unit: 'm', tile_id: 'fixture' }
const result = () => ({
  parameters: { axis: 'row', index: 0, slope_threshold_deg: 15 },
  grid_summary: { estimated_cells: 0, unknown_cells: 4, threshold_exceeded_cells: 0 },
  profile_summary: { known_samples: 3, sample_count: 4, horizontal_span_m: 30, measured_segment_distance_m: 10, unknown_segments: 2, observed_ascent_m: 1, observed_descent_m: 0, complete_elevation_coverage: false },
  cells: [0, 1, 2, 3].map(col => ({ row: 0, col, estimate_status: 'boundary', slope_deg: null, roughness_rms_m: null, slope_screening: 'unknown' })),
  profile: [2, 3, null, 5].map((z, col) => ({ row: 0, col, distance_m: col * 10, elevation_m: z, segment_status: col === 0 ? 'start' : col === 1 ? 'measured' : 'unknown', rise_m: col === 1 ? 1 : null, grade_percent: col === 1 ? 10 : null, grade_deg: col === 1 ? 5.710593137499643 : null })),
  analysis_digest: 'sha256:fixture', profile_csv: 'profile fixture', cells_csv: 'cell fixture', report_markdown: 'readable fixture',
})

test('profile plot preserves isolated values and never connects a gap', () => {
  assert.deepEqual(profileRuns(result().profile).map(run => run.map(p => p.elevation_m)), [[2, 3], [5]])
  assert.deepEqual(profileRuns([{ elevation_m: null }]), [])
})

test('input validation precedes the shared numerical callback and does not change retained results', () => {
  const state = analysisState(); let called = 0
  const analyze = (...args) => { called++; assert.equal(args[1], 'row'); assert.equal(args[2], 0); return JSON.stringify({ ok: true, analysis: result() }) }
  assert.equal(calculateAnalysis(bundle, state, analyze).profile.length, 4)
  for (const [key, bad] of [['index', '0.5'], ['index', ''], ['index', '2'], ['threshold', '90'], ['threshold', 'NaN']]) {
    const changed = { ...state, [key]: bad }; assert.throws(() => calculateAnalysis(bundle, changed, analyze))
  }
  assert.equal(called, 1)
  assert.throws(() => calculateAnalysis(bundle, state, () => JSON.stringify({ ok: false, error: 'Metric frame required' })), /Metric frame required/)
})

test('calculate edit recalculate export and stale controls keep exact source result', () => {
  const output = new Node('div'), state = analysisState(), downloads = [], selections = []
  let active = true, called = 0
  const analyze = (text, axis, index, threshold) => {
    called++; assert.deepEqual(JSON.parse(text), bundle)
    const value = result(); value.parameters = { axis, index, slope_threshold_deg: threshold }
    return JSON.stringify({ ok: true, analysis: value })
  }
  renderTerrainAnalysis({ document, output, bundle, analyze, state, download: (...args) => downloads.push(args), active: () => active, selectCell: i => selections.push(i), selected: 0 })
  output.find('terrain-analysis-calculate').fire('click')
  assert.equal(called, 1)
  assert.match(output.text(), /partial coverage/)
  assert.match(output.text(), /Selected cell \[0,0\]: boundary/)
  assert.equal(output.all('polyline').length, 2)
  assert.equal(output.all('circle').length, 3)
  output.all('rect')[2].fire('click'); assert.deepEqual(selections, [2])
  const oldExport = output.find('terrain-analysis-profile-csv')
  oldExport.fire('click'); assert.equal(downloads[0][0], 'profile fixture')
  const threshold = output.find('terrain-analysis-threshold'); threshold.value = '30'; threshold.fire('input')
  assert.match(output.find('terrain-analysis-status').text(), /last calculation/)
  assert.equal(state.result.parameters.slope_threshold_deg, 15)
  output.find('terrain-analysis-calculate').fire('click')
  assert.equal(state.result.parameters.slope_threshold_deg, 30)
  oldExport.fire('click'); assert.equal(downloads.length, 1)
  threshold.value = '90'; threshold.fire('input'); output.find('terrain-analysis-calculate').fire('click')
  assert.match(output.find('terrain-analysis-status').text(), /Previous calculation remains/)
  assert.equal(state.result.parameters.slope_threshold_deg, 30)
  active = false
  output.find('terrain-analysis-evidence').fire('click')
  output.find('terrain-analysis-calculate').fire('click')
  assert.equal(downloads.length, 1); assert.equal(called, 2)
})

test('degree input keeps exploration available without presenting metric controls', () => {
  const output = new Node('div')
  renderTerrainAnalysis({ document, output, bundle: { ...bundle, horizontal_unit: 'degrees' } })
  assert.match(output.text(), /Reproject externally/)
  assert.equal(output.find('terrain-analysis-calculate'), undefined)
})
