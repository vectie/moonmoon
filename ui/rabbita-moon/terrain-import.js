// File/DOM adapter only. Raster parsing, coordinates, CSV and digests come from
// the compiled MoonBit terrain_import package, shared with the native CLI.
import { analysisState, exampleAnalysisAscii, renderTerrainAnalysis } from './terrain-analysis.js'
export const exampleAscii = 'ncols 4\nnrows 3\nxllcorner 100\nyllcorner -50\ncellsize 20\nNODATA_value -9999\n11 12 -9999 14\n10 11 12 13\n9 10 11 -9999\n'
const need = (value, message) => { if (!value) throw new Error(message) }

export function bindTerrainImport(document, convert, reopen, analyze) {
  const get = name => document.getElementById('terrain-import-' + name)
  if (!get('open') || get('open').dataset.bound) return
  get('open').dataset.bound = 'true'
  let bundle = null, selected = 0, generation = 0, displayGeneration = 0, busy = false
  let analysis = analysisState()
  const status = text => { get('status').textContent = text }
  const element = (tag, text, attrs = {}) => {
    const node = document.createElement(tag)
    if (text !== undefined) node.textContent = text
    for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, value)
    return node
  }
  const parse = (text, tile, frame, unit, note) => {
    const result = JSON.parse(convert(text, tile, frame, unit, note))
    need(result.ok, result.error || 'Terrain import failed')
    return result.bundle
  }
  const metadata = () => [get('tile').value.trim(), get('frame').value.trim(), get('unit').value, get('note').value.trim()]
  const download = (text, filename, type) => {
    const url = URL.createObjectURL(new Blob([text], { type }))
    const link = element('a'); link.href = url; link.download = filename; link.click()
    URL.revokeObjectURL(url)
  }
  const render = () => {
    const output = get('results'), current = ++displayGeneration
    output.replaceChildren()
    if (!bundle) return
    const active = bundle
    const select = index => {
      if (current !== displayGeneration || bundle !== active || index < 0 || index >= bundle.samples.length) return
      selected = index; render()
    }
    output.appendChild(element('h3', `${bundle.tile_id}: ${bundle.rows} rows × ${bundle.cols} columns`))
    output.appendChild(element('p', `${bundle.sample_count} elevation values; ${bundle.nodata_count} NODATA cells remain unknown. Elevation range ${bundle.minimum_elevation_m ?? 'unknown'} to ${bundle.maximum_elevation_m ?? 'unknown'} m. NODATA ${bundle.nodata_value} (${bundle.nodata_declared ? 'declared' : 'format default'}).`))
    output.appendChild(element('p', `${bundle.coordinate_frame}; horizontal units ${bundle.horizontal_unit}. Lower-left ${bundle.origin_kind} origin (${bundle.origin_x}, ${bundle.origin_y}), cell size ${bundle.cell_size}. Row zero is the top row; coordinates below are cell centers. No reprojection.`))
    output.appendChild(element('p', bundle.source_note))
    output.appendChild(element('p', bundle.source_digest, { class: 'terrain-import-digest' }))
    const pickerLabel = element('label', 'Inspect a cell '), picker = element('select', undefined, { id: 'terrain-import-cell' })
    bundle.samples.forEach((sample, index) => {
      const option = element('option', `[${sample.row},${sample.col}] ${sample.elevation_m === null ? 'NODATA / unknown' : sample.elevation_m + ' m'}`)
      option.value = String(index); picker.appendChild(option)
    })
    picker.value = String(selected); picker.addEventListener('change', () => { select(Number(picker.value)); get('cell')?.focus() })
    pickerLabel.appendChild(picker); output.appendChild(pickerLabel)
    for (const [name, label, delta] of [['previous', 'Previous cell', -1], ['next', 'Next cell', 1]]) {
      const button = element('button', label, { type: 'button', id: 'terrain-import-' + name })
      button.disabled = selected + delta < 0 || selected + delta >= bundle.samples.length
      button.addEventListener('click', () => { select(selected + delta); get(name)?.focus() }); output.appendChild(button)
    }
    const sample = bundle.samples[selected]
    output.appendChild(element('p', `Cell [${sample.row},${sample.col}]: center x ${sample.x}, y ${sample.y} ${bundle.horizontal_unit}; elevation ${sample.elevation_m === null ? 'UNKNOWN (NODATA); omitted from terrain CSV' : sample.elevation_m + ' m'}.`, { id: 'terrain-import-detail', role: 'status', 'aria-live': 'polite' }))
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
    svg.setAttribute('viewBox', `0 0 ${bundle.cols} ${bundle.rows}`)
    svg.setAttribute('role', 'img'); svg.setAttribute('aria-label', 'Imported raster elevation preview. Gray cells are NODATA; use the cell selector for exact values.')
    svg.setAttribute('class', 'terrain-import-map')
    const range = bundle.maximum_elevation_m - bundle.minimum_elevation_m
    bundle.samples.forEach((cell, index) => {
      const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect')
      rect.setAttribute('x', String(cell.col)); rect.setAttribute('y', String(cell.row))
      rect.setAttribute('width', '1'); rect.setAttribute('height', '1')
      const level = range ? (cell.elevation_m - bundle.minimum_elevation_m) / range : 0.5
      rect.setAttribute('fill', cell.elevation_m === null ? '#666' : `hsl(${230 - level * 190} 65% ${35 + level * 20}%)`)
      rect.setAttribute('stroke', index === selected ? '#fff' : '#222'); rect.setAttribute('stroke-width', index === selected ? '0.12' : '0.025')
      rect.addEventListener('click', () => select(index)); svg.appendChild(rect)
      if (cell.elevation_m === null) {
        const cross = document.createElementNS('http://www.w3.org/2000/svg', 'path')
        cross.setAttribute('d', `M ${cell.col + 0.2} ${cell.row + 0.2} l .6 .6 M ${cell.col + 0.8} ${cell.row + 0.2} l -.6 .6`)
        cross.setAttribute('stroke', '#ddd'); cross.setAttribute('stroke-width', '0.06'); cross.setAttribute('pointer-events', 'none'); svg.appendChild(cross)
      }
    })
    output.appendChild(svg)
    output.appendChild(element('p', 'Low elevation: blue. High: orange. Gray ×: unknown. Colors are a relative display scale, not a slope or hazard assessment.'))
    const table = element('table'), caption = element('caption', `Exact values for selected row ${sample.row}`)
    table.appendChild(caption)
    const heading = element('tr')
    for (const label of ['Column', 'Center x', 'Center y', 'Elevation (m)']) heading.appendChild(element('th', label, { scope: 'col' }))
    table.appendChild(heading)
    for (const cell of bundle.samples.filter(cell => cell.row === sample.row)) {
      const row = element('tr')
      for (const value of [cell.col, cell.x, cell.y, cell.elevation_m ?? 'NODATA']) row.appendChild(element('td', String(value)))
      table.appendChild(row)
    }
    const scroll = element('div', undefined, { class: 'terrain-import-table' }); scroll.appendChild(table); output.appendChild(scroll)
    for (const [name, label, text, suffix, type] of [
      ['csv', 'Download sparse terrain CSV', bundle.terrain_csv, '.csv', 'text/csv'],
      ['bundle', 'Download source bundle (reopenable)', JSON.stringify(bundle, null, 2) + '\n', '-terrain-import.json', 'application/json'],
    ]) {
      const button = element('button', label, { type: 'button', id: 'terrain-import-' + name })
      button.addEventListener('click', () => {
        if (current !== displayGeneration || bundle !== active) return
        download(text, bundle.tile_id + suffix, type)
        status('Download prepared for the currently imported source. NODATA stays unknown. The mission study is unchanged.')
      })
      output.appendChild(button)
    }
    output.appendChild(element('p', 'CSV preserves source row/column indices and omits missing cells. Keep its companion bundle for coordinates, units, raw source and digests. Degree grids require a separate reviewed reprojection before use as metric mission terrain.'))
    renderTerrainAnalysis({ document, output, bundle, analyze, state: analysis, download, active: () => current === displayGeneration && bundle === active, selectCell: select, selected })
  }
  const adopt = next => { bundle = next; selected = 0; analysis = analysisState(); render(); status(`Imported ${bundle.sample_count} values and ${bundle.nodata_count} unknown cells. Ready to inspect and export; no mission inputs changed.`) }
  const run = action => async () => {
    if (busy) return
    busy = true
    try { await action() } catch (error) { status(error.message + (bundle ? ' Previous imported terrain remains available.' : '')) } finally { busy = false }
  }
  for (const name of ['file', 'tile', 'frame', 'unit', 'note', 'metres']) get(name).addEventListener(name === 'file' || name === 'unit' || name === 'metres' ? 'change' : 'input', () => { generation++; status('Inputs changed. Choose Import and inspect terrain to apply them. Existing exports still describe the previously imported source.') })
  get('open').addEventListener('click', run(async () => {
    const file = get('file').files?.[0], stamp = generation
    const isBundle = file?.name?.toLowerCase().endsWith('.json')
    need(file && file.size <= (isBundle ? 4194304 : 1048576), 'Choose an ASCII grid up to 1 MiB or exported JSON up to 4 MiB')
    const text = await file.text()
    need(stamp === generation, 'Inputs changed during file read; retry')
    if (isBundle) {
      const checked = JSON.parse(reopen(text))
      need(checked.ok, checked.error || 'Terrain bundle could not be reopened')
      const next = checked.bundle
      get('tile').value = next.tile_id; get('frame').value = next.coordinate_frame; get('unit').value = next.horizontal_unit; get('note').value = next.source_note; get('metres').checked = true
      adopt(next)
    } else {
      need(get('metres').checked, 'Confirm that source elevations are already metres')
      adopt(parse(text, ...metadata()))
    }
  }))
  get('sample').addEventListener('click', () => {
    generation++
    const next = parse(exampleAnalysisAscii, 'synthetic-ridge', 'Synthetic local Cartesian frame; no surveyed lunar coordinates', 'm', 'Bundled synthetic ridge demonstration, Apache-2.0; not observed lunar terrain.')
    get('tile').value = next.tile_id; get('frame').value = next.coordinate_frame; get('unit').value = 'm'; get('note').value = next.source_note; get('metres').checked = true
    adopt(next)
  })
  get('clear').addEventListener('click', () => { generation++; bundle = null; selected = 0; render(); status('Imported terrain cleared. The existing mission study is unchanged.') })
}

globalThis.__moonmoonBindTerrainImport = (convert, reopen, analyze) => bindTerrainImport(document, convert, reopen, analyze)
