import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile } from 'node:fs/promises'
import { readStudy, readStudyRecord, StudyStore, sha256, bindMissionStudy } from './mission-study.js'
import { createStudyArchive, readStudyArchive, STUDY_ARCHIVE_LIMIT_BYTES } from './mission-study-archive.js'

const fixtureText = await readFile(new URL('./fixtures/mission-study-local.json', import.meta.url), 'utf8')
const revisedText = await readFile(new URL('./fixtures/mission-study-revised.json', import.meta.url), 'utf8')
const fixture = await readStudy(fixtureText), revised = await readStudy(revisedText)
const key = 'moonmoon.study.v1/local-study/r1'
const review = { dossierDigest: fixture.envelope.dossier_digest, reviewer: 'A reviewer <script>test</script>', choice: 'none', rationale: 'Keep the negative energy blocker; do not dispatch.', authority: 'digital-only' }
const make = raw => createStudyArchive(raw, readStudyRecord, sha256)
const inspect = text => readStudyArchive(text, readStudyRecord, sha256)
class Storage {
  values = new Map(); writes = []; mode = ''; onRead = null
  get length() { return this.values.size }
  key(index) { return [...this.values.keys()][index] ?? null }
  getItem(key) { if (this.mode === 'read-denied') throw Error('Storage read denied'); this.onRead?.(key); return this.values.get(key) ?? null }
  setItem(key, value) {
    if (this.mode === 'quota' || this.mode === 'before-record' && !key.endsWith('/pending')) throw Error('Quota exceeded')
    this.writes.push(['set', key, value]); this.values.set(key, value)
    if (this.mode === 'after-record' && !key.endsWith('/pending')) throw Error('Acknowledgement lost')
  }
  removeItem(key) { if (this.mode === 'cleanup-denied') throw Error('Cleanup denied'); this.writes.push(['remove', key]); this.values.delete(key) }
}
async function archived() {
  const storage = new Storage(), store = new StudyStore(storage)
  let raw = await store.save(fixture, review, null)
  raw = await store.save(fixture, { ...review, rationale: 'Second review retains both alternatives and their uncertainty.' }, raw)
  return { storage, store, raw, text: await make(raw) }
}
class Element {
  constructor(tag = 'div') { this.tag = tag; this.id = ''; this.dataset = {}; this.value = ''; this.textContent = ''; this.events = new Map(); this.files = []; this.children = []; this.disabled = false }
  appendChild(child) { this.children.push(child); child.parentNode = this; return child }
  replaceChildren(...children) { this.children = children }
  addEventListener(name, fn) { this.events.set(name, [...(this.events.get(name) || []), fn]) }
  async fire(name) { if (name === 'click' && this.disabled) return; for (const fn of this.events.get(name) || []) await fn({ preventDefault() {} }) }
  click() { this.clicked?.(this) }
}
const descendants = node => [node, ...node.children.flatMap(descendants)]
function ui(storage) {
  const panel = new Element(); panel.id = 'mission-study-panel'
  for (const id of ['file','status','comparison','sensitivity-matrix','id','revision','reviewer','choice','rationale','reopen','discard','save','reconcile','export','export-session']) {
    const node = new Element(); node.id = 'study-' + id; panel.appendChild(node)
  }
  const downloads = [], calls = []
  const document = { getElementById: id => descendants(panel).find(node => node.id === id), createElement: tag => { const node = new Element(tag); node.clicked = link => downloads.push({ href: link.href, filename: link.download }); return node } }
  const client = new Proxy({}, { get: (_, name) => () => { calls.push(name); throw Error('No mission execution permitted') } })
  const bind = () => bindMissionStudy(document, () => storage, client); bind()
  const get = id => document.getElementById('study-' + id)
  return { panel, document, get, bind, downloads, calls,
    stage: async text => { get('archive-file').files = [{ size: Buffer.byteLength(text), text: async () => text }]; await get('archive-file').fire('change') },
    open: async (revision = 'r1') => { get('id').value = 'local-study'; get('revision').value = revision; await get('reopen').fire('click') },
  }
}

test('archive moves exact frozen evidence, review and ordered history into fresh storage and survives a new store', async () => {
  const source = await archived(), destination = new Storage(), store = new StudyStore(destination)
  const inspected = await inspect(source.text)
  assert.equal(inspected.archive.record_digest, await sha256(source.raw))
  assert.equal(inspected.observed, source.raw)
  assert.equal(inspected.archive.reviewer_identity, 'unverified')
  assert.deepEqual(inspected.reviewHistory, [review])
  const restored = await store.restoreArchive(source.text)
  assert.equal(restored, source.raw)
  assert.equal(destination.values.get(key), source.raw)
  const reopened = await new StudyStore(destination).open('local-study', 'r1')
  assert.equal(reopened.study.text, fixtureText)
  assert.equal(reopened.study.alternatives[1].resultText, fixture.alternatives[1].resultText)
  assert.ok(reopened.study.alternatives[1].result.energy.margin_wh < 0)
  assert.deepEqual(reopened.reviewHistory, [review])
  assert.equal(await make(restored), source.text, 'unchanged record reexports byte-identically')
  assert.equal(source.storage.values.get(key), source.raw)
  await store.save(reopened.study, { ...review, rationale: 'A new local review after transfer' }, restored)
  assert.deepEqual((await store.open('local-study', 'r1')).reviewHistory, [review, reopened.review])
})

test('unreviewed study archive retains null review without inventing a recommendation', async () => {
  const storage = new Storage(), raw = await new StudyStore(storage).save(fixture, null, null)
  const result = await inspect(await make(raw))
  assert.equal(result.review, null); assert.deepEqual(result.reviewHistory, [])
})

test('archive checks byte integrity, exact identity, history and digital-only authority before any writes', async () => {
  const { text } = await archived()
  const changes = [
    archive => { archive.record_text += ' ' },
    archive => { archive.study_id = 'other-study' },
    archive => { archive.revision = 'r2' },
    archive => { archive.dossier_digest = 'sha256:' + '0'.repeat(64) },
    archive => { archive.authority = 'physical' },
    archive => { archive.physical_readiness = true },
    archive => { archive.reviewer_identity = 'authenticated' },
    async archive => { const record = JSON.parse(archive.record_text); record.reviewHistory[0].choice = 'missing-session'; archive.record_text = JSON.stringify(record); archive.record_digest = await sha256(archive.record_text) },
    async archive => { const record = JSON.parse(archive.record_text); record.review.dossierDigest = 'wrong'; archive.record_text = JSON.stringify(record); archive.record_digest = await sha256(archive.record_text) },
    async archive => { const record = JSON.parse(archive.record_text); const dossier = JSON.parse(record.envelopeText); dossier.dossier_json += ' '; record.envelopeText = JSON.stringify(dossier); archive.record_text = JSON.stringify(record); archive.record_digest = await sha256(archive.record_text) },
  ]
  for (const change of changes) {
    const archive = JSON.parse(text); await change(archive)
    const storage = new Storage()
    await assert.rejects(new StudyStore(storage).restoreArchive(JSON.stringify(archive)))
    assert.deepEqual(storage.writes, [])
  }
})

test('existing same or different saved bytes and empty pending journals are never merged or replaced', async () => {
  const { text, raw } = await archived()
  for (const present of [raw, '{different}', '']) {
    const storage = new Storage(); storage.values.set(key, present)
    await assert.rejects(new StudyStore(storage).restoreArchive(text), /already exists/)
    assert.equal(storage.values.get(key), present); assert.deepEqual(storage.writes, [])
  }
  const storage = new Storage(); storage.values.set(key + '/pending', '')
  await assert.rejects(new StudyStore(storage).restoreArchive(text), /unresolved save/)
  assert.deepEqual(storage.writes, [])
})

test('a target created during asynchronous prepare is preserved', async () => {
  const { text } = await archived(), storage = new Storage()
  let once = false
  storage.onRead = target => { if (target === key && !once) { once = true; queueMicrotask(() => storage.values.set(key, 'other tab')) } }
  await assert.rejects(new StudyStore(storage).restoreArchive(text), /changed while preparing/)
  assert.equal(storage.values.get(key), 'other tab'); assert.deepEqual(storage.writes, [])
})

test('interrupted restore uses the existing journal and explicit reconcile without losing review history', async () => {
  const { text, raw } = await archived()
  for (const mode of ['before-record', 'after-record', 'cleanup-denied']) {
    const storage = new Storage(), store = new StudyStore(storage); storage.mode = mode
    await assert.rejects(store.restoreArchive(text))
    assert.ok(storage.values.has(key + '/pending'))
    storage.mode = ''
    const verdict = await store.reconcile('local-study', 'r1')
    if (mode === 'before-record') { assert.match(verdict, /not applied/); await store.restoreArchive(text) }
    else assert.match(verdict, /Exact save confirmed/)
    assert.equal((await store.open('local-study', 'r1')).observed, raw)
    assert.equal(storage.values.has(key + '/pending'), false)
  }
})

test('read denial and pre-journal quota errors do not claim successful persistence', async () => {
  const { text } = await archived()
  for (const mode of ['read-denied', 'quota']) {
    const storage = new Storage(); storage.mode = mode
    await assert.rejects(new StudyStore(storage).restoreArchive(text))
    assert.deepEqual([...storage.values], [])
  }
})

test('transfer and record size budgets reject files without persistence', async () => {
  await assert.rejects(inspect(' '.repeat(STUDY_ARCHIVE_LIMIT_BYTES + 1)), /32 MiB/)
  await assert.rejects(make(' '.repeat(24 * 1024 * 1024 + 1)), /24 MiB/)
  const archive = JSON.parse((await archived()).text); archive.record_text = 'x'.repeat(24 * 1024 * 1024 + 1)
  await assert.rejects(inspect(JSON.stringify(archive)), /24 MiB/)
})

test('production handlers preview then restore, leave the open revision untouched and reopen through the existing library', async () => {
  const { text, raw } = await archived(), destination = new Storage()
  await new StudyStore(destination).save(revised, null, null)
  const screen = ui(destination); screen.bind(); await screen.open('r2')
  const before = screen.get('comparison').textContent; destination.writes = []
  await screen.stage(text)
  assert.deepEqual(destination.writes, []); assert.equal(screen.get('archive-restore').disabled, false)
  assert.match(screen.get('archive-preview').textContent, /A reviewer <script>test<\/script>/)
  assert.match(screen.get('archive-preview').textContent, /energy margin -/)
  assert.match(screen.get('archive-preview').textContent, /identity is unverified/)
  assert.ok(descendants(screen.get('archive-panel')).every(node => node.innerHTML === undefined))
  assert.equal(descendants(screen.panel).filter(node => node.id === 'study-archive-panel').length, 1)
  await screen.get('archive-restore').fire('click')
  assert.equal(destination.values.get(key), raw)
  assert.equal(screen.get('comparison').textContent, before)
  assert.match(screen.get('archive-status').textContent, /Restored and read back local-study \/ r1/)
  await screen.get('library-refresh').fire('click')
  const buttons = descendants(screen.get('library-rows')).filter(node => node.tag === 'button')
  await buttons[0].fire('click')
  assert.equal(screen.get('reviewer').value, review.reviewer)
  assert.match(screen.get('comparison').textContent, /unauthenticated digital claims/)
  assert.equal(screen.get('archive-restore').disabled, true)
  assert.deepEqual(screen.calls, [])
})

test('actual download contains the verified saved record, history and stable filename', async () => {
  const { storage, raw } = await archived(), screen = ui(storage); await screen.open()
  let blob, revoked
  const create = URL.createObjectURL, revoke = URL.revokeObjectURL
  URL.createObjectURL = value => { blob = value; return 'blob:archive-download' }
  URL.revokeObjectURL = value => { revoked = value }
  try {
    await screen.get('archive-download').fire('click')
    assert.equal((await inspect(await blob.text())).observed, raw)
    assert.deepEqual(screen.downloads, [{ href: 'blob:archive-download', filename: 'local-study-r1-reviewed-study.json' }])
    assert.equal(revoked, 'blob:archive-download')
    assert.match(screen.get('archive-status').textContent, /private review text/)
    assert.deepEqual(screen.calls, [])
  } finally { URL.createObjectURL = create; URL.revokeObjectURL = revoke }
})

test('unsaved review and concurrently changed saved bytes block export without silently exporting the earlier review', async () => {
  const { storage } = await archived(), screen = ui(storage); await screen.open()
  screen.get('rationale').value = 'Unsaved changes'; await screen.get('rationale').fire('input')
  await screen.get('archive-download').fire('click')
  assert.match(screen.get('archive-status').textContent, /Save and confirm/)
  await screen.get('discard').fire('click')
  storage.values.set(key, storage.values.get(key) + ' ')
  await screen.get('archive-download').fire('click')
  assert.match(screen.get('archive-status').textContent, /changed since discovery/)
  assert.deepEqual(screen.downloads, [])
})

test('review edits during export validation prevent download and remain visible', async () => {
  const { storage } = await archived(), screen = ui(storage); await screen.open()
  let once = false
  storage.onRead = target => { if (target === key && !once) { once = true; queueMicrotask(() => { screen.get('rationale').value = 'Newer edits'; screen.get('rationale').fire('input') }) } }
  await screen.get('archive-download').fire('click')
  assert.match(screen.get('archive-status').textContent, /edits changed during export/)
  assert.equal(screen.get('rationale').value, 'Newer edits'); assert.deepEqual(screen.downloads, [])
})

test('clear, replacement file and invalid input invalidate an earlier asynchronous preview', async () => {
  const { text } = await archived(), storage = new Storage(), screen = ui(storage)
  let resolve
  screen.get('archive-file').files = [{ size: text.length, text: () => new Promise(done => { resolve = done }) }]
  const pending = screen.get('archive-file').fire('change')
  await screen.get('archive-clear').fire('click'); resolve(text); await pending
  assert.equal(screen.get('archive-preview').textContent, ''); assert.equal(screen.get('archive-restore').disabled, true)
  await screen.stage(text); await screen.stage('{invalid')
  assert.equal(screen.get('archive-restore').disabled, true)
  assert.equal(screen.get('archive-preview').textContent, '')
  assert.deepEqual(storage.writes, [])
})

test('restore refuses unsaved current edits while retaining the staged archive and all input text', async () => {
  const { text } = await archived(), storage = new Storage(); await new StudyStore(storage).save(revised, null, null)
  const screen = ui(storage); await screen.open('r2'); await screen.stage(text); storage.writes = []
  screen.get('reviewer').value = 'Unsaved'; await screen.get('reviewer').fire('input')
  await screen.get('archive-restore').fire('click')
  assert.match(screen.get('archive-status').textContent, /Save or explicitly discard/)
  assert.equal(screen.get('reviewer').value, 'Unsaved'); assert.equal(screen.get('archive-restore').disabled, false)
  assert.deepEqual(storage.writes, [])
})

test('repeat restore clicks produce one journal and collision failure leaves archived source untouched', async () => {
  const { text } = await archived(), storage = new Storage(), screen = ui(storage)
  await screen.stage(text)
  await Promise.all([screen.get('archive-restore').fire('click'), screen.get('archive-restore').fire('click')])
  assert.equal(storage.writes.filter(([op, target]) => op === 'set' && target === key).length, 1)
  const saved = storage.values.get(key)
  await screen.stage(text); await screen.get('archive-restore').fire('click')
  assert.match(screen.get('archive-status').textContent, /already exists/)
  assert.equal(storage.values.get(key), saved)
  assert.equal(screen.get('archive-restore').disabled, false)
})


test('production interrupted restore returns through existing exact-ID reconciliation and reopen controls', async () => {
  const { text, raw } = await archived(), storage = new Storage(), screen = ui(storage)
  await screen.stage(text); storage.mode = 'after-record'
  await screen.get('archive-restore').fire('click')
  assert.match(screen.get('archive-status').textContent, /restore not confirmed/)
  assert.equal(storage.values.get(key), raw)
  storage.mode = ''
  screen.get('id').value = 'local-study'; screen.get('revision').value = 'r1'
  await screen.get('reconcile').fire('click')
  assert.match(screen.get('status').textContent, /Exact save confirmed/)
  await screen.get('reopen').fire('click')
  assert.equal(screen.get('reviewer').value, review.reviewer)
  assert.equal(storage.values.has(key + '/pending'), false)
  assert.deepEqual(screen.calls, [])
})
