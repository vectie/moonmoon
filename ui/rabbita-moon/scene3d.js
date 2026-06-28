import {
  FOOT_PHASE_SEQUENCE,
  NOETIX_HINGE_MOTOR_JOINTS,
  NOETIX_URDF_LIMIT_SOURCE,
  NOETIX_VISUAL_RIG,
  cloneJointSamples,
  cycle01,
  emptyJointCorrections,
  footRoleColor,
  jointSamples,
  near,
  supportMassTransferX,
  walkClipSample,
} from './gait-clip.js'

const DEG = Math.PI / 180
const LUNAR_TEXTURE_URL = new URL('./assets/lunar_global_texture.jpg', import.meta.url).href

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

function createMoonProgram(gl) {
  const vertex = gl.createShader(gl.VERTEX_SHADER)
  gl.shaderSource(vertex, `
    attribute vec3 a_position;
    attribute vec2 a_uv;
    uniform mat4 u_mvp;
    varying vec2 v_uv;
    varying vec3 v_normal;
    void main() {
      gl_Position = u_mvp * vec4(a_position, 1.0);
      v_uv = a_uv;
      v_normal = normalize(a_position);
    }
  `)
  gl.compileShader(vertex)
  if (!gl.getShaderParameter(vertex, gl.COMPILE_STATUS)) {
    throw new Error(gl.getShaderInfoLog(vertex) || 'moon vertex shader failed')
  }
  const fragment = gl.createShader(gl.FRAGMENT_SHADER)
  gl.shaderSource(fragment, `
    precision mediump float;
    uniform sampler2D u_texture;
    varying vec2 v_uv;
    varying vec3 v_normal;
    void main() {
      vec3 tex = texture2D(u_texture, v_uv).rgb;
      vec3 light = normalize(vec3(-0.35, 0.42, 0.84));
      float shade = 0.32 + max(dot(normalize(v_normal), light), 0.0) * 0.78;
      float polar = pow(abs(v_normal.y), 3.0) * 0.10;
      gl_FragColor = vec4(tex * shade + vec3(polar), 1.0);
    }
  `)
  gl.compileShader(fragment)
  if (!gl.getShaderParameter(fragment, gl.COMPILE_STATUS)) {
    throw new Error(gl.getShaderInfoLog(fragment) || 'moon fragment shader failed')
  }
  const program = gl.createProgram()
  gl.attachShader(program, vertex)
  gl.attachShader(program, fragment)
  gl.linkProgram(program)
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    throw new Error(gl.getProgramInfoLog(program) || 'moon program failed')
  }
  return {
    program,
    position: gl.getAttribLocation(program, 'a_position'),
    uv: gl.getAttribLocation(program, 'a_uv'),
    mvp: gl.getUniformLocation(program, 'u_mvp'),
    texture: gl.getUniformLocation(program, 'u_texture'),
  }
}

function createBuffers(gl) {
  return {
    positions: gl.createBuffer(),
    colors: gl.createBuffer(),
  }
}

function createMoonBuffers(gl) {
  return {
    positions: gl.createBuffer(),
    uvs: gl.createBuffer(),
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

function uploadMoon(gl, shader, buffers, mesh, texture, mvp) {
  gl.useProgram(shader.program)
  gl.uniformMatrix4fv(shader.mvp, false, new Float32Array(mvp))
  gl.activeTexture(gl.TEXTURE0)
  gl.bindTexture(gl.TEXTURE_2D, texture)
  gl.uniform1i(shader.texture, 0)
  gl.bindBuffer(gl.ARRAY_BUFFER, buffers.positions)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(mesh.vertices), gl.STATIC_DRAW)
  gl.enableVertexAttribArray(shader.position)
  gl.vertexAttribPointer(shader.position, 3, gl.FLOAT, false, 0, 0)
  gl.bindBuffer(gl.ARRAY_BUFFER, buffers.uvs)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(mesh.uvs), gl.STATIC_DRAW)
  gl.enableVertexAttribArray(shader.uv)
  gl.vertexAttribPointer(shader.uv, 2, gl.FLOAT, false, 0, 0)
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

function sphereMesh(latBands, lonBands) {
  const vertices = []
  const uvs = []
  function push(point, u, v) {
    vertices.push(...point)
    uvs.push(u, v)
  }
  for (let lat = 0; lat < latBands; lat += 1) {
    const t0 = -Math.PI / 2 + (lat / latBands) * Math.PI
    const t1 = -Math.PI / 2 + ((lat + 1) / latBands) * Math.PI
    for (let lon = 0; lon < lonBands; lon += 1) {
      const p0 = (lon / lonBands) * Math.PI * 2
      const p1 = ((lon + 1) / lonBands) * Math.PI * 2
      const a = spherePoint(t0, p0)
      const b = spherePoint(t1, p0)
      const c = spherePoint(t1, p1)
      const d = spherePoint(t0, p1)
      const u0 = 1 - lon / lonBands
      const u1 = 1 - (lon + 1) / lonBands
      const v0 = 1 - lat / latBands
      const v1 = 1 - (lat + 1) / latBands
      push(a, u0, v0)
      push(b, u0, v1)
      push(c, u1, v1)
      push(a, u0, v0)
      push(c, u1, v1)
      push(d, u1, v0)
    }
  }
  return { vertices, uvs }
}

function spherePoint(theta, phi) {
  const ct = Math.cos(theta)
  return [ct * Math.cos(phi), Math.sin(theta), ct * Math.sin(phi)]
}

function latLonPoint(latDeg, lonDeg, radius = 1.025) {
  const lat = latDeg * DEG
  const lon = lonDeg * DEG
  const cl = Math.cos(lat)
  return [radius * cl * Math.cos(lon), radius * Math.sin(lat), radius * cl * Math.sin(lon)]
}

function loadMoonTexture(gl, canvas) {
  const texture = gl.createTexture()
  gl.bindTexture(gl.TEXTURE_2D, texture)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  gl.texImage2D(
    gl.TEXTURE_2D,
    0,
    gl.RGBA,
    1,
    1,
    0,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    new Uint8Array([86, 84, 78, 255]),
  )
  const image = new Image()
  image.onload = () => {
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)
    canvas.dataset.textureStatus = 'lunar-global-texture-loaded'
  }
  image.onerror = () => {
    canvas.dataset.textureStatus = 'lunar-global-texture-unavailable'
  }
  image.src = LUNAR_TEXTURE_URL
  canvas.dataset.textureStatus = 'lunar-global-texture-loading'
  return texture
}

function initMoon(canvas, view) {
  const gl = canvas.getContext('webgl', { antialias: true })
  if (!gl) {
    canvas.dataset.sceneStatus = 'webgl-unavailable'
    return
  }
  const moonShader = createMoonProgram(gl)
  const moonBuffers = createMoonBuffers(gl)
  const pointShader = createProgram(gl)
  const pointBuffers = createBuffers(gl)
  const texture = loadMoonTexture(gl, canvas)
  const mesh = sphereMesh(44, 88)
  const site = {
    lat: Number(view.site_latitude_deg || -89.88),
    lon: Number(view.site_longitude_deg || 0.12),
  }
  let yaw = 0.35
  let pitch = -0.92
  let dragging = false
  let lastX = 0
  let lastY = 0
  canvas.onpointerdown = event => {
    dragging = true
    lastX = event.clientX
    lastY = event.clientY
    canvas.setPointerCapture(event.pointerId)
  }
  canvas.onpointermove = event => {
    if (!dragging) return
    yaw += (event.clientX - lastX) * 0.008
    pitch = clamp(pitch + (event.clientY - lastY) * 0.006, -1.45, 1.45)
    lastX = event.clientX
    lastY = event.clientY
  }
  canvas.onpointerup = event => {
    dragging = false
    canvas.releasePointerCapture(event.pointerId)
  }
  function draw() {
    resizeCanvas(canvas, gl)
    gl.clearColor(0.02, 0.026, 0.024, 1)
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.enable(gl.DEPTH_TEST)
    const aspect = canvas.width / Math.max(1, canvas.height)
    let model = mat4Identity()
    model = mat4RotateX(model, pitch)
    model = mat4RotateY(model, yaw)
    const viewMat = mat4Translate(mat4Identity(), 0, 0, -3.35)
    const mvp = mat4Multiply(mat4Perspective(44 * DEG, aspect, 0.1, 20), mat4Multiply(viewMat, model))
    uploadMoon(gl, moonShader, moonBuffers, mesh, texture, mvp)
    gl.drawArrays(gl.TRIANGLES, 0, mesh.vertices.length / 3)

    const point = latLonPoint(site.lat, site.lon)
    upload(gl, pointShader, pointBuffers, point, [0.94, 0.76, 0.25], mvp)
    gl.drawArrays(gl.POINTS, 0, 1)
    canvas.dataset.sceneStatus = 'moon-globe-webgl-rendered'
    canvas.dataset.renderedFrames = String(Number(canvas.dataset.renderedFrames || 0) + 1)
    if (!dragging) yaw += 0.0015
    requestAnimationFrame(draw)
  }
  draw()
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

function addVisualLink(vertices, colors, diagnostics, linkId, matrix, center, size, color, source) {
  addCube(vertices, colors, matrix, center, size, color)
  diagnostics.visualLinks.push({
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

function supportAnchoredCenterOfMass(root, diagnostics) {
  const fallback = transformPoint(root, [
    diagnostics.supportMassTransferX,
    0.16,
    0.035,
  ])
  const activeFeet = diagnostics.feet.filter(foot => foot.supporting)
  if (activeFeet.length === 0) {
    return pointRecord(fallback)
  }
  const center = activeFeet.reduce((sum, foot) => ({
    x: sum.x + foot.contactPatch.center.x,
    y: sum.y + foot.contactPatch.center.y,
    z: sum.z + foot.contactPatch.center.z,
  }), { x: 0, y: 0, z: 0 })
  const inv = 1 / activeFeet.length
  return {
    x: center.x * inv,
    y: fallback[1],
    z: center.z * inv,
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

function addGround(vertices, colors, clip) {
  const spacing = 0.24
  const startWorldZ = Math.floor((clip.rootDistanceM - 1.92) / spacing) * spacing
  for (let i = 0; i <= 17; i += 1) {
    const worldZ = startWorldZ + i * spacing
    const z = worldZ - clip.rootDistanceM
    const nextZ = z + 0.018
    const a = terrainSampleAt(-1.6, z, clip).heightM
    const b = terrainSampleAt(1.6, z, clip).heightM
    const c = terrainSampleAt(1.6, nextZ, clip).heightM
    const d = terrainSampleAt(-1.6, nextZ, clip).heightM
    addQuad(vertices, colors, [-1.6, a, z], [1.6, b, z], [1.6, c - 0.012, nextZ], [-1.6, d - 0.012, nextZ], [0.18, 0.24, 0.21])
  }
  for (let i = -4; i <= 4; i += 1) {
    const x = i * 0.32
    const a = terrainSampleAt(x, -1.4, clip).heightM
    const b = terrainSampleAt(x + 0.014, -1.4, clip).heightM
    const c = terrainSampleAt(x + 0.014, 1.4, clip).heightM
    const d = terrainSampleAt(x, 1.4, clip).heightM
    addQuad(vertices, colors, [x, a, -1.4], [x + 0.014, b, -1.4], [x + 0.014, c - 0.012, 1.4], [x, d - 0.012, 1.4], [0.14, 0.20, 0.18])
  }
}

function addGaitTimingRails(vertices, colors, clip) {
  for (let i = -6; i <= 6; i += 1) {
    const z = i * 0.18
    const terrain = terrainSampleAt(0, z, clip)
    const size = i === 0 ? [0.050, 0.020, 0.050] : [0.030, 0.012, 0.030]
    const color = i === 0 ? [0.74, 0.96, 0.88] : [0.26, 0.48, 0.42]
    addCube(vertices, colors, mat4Identity(), [0, terrain.heightM + 0.018, z], size, color)
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
      addCube(vertices, colors, mat4Identity(), [x, terrain.heightM + 0.020, z], size, color)
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

function robotGeometry(time, options = { quality: true }) {
  const vertices = []
  const colors = []
  const clip = walkClipSample(time)
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
  const authoredTargets = {
    left: footTargetForPose(legPose(ikRoot, 1, authoredJoints).sole, clip.footChannels.left, clip),
    right: footTargetForPose(legPose(ikRoot, -1, authoredJoints).sole, clip.footChannels.right, clip),
  }
  const joints = ik.correctedJoints
  const terrain = terrainProfileReport(clip)
  const diagnostics = { feet: [], arms: [], visualLinks: [], authoredJoints, joints, ik, terrain, footLock }
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
    `${NOETIX_URDF_LIMIT_SOURCE.urdf_path}#base_link mesh meshes/base.obj`,
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
  diagnostics.centerOfMass = supportAnchoredCenterOfMass(root, diagnostics)
  diagnostics.centerOfMassVelocity = { x: 0, y: 0, z: 0 }
  addGround(vertices, colors, clip)
  addGaitTimingRails(vertices, colors, clip)
  const gait = { ...diagnostics, ...clip }
  if (options.quality === false) {
    return { vertices, colors, diagnostics: gait }
  }
  return { vertices, colors, diagnostics: { ...gait, quality: gaitQuality(time, gait) } }
}

function gaitQuality(time, diagnostics) {
  const cycleSeconds = 1 / NOETIX_VISUAL_RIG.cycleHz
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
  const footLockDrift = cycleFootLockWorldDrift(time, cycleSeconds)
  const footWorldMotionContinuity = cycleFootWorldMotionContinuity(time, cycleSeconds)
  const rootCorrectionContinuity = cycleRootCorrectionContinuity(time, cycleSeconds)
  const phaseCoverage = cycleFootPhaseCoverage(time, cycleSeconds)
  const swingFootClearance = cycleSwingFootClearance(time, cycleSeconds)
  const visualLinkAttachments = visualLinkAttachmentReport(diagnostics.visualLinks)
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
    swingFootClearance: swingFootClearance.minClearanceM >= NOETIX_VISUAL_RIG.swingFootClearanceMinM ? 'pass' : 'fail',
    visualLinkAttachments: visualLinkAttachments.status,
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
    swingFootClearance,
    visualLinkAttachments,
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
  const ids = new Set(visualLinks.map(link => link.linkId))
  const duplicateIds = visualLinks
    .map(link => link.linkId)
    .filter((id, index, list) => list.indexOf(id) !== index)
  const missingCount = Math.max(0, NOETIX_VISUAL_RIG.linkCount - ids.size)
  const status = ids.size === NOETIX_VISUAL_RIG.linkCount &&
    duplicateIds.length === 0 &&
    visualLinks.every(link => link.attached)
    ? 'pass'
    : 'fail'
  return {
    status,
    expectedCount: NOETIX_VISUAL_RIG.linkCount,
    attachedCount: ids.size,
    missingCount,
    duplicateIds,
    links: visualLinks.map(link => ({
      linkId: link.linkId,
      geometry: link.geometry,
      source: link.source,
      attached: link.attached,
    })),
  }
}

function cycleSwingFootClearance(time, cycleSeconds) {
  let minClearanceM = Infinity
  let minFrame = null
  let sampleCount = 0
  for (let i = 0; i <= 96; i += 1) {
    const sampleTime = time + (i / 96) * cycleSeconds
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

function cycleFootLockWorldDrift(time, cycleSeconds) {
  const previous = {}
  const perFoot = {
    left: { maxStepM: 0, sampleCount: 0 },
    right: { maxStepM: 0, sampleCount: 0 },
  }
  let maxStepM = 0
  let maxFrame = null
  for (let i = 0; i <= 48; i += 1) {
    const sampleTime = time + (i / 48) * cycleSeconds
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

function cycleFootWorldMotionContinuity(time, cycleSeconds) {
  const previous = {}
  const perFoot = {
    left: { maxStepM: 0, sampleCount: 0 },
    right: { maxStepM: 0, sampleCount: 0 },
  }
  let maxStepM = 0
  let maxFrame = null
  for (let i = 0; i <= 96; i += 1) {
    const sampleTime = time + (i / 96) * cycleSeconds
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

function cycleRootCorrectionContinuity(time, cycleSeconds) {
  let previous = null
  let maxStepM = 0
  let maxFrame = null
  for (let i = 0; i <= 96; i += 1) {
    const sampleTime = time + (i / 96) * cycleSeconds
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
  return { maxStepM, maxFrame, sampleCount: 97 }
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
  const travelZ = z + clip.rootDistanceM
  const a = NOETIX_VISUAL_RIG.terrainReliefMaxM * 0.44
  const b = NOETIX_VISUAL_RIG.terrainReliefMaxM * 0.22
  const kxA = 0.9
  const kzA = 3.1
  const kxB = 2.4
  const kzB = -1.7
  const phaseA = kxA * x + kzA * travelZ
  const phaseB = kxB * x + kzB * travelZ + 0.45
  const heightM = a * Math.sin(phaseA) + b * Math.sin(phaseB)
  const dhdx = a * kxA * Math.cos(phaseA) + b * kxB * Math.cos(phaseB)
  const dhdz = a * kzA * Math.cos(phaseA) + b * kzB * Math.cos(phaseB)
  return {
    heightM,
    normal: normalizeVec3({ x: -dhdx, y: 1, z: -dhdz }),
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
  const startClip = walkClipSample(startTime + 0.000001 / NOETIX_VISUAL_RIG.cycleHz)
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
      min_clearance_m: Number((fk.y - patch.maxHeightM).toFixed(4)),
      max_clearance_m: Number((fk.y - patch.minHeightM).toFixed(4)),
      average_surface_elevation_m: Number(averageElevation.toFixed(4)),
      average_surface_normal: moonphysVector(patch.normal),
      samples: patch.samples.map((sample, index) => ({
        probe_id: `${foot.name}-sole-patch/sample/${index}`,
        position: moonphysPoint(sample),
        surface_elevation_m: Number(sample.y.toFixed(4)),
        surface_normal: moonphysVector(sample.normal),
        clearance_m: Number((fk.y - sample.y).toFixed(4)),
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
    const diagnostics = robotGeometry(time_s).diagnostics
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
  for (const frame of frames) {
    maxTotalNormalForceN = Math.max(maxTotalNormalForceN, frame.review.total_normal_force_n)
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
    },
  }
}

function hingeJointPosition(joints, spec) {
  return joints[spec.side][spec.field]
}

function moonphysJointMotorStep(spec, before, after, dt_s) {
  const beforePosition = hingeJointPosition(before.diagnostics.joints, spec)
  const afterPosition = hingeJointPosition(after.diagnostics.joints, spec)
  const angleDelta = afterPosition - beforePosition
  const targetVelocity = dt_s > 0 ? angleDelta / dt_s : 0
  const boundedVelocity = clamp(targetVelocity, -spec.max_velocity, spec.max_velocity)
  const rawTorque = spec.stiffness * angleDelta + spec.damping * boundedVelocity
  const commandedTorque = clamp(rawTorque, -spec.max_torque, spec.max_torque)
  const positionWithinLimits = afterPosition >= spec.min && afterPosition <= spec.max
  const velocityWithinLimits = Math.abs(targetVelocity) <= spec.max_velocity + 0.000001
  const torqueSaturated = Math.abs(rawTorque - commandedTorque) > 0.000001
  const workJ = commandedTorque * angleDelta
  const status = !positionWithinLimits || !velocityWithinLimits
    ? 'joint-limit-review'
    : torqueSaturated
      ? 'joint-torque-review'
      : 'joint-commanded'
  return {
    joint_id: spec.joint_id,
    parent_link: spec.parent_link,
    child_link: spec.child_link,
    axis: { x: 1, y: 0, z: 0 },
    before_position_rad: Number(beforePosition.toFixed(4)),
    target_position_rad: Number(afterPosition.toFixed(4)),
    target_velocity_rad_s: Number(targetVelocity.toFixed(4)),
    bounded_velocity_rad_s: Number(boundedVelocity.toFixed(4)),
    angle_delta_rad: Number(angleDelta.toFixed(4)),
    commanded_torque_nm: Number(commandedTorque.toFixed(4)),
    work_j: Number(workJ.toFixed(4)),
    stiffness_nm_per_rad: spec.stiffness,
    damping_nm_s_per_rad: spec.damping,
    limit: {
      min_position_rad: spec.min,
      max_position_rad: spec.max,
      max_velocity_rad_s: spec.max_velocity,
      max_torque_nm: spec.max_torque,
      source: NOETIX_URDF_LIMIT_SOURCE.urdf_path,
    },
    position_within_limits: positionWithinLimits,
    velocity_within_limits: velocityWithinLimits,
    torque_saturated: torqueSaturated,
    status,
  }
}

function moonphysHingeMotorFrameEvidence(before, after, frameIndex, dt_s) {
  const steps = NOETIX_HINGE_MOTOR_JOINTS.map(spec => moonphysJointMotorStep(spec, before, after, dt_s))
  const drivenSteps = steps.filter(step => Math.abs(step.angle_delta_rad) > 0.0001)
  const reviewSteps = steps.filter(step => step.status !== 'joint-commanded')
  const totalAbsoluteWorkJ = steps.reduce((sum, step) => sum + Math.abs(step.work_j), 0)
  const maxAbsTorque = Math.max(...steps.map(step => Math.abs(step.commanded_torque_nm)))
  const maxAbsVelocity = Math.max(...steps.map(step => Math.abs(step.target_velocity_rad_s)))
  const maxAbsAngleDelta = Math.max(...steps.map(step => Math.abs(step.angle_delta_rad)))
  return {
    frame_index: frameIndex,
    time_s: before.time_s,
    dt_s: Number(dt_s.toFixed(4)),
    source: 'corrected-fk-joint-samples',
    phase_label: before.diagnostics.phaseLabel,
    support_foot: before.diagnostics.supportFoot,
    joint_count: steps.length,
    driven_joint_count: drivenSteps.length,
    review_count: reviewSteps.length,
    max_abs_angle_delta_rad: Number(maxAbsAngleDelta.toFixed(4)),
    max_abs_velocity_rad_s: Number(maxAbsVelocity.toFixed(4)),
    max_abs_commanded_torque_nm: Number(maxAbsTorque.toFixed(4)),
    total_absolute_work_j: Number(totalAbsoluteWorkJ.toFixed(4)),
    steps,
    status: reviewSteps.length > 0
      ? 'world-heightfield-hinge-motor-review'
      : drivenSteps.length > 0
        ? 'world-heightfield-hinge-motor-driven'
        : 'world-heightfield-hinge-motor-idle',
  }
}

function moonphysHingeMotorReplayEvidence(sampleCount = 24) {
  const cycleSeconds = 1 / NOETIX_VISUAL_RIG.cycleHz
  const dt_s = cycleSeconds / sampleCount
  const samples = Array.from({ length: sampleCount + 1 }, (_, index) => {
    const time_s = index * dt_s
    return {
      time_s: Number(time_s.toFixed(4)),
      diagnostics: robotGeometry(time_s).diagnostics,
    }
  })
  const frames = Array.from({ length: sampleCount }, (_, index) => (
    moonphysHingeMotorFrameEvidence(samples[index], samples[index + 1], index, dt_s)
  ))
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
    sample_source: 'corrected-fk-joint-samples',
    frame_count: frames.length,
    motor_frame_count: frames.length,
    joint_count: NOETIX_HINGE_MOTOR_JOINTS.length,
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

function moonphysMotionHingeReviewEvidence(sampleCount = 24) {
  const motionTrace = moonphysReviewTraceEvidence(sampleCount)
  const hingeTrace = moonphysHingeMotorReplayEvidence(sampleCount)
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
    if (footName === supportFoot || foot.supporting) return 1
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
  const maxDelta = diagnostics.quality.maxTargetFkDelta
  while (debug.children.length < 3) {
    debug.appendChild(document.createElement('span'))
  }
  debug.children[0].textContent = `phase ${diagnostics.gaitPhaseLabel}`
  debug.children[1].textContent = `support ${diagnostics.supportFoot} swing ${diagnostics.swingFoot} lock ${locked}`
  debug.children[2].textContent = `quality ${diagnostics.quality.status} IK ${diagnostics.ik.pelvisCorrectionM.toFixed(3)}m target/FK ${maxDelta.toFixed(3)}m`
}

function initRobot(canvas) {
  const gl = canvas.getContext('webgl', { antialias: true })
  if (!gl) {
    canvas.dataset.sceneStatus = 'webgl-unavailable'
    return
  }
  const debug = document.getElementById('moonmoon-robot-debug')
  const shader = createProgram(gl)
  const buffers = createBuffers(gl)
  const moonphysReviewTrace = moonphysReviewTraceEvidence()
  const moonphysHingeMotorTrace = moonphysHingeMotorReplayEvidence()
  const moonphysMotionHingeReview = moonphysMotionHingeReviewEvidence()
  function draw(now) {
    resizeCanvas(canvas, gl)
    gl.clearColor(0.035, 0.055, 0.052, 1)
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.enable(gl.DEPTH_TEST)
    const aspect = canvas.width / Math.max(1, canvas.height)
    const camera = mat4Translate(mat4Identity(), 0, -0.68, -3.25)
    const scene = mat4RotateX(mat4Identity(), -0.08)
    const mvp = mat4Multiply(mat4Perspective(38 * DEG, aspect, 0.1, 20), mat4Multiply(camera, scene))
    const geometry = robotGeometry(now * 0.001)
    upload(gl, shader, buffers, geometry.vertices, geometry.colors, mvp)
    gl.drawArrays(gl.TRIANGLES, 0, geometry.vertices.length / 3)
    canvas.dataset.sceneStatus = 'robot-rig-webgl-rendered'
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
    canvas.dataset.walkPipeline = 'clip-targets-to-rigid-fk'
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
    canvas.dataset.moonphysReviewFrame = JSON.stringify(moonphysReviewFrameEvidence(geometry.diagnostics))
    canvas.dataset.moonphysReviewTrace = JSON.stringify(moonphysReviewTrace)
    canvas.dataset.moonphysHingeMotorTrace = JSON.stringify(moonphysHingeMotorTrace)
    canvas.dataset.moonphysMotionHingeReview = JSON.stringify(moonphysMotionHingeReview)
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
    canvas.dataset.visualLinkAttachments = JSON.stringify({
      expectedCount: geometry.diagnostics.quality.visualLinkAttachments.expectedCount,
      attachedCount: geometry.diagnostics.quality.visualLinkAttachments.attachedCount,
      missingCount: geometry.diagnostics.quality.visualLinkAttachments.missingCount,
      duplicateIds: geometry.diagnostics.quality.visualLinkAttachments.duplicateIds,
      links: geometry.diagnostics.quality.visualLinkAttachments.links,
    })
    canvas.dataset.linkLengthInvariantStatus = geometry.diagnostics.quality.statuses.linkLengthInvariant
    canvas.dataset.gaitQualityReport = JSON.stringify(geometry.diagnostics.quality)
    canvas.dataset.visualLinkCount = String(NOETIX_VISUAL_RIG.linkCount)
    canvas.dataset.renderedFrames = String(Number(canvas.dataset.renderedFrames || 0) + 1)
    updateRobotDebug(debug, geometry.diagnostics)
    requestAnimationFrame(draw)
  }
  requestAnimationFrame(draw)
}

globalThis.__moonmoonRenderScene3d = modelJson => {
  const view = JSON.parse(modelJson)
  const moon = document.getElementById('moonmoon-globe-3d')
  const robot = document.getElementById('moonmoon-robot-3d')
  if (moon && moon.dataset.sceneBooted !== 'true') {
    moon.dataset.sceneBooted = 'true'
    initMoon(moon, view)
  }
  if (robot && robot.dataset.sceneBooted !== 'true') {
    robot.dataset.sceneBooted = 'true'
    initRobot(robot)
  }
}

globalThis.__moonmoonGaitDiagnostics = {
  rig: NOETIX_VISUAL_RIG,
  sampleRobotGeometry: robotGeometry,
  moonphysReviewFrameEvidence,
  moonphysReviewTraceEvidence,
  moonphysHingeMotorReplayEvidence,
  moonphysMotionHingeReviewEvidence,
}
