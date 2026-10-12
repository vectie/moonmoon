// Product runtime: loopback static UI and a fixed, local native simulation adapter.
// No shell, provider, hardware, browser-selected executable or external URL is used.
import http from 'node:http'
import { spawn } from 'node:child_process'
import { constants } from 'node:fs'
import { access, mkdir, readFile, writeFile, rename, readdir, realpath, stat, open, unlink } from 'node:fs/promises'
import { resolve, join, relative, extname, isAbsolute } from 'node:path'
import { fileURLToPath } from 'node:url'
import { webcrypto } from 'node:crypto'
import { readDraft, draftVariants, readRobotInput } from './mission-authoring.js'
import { readStudy, sha256 } from './mission-study.js'

if (!globalThis.crypto) globalThis.crypto = webcrypto
const need = (ok, message) => { if (!ok) throw new Error(message) }
const active = state => ['queued', 'starting', 'running', 'verifying', 'cancelling'].includes(state)
const runId = value => /^run-[a-f0-9]{64}$/.test(value)
const maxDraft = 16777216
const stable = value => JSON.stringify(value, function (key, item) {
  return item && !Array.isArray(item) && typeof item === 'object' ? Object.fromEntries(Object.keys(item).sort().map(name => [name, item[name]])) : item
})

// The simulator may prepare expected numeric criteria, but never rewrite the
// accepted authored inputs or frozen safety constraints. Replay alone does not
// prove that the process ran the draft accepted by this host.
const authoredInputs = design => {
  const value = structuredClone(design)
  delete value.verification_criteria.energy
  for (const key of ['distance_m', 'waypoint_count', 'drive_duration_s', 'maximum_measured_segment_slope_deg']) delete value.verification_criteria.path[key]
  return value
}

export async function verifyDraftResult(frozen, checked) {
  const { draft, parent } = await readDraft(frozen)
  need(checked.dossier.study_id === draft.study_id && checked.dossier.revision === draft.revision && checked.dossier.parent_digest === draft.parent_digest && stable(checked.dossier.site) === stable(parent.dossier.site), 'Native output does not bind the accepted draft identity and site')
  const suffix = (await sha256(frozen)).slice(7, 23), variants = draftVariants(draft)
  const sessions = ['authored-' + suffix + '-reference', ...variants.map(variant => 'authored-' + suffix + '-' + variant.variant_id)]
  need(stable(checked.alternatives.map(item => item.session_id)) === stable(sessions), 'Native output does not bind the exact accepted session list and order')
  const parentAlternative = parent.alternatives.find(item => item.session_id === draft.base_session_id)
  const baseline = structuredClone(parentAlternative.design)
  if (draft.robot_envelope_json) {
    const { robot } = await readRobotInput(draft.robot_envelope_json)
    baseline.design_id = robot.design_id; baseline.revision = robot.revision; baseline.robot_artifact = robot.robot_artifact
    baseline.environment.calibration = { ...baseline.environment.calibration, qualified: false, fault_models: [], testbed_reference: 'unqualified:robot-input-adoption' }
  }
  const expectedBaseline = { ...JSON.parse(parentAlternative.baseline_json), robot_artifact: baseline.robot_artifact, calibration: baseline.environment.calibration }
  need(checked.alternatives.every(item => stable(JSON.parse(item.baseline_json)) === stable(expectedBaseline)), 'Native baseline does not bind accepted terrain, robot and calibration sources')
  const expected = [baseline, ...variants.map(variant => {
    const design = structuredClone(baseline), e = variant.edits
    design.mission.route_id = e.route_id
    design.scenario = { ...design.scenario, scenario_id: 'authored-' + variant.variant_id, seed: e.seed, scenario_kind: e.injected_faults.length ? 'fault-injection' : 'nominal', injected_faults: [...e.injected_faults] }
    design.environment.path_cells = structuredClone(e.path_cells)
    design.environment.illumination.terrain_available_energy_wh = e.terrain_available_energy_wh
    design.verification_criteria.path.commanded_speed_mps = e.commanded_speed_mps
    return design
  })]
  checked.alternatives.forEach((item, index) => need(stable(authoredInputs(item.design)) === stable(authoredInputs(expected[index])), 'Native design does not bind accepted inputs and safety constraints for ' + sessions[index]))
  if (draft.variants) {
    const descriptions = checked.dossier.limitations.filter(line => line.startsWith('Authored variant: ')).map(line => JSON.parse(line.slice('Authored variant: '.length)))
    need(stable(descriptions) === stable(variants.map(({ variant_id, name, edits }) => ({ variant_id, name, assumption_note: edits.assumption_note }))), 'Native variant names and assumptions do not bind the accepted draft')
  }
  return sessions
}

export async function createMissionHost({ cliPath, root, staticRoot, port = 8766 }) {
  need(isAbsolute(cliPath) && isAbsolute(root) && isAbsolute(staticRoot), 'Host paths must be absolute local paths')
  need(Number.isInteger(port) && port >= 0 && port <= 65535, 'Invalid loopback port')
  await mkdir(root, { recursive: true, mode: 0o700 })
  root = await realpath(root)
  staticRoot = await realpath(staticRoot)
  // A single writer protects identity/idempotency across requests and hosts.
  let lock
  try { lock = await open(join(root, 'host.lock'), 'wx', 0o600) }
  catch { throw new Error('Run storage is already locked. If a host crashed, stop any old native processes, then remove host.lock explicitly before restarting') }
  await lock.writeFile(JSON.stringify({ pid: process.pid, created_at: new Date().toISOString() }))
  const runs = new Map(), processes = new Map()
  let closing = false, working = false, gate = Promise.resolve(), writes = Promise.resolve(), origin = ''
  const serial = action => { const next = gate.then(action); gate = next.catch(() => {}); return next }
  const directory = id => join(root, id)
  const publish = run => ({ ...run, physical_execution_allowed: false })
  const save = run => {
    run.updated_at = new Date().toISOString()
    const path = join(directory(run.run_id), 'state.json'), bytes = JSON.stringify(publish(run), null, 2) + '\n'
    const write = writes.then(async () => {
      await writeFile(path + '.next', bytes, { mode: 0o600 })
      await rename(path + '.next', path)
    })
    writes = write.catch(() => {})
    return write
  }
  const native = (run, args) => new Promise(resolveNative => {
    const child = spawn(cliPath, args, { shell: false, cwd: directory(run.run_id), env: { PATH: process.env.PATH || '' }, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true })
    processes.set(run.run_id, child)
    let output = '', error = '', spawnError = ''
    child.once('spawn', () => {
      if (run.state === 'starting') {
        run.state = 'running'; run.message = 'Native mission_study process started; no percentage estimate'
        void save(run).catch(value => { spawnError = 'Could not retain process-start state: ' + value.message; child.kill('SIGTERM') })
      }
    })
    child.stdout.on('data', bytes => { output = (output + bytes.toString()).slice(-16384) })
    child.stderr.on('data', bytes => { error = (error + bytes.toString()).slice(-16384) })
    child.on('error', value => { spawnError = value.message })
    child.on('close', (code, signal) => {
      processes.delete(run.run_id)
      resolveNative({ code, signal, output, error: spawnError || error })
    })
  })
  const resultPath = run => join(directory(run.run_id), 'output', '.moonsuite/products/moonmoon/mission-studies', run.study_id, run.revision, 'dossier.json')
  const inspectResult = async run => {
    const path = resultPath(run)
    need((await realpath(path)).startsWith(directory(run.run_id) + '/'), 'Retained result escaped its local run directory')
    const file = await stat(path)
    need(file.isFile() && file.size <= 8388608, 'Retained dossier is missing or too large')
    const text = await readFile(path, 'utf8'), checked = await readStudy(text)
    need(checked.dossier.study_id === run.study_id && checked.dossier.revision === run.revision && checked.dossier.parent_digest === run.parent_digest, 'Native output does not bind the accepted draft')
    const frozen = await readFile(join(directory(run.run_id), 'draft.json'), 'utf8')
    const suffix = run.run_id.slice(4, 20)
    need(await readFile(join(directory(run.run_id), 'output/authored', suffix, 'draft.json'), 'utf8') === frozen, 'Native output does not bind the exact accepted draft bytes')
    await verifyDraftResult(frozen, checked)
    const inspection = await native(run, ['inspect', path])
    need(inspection.code === 0, 'Native replay inspection failed: ' + (inspection.error || inspection.output))
    need(await readFile(path, 'utf8') === text, 'Native output changed during inspection')
    return { text, checked }
  }
  const complete = async (run, recovered = false) => {
    const { text, checked } = await inspectResult(run)
    if (run.state === 'cancelling') { run.state = 'cancelled'; run.message = 'Cancellation observed; any retained output is preserved without automatic import'; await save(run); return }
    run.dossier_digest = checked.envelope.dossier_digest
    run.result_bytes_digest = await sha256(text)
    run.state = 'completed'
    run.message = recovered ? 'Recovered retained native dossier and independently replayed it; original process exit was not observed' : 'Native simulation exited successfully; retained dossier independently replayed'
    run.recovered_from_interruption = recovered
    const receipt = join(directory(run.run_id), 'receipt.json')
    try { await writeFile(receipt, JSON.stringify(publish(run), null, 2) + '\n', { flag: 'wx', mode: 0o600 }) }
    catch (error) {
      if (error.code !== 'EEXIST') throw error
      const retained = JSON.parse(await readFile(receipt, 'utf8'))
      need(retained.run_id === run.run_id && retained.draft_digest === run.draft_digest && retained.dossier_digest === run.dossier_digest && retained.result_bytes_digest === run.result_bytes_digest, 'Retained receipt conflicts with recovered native output')
    }
    await save(run)
  }
  const pump = async () => {
    if (working || closing) return
    const run = [...runs.values()].find(item => item.state === 'queued')
    if (!run) return
    working = true
    try {
      await access(cliPath, constants.X_OK)
      if (run.state !== 'queued' || closing) return
      run.state = 'starting'; run.message = 'Launching the fixed local native simulator'; await save(run)
      if (run.state === 'cancelling') { run.state = 'cancelled'; run.message = 'Cancelled before native start'; await save(run); return }
      const result = await native(run, ['run-draft', join(directory(run.run_id), 'draft.json'), join(directory(run.run_id), 'output')])
      if (closing) { run.state = 'interrupted'; run.message = 'Host shutdown; retained outputs require reconciliation'; await save(run); return }
      run.native_exit_observed = true; run.exit_code = result.code; run.exit_signal = result.signal
      if (run.state === 'cancelling') { run.state = 'cancelled'; run.message = 'Native process stopped after cancellation; partial outputs retained' }
      else if (result.code !== 0) { run.state = 'failed'; run.message = 'Native simulation failed: ' + (result.error || result.output || String(result.code)) }
      else { run.state = 'verifying'; run.message = 'Native process exited successfully; replaying exact retained dossier'; await save(run); await complete(run); return }
      await save(run)
    } catch (error) {
      run.state = closing ? 'interrupted' : run.state === 'cancelling' ? 'cancelled' : 'failed'
      run.message = error.message
      await save(run)
    } finally { working = false; if (!closing) queueMicrotask(() => { void pump() }) }
  }
  try {
    for (const entry of await readdir(root, { withFileTypes: true })) {
      if (!runId(entry.name)) continue
      need(entry.isDirectory() && !entry.isSymbolicLink(), 'Run storage contains an unsafe directory')
      const run = JSON.parse(await readFile(join(root, entry.name, 'state.json'), 'utf8'))
      const frozen = await readFile(join(root, entry.name, 'draft.json'), 'utf8'), loaded = await readDraft(frozen)
      need(run.run_id === entry.name && run.run_id === 'run-' + (await sha256(frozen)).slice(7) && run.draft_digest === JSON.parse(frozen).draft_digest && run.study_id === loaded.draft.study_id && run.revision === loaded.draft.revision, 'Retained run identity changed')
      if (active(run.state)) { run.state = 'interrupted'; run.message = 'Host stopped without a confirmed terminal result. Reconcile retained output; no process is claimed to be running'; await save(run) }
      runs.set(run.run_id, run)
    }
  } catch (error) { await lock.close(); await unlink(join(root, 'host.lock')); throw error }
  const send = (response, code, body, type = 'application/json; charset=utf-8') => {
    response.writeHead(code, { 'Content-Type': type, 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'Cross-Origin-Resource-Policy': 'same-origin', 'Referrer-Policy': 'no-referrer' })
    response.end(typeof body === 'string' ? body : JSON.stringify(body))
  }
  const body = async request => {
    need(request.headers['content-type'] === 'application/json', 'Use application/json')
    let size = 0; const chunks = []
    for await (const chunk of request) { size += chunk.length; need(size <= maxDraft * 2 + 1024, 'Request exceeds the frozen-input limit'); chunks.push(chunk) }
    return JSON.parse(Buffer.concat(chunks).toString('utf8'))
  }
  const api = async (request, response, path) => {
    need(request.headers['x-moonmoon-local'] === '1', 'Local UI request header required')
    need(!request.headers.origin || request.headers.origin === origin, 'Cross-origin requests are refused')
    need(!request.headers['sec-fetch-site'] || request.headers['sec-fetch-site'] === 'same-origin', 'Cross-site requests are refused')
    if (path === '/api/mission-runs' && request.method === 'GET') return send(response, 200, { runs: [...runs.values()].map(publish) })
    if (path === '/api/mission-runs' && request.method === 'POST') {
      const { draft_text } = await body(request)
      const loaded = await readDraft(draft_text), draft = loaded.draft
      const id = 'run-' + (await sha256(draft_text)).slice(7)
      const run = await serial(async () => {
        if (runs.has(id)) return runs.get(id)
        need(runs.size < 32, 'This local host retains 32 runs. Use a new private run-storage directory; existing evidence is never deleted automatically')
        need(![...runs.values()].some(item => item.study_id === draft.study_id && item.revision === draft.revision), 'This study/revision already has different frozen inputs. Choose a new revision')
        await mkdir(directory(id), { mode: 0o700 })
        await writeFile(join(directory(id), 'draft.json'), draft_text, { flag: 'wx', mode: 0o600 })
        const item = { contract_id: 'moonmoon.local-mission-run.v1', run_id: id, study_id: draft.study_id, revision: draft.revision, parent_digest: draft.parent_digest, draft_digest: JSON.parse(draft_text).draft_digest, draft_envelope_digest: 'sha256:' + id.slice(4), state: 'queued', message: 'Exact draft retained; waiting for the local native runner', created_at: new Date().toISOString(), native_exit_observed: false, physical_execution_allowed: false }
        await save(item); runs.set(id, item); return item
      })
      send(response, 202, publish(run)); void pump(); return
    }
    const match = /^\/api\/mission-runs\/(run-[a-f0-9]{64})(?:\/(result|draft|cancel|reconcile))?$/.exec(path)
    if (!match || !runs.has(match[1])) return send(response, 404, { error: 'Unknown retained run' })
    const run = runs.get(match[1]), action = match[2]
    if (!action && request.method === 'GET') return send(response, 200, publish(run))
    if (action === 'draft' && request.method === 'GET') return send(response, 200, await readFile(join(directory(run.run_id), 'draft.json'), 'utf8'))
    if (action === 'result' && request.method === 'GET') {
      need(run.state === 'completed', 'No confirmed completed dossier is available')
      const text = await readFile(resultPath(run), 'utf8')
      need(await sha256(text) === run.result_bytes_digest, 'Retained result bytes changed; preserve evidence and investigate')
      return send(response, 200, text)
    }
    if (action === 'cancel' && request.method === 'POST') {
      await body(request)
      if (run.state === 'queued') { run.state = 'cancelled'; run.message = 'Cancelled before native start'; await save(run) }
      else if (active(run.state)) {
        run.state = 'cancelling'; run.message = 'Cancellation requested; waiting for native process exit'; await save(run)
        const child = processes.get(run.run_id)
        if (child) {
          child.kill('SIGTERM')
          const timer = setTimeout(() => { if (processes.get(run.run_id) === child) child.kill('SIGKILL') }, 2000)
          timer.unref()
        }
      }
      return send(response, 200, publish(run))
    }
    if (action === 'reconcile' && request.method === 'POST') {
      await body(request)
      need(run.state === 'interrupted', 'Only an interrupted run needs output reconciliation')
      need(!working && processes.size === 0, 'Wait for the current native process before replaying interrupted output')
      await serial(async () => {
        need(run.state === 'interrupted', 'Reconciliation is already in progress')
        run.state = 'verifying'; run.message = 'Checking retained output without rerunning simulation'; await save(run)
        try { await complete(run, true) }
        catch (error) { run.state = 'interrupted'; run.message = 'Retained result remains unconfirmed: ' + error.message; await save(run) }
      })
      return send(response, 200, publish(run))
    }
    send(response, 405, { error: 'Unsupported local operation' })
  }
  const server = http.createServer(async (request, response) => {
    try {
      need(request.headers.host === origin.slice(7), 'Unexpected host; use the exact loopback address')
      const url = new URL(request.url, origin)
      if (url.pathname.startsWith('/api/')) return await api(request, response, url.pathname)
      need(request.method === 'GET' || request.method === 'HEAD', 'Read-only UI assets')
      const requested = decodeURIComponent(url.pathname)
      need(!requested.includes('\\') && !requested.includes('\0'), 'Unsafe asset path')
      const path = await realpath(join(staticRoot, requested === '/' ? 'index.html' : requested))
      need(!relative(staticRoot, path).startsWith('..') && !isAbsolute(relative(staticRoot, path)), 'Asset is outside the built UI')
      const info = await stat(path); need(info.isFile() && info.size <= 67108864, 'Asset is unavailable')
      const mime = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css', '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png', '.woff2': 'font/woff2', '.mp4': 'video/mp4' }[extname(path)] || 'application/octet-stream'
      const bytes = await readFile(path)
      response.writeHead(200, { 'Content-Type': mime, 'X-Content-Type-Options': 'nosniff', 'Cross-Origin-Resource-Policy': 'same-origin', 'Cache-Control': 'no-cache' }); response.end(request.method === 'HEAD' ? undefined : bytes)
    } catch (error) { send(response, 400, { error: error.message }) }
  })
  try { await new Promise((ok, reject) => { server.once('error', reject); server.listen(port, '127.0.0.1', ok) }) }
  catch (error) { await lock.close(); await unlink(join(root, 'host.lock')); throw error }
  origin = 'http://127.0.0.1:' + server.address().port
  return {
    origin, server,
    async close() {
      closing = true
      for (const run of runs.values()) if (active(run.state)) {
        run.state = 'interrupted'; run.message = 'Host shutdown; retained outputs require reconciliation'; await save(run)
      }
      for (const child of processes.values()) child.kill('SIGKILL')
      await new Promise(ok => server.close(ok))
      // Do not release the single-writer lock while native callbacks can write.
      while (working || processes.size) await new Promise(ok => setTimeout(ok, 10))
      await lock.close(); await unlink(join(root, 'host.lock'))
    },
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const directory = fileURLToPath(new URL('.', import.meta.url))
  const host = await createMissionHost({
    cliPath: resolve(process.env.MOONMOON_NATIVE_CLI || join(directory, '../../_build/native/release/build/cmd/mission_study/mission_study.exe')),
    root: resolve(process.env.MOONMOON_RUN_ROOT || join(directory, '../../output/ui-mission-runs')),
    staticRoot: resolve(process.env.MOONMOON_UI_DIST || join(directory, 'dist')),
    port: Number(process.env.MOONMOON_PORT || 8766),
  })
  console.log('MoonMoon local digital mission UI: ' + host.origin)
  console.log('Local simulation only. Close this process to stop the host; retained runs remain on disk.')
  let stopping = false
  const stop = async () => { if (stopping) return; stopping = true; await host.close() }
  process.once('SIGINT', stop); process.once('SIGTERM', stop)
}
