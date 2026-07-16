import {
  createIcons,
  Crosshair,
  Pause,
  Play,
  RotateCcw,
} from 'lucide'

function setText(id, value) {
  const element = document.getElementById(id)
  if (element) element.textContent = String(value)
}

function statusClass(status) {
  const normalized = String(status).toLowerCase()
  if (normalized.includes('block') || normalized.includes('gated')) return 'is-blocked'
  if (normalized.includes('review') || normalized.includes('caution')) return 'is-review'
  return 'is-ready'
}

function setStatus(element, status) {
  if (!element) return
  element.classList.remove('is-blocked', 'is-review', 'is-ready')
  element.classList.add(statusClass(status))
  element.textContent = status
}

function setIlluminationStatus(element, status) {
  setStatus(element, status)
  if (!element) return
  const normalized = String(status).toLowerCase()
  element.textContent = normalized.includes('block')
    ? 'illumination block'
    : normalized.includes('review') || normalized.includes('caution')
      ? 'illumination review'
      : 'illumination pass'
}

function setCandidateStatus(element, status) {
  if (!element) return
  const blocked = String(status).toLowerCase().includes('block')
  element.classList.remove('is-blocked', 'is-review', 'is-ready')
  element.classList.add(blocked ? 'is-blocked' : 'is-review')
  element.textContent = blocked ? 'not viable' : 'candidate'
}

function compactNumber(value, digits = 3) {
  const number = Number(value)
  if (!Number.isFinite(number)) return String(value)
  return number.toFixed(digits).replace(/\.?0+$/, '')
}

function updateHorizonProfile(samples) {
  for (const sample of samples || []) {
    const angle = Number(sample.horizon_angle_deg)
    const level = Number.isFinite(angle)
      ? Math.max(0.06, Math.min(1, (angle + 30) / 60))
      : 0.06
    const bar = document.getElementById(`operator-horizon-bar-${sample.label}`)
    if (bar) {
      bar.style.height = `${level * 100}%`
      bar.classList.toggle('below-horizon', angle < 0)
    }
    setText(`operator-horizon-angle-${sample.label}`, compactNumber(angle, 1))
  }
}

globalThis.__moonmoonBindOperatorUi = modelJson => {
  const root = document.querySelector('.operator-shell')
  if (!root || root.dataset.operatorBound === 'true') return
  root.dataset.operatorBound = 'true'

  createIcons({
    icons: { Crosshair, Pause, Play, RotateCcw },
    attrs: { 'aria-hidden': 'true', 'stroke-width': 1.5 },
  })

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
    const illumination = route.illumination || {}
    setIlluminationStatus(
      document.getElementById('operator-illumination-status'),
      illumination.decision || 'blocked',
    )
    setText(
      'operator-illumination-window',
      `${illumination.time_start_utc || 'unknown'} to ${illumination.time_end_utc || 'unknown'}`,
    )
    setText(
      'operator-illumination-sunlit',
      `${compactNumber(illumination.terrain_sunlit_hours)} h`,
    )
    setText(
      'operator-illumination-dark',
      `${compactNumber(illumination.longest_dark_hours)} h`,
    )
    setText(
      'operator-illumination-energy',
      `${compactNumber(illumination.terrain_available_energy_wh)} Wh`,
    )
    setText(
      'operator-illumination-clearance',
      `${compactNumber(illumination.maximum_solar_clearance_deg)} deg`,
    )
    setText('operator-illumination-evidence', illumination.horizon_evidence_path || '')
    updateHorizonProfile(illumination.horizon_profile)
    const recommended = illumination.recommended_window || {}
    setCandidateStatus(
      document.getElementById('operator-window-status'),
      recommended.decision || 'review',
    )
    setText(
      'operator-window-range',
      `${recommended.time_start_utc || 'unknown'} to ${recommended.time_end_utc || 'unknown'}`,
    )
    setText(
      'operator-window-sunlit',
      `${compactNumber(recommended.terrain_sunlit_hours)} h`,
    )
    setText(
      'operator-window-dark',
      `${compactNumber(recommended.longest_dark_hours)} h`,
    )
    setText(
      'operator-window-energy',
      `${compactNumber(recommended.terrain_available_energy_wh)} Wh`,
    )
    setText(
      'operator-window-clearance',
      `${compactNumber(recommended.minimum_solar_clearance_deg)} deg`,
    )
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
