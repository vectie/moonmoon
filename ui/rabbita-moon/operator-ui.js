import {
  createIcons,
  Crosshair,
  Database,
  MapPinned,
  Pause,
  Play,
  RotateCcw,
  Route,
  SearchCheck,
  ShieldCheck,
  Undo2,
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

function bindPageNavigation() {
  const pages = {
    operator: document.getElementById('operator-page'),
    moonbook: document.getElementById('moonbook-page'),
  }
  const links = [...document.querySelectorAll('[data-app-page]')]
  if (!pages.operator || !pages.moonbook || links.length === 0) return

  const pageFromLocation = () => location.hash === '#moonbook' ? 'moonbook' : 'operator'
  const showPage = (pageName, scroll = true) => {
    const selected = pages[pageName] ? pageName : 'operator'
    for (const [name, page] of Object.entries(pages)) {
      page.hidden = name !== selected
    }
    for (const link of links) {
      const active = link.dataset.appPage === selected
      link.classList.toggle('active', active)
      if (active) link.setAttribute('aria-current', 'page')
      else link.removeAttribute('aria-current')
    }
    document.body.dataset.appPage = selected
    document.title = selected === 'moonbook'
      ? 'Moonbook & Guide · MoonMoon'
      : 'Lunar Operator · MoonMoon'
    if (scroll) window.scrollTo({ top: 0, behavior: 'instant' })
  }

  for (const link of links) {
    link.addEventListener('click', event => {
      event.preventDefault()
      const page = link.dataset.appPage
      const hash = page === 'moonbook' ? '#moonbook' : '#operator'
      if (location.hash !== hash) history.pushState({ moonmoonPage: page }, '', hash)
      showPage(page)
    })
  }
  window.addEventListener('popstate', () => showPage(pageFromLocation()))
  if (!location.hash) history.replaceState({ moonmoonPage: 'operator' }, '', '#operator')
  showPage(pageFromLocation(), false)
}

function bindMoonbook(view, registry) {
  const page = document.getElementById('moonbook-page')
  if (!page || page.dataset.bookkeeperBound === 'true') return
  page.dataset.bookkeeperBound = 'true'

  const selectedRoute = (view.routes || []).find(route => route.route_id === view.selected_route_id)
    || (view.routes || [])[0]
  const recommended = selectedRoute?.illumination?.recommended_window || {}
  const blockers = view.blockers || []
  const sourcePath = view.source_panel?.local_source_path || 'source unavailable'
  const horizonPath = selectedRoute?.illumination?.horizon_evidence_path || 'evidence unavailable'
  const projectSource = 'ui/rabbita-moon/main/moonbook.mbt'
  const isChinese = () => globalThis.MoonSuiteI18n?.locale?.() === 'zh-Hans'

  const topics = {
    mission: {
      kind: 'Mission guide',
      title: 'Why the mission is blocked',
      summary: `The current trusted-square decision is ${view.scorecard?.decision}. ${blockers.length} controlling blockers must be cleared before route motion can be authorized.`,
      action: view.scorecard?.next_action,
      authority: 'Mission gate; not a robot preview',
      source: sourcePath,
    },
    terrain: {
      kind: 'Moon facts',
      title: 'How to read trusted terrain',
      summary: `${view.terrain_cells?.length || 0} terrain cells carry elevation, slope, roughness, hazard, and confidence. Selecting a cell changes inspection only; it does not select a route.`,
      action: 'Choose a terrain cell, then compare its hazard and confidence with the route corridor.',
      authority: view.source_panel?.authority || 'NASA PDS Geosciences / LRO LOLA',
      source: sourcePath,
    },
    lighting: {
      kind: 'Moon and mission facts',
      title: 'How illumination gates a route',
      summary: `The ranked window for ${selectedRoute?.route_id} runs ${recommended.time_start_utc} to ${recommended.time_end_utc}, with ${compactNumber(recommended.terrain_available_energy_wh)} Wh available.`,
      action: 'Compare route sunlight, longest darkness, and minimum solar clearance before treating a window as viable.',
      authority: 'Mission-window evidence; candidate until every gate passes',
      source: horizonPath,
    },
    routes: {
      kind: 'Mission guide',
      title: 'Selected is not the same as inspected',
      summary: `${view.selected_route_id} is mission-selected. Inspecting another of the ${view.routes?.length || 0} measured corridors changes the evidence view but never changes mission authority.`,
      action: 'Use Compare route candidates, then return to the mission-selected route before handoff.',
      authority: 'Mission selection remains authoritative',
      source: 'src/ui/route_overlay.mbt',
    },
    motion: {
      kind: 'Project boundary',
      title: 'Robot motion cannot authorize a route',
      summary: 'The Noetix E1 scene is an explicit, non-authoritative adapter preview. It visualizes a gated handoff but cannot clear terrain, power, or illumination blockers.',
      action: 'Clear the mission evidence gates before exporting or executing a motion contract.',
      authority: 'Preview only; mission gate owns authorization',
      source: 'src/ui/motion_contract.mbt',
    },
    project: {
      kind: 'Project facts',
      title: 'Where the product logic lives',
      summary: 'MoonBit owns the domain and view model. Rabbita renders semantic UI. Small JavaScript adapters bind browser history, WebGL, and input events without replacing the MoonBit product model.',
      action: 'Change mission truth in MoonBit, render it through Rabbita, and keep adapters at the browser boundary.',
      authority: 'Repository architecture',
      source: projectSource,
    },
  }

  const setTopic = topicId => {
    const topic = topics[topicId] || topics.mission
    for (const button of page.querySelectorAll('[data-moonbook-topic]')) {
      const active = button.dataset.moonbookTopic === topicId
      button.classList.toggle('active', active)
      button.setAttribute('aria-pressed', String(active))
    }
    setText('moonbook-topic-kind', topic.kind)
    setText('moonbook-topic-title', topic.title)
    setText('moonbook-topic-summary', topic.summary)
    setText('moonbook-topic-action', topic.action)
    setText('moonbook-topic-authority', topic.authority)
    setText('moonbook-topic-source', topic.source)
  }

  for (const button of page.querySelectorAll('[data-moonbook-topic]')) {
    button.addEventListener('click', () => setTopic(button.dataset.moonbookTopic))
  }

  const question = document.getElementById('bookkeeper-question')
  const answer = document.getElementById('bookkeeper-answer')
  const answerCategory = rawQuestion => {
    const normalized = rawQuestion.trim().toLowerCase()
    if (!normalized) return 'empty'
    if (/(block|why.*mission|任务.*阻|为什么.*任务)/.test(normalized)) {
      return 'blocked'
    }
    if (/(light|illumination|window|sun|光照|窗口|太阳)/.test(normalized)) {
      return 'window'
    }
    if (/(terrain|lola|elevation|slope|source|地形|高程|坡度|来源)/.test(normalized)) {
      return 'terrain_source'
    }
    if (/(robot|motion|authorize|authority|preview|机器人|运动|授权|权限|预览)/.test(normalized)) {
      return 'robot_authority'
    }
    if (/(moonbit|rabbita|project|architecture|code|项目|架构|代码)/.test(normalized)) {
      return 'project'
    }
    return 'unknown'
  }

  const answerFor = rawQuestion => {
    const category = answerCategory(rawQuestion)
    const locale = isChinese() ? 'zh_hans' : 'en_us'
    return registry?.[category]?.[locale] || registry?.unknown?.[locale]
  }

  const renderAnswer = result => {
    answer.classList.remove('is-empty', 'is-warning', 'is-answered', 'is-unknown')
    answer.classList.add(result.state)
    setText('bookkeeper-answer-kind', result.kind)
    setText('bookkeeper-answer-title', result.title)
    setText('bookkeeper-answer-body', result.body)
    for (let index = 0; index < 3; index += 1) {
      const item = document.getElementById(`bookkeeper-source-${index + 1}`)
      const value = result.sources[index]
      if (item) {
        item.hidden = !value
        item.textContent = value ? `Source: ${value}` : ''
      }
    }
  }

  const ask = value => {
    const nextQuestion = value ?? question?.value ?? ''
    if (question && value != null) question.value = value
    renderAnswer(answerFor(nextQuestion))
  }
  const canonicalQuestions = {
    blocked: 'Why is the mission blocked?',
    window: 'What is the best illumination window?',
    'terrain-source': 'Where does terrain data come from?',
    'robot-authority': 'Can robot motion authorize a route?',
  }
  for (const button of page.querySelectorAll('[data-bookkeeper-question]')) {
    button.addEventListener('click', () => ask(canonicalQuestions[button.dataset.bookkeeperQuestion]))
  }
  document.getElementById('bookkeeper-form')?.addEventListener('submit', event => {
    event.preventDefault()
    ask()
  })
  document.getElementById('bookkeeper-clear')?.addEventListener('click', () => {
    if (question) question.value = ''
    answer.className = 'bookkeeper-answer is-empty'
    setText('bookkeeper-answer-kind', isChinese() ? '就绪' : 'Ready')
    setText('bookkeeper-answer-title', isChinese() ? '输入问题以开始' : 'Ask a question to begin')
    setText(
      'bookkeeper-answer-body',
      isChinese()
        ? '选择常见问题或自行输入。回答会区分月球事实与项目事实，并列出证据来源。'
        : 'Choose a common question or write your own. Answers distinguish Moon facts from project facts and cite their evidence.',
    )
    for (let index = 1; index <= 3; index += 1) {
      const item = document.getElementById(`bookkeeper-source-${index}`)
      if (item) {
        item.hidden = true
        item.textContent = ''
      }
    }
    question?.focus()
  })
}

globalThis.__moonmoonBindOperatorUi = (modelJson, bookkeeperJson) => {
  const root = document.querySelector('.operator-shell')
  if (!root || root.dataset.operatorBound === 'true') return
  root.dataset.operatorBound = 'true'

  createIcons({
    icons: {
      Crosshair,
      Database,
      MapPinned,
      Pause,
      Play,
      RotateCcw,
      Route,
      SearchCheck,
      ShieldCheck,
      Undo2,
    },
    attrs: { 'aria-hidden': 'true', 'stroke-width': 1.5 },
  })

  const view = JSON.parse(modelJson)
  const bookkeeperRegistry = JSON.parse(bookkeeperJson)
  const routes = new Map((view.routes || []).map(route => [route.route_id, route]))
  const cells = new Map((view.terrain_cells || []).map(cell => [cell.cell_id, cell]))
  const routeButtons = [...document.querySelectorAll('[data-route-id]')]
  const cellButtons = [...document.querySelectorAll('[data-cell-id]')]
  const terrainSwitch = document.getElementById('moon-terrain-switch')
  const evidenceHandoff = document.querySelector('.evidence-handoff')
  let storedState = {}
  try {
    storedState = JSON.parse(sessionStorage.getItem('moonmoon.operatorState') || '{}')
  } catch {
    storedState = {}
  }
  const state = {
    missionSelectedRouteId: view.selected_route_id,
    inspectedRouteId: routes.has(storedState.inspectedRouteId)
      ? storedState.inspectedRouteId
      : view.selected_route_id,
    selectedCellId: cells.has(storedState.selectedCellId)
      ? storedState.selectedCellId
      : view.selected_cell_id,
  }
  const persistState = () => sessionStorage.setItem(
    'moonmoon.operatorState',
    JSON.stringify({
      inspectedRouteId: state.inspectedRouteId,
      selectedCellId: state.selectedCellId,
    }),
  )

  function showTerrain() {
    if (terrainSwitch) {
      terrainSwitch.checked = true
      sessionStorage.setItem('moonmoon.terrainView', 'terrain')
    }
  }

  function selectRoute(routeId, revealTerrain = true) {
    const route = routes.get(routeId)
    if (!route) return
    state.inspectedRouteId = routeId
    persistState()
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
    persistState()
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
  document.getElementById('review-blocking-evidence')?.addEventListener('click', () => {
    if (!evidenceHandoff) return
    evidenceHandoff.open = true
    evidenceHandoff.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
    evidenceHandoff.querySelector('summary')?.focus()
  })
  document.getElementById('return-mission-route')?.addEventListener('click', () => {
    selectRoute(state.missionSelectedRouteId)
    document.getElementById('operator-route-label')?.focus?.()
  })

  selectRoute(state.inspectedRouteId, false)
  selectCell(state.selectedCellId, false)
  bindPageNavigation()
  bindMoonbook(view, bookkeeperRegistry)
  globalThis.MoonSuiteI18n?.translate?.(document.body)
  globalThis.__moonmoonOperatorUi = { state, selectRoute, selectCell }
}
