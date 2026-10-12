import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile } from 'node:fs/promises'
import { readStudy, StudyStore, STUDY_LIBRARY_LIMITS, bindMissionStudy } from './mission-study.js'

const fixtureText = await readFile(new URL('./fixtures/mission-study-local.json', import.meta.url), 'utf8')
const revisedText = await readFile(new URL('./fixtures/mission-study-revised.json', import.meta.url), 'utf8')
const fixture = await readStudy(fixtureText), revised = await readStudy(revisedText)
const key = 'moonmoon.study.v1/local-study/r1', secondKey = 'moonmoon.study.v1/local-study/r2'
const review = { dossierDigest: fixture.envelope.dossier_digest, reviewer: '<img src=x onerror=alert(1)>', choice: 'none', rationale: 'Keep digital evidence and negative energy visible', authority: 'digital-only' }
class Storage {
  values = new Map(); writes = []; reads = []; mode = ''; onRead = null
  get length() { if (this.mode === 'enumeration-denied') throw Error('Storage denied'); return this.values.size }
  key(index) { return [...this.values.keys()][index] ?? null }
  getItem(key) { this.reads.push(key); this.onRead?.(key); if (this.mode === 'read-denied') throw Error('Storage read denied'); return this.values.get(key) ?? null }
  setItem(key, value) { if (this.mode === 'quota') throw Error('Quota exceeded'); this.writes.push(['set', key]); this.values.set(key, value) }
  removeItem(key) { this.writes.push(['remove', key]); this.values.delete(key) }
}
async function saved() {
  const storage = new Storage(), store = new StudyStore(storage)
  await store.save(revised, null, null)
  await store.save(fixture, review, null)
  storage.writes = []; storage.reads = []
  return { storage, store }
}
class Element {
  constructor(tag = 'div') { this.tag = tag; this.id = ''; this.dataset = {}; this.value = ''; this.textContent = ''; this.events = new Map(); this.files = []; this.children = []; this.disabled = false }
  appendChild(child) { this.children.push(child); child.parentNode = this; return child }
  replaceChildren(...children) { this.children = children }
  addEventListener(name, fn) { this.events.set(name, [...(this.events.get(name) || []), fn]) }
  async fire(name) { if (name === 'click' && this.disabled) return; for (const fn of this.events.get(name) || []) await fn({ preventDefault() {} }) }
}
const descendants = node => [node, ...node.children.flatMap(descendants)]
function ui(storage) {
  const panel = new Element(); panel.id = 'mission-study-panel'
  for (const id of ['file','status','comparison','sensitivity-matrix','id','revision','reviewer','choice','rationale','reopen','discard','save','reconcile','export','export-session']) {
    const node = new Element(); node.id = 'study-' + id; panel.appendChild(node)
  }
  const document = { getElementById: id => descendants(panel).find(node => node.id === id), createElement: tag => new Element(tag) }
  const calls = []
  const runClient = new Proxy({}, { get: (_, name) => () => { calls.push(name); throw Error('No execution permitted') } })
  const bind = () => bindMissionStudy(document, () => storage, runClient)
  bind()
  const get = id => document.getElementById('study-' + id)
  return { document, panel, get, bind, calls,
    refresh: () => get('library-refresh').fire('click'),
    buttons: () => descendants(get('library-rows')).filter(node => node.tag === 'button'),
    text: () => descendants(get('library')).map(node => node.textContent).join('\n'),
    import: async text => { get('file').files = [{ size: Buffer.byteLength(text), text: async () => text }]; await get('file').fire('change') },
  }
}

test('catalogue discovers exact revisions in stable order without changing any stored bytes or reading unrelated values', async () => {
  const { storage, store } = await saved()
  storage.values.set('other.application.secret', 'never inspect this')
  const before = [...storage.values]
  const result = await store.catalogue()
  assert.deepEqual(result.entries.map(x => [x.id, x.revision, x.state]), [['local-study', 'r1', 'verified'], ['local-study', 'r2', 'verified']])
  assert.match(result.entries[0].message, /<img src=x onerror=alert\(1\)>/)
  assert.match(result.entries[1].message, /No named digital review/)
  assert.equal(result.truncated, false)
  assert.deepEqual(storage.writes, [])
  assert.deepEqual([...storage.values], before)
  assert.ok(!storage.reads.includes('other.application.secret'))
})

test('malformed evidence, mismatched identity, corrupt review and empty or orphan journals remain visible and unselectable', async () => {
  const { storage, store } = await saved()
  const raw = storage.values.get(key)
  storage.values.set(key + '/pending', '')
  storage.values.set('moonmoon.study.v1/orphan/r1/pending', '{broken')
  storage.values.set('moonmoon.study.v1/broken/r1', '{broken')
  storage.values.set('moonmoon.study.v1/mismatched/r1', raw)
  storage.values.set('moonmoon.study.v1/<script>/r1', 'untrusted key')
  const badReview = JSON.parse(storage.values.get(secondKey)); badReview.review = { ...review, authority: 'physical' }
  storage.values.set(secondKey, JSON.stringify(badReview))
  const before = [...storage.values], result = await store.catalogue()
  assert.equal(result.invalidKeys, 1)
  assert.equal(result.entries.find(x => x.id === 'orphan').state, 'interrupted')
  assert.equal(result.entries.find(x => x.id === 'local-study' && x.revision === 'r1').state, 'interrupted')
  assert.equal(result.entries.filter(x => x.state === 'invalid').length, 3)
  const screen = ui(storage); await screen.refresh()
  assert.equal(screen.buttons().length, 0)
  assert.match(screen.text(), /interrupted/)
  assert.deepEqual([...storage.values], before)
  assert.deepEqual(storage.writes, [])
})

test('actual library handlers restore the chosen saved review after restart and repeated binding creates no duplicate controls', async () => {
  const { storage } = await saved(), screen = ui(storage)
  screen.bind(); screen.bind()
  assert.equal(descendants(screen.panel).filter(node => node.id === 'study-library').length, 1)
  assert.equal(storage.reads.length, 0, 'discovery requires an explicit button')
  await screen.refresh()
  assert.equal(screen.buttons().length, 2)
  assert.ok(screen.text().includes(review.reviewer), 'untrusted reviewer stays inert text')
  assert.ok(descendants(screen.get('library')).every(node => node.innerHTML === undefined))
  await screen.buttons()[0].fire('click')
  assert.equal(screen.get('id').value, 'local-study'); assert.equal(screen.get('revision').value, 'r1')
  assert.equal(screen.get('reviewer').value, review.reviewer)
  assert.equal(screen.get('rationale').value, review.rationale)
  assert.match(screen.get('comparison').textContent, /energy margin -/)
  assert.match(screen.get('comparison').textContent, /No physical authority/)
  await screen.buttons()[1].fire('click')
  assert.equal(screen.get('revision').value, 'r2'); assert.equal(screen.get('reviewer').value, '')
  assert.deepEqual(storage.writes, []); assert.deepEqual(screen.calls, [])
})

test('stale catalogue selections cannot replace current study or a newer saved review', async () => {
  const { storage } = await saved(), screen = ui(storage)
  await screen.refresh(); await screen.buttons()[1].fire('click')
  const current = screen.get('comparison').textContent
  const changed = JSON.parse(storage.values.get(key)); changed.review.reviewer = 'A newer review'
  storage.values.set(key, JSON.stringify(changed))
  await screen.buttons()[0].fire('click')
  assert.match(screen.get('library-status').textContent, /changed since discovery/)
  assert.equal(screen.get('comparison').textContent, current)
  assert.equal(screen.get('revision').value, 'r2')
  await screen.refresh(); await screen.buttons()[0].fire('click')
  assert.equal(screen.get('reviewer').value, 'A newer review')
  assert.deepEqual(storage.writes, [])
})

test('unsaved and unknown-outcome controls are preserved when a library entry is clicked', async () => {
  const { storage } = await saved(), screen = ui(storage)
  await screen.refresh(); await screen.buttons()[0].fire('click')
  screen.get('reviewer').value = 'Unsaved reviewer'; await screen.get('reviewer').fire('input')
  await screen.buttons()[1].fire('click')
  assert.match(screen.get('library-status').textContent, /Save edits first/)
  assert.equal(screen.get('reviewer').value, 'Unsaved reviewer')
  storage.mode = 'quota'; await screen.get('save').fire('click')
  storage.mode = ''; await screen.buttons()[1].fire('click')
  assert.equal(screen.get('reviewer').value, 'Unsaved reviewer')
  assert.match(screen.get('status').textContent, /draft is still open/)
  assert.deepEqual(storage.writes, [])
})

test('storage denial and failed refresh clear old selections without claiming an empty library', async () => {
  const { storage } = await saved(), screen = ui(storage)
  await screen.refresh(); const old = screen.buttons()[0]
  storage.mode = 'enumeration-denied'; await screen.refresh()
  assert.equal(screen.buttons().length, 0)
  assert.match(screen.get('library-status').textContent, /library unavailable/)
  await old.fire('click'); assert.equal(screen.get('id').value, '')
  storage.mode = 'read-denied'; await screen.refresh()
  assert.equal(screen.buttons().length, 0)
  assert.match(screen.text(), /Storage read denied/)
  assert.deepEqual(storage.writes, [])
})

test('enumeration and record limits are bounded, honest, and deterministic with unrelated keys', async () => {
  const storage = new Storage(), store = new StudyStore(storage)
  for (let i = 40; i >= 0; i--) storage.values.set(`moonmoon.study.v1/study-${String(i).padStart(2, '0')}/r1`, '{}')
  for (let i = 0; i < 50; i++) storage.values.set(`unrelated-${i}`, 'never read')
  const result = await store.catalogue()
  assert.equal(result.entries.length, STUDY_LIBRARY_LIMITS.records)
  assert.equal(result.entries[0].id, 'study-00'); assert.equal(result.entries.at(-1).id, 'study-31')
  assert.equal(result.truncated, true)
  assert.ok(storage.reads.every(key => key.startsWith('moonmoon.study.v1/')))
  const screen = ui(storage); await screen.refresh(); assert.match(screen.text(), /more saved studies may exist/)
  for (let i = 0; i <= STUDY_LIBRARY_LIMITS.keys; i++) storage.values.set(`extra-${i}`, '')
  storage.reads = []; await assert.rejects(store.catalogue(), /inspection limit/)
  assert.deepEqual(storage.reads, []); assert.deepEqual(storage.writes, [])
})

test('oversized records remain untouched and do not prevent smaller revisions from being discovered', async () => {
  const { storage, store } = await saved()
  storage.values.set('moonmoon.study.v1/oversized/r1', 'x'.repeat(STUDY_LIBRARY_LIMITS.recordBytes + 1))
  const result = await store.catalogue()
  assert.equal(result.entries.filter(x => x.state === 'verified').length, 2)
  assert.equal(result.entries.find(x => x.id === 'oversized').state, 'limited')
  assert.equal(result.truncated, true); assert.deepEqual(storage.writes, [])
})

test('a record changed during async integrity checking is never offered as verified', async () => {
  const { storage, store } = await saved()
  let once = false
  storage.onRead = selected => { if (selected === key && !once) { once = true; queueMicrotask(() => storage.values.set(key, '{changed')) } }
  const result = await store.catalogue()
  assert.equal(result.entries.find(x => x.revision === 'r1').state, 'changed')
  assert.equal(result.entries.find(x => x.revision === 'r2').state, 'verified')
  assert.equal(storage.values.get(key), '{changed'); assert.deepEqual(storage.writes, [])
})

test('review and identity edits made while a selected revision verifies cancel that open', async () => {
  for (const field of ['reviewer', 'id']) {
    const { storage } = await saved(), screen = ui(storage)
    await screen.refresh(); await screen.buttons()[1].fire('click')
    const current = screen.get('comparison').textContent
    let once = false
    storage.onRead = selected => { if (selected === key && !once) { once = true; queueMicrotask(() => { screen.get(field).value = 'New input'; screen.get(field).fire('input') }) } }
    await screen.buttons()[0].fire('click')
    assert.match(screen.get('library-status').textContent, /Edits changed during reopen/)
    assert.equal(screen.get(field).value, 'New input')
    assert.equal(screen.get('comparison').textContent, current)
    assert.deepEqual(storage.writes, [])
  }
})

test('new empty pending journal or removed bytes after discovery block opening without changing the current view', async () => {
  for (const mutate of [storage => storage.values.set(key + '/pending', ''), storage => storage.values.delete(key)]) {
    const { storage } = await saved(), screen = ui(storage)
    await screen.refresh(); await screen.buttons()[1].fire('click')
    const current = screen.get('comparison').textContent
    mutate(storage)
    await screen.buttons()[0].fire('click')
    assert.equal(screen.get('comparison').textContent, current)
    assert.equal(screen.get('revision').value, 'r2')
    assert.match(screen.get('library-status').textContent, /current study and edits were kept/)
    assert.deepEqual(storage.writes, [])
  }
})

test('repeated clicks cannot launch concurrent opens or a refresh while an open verifies', async () => {
  const { storage } = await saved(), screen = ui(storage)
  await screen.refresh()
  const first = screen.buttons()[0].fire('click')
  const second = screen.buttons()[1].fire('click')
  const refresh = screen.refresh()
  await Promise.all([first, second, refresh])
  assert.equal(screen.get('revision').value, 'r1')
  assert.equal(screen.buttons().length, 2)
  assert.deepEqual(storage.writes, [])
})

test('the aggregate byte budget limits inspection without labeling skipped evidence corrupt', async () => {
  const { storage, store } = await saved()
  for (const selected of [key, secondKey]) {
    const record = JSON.parse(storage.values.get(selected)); record.retainedExtra = 'x'.repeat(17 * 1024 * 1024)
    storage.values.set(selected, JSON.stringify(record))
  }
  const result = await store.catalogue()
  assert.deepEqual(result.entries.map(x => x.state), ['verified', 'limited'])
  assert.equal(result.truncated, true)
  assert.deepEqual(storage.writes, [])
})

test('a concurrently replaced oversized snapshot is never parsed during discovery or selected open', async () => {
  for (const mode of ['discovery', 'open']) {
    const { storage, store } = await saved(), screen = ui(storage)
    if (mode === 'open') await screen.refresh()
    const huge = storage.values.get(key) + ' '.repeat(STUDY_LIBRARY_LIMITS.recordBytes + 1)
    let reads = 0
    storage.onRead = selected => { if (selected === key && ++reads === (mode === 'discovery' ? 2 : 1)) storage.values.set(key, huge) }
    const parse = JSON.parse; let parsedOversize = false
    JSON.parse = function (value, ...args) {
      if (typeof value === 'string' && value.length > STUDY_LIBRARY_LIMITS.recordBytes) parsedOversize = true
      return parse.call(this, value, ...args)
    }
    try {
      if (mode === 'discovery') {
        const result = await store.catalogue()
        assert.equal(result.entries.find(entry => entry.revision === 'r1').state, 'changed')
      } else {
        await screen.buttons()[0].fire('click')
        assert.match(screen.get('library-status').textContent, /changed since discovery/)
        assert.equal(screen.get('id').value, '')
      }
      assert.equal(parsedOversize, false, 'Only the budgeted, selected immutable snapshot may be decoded')
      assert.deepEqual(storage.writes, [])
    } finally { JSON.parse = parse }
  }
})

test('inventory additions and same-count replacements during validation disclose an incomplete list', async () => {
  for (const replace of [false, true]) {
    const { storage, store } = await saved()
    let once = false
    storage.onRead = selected => {
      if (selected === key && !once) {
        once = true
        queueMicrotask(() => { if (replace) storage.values.delete(secondKey); storage.values.set('moonmoon.study.v1/new-study/r9', '{}') })
      }
    }
    const result = await store.catalogue()
    assert.equal(result.inventoryChanged, true)
    assert.equal(result.truncated, true)
    assert.deepEqual(storage.writes, [])
  }
})

test('actual refresh warns when the saved inventory changes instead of presenting a complete catalogue', async () => {
  const { storage } = await saved(), screen = ui(storage)
  let once = false
  storage.onRead = selected => { if (selected === key && !once) { once = true; queueMicrotask(() => storage.values.set('moonmoon.study.v1/new-study/r9', '{}')) } }
  await screen.refresh()
  assert.match(screen.get('library-status').textContent, /inventory changed.*incomplete/)
  await screen.refresh()
  assert.ok(screen.text().includes('new-study / r9'))
  assert.deepEqual(storage.writes, [])
})
