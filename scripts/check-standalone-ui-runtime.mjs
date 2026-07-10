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
const selectedRoute = model.routes?.find(route => route.route_id === model.selected_route_id)
requireValue(selectedRoute != null, 'selected route projection missing')
requireValue(
  selectedRoute.illumination?.recommended_window?.time_start_utc === '2026-11-08T00:00:00Z',
  'selected route recommendation mismatch',
)
requireValue(
  selectedRoute.illumination.recommended_window.meets_illumination_constraint === true,
  'selected route recommendation must clear illumination',
)
requireValue(model.globe_overlay?.source_dataset_id === 'lro-lola-first-trusted-square-dem-v1', 'source dataset mismatch')
requireValue(model.terrain_cells.some(cell => cell.selected), 'missing selected terrain cell')
requireValue(html.includes('data-terrain-texture="lola-dem-elevation-hazard"'), 'missing terrain texture marker')
requireValue(html.includes(`data-source="${model.globe_overlay.source_path}"`), 'canvas source path mismatch')
requireValue(html.includes(`data-route="${model.selected_route_id}"`), 'canvas selected route mismatch')
requireValue(runtimeText.includes('drawSourceTerrainTexture'), 'missing terrain texture renderer')
requireValue(runtimeText.includes('terrainColor'), 'missing terrain color mapping')
requireValue(runtimeText.includes('terrainCellCenter'), 'missing terrain projection mapping')
requireValue(runtimeText.includes('textureStats'), 'missing terrain texture stats')

const controls = [...html.matchAll(/data-moon-action="([^"]+)"/g)].map(match => match[1]).sort()
requireValue(JSON.stringify(controls) === JSON.stringify(['focus', 'orbit', 'reset']), 'moon controls mismatch')

console.log(
  `Standalone UI runtime check passed: ${model.selected_route_id}, ${model.terrain_cells.length} terrain cells, ${model.globe_overlay.corridor_windows.length} corridor windows`,
)
