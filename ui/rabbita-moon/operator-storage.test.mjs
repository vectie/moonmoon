import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { pathToFileURL } from 'node:url'
import vm from 'node:vm'
import test from 'node:test'

// DOM/WebGL fixtures only. Images, animation frames, and network never run.
// Run: node --experimental-vm-modules --test operator-storage.test.mjs
const base = process.env.MOONMOON_UI_ROOT
  ? pathToFileURL(`${process.env.MOONMOON_UI_ROOT}/`)
  : new URL('./', import.meta.url)

class Element {
  constructor(dataset = {}) {
    this.dataset = dataset
    this.attributes = {}
    this.events = new Map()
    this.classes = new Set()
    this.classList = {
      add: (...names) => names.forEach(name => this.classes.add(name)),
      remove: (...names) => names.forEach(name => this.classes.delete(name)),
      toggle: (name, active) => active ? this.classes.add(name) : this.classes.delete(name),
    }
    this.style = {}
    this.textContent = ''
    this.value = ''
  }
  setAttribute(key, value) { this.attributes[key] = value }
  removeAttribute(key) { delete this.attributes[key] }
  addEventListener(name, callback) {
    const callbacks = this.events.get(name) || []
    callbacks.push(callback)
    this.events.set(name, callbacks)
  }
  fire(name, event = {}) {
    for (const callback of this.events.get(name) || []) {
      callback({ currentTarget: this, preventDefault() {}, ...event })
    }
  }
  focus() { this.focused = true }
  scrollIntoView() {}
  querySelector() { return null }
}

async function fixture(mode, stored = null) {
  const ids = new Map()
  const element = id => {
    const node = new Element()
    ids.set(id, node)
    return node
  }
  const root = new Element()
  const shell = new Element()
  shell.prepend = node => ids.set(node.id, node)
  const routes = ['mission-route', 'candidate-route'].map(routeId => new Element({ routeId }))
  const cells = ['cell-a', 'cell-b'].map(cellId => new Element({ cellId }))
  const links = ['operator', 'moonbook'].map(appPage => new Element({ appPage }))
  const topic = new Element({ moonbookTopic: 'routes' })
  const questionButton = new Element({ bookkeeperQuestion: 'blocked' })
  for (const id of [
    'operator-page', 'moonbook-page', 'moon-terrain-switch', 'operator-route-label',
    'operator-route-context', 'operator-cell-id', 'return-mission-route',
    'bookkeeper-form', 'bookkeeper-question', 'bookkeeper-answer', 'bookkeeper-clear',
    'bookkeeper-answer-title', 'bookkeeper-answer-kind', 'bookkeeper-answer-body',
    'bookkeeper-source-1', 'bookkeeper-source-2', 'bookkeeper-source-3',
    'moonbook-topic-title', 'moon-focus-site', 'moon-reset-view', 'moon-toggle-orbit',
    'moon-lighting-time-index', 'moon-lighting-mode', 'moonmoon-globe-3d',
  ]) element(id)
  ids.get('moonbook-page').querySelectorAll = selector => {
    if (selector === '[data-moonbook-topic]') return [topic]
    if (selector === '[data-bookkeeper-question]') return [questionButton]
    return []
  }
  const document = {
    body: new Element(),
    getElementById: id => ids.get(id) || null,
    createElement: () => new Element(),
    querySelector: selector => ({ '.operator-shell': root, '.moon-shell': shell })[selector] || null,
    querySelectorAll: selector => ({ '[data-route-id]': routes, '[data-cell-id]': cells, '[data-app-page]': links })[selector] || [],
  }
  const window = new Element()
  window.matchMedia = () => ({ matches: true })
  window.scrollTo = () => {}
  window.dispatchEvent = () => {}
  const location = { hash: '' }
  const history = {
    pushState: (_data, _title, hash) => { location.hash = hash },
    replaceState: (_data, _title, hash) => { location.hash = hash },
  }
  const values = new Map(stored === null ? [] : [['moonmoon.operatorState', stored]])
  const storage = {
    getItem(key) {
      if (mode === 'blocked-methods') throw new Error('SecurityError fixture')
      return values.get(key) ?? null
    },
    setItem(key, value) {
      if (mode !== 'working') throw new Error('QuotaExceededError fixture')
      values.set(key, value)
    },
  }
  const terrainSelections = []
  const context = vm.createContext({
    document, window, location, history, URL, TextEncoder,
    CustomEvent: class { constructor(name, init) { this.name = name; this.detail = init.detail } },
    Image: class {},
    requestAnimationFrame: () => 1,
    cancelAnimationFrame: () => {},
    fetch: () => { throw new Error('No network is permitted in this test') },
    __moonmoonTerrainController: {
      selectRoute: value => terrainSelections.push(['route', value]),
      selectCell: value => terrainSelections.push(['cell', value]),
    },
  })
  Object.defineProperty(context, 'sessionStorage', {
    get() {
      if (mode === 'blocked-property') throw new Error('SecurityError fixture')
      return storage
    },
  })
  const gl = new Proxy({}, { get: () => () => true })
  ids.get('moonmoon-globe-3d').getContext = () => gl
  const modules = new Map()
  const lucideNames = ['createIcons', 'Crosshair', 'Database', 'MapPinned', 'Pause', 'Play', 'RotateCcw', 'Route', 'SearchCheck', 'ShieldCheck', 'Undo2']
  const load = url => {
    if (modules.has(url)) return modules.get(url)
    // Cache construction before the first read resolves. The VM links the graph
    // recursively itself, including the existing study/authoring cycle.
    const pending = (async () => url === 'lucide'
      ? new vm.SyntheticModule(lucideNames, function () {
        for (const name of lucideNames) this.setExport(name, () => {})
      }, { context })
      : new vm.SourceTextModule(await readFile(new URL(url), 'utf8'), {
        context, identifier: url,
        initializeImportMeta: meta => { meta.url = url },
      }))()
    modules.set(url, pending)
    return pending
  }
  for (const entry of ['scene-shell.js', 'operator-ui.js']) {
    const module = await load(new URL(entry, base).href)
    if (module.status === 'unlinked') await module.link((specifier, parent) => load(specifier === 'lucide' ? 'lucide' : new URL(specifier, parent.identifier).href))
    await module.evaluate()
  }
  const view = {
    selected_route_id: 'mission-route', selected_cell_id: 'cell-a',
    routes: ['mission-route', 'candidate-route'].map(route_id => ({ route_id, label: route_id, decision: 'blocked' })),
    terrain_cells: ['cell-a', 'cell-b'].map(cell_id => ({ cell_id, hazard: 'review' })),
    scorecard: { decision: 'blocked', next_action: 'Review fixture evidence' },
    lighting: { samples: [{ timestamp_utc: 'fixture-time', sun_altitude_deg: 3, earth_illuminated_fraction: 0.5 }] },
  }
  const answer = { state: 'is-answered', kind: 'Fixture', title: 'Fixture answer', body: 'Local registry answer', sources: ['fixture-source'] }
  const registry = { blocked: { en_us: answer }, unknown: { en_us: answer } }
  // Follow the actual startup ordering: globe first, then operator bindings.
  context.__moonmoonRenderScene3d(JSON.stringify(view))
  context.__moonmoonBindOperatorUi(JSON.stringify(view), JSON.stringify(registry))
  return { context, root, ids, routes, cells, links, topic, questionButton, location, window, values, terrainSelections }
}

function assertInteractions(f) {
  assert.equal(f.root.dataset.inspectedRouteId, 'mission-route')
  assert.equal(f.ids.get('moonbook-page').dataset.bookkeeperBound, 'true')
  // Repeated setup must not add another handler or reset in-memory state.
  f.context.__moonmoonBindOperatorUi('not parsed on a repeat bind', '{}')
  assert.equal(f.routes[1].events.get('click').length, 1)
  f.routes[1].fire('click')
  assert.equal(f.root.dataset.inspectedRouteId, 'candidate-route')
  assert.equal(f.root.dataset.missionSelectedRouteId, 'mission-route')
  assert.equal(f.ids.get('operator-route-context').textContent, 'Inspecting candidate; mission selection unchanged')
  assert.equal(f.routes[1].attributes['aria-pressed'], 'true')
  f.cells[1].fire('click')
  assert.equal(f.root.dataset.selectedCellId, 'cell-b')
  assert.equal(f.ids.get('moon-terrain-switch').checked, true)
  f.links[1].fire('click')
  assert.equal(f.location.hash, '#moonbook')
  assert.equal(f.ids.get('moonbook-page').hidden, false)
  f.topic.fire('click')
  assert.equal(f.ids.get('moonbook-topic-title').textContent, 'Selected is not the same as inspected')
  f.questionButton.fire('click')
  assert.equal(f.ids.get('bookkeeper-answer-body').textContent, 'Local registry answer')
  f.ids.get('bookkeeper-question').value = 'Why is the mission blocked?'
  f.ids.get('bookkeeper-form').fire('submit')
  assert.equal(f.ids.get('bookkeeper-source-1').textContent, 'Source: fixture-source')
  f.ids.get('bookkeeper-clear').fire('click')
  assert.equal(f.ids.get('bookkeeper-question').value, '')
  assert.equal(f.ids.get('bookkeeper-source-1').hidden, true)
  f.location.hash = '#operator'
  f.window.fire('popstate')
  assert.equal(f.ids.get('operator-page').hidden, false)
  f.ids.get('return-mission-route').fire('click')
  assert.equal(f.root.dataset.inspectedRouteId, 'mission-route')
  f.ids.get('moon-reset-view').fire('click')
  assert.equal(f.ids.get('moon-terrain-switch').checked, false)
  f.ids.get('moon-focus-site').fire('click')
  assert.equal(f.ids.get('moon-terrain-switch').checked, true)
  f.ids.get('moon-lighting-mode').fire('click')
  assert.equal(f.ids.get('moonmoon-globe-3d').dataset.lightingMode, 'readable')
  f.ids.get('moon-lighting-time-index').fire('input')
  f.ids.get('moon-terrain-switch').fire('change')
  assert.deepEqual(f.terrainSelections.at(-1), ['route', 'mission-route'])
}

for (const mode of ['blocked-property', 'blocked-methods', 'quota-full', 'working']) {
  test(`globe and operator controls remain usable with ${mode} storage`, async () => {
    const f = await fixture(mode)
    assertInteractions(f)
    const notice = f.ids.get('moonmoon-persistence-notice')
    assert.equal(Boolean(notice), mode !== 'working')
    if (notice) {
      assert.equal(notice.attributes.role, 'status')
      assert.match(notice.textContent, /may not be restored after reload/)
    } else {
      assert.equal(JSON.parse(f.values.get('moonmoon.operatorState')).selectedCellId, 'cell-b')
      assert.equal(f.values.get('moonmoon.terrainView'), 'terrain')
    }
  })
}

test('valid stored inspection restores without changing mission authority', async () => {
  const f = await fixture('working', JSON.stringify({ inspectedRouteId: 'candidate-route', selectedCellId: 'cell-b' }))
  assert.equal(f.root.dataset.inspectedRouteId, 'candidate-route')
  assert.equal(f.root.dataset.selectedCellId, 'cell-b')
  assert.equal(f.root.dataset.missionSelectedRouteId, 'mission-route')
})

for (const stored of ['null', 'broken-json', 'false', '{"inspectedRouteId":"missing","selectedCellId":"missing"}']) {
  test(`invalid stored inspection falls back safely: ${stored}`, async () => {
    assertInteractions(await fixture('working', stored))
  })
}
