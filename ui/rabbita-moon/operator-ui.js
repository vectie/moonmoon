function setText(id, value) {
  const element = document.getElementById(id)
  if (element) element.textContent = String(value)
}

function statusClass(status) {
  if (status.includes('block') || status.includes('gated')) return 'is-blocked'
  if (status.includes('review') || status.includes('caution')) return 'is-review'
  return 'is-ready'
}

function setStatus(element, status) {
  if (!element) return
  element.classList.remove('is-blocked', 'is-review', 'is-ready')
  element.classList.add(statusClass(status))
  element.textContent = status
}

function compactNumber(value, digits = 3) {
  const number = Number(value)
  if (!Number.isFinite(number)) return String(value)
  return number.toFixed(digits).replace(/\.?0+$/, '')
}

globalThis.__moonmoonBindOperatorUi = modelJson => {
  const root = document.querySelector('.operator-shell')
  if (!root || root.dataset.operatorBound === 'true') return
  root.dataset.operatorBound = 'true'

  const view = JSON.parse(modelJson)
  const routes = new Map((view.routes || []).map(route => [route.route_id, route]))
  const cells = new Map((view.terrain_cells || []).map(cell => [cell.cell_id, cell]))
  const routeButtons = [...document.querySelectorAll('[data-route-id]')]
  const cellButtons = [...document.querySelectorAll('[data-cell-id]')]
  const terrainSwitch = document.getElementById('moon-terrain-switch')
  const state = {
    missionSelectedRouteId: view.selected_route_id,
    inspectedRouteId: view.selected_route_id,
    selectedCellId: view.selected_cell_id,
  }

  function showTerrain() {
    if (terrainSwitch) terrainSwitch.checked = true
  }

  function selectRoute(routeId, revealTerrain = true) {
    const route = routes.get(routeId)
    if (!route) return
    state.inspectedRouteId = routeId
    root.dataset.inspectedRouteId = routeId
    root.dataset.missionSelectedRouteId = state.missionSelectedRouteId
    for (const button of routeButtons) {
      const active = button.dataset.routeId === routeId
      button.classList.toggle('active', active)
      button.setAttribute('aria-pressed', String(active))
    }
    setText(
      'operator-route-context',
      routeId === state.missionSelectedRouteId
        ? 'Mission selected route'
        : 'Inspecting candidate; mission selection unchanged',
    )
    setText('operator-route-label', route.label)
    setText('operator-route-id', route.route_id)
    setStatus(document.getElementById('operator-route-decision'), route.decision)
    setText('operator-route-score', route.score)
    setText('operator-route-grade', compactNumber(route.max_grade))
    setText('operator-route-roughness', `${compactNumber(route.roughness_m)} m`)
    setText('operator-route-action', route.next_action)
    globalThis.__moonmoonTerrainController?.selectRoute(routeId)
    if (revealTerrain) showTerrain()
  }

  function selectCell(cellId, revealTerrain = true) {
    const cell = cells.get(cellId)
    if (!cell) return
    state.selectedCellId = cellId
    root.dataset.selectedCellId = cellId
    for (const button of cellButtons) {
      const active = button.dataset.cellId === cellId
      button.classList.toggle('selected', active)
      button.setAttribute('aria-pressed', String(active))
    }
    setText('operator-cell-id', cell.cell_id)
    setText('operator-cell-hazard', cell.hazard)
    setText('operator-cell-elevation', `${compactNumber(cell.elevation_m)} m`)
    setText('operator-cell-slope', compactNumber(cell.slope_grade))
    setText('operator-cell-roughness', `${compactNumber(cell.roughness_m)} m`)
    setText('operator-cell-confidence', compactNumber(cell.confidence, 2))
    globalThis.__moonmoonTerrainController?.selectCell(cellId)
    if (revealTerrain) showTerrain()
  }

  for (const button of routeButtons) {
    button.addEventListener('click', () => selectRoute(button.dataset.routeId))
  }
  for (const button of cellButtons) {
    button.addEventListener('click', () => selectCell(button.dataset.cellId))
  }

  selectRoute(state.inspectedRouteId, false)
  selectCell(state.selectedCellId, false)
  globalThis.__moonmoonOperatorUi = { state, selectRoute, selectCell }
}
