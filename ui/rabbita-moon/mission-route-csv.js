// Route exchange is draft input only, never an assessment or terrain import.
import { parseDraftCells } from './mission-draft-map.js'

export function readRouteCSV(text) {
  if (typeof text !== 'string' || text.length > 16384) throw new Error('Route CSV exceeds 16 KiB')
  const lines = text.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').trim().split('\n')
  if (lines.shift()?.trim() !== 'row,column') throw new Error('Use the exact CSV header row,column')
  return parseDraftCells(lines.join('\n'))
}

export function writeRouteCSV(text) {
  return 'row,column\n' + parseDraftCells(text).map(cell => cell.join(',')).join('\n') + '\n'
}

export function bindRouteCSV(document, host, { text, live, commit, terrain }) {
  const element = (tag, suffix, content) => {
    const node = document.createElement(tag); node.id = 'study-draft-map-csv-' + suffix
    if (content !== undefined) node.textContent = content
    host.appendChild(node); return node
  }
  element('p', 'help', 'Exchange a route CSV in this frozen terrain’s zero-based row,column indices. This file contains no source identity, frame, units or validation. Verify that it belongs to this terrain. Import stages a preview; only Apply changes the selected variant.')
  element('p', 'source', terrain.available ? `Target frozen source: ${terrain.source.artifact_ref} · ${terrain.source.digest}. ${terrain.cellSize} m/index. Known sample index bounds: rows ${terrain.bounds.minRow}–${terrain.bounds.maxRow}, columns ${terrain.bounds.minCol}–${terrain.bounds.maxCol}; gaps remain unknown.` : `Target terrain unavailable: ${terrain.reason}. CSV editing remains unvalidated.`)
  const input = element('input', 'file'); input.type = 'file'; input.accept = '.csv,text/csv'; input.setAttribute('aria-label', 'Stage route CSV file')
  const mode = element('select', 'mode'); mode.setAttribute('aria-label', 'Apply CSV route as replace or append')
  for (const [value, label] of [['replace', 'Replace selected route'], ['append', 'Append to selected route']]) {
    const option = document.createElement('option'); option.value = value; option.textContent = label; mode.appendChild(option)
  }
  mode.value = 'replace'
  const status = element('p', 'status', 'No route CSV staged.'); status.setAttribute('role', 'status')
  const preview = element('pre', 'preview')
  const apply = element('button', 'apply', 'Apply reviewed route CSV'); apply.type = 'button'; apply.disabled = true
  const download = element('button', 'export', 'Download selected route CSV'); download.type = 'button'
  let staged = null, request = 0
  let current
  try { current = parseDraftCells(text) } catch { download.disabled = true }
  function update() {
    if (!staged) return
    const append = mode.value === 'append', total = staged.length + (append ? current?.length || 0 : 0)
    const invalid = !['replace', 'append'].includes(mode.value) || (append && !current) || total > 256
    const missing = terrain.available ? staged.filter(([r,c]) => !terrain.byCell.has(`${r},${c}`)).length : null
    status.textContent = `${staged.length} imported occurrences; ${append ? 'append' : 'replace'} produces ${total} occurrences. ${missing === null ? 'Frozen terrain unavailable; coverage unknown.' : `${missing} imported occurrences lack an exact frozen terrain sample.`} ${invalid ? 'Cannot apply: append needs a valid current route and total must not exceed 256.' : 'Review every occurrence and the terrain identity, then apply. No mission has run.'}`
    preview.textContent = staged.map(([r,c], n) => `${n + 1}. ${r},${c}`).join('\n')
    apply.disabled = invalid
  }
  input.addEventListener('change', async () => {
    if (!live()) return
    const token = ++request; staged = null; apply.disabled = true; preview.textContent = ''
    const file = input.files?.[0]
    if (!file) { status.textContent = 'No route CSV staged.'; return }
    status.textContent = 'Reading route CSV for review…'
    try {
      if (!Number.isFinite(file.size) || file.size < 0 || file.size > 16384) throw new Error('Route CSV exceeds 16 KiB')
      const bytes = await file.text()
      if (!live() || token !== request) return
      staged = readRouteCSV(bytes); update()
    } catch (error) { if (live() && token === request) status.textContent = `CSV not staged: ${error.message}. Current route unchanged.` }
  })
  mode.addEventListener('change', () => { if (live()) update() })
  apply.addEventListener('click', () => {
    if (!live() || !staged || apply.disabled) return
    const cells = mode.value === 'append' ? [...current, ...staged] : staged
    commit(cells)
  })
  download.addEventListener('click', () => {
    if (!live() || download.disabled) return
    const url = URL.createObjectURL(new Blob([writeRouteCSV(text)], { type: 'text/csv;charset=utf-8' }))
    try {
      const link = document.createElement('a'); link.href = url; link.download = 'moonmoon-draft-route.csv'; link.click()
      status.textContent = 'Downloaded selected route indices only. Retain the full draft JSON separately for source identity and assumptions.'
    } finally { URL.revokeObjectURL(url) }
  })
}
