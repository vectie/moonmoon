// Optional real-browser product regression. Uses an existing test-infrastructure
// Playwright module and Chromium binary supplied by the verification environment;
// no product dependency, external service, or new browser installation is needed.
import assert from 'node:assert/strict'
import test from 'node:test'
import { mkdtemp, readFile, writeFile, mkdir } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { createMissionHost } from './mission-run-host.js'
import { readStudy, sha256 } from './mission-study.js'

const enabled = process.env.MOONMOON_BROWSER_MODULE && process.env.MOONMOON_BROWSER_EXE && process.env.MOONMOON_NATIVE_CLI && process.env.MOONMOON_BUILD_DIST
test('served production app shows frozen route extension and keyboard details without execution or review mutation', { skip: !enabled, timeout: 60000 }, async () => {
  const { chromium } = await import(pathToFileURL(process.env.MOONMOON_BROWSER_MODULE).href)
  const root = await mkdtemp(join(tmpdir(), 'moonmoon-map-browser-'))
  const host = await createMissionHost({ cliPath: process.env.MOONMOON_NATIVE_CLI, root, staticRoot: process.env.MOONMOON_BUILD_DIST, port: 0 })
  let browser
  try {
    browser = await chromium.launch({ executablePath: process.env.MOONMOON_BROWSER_EXE, headless: true, timeout: 15000, args: ['--no-sandbox', '--disable-dev-shm-usage', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] })
    const page = await browser.newPage({ viewport: { width: 1280, height: 1000 }, reducedMotion: 'reduce' })
    const external = [], mutations = [], errors = []
    page.on('pageerror', error => errors.push(error.message))
    await page.route('**/*', route => {
      const request = route.request(), url = request.url()
      if (!url.startsWith(host.origin + '/') && !url.startsWith('data:') && !url.startsWith('blob:')) { external.push(url); return route.abort() }
      if (request.method() !== 'GET') mutations.push({ url, method: request.method() })
      return route.continue()
    })
    await page.goto(host.origin)
    await page.locator('#mission-study-panel > summary').click()
    const fixture = fileURLToPath(new URL('./fixtures/mission-study-local.json', import.meta.url))
    await page.locator('#study-file').setInputFiles(fixture)
    await page.locator('#study-map-session').waitFor()
    await page.locator('#study-save').click()
    await page.waitForFunction(() => document.getElementById('study-status').textContent.includes('Saved and read back'))
    const storageBefore = await page.evaluate(() => JSON.stringify(Object.entries(localStorage).sort()))
    await page.locator('#study-map-session').selectOption('1')
    await page.locator('#study-map-overlay').check()
    await page.locator('#study-map-detail-selection').selectOption('cell:4')
    assert.match(await page.locator('#study-map-detail').textContent(), /q11-b.*Cell 5 END.*\[4,3\].*row offset 80 m.*UNKNOWN/)
    const endpoint = page.locator('#study-route-map circle[aria-label*="Cell 5"]')
    await endpoint.focus(); await page.keyboard.press('Enter')
    assert.match(await page.locator('#study-map-detail').textContent(), /Cell 5 END/)
    const line = page.locator('#study-route-map line[aria-label*="Segment 4"]')
    await line.focus(); await page.keyboard.press('Space')
    assert.match(await page.locator('#study-map-detail').textContent(), /UNKNOWN.*slope, distance and acceptance unknown/)
    const rendered = await page.locator('#study-route-map').textContent()
    assert.match(rendered, /Frozen terrain: terrain\/route.csv/)
    assert.match(rendered, /Declared frame: local-test-grid row\/column/)
    const positions = await page.locator('#study-route-map circle[aria-label]').evaluateAll(nodes => nodes.map(node => ({ name: node.getAttribute('aria-label'), x: Number(node.getAttribute('cx')), y: Number(node.getAttribute('cy')) })))
    assert.equal(positions.length, 5)
    assert.ok(positions[4].y > positions[3].y)
    assert.ok(positions.every(point => point.x === positions[0].x))
    assert.equal(await page.evaluate(() => JSON.stringify(Object.entries(localStorage).sort())), storageBefore)
    assert.deepEqual(mutations, [])
    await page.locator('#study-export-session').fill('q11-b')
    const downloadPromise = page.waitForEvent('download'); await page.locator('#study-export').click()
    const download = await downloadPromise, downloadPath = join(root, 'exact-result.json')
    await download.saveAs(downloadPath)
    const study = await readStudy(await readFile(fixture, 'utf8'))
    assert.equal(await readFile(downloadPath, 'utf8'), study.alternatives[1].resultText)
    await page.locator('#study-file').setInputFiles({ name: 'invalid.json', mimeType: 'application/json', buffer: Buffer.from('{broken') })
    assert.equal(await page.locator('#study-map-session').inputValue(), '1')
    await page.locator('#study-reviewer').fill('Unsaved reviewer')
    await page.locator('#study-file').setInputFiles(fileURLToPath(new URL('./fixtures/mission-study-revised.json', import.meta.url)))
    assert.equal(await page.locator('#study-reviewer').inputValue(), 'Unsaved reviewer')
    assert.equal(await page.locator('#study-map-session').inputValue(), '1')
    if (process.env.MOONMOON_BROWSER_PROOF_DIR) {
      const out = process.env.MOONMOON_BROWSER_PROOF_DIR; await mkdir(out, { recursive: true })
      await page.locator('#study-route-map').screenshot({ path: join(out, 'frozen-route-map-unknown-extension.png') })
      await writeFile(join(out, 'served-browser-proof.json'), JSON.stringify({ origin: host.origin, rendered_text: rendered, positions,
        study_digest: study.envelope.dossier_digest, exported_result_digest: await sha256(await readFile(downloadPath, 'utf8')),
        storage_unchanged_by_map: true, map_execution_requests: mutations, external_requests_blocked: external, page_errors: errors }, null, 2) + '\n')
    }
    assert.deepEqual(external, []); assert.deepEqual(errors, [])
    await page.locator('#study-discard').click()
    await page.waitForFunction(() => document.getElementById('study-status').textContent.includes('Reopened the exact'))
    await page.locator('#study-file').setInputFiles(fileURLToPath(new URL('./fixtures/mission-study-revised.json', import.meta.url)))
    await page.waitForFunction(() => document.getElementById('study-route-map').textContent.includes('local-study / r2'))
    assert.equal(await page.locator('#study-map-session').inputValue(), '0')
    assert.equal(await page.locator('#study-map-overlay').isChecked(), false)
    assert.deepEqual(mutations, [])
  } finally { await browser?.close(); await host.close() }
})
