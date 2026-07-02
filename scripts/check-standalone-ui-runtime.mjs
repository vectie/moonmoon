import { spawnSync } from 'node:child_process'

const result = spawnSync('moon', ['run', 'cmd/main', '--', 'ui', 'html'], {
  encoding: 'utf8',
  maxBuffer: 16 * 1024 * 1024,
})

if (result.status !== 0) {
  process.stderr.write(result.stderr)
  process.stderr.write(result.stdout)
  process.exit(result.status ?? 1)
}

const html = result.stdout

function requireMatch(pattern, label) {
  const match = html.match(pattern)
  if (!match) {
    throw new Error(`missing ${label}`)
  }
  return match
}

const modelText = requireMatch(
  /<script id="moonmoon-view-model" type="application\/json">([\s\S]*?)<\/script>/,
  'view-model JSON',
)[1]
const runtimeText = requireMatch(
  /<script id="moonmoon-globe-runtime">([\s\S]*?)<\/script>/,
  'globe runtime',
)[1]

const model = JSON.parse(modelText)
new Function(runtimeText)

function requireValue(condition, message) {
  if (!condition) {
    throw new Error(message)
  }
}

requireValue(model.selected_route_id === 'northeast-stepout', 'selected route mismatch')
requireValue(model.globe_overlay?.corridor_windows?.length === 81, 'corridor window count mismatch')
requireValue(model.terrain_cells?.length === 16, 'terrain cell count mismatch')
requireValue(model.globe_overlay?.source_dataset_id === 'lro-lola-first-trusted-square-dem-v1', 'source dataset mismatch')
requireValue(html.includes('data-terrain-texture="lola-dem-elevation-hazard"'), 'missing terrain texture marker')
requireValue(runtimeText.includes('drawSourceTerrainTexture'), 'missing terrain texture renderer')
requireValue(runtimeText.includes('terrainColor'), 'missing terrain color mapping')
requireValue(runtimeText.includes('data-moon-action'), 'missing moon controls')

console.log(
  `Standalone UI runtime check passed: ${model.selected_route_id}, ${model.terrain_cells.length} terrain cells, ${model.globe_overlay.corridor_windows.length} corridor windows`,
)
