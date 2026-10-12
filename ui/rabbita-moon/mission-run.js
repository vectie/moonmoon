// UI transport/controller only. All scientific execution is the native host's job.
import { readStudy, sha256 } from './mission-study.js'

const need = (ok, message) => { if (!ok) throw new Error(message) }
const pending = state => ['queued', 'starting', 'running', 'verifying', 'cancelling'].includes(state)
const key = 'moonmoon.local-run.last.v1'
const validId = id => /^run-[a-f0-9]{64}$/.test(id)

export class MissionRunClient {
  constructor(fetcher = globalThis.fetch.bind(globalThis)) { this.fetcher = fetcher }
  async request(path = '', method = 'GET', body) {
    const response = await this.fetcher('/api/mission-runs' + path, {
      method, headers: { 'X-MoonMoon-Local': '1', ...(body === undefined ? {} : { 'Content-Type': 'application/json' }) },
      body: body === undefined ? undefined : JSON.stringify(body), cache: 'no-store', credentials: 'omit',
    })
    const text = await response.text()
    let value; try { value = JSON.parse(text) } catch { throw new Error('Local simulation host is unavailable. Launch the supported local host and reopen this UI') }
    if (!response.ok) throw new Error(value.error || 'Local host request failed')
    return { value, text }
  }
  async start(text) { return (await this.request('', 'POST', { draft_text: text })).value }
  async list() { return (await this.request()).value.runs }
  async get(id) { need(validId(id), 'Choose an exact retained run ID'); return (await this.request('/' + id)).value }
  async result(id) { need(validId(id), 'Invalid retained run ID'); return (await this.request('/' + id + '/result')).text }
  async draft(id) { need(validId(id), 'Invalid retained run ID'); return (await this.request('/' + id + '/draft')).text }
  async cancel(id) { need(validId(id), 'Invalid retained run ID'); return (await this.request('/' + id + '/cancel', 'POST', {})).value }
  async reconcile(id) { need(validId(id), 'Invalid retained run ID'); return (await this.request('/' + id + '/reconcile', 'POST', {})).value }
}

export class MissionRunController {
  constructor({ client, storage, context, deliver, update }) {
    Object.assign(this, { client, storage, context, deliver, update })
    this.current = null; this.stamp = null; this.imported = null; this.starting = false; this.refreshing = false
    this.persistenceAvailable = Boolean(storage)
    this.lastId = ''
    try { this.lastId = storage?.getItem(key) || '' }
    catch { this.storage = null; this.persistenceAvailable = false }
  }
  remember(id) {
    this.lastId = id
    try { this.storage?.setItem(key, id) }
    catch { this.persistenceAvailable = false /* Host retains authoritative bytes even if browser storage is full. */ }
  }
  async start(text) {
    if (this.starting) return this.current
    this.starting = true
    const stamp = this.context()
    try {
      const id = 'run-' + (await sha256(text)).slice(7)
      if (pending(this.current?.state)) {
        need(this.current.run_id === id, 'Wait for the current native run or cancel it before submitting different inputs')
        return this.current
      }
      this.stamp = stamp; this.imported = null
      // Exact identity is known before POST: lost replies reconnect without rerunning.
      this.remember(id)
      this.current = await this.client.start(text); this.update(this.current); return this.current
    }
    finally { this.starting = false }
  }
  async reconnect(id = this.lastId) {
    need(validId(id), 'No retained run selected yet')
    this.remember(id); this.current = await this.client.get(id)
    this.stamp = null; this.imported = null; this.update(this.current)
    return this.current
  }
  async refresh({ explicitlyOpen = false } = {}) {
    if (this.refreshing || !this.lastId) return
    this.refreshing = true
    try {
      const id = this.lastId, run = await this.client.get(id)
      if (id !== this.lastId) return
      this.current = run; this.update(run)
      if (run.state !== 'completed' || (!explicitlyOpen && this.imported === run.run_id)) return
      if (!explicitlyOpen && (this.stamp === null || this.stamp !== this.context())) return
      const stamp = this.context(), text = await this.client.result(id), checked = await readStudy(text)
      need(id === this.lastId && stamp === this.context(), 'View or edits changed while fetching the result; reopen this retained result explicitly')
      need(checked.envelope.dossier_digest === run.dossier_digest && checked.dossier.parent_digest === run.parent_digest && checked.dossier.study_id === run.study_id && checked.dossier.revision === run.revision, 'Returned dossier does not match its retained run receipt')
      await this.deliver(checked)
      this.imported = id; this.update(run, true)
    } finally { this.refreshing = false }
  }
  async cancel() { need(this.lastId, 'No run selected'); this.current = await this.client.cancel(this.lastId); this.update(this.current) }
  async reconcile() { need(this.lastId, 'No run selected'); this.current = await this.client.reconcile(this.lastId); this.update(this.current) }
}

export function bindMissionRun(document, { freeze, context, deliver, restore, submitted, storageFactory = () => globalThis.localStorage, client = new MissionRunClient() }) {
  const byId = name => document.getElementById('study-run-' + name)
  const button = byId('start')
  if (!button || button.dataset.bound) return
  button.dataset.bound = 'true'
  const connected = () => document.getElementById('study-run-start') === button && button.isConnected !== false
  const location = () => document.location?.href || ''
  const status = message => { if (connected()) byId('status').textContent = message }
  const persistenceNotice = 'Browser run-ID storage is unavailable. Keep the exact run ID or use List retained runs after reload; host evidence remains retained.'
  let storage; try { storage = storageFactory() } catch { storage = null }
  const controller = new MissionRunController({ client, storage,
    context: () => JSON.stringify([connected(), location(), context()]), deliver,
    update: (run, imported = false) => {
      if (!connected()) return
      byId('id').value = run.run_id
      button.disabled = pending(run.state)
      byId('cancel').disabled = !pending(run.state)
      byId('open').disabled = run.state !== 'completed'
      byId('reconcile').disabled = run.state !== 'interrupted'
      status(`${run.study_id}/${run.revision} · ${run.state}\n${run.message}\nAccepted draft ${run.draft_digest}${run.dossier_digest ? '\nReturned dossier ' + run.dossier_digest : ''}\n${imported ? 'Actual result opened in the comparison below. A new digital review is required.' : run.state === 'completed' ? 'Retained result available. Open it when ready if the current view or edits changed.' : 'Digital simulation only; no physical authority.'}${controller.persistenceAvailable ? '' : '\n' + persistenceNotice}`)
    },
  })
  let busy = false, timer = null
  const poll = () => {
    if (!connected() || !pending(controller.current?.state) || timer) return
    timer = setTimeout(async () => {
      timer = null
      if (!connected()) return
      try { await controller.refresh(); poll() }
      catch (error) { status(error.message + '\nConnection lost; execution outcome is unknown. Use Reconnect to read the retained run. No rerun was sent') }
    }, 400)
    timer.unref?.()
  }
  const action = fn => async () => {
    if (busy) return
    busy = true
    try { await fn(); poll() }
    catch (error) { status(error.message + '\nExact accepted runs remain on the local host. No completed result is invented') }
    finally { busy = false }
  }
  button.addEventListener('click', action(async () => {
    const text = await freeze()
    await controller.start(text)
    await submitted(text)
    await controller.refresh()
  }))
  byId('cancel').addEventListener('click', action(() => controller.cancel()))
  byId('reconnect').addEventListener('click', action(async () => { await controller.reconnect(byId('id').value.trim() || controller.lastId); await controller.refresh() }))
  byId('open').addEventListener('click', action(() => controller.refresh({ explicitlyOpen: true })))
  byId('reconcile').addEventListener('click', action(() => controller.reconcile()))
  byId('restore').addEventListener('click', action(async () => { await restore(await client.draft(byId('id').value.trim() || controller.lastId)) }))
  byId('list').addEventListener('click', action(async () => {
    const runs = await client.list()
    byId('retained').textContent = runs.length ? runs.map(run => `${run.study_id}/${run.revision} · ${run.state}\n${run.run_id}`).join('\n\n') : 'No retained runs on this local host'
  }))
  if (controller.lastId) {
    byId('id').value = controller.lastId
    void action(async () => { await controller.reconnect(); poll() })()
  } else if (!controller.persistenceAvailable) status(persistenceNotice)
  return controller
}
