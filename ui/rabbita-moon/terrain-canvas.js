function terrainPoint(col, row, elevation, state) {
  return {
    x: col - state.cols / 2,
    y: ((elevation - state.minElevation) / state.elevationSpan) * 1.8,
    z: row - state.rows / 2,
  }
}

function project(point, canvas, yaw) {
  const cy = Math.cos(yaw)
  const sy = Math.sin(yaw)
  const x = point.x * cy - point.z * sy
  const z = point.x * sy + point.z * cy
  const scale = Math.min(canvas.width, canvas.height) * 0.16
  return {
    x: canvas.width * 0.5 + x * scale,
    y: canvas.height * 0.72 + z * scale * 0.48 - point.y * scale * 1.18,
    depth: z,
  }
}

function polygon(ctx, points, fill, stroke) {
  ctx.beginPath()
  ctx.moveTo(points[0].x, points[0].y)
  for (let i = 1; i < points.length; i += 1) ctx.lineTo(points[i].x, points[i].y)
  ctx.closePath()
  ctx.fillStyle = fill
  ctx.fill()
  ctx.strokeStyle = stroke
  ctx.stroke()
}

function topColor(cell, t) {
  if (cell.selected) return `rgb(${196 + t * 28}, ${216 + t * 18}, ${206 + t * 14})`
  if (cell.hazard === 'blocked') return `rgb(${124 + t * 62}, ${94 + t * 44}, ${75 + t * 32})`
  return `rgb(${82 + t * 68}, ${132 + t * 52}, ${112 + t * 38})`
}

function cellMesh(cell, state, canvas, yaw) {
  const c = Number(cell.col)
  const r = Number(cell.row)
  const h = Number(cell.elevation_m || 0)
  const top = [
    terrainPoint(c, r, h, state),
    terrainPoint(c + 0.95, r, h, state),
    terrainPoint(c + 0.95, r + 0.95, h, state),
    terrainPoint(c, r + 0.95, h, state),
  ]
  const base = top.map(point => ({ ...point, y: 0 }))
  return {
    cell,
    top,
    base,
    depth: top.reduce((sum, point) => sum + project(point, canvas, yaw).depth, 0) / 4,
  }
}

function drawRoute(ctx, canvas, state, yaw) {
  const start = project(terrainPoint(0.2, state.rows - 0.18, state.minElevation, state), canvas, yaw)
  const end = project(terrainPoint(state.cols - 0.05, 0.2, state.maxElevation, state), canvas, yaw)
  ctx.beginPath()
  ctx.moveTo(start.x, start.y)
  ctx.lineTo(end.x, end.y)
  ctx.strokeStyle = 'rgba(39, 120, 98, 0.9)'
  ctx.lineWidth = 4
  ctx.stroke()
}

function drawSelectedPin(ctx, canvas, state, yaw) {
  const selected = state.selected
  const p = project(
    terrainPoint(selected.col + 0.48, selected.row + 0.48, selected.elevation_m, state),
    canvas,
    yaw,
  )
  ctx.beginPath()
  ctx.arc(p.x, p.y - 10, 6, 0, Math.PI * 2)
  ctx.fillStyle = '#236f5c'
  ctx.fill()
  ctx.strokeStyle = '#f7fbf9'
  ctx.lineWidth = 2
  ctx.stroke()
  ctx.beginPath()
  ctx.moveTo(p.x, p.y - 3)
  ctx.lineTo(p.x, p.y + 20)
  ctx.strokeStyle = 'rgba(35, 111, 92, 0.78)'
  ctx.lineWidth = 2
  ctx.stroke()
}

globalThis.__moonmoonRenderTerrain = modelJson => {
  const canvas = document.getElementById('moonmoon-terrain-3d')
  if (!canvas) return
  const view = JSON.parse(modelJson)
  const cells = view.terrain_cells || []
  const ctx = canvas.getContext('2d')
  if (!ctx || cells.length === 0) return
  const elevations = cells.map(cell => Number(cell.elevation_m || 0))
  const state = {
    cells,
    rows: view.viewport.rows || 4,
    cols: view.viewport.cols || 4,
    selected: view.selected_tile || cells[0],
    minElevation: Math.min(...elevations),
    maxElevation: Math.max(...elevations),
  }
  state.elevationSpan = Math.max(1, state.maxElevation - state.minElevation)

  let yaw = -0.72
  let dragging = false
  let lastX = 0
  let frame = 0

  canvas.onpointerdown = event => {
    dragging = true
    lastX = event.clientX
    canvas.setPointerCapture(event.pointerId)
  }
  canvas.onpointermove = event => {
    if (!dragging) return
    yaw += (event.clientX - lastX) * 0.01
    lastX = event.clientX
  }
  canvas.onpointerup = () => {
    dragging = false
  }

  function render() {
    const ratio = window.devicePixelRatio || 1
    const rect = canvas.getBoundingClientRect()
    const width = Math.max(360, Math.floor(rect.width * ratio))
    const height = Math.max(260, Math.floor(rect.height * ratio))
    if (canvas.width !== width || canvas.height !== height) {
      canvas.width = width
      canvas.height = height
    }

    const gradient = ctx.createLinearGradient(0, 0, 0, canvas.height)
    gradient.addColorStop(0, '#17201d')
    gradient.addColorStop(1, '#eef0ea')
    ctx.fillStyle = gradient
    ctx.fillRect(0, 0, canvas.width, canvas.height)

    const meshes = cells.map(cell => cellMesh(cell, state, canvas, yaw)).sort((a, b) => a.depth - b.depth)
    for (const mesh of meshes) {
      const top = mesh.top.map(point => project(point, canvas, yaw))
      const base = mesh.base.map(point => project(point, canvas, yaw))
      const t = (Number(mesh.cell.elevation_m || 0) - state.minElevation) / state.elevationSpan
      polygon(ctx, [base[0], base[1], top[1], top[0]], 'rgba(67, 71, 65, 0.46)', 'rgba(34, 39, 35, 0.34)')
      polygon(ctx, [base[1], base[2], top[2], top[1]], 'rgba(48, 53, 49, 0.42)', 'rgba(34, 39, 35, 0.30)')
      polygon(ctx, top, topColor(mesh.cell, t), 'rgba(255, 255, 255, 0.30)')
    }

    drawRoute(ctx, canvas, state, yaw)
    drawSelectedPin(ctx, canvas, state, yaw)
    yaw += dragging ? 0 : 0.0018
    canvas.dataset.renderedFrames = String(frame)
    frame += 1
    window.requestAnimationFrame(render)
  }

  render()
}
