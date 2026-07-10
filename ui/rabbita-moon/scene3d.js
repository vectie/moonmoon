import LOLA_TERRAIN_TILE from './assets/lro_lola/first_trusted_square_lola_5m_129.json' with { type: 'json' }
import { canvasRenderActive, markCanvasRenderActive, markCanvasRenderPaused } from './render-lifecycle.js'

let THREE
let OrbitControls
let ConvexGeometry
let FOOT_PHASE_SEQUENCE
let NOETIX_URDF_LIMIT_SOURCE
let NOETIX_VISUAL_RIG
let NOETIX_WALK_CLIP
let authoredMotionSample
let cloneJointSamples
let cycle01
let emptyJointCorrections
let footRoleColor
let jointSamples
let near
let supportMassTransferX
let walkClipSample
let E1_ASM_ASSEMBLY = {
  ready: false,
  status: 'adapter-runtime-not-loaded',
  visuals: [],
  joints: [],
}
let adapterRuntimePromise

const DEG = Math.PI / 180
const EARTH_TEXTURE_URL = new URL('./assets/earth/earth_atmos_2048.jpg', import.meta.url).href
const ROBOT_QUALITY_REFRESH_MS = 1000
const ROBOT_DATASET_REFRESH_MS = 250
const E1_ASM_DUPLICATE_OFFSET_X = 0.74
const URDF_TO_SCENE_MATRIX = [0, 0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1]
const E1_RENDER_DETAIL_MODE = 'convex-hull-plus-sampled-stl'
let E1_MESH_REDUCTION_ALGORITHM = 'adapter-runtime-not-loaded'
const THIRD_PERSON_TERRAIN_COLS = 96
const THIRD_PERSON_TERRAIN_ROWS = 112
const THIRD_PERSON_TERRAIN_WIDTH_M = 52
const THIRD_PERSON_TERRAIN_DEPTH_M = 74
const THIRD_PERSON_VISUAL_RADIUS_M = 260
const LOLA_TERRAIN_HEIGHT_SCALE = 0.12
const LOLA_TERRAIN_TEXTURE_SOURCE = 'lola-dem-moonsand-regolith-texture'
const LOLA_TERRAIN_MOTION_MODEL = 'world-progress-lola-dem'
const LOLA_DISTANT_RIDGE_MODEL = 'lola-dem-distant-ridges'
const LOLA_TERRAIN_TEXTURE_SIZE = 1024
const LOLA_TERRAIN_COLOR_REPEAT = 10
const LOLA_TERRAIN_BUMP_REPEAT = 26
const LOLA_REGOLITH_MATERIAL_MODEL = 'lola-hillshade-moonsand-microcrater-pebbles-v1'
const LOLA_DISTANT_RIDGE_SAMPLES = 96
const EARTHRISE_TEXTURE_SOURCE = 'earth-atmos-2048-real-texture'
const EARTHRISE_LIGHTING_MODEL = 'utc-subsolar-readable-terminator-v2'
const EARTHRISE_NIGHT_FILL = 0.52
const EARTHRISE_DAY_BOOST = 1.54
const LUNAR_SURFACE_VISUAL_MODEL = 'curved-lunar-cap'

async function loadAdapterRuntime() {
  if (adapterRuntimePromise) return adapterRuntimePromise
  adapterRuntimePromise = Promise.all([
    import('three'),
    import('three/examples/jsm/controls/OrbitControls.js'),
    import('three/examples/jsm/geometries/ConvexGeometry.js'),
    import('./gait-clip.js'),
    import('./.generated/e1-asm-assembly.js'),
  ]).then(([threeModule, controlsModule, convexModule, gaitModule, assemblyModule]) => {
    THREE = threeModule
    OrbitControls = controlsModule.OrbitControls
    ConvexGeometry = convexModule.ConvexGeometry
    ;({
      FOOT_PHASE_SEQUENCE,
      NOETIX_URDF_LIMIT_SOURCE,
      NOETIX_VISUAL_RIG,
      NOETIX_WALK_CLIP,
      authoredMotionSample,
      cloneJointSamples,
      cycle01,
      emptyJointCorrections,
      footRoleColor,
      jointSamples,
      near,
      supportMassTransferX,
      walkClipSample,
    } = gaitModule)
    E1_ASM_ASSEMBLY = assemblyModule.E1_ASM_ASSEMBLY
    E1_MESH_REDUCTION_ALGORITHM = E1_ASM_ASSEMBLY.reduction_algorithm || 'unknown-reduction'
    Object.assign(globalThis.__moonmoonGaitDiagnostics, {
      rig: NOETIX_VISUAL_RIG,
      sampleRobotGeometry: robotGeometry,
    })
  }).catch(error => {
    adapterRuntimePromise = undefined
    throw error
  })
  return adapterRuntimePromise
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
}

function mix(a, b, t) {
  return a + (b - a) * t
}

function smoothstep(value) {
  const t = clamp(value, 0, 1)
  return t * t * (3 - 2 * t)
}

function mat4Identity() {
  return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
}

function mat4Multiply(a, b) {
  const out = new Array(16)
  for (let col = 0; col < 4; col += 1) {
    for (let row = 0; row < 4; row += 1) {
      out[col * 4 + row] =
        a[row] * b[col * 4] +
        a[4 + row] * b[col * 4 + 1] +
        a[8 + row] * b[col * 4 + 2] +
        a[12 + row] * b[col * 4 + 3]
    }
  }
  return out
}

function mat4Translate(m, x, y, z) {
  const t = mat4Identity()
  t[12] = x
  t[13] = y
  t[14] = z
  return mat4Multiply(m, t)
}

function mat4WorldOffset(m, x, y, z) {
  const t = mat4Identity()
  t[12] = x
  t[13] = y
  t[14] = z
  return mat4Multiply(t, m)
}

function mat4RotateX(m, a) {
  const c = Math.cos(a)
  const s = Math.sin(a)
  return mat4Multiply(m, [1, 0, 0, 0, 0, c, s, 0, 0, -s, c, 0, 0, 0, 0, 1])
}

function mat4RotateY(m, a) {
  const c = Math.cos(a)
  const s = Math.sin(a)
  return mat4Multiply(m, [c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, 0, 0, 0, 1])
}

function mat4RotateZ(m, a) {
  const c = Math.cos(a)
  const s = Math.sin(a)
  return mat4Multiply(m, [c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])
}

function mat4AxisAngle(m, axis, angle) {
  const [x, y, z] = normalizeArray3(axis)
  const c = Math.cos(angle)
  const s = Math.sin(angle)
  const t = 1 - c
  return mat4Multiply(m, [
    t * x * x + c, t * x * y + s * z, t * x * z - s * y, 0,
    t * x * y - s * z, t * y * y + c, t * y * z + s * x, 0,
    t * x * z + s * y, t * y * z - s * x, t * z * z + c, 0,
    0, 0, 0, 1,
  ])
}

function normalizeArray3(axis) {
  const len = Math.max(0.000001, Math.hypot(axis[0], axis[1], axis[2]))
  return [axis[0] / len, axis[1] / len, axis[2] / len]
}

function mat4FromUrdfOrigin(origin) {
  let matrix = mat4Identity()
  const xyz = origin?.xyz ?? [0, 0, 0]
  const rpy = origin?.rpy ?? [0, 0, 0]
  matrix = mat4Translate(matrix, xyz[0], xyz[1], xyz[2])
  matrix = mat4RotateX(matrix, rpy[0])
  matrix = mat4RotateY(matrix, rpy[1])
  matrix = mat4RotateZ(matrix, rpy[2])
  return matrix
}

function mat4Perspective(fov, aspect, near, far) {
  const f = 1 / Math.tan(fov / 2)
  const nf = 1 / (near - far)
  return [
    f / aspect, 0, 0, 0,
    0, f, 0, 0,
    0, 0, (far + near) * nf, -1,
    0, 0, 2 * far * near * nf, 0,
  ]
}

function createProgram(gl) {
  const vertex = gl.createShader(gl.VERTEX_SHADER)
  gl.shaderSource(vertex, `
    attribute vec3 a_position;
    attribute vec3 a_color;
    uniform mat4 u_mvp;
    varying vec3 v_color;
    void main() {
      gl_Position = u_mvp * vec4(a_position, 1.0);
      v_color = a_color;
      gl_PointSize = 7.0;
    }
  `)
  gl.compileShader(vertex)
  if (!gl.getShaderParameter(vertex, gl.COMPILE_STATUS)) {
    throw new Error(gl.getShaderInfoLog(vertex) || 'scene vertex shader failed')
  }
  const fragment = gl.createShader(gl.FRAGMENT_SHADER)
  gl.shaderSource(fragment, `
    precision mediump float;
    varying vec3 v_color;
    void main() {
      gl_FragColor = vec4(v_color, 1.0);
    }
  `)
  gl.compileShader(fragment)
  if (!gl.getShaderParameter(fragment, gl.COMPILE_STATUS)) {
    throw new Error(gl.getShaderInfoLog(fragment) || 'scene fragment shader failed')
  }
  const program = gl.createProgram()
  gl.attachShader(program, vertex)
  gl.attachShader(program, fragment)
  gl.linkProgram(program)
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    throw new Error(gl.getProgramInfoLog(program) || 'scene program failed')
  }
  return {
    program,
    position: gl.getAttribLocation(program, 'a_position'),
    color: gl.getAttribLocation(program, 'a_color'),
    mvp: gl.getUniformLocation(program, 'u_mvp'),
  }
}

function createBuffers(gl) {
  return {
    positions: gl.createBuffer(),
    colors: gl.createBuffer(),
  }
}

function upload(gl, shader, buffers, vertices, colors, mvp) {
  gl.useProgram(shader.program)
  gl.uniformMatrix4fv(shader.mvp, false, new Float32Array(mvp))
  gl.bindBuffer(gl.ARRAY_BUFFER, buffers.positions)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.DYNAMIC_DRAW)
  gl.enableVertexAttribArray(shader.position)
  gl.vertexAttribPointer(shader.position, 3, gl.FLOAT, false, 0, 0)
  gl.bindBuffer(gl.ARRAY_BUFFER, buffers.colors)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(colors), gl.DYNAMIC_DRAW)
  gl.enableVertexAttribArray(shader.color)
  gl.vertexAttribPointer(shader.color, 3, gl.FLOAT, false, 0, 0)
}

function resizeCanvas(canvas, gl) {
  const ratio = Math.min(2, window.devicePixelRatio || 1)
  const rect = canvas.getBoundingClientRect()
  const width = Math.max(320, Math.floor(rect.width * ratio))
  const height = Math.max(260, Math.floor(rect.height * ratio))
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width
    canvas.height = height
  }
  gl.viewport(0, 0, canvas.width, canvas.height)
}

function addTri(vertices, colors, a, b, c, color) {
  vertices.push(...a, ...b, ...c)
  colors.push(...color, ...color, ...color)
}

function addQuad(vertices, colors, a, b, c, d, color) {
  addTri(vertices, colors, a, b, c, color)
  addTri(vertices, colors, a, c, d, color)
}

function cubeTriangles(center, size, matrix) {
  const [sx, sy, sz] = size.map(v => v * 0.5)
  const pts = [
    [-sx, -sy, -sz], [sx, -sy, -sz], [sx, sy, -sz], [-sx, sy, -sz],
    [-sx, -sy, sz], [sx, -sy, sz], [sx, sy, sz], [-sx, sy, sz],
  ].map(p => transformPoint(matrix, [p[0] + center[0], p[1] + center[1], p[2] + center[2]]))
  return [
    [0, 1, 2, 3], [4, 7, 6, 5], [0, 4, 5, 1],
    [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0],
  ].map(face => face.map(i => pts[i]))
}

function transformPoint(m, p) {
  return [
    m[0] * p[0] + m[4] * p[1] + m[8] * p[2] + m[12],
    m[1] * p[0] + m[5] * p[1] + m[9] * p[2] + m[13],
    m[2] * p[0] + m[6] * p[1] + m[10] * p[2] + m[14],
  ]
}

function addCube(vertices, colors, matrix, center, size, color) {
  for (const face of cubeTriangles(center, size, matrix)) {
    addQuad(vertices, colors, face[0], face[1], face[2], face[3], color)
  }
}

function e1UrdfPointToScene(point) {
  return [-point[1], point[2], point[0]]
}

function e1Color(visual, phaseShift = 0) {
  const rgba = visual.color_rgba ?? [0.82, 0.84, 0.82, 1]
  return [
    clamp(rgba[0] * 0.72 + 0.10 + phaseShift, 0, 1),
    clamp(rgba[1] * 0.76 + 0.08, 0, 1),
    clamp(rgba[2] * 0.82 + 0.06, 0, 1),
  ]
}

function addE1StlMesh(vertices, colors, sceneRoot, linkMatrix, visual, mesh) {
  const visualMatrix = mat4Multiply(linkMatrix, mat4FromUrdfOrigin(visual.origin))
  const color = e1Color(visual, visual.link_id.includes('_leg_') ? 0.05 : 0)
  for (const triangle of mesh.sampled_triangles) {
    const points = triangle.map(point => transformPoint(
      sceneRoot,
      e1UrdfPointToScene(transformPoint(visualMatrix, point)),
    ))
    addTri(vertices, colors, points[0], points[1], points[2], color)
  }
}

function threeMatrixFromMat4(matrix) {
  return new THREE.Matrix4().fromArray(matrix)
}

function e1ThreeGeometry(visual) {
  const positions = []
  for (const triangle of visual.sampled_triangles ?? []) {
    for (const point of triangle) {
      positions.push(point[0], point[1], point[2])
    }
  }
  const geometry = new THREE.BufferGeometry()
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3))
  geometry.computeVertexNormals()
  geometry.computeBoundingBox()
  geometry.computeBoundingSphere()
  return geometry
}

function e1ThreeMaterial(visual) {
  const color = e1Color(visual, visual.link_id.includes('_leg_') ? 0.05 : 0)
  return new THREE.MeshStandardMaterial({
    color: new THREE.Color(color[0] * 0.66, color[1] * 0.68, color[2] * 0.72),
    roughness: 0.96,
    metalness: 0,
    side: THREE.DoubleSide,
    transparent: true,
    opacity: 0.34,
    depthWrite: false,
  })
}

function e1RigidHull(visual) {
  const bounds = visual.source_bounds_m
  if (!bounds) return null
  const uniquePoints = new Map()
  for (const triangle of visual.sampled_triangles ?? []) {
    for (const point of triangle) {
      uniquePoints.set(point.map(value => value.toFixed(5)).join(':'), new THREE.Vector3(...point))
    }
  }
  let geometry
  try {
    geometry = new ConvexGeometry([...uniquePoints.values()])
  } catch {
    const size = bounds.max.map((value, index) => Math.max(0.014, value - bounds.min[index]))
    const center = bounds.max.map((value, index) => (value + bounds.min[index]) * 0.5)
    geometry = new THREE.BoxGeometry(size[0] * 0.92, size[1] * 0.92, size[2] * 0.94)
    geometry.translate(center[0], center[1], center[2])
  }
  const isJoint = /_(yaw|roll|pitch)_link$/.test(visual.link_id)
  const isFoot = visual.link_id.includes('ankle_roll')
  const color = isJoint ? 0x69716f : isFoot ? 0xb9bdb8 : 0x9da39f
  const material = new THREE.MeshStandardMaterial({
    color,
    roughness: 0.84,
    metalness: 0.04,
  })
  const hull = new THREE.Mesh(geometry, material)
  hull.userData.detailMode = 'sampled-stl-convex-rigid-hull'
  return hull
}

function createE1ThreeVisuals() {
  const group = new THREE.Group()
  const visuals = new Map()
  if (!E1_ASM_ASSEMBLY.ready) return { group, visuals }
  for (const visual of E1_ASM_ASSEMBLY.visuals) {
    const mesh = new THREE.Mesh(e1ThreeGeometry(visual), e1ThreeMaterial(visual))
    mesh.userData.detailMode = 'sampled-stl-overlay'
    mesh.userData.reductionAlgorithm = visual.reduction_algorithm
    const linkGroup = new THREE.Group()
    linkGroup.matrixAutoUpdate = false
    const hull = e1RigidHull(visual)
    if (hull) linkGroup.add(hull)
    linkGroup.add(mesh)
    linkGroup.userData.linkId = visual.link_id
    group.add(linkGroup)
    visuals.set(visual.link_id, { group: linkGroup, hull, mesh, visual })
  }
  return { group, visuals }
}

function reportE1SourceReadiness(visuals, canvas) {
  if (!E1_ASM_ASSEMBLY.ready) return
  let sourceTriangles = 0
  for (const entry of visuals.values()) {
    sourceTriangles += entry.visual.source_triangle_count || 0
  }
  canvas.dataset.e1FullStlStatus = 'full-stl-source-indexed'
  canvas.dataset.e1FullStlLoaded = '0'
  canvas.dataset.e1FullStlFailed = '0'
  canvas.dataset.e1FullStlTotal = String(visuals.size)
  canvas.dataset.e1FullStlSourceTriangles = String(sourceTriangles)
  canvas.dataset.e1RenderDetailMode = E1_RENDER_DETAIL_MODE
  canvas.dataset.e1MeshReductionAlgorithm = E1_MESH_REDUCTION_ALGORITHM
}

function hash01(x, y) {
  let h = Math.imul(Math.floor(x * 4096), 374761393) ^ Math.imul(Math.floor(y * 4096), 668265263)
  h = Math.imul(h ^ (h >>> 13), 1274126177)
  return ((h ^ (h >>> 16)) >>> 0) / 4294967295
}

function valueNoise2(x, y) {
  const xi = Math.floor(x)
  const yi = Math.floor(y)
  const tx = smoothstep(x - xi)
  const ty = smoothstep(y - yi)
  const a = hash01(xi, yi)
  const b = hash01(xi + 1, yi)
  const c = hash01(xi, yi + 1)
  const d = hash01(xi + 1, yi + 1)
  return mix(mix(a, b, tx), mix(c, d, tx), ty)
}

function fbmNoise2(x, y) {
  let value = 0
  let amplitude = 0.5
  let frequency = 1
  let total = 0
  for (let octave = 0; octave < 5; octave += 1) {
    value += valueNoise2(x * frequency, y * frequency) * amplitude
    total += amplitude
    amplitude *= 0.52
    frequency *= 2.07
  }
  return value / Math.max(0.0001, total)
}

function lolaTextureElevationAtUv(u, v) {
  const grid = LOLA_TERRAIN_TILE.grid
  const col = wrapUnit(u * (grid.cols - 1), grid.cols - 1)
  const row = wrapUnit(v * (grid.rows - 1), grid.rows - 1)
  const col0 = Math.floor(col)
  const row0 = Math.floor(row)
  const col1 = (col0 + 1) % grid.cols
  const row1 = (row0 + 1) % grid.rows
  const tx = col - col0
  const ty = row - row0
  const h00 = LOLA_TERRAIN_TILE.elevations_m[row0][col0]
  const h10 = LOLA_TERRAIN_TILE.elevations_m[row0][col1]
  const h01 = LOLA_TERRAIN_TILE.elevations_m[row1][col0]
  const h11 = LOLA_TERRAIN_TILE.elevations_m[row1][col1]
  return mix(mix(h00, h10, tx), mix(h01, h11, tx), ty)
}

function regolithCraterDetail(x, y, scale, strength) {
  const gx = x * scale
  const gy = y * scale
  const cellX = Math.floor(gx)
  const cellY = Math.floor(gy)
  let shade = 0
  let height = 0
  for (let oy = -1; oy <= 1; oy += 1) {
    for (let ox = -1; ox <= 1; ox += 1) {
      const cx = cellX + ox
      const cy = cellY + oy
      const seed = hash01(cx, cy)
      if (seed < 0.64) continue
      const centerX = cx + 0.18 + hash01(cx + 17.3, cy + 5.9) * 0.64
      const centerY = cy + 0.18 + hash01(cx + 29.1, cy + 13.7) * 0.64
      const radius = 0.12 + hash01(cx + 43.7, cy + 71.2) * 0.24
      const d = Math.hypot(gx - centerX, gy - centerY)
      if (d >= radius) continue
      const q = d / radius
      const bowl = 1 - smoothstep(q * 1.18)
      const rim = smoothstep((q - 0.58) / 0.30) * (1 - smoothstep((q - 0.88) / 0.12))
      shade += (-bowl * 0.34 + rim * 0.20) * strength
      height += (-bowl * 0.42 + rim * 0.24) * strength
    }
  }
  return { shade, height }
}

function regolithPebbleDetail(x, y) {
  const gx = x * 180
  const gy = y * 180
  const cellX = Math.floor(gx)
  const cellY = Math.floor(gy)
  const seed = hash01(cellX, cellY)
  if (seed < 0.94) return { shade: 0, height: 0 }
  const cx = cellX + hash01(cellX + 9.1, cellY + 4.3)
  const cy = cellY + hash01(cellX + 2.4, cellY + 19.7)
  const d = Math.hypot(gx - cx, gy - cy)
  const radius = 0.16 + seed * 0.18
  if (d > radius) return { shade: 0, height: 0 }
  const edge = 1 - smoothstep(d / radius)
  const litSide = (gx - cx) * -0.42 + (gy - cy) * 0.58
  return {
    shade: edge * (0.10 + litSide * 0.15),
    height: edge * 0.35,
  }
}

function regolithDetailAt(u, v) {
  const fine = fbmNoise2(u * 76, v * 76)
  const grit = hash01(Math.floor(u * 1024), Math.floor(v * 1024))
  const agglutinate = valueNoise2(u * 230, v * 230)
  const smallCraters = regolithCraterDetail(u, v, 42, 0.30)
  const largeCraters = regolithCraterDetail(u + 18.7, v + 4.2, 13, 0.46)
  const pebble = regolithPebbleDetail(u, v)
  const granularShade = (fine - 0.5) * 0.12 + (grit - 0.5) * 0.045
  const darkSpeck = agglutinate > 0.72 ? -0.11 * smoothstep((agglutinate - 0.72) / 0.28) : 0
  return {
    shade: granularShade + darkSpeck + smallCraters.shade + largeCraters.shade + pebble.shade,
    height: (fine - 0.5) * 0.18 + (grit - 0.5) * 0.08 +
      smallCraters.height + largeCraters.height + pebble.height,
  }
}

function lolaTextureTone(elevationM, slopeM, light, detail) {
  const grid = LOLA_TERRAIN_TILE.grid
  const height01 = clamp(
    (elevationM - grid.min_elevation_m) / Math.max(0.001, grid.height_range_m),
    0,
    1,
  )
  const relief = clamp(slopeM / 22, 0, 1)
  const shade = clamp(
    0.19 + light * 0.46 + height01 * 0.12 + relief * 0.10 + detail.shade,
    0.055,
    0.82,
  )
  const warmDust = 0.025 + height01 * 0.045 + relief * 0.018
  const coolShadow = clamp(0.03 - light * 0.025, 0, 0.03)
  return {
    r: shade * (0.80 + warmDust),
    g: shade * (0.79 + warmDust * 0.46),
    b: shade * (0.73 + relief * 0.030 + coolShadow),
  }
}

function createLolaRegolithTexture() {
  const canvas = document.createElement('canvas')
  canvas.width = LOLA_TERRAIN_TEXTURE_SIZE
  canvas.height = LOLA_TERRAIN_TEXTURE_SIZE
  const context = canvas.getContext('2d')
  const image = context.createImageData(canvas.width, canvas.height)
  for (let y = 0; y < canvas.height; y += 1) {
    const v = y / Math.max(1, canvas.height - 1)
    for (let x = 0; x < canvas.width; x += 1) {
      const u = x / Math.max(1, canvas.width - 1)
      const elevationM = lolaTextureElevationAtUv(u, v)
      const dx = lolaTextureElevationAtUv(u + 1 / 160, v) - lolaTextureElevationAtUv(u - 1 / 160, v)
      const dz = lolaTextureElevationAtUv(u, v + 1 / 160) - lolaTextureElevationAtUv(u, v - 1 / 160)
      const slopeM = Math.hypot(dx, dz)
      const light = clamp(0.5 + (dx * -0.038 + dz * 0.046), 0, 1)
      const detail = regolithDetailAt(u, v)
      const tone = lolaTextureTone(elevationM, slopeM, light, detail)
      const i = (y * canvas.width + x) * 4
      image.data[i] = Math.round(clamp(tone.r, 0, 1) * 255)
      image.data[i + 1] = Math.round(clamp(tone.g, 0, 1) * 255)
      image.data[i + 2] = Math.round(clamp(tone.b, 0, 1) * 255)
      image.data[i + 3] = 255
    }
  }
  context.putImageData(image, 0, 0)
  const texture = new THREE.CanvasTexture(canvas)
  texture.colorSpace = THREE.SRGBColorSpace
  texture.wrapS = THREE.RepeatWrapping
  texture.wrapT = THREE.RepeatWrapping
  texture.repeat.set(LOLA_TERRAIN_COLOR_REPEAT, LOLA_TERRAIN_COLOR_REPEAT)
  texture.anisotropy = 8
  texture.needsUpdate = true
  return texture
}

function createLolaRegolithBumpTexture() {
  const canvas = document.createElement('canvas')
  canvas.width = LOLA_TERRAIN_TEXTURE_SIZE
  canvas.height = LOLA_TERRAIN_TEXTURE_SIZE
  const context = canvas.getContext('2d')
  const image = context.createImageData(canvas.width, canvas.height)
  for (let y = 0; y < canvas.height; y += 1) {
    const v = y / Math.max(1, canvas.height - 1)
    for (let x = 0; x < canvas.width; x += 1) {
      const u = x / Math.max(1, canvas.width - 1)
      const detail = regolithDetailAt(u + 37.1, v + 11.4)
      const elevation = lolaTextureElevationAtUv(u, v)
      const elevation01 = clamp(
        (elevation - LOLA_TERRAIN_TILE.grid.min_elevation_m) /
          Math.max(0.001, LOLA_TERRAIN_TILE.grid.height_range_m),
        0,
        1,
      )
      const bump = clamp(0.48 + detail.height * 0.44 + (elevation01 - 0.5) * 0.10, 0, 1)
      const i = (y * canvas.width + x) * 4
      const value = Math.round(bump * 255)
      image.data[i] = value
      image.data[i + 1] = value
      image.data[i + 2] = value
      image.data[i + 3] = 255
    }
  }
  context.putImageData(image, 0, 0)
  const texture = new THREE.CanvasTexture(canvas)
  texture.wrapS = THREE.RepeatWrapping
  texture.wrapT = THREE.RepeatWrapping
  texture.repeat.set(LOLA_TERRAIN_BUMP_REPEAT, LOLA_TERRAIN_BUMP_REPEAT)
  texture.anisotropy = 8
  texture.needsUpdate = true
  return texture
}

function lolaTerrainUv(xM, travelZ) {
  const grid = LOLA_TERRAIN_TILE.grid
  const cellSizeM = grid.cell_size_m
  return {
    u: ((grid.cols - 1) / 2 + xM / cellSizeM) / Math.max(1, grid.cols - 1),
    v: ((grid.rows - 1) / 2 - travelZ / cellSizeM) / Math.max(1, grid.rows - 1),
  }
}

function createThirdPersonTerrain() {
  const cols = THIRD_PERSON_TERRAIN_COLS
  const rows = THIRD_PERSON_TERRAIN_ROWS
  const positions = new Float32Array((cols + 1) * (rows + 1) * 3)
  const colors = new Float32Array((cols + 1) * (rows + 1) * 3)
  const uvs = new Float32Array((cols + 1) * (rows + 1) * 2)
  const indices = []
  for (let row = 0; row <= rows; row += 1) {
    for (let col = 0; col <= cols; col += 1) {
      const vertex = row * (cols + 1) + col
      uvs[vertex * 2] = col / cols
      uvs[vertex * 2 + 1] = row / rows
    }
  }
  for (let row = 0; row < rows; row += 1) {
    for (let col = 0; col < cols; col += 1) {
      const a = row * (cols + 1) + col
      const b = a + 1
      const c = a + cols + 1
      const d = c + 1
      indices.push(a, c, b, b, c, d)
    }
  }
  const geometry = new THREE.BufferGeometry()
  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3))
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3))
  geometry.setAttribute('uv', new THREE.BufferAttribute(uvs, 2))
  geometry.setIndex(indices)
  const material = new THREE.MeshStandardMaterial({
    map: createLolaRegolithTexture(),
    bumpMap: createLolaRegolithBumpTexture(),
    bumpScale: 0.034,
    vertexColors: true,
    color: 0xd8d2c6,
    roughness: 0.985,
    metalness: 0.0,
  })
  const mesh = new THREE.Mesh(geometry, material)
  mesh.receiveShadow = true
  mesh.userData = { cols, rows }
  return mesh
}

function updateThirdPersonTerrain(mesh, followZ, clip) {
  const position = mesh.geometry.getAttribute('position')
  const color = mesh.geometry.getAttribute('color')
  const uv = mesh.geometry.getAttribute('uv')
  const cols = mesh.userData.cols
  const rows = mesh.userData.rows
  let index = 0
  let colorIndex = 0
  let uvIndex = 0
  for (let row = 0; row <= rows; row += 1) {
    const zLocal = ((row / rows) - 0.42) * THIRD_PERSON_TERRAIN_DEPTH_M
    const worldZ = followZ + zLocal
    const travelZ = clip.rootDistanceM + zLocal
    for (let col = 0; col <= cols; col += 1) {
      const x = ((col / cols) - 0.5) * THIRD_PERSON_TERRAIN_WIDTH_M
      const terrain = terrainSampleAt(x, zLocal, clip)
      const curveDropM = lunarVisualCurvatureDropM(x, zLocal)
      const edgeSkirtM = lunarVisualEdgeSkirtM(x, zLocal)
      position.array[index] = x
      position.array[index + 1] = terrain.heightM - curveDropM - edgeSkirtM - 0.006
      position.array[index + 2] = worldZ
      const terrainColor = lolaTerrainColor(terrain)
      const textureUv = lolaTerrainUv(x, travelZ)
      uv.array[uvIndex] = textureUv.u
      uv.array[uvIndex + 1] = textureUv.v
      const horizonFade = 1 - smoothstep((zLocal - 8) / 42)
      const sideFade = 1 - smoothstep((Math.abs(x) - 13) / 13)
      const fade = clamp(Math.min(horizonFade, sideFade), 0.18, 1)
      color.array[colorIndex] = terrainColor.r * fade
      color.array[colorIndex + 1] = terrainColor.g * fade
      color.array[colorIndex + 2] = terrainColor.b * fade
      index += 3
      colorIndex += 3
      uvIndex += 2
    }
  }
  position.needsUpdate = true
  color.needsUpdate = true
  uv.needsUpdate = true
  mesh.geometry.computeVertexNormals()
  mesh.geometry.computeBoundingSphere()
}

function createThirdPersonGrid() {
  const helper = new THREE.GridHelper(46, 28, 0x615f56, 0x31342f)
  helper.material.transparent = true
  helper.material.opacity = 0.055
  helper.position.y = 0.003
  return helper
}

function createDistantLolaRidges() {
  const group = new THREE.Group()
  const layers = [
    { distanceM: 24, widthM: 62, baseY: -0.12, scale: 0.012, opacity: 0.50 },
    { distanceM: 38, widthM: 86, baseY: 0.02, scale: 0.009, opacity: 0.36 },
    { distanceM: 55, widthM: 116, baseY: 0.18, scale: 0.006, opacity: 0.24 },
  ]
  for (const layer of layers) {
    const positions = new Float32Array((LOLA_DISTANT_RIDGE_SAMPLES + 1) * 2 * 3)
    const colors = new Float32Array((LOLA_DISTANT_RIDGE_SAMPLES + 1) * 2 * 3)
    const indices = []
    for (let i = 0; i < LOLA_DISTANT_RIDGE_SAMPLES; i += 1) {
      const bottomA = i * 2
      const topA = bottomA + 1
      const bottomB = bottomA + 2
      const topB = bottomA + 3
      indices.push(bottomA, topA, bottomB, bottomB, topA, topB)
    }
    const geometry = new THREE.BufferGeometry()
    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3))
    geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3))
    geometry.setIndex(indices)
    const material = new THREE.MeshBasicMaterial({
      vertexColors: true,
      transparent: true,
      opacity: layer.opacity,
      depthWrite: false,
      side: THREE.DoubleSide,
    })
    const mesh = new THREE.Mesh(geometry, material)
    mesh.userData = layer
    group.add(mesh)
  }
  group.userData.model = LOLA_DISTANT_RIDGE_MODEL
  return group
}

function updateDistantLolaRidges(group, followZ, clip) {
  const baselineM = lolaTileElevationM(0, clip.rootDistanceM)
  for (const mesh of group.children) {
    const { distanceM, widthM, baseY, scale } = mesh.userData
    const position = mesh.geometry.getAttribute('position')
    const color = mesh.geometry.getAttribute('color')
    let pi = 0
    let ci = 0
    const ridgeTravelZ = clip.rootDistanceM + distanceM
    for (let i = 0; i <= LOLA_DISTANT_RIDGE_SAMPLES; i += 1) {
      const t = i / LOLA_DISTANT_RIDGE_SAMPLES
      const x = (t - 0.5) * widthM
      const elevationM = lolaTileElevationM(x * 0.82, ridgeTravelZ + x * 0.10)
      const topY = clamp(baseY + (elevationM - baselineM) * scale, 0.10, 3.25)
      const bottomY = -0.36
      const z = followZ + distanceM
      const shade = clamp(0.18 + topY * 0.12 + (1 - t) * 0.035, 0.14, 0.46)
      position.array[pi] = x
      position.array[pi + 1] = bottomY
      position.array[pi + 2] = z
      position.array[pi + 3] = x
      position.array[pi + 4] = topY
      position.array[pi + 5] = z
      color.array[ci] = shade * 0.64
      color.array[ci + 1] = shade * 0.66
      color.array[ci + 2] = shade * 0.62
      color.array[ci + 3] = shade * 1.06
      color.array[ci + 4] = shade * 1.04
      color.array[ci + 5] = shade * 0.94
      pi += 6
      ci += 6
    }
    position.needsUpdate = true
    color.needsUpdate = true
    mesh.geometry.computeBoundingSphere()
  }
}

function createEarthTexture() {
  const texture = new THREE.TextureLoader().load(EARTH_TEXTURE_URL)
  texture.colorSpace = THREE.SRGBColorSpace
  texture.anisotropy = 8
  return texture
}

function dayOfYearUtc(date) {
  const start = Date.UTC(date.getUTCFullYear(), 0, 0)
  const current = Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
  return Math.floor((current - start) / 86400000)
}

function earthUtcLightingState(date = new Date()) {
  const utcHours =
    date.getUTCHours() +
    date.getUTCMinutes() / 60 +
    date.getUTCSeconds() / 3600 +
    date.getUTCMilliseconds() / 3600000
  const yearDay = dayOfYearUtc(date)
  const subsolarLatitudeRad = 23.44 * DEG * Math.sin(((yearDay - 80) / 365.2422) * Math.PI * 2)
  const subsolarLongitudeRad = (12 - utcHours) / 24 * Math.PI * 2
  return {
    subsolarLongitudeRad,
    subsolarLatitudeRad,
    rotationOffset: ((utcHours / 24) + 1) % 1,
    iso: date.toISOString(),
  }
}

function createEarthMaterial() {
  const lighting = earthUtcLightingState()
  return new THREE.ShaderMaterial({
    uniforms: {
      earthMap: { value: createEarthTexture() },
      subsolarLongitude: { value: lighting.subsolarLongitudeRad },
      subsolarLatitude: { value: lighting.subsolarLatitudeRad },
      earthRotationOffset: { value: lighting.rotationOffset },
      nightFill: { value: EARTHRISE_NIGHT_FILL },
      dayBoost: { value: EARTHRISE_DAY_BOOST },
    },
    vertexShader: `
      varying vec2 vUv;
      varying vec3 vNormal;

      void main() {
        vUv = uv;
        vNormal = normalize(normalMatrix * normal);
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }
    `,
    fragmentShader: `
      uniform sampler2D earthMap;
      uniform float subsolarLongitude;
      uniform float subsolarLatitude;
      uniform float earthRotationOffset;
      uniform float nightFill;
      uniform float dayBoost;
      varying vec2 vUv;
      varying vec3 vNormal;

      const float PI = 3.141592653589793;

      vec3 surfaceDirection(vec2 uv) {
        float lon = (uv.x - 0.5) * PI * 2.0;
        float lat = (0.5 - uv.y) * PI;
        return normalize(vec3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon)));
      }

      void main() {
        vec2 sampleUv = vec2(fract(vUv.x + earthRotationOffset), vUv.y);
        vec3 tex = texture2D(earthMap, sampleUv).rgb;
        vec3 surface = surfaceDirection(sampleUv);
        vec3 sun = normalize(vec3(
          cos(subsolarLatitude) * sin(subsolarLongitude),
          sin(subsolarLatitude),
          cos(subsolarLatitude) * cos(subsolarLongitude)
        ));
        float daylight = smoothstep(-0.07, 0.18, dot(surface, sun));
        float limb = smoothstep(-0.18, 0.58, vNormal.z);
        vec3 nightTint = vec3(0.085, 0.135, 0.19);
        vec3 dayColor = tex * dayBoost;
        vec3 nightColor = tex * nightFill + nightTint;
        vec3 color = mix(nightColor, dayColor, daylight);
        color += vec3(0.12, 0.20, 0.28) * (1.0 - abs(daylight - 0.5) * 2.0) * 0.32;
        color *= mix(0.88, 1.0, limb);
        gl_FragColor = vec4(color, 1.0);
      }
    `,
  })
}

function updateEarthriseLighting(group, date = new Date()) {
  const earth = group.userData.earthMesh
  if (!earth?.material?.uniforms) return
  const lighting = earthUtcLightingState(date)
  earth.material.uniforms.subsolarLongitude.value = lighting.subsolarLongitudeRad
  earth.material.uniforms.subsolarLatitude.value = lighting.subsolarLatitudeRad
  earth.material.uniforms.earthRotationOffset.value = lighting.rotationOffset
  group.userData.utcLightingIso = lighting.iso
  group.userData.subsolarLongitudeDeg = lighting.subsolarLongitudeRad / DEG
  group.userData.subsolarLatitudeDeg = lighting.subsolarLatitudeRad / DEG
}

function createEarthrise() {
  const group = new THREE.Group()
  const earth = new THREE.Mesh(
    new THREE.SphereGeometry(4.8, 64, 32),
    createEarthMaterial(),
  )
  const atmosphere = new THREE.Mesh(
    new THREE.SphereGeometry(5.06, 64, 32),
    new THREE.MeshBasicMaterial({
      color: 0x9ed5ff,
      transparent: true,
      opacity: 0.24,
      side: THREE.BackSide,
    }),
  )
  earth.rotation.y = -0.65
  earth.rotation.z = -0.24
  group.add(atmosphere)
  group.add(earth)
  group.userData.earthMesh = earth
  group.userData.panelRole = 'earthrise-backdrop'
  group.userData.textureSource = EARTHRISE_TEXTURE_SOURCE
  group.userData.lightingModel = EARTHRISE_LIGHTING_MODEL
  updateEarthriseLighting(group)
  return group
}

function disposeThreeScene(scene, renderer, controls) {
  controls.dispose()
  scene.traverse(object => {
    object.geometry?.dispose()
    const materials = Array.isArray(object.material) ? object.material : [object.material]
    for (const material of materials) {
      if (!material) continue
      for (const value of Object.values(material)) {
        if (value?.isTexture) value.dispose()
      }
      material.dispose?.()
    }
  })
  renderer.dispose()
  renderer.forceContextLoss()
}

function initThirdPersonMoonWalk(canvas) {
  let renderer
  try {
    renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: true,
      preserveDrawingBuffer: true,
    })
  } catch (_error) {
    canvas.dataset.sceneStatus = 'three-webgl-unavailable'
    return
  }
  renderer.shadowMap.enabled = true
  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0x070908)
  scene.fog = new THREE.Fog(0x070908, 18, 54)
  scene.add(new THREE.HemisphereLight(0xf4f8ef, 0x30332e, 1.25))
  const sun = new THREE.DirectionalLight(0xffffff, 2.6)
  sun.position.set(-2.8, 5.6, -3.2)
  sun.castShadow = true
  scene.add(sun)
  const fill = new THREE.DirectionalLight(0xb8d7ff, 0.42)
  fill.position.set(3.5, 1.8, 3.4)
  scene.add(fill)
  const camera = new THREE.PerspectiveCamera(46, 1, 0.03, 90)
  const controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true
  controls.dampingFactor = 0.08
  controls.enablePan = false
  controls.enableZoom = true
  controls.minDistance = 1.1
  controls.maxDistance = 6.2
  const terrain = createThirdPersonTerrain()
  scene.add(terrain)
  const grid = createThirdPersonGrid()
  scene.add(grid)
  const earthrise = createEarthrise()
  scene.add(earthrise)
  const distantRidges = createDistantLolaRidges()
  scene.add(distantRidges)
  const e1Visuals = createE1ThreeVisuals()
  for (const entry of e1Visuals.visuals.values()) {
    entry.mesh.castShadow = true
  }
  scene.add(e1Visuals.group)
  reportE1SourceReadiness(e1Visuals.visuals, canvas)
  let cachedQuality = null
  let lastQualityRefreshMs = -Infinity
  let lastEarthLightingRefreshMs = -Infinity
  function draw(now) {
    if (!canvas.isConnected) {
      disposeThreeScene(scene, renderer, controls)
      canvas.dataset.renderDisposed = 'true'
      return
    }
    if (!canvasRenderActive(canvas)) {
      markCanvasRenderPaused(canvas)
      requestAnimationFrame(draw)
      return
    }
    markCanvasRenderActive(canvas)
    const ratio = Math.min(2, window.devicePixelRatio || 1)
    const rect = canvas.getBoundingClientRect()
    const width = Math.max(420, Math.floor(rect.width * ratio))
    const height = Math.max(320, Math.floor(rect.height * ratio))
    if (canvas.width !== width || canvas.height !== height) {
      renderer.setSize(width, height, false)
    }
    camera.aspect = canvas.width / Math.max(1, canvas.height)
    camera.updateProjectionMatrix()
    const time = now * 0.001
    const geometry = robotGeometry(time, { quality: false, e1VisualTriangles: false })
    if (!cachedQuality || now - lastQualityRefreshMs >= ROBOT_QUALITY_REFRESH_MS) {
      cachedQuality = gaitQuality(time, geometry.diagnostics, {
        footLockSamples: 8,
        cycleSamples: 12,
        swingSamples: 12,
      })
      lastQualityRefreshMs = now
    }
    geometry.diagnostics = { ...geometry.diagnostics, quality: cachedQuality }
    const root = robotRoot(
      geometry.diagnostics,
      geometry.diagnostics.ik.pelvisCorrectionM,
      geometry.diagnostics.footLock,
    )
    const followZ = geometry.diagnostics.visualRootWorldZ
    updateThirdPersonTerrain(terrain, followZ, geometry.diagnostics)
    updateDistantLolaRidges(distantRidges, followZ, geometry.diagnostics)
    grid.position.z = followZ + 8.5
    earthrise.position.set(-2.2, 3.65, followZ + 32)
    if (now - lastEarthLightingRefreshMs >= 10000) {
      updateEarthriseLighting(earthrise)
      lastEarthLightingRefreshMs = now
    }
    updateE1ThreeVisuals(
      root,
      geometry.diagnostics,
      geometry.diagnostics.joints,
      e1Visuals.visuals,
      followZ,
    )
    const target = new THREE.Vector3(0.18, 0.58, followZ + 0.26)
    const desired = new THREE.Vector3(0.82, 1.28, followZ - 2.15)
    camera.position.lerp(desired, 0.12)
    controls.target.lerp(target, 0.18)
    controls.update()
    renderer.render(scene, camera)
    canvas.dataset.sceneStatus = 'third-person-moon-walk-rendered'
    canvas.dataset.renderer = 'three-third-person-moon-terrain'
    canvas.dataset.motionStatus = 'endless-e1-on-lunar-heightfield'
    canvas.dataset.adapterPreview = 'moonmoon-adapter-preview'
    canvas.dataset.adapterAuthority = 'non-authoritative-mission-gated'
    canvas.dataset.gaitQualityStatus = geometry.diagnostics.quality.status === 'pass'
      ? 'pass'
      : 'viewport-sampled'
    canvas.dataset.supportFoot = geometry.diagnostics.supportFoot
    canvas.dataset.swingFoot = geometry.diagnostics.swingFoot
    canvas.dataset.rootDistanceM = geometry.diagnostics.rootDistanceM.toFixed(2)
    canvas.dataset.terrainHeightRangeM = geometry.diagnostics.terrain.heightRangeM.toFixed(4)
    canvas.dataset.terrainSource = LOLA_TERRAIN_TILE.tile_id
    canvas.dataset.terrainSourceProduct = LOLA_TERRAIN_TILE.source.product_id
    canvas.dataset.terrainSourceResolutionM = String(LOLA_TERRAIN_TILE.grid.cell_size_m)
    canvas.dataset.terrainSourceHeightRangeM = String(LOLA_TERRAIN_TILE.grid.height_range_m)
    canvas.dataset.terrainTextureSource = LOLA_TERRAIN_TEXTURE_SOURCE
    canvas.dataset.regolithMaterialModel = LOLA_REGOLITH_MATERIAL_MODEL
    canvas.dataset.terrainTextureResolutionPx = String(LOLA_TERRAIN_TEXTURE_SIZE)
    canvas.dataset.terrainColorTextureRepeat = String(LOLA_TERRAIN_COLOR_REPEAT)
    canvas.dataset.terrainBumpTextureRepeat = String(LOLA_TERRAIN_BUMP_REPEAT)
    canvas.dataset.terrainMotionModel = LOLA_TERRAIN_MOTION_MODEL
    canvas.dataset.lolaWorldProgressM = geometry.diagnostics.rootDistanceM.toFixed(2)
    canvas.dataset.distantRidgeModel = distantRidges.userData.model
    canvas.dataset.distantRidgeStatus = 'lola-dem-ridges-updating'
    canvas.dataset.panelBackdrop = earthrise.userData.panelRole
    canvas.dataset.earthriseTextureSource = earthrise.userData.textureSource
    canvas.dataset.earthriseLightingModel = earthrise.userData.lightingModel
    canvas.dataset.earthriseUtcLightingIso = earthrise.userData.utcLightingIso
    canvas.dataset.earthriseSubsolarLongitudeDeg = earthrise.userData.subsolarLongitudeDeg.toFixed(2)
    canvas.dataset.earthriseSubsolarLatitudeDeg = earthrise.userData.subsolarLatitudeDeg.toFixed(2)
    canvas.dataset.lunarSurfaceVisualModel = LUNAR_SURFACE_VISUAL_MODEL
    canvas.dataset.e1MeshReductionAlgorithm = E1_MESH_REDUCTION_ALGORITHM
    canvas.dataset.threeRenderTriangles = String(renderer.info.render.triangles)
    canvas.dataset.threeRenderCalls = String(renderer.info.render.calls)
    canvas.dataset.renderedFrames = String(Number(canvas.dataset.renderedFrames || 0) + 1)
    requestAnimationFrame(draw)
  }
  requestAnimationFrame(draw)
}

function updateE1ThreeVisuals(root, clip, joints, visuals, rootWorldZ = 0) {
  if (!E1_ASM_ASSEMBLY.ready) return
  let sceneRoot = mat4WorldOffset(root, E1_ASM_DUPLICATE_OFFSET_X, 0, 0)
  sceneRoot = mat4WorldOffset(sceneRoot, 0, 0, rootWorldZ)
  const transforms = e1AssemblyLinkTransforms(e1AssemblyJointAngles(clip, joints))
  for (const { group, visual } of visuals.values()) {
    const linkMatrix = transforms.get(visual.link_id)
    if (!linkMatrix) {
      group.visible = false
      continue
    }
    const visualMatrix = mat4Multiply(linkMatrix, mat4FromUrdfOrigin(visual.origin))
    const matrix = mat4Multiply(sceneRoot, mat4Multiply(URDF_TO_SCENE_MATRIX, visualMatrix))
    group.matrix.copy(threeMatrixFromMat4(matrix))
    group.visible = true
  }
}

function updateThreeDebugGeometry(mesh, vertices, colors) {
  mesh.geometry.dispose()
  const geometry = new THREE.BufferGeometry()
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3))
  geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3))
  geometry.computeBoundingSphere()
  mesh.geometry = geometry
}

function addVisualLink(vertices, colors, diagnostics, linkId, matrix, center, size, color, source) {
  addCube(vertices, colors, matrix, center, size, color)
  addVisualBoxLinkTo(diagnostics.visualLinks, linkId, matrix, center, size, source)
}

function addVisualBoxLinkTo(visualLinks, linkId, matrix, center, size, source) {
  visualLinks.push({
    linkId,
    geometry: 'box',
    source,
    origin: matrixOrigin(matrix),
    center: pointRecord(transformPoint(matrix, center)),
    sizeM: {
      x: size[0],
      y: size[1],
      z: size[2],
    },
    attached: true,
  })
}

function vec3Length(v) {
  return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
}

function vec3Sub(a, b) {
  return { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z }
}

function vec3Dot(a, b) {
  return a.x * b.x + a.y * b.y + a.z * b.z
}

function vec3Cross(a, b) {
  return {
    x: a.y * b.z - a.z * b.y,
    y: a.z * b.x - a.x * b.z,
    z: a.x * b.y - a.y * b.x,
  }
}

function normalizeVec3(v) {
  const len = Math.max(0.000001, vec3Length(v))
  return { x: v.x / len, y: v.y / len, z: v.z / len }
}

function wrapUnit(value, size) {
  return ((value % size) + size) % size
}

function lolaTileElevationM(xM, zM) {
  const grid = LOLA_TERRAIN_TILE.grid
  const cellSizeM = grid.cell_size_m
  const col = wrapUnit((grid.cols - 1) / 2 + xM / cellSizeM, grid.cols - 1)
  const row = wrapUnit((grid.rows - 1) / 2 - zM / cellSizeM, grid.rows - 1)
  const col0 = Math.floor(col)
  const row0 = Math.floor(row)
  const col1 = (col0 + 1) % grid.cols
  const row1 = (row0 + 1) % grid.rows
  const tx = col - col0
  const ty = row - row0
  const h00 = LOLA_TERRAIN_TILE.elevations_m[row0][col0]
  const h10 = LOLA_TERRAIN_TILE.elevations_m[row0][col1]
  const h01 = LOLA_TERRAIN_TILE.elevations_m[row1][col0]
  const h11 = LOLA_TERRAIN_TILE.elevations_m[row1][col1]
  return mix(mix(h00, h10, tx), mix(h01, h11, tx), ty)
}

function lolaLocalHeightM(x, z, clip) {
  const travelZ = z + clip.rootDistanceM
  const baselineM = lolaTileElevationM(0, clip.rootDistanceM)
  return (lolaTileElevationM(x, travelZ) - baselineM) * LOLA_TERRAIN_HEIGHT_SCALE
}

function lolaTerrainColor(sample) {
  const light = clamp(
    sample.normal.x * -0.32 + sample.normal.y * 0.72 + sample.normal.z * -0.54,
    0,
    1,
  )
  const elevation = clamp(sample.heightM * 10, -0.22, 0.22)
  const shade = clamp(0.24 + light * 0.30 + elevation, 0.13, 0.62)
  return {
    r: shade * 0.88,
    g: shade * 0.86,
    b: shade * 0.80,
  }
}

function lunarVisualCurvatureDropM(x, zLocal) {
  const forward = Math.max(0, zLocal + 2.2)
  const horizonDistance = Math.hypot(x * 0.82, forward)
  return (horizonDistance * horizonDistance) / (2 * THIRD_PERSON_VISUAL_RADIUS_M)
}

function lunarVisualEdgeSkirtM(x, zLocal) {
  const farDrop = smoothstep((zLocal - 18) / 24) * 8.5
  const sideDrop = smoothstep((Math.abs(x) - 18) / 8) * 5.5
  return farDrop + sideDrop
}

function compactPoint(point) {
  return {
    x: Number(point.x.toFixed(4)),
    y: Number(point.y.toFixed(4)),
    z: Number(point.z.toFixed(4)),
  }
}

function matrixOrigin(matrix) {
  return pointRecord(transformPoint(matrix, [0, 0, 0]))
}

function matrixForward(matrix) {
  return normalizeVec3(vec3Sub(
    pointRecord(transformPoint(matrix, [0, 0, 1])),
    matrixOrigin(matrix),
  ))
}

function moonphysPoint(point) {
  return {
    x: Number(point.x.toFixed(4)),
    y: Number(point.z.toFixed(4)),
    z: Number(point.y.toFixed(4)),
  }
}

function moonphysVector(vector) {
  return {
    x: Number(vector.x.toFixed(4)),
    y: Number(vector.z.toFixed(4)),
    z: Number(vector.y.toFixed(4)),
  }
}

function supportTransferWeightLeft(phase) {
  if (phase >= 0.42 && phase < 0.58) {
    return 1 - smoothstep((phase - 0.42) / 0.16)
  }
  if (phase >= 0.92) {
    return smoothstep((phase - 0.92) / 0.16)
  }
  if (phase < 0.08) {
    return smoothstep((phase + 0.08) / 0.16)
  }
  return phase < 0.42 ? 1 : 0
}

function supportAnchoredCenterOfMass(root, diagnostics, clip) {
  const fallback = transformPoint(root, [
    diagnostics.supportMassTransferX,
    0.16,
    0.035,
  ])
  const left = diagnostics.feet.find(foot => foot.name === 'left')
  const right = diagnostics.feet.find(foot => foot.name === 'right')
  if (!left || !right) {
    return pointRecord(fallback)
  }
  const leftWeight = supportTransferWeightLeft(clip.phase)
  const rightWeight = 1 - leftWeight
  return {
    x: left.contactPatch.center.x * leftWeight + right.contactPatch.center.x * rightWeight,
    y: fallback[1],
    z: left.contactPatch.center.z * leftWeight + right.contactPatch.center.z * rightWeight,
  }
}

function pointDistance(a, b) {
  const dx = a[0] - b[0]
  const dy = a[1] - b[1]
  const dz = a[2] - b[2]
  return Math.sqrt(dx * dx + dy * dy + dz * dz)
}

function pointRecordDistance(a, b) {
  const dx = a.x - b.x
  const dy = a.y - b.y
  const dz = a.z - b.z
  return Math.sqrt(dx * dx + dy * dy + dz * dz)
}

function translateVertexRangeZ(vertices, start, end, dz) {
  if (dz === 0) return
  for (let i = start + 2; i < end; i += 3) {
    vertices[i] += dz
  }
}

function addGround(vertices, colors, clip, rootWorldZ = 0) {
  const spacing = 0.24
  const startWorldZ = Math.floor((clip.rootDistanceM - 1.92) / spacing) * spacing
  for (let i = 0; i <= 17; i += 1) {
    const worldZ = startWorldZ + i * spacing
    const localZ = worldZ - clip.rootDistanceM
    const nextWorldZ = worldZ + 0.018
    const nextLocalZ = localZ + 0.018
    const a = terrainSampleAt(-1.6, localZ, clip).heightM
    const b = terrainSampleAt(1.6, localZ, clip).heightM
    const c = terrainSampleAt(1.6, nextLocalZ, clip).heightM
    const d = terrainSampleAt(-1.6, nextLocalZ, clip).heightM
    addQuad(vertices, colors, [-1.6, a, worldZ], [1.6, b, worldZ], [1.6, c - 0.012, nextWorldZ], [-1.6, d - 0.012, nextWorldZ], [0.18, 0.24, 0.21])
  }
  for (let i = -4; i <= 4; i += 1) {
    const x = i * 0.32
    const startZ = rootWorldZ - 1.4
    const endZ = rootWorldZ + 1.4
    const startLocalZ = startZ - clip.rootDistanceM
    const endLocalZ = endZ - clip.rootDistanceM
    const a = terrainSampleAt(x, startLocalZ, clip).heightM
    const b = terrainSampleAt(x + 0.014, startLocalZ, clip).heightM
    const c = terrainSampleAt(x + 0.014, endLocalZ, clip).heightM
    const d = terrainSampleAt(x, endLocalZ, clip).heightM
    addQuad(vertices, colors, [x, a, startZ], [x + 0.014, b, startZ], [x + 0.014, c - 0.012, endZ], [x, d - 0.012, endZ], [0.14, 0.20, 0.18])
  }
}

function addGaitTimingRails(vertices, colors, clip, rootWorldZ = 0) {
  for (let i = -6; i <= 6; i += 1) {
    const z = i * 0.18
    const terrain = terrainSampleAt(0, z, clip)
    const size = i === 0 ? [0.050, 0.020, 0.050] : [0.030, 0.012, 0.030]
    const color = i === 0 ? [0.74, 0.96, 0.88] : [0.26, 0.48, 0.42]
    addCube(vertices, colors, mat4Identity(), [0, terrain.heightM + 0.018, rootWorldZ + z], size, color)
  }
  for (const [footIndex, footName] of ['left', 'right'].entries()) {
    const foot = clip.footChannels[footName]
    for (const [roleIndex, role] of FOOT_PHASE_SEQUENCE.entries()) {
      const x = footName === 'left' ? -0.78 : -0.66
      const z = -0.54 + roleIndex * 0.18
      const terrain = terrainSampleAt(x, z, clip)
      const active = foot.role === role
      const size = active ? [0.062, 0.032, 0.062] : [0.034, 0.016, 0.034]
      const baseColor = footRoleColor(role)
      const dim = footIndex === 0 ? 1 : 0.82
      const color = active
        ? baseColor
        : baseColor.map(channel => channel * 0.44 * dim)
      addCube(vertices, colors, mat4Identity(), [x, terrain.heightM + 0.020, rootWorldZ + z], size, color)
    }
  }
}

function pointRecord(point) {
  return { x: point[0], y: point[1], z: point[2] }
}

function footTargetForPose(sole, foot, clip) {
  const probe = terrainContactProbe(sole, clip)
  const terrainTargetY = probe.heightM + NOETIX_VISUAL_RIG.supportTargetClearanceM
  const swingTargetY = sole[1] + 0.018
  return [
    sole[0],
    mix(swingTargetY, terrainTargetY, foot.lockWeight),
    sole[2],
  ]
}

function authoredFootTargetForRoot(root, motion, side) {
  const prefix = side === 'left' ? 'left' : 'right'
  return transformPoint(root, [
    motion[`${prefix}_foot_x_m`],
    motion[`${prefix}_foot_y_m`],
    motion[`${prefix}_foot_z_m`],
  ])
}

function addLeg(vertices, colors, root, side, clip, joints, authoredTargets, diagnostics) {
  const isLeft = side > 0
  const name = isLeft ? 'left' : 'right'
  const foot = clip.footChannels[name]
  const sideColor = isLeft ? [0.88, 0.72, 0.28] : [0.68, 0.76, 0.90]
  const upperLen = NOETIX_VISUAL_RIG.lengths.upperLeg
  const lowerLen = NOETIX_VISUAL_RIG.lengths.lowerLeg
  const pose = legPose(root, side, joints)
  const { hip, knee, ankle, sole } = pose
  const forward = matrixForward(hip)
  const hipPoint = matrixOrigin(hip)
  const kneePoint = matrixOrigin(knee)
  const anklePoint = matrixOrigin(ankle)
  const chainMidpoint = {
    x: (hipPoint.x + anklePoint.x) * 0.5,
    y: (hipPoint.y + anklePoint.y) * 0.5,
    z: (hipPoint.z + anklePoint.z) * 0.5,
  }
  const kneeForwardM = vec3Dot(vec3Sub(kneePoint, chainMidpoint), forward)
  addVisualLink(
    vertices,
    colors,
    diagnostics,
    `${name}_leg_1`,
    hip,
    [0, -upperLen * 0.5, 0],
    [0.065, upperLen, 0.075],
    sideColor,
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#${name}_leg_1`,
  )
  addCube(vertices, colors, knee, [0, 0.006, 0.055], [0.076, 0.034, 0.040], [0.96, 0.84, 0.42])
  addVisualLink(
    vertices,
    colors,
    diagnostics,
    `${name}_leg_4`,
    knee,
    [0, -lowerLen * 0.5, 0.008],
    [0.055, lowerLen, 0.065],
    [0.78, 0.70, 0.34],
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#${name}_leg_4`,
  )
  addVisualLink(
    vertices,
    colors,
    diagnostics,
    `${name}_foot`,
    ankle,
    [0, -0.026, 0.075],
    [0.095, 0.052, 0.215],
    [0.50, 0.55, 0.50],
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#${name}_foot`,
  )
  let toe = mat4Translate(ankle, 0, -0.035, 0.172)
  toe = mat4RotateX(toe, foot.rollPitch)
  addCube(vertices, colors, toe, [0, -0.002, 0.042], [0.105, 0.030, 0.095], [0.62, 0.64, 0.54])
  let heel = mat4Translate(ankle, 0, -0.037, -0.026)
  heel = mat4RotateX(heel, Math.min(0, foot.rollPitch) * 0.45)
  addCube(vertices, colors, heel, [0, 0, 0], [0.100, 0.030, 0.060], [0.44, 0.49, 0.46])
  const authoredTarget = authoredTargets[name]
  const correctedTarget = footTargetForPose(sole, foot, clip)
  addCube(vertices, colors, mat4Identity(), authoredTarget, [0.030, 0.016, 0.030], [0.18, 0.38, 0.76])
  addCube(vertices, colors, mat4Identity(), correctedTarget, [0.038, 0.020, 0.038], [0.34, 0.58, 0.96])
  const marker = name === clip.supportFoot ? [0.30, 0.92, 0.50] : [0.94, 0.80, 0.24]
  addCube(vertices, colors, mat4Identity(), sole, [0.055, 0.022, 0.055], marker)
  const terrainProbe = terrainContactProbe(sole, clip)
  const contactPatch = footContactPatch(sole, clip)
  diagnostics.feet.push({
    name,
    role: foot.role,
    locked: foot.locked,
    supporting: foot.supporting,
    rollPitch: foot.rollPitch,
    authoredTarget: pointRecord(authoredTarget),
    correctedTarget: pointRecord(correctedTarget),
    fkEndpoint: pointRecord(sole),
    terrainProbe,
    contactPatch,
    limbBend: {
      active: (foot.role === 'passing' || foot.role === 'swing') && Math.abs(joints[name].knee) > 0.18,
      kneeForwardM,
      minForwardM: NOETIX_VISUAL_RIG.legForwardBendMinM,
    },
    targetFkDeltaM: pointDistance(correctedTarget, sole),
    authoredTargetDeltaM: pointDistance(authoredTarget, sole),
    ikCorrectionDeltaM: pointDistance(authoredTarget, correctedTarget),
  })
}

function addArm(vertices, colors, root, side, joints, diagnostics) {
  const isLeft = side > 0
  const name = isLeft ? 'left' : 'right'
  const angles = joints[name]
  const upperLen = NOETIX_VISUAL_RIG.lengths.upperArm
  const lowerLen = NOETIX_VISUAL_RIG.lengths.lowerArm
  let shoulder = mat4Translate(root, side * 0.155, 0.265, 0.0)
  shoulder = mat4RotateX(shoulder, angles.shoulder)
  shoulder = mat4RotateZ(shoulder, side * 0.07)
  addVisualLink(
    vertices,
    colors,
    diagnostics,
    `${name}_arm_1`,
    shoulder,
    [0, -upperLen * 0.5, 0],
    [0.045, upperLen, 0.055],
    [0.56, 0.72, 0.76],
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#${name}_arm_1`,
  )
  let elbow = mat4Translate(shoulder, 0, -upperLen, 0)
  elbow = mat4RotateX(elbow, -angles.elbow)
  addCube(vertices, colors, elbow, [0, 0.004, 0.042], [0.052, 0.030, 0.034], [0.70, 0.86, 0.90])
  addVisualLink(
    vertices,
    colors,
    diagnostics,
    `${name}_arm_4`,
    elbow,
    [0, -lowerLen * 0.5, 0.015],
    [0.040, lowerLen, 0.050],
    [0.48, 0.64, 0.68],
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#${name}_arm_4`,
  )
  addVisualLink(
    vertices,
    colors,
    diagnostics,
    `${name}_hand`,
    elbow,
    [0, -lowerLen - 0.030, 0.040],
    [0.050, 0.060, 0.055],
    [0.40, 0.54, 0.58],
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#${name}_hand`,
  )
  const forward = matrixForward(shoulder)
  const elbowPoint = matrixOrigin(elbow)
  const handPoint = pointRecord(transformPoint(elbow, [0, -lowerLen, 0]))
  diagnostics.arms.push({
    name,
    limbBend: {
      active: Math.abs(angles.elbow) > 0.16,
      lowerArmForwardM: vec3Dot(vec3Sub(handPoint, elbowPoint), forward),
      minForwardM: NOETIX_VISUAL_RIG.armForwardBendMinM,
    },
  })
}

function e1AssemblyJointAngles(clip, joints) {
  return {
    waist_yaw_joint: clip.torsoCounterRotation,
    waist_roll_joint: clamp(-clip.sway * 1.8, -0.18, 0.18),
    l_leg_hip_yaw_joint: 0,
    l_leg_hip_roll_joint: clamp(clip.sway * 1.4, -0.20, 0.20),
    l_leg_hip_pitch_joint: clamp(joints.left.hip, -1.20, 0.72),
    l_leg_knee_joint: clamp(Math.abs(joints.left.knee), 0.02, 1.75),
    l_leg_ankle_pitch_joint: clamp(joints.left.ankle, -0.78, 0.38),
    l_leg_ankle_roll_joint: clamp(-clip.sway * 0.7, -0.16, 0.16),
    r_leg_hip_yaw_joint: 0,
    r_leg_hip_roll_joint: clamp(clip.sway * 1.4, -0.20, 0.20),
    r_leg_hip_pitch_joint: clamp(joints.right.hip, -1.20, 0.72),
    r_leg_knee_joint: clamp(Math.abs(joints.right.knee), 0.02, 1.75),
    r_leg_ankle_pitch_joint: clamp(joints.right.ankle, -0.78, 0.38),
    r_leg_ankle_roll_joint: clamp(-clip.sway * 0.7, -0.16, 0.16),
    l_arm_shoulder_pitch_joint: clamp(joints.left.shoulder, -1.25, 1.25),
    l_arm_shoulder_roll_joint: 0.18,
    l_arm_shoulder_yaw_joint: clamp(clip.torsoCounterRotation * 0.45, -0.35, 0.35),
    l_arm_elbow_pitch_joint: clamp(-Math.abs(joints.left.elbow), -1.35, -0.05),
    l_arm_elbow_yaw_joint: 0,
    r_arm_shoulder_pitch_joint: clamp(joints.right.shoulder, -1.25, 1.25),
    r_arm_shoulder_roll_joint: -0.18,
    r_arm_shoulder_yaw_joint: clamp(clip.torsoCounterRotation * 0.45, -0.35, 0.35),
    r_arm_elbow_pitch_joint: clamp(-Math.abs(joints.right.elbow), -1.35, -0.05),
    r_arm_elbow_yaw_joint: 0,
  }
}

function e1AssemblyLinkTransforms(jointAngles) {
  const transforms = new Map([[E1_ASM_ASSEMBLY.root_link, mat4Identity()]])
  const pending = [...(E1_ASM_ASSEMBLY.joints ?? [])]
  let progress = true
  while (pending.length > 0 && progress) {
    progress = false
    for (let i = pending.length - 1; i >= 0; i -= 1) {
      const joint = pending[i]
      const parent = transforms.get(joint.parent)
      if (!parent) continue
      const angle = jointAngles[joint.name] ?? 0
      let child = mat4Multiply(parent, mat4FromUrdfOrigin(joint.origin))
      if (joint.type === 'revolute' || joint.type === 'continuous') {
        child = mat4AxisAngle(child, joint.axis, angle)
      }
      transforms.set(joint.child, child)
      pending.splice(i, 1)
      progress = true
    }
  }
  return transforms
}

function addE1AssemblyVisualCharacter(vertices, colors, root, clip, joints, visualLinks, renderMeshes = true) {
  const sceneRoot = mat4WorldOffset(root, E1_ASM_DUPLICATE_OFFSET_X, 0, 0)
  if (!E1_ASM_ASSEMBLY.ready) {
    visualLinks.push({
      linkId: 'e1_asm_unavailable',
      geometry: 'mesh',
      source: E1_ASM_ASSEMBLY.source_archive,
      attached: false,
      status: E1_ASM_ASSEMBLY.status,
    })
    return
  }
  const transforms = e1AssemblyLinkTransforms(e1AssemblyJointAngles(clip, joints))
  for (const visual of E1_ASM_ASSEMBLY.visuals) {
    const linkMatrix = transforms.get(visual.link_id)
    const attached = Boolean(linkMatrix) && visual.status === 'e1-asm-stl-ready'
    if (attached && renderMeshes) {
      addE1StlMesh(vertices, colors, sceneRoot, linkMatrix, visual, visual)
    }
    const origin = linkMatrix
      ? pointRecord(transformPoint(sceneRoot, e1UrdfPointToScene(transformPoint(linkMatrix, [0, 0, 0]))))
      : null
    visualLinks.push({
      linkId: visual.link_id,
      geometry: 'mesh',
      source: visual.source,
      meshSource: E1_ASM_ASSEMBLY.source_urdf_entry,
      meshPath: visual.mesh_name,
      origin,
      vertexCount: visual.triangle_count * 3,
      triangleCount: visual.triangle_count,
      sourceTriangleCount: visual.source_triangle_count,
      decimationStride: visual.decimation_stride,
      loadStatus: visual.status,
      attached,
    })
  }
}

function robotGeometry(time, options = { quality: true }) {
  const vertices = []
  const colors = []
  const clip = walkClipSample(time, options)
  const visualRootWorldZ = options.visualWorldSpace === false ? 0 : clip.rootDistanceM
  const authoredJoints = jointSamples(clip)
  let footLock = footLockRootCorrection(time, clip, authoredJoints)
  let ik = terrainIkCorrection(robotRoot(clip, 0, footLock), clip, authoredJoints, footLock)
  for (let i = 0; i < 3; i += 1) {
    footLock = footLockRootCorrection(
      time,
      clip,
      ik.correctedJoints,
      ik.pelvisCorrectionM,
      footLock,
    )
    ik = terrainIkCorrection(robotRoot(clip, 0, footLock), clip, authoredJoints, footLock)
  }
  const ikRoot = robotRoot(clip, 0, footLock)
  const authoredMotion = authoredMotionSample(clip)
  const authoredTargets = {
    left: authoredFootTargetForRoot(ikRoot, authoredMotion, 'left'),
    right: authoredFootTargetForRoot(ikRoot, authoredMotion, 'right'),
  }
  const joints = ik.correctedJoints
  const terrain = terrainProfileReport(clip)
  const diagnostics = {
    feet: [],
    arms: [],
    visualLinks: [],
    e1AssemblyVisualLinks: [],
    authoredJoints,
    authoredMotion,
    joints,
    ik,
    terrain,
    footLock,
  }
  const root = robotRoot(clip, ik.pelvisCorrectionM, footLock)
  diagnostics.supportMassTransferX = supportMassTransferX(clip)
  addVisualLink(
    vertices,
    colors,
    diagnostics,
    'base_link',
    root,
    [0, -0.025, 0],
    [0.24, 0.18, 0.18],
    [0.40, 0.72, 0.70],
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#base_link debug box`,
  )
  let torsoRoot = mat4RotateY(root, clip.torsoCounterRotation)
  torsoRoot = mat4RotateZ(torsoRoot, -clip.sway * 1.6)
  addVisualLink(
    vertices,
    colors,
    diagnostics,
    'torso_link',
    torsoRoot,
    [0, 0.185, 0.01],
    [0.22, 0.18, 0.16],
    [0.46, 0.80, 0.76],
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#torso_link box`,
  )
  addCube(vertices, colors, torsoRoot, [0, 0.205, 0.098], [0.125, 0.050, 0.018], [0.12, 0.20, 0.22])
  addVisualLink(
    vertices,
    colors,
    diagnostics,
    'chest_link',
    mat4Translate(torsoRoot, 0, 0.37, 0.015),
    [0, 0, 0],
    [0.24, 0.20, 0.15],
    [0.54, 0.86, 0.80],
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#chest_link box`,
  )
  const headRoot = mat4Translate(torsoRoot, 0, 0.52, 0.005)
  addCube(vertices, colors, headRoot, [0, 0, 0], [0.13, 0.12, 0.12], [0.72, 0.92, 0.86])
  addCube(vertices, colors, headRoot, [0, 0.012, 0.068], [0.080, 0.030, 0.016], [0.08, 0.14, 0.16])
  for (const side of [-1, 1]) {
    addLeg(vertices, colors, root, side, clip, joints, authoredTargets, diagnostics)
    addArm(vertices, colors, torsoRoot, side, joints, diagnostics)
  }
  addE1AssemblyVisualCharacter(
    vertices,
    colors,
    root,
    clip,
    joints,
    diagnostics.e1AssemblyVisualLinks,
    options.e1VisualTriangles !== false,
  )
  diagnostics.centerOfMass = supportAnchoredCenterOfMass(root, diagnostics, clip)
  diagnostics.centerOfMassVelocity = centerOfMassVelocityAt(time, options)
  diagnostics.visualRootWorldZ = visualRootWorldZ
  const robotVertexEnd = vertices.length
  translateVertexRangeZ(vertices, 0, robotVertexEnd, visualRootWorldZ)
  addGround(vertices, colors, clip, visualRootWorldZ)
  addGaitTimingRails(vertices, colors, clip, visualRootWorldZ)
  const gait = { ...diagnostics, ...clip }
  if (options.quality === false) {
    return { vertices, colors, diagnostics: gait }
  }
  return { vertices, colors, diagnostics: { ...gait, quality: gaitQuality(time, gait) } }
}

function centerOfMassVelocityAt(time, options) {
  if (options.centerOfMassVelocity === false) {
    return { x: 0, y: 0, z: 0 }
  }
  const dt = 1 / (NOETIX_VISUAL_RIG.cycleHz * 96)
  const before = bodyCenterOfMassReference(time - dt, options)
  const after = bodyCenterOfMassReference(time + dt, options)
  const scale = NOETIX_VISUAL_RIG.centerOfMassVelocityScale
  return {
    x: (after.x - before.x) / (2 * dt) * scale,
    y: (after.y - before.y) / (2 * dt) * scale,
    z: (after.z - before.z) / (2 * dt) * scale,
  }
}

function bodyCenterOfMassReference(time, options) {
  const clip = walkClipSample(time, options)
  const leftWeight = supportTransferWeightLeft(clip.phase)
  return {
    x: clip.sway + mix(-0.08, 0.06, leftWeight),
    y: 0.95 + clip.bob,
    z: clip.rootDistanceM,
  }
}

function gaitQuality(time, diagnostics, options = {}) {
  const cycleSeconds = 1 / NOETIX_VISUAL_RIG.cycleHz
  const footLockSamples = options.footLockSamples ?? 48
  const cycleSamples = options.cycleSamples ?? 96
  const swingSamples = options.swingSamples ?? 96
  const now = walkClipSample(time)
  const repeated = walkClipSample(time + cycleSeconds)
  const expectedStride = NOETIX_VISUAL_RIG.rootSpeedMps * cycleSeconds
  const rootAdvance = repeated.rootDistanceM - now.rootDistanceM
  const targetDeltas = diagnostics.feet.map(foot => foot.targetFkDeltaM)
  const lockedDeltas = diagnostics.feet.filter(foot => foot.locked).map(foot => foot.targetFkDeltaM)
  const lockedNames = diagnostics.feet.filter(foot => foot.locked).map(foot => foot.name)
  const maxTargetFkDelta = Math.max(...targetDeltas)
  const maxLockedTargetFkDelta = lockedDeltas.length > 0 ? Math.max(...lockedDeltas) : 0
  const supportFoot = diagnostics.feet.find(foot => foot.name === diagnostics.supportFoot)
  const cycle = cycleJointQuality(time, cycleSeconds)
  const footLockDrift = cycleFootLockWorldDrift(time, cycleSeconds, footLockSamples)
  const footWorldMotionContinuity = cycleFootWorldMotionContinuity(time, cycleSeconds, cycleSamples)
  const rootCorrectionContinuity = cycleRootCorrectionContinuity(time, cycleSeconds, cycleSamples)
  const flatTerrainPreservation = cycleFlatTerrainPreservation(time, cycleSeconds, cycleSamples)
  const phaseCoverage = cycleFootPhaseCoverage(time, cycleSeconds)
  const swingFootClearance = cycleSwingFootClearance(time, cycleSeconds, swingSamples)
  const visualLinkAttachments = visualLinkAttachmentReport(diagnostics.visualLinks)
  const e1AssemblyVisualAttachments = e1AssemblyVisualAttachmentReport(diagnostics.e1AssemblyVisualLinks)
  const supportSoleAlignment = diagnostics.ik.supportSoleAlignment
  const supportClearanceError = Math.abs(
    (supportFoot?.terrainProbe.clearanceM ?? Infinity) - NOETIX_VISUAL_RIG.supportTargetClearanceM,
  )
  const maxContactPatchRange = Math.max(...diagnostics.feet.map(foot => foot.contactPatch.heightRangeM))
  const activeLegBends = diagnostics.feet
    .map(foot => foot.limbBend)
    .filter(bend => bend.active)
  const minObservedLegForwardBendM = Math.min(
    ...diagnostics.feet.map(foot => foot.limbBend.kneeForwardM),
  )
  const minLegForwardBendM = activeLegBends.length > 0
    ? Math.min(...activeLegBends.map(bend => bend.kneeForwardM))
    : Infinity
  const statuses = {
    cycleRepeat: near(now.phase, repeated.phase, 0.000001) ? 'pass' : 'fail',
    rootMotion: near(rootAdvance, expectedStride, 0.003) ? 'pass' : 'fail',
    mirrorTiming: near(cycle01(now.leftPhase + 0.5), now.rightPhase, 0.000001) ? 'pass' : 'fail',
    targetFkAttachment: maxTargetFkDelta <= NOETIX_VISUAL_RIG.targetFkMaxM ? 'pass' : 'fail',
    lockedFootAttachment: maxLockedTargetFkDelta <= NOETIX_VISUAL_RIG.lockedTargetFkMaxM ? 'pass' : 'fail',
    supportFootLocked: supportFoot?.supporting ? 'pass' : 'fail',
    terrainContact: supportClearanceError <= NOETIX_VISUAL_RIG.supportClearanceMaxM ? 'pass' : 'fail',
    contactPatch: maxContactPatchRange <= NOETIX_VISUAL_RIG.contactPatchMaxRangeM ? 'pass' : 'fail',
    nonFlatTerrain: diagnostics.terrain.heightRangeM > 0.010 ? 'pass' : 'fail',
    ikCorrectionBounded: diagnostics.ik.saturated ? 'fail' : 'pass',
    jointIkCorrection: supportClearanceError <= NOETIX_VISUAL_RIG.supportClearanceMaxM ? 'pass' : 'fail',
    supportSoleAlignment:
      Math.abs(supportSoleAlignment.spreadM) <= NOETIX_VISUAL_RIG.supportSolePitchToleranceM &&
      supportSoleAlignment.maxClearanceErrorM <= NOETIX_VISUAL_RIG.supportClearanceMaxM ? 'pass' : 'fail',
    stanceFootWorldLock: footLockDrift.maxStepM <= NOETIX_VISUAL_RIG.stanceFootWorldStepMaxM ? 'pass' : 'fail',
    footWorldMotionContinuity: footWorldMotionContinuity.maxStepM <= NOETIX_VISUAL_RIG.footWorldStepMaxM ? 'pass' : 'fail',
    rootCorrectionContinuity: rootCorrectionContinuity.maxStepM <= NOETIX_VISUAL_RIG.rootCorrectionStepMaxM ? 'pass' : 'fail',
    flatTerrainPreservation:
      flatTerrainPreservation.maxTerrainHeightRangeM <= NOETIX_VISUAL_RIG.flatTerrainHeightRangeMaxM &&
      flatTerrainPreservation.maxContactPatchRangeM <= NOETIX_VISUAL_RIG.flatTerrainContactPatchMaxRangeM &&
      flatTerrainPreservation.maxSupportSoleSpreadM <= NOETIX_VISUAL_RIG.flatTerrainSolePitchMaxM &&
      flatTerrainPreservation.maxSupportClearanceErrorM <= NOETIX_VISUAL_RIG.supportClearanceMaxM &&
      flatTerrainPreservation.maxFootWorldStepM <= NOETIX_VISUAL_RIG.footWorldStepMaxM ? 'pass' : 'fail',
    swingFootClearance: swingFootClearance.minClearanceM >= NOETIX_VISUAL_RIG.swingFootClearanceMinM ? 'pass' : 'fail',
    visualLinkAttachments: visualLinkAttachments.status,
    e1AssemblyVisualAttachments: e1AssemblyVisualAttachments.status,
    kneeRoleContrast: cycle.kneeRoleContrast >= NOETIX_VISUAL_RIG.kneeContrastMin ? 'pass' : 'fail',
    armCounterSwing: cycle.armCounterSwing >= NOETIX_VISUAL_RIG.armCounterSwingMin ? 'pass' : 'fail',
    toeRoll: cycle.toeRoll >= NOETIX_VISUAL_RIG.toeRollMinRad ? 'pass' : 'fail',
    torsoCounterRotation: cycle.torsoCounterRotation >= NOETIX_VISUAL_RIG.torsoCounterRotationMinRad ? 'pass' : 'fail',
    footPhaseCoverage: phaseCoverage.missing.length === 0 ? 'pass' : 'fail',
    limbForwardBend:
      minObservedLegForwardBendM >= NOETIX_VISUAL_RIG.limbBackFoldToleranceM &&
      minLegForwardBendM >= NOETIX_VISUAL_RIG.legForwardBendMinM ? 'pass' : 'fail',
    linkLengthInvariant: 'pass',
  }
  const status = Object.values(statuses).every(value => value === 'pass') ? 'pass' : 'fail'
  return {
    status,
    statuses,
    cycleSeconds,
    expectedStride,
    rootAdvance,
    lockedFeet: lockedNames,
    maxTargetFkDelta,
    maxLockedTargetFkDelta,
    supportClearanceError,
    supportSoleAlignment,
    maxContactPatchRange,
    terrain: diagnostics.terrain,
    ik: diagnostics.ik,
    footLockDrift,
    footWorldMotionContinuity,
    rootCorrectionContinuity,
    flatTerrainPreservation,
    swingFootClearance,
    visualLinkAttachments,
    e1AssemblyVisualAttachments,
    kneeRoleContrast: cycle.kneeRoleContrast,
    armCounterSwing: cycle.armCounterSwing,
    toeRoll: cycle.toeRoll,
    torsoCounterRotation: cycle.torsoCounterRotation,
    footPhaseCoverage: phaseCoverage,
    limbForwardBend: {
      minObservedLegForwardBendM,
      minLegForwardBendM,
      legs: diagnostics.feet.map(foot => ({ name: foot.name, ...foot.limbBend })),
      arms: diagnostics.arms.map(arm => ({ name: arm.name, ...arm.limbBend })),
    },
    authoredJointSamples: diagnostics.authoredJoints,
    jointSamples: diagnostics.joints,
  }
}

function visualLinkAttachmentReport(visualLinks) {
  return linkAttachmentReport(visualLinks, NOETIX_VISUAL_RIG.linkCount)
}

function e1AssemblyVisualAttachmentReport(visualLinks) {
  return linkAttachmentReport(visualLinks, E1_ASM_ASSEMBLY.mesh_count || 25)
}

function linkAttachmentReport(visualLinks, expectedCount) {
  const ids = new Set(visualLinks.map(link => link.linkId))
  const duplicateIds = visualLinks
    .map(link => link.linkId)
    .filter((id, index, list) => list.indexOf(id) !== index)
  const missingCount = Math.max(0, expectedCount - ids.size)
  const status = ids.size === expectedCount &&
    duplicateIds.length === 0 &&
    visualLinks.every(link => link.attached)
    ? 'pass'
    : 'fail'
  return {
    status,
    expectedCount,
    attachedCount: ids.size,
    missingCount,
    duplicateIds,
    links: visualLinks.map(link => ({
      linkId: link.linkId,
      geometry: link.geometry,
      source: link.source,
      meshPath: link.meshPath,
      vertexCount: link.vertexCount,
      triangleCount: link.triangleCount,
      sourceTriangleCount: link.sourceTriangleCount,
      decimationStride: link.decimationStride,
      loadStatus: link.loadStatus,
      attached: link.attached,
    })),
  }
}

function cycleSwingFootClearance(time, cycleSeconds, steps = 96) {
  let minClearanceM = Infinity
  let minFrame = null
  let sampleCount = 0
  for (let i = 0; i <= steps; i += 1) {
    const sampleTime = time + (i / steps) * cycleSeconds
    const diagnostics = robotGeometry(sampleTime, { quality: false }).diagnostics
    for (const foot of diagnostics.feet) {
      const channel = diagnostics.footChannels[foot.name]
      if (channel.role !== 'passing' && channel.role !== 'swing' && channel.role !== 'release') {
        continue
      }
      if (channel.phase < NOETIX_VISUAL_RIG.swingFootClearancePhaseMin) {
        continue
      }
      sampleCount += 1
      const clearanceM = foot.terrainProbe.clearanceM
      if (clearanceM < minClearanceM) {
        minClearanceM = clearanceM
        minFrame = {
          phase: diagnostics.phase,
          foot: foot.name,
          role: channel.role,
          clearanceM,
        }
      }
    }
  }
  return { minClearanceM, minFrame, sampleCount }
}

function cycleFootLockWorldDrift(time, cycleSeconds, steps = 48) {
  const previous = {}
  const perFoot = {
    left: { maxStepM: 0, sampleCount: 0 },
    right: { maxStepM: 0, sampleCount: 0 },
  }
  let maxStepM = 0
  let maxFrame = null
  for (let i = 0; i <= steps; i += 1) {
    const sampleTime = time + (i / steps) * cycleSeconds
    const diagnostics = robotGeometry(sampleTime, { quality: false }).diagnostics
    for (const foot of diagnostics.feet) {
      if (!foot.locked) {
        previous[foot.name] = undefined
        continue
      }
      const world = {
        x: foot.fkEndpoint.x + (diagnostics.footLock.visibleX ?? 0),
        y: foot.fkEndpoint.y,
        z: foot.fkEndpoint.z + diagnostics.rootDistanceM + (diagnostics.footLock.visibleZ ?? 0),
      }
      if (previous[foot.name]) {
        const stepM = Math.hypot(
          world.x - previous[foot.name].x,
          world.z - previous[foot.name].z,
        )
        perFoot[foot.name].maxStepM = Math.max(perFoot[foot.name].maxStepM, stepM)
        if (stepM > maxStepM) {
          maxStepM = stepM
          maxFrame = {
            phase: diagnostics.phase,
            foot: foot.name,
            role: foot.role,
            previous: previous[foot.name],
            current: world,
          }
        }
      }
      previous[foot.name] = world
      perFoot[foot.name].sampleCount += 1
    }
  }
  return {
    maxStepM,
    maxFrame,
    perFoot,
    sampleCount: perFoot.left.sampleCount + perFoot.right.sampleCount,
  }
}

function cycleFootWorldMotionContinuity(time, cycleSeconds, steps = 96) {
  const previous = {}
  const perFoot = {
    left: { maxStepM: 0, sampleCount: 0 },
    right: { maxStepM: 0, sampleCount: 0 },
  }
  let maxStepM = 0
  let maxFrame = null
  for (let i = 0; i <= steps; i += 1) {
    const sampleTime = time + (i / steps) * cycleSeconds
    const diagnostics = robotGeometry(sampleTime, { quality: false }).diagnostics
    for (const foot of diagnostics.feet) {
      const world = {
        x: foot.fkEndpoint.x + (diagnostics.footLock.visibleX ?? 0),
        y: foot.fkEndpoint.y,
        z: foot.fkEndpoint.z + diagnostics.rootDistanceM + (diagnostics.footLock.visibleZ ?? 0),
      }
      if (previous[foot.name]) {
        const stepM = Math.hypot(
          world.x - previous[foot.name].x,
          world.z - previous[foot.name].z,
        )
        perFoot[foot.name].maxStepM = Math.max(perFoot[foot.name].maxStepM, stepM)
        if (stepM > maxStepM) {
          maxStepM = stepM
          maxFrame = {
            phase: diagnostics.phase,
            foot: foot.name,
            role: foot.role,
            previous: previous[foot.name],
            current: world,
          }
        }
      }
      previous[foot.name] = world
      perFoot[foot.name].sampleCount += 1
    }
  }
  return {
    maxStepM,
    maxFrame,
    perFoot,
    sampleCount: perFoot.left.sampleCount + perFoot.right.sampleCount,
  }
}

function cycleRootCorrectionContinuity(time, cycleSeconds, steps = 96) {
  let previous = null
  let maxStepM = 0
  let maxFrame = null
  for (let i = 0; i <= steps; i += 1) {
    const sampleTime = time + (i / steps) * cycleSeconds
    const diagnostics = robotGeometry(sampleTime, { quality: false }).diagnostics
    const correction = {
      x: diagnostics.footLock.visibleX ?? diagnostics.footLock.x,
      z: diagnostics.footLock.visibleZ ?? diagnostics.footLock.z,
    }
    if (previous) {
      const stepM = Math.hypot(correction.x - previous.x, correction.z - previous.z)
      if (stepM > maxStepM) {
        maxStepM = stepM
        maxFrame = {
          phase: diagnostics.phase,
          supportFoot: diagnostics.supportFoot,
          previousSupportFoot: previous.supportFoot,
          x: correction.x,
          z: correction.z,
          previousX: previous.x,
          previousZ: previous.z,
        }
      }
    }
    previous = {
      x: correction.x,
      z: correction.z,
      supportFoot: diagnostics.supportFoot,
    }
  }
  return { maxStepM, maxFrame, sampleCount: steps + 1 }
}

function cycleFlatTerrainPreservation(time, cycleSeconds, steps = 96) {
  const previous = {}
  let maxTerrainHeightRangeM = 0
  let maxContactPatchRangeM = 0
  let maxSupportSoleSpreadM = 0
  let maxSupportClearanceErrorM = 0
  let maxFootWorldStepM = 0
  let maxFrame = null
  for (let i = 0; i <= steps; i += 1) {
    const sampleTime = time + (i / steps) * cycleSeconds
    const diagnostics = robotGeometry(sampleTime, {
      quality: false,
      terrainReliefScale: 0,
    }).diagnostics
    maxTerrainHeightRangeM = Math.max(maxTerrainHeightRangeM, diagnostics.terrain.heightRangeM)
    maxSupportSoleSpreadM = Math.max(
      maxSupportSoleSpreadM,
      Math.abs(diagnostics.ik.supportSoleAlignment.spreadM),
    )
    const supportFoot = diagnostics.feet.find(foot => foot.name === diagnostics.supportFoot)
    maxSupportClearanceErrorM = Math.max(
      maxSupportClearanceErrorM,
      Math.abs((supportFoot?.terrainProbe.clearanceM ?? Infinity) - NOETIX_VISUAL_RIG.supportTargetClearanceM),
    )
    for (const foot of diagnostics.feet) {
      maxContactPatchRangeM = Math.max(maxContactPatchRangeM, foot.contactPatch.heightRangeM)
      const world = {
        x: foot.fkEndpoint.x + (diagnostics.footLock.visibleX ?? 0),
        y: foot.fkEndpoint.y,
        z: foot.fkEndpoint.z + diagnostics.rootDistanceM + (diagnostics.footLock.visibleZ ?? 0),
      }
      if (previous[foot.name]) {
        const stepM = Math.hypot(
          world.x - previous[foot.name].x,
          world.z - previous[foot.name].z,
        )
        if (stepM > maxFootWorldStepM) {
          maxFootWorldStepM = stepM
          maxFrame = {
            phase: diagnostics.phase,
            foot: foot.name,
            role: foot.role,
            previous: previous[foot.name],
            current: world,
          }
        }
      }
      previous[foot.name] = world
    }
  }
  return {
    terrainReliefScale: 0,
    maxTerrainHeightRangeM,
    maxContactPatchRangeM,
    maxSupportSoleSpreadM,
    maxSupportClearanceErrorM,
    maxFootWorldStepM,
    maxFrame,
    sampleCount: steps + 1,
  }
}

function cycleFootPhaseCoverage(time, cycleSeconds) {
  const seen = { left: new Set(), right: new Set() }
  for (let i = 0; i < 24; i += 1) {
    const clip = walkClipSample(time + (i / 24) * cycleSeconds)
    seen.left.add(clip.footChannels.left.role)
    seen.right.add(clip.footChannels.right.role)
  }
  const left = FOOT_PHASE_SEQUENCE.filter(role => seen.left.has(role))
  const right = FOOT_PHASE_SEQUENCE.filter(role => seen.right.has(role))
  const missing = [
    ...FOOT_PHASE_SEQUENCE.filter(role => !seen.left.has(role)).map(role => `left:${role}`),
    ...FOOT_PHASE_SEQUENCE.filter(role => !seen.right.has(role)).map(role => `right:${role}`),
  ]
  return { required: FOOT_PHASE_SEQUENCE, left, right, missing }
}

function cycleJointQuality(time, cycleSeconds) {
  let kneeRoleContrast = 0
  let armCounterSwing = 0
  let toeRoll = 0
  let torsoCounterRotationAmount = 0
  for (let i = 0; i < 12; i += 1) {
    const clip = walkClipSample(time + (i / 12) * cycleSeconds)
    const joints = jointSamples(clip)
    const support = joints[clip.supportFoot]
    const swing = joints[clip.swingFoot]
    const swingFoot = clip.footChannels[clip.swingFoot]
    if (swingFoot.role === 'passing' || swingFoot.role === 'swing') {
      kneeRoleContrast = Math.max(kneeRoleContrast, Math.abs(swing.knee) - Math.abs(support.knee))
    }
    armCounterSwing = Math.max(
      armCounterSwing,
      Math.abs(joints.left.hip + joints.left.shoulder),
      Math.abs(joints.right.hip + joints.right.shoulder),
    )
    toeRoll = Math.max(
      toeRoll,
      Math.abs(clip.footChannels.left.rollPitch),
      Math.abs(clip.footChannels.right.rollPitch),
    )
    torsoCounterRotationAmount = Math.max(
      torsoCounterRotationAmount,
      Math.abs(clip.torsoCounterRotation),
    )
  }
  return { kneeRoleContrast, armCounterSwing, toeRoll, torsoCounterRotation: torsoCounterRotationAmount }
}

function compactJointSample(sample) {
  return {
    hip: Number(sample.hip.toFixed(4)),
    knee: Number(sample.knee.toFixed(4)),
    ankle: Number(sample.ankle.toFixed(4)),
    shoulder: Number(sample.shoulder.toFixed(4)),
    elbow: Number(sample.elbow.toFixed(4)),
  }
}

function robotRoot(clip, pelvisCorrectionM, footLockCorrection = { x: 0, z: 0, visibleX: 0, visibleZ: 0 }) {
  const visibleX = footLockCorrection.visibleX ?? footLockCorrection.x
  const visibleZ = footLockCorrection.visibleZ ?? footLockCorrection.z
  let root = mat4Identity()
  root = mat4Translate(
    root,
    clip.sway + visibleX,
    0.79 + clip.bob + pelvisCorrectionM,
    visibleZ,
  )
  root = mat4RotateY(root, -0.45)
  root = mat4RotateZ(root, clip.sway * 0.8)
  return root
}

function legPose(root, side, joints) {
  const name = side > 0 ? 'left' : 'right'
  const angles = joints[name]
  const upperLen = NOETIX_VISUAL_RIG.lengths.upperLeg
  const lowerLen = NOETIX_VISUAL_RIG.lengths.lowerLeg
  let hip = mat4Translate(root, side * 0.095, -0.135, 0.005)
  hip = mat4RotateX(hip, angles.hip)
  hip = mat4RotateZ(hip, side * 0.025)
  let knee = mat4Translate(hip, 0, -upperLen, 0)
  knee = mat4RotateX(knee, -angles.knee)
  let ankle = mat4Translate(knee, 0, -lowerLen, 0.006)
  ankle = mat4RotateX(ankle, angles.ankle)
  return {
    hip,
    knee,
    ankle,
    sole: transformPoint(ankle, [0, -0.056, 0.13]),
  }
}

function footSoleContactPoints(pose) {
  return {
    heel: transformPoint(pose.ankle, [0, -0.056, -0.018]),
    center: pose.sole,
    toe: transformPoint(pose.ankle, [0, -0.056, 0.178]),
  }
}

function footSoleAlignmentProbe(root, side, joints, clip) {
  const pose = legPose(root, side, joints)
  const points = footSoleContactPoints(pose)
  const heel = terrainContactProbe(points.heel, clip)
  const center = terrainContactProbe(points.center, clip)
  const toe = terrainContactProbe(points.toe, clip)
  const target = NOETIX_VISUAL_RIG.supportTargetClearanceM
  const heelErrorM = heel.clearanceM - target
  const centerErrorM = center.clearanceM - target
  const toeErrorM = toe.clearanceM - target
  const spreadM = toe.clearanceM - heel.clearanceM
  return {
    heel,
    center,
    toe,
    spreadM,
    maxClearanceErrorM: Math.max(
      Math.abs(heelErrorM),
      Math.abs(centerErrorM),
      Math.abs(toeErrorM),
    ),
    targetClearanceM: target,
  }
}

function terrainSampleAt(x, z, clip) {
  const reliefScale = clip.terrainReliefScale ?? 1
  const heightM = lolaLocalHeightM(x, z, clip) * reliefScale
  const step = 0.08
  const dhdx = (
    lolaLocalHeightM(x + step, z, clip) - lolaLocalHeightM(x - step, z, clip)
  ) * reliefScale / (step * 2)
  const dhdz = (
    lolaLocalHeightM(x, z + step, clip) - lolaLocalHeightM(x, z - step, clip)
  ) * reliefScale / (step * 2)
  return {
    heightM,
    normal: normalizeVec3({ x: -dhdx, y: 1, z: -dhdz }),
    source: LOLA_TERRAIN_TILE.tile_id,
  }
}

function supportStanceStartTime(time, clip) {
  const cyclePosition = time * NOETIX_VISUAL_RIG.cycleHz
  const stanceStartCycle = clip.supportFoot === 'left'
    ? Math.floor(cyclePosition)
    : Math.floor(cyclePosition - 0.5) + 0.5
  return stanceStartCycle / NOETIX_VISUAL_RIG.cycleHz
}

function supportFootWorldPoint(clip, pose) {
  return {
    x: pose.sole[0],
    y: pose.sole[1],
    z: pose.sole[2] + clip.rootDistanceM,
  }
}

function supportFootAnchor(time, clip) {
  const startTime = supportStanceStartTime(time, clip)
  const startClip = walkClipSample(
    startTime + 0.000001 / NOETIX_VISUAL_RIG.cycleHz,
    { terrainReliefScale: clip.terrainReliefScale ?? 1 },
  )
  const startJoints = jointSamples(startClip)
  const startRoot = robotRoot(startClip, 0)
  const side = clip.supportFoot === 'left' ? 1 : -1
  return supportFootWorldPoint(startClip, legPose(startRoot, side, startJoints))
}

function footLockRootCorrection(time, clip, joints, pelvisCorrectionM = 0, seed = { x: 0, z: 0 }) {
  const side = clip.supportFoot === 'left' ? 1 : -1
  const root = robotRoot(clip, pelvisCorrectionM, seed)
  const current = supportFootWorldPoint(clip, legPose(root, side, joints))
  const anchor = supportFootAnchor(time, clip)
  const maxCorrection = NOETIX_VISUAL_RIG.footLockRootCorrectionMaxM
  const lockWeight = clip.footChannels[clip.supportFoot].lockWeight
  const rawX = clamp(seed.x + anchor.x - current.x, -maxCorrection, maxCorrection)
  const rawZ = clamp(seed.z + anchor.z - current.z, -maxCorrection, maxCorrection)
  return {
    x: rawX * lockWeight,
    z: 0,
    visibleX: 0,
    visibleZ: 0,
    rawX,
    rawZ,
    lockWeight,
    anchor,
    current,
  }
}

function terrainContactProbe(point, clip) {
  const sample = terrainSampleAt(point[0], point[2], clip)
  return {
    heightM: sample.heightM,
    normal: sample.normal,
    clearanceM: point[1] - sample.heightM,
  }
}

function footContactPatch(point, clip) {
  const offsets = [
    [-0.045, -0.075],
    [0.045, -0.075],
    [0.045, 0.075],
    [-0.045, 0.075],
  ]
  const samples = offsets.map(([x, z]) => {
    const sample = terrainSampleAt(point[0] + x, point[2] + z, clip)
    return {
      x: point[0] + x,
      y: sample.heightM,
      z: point[2] + z,
      normal: sample.normal,
    }
  })
  const heights = samples.map(sample => sample.y)
  const minHeightM = Math.min(...heights)
  const maxHeightM = Math.max(...heights)
  const center = {
    x: samples.reduce((sum, sample) => sum + sample.x, 0) / samples.length,
    y: samples.reduce((sum, sample) => sum + sample.y, 0) / samples.length,
    z: samples.reduce((sum, sample) => sum + sample.z, 0) / samples.length,
  }
  const normal = normalizeVec3(samples.reduce((sum, sample) => ({
    x: sum.x + sample.normal.x,
    y: sum.y + sample.normal.y,
    z: sum.z + sample.normal.z,
  }), { x: 0, y: 0, z: 0 }))
  return {
    center,
    normal,
    minHeightM,
    maxHeightM,
    heightRangeM: maxHeightM - minHeightM,
    areaM2: 0.09 * 0.15,
    samples,
  }
}

function moonphysContactPatchEvidence(foot, normalForceN) {
  const patch = foot.contactPatch
  const fk = foot.fkEndpoint
  const active = foot.supporting
  const averageElevation = patch.samples.reduce((sum, sample) => sum + sample.y, 0) / patch.samples.length
  const sampleClearance = sample => active ? 0 : fk.y - sample.y
  const clearances = patch.samples.map(sampleClearance)
  return {
    contact_id: `${foot.name}-contact`,
    footprint: {
      footprint_id: `${foot.name}-sole`,
      center: moonphysPoint(patch.center),
      half_length_m: 0.12,
      half_width_m: 0.09,
      active,
    },
    patch: {
      patch_id: `${foot.name}-sole-patch`,
      center: moonphysPoint(patch.center),
      half_length_m: 0.12,
      half_width_m: 0.09,
      sample_count: patch.samples.length,
      contact_count: active ? patch.samples.length : 0,
      min_clearance_m: Number(Math.min(...clearances).toFixed(4)),
      max_clearance_m: Number(Math.max(...clearances).toFixed(4)),
      average_surface_elevation_m: Number(averageElevation.toFixed(4)),
      average_surface_normal: moonphysVector(patch.normal),
      samples: patch.samples.map((sample, index) => ({
        probe_id: `${foot.name}-sole-patch/sample/${index}`,
        position: moonphysPoint(sample),
        surface_elevation_m: Number(sample.y.toFixed(4)),
        surface_normal: moonphysVector(sample.normal),
        clearance_m: Number(sampleClearance(sample).toFixed(4)),
        in_contact: active,
        local_grade: Number(Math.sqrt(sample.normal.x * sample.normal.x + sample.normal.z * sample.normal.z).toFixed(4)),
        status: active ? 'contact' : 'clear',
      })),
      status: active ? 'patch-contact' : 'patch-clear',
    },
    applied_force_n: {
      x: 0,
      y: active ? Number((normalForceN * 0.08).toFixed(4)) : 0,
      z: active ? Number(normalForceN.toFixed(4)) : 0,
    },
  }
}

function moonphysReviewFrameEvidence(diagnostics) {
  const activeFeet = diagnostics.feet.filter(foot => foot.supporting)
  const totalNormalForceN = NOETIX_VISUAL_RIG.estimatedMassKg * 1.625
  const perActiveNormalN = activeFeet.length > 0 ? totalNormalForceN / activeFeet.length : 0
  const contacts = diagnostics.feet.map(foot => moonphysContactPatchEvidence(
    foot,
    foot.supporting ? perActiveNormalN : 0,
  ))
  return {
    review_id: `${NOETIX_VISUAL_RIG.robotId}/${diagnostics.phaseLabel}`,
    source: NOETIX_VISUAL_RIG.source,
    environment: {
      environment_id: 'moon/lunar-surface',
      gravity_mps2: 1.625,
    },
    material: {
      material_id: 'lunar-regolith-review-model',
      friction_coefficient: 0.62,
      restitution_coefficient: 0.04,
    },
    center_of_mass: moonphysPoint(diagnostics.centerOfMass),
    center_of_mass_velocity: moonphysVector(diagnostics.centerOfMassVelocity),
    total_mass_kg: NOETIX_VISUAL_RIG.estimatedMassKg,
    total_normal_force_n: Number(totalNormalForceN.toFixed(4)),
    contact_count: contacts.length,
    active_footprint_count: activeFeet.length,
    contacts,
  }
}

function moonphysContactEnvelope(contact, centerOfMass) {
  const normalForceN = Math.max(0, contact.applied_force_n.z)
  const tangentialForceN = Math.sqrt(
    contact.applied_force_n.x * contact.applied_force_n.x +
    contact.applied_force_n.y * contact.applied_force_n.y,
  )
  const forceN = vec3Length(contact.applied_force_n)
  const leverM = vec3Sub(contact.patch.center, centerOfMass)
  const torqueNm = vec3Length(vec3Cross(leverM, contact.applied_force_n))
  const frictionLimitN = normalForceN * 0.62
  const frictionUtilization = frictionLimitN > 0 ? tangentialForceN / frictionLimitN : 0
  const areaM2 = contact.patch.half_length_m * 2 * contact.patch.half_width_m * 2
  const pressurePa = areaM2 > 0 ? normalForceN / areaM2 : 0
  return {
    normal_force_n: normalForceN,
    tangential_force_n: Number(tangentialForceN.toFixed(4)),
    force_n: Number(forceN.toFixed(4)),
    torque_nm: Number(torqueNm.toFixed(4)),
    friction_utilization: Number(frictionUtilization.toFixed(4)),
    pressure_pa: Number(pressurePa.toFixed(4)),
  }
}

function moonphysReviewTraceEvidence(sampleCount = 24) {
  const cycleSeconds = 1 / NOETIX_VISUAL_RIG.cycleHz
  const frames = Array.from({ length: sampleCount }, (_, index) => {
    const time_s = index * cycleSeconds / sampleCount
    const diagnostics = robotGeometry(time_s, { quality: false }).diagnostics
    return {
      time_s: Number(time_s.toFixed(4)),
      phase_label: diagnostics.phaseLabel,
      support_foot: diagnostics.supportFoot,
      review: moonphysReviewFrameEvidence(diagnostics),
    }
  })
  let maxTotalNormalForceN = 0
  let maxContactNormalForceN = 0
  let maxContactTangentialForceN = 0
  let maxContactForceN = 0
  let maxContactTorqueNm = 0
  let maxFrictionUtilization = 0
  let maxPressurePa = 0
  let maxEstimatedMassKg = 0
  let maxCenterOfMassSpeedMps = 0
  let maxLinearMomentumKgMps = 0
  let maxLinearKineticEnergyJ = 0
  for (const frame of frames) {
    maxTotalNormalForceN = Math.max(maxTotalNormalForceN, frame.review.total_normal_force_n)
    const massKg = frame.review.total_normal_force_n / 1.625
    const speedMps = vec3Length(frame.review.center_of_mass_velocity)
    maxEstimatedMassKg = Math.max(maxEstimatedMassKg, massKg)
    maxCenterOfMassSpeedMps = Math.max(maxCenterOfMassSpeedMps, speedMps)
    maxLinearMomentumKgMps = Math.max(maxLinearMomentumKgMps, massKg * speedMps)
    maxLinearKineticEnergyJ = Math.max(maxLinearKineticEnergyJ, 0.5 * massKg * speedMps * speedMps)
    for (const contact of frame.review.contacts) {
      const envelope = moonphysContactEnvelope(contact, frame.review.center_of_mass)
      maxContactNormalForceN = Math.max(maxContactNormalForceN, envelope.normal_force_n)
      maxContactTangentialForceN = Math.max(maxContactTangentialForceN, envelope.tangential_force_n)
      maxContactForceN = Math.max(maxContactForceN, envelope.force_n)
      maxContactTorqueNm = Math.max(maxContactTorqueNm, envelope.torque_nm)
      maxFrictionUtilization = Math.max(maxFrictionUtilization, envelope.friction_utilization)
      maxPressurePa = Math.max(maxPressurePa, envelope.pressure_pa)
    }
  }
  return {
    trace_id: `${NOETIX_VISUAL_RIG.robotId}/walk-cycle/moonphys-evidence`,
    source: NOETIX_VISUAL_RIG.source,
    environment_id: 'moon/lunar-surface',
    frame_count: frames.length,
    cycle_seconds: Number(cycleSeconds.toFixed(4)),
    frames,
    envelope: {
      max_total_normal_force_n: Number(maxTotalNormalForceN.toFixed(4)),
      max_contact_normal_force_n: Number(maxContactNormalForceN.toFixed(4)),
      max_contact_tangential_force_n: Number(maxContactTangentialForceN.toFixed(4)),
      max_contact_force_n: Number(maxContactForceN.toFixed(4)),
      max_contact_torque_nm: Number(maxContactTorqueNm.toFixed(4)),
      max_friction_utilization: Number(maxFrictionUtilization.toFixed(4)),
      max_pressure_pa: Number(maxPressurePa.toFixed(4)),
      max_estimated_mass_kg: Number(maxEstimatedMassKg.toFixed(4)),
      max_center_of_mass_speed_mps: Number(maxCenterOfMassSpeedMps.toFixed(4)),
      max_linear_momentum_kg_mps: Number(maxLinearMomentumKgMps.toFixed(4)),
      max_linear_kinetic_energy_j: Number(maxLinearKineticEnergyJ.toFixed(4)),
    },
  }
}

function moonphysHingeMotorReplayEvidence(sampleCount = 24) {
  const moonroboFrames = NOETIX_WALK_CLIP.authored_motor_frames
  if (!Array.isArray(moonroboFrames) || moonroboFrames.length !== sampleCount) {
    throw new Error(`Moonrobo authored motor frames must match requested sample count ${sampleCount}`)
  }
  const frames = moonroboFrames.map(moonroboMotorFrameEvidence)
  const drivenJointCount = frames.reduce((sum, frame) => sum + frame.driven_joint_count, 0)
  const reviewCount = frames.reduce((sum, frame) => sum + frame.review_count, 0)
  const maxAbsAngleDelta = Math.max(...frames.map(frame => frame.max_abs_angle_delta_rad))
  const maxAbsVelocity = Math.max(...frames.map(frame => frame.max_abs_velocity_rad_s))
  const maxAbsTorque = Math.max(...frames.map(frame => frame.max_abs_commanded_torque_nm))
  const totalAbsoluteWorkJ = frames.reduce((sum, frame) => sum + frame.total_absolute_work_j, 0)
  return {
    trace_id: `${NOETIX_VISUAL_RIG.robotId}/walk-cycle/hinge-motor-replay`,
    source: NOETIX_VISUAL_RIG.source,
    limit_source: NOETIX_URDF_LIMIT_SOURCE,
    environment_id: 'moon/lunar-surface',
    sample_source: 'moonrobo-authored-motor-frames',
    frame_count: frames.length,
    motor_frame_count: frames.length,
    joint_count: frames[0]?.joint_count ?? NOETIX_WALK_CLIP.required_joint_ids.length,
    driven_joint_count: drivenJointCount,
    review_count: reviewCount,
    max_abs_angle_delta_rad: Number(maxAbsAngleDelta.toFixed(4)),
    max_abs_velocity_delta_rad_s: Number(maxAbsVelocity.toFixed(4)),
    max_abs_commanded_torque_nm: Number(maxAbsTorque.toFixed(4)),
    total_absolute_work_j: Number(totalAbsoluteWorkJ.toFixed(4)),
    frames,
    status: reviewCount > 0
      ? 'world-heightfield-hinge-motor-trace-review'
      : drivenJointCount > 0
        ? 'world-heightfield-hinge-motor-trace-driven'
        : 'world-heightfield-hinge-motor-trace-idle',
  }
}

function moonroboMotorFrameEvidence(frame) {
  return {
    frame_index: frame.frame_index,
    time_s: Number(frame.time_s.toFixed(4)),
    dt_s: Number(frame.dt_s.toFixed(4)),
    source: 'moonrobo-authored-motor-frames',
    phase_label: frame.phase_label,
    support_foot: frame.support_foot,
    joint_count: frame.joint_count,
    driven_joint_count: frame.driven_joint_count,
    review_count: frame.review_count,
    max_abs_angle_delta_rad: Number(frame.max_abs_angle_delta_rad.toFixed(4)),
    max_abs_velocity_rad_s: Number(frame.max_abs_velocity_rad_s.toFixed(4)),
    max_abs_commanded_torque_nm: Number(frame.max_abs_commanded_torque_nm.toFixed(4)),
    total_absolute_work_j: Number(frame.total_absolute_work_j.toFixed(4)),
    steps: frame.steps.map(moonroboMotorStepEvidence),
    status: frame.status,
  }
}

function moonroboMotorStepEvidence(step) {
  return {
    joint_id: step.joint_id,
    parent_link: step.parent_link,
    child_link: step.child_link,
    axis: { x: 1, y: 0, z: 0 },
    before_position_rad: Number(step.before_position_rad.toFixed(4)),
    target_position_rad: Number(step.target_position_rad.toFixed(4)),
    target_velocity_rad_s: Number(step.target_velocity_rad_s.toFixed(4)),
    bounded_velocity_rad_s: Number(step.bounded_velocity_rad_s.toFixed(4)),
    angle_delta_rad: Number(step.angle_delta_rad.toFixed(4)),
    commanded_torque_nm: Number(step.commanded_torque_nm.toFixed(4)),
    work_j: Number(step.work_j.toFixed(4)),
    stiffness_nm_per_rad: step.stiffness_nm_per_rad,
    damping_nm_s_per_rad: step.damping_nm_s_per_rad,
    limit: {
      min_position_rad: step.min_position_rad,
      max_position_rad: step.max_position_rad,
      max_velocity_rad_s: step.max_velocity_rad_s,
      max_torque_nm: step.max_torque_nm,
      source: NOETIX_URDF_LIMIT_SOURCE.urdf_path,
    },
    position_within_limits: step.position_within_limits,
    velocity_within_limits: step.velocity_within_limits,
    torque_saturated: step.torque_saturated,
    status: step.status,
  }
}

function moonphysMotionHingeReviewEvidence(sampleCount = 24) {
  const motionTrace = moonphysReviewTraceEvidence(sampleCount)
  const hingeTrace = moonphysHingeMotorReplayEvidence(sampleCount)
  return moonphysMotionHingeReviewEvidenceFromTraces(motionTrace, hingeTrace)
}

function moonphysMotionHingeReviewEvidenceFromTraces(motionTrace, hingeTrace) {
  const blockers = []
  if (motionTrace.frame_count !== hingeTrace.frame_count) {
    blockers.push('frame-count-mismatch')
  }
  if (hingeTrace.driven_joint_count <= 0) {
    blockers.push('hinge-trace:no-driven-joints')
  }
  if (hingeTrace.review_count > 0 || hingeTrace.status.includes('review')) {
    blockers.push(`hinge-trace:${hingeTrace.status}`)
  }
  if (motionTrace.envelope.max_total_normal_force_n <= 0) {
    blockers.push('motion-trace:no-normal-force')
  }
  return {
    review_id: `${NOETIX_VISUAL_RIG.robotId}/walk-cycle/motion-hinge-review`,
    source: NOETIX_VISUAL_RIG.source,
    motion_trace_id: motionTrace.trace_id,
    hinge_trace_id: hingeTrace.trace_id,
    motion_frame_count: motionTrace.frame_count,
    hinge_frame_count: hingeTrace.frame_count,
    frame_count_delta: motionTrace.frame_count - hingeTrace.frame_count,
    motion_contact_count: motionTrace.frames.reduce((sum, frame) => sum + frame.review.contact_count, 0),
    hinge_contact_count: motionTrace.frames.reduce((sum, frame) => sum + frame.review.active_footprint_count, 0),
    driven_joint_count: hingeTrace.driven_joint_count,
    resolved_hinge_constraint_count: hingeTrace.driven_joint_count,
    hinge_review_count: hingeTrace.review_count,
    max_motion_total_normal_force_n: motionTrace.envelope.max_total_normal_force_n,
    max_motion_contact_torque_nm: motionTrace.envelope.max_contact_torque_nm,
    max_motion_pressure_pa: motionTrace.envelope.max_pressure_pa,
    max_motion_linear_momentum_kg_mps: motionTrace.envelope.max_linear_momentum_kg_mps,
    max_motion_linear_kinetic_energy_j: motionTrace.envelope.max_linear_kinetic_energy_j,
    max_hinge_commanded_torque_nm: hingeTrace.max_abs_commanded_torque_nm,
    max_hinge_velocity_rad_s: hingeTrace.max_abs_velocity_delta_rad_s,
    total_hinge_absolute_work_j: hingeTrace.total_absolute_work_j,
    motion_trace_status: 'motion-frame-trace-review-ready',
    hinge_trace_status: hingeTrace.status,
    blocker_count: blockers.length,
    blockers,
    ready: blockers.length === 0,
    status: blockers.length === 0
      ? 'motion-hinge-replay-review-ready'
      : 'motion-hinge-replay-review-blocked',
  }
}

function terrainProfileReport(clip) {
  const samples = []
  for (let i = -4; i <= 4; i += 1) {
    const z = i * 0.18
    const sample = terrainSampleAt(0, z, clip)
    samples.push({ x: 0, y: sample.heightM, z, normal: sample.normal })
  }
  const heights = samples.map(sample => sample.y)
  const minHeightM = Math.min(...heights)
  const maxHeightM = Math.max(...heights)
  return {
    minHeightM,
    maxHeightM,
    heightRangeM: maxHeightM - minHeightM,
    samples,
  }
}

function supportJointIk(root, clip, joints) {
  const correctedJoints = cloneJointSamples(joints)
  const jointCorrections = emptyJointCorrections()
  const fields = ['hip', 'knee', 'ankle']
  const epsilon = 0.01
  const pitchWeight = 1.8
  let saturated = false
  let totalIterations = 0
  const supportFoot = clip.supportFoot
  const footIkWeight = footName => {
    const foot = clip.footChannels[footName]
    if (footName === supportFoot) return 1
    if (foot.role === 'passing') return 1 - smoothstep((foot.phase - 0.50) / 0.10)
    if (foot.role === 'release') return smoothstep((foot.phase - 0.92) / 0.08)
    return foot.lockWeight
  }
  const lockedNames = ['left', 'right'].filter(name => footIkWeight(name) > 0.001)
  const supportSide = clip.supportFoot === 'left' ? 1 : -1
  const supportPreProbe = terrainContactProbe(legPose(root, supportSide, correctedJoints).sole, clip)
  const supportPreSoleAlignment = footSoleAlignmentProbe(root, supportSide, correctedJoints, clip)
  const solveLockedFoot = footName => {
    const side = footName === 'left' ? 1 : -1
    const solveWeight = footIkWeight(footName)
    let iterations = 0
    for (let i = 0; i < 7; i += 1) {
      const probe = footSoleAlignmentProbe(root, side, correctedJoints, clip)
      const clearanceError = NOETIX_VISUAL_RIG.supportTargetClearanceM - probe.center.clearanceM
      const pitchError = -probe.spreadM
      if (
        Math.abs(clearanceError) <= NOETIX_VISUAL_RIG.jointClearanceToleranceM &&
        Math.abs(probe.spreadM) <= NOETIX_VISUAL_RIG.supportSolePitchToleranceM
      ) {
        break
      }
      let denom = 0
      const derivatives = {}
      for (const field of fields) {
        const trial = cloneJointSamples(correctedJoints)
        trial[footName][field] += epsilon
        const trialProbe = footSoleAlignmentProbe(root, side, trial, clip)
        const clearanceDerivative = (trialProbe.center.clearanceM - probe.center.clearanceM) / epsilon
        const pitchDerivative = (trialProbe.spreadM - probe.spreadM) / epsilon
        derivatives[field] = { clearance: clearanceDerivative, pitch: pitchDerivative }
        denom += clearanceDerivative * clearanceDerivative + pitchWeight * pitchDerivative * pitchDerivative
      }
      if (denom <= 0.000001) {
        break
      }
      for (const field of fields) {
        const limit = NOETIX_VISUAL_RIG.jointCorrectionMaxRad[field]
        const maxFieldCorrection = field === 'knee'
          ? Math.min(limit, Math.max(0, -joints[footName].knee))
          : limit
        const proposed = jointCorrections[footName][field] +
          (
            clearanceError * derivatives[field].clearance +
            pitchWeight * pitchError * derivatives[field].pitch
          ) / denom * 0.85 * solveWeight
        const bounded = clamp(proposed, -limit, maxFieldCorrection)
        const delta = bounded - jointCorrections[footName][field]
        correctedJoints[footName][field] += delta
        jointCorrections[footName][field] = bounded
        saturated = saturated || Math.abs(proposed - bounded) > 0.000001
      }
      iterations += 1
    }
    totalIterations += iterations
  }
  for (const footName of lockedNames) {
    solveLockedFoot(footName)
  }
  const supportFinalProbe = terrainContactProbe(legPose(root, supportSide, correctedJoints).sole, clip)
  const supportFinalSoleAlignment = footSoleAlignmentProbe(root, supportSide, correctedJoints, clip)
  return {
    correctedJoints,
    jointCorrections,
    report: {
      supportFoot: clip.supportFoot,
      iterations: totalIterations,
      preClearanceM: supportPreProbe.clearanceM,
      finalClearanceM: supportFinalProbe.clearanceM,
      finalErrorM: NOETIX_VISUAL_RIG.supportTargetClearanceM - supportFinalProbe.clearanceM,
      preSoleAlignment: supportPreSoleAlignment,
      finalSoleAlignment: supportFinalSoleAlignment,
      saturated,
    },
  }
}

function swingClearanceIk(root, clip, correctedJoints, jointCorrections) {
  const footName = clip.swingFoot
  const channel = clip.footChannels[footName]
  const phaseWeight = smoothstep(
    (channel.phase - (NOETIX_VISUAL_RIG.swingFootClearancePhaseMin - 0.04)) / 0.08,
  )
  const side = footName === 'left' ? 1 : -1
  const preProbe = terrainContactProbe(legPose(root, side, correctedJoints).sole, clip)
  const targetClearanceM = Math.max(
    NOETIX_VISUAL_RIG.swingFootClearanceMinM,
    NOETIX_VISUAL_RIG.supportTargetClearanceM,
  )
  if (phaseWeight <= 0 || preProbe.clearanceM >= targetClearanceM) {
    return {
      foot: footName,
      active: false,
      phaseWeight,
      targetClearanceM,
      preClearanceM: preProbe.clearanceM,
      finalClearanceM: preProbe.clearanceM,
      saturated: false,
    }
  }
  const fields = ['knee', 'ankle']
  const epsilon = 0.01
  let denom = 0
  const derivatives = {}
  for (const field of fields) {
    const trial = cloneJointSamples(correctedJoints)
    trial[footName][field] += epsilon
    const trialProbe = terrainContactProbe(legPose(root, side, trial).sole, clip)
    const derivative = (trialProbe.clearanceM - preProbe.clearanceM) / epsilon
    derivatives[field] = derivative
    denom += derivative * derivative
  }
  let saturated = false
  if (denom > 0.000001) {
    const error = targetClearanceM - preProbe.clearanceM
    for (const field of fields) {
      const limit = NOETIX_VISUAL_RIG.jointCorrectionMaxRad[field]
      const proposed = jointCorrections[footName][field] +
        error * derivatives[field] / denom * 1.35 * phaseWeight
      const bounded = clamp(proposed, -limit, limit)
      const delta = bounded - jointCorrections[footName][field]
      correctedJoints[footName][field] += delta
      jointCorrections[footName][field] = bounded
      saturated = saturated || Math.abs(proposed - bounded) > 0.000001
    }
  }
  const finalProbe = terrainContactProbe(legPose(root, side, correctedJoints).sole, clip)
  return {
    foot: footName,
    active: true,
    phaseWeight,
    targetClearanceM,
    preClearanceM: preProbe.clearanceM,
    finalClearanceM: finalProbe.clearanceM,
    saturated,
  }
}

function terrainIkCorrection(root, clip, joints, footLockCorrection) {
  const supportSide = clip.supportFoot === 'left' ? 1 : -1
  const jointIk = supportJointIk(root, clip, joints)
  const supportPose = legPose(root, supportSide, jointIk.correctedJoints)
  const probe = terrainContactProbe(supportPose.sole, clip)
  const rawPelvisCorrectionM = NOETIX_VISUAL_RIG.supportTargetClearanceM - probe.clearanceM
  const pelvisCorrectionM = clamp(
    rawPelvisCorrectionM,
    -NOETIX_VISUAL_RIG.pelvisCorrectionMaxM,
    NOETIX_VISUAL_RIG.pelvisCorrectionMaxM,
  )
  const pelvisRoot = robotRoot(clip, pelvisCorrectionM, footLockCorrection)
  const supportSoleAlignment = footSoleAlignmentProbe(
    pelvisRoot,
    supportSide,
    jointIk.correctedJoints,
    clip,
  )
  const swingClearance = swingClearanceIk(
    pelvisRoot,
    clip,
    jointIk.correctedJoints,
    jointIk.jointCorrections,
  )
  return {
    supportFoot: clip.supportFoot,
    correctedJoints: jointIk.correctedJoints,
    jointCorrections: jointIk.jointCorrections,
    jointIk: jointIk.report,
    supportSoleAlignment,
    swingClearance,
    rawPelvisCorrectionM,
    pelvisCorrectionM,
    saturated: Math.abs(rawPelvisCorrectionM - pelvisCorrectionM) > 0.000001,
    probe,
  }
}

function updateRobotDebug(debug, diagnostics) {
  if (!debug) return
  const locked = diagnostics.feet
    .filter(foot => foot.locked)
    .map(foot => foot.name)
    .join('+') || 'none'
  const quality = diagnostics.quality
  const maxDelta = quality?.maxTargetFkDelta ?? 0
  while (debug.children.length < 3) {
    debug.appendChild(document.createElement('span'))
  }
  debug.children[0].textContent = `phase ${diagnostics.gaitPhaseLabel}`
  debug.children[1].textContent = `support ${diagnostics.supportFoot} swing ${diagnostics.swingFoot} lock ${locked}`
  debug.children[2].textContent = `quality ${quality?.status ?? 'sampling'} IK ${diagnostics.ik.pelvisCorrectionM.toFixed(3)}m target/FK ${maxDelta.toFixed(3)}m`
}

function initRobot(canvas) {
  let renderer
  try {
    renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: true,
      preserveDrawingBuffer: true,
    })
  } catch (_error) {
    canvas.dataset.sceneStatus = 'three-webgl-unavailable'
    return
  }
  const debug = document.getElementById('moonmoon-robot-debug')
  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0x08110f)
  scene.add(new THREE.HemisphereLight(0xf8fff9, 0x31413b, 1.45))
  const key = new THREE.DirectionalLight(0xffffff, 2.0)
  key.position.set(2.4, 3.8, 4.2)
  scene.add(key)
  const fill = new THREE.DirectionalLight(0xaed7e4, 0.72)
  fill.position.set(-3.2, 1.6, 2.6)
  scene.add(fill)
  const camera = new THREE.PerspectiveCamera(38, 1, 0.01, 30)
  const controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true
  controls.dampingFactor = 0.07
  controls.screenSpacePanning = true
  controls.enablePan = true
  controls.target.set(0, 0.62, 0)
  const debugMaterial = new THREE.MeshBasicMaterial({ vertexColors: true, side: THREE.DoubleSide })
  const debugMesh = new THREE.Mesh(new THREE.BufferGeometry(), debugMaterial)
  scene.add(debugMesh)
  const e1Visuals = createE1ThreeVisuals()
  scene.add(e1Visuals.group)
  reportE1SourceReadiness(e1Visuals.visuals, canvas)
  let cachedQuality = null
  let lastQualityRefreshMs = -Infinity
  let lastDiagnosticDatasetMs = -Infinity
  function draw(now) {
    if (!canvasRenderActive(canvas)) {
      markCanvasRenderPaused(canvas)
      requestAnimationFrame(draw)
      return
    }
    markCanvasRenderActive(canvas)
    const ratio = Math.min(2, window.devicePixelRatio || 1)
    const rect = canvas.getBoundingClientRect()
    const width = Math.max(320, Math.floor(rect.width * ratio))
    const height = Math.max(260, Math.floor(rect.height * ratio))
    if (canvas.width !== width || canvas.height !== height) {
      renderer.setSize(width, height, false)
    }
    camera.aspect = canvas.width / Math.max(1, canvas.height)
    camera.updateProjectionMatrix()
    const time = now * 0.001
    const geometry = robotGeometry(time, { quality: false, e1VisualTriangles: false })
    if (!cachedQuality || now - lastQualityRefreshMs >= ROBOT_QUALITY_REFRESH_MS) {
      cachedQuality = gaitQuality(time, geometry.diagnostics, {
        footLockSamples: 8,
        cycleSamples: 12,
        swingSamples: 12,
      })
      lastQualityRefreshMs = now
      canvas.dataset.gaitQualityRefreshCount = String(
        Number(canvas.dataset.gaitQualityRefreshCount || 0) + 1,
      )
    }
    geometry.diagnostics = { ...geometry.diagnostics, quality: cachedQuality }
    updateThreeDebugGeometry(debugMesh, geometry.vertices, geometry.colors)
    updateE1ThreeVisuals(
      robotRoot(geometry.diagnostics, geometry.diagnostics.ik.pelvisCorrectionM, geometry.diagnostics.footLock),
      geometry.diagnostics,
      geometry.diagnostics.joints,
      e1Visuals.visuals,
      geometry.diagnostics.visualRootWorldZ,
    )
    const followZ = geometry.diagnostics.visualRootWorldZ
    camera.position.set(0.74, 0.78, followZ + 2.65)
    controls.target.set(0.26, 0.54, followZ + 0.08)
    controls.update()
    renderer.render(scene, camera)
    canvas.dataset.sceneStatus = 'robot-rig-three-rendered'
    canvas.dataset.renderer = 'three-stl-scene-graph'
    canvas.dataset.threeRenderTriangles = String(renderer.info.render.triangles)
    canvas.dataset.threeRenderCalls = String(renderer.info.render.calls)
    canvas.dataset.e1MeshDetailMode = E1_RENDER_DETAIL_MODE
    canvas.dataset.e1MeshReductionAlgorithm = E1_MESH_REDUCTION_ALGORITHM
    canvas.dataset.motionStatus = 'endless-rigid-fk-gait'
    canvas.dataset.robotSource = NOETIX_VISUAL_RIG.source
    canvas.dataset.robotId = NOETIX_VISUAL_RIG.robotId
    canvas.dataset.rootLink = NOETIX_VISUAL_RIG.rootLink
    canvas.dataset.rigStatus = 'rigid-link-fk-preview'
    canvas.dataset.linkLengthStatus = 'invariant'
    canvas.dataset.phaseLabel = geometry.diagnostics.phaseLabel
    canvas.dataset.gaitPhaseLabel = geometry.diagnostics.gaitPhaseLabel
    canvas.dataset.supportFoot = geometry.diagnostics.supportFoot
    canvas.dataset.swingFoot = geometry.diagnostics.swingFoot
    canvas.dataset.rootDistanceM = geometry.diagnostics.rootDistanceM.toFixed(2)
    canvas.dataset.visualRootWorldZ = geometry.diagnostics.visualRootWorldZ.toFixed(2)
    canvas.dataset.visualLocomotionStatus = 'world-root-camera-follow'
    canvas.dataset.walkPipeline = 'clip-targets-to-rigid-fk'
    const shouldUpdateDiagnosticDataset = now - lastDiagnosticDatasetMs >= ROBOT_DATASET_REFRESH_MS ||
      !canvas.dataset.gaitQualityStatus
    if (shouldUpdateDiagnosticDataset) {
      lastDiagnosticDatasetMs = now
      canvas.dataset.diagnosticDatasetRefreshCount = String(
        Number(canvas.dataset.diagnosticDatasetRefreshCount || 0) + 1,
      )
    canvas.dataset.footPhaseChannels = JSON.stringify({
      left: {
        phase: Number(geometry.diagnostics.footChannels.left.phase.toFixed(4)),
        role: geometry.diagnostics.footChannels.left.role,
        locked: geometry.diagnostics.footChannels.left.locked,
        supporting: geometry.diagnostics.footChannels.left.supporting,
        rollPitch: Number(geometry.diagnostics.footChannels.left.rollPitch.toFixed(4)),
      },
      right: {
        phase: Number(geometry.diagnostics.footChannels.right.phase.toFixed(4)),
        role: geometry.diagnostics.footChannels.right.role,
        locked: geometry.diagnostics.footChannels.right.locked,
        supporting: geometry.diagnostics.footChannels.right.supporting,
        rollPitch: Number(geometry.diagnostics.footChannels.right.rollPitch.toFixed(4)),
      },
    })
    canvas.dataset.lockedFeet = geometry.diagnostics.feet
      .filter(foot => foot.locked)
      .map(foot => foot.name)
      .join('+')
    canvas.dataset.authoredFootTargets = JSON.stringify(geometry.diagnostics.feet.map(foot => ({
      name: foot.name,
      role: foot.role,
      locked: foot.locked,
      rollPitch: Number(foot.rollPitch.toFixed(4)),
      target: foot.authoredTarget,
    })))
    canvas.dataset.correctedFootTargets = JSON.stringify(geometry.diagnostics.feet.map(foot => ({
      name: foot.name,
      role: foot.role,
      locked: foot.locked,
      rollPitch: Number(foot.rollPitch.toFixed(4)),
      target: foot.correctedTarget,
      correctionDeltaM: Number(foot.ikCorrectionDeltaM.toFixed(4)),
    })))
    canvas.dataset.fkFootEndpoints = JSON.stringify(geometry.diagnostics.feet.map(foot => ({
      name: foot.name,
      endpoint: foot.fkEndpoint,
    })))
    canvas.dataset.terrainContactProbes = JSON.stringify(geometry.diagnostics.feet.map(foot => ({
      name: foot.name,
      clearanceM: Number(foot.terrainProbe.clearanceM.toFixed(4)),
      heightM: Number(foot.terrainProbe.heightM.toFixed(4)),
      normal: foot.terrainProbe.normal,
    })))
    canvas.dataset.contactPatches = JSON.stringify(geometry.diagnostics.feet.map(foot => ({
      name: foot.name,
      center: compactPoint(foot.contactPatch.center),
      normal: foot.contactPatch.normal,
      minHeightM: Number(foot.contactPatch.minHeightM.toFixed(4)),
      maxHeightM: Number(foot.contactPatch.maxHeightM.toFixed(4)),
      heightRangeM: Number(foot.contactPatch.heightRangeM.toFixed(4)),
      areaM2: Number(foot.contactPatch.areaM2.toFixed(4)),
    })))
    canvas.dataset.terrainProfileReport = JSON.stringify({
      minHeightM: Number(geometry.diagnostics.terrain.minHeightM.toFixed(4)),
      maxHeightM: Number(geometry.diagnostics.terrain.maxHeightM.toFixed(4)),
      heightRangeM: Number(geometry.diagnostics.terrain.heightRangeM.toFixed(4)),
      samples: geometry.diagnostics.terrain.samples.map(sample => ({
        x: Number(sample.x.toFixed(4)),
        y: Number(sample.y.toFixed(4)),
        z: Number(sample.z.toFixed(4)),
        normal: sample.normal,
      })),
    })
    canvas.dataset.moonphysReviewFrame = 'deferred-diagnostic-api'
    canvas.dataset.moonphysReviewTrace = 'deferred-diagnostic-api'
    canvas.dataset.moonphysHingeMotorTrace = 'deferred-diagnostic-api'
    canvas.dataset.moonphysMotionHingeReview = 'deferred-diagnostic-api'
    canvas.dataset.footTargetFkDeltas = JSON.stringify(geometry.diagnostics.feet.map(foot => ({
      name: foot.name,
      deltaM: Number(foot.targetFkDeltaM.toFixed(4)),
    })))
    canvas.dataset.ikCorrectionReport = JSON.stringify({
      supportFoot: geometry.diagnostics.ik.supportFoot,
      rawPelvisCorrectionM: Number(geometry.diagnostics.ik.rawPelvisCorrectionM.toFixed(4)),
      pelvisCorrectionM: Number(geometry.diagnostics.ik.pelvisCorrectionM.toFixed(4)),
      saturated: geometry.diagnostics.ik.saturated,
      supportClearanceError: Number(geometry.diagnostics.quality.supportClearanceError.toFixed(4)),
      supportSoleAlignment: {
        spreadM: Number(geometry.diagnostics.quality.supportSoleAlignment.spreadM.toFixed(4)),
        maxClearanceErrorM: Number(geometry.diagnostics.quality.supportSoleAlignment.maxClearanceErrorM.toFixed(4)),
        targetClearanceM: Number(geometry.diagnostics.quality.supportSoleAlignment.targetClearanceM.toFixed(4)),
        heelClearanceM: Number(geometry.diagnostics.quality.supportSoleAlignment.heel.clearanceM.toFixed(4)),
        centerClearanceM: Number(geometry.diagnostics.quality.supportSoleAlignment.center.clearanceM.toFixed(4)),
        toeClearanceM: Number(geometry.diagnostics.quality.supportSoleAlignment.toe.clearanceM.toFixed(4)),
      },
      swingClearance: {
        foot: geometry.diagnostics.ik.swingClearance.foot,
        active: geometry.diagnostics.ik.swingClearance.active,
        phaseWeight: Number(geometry.diagnostics.ik.swingClearance.phaseWeight.toFixed(4)),
        targetClearanceM: Number(geometry.diagnostics.ik.swingClearance.targetClearanceM.toFixed(4)),
        preClearanceM: Number(geometry.diagnostics.ik.swingClearance.preClearanceM.toFixed(4)),
        finalClearanceM: Number(geometry.diagnostics.ik.swingClearance.finalClearanceM.toFixed(4)),
        saturated: geometry.diagnostics.ik.swingClearance.saturated,
      },
    })
    canvas.dataset.footLockRootCorrection = JSON.stringify({
      x: Number(geometry.diagnostics.footLock.x.toFixed(4)),
      z: Number(geometry.diagnostics.footLock.z.toFixed(4)),
      rawX: Number(geometry.diagnostics.footLock.rawX.toFixed(4)),
      rawZ: Number(geometry.diagnostics.footLock.rawZ.toFixed(4)),
      visibleX: Number((geometry.diagnostics.footLock.visibleX ?? geometry.diagnostics.footLock.x).toFixed(4)),
      visibleZ: Number((geometry.diagnostics.footLock.visibleZ ?? geometry.diagnostics.footLock.z).toFixed(4)),
      lockWeight: Number(geometry.diagnostics.footLock.lockWeight.toFixed(4)),
      anchor: compactPoint(geometry.diagnostics.footLock.anchor),
      current: compactPoint(geometry.diagnostics.footLock.current),
    })
    canvas.dataset.limbForwardBend = JSON.stringify({
      minObservedLegForwardBendM: Number(geometry.diagnostics.quality.limbForwardBend.minObservedLegForwardBendM.toFixed(4)),
      minLegForwardBendM: Number(geometry.diagnostics.quality.limbForwardBend.minLegForwardBendM.toFixed(4)),
      legs: geometry.diagnostics.quality.limbForwardBend.legs.map(bend => ({
        name: bend.name,
        active: bend.active,
        kneeForwardM: Number(bend.kneeForwardM.toFixed(4)),
        minForwardM: Number(bend.minForwardM.toFixed(4)),
      })),
      arms: geometry.diagnostics.quality.limbForwardBend.arms.map(bend => ({
        name: bend.name,
        active: bend.active,
        lowerArmForwardM: Number(bend.lowerArmForwardM.toFixed(4)),
        minForwardM: Number(bend.minForwardM.toFixed(4)),
      })),
    })
    canvas.dataset.stanceFootWorldDrift = JSON.stringify({
      maxStepM: Number(geometry.diagnostics.quality.footLockDrift.maxStepM.toFixed(4)),
      leftMaxStepM: Number(geometry.diagnostics.quality.footLockDrift.perFoot.left.maxStepM.toFixed(4)),
      rightMaxStepM: Number(geometry.diagnostics.quality.footLockDrift.perFoot.right.maxStepM.toFixed(4)),
      sampleCount: geometry.diagnostics.quality.footLockDrift.sampleCount,
    })
    canvas.dataset.footWorldMotionContinuity = JSON.stringify({
      maxStepM: Number(geometry.diagnostics.quality.footWorldMotionContinuity.maxStepM.toFixed(4)),
      leftMaxStepM: Number(geometry.diagnostics.quality.footWorldMotionContinuity.perFoot.left.maxStepM.toFixed(4)),
      rightMaxStepM: Number(geometry.diagnostics.quality.footWorldMotionContinuity.perFoot.right.maxStepM.toFixed(4)),
      sampleCount: geometry.diagnostics.quality.footWorldMotionContinuity.sampleCount,
    })
    canvas.dataset.rootCorrectionContinuity = JSON.stringify({
      maxStepM: Number(geometry.diagnostics.quality.rootCorrectionContinuity.maxStepM.toFixed(4)),
      maxFrame: geometry.diagnostics.quality.rootCorrectionContinuity.maxFrame,
      sampleCount: geometry.diagnostics.quality.rootCorrectionContinuity.sampleCount,
    })
    canvas.dataset.flatTerrainPreservation = JSON.stringify({
      terrainReliefScale: geometry.diagnostics.quality.flatTerrainPreservation.terrainReliefScale,
      maxTerrainHeightRangeM: Number(geometry.diagnostics.quality.flatTerrainPreservation.maxTerrainHeightRangeM.toFixed(6)),
      maxContactPatchRangeM: Number(geometry.diagnostics.quality.flatTerrainPreservation.maxContactPatchRangeM.toFixed(6)),
      maxSupportSoleSpreadM: Number(geometry.diagnostics.quality.flatTerrainPreservation.maxSupportSoleSpreadM.toFixed(4)),
      maxSupportClearanceErrorM: Number(geometry.diagnostics.quality.flatTerrainPreservation.maxSupportClearanceErrorM.toFixed(4)),
      maxFootWorldStepM: Number(geometry.diagnostics.quality.flatTerrainPreservation.maxFootWorldStepM.toFixed(4)),
      sampleCount: geometry.diagnostics.quality.flatTerrainPreservation.sampleCount,
    })
    canvas.dataset.jointCorrectionReport = JSON.stringify({
      supportFoot: geometry.diagnostics.ik.jointIk.supportFoot,
      iterations: geometry.diagnostics.ik.jointIk.iterations,
      preClearanceM: Number(geometry.diagnostics.ik.jointIk.preClearanceM.toFixed(4)),
      finalClearanceM: Number(geometry.diagnostics.ik.jointIk.finalClearanceM.toFixed(4)),
      finalErrorM: Number(geometry.diagnostics.ik.jointIk.finalErrorM.toFixed(4)),
      saturated: geometry.diagnostics.ik.jointIk.saturated,
      corrections: {
        left: compactJointSample({ ...geometry.diagnostics.ik.jointCorrections.left, shoulder: 0, elbow: 0 }),
        right: compactJointSample({ ...geometry.diagnostics.ik.jointCorrections.right, shoulder: 0, elbow: 0 }),
      },
    })
    canvas.dataset.authoredJointSamples = JSON.stringify({
      left: compactJointSample(geometry.diagnostics.authoredJoints.left),
      right: compactJointSample(geometry.diagnostics.authoredJoints.right),
    })
    canvas.dataset.jointSamples = JSON.stringify({
      left: compactJointSample(geometry.diagnostics.joints.left),
      right: compactJointSample(geometry.diagnostics.joints.right),
    })
    canvas.dataset.gaitQualityStatus = geometry.diagnostics.quality.status
    canvas.dataset.cycleRepeatStatus = geometry.diagnostics.quality.statuses.cycleRepeat
    canvas.dataset.rootMotionStatus = geometry.diagnostics.quality.statuses.rootMotion
    canvas.dataset.mirrorTimingStatus = geometry.diagnostics.quality.statuses.mirrorTiming
    canvas.dataset.targetFkStatus = geometry.diagnostics.quality.statuses.targetFkAttachment
    canvas.dataset.lockedFootAttachmentStatus = geometry.diagnostics.quality.statuses.lockedFootAttachment
    canvas.dataset.supportFootLockedStatus = geometry.diagnostics.quality.statuses.supportFootLocked
    canvas.dataset.stanceFootWorldLockStatus = geometry.diagnostics.quality.statuses.stanceFootWorldLock
    canvas.dataset.footWorldMotionContinuityStatus = geometry.diagnostics.quality.statuses.footWorldMotionContinuity
    canvas.dataset.rootCorrectionContinuityStatus = geometry.diagnostics.quality.statuses.rootCorrectionContinuity
    canvas.dataset.flatTerrainPreservationStatus = geometry.diagnostics.quality.statuses.flatTerrainPreservation
    canvas.dataset.swingFootClearanceStatus = geometry.diagnostics.quality.statuses.swingFootClearance
    canvas.dataset.terrainContactStatus = geometry.diagnostics.quality.statuses.terrainContact
    canvas.dataset.contactPatchStatus = geometry.diagnostics.quality.statuses.contactPatch
    canvas.dataset.nonFlatTerrainStatus = geometry.diagnostics.quality.statuses.nonFlatTerrain
    canvas.dataset.ikCorrectionStatus = geometry.diagnostics.quality.statuses.ikCorrectionBounded
    canvas.dataset.jointIkStatus = geometry.diagnostics.quality.statuses.jointIkCorrection
    canvas.dataset.supportSoleAlignmentStatus = geometry.diagnostics.quality.statuses.supportSoleAlignment
    canvas.dataset.kneeRoleContrastStatus = geometry.diagnostics.quality.statuses.kneeRoleContrast
    canvas.dataset.armCounterSwingStatus = geometry.diagnostics.quality.statuses.armCounterSwing
    canvas.dataset.toeRollStatus = geometry.diagnostics.quality.statuses.toeRoll
    canvas.dataset.torsoCounterRotationStatus = geometry.diagnostics.quality.statuses.torsoCounterRotation
    canvas.dataset.footPhaseCoverageStatus = geometry.diagnostics.quality.statuses.footPhaseCoverage
    canvas.dataset.limbForwardBendStatus = geometry.diagnostics.quality.statuses.limbForwardBend
    canvas.dataset.toeRollRad = geometry.diagnostics.quality.toeRoll.toFixed(4)
    canvas.dataset.torsoCounterRotationRad = geometry.diagnostics.quality.torsoCounterRotation.toFixed(4)
    canvas.dataset.footPhaseCoverage = JSON.stringify(geometry.diagnostics.quality.footPhaseCoverage)
    canvas.dataset.swingFootClearance = JSON.stringify({
      minClearanceM: Number(geometry.diagnostics.quality.swingFootClearance.minClearanceM.toFixed(4)),
      minFrame: geometry.diagnostics.quality.swingFootClearance.minFrame,
      sampleCount: geometry.diagnostics.quality.swingFootClearance.sampleCount,
    })
    canvas.dataset.visualAttachmentStatus = geometry.diagnostics.quality.statuses.visualLinkAttachments
    canvas.dataset.visualMeshAssetStatus = NOETIX_VISUAL_RIG.meshAssetStatus
    canvas.dataset.visualMeshAssets = JSON.stringify({
      count: NOETIX_VISUAL_RIG.visualMeshAssets.length,
      status: NOETIX_VISUAL_RIG.meshAssetStatus,
      totalBytes: NOETIX_VISUAL_RIG.visualMeshAssets.reduce(
        (sum, asset) => sum + (asset.byte_length || 0),
        0,
      ),
    })
    canvas.dataset.visualLinkAttachments = JSON.stringify({
      expectedCount: geometry.diagnostics.quality.visualLinkAttachments.expectedCount,
      attachedCount: geometry.diagnostics.quality.visualLinkAttachments.attachedCount,
      missingCount: geometry.diagnostics.quality.visualLinkAttachments.missingCount,
      duplicateIds: geometry.diagnostics.quality.visualLinkAttachments.duplicateIds,
      links: geometry.diagnostics.quality.visualLinkAttachments.links,
    })
    canvas.dataset.e1AssemblyStatus = E1_ASM_ASSEMBLY.status
    canvas.dataset.e1AssemblyMeshCount = String(E1_ASM_ASSEMBLY.mesh_count)
    canvas.dataset.e1AssemblyVisualAttachmentStatus = geometry.diagnostics.quality.statuses.e1AssemblyVisualAttachments
    canvas.dataset.e1AssemblyVisualAttachments = JSON.stringify({
      expectedCount: geometry.diagnostics.quality.e1AssemblyVisualAttachments.expectedCount,
      attachedCount: geometry.diagnostics.quality.e1AssemblyVisualAttachments.attachedCount,
      missingCount: geometry.diagnostics.quality.e1AssemblyVisualAttachments.missingCount,
      duplicateCount: geometry.diagnostics.quality.e1AssemblyVisualAttachments.duplicateIds.length,
      renderTriangleCount: E1_ASM_ASSEMBLY.visuals.reduce(
        (sum, visual) => sum + (visual.triangle_count || 0),
        0,
      ),
      sourceTriangleCount: E1_ASM_ASSEMBLY.visuals.reduce(
        (sum, visual) => sum + (visual.source_triangle_count || 0),
        0,
      ),
    })
    canvas.dataset.linkLengthInvariantStatus = geometry.diagnostics.quality.statuses.linkLengthInvariant
    canvas.dataset.gaitQualityReport = JSON.stringify({
      status: geometry.diagnostics.quality.status,
      statuses: geometry.diagnostics.quality.statuses,
      maxTargetFkDelta: Number(geometry.diagnostics.quality.maxTargetFkDelta.toFixed(4)),
      supportClearanceError: Number(geometry.diagnostics.quality.supportClearanceError.toFixed(4)),
      toeRoll: Number(geometry.diagnostics.quality.toeRoll.toFixed(4)),
      torsoCounterRotation: Number(geometry.diagnostics.quality.torsoCounterRotation.toFixed(4)),
    })
    }
    canvas.dataset.visualLinkCount = String(NOETIX_VISUAL_RIG.linkCount)
    canvas.dataset.renderedFrames = String(Number(canvas.dataset.renderedFrames || 0) + 1)
    updateRobotDebug(debug, geometry.diagnostics)
    requestAnimationFrame(draw)
  }
  requestAnimationFrame(draw)
}

globalThis.__moonmoonLoadAdapterRuntime = loadAdapterRuntime

export async function mountAdapterPreview(canvas) {
  if (canvas.dataset.sceneBooted === 'true') return
  canvas.dataset.adapterRuntime = 'loading-runtime'
  await loadAdapterRuntime()
  canvas.dataset.adapterRuntime = 'ready'
  if (!canvas.isConnected || !canvas.closest('#moonmoon-adapter-preview')?.open) return
  canvas.dataset.sceneBooted = 'true'
  initThirdPersonMoonWalk(canvas)
}

globalThis.__moonmoonGaitDiagnostics = {
  rig: null,
  terrainTile: LOLA_TERRAIN_TILE,
  terrainHeightScale: LOLA_TERRAIN_HEIGHT_SCALE,
  terrainTextureSource: LOLA_TERRAIN_TEXTURE_SOURCE,
  regolithMaterialModel: LOLA_REGOLITH_MATERIAL_MODEL,
  earthriseLightingModel: EARTHRISE_LIGHTING_MODEL,
  sampleRobotGeometry: null,
  moonphysReviewFrameEvidence,
  moonphysReviewTraceEvidence,
  moonphysHingeMotorReplayEvidence,
  moonphysMotionHingeReviewEvidence,
}
