// Authored index geometry only. A retraced route is not a simulated return.
export function planRouteReturn(cells, cellSize) {
  if (!Array.isArray(cells) || cells.length < 2 || cells.length > 256 || cells.some(cell => !Array.isArray(cell) || cell.length !== 2 || cell.some(n => !Number.isSafeInteger(n) || n < 0 || n > 1000000))) throw new Error('Correct the current route first: 2–256 nonnegative row,column pairs')
  if (cells.length * 2 - 1 > 256) throw new Error('Retraced return would exceed the 256-occurrence route limit; use at most 128 outbound occurrences')
  const outbound = cells.map(cell => [...cell])
  const returnLeg = cells.slice(0, -1).reverse().map(cell => [...cell])
  const route = [...outbound, ...returnLeg]
  let indexDistance = 0
  for (let i = 1; i < outbound.length; i++) indexDistance += Math.hypot(outbound[i][0] - outbound[i - 1][0], outbound[i][1] - outbound[i - 1][1])
  const estimate = indexDistance * cellSize
  const distanceM = Number.isFinite(cellSize) && cellSize > 0 && Number.isFinite(estimate * 2) && (indexDistance === 0 || estimate > 0) ? { outbound: estimate, return: estimate, total: estimate * 2 } : null
  return { route, returnLeg, distanceM }
}

export function bindRouteReturn(document, host, { cells, cellSize, live, commit }) {
  const element = (tag, suffix, text) => {
    const node = document.createElement(tag); node.id = 'study-draft-map-return-' + suffix
    if (text !== undefined) node.textContent = text
    host.appendChild(node); return node
  }
  element('h4', 'title', 'Author an out-and-back route')
  element('p', 'help', 'To keep the outbound alternative, duplicate the selected variant first using Duplicate variant. This action treats its entire current route as outbound and appends prior occurrences in reverse order, omitting only the duplicate turnaround occurrence. Existing repeated cells stay distinct. Preview and Apply affect only the selected draft. No energy, coverage, hazard or feasibility assessment is performed; run the digital mission separately.')
  const status = element('p', 'status', 'Preview the retraced return before applying it.')
  status.setAttribute('role', 'status'); status.setAttribute('aria-live', 'polite')
  const preview = element('pre', 'preview')
  const plan = element('button', 'plan', 'Preview retraced return'); plan.type = 'button'
  const apply = element('button', 'apply', 'Apply retraced return'); apply.type = 'button'; apply.disabled = true
  const cancel = element('button', 'cancel', 'Cancel return preview'); cancel.type = 'button'
  let staged = null
  const clear = message => { staged = null; apply.disabled = true; preview.textContent = ''; status.textContent = message }
  cancel.addEventListener('click', () => { if (live()) clear('Return preview canceled. Current route unchanged.') })
  plan.addEventListener('click', () => {
    if (!live()) return
    clear('Preparing authored return…')
    try {
      staged = planRouteReturn(cells, cellSize)
      preview.textContent = staged.returnLeg.map((cell, i) => `${cells.length + i + 1}. ${cell.join(',')}`).join('\n')
      const distance = staged.distanceM
      status.textContent = `${cells.length} outbound occurrences + ${staged.returnLeg.length} appended return occurrences = ${staged.route.length} total. ` + (distance ? `Authored straight-segment estimated distance: outbound ${distance.outbound} m; return ${distance.return} m; total ${distance.total} m, using declared cell size ${cellSize} m/index. ` : 'Authored estimated distance unavailable: no supported finite declared cell size. ') + 'Only the appended return is listed below. Terrain between samples, coverage and mission feasibility remain unassessed. Original route unchanged until Apply.'
      apply.disabled = false
    } catch (error) { clear('No return staged: ' + error.message + '. Current route unchanged.') }
  })
  apply.addEventListener('click', () => {
    if (!live() || !staged || apply.disabled) return
    const route = staged.route; clear('Return applied to the selected draft only.'); commit(route)
  })
}
