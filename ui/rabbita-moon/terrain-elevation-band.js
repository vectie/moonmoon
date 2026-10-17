// Exploratory cell selection on the already validated import. No interpolation,
// reprojection, slope calculation or mission feasibility is inferred here.
export const elevationBandState = () => ({ minimum: '', maximum: '' })
export function elevationBand(bundle, state) {
  const bound = value => {
    if (String(value).trim() === '') return null
    const number = Number(value)
    if (!Number.isFinite(number)) throw new Error('Use finite elevations in metres or leave a bound empty.')
    return number
  }
  const minimum = bound(state.minimum), maximum = bound(state.maximum)
  if (minimum !== null && maximum !== null && minimum > maximum) throw new Error('Minimum elevation must not exceed maximum.')
  const indices = [], unknown = []
  bundle.samples.forEach((cell, index) => {
    if (cell.elevation_m === null) unknown.push(index)
    else if ((minimum === null || cell.elevation_m >= minimum) && (maximum === null || cell.elevation_m <= maximum)) indices.push(index)
  })
  return { minimum, maximum, indices, unknown }
}
export function renderElevationBand({ document, output, bundle, state, active, selectCell, selected, mapCells }) {
  const element = (tag, text, attrs = {}) => { const node = document.createElement(tag); if (text !== undefined) node.textContent = text; for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, value); return node }
  const section = element('section', undefined, { 'aria-label': 'Elevation band exploration' })
  section.appendChild(element('h3', 'Explore an elevation band'))
  section.appendChild(element('p', 'Inclusive elevations in metres. Blank bounds include all known elevations. This selects measured/declarative values only; NODATA stays unknown. It does not identify safe terrain or alter a mission.'))
  for (const [key, label] of [['minimum', 'Minimum elevation (m)'], ['maximum', 'Maximum elevation (m)']]) {
    const id = 'terrain-band-' + key, input = element('input', undefined, { id, type: 'number', step: 'any' })
    input.value = state[key]; const wrapper = element('label', label, { for: id }); wrapper.appendChild(input); section.appendChild(wrapper)
    input.addEventListener('input', () => { if (!active()) return; state[key] = input.value; refresh() })
  }
  const status = element('p', undefined, { id: 'terrain-band-status', role: 'status', 'aria-live': 'polite' })
  section.appendChild(status)
  const previous = element('button', 'Previous matching cell', { id: 'terrain-band-previous', type: 'button' })
  const next = element('button', 'Next matching cell', { id: 'terrain-band-next', type: 'button' })
  section.appendChild(previous); section.appendChild(next)
  let matches = []
  function refresh() {
    try {
      const result = elevationBand(bundle, state); matches = result.indices
      const included = new Set(matches)
      mapCells.forEach((rect, index) => { rect.setAttribute('opacity', included.has(index) ? '1' : '0.3'); rect.setAttribute('data-elevation-band-match', String(included.has(index))) })
      const position = matches.indexOf(selected)
      status.textContent = `${matches.length} of ${bundle.samples.length - result.unknown.length} known cells match; ${result.unknown.length} unknown cells excluded. ${position < 0 ? 'Selected cell is outside this band or unknown.' : 'Selected match ' + (position + 1) + ' of ' + matches.length + '.'} Bright cells match; dim cells do not. Frame: ${bundle.coordinate_frame}; source ${bundle.source_digest}.`
      previous.disabled = !matches.some(index => index < selected)
      next.disabled = !matches.some(index => index > selected)
    } catch (error) {
      matches = []; previous.disabled = next.disabled = true
      mapCells.forEach(rect => { rect.setAttribute('opacity', '1'); rect.setAttribute('data-elevation-band-match', 'false') })
      status.textContent = error.message + ' No band is highlighted.'
    }
  }
  previous.addEventListener('click', () => { if (!active()) return; const index = matches.filter(index => index < selected).at(-1); if (index !== undefined) selectCell(index) })
  next.addEventListener('click', () => { if (!active()) return; const index = matches.find(index => index > selected); if (index !== undefined) selectCell(index) })
  output.appendChild(section); refresh()
}
