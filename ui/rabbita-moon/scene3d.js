const DEG = Math.PI / 180
const LUNAR_TEXTURE_URL = new URL('./assets/lunar_global_texture.jpg', import.meta.url).href

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
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

const NOETIX_VISUAL_RIG = {
  robotId: 'noetix-e1-lab-01',
  source: 'moonrobo-urdf-visual-adapter',
  rootLink: 'base_link',
  linkCount: 13,
  lengths: {
    upperLeg: 0.30,
    lowerLeg: 0.31,
    upperArm: 0.25,
    lowerArm: 0.23,
  },
}

function cycle01(value) {
  return value - Math.floor(value)
}

function smoothstep(value) {
  const t = clamp(value, 0, 1)
  return t * t * (3 - 2 * t)
}

function mix(a, b, t) {
  return a + (b - a) * t
}

function gaitState(time) {
  const phase = cycle01(time * 0.74)
  const leftStance = phase < 0.5
  return {
    phase,
    phaseLabel: leftStance ? 'left-stance-right-swing' : 'right-stance-left-swing',
    supportFoot: leftStance ? 'left' : 'right',
    swingFoot: leftStance ? 'right' : 'left',
    rootDistanceM: time * 0.28,
    bob: Math.cos(phase * Math.PI * 4) * 0.016,
    sway: (leftStance ? 1 : -1) * 0.018 * Math.sin(cycle01(phase * 2) * Math.PI),
  }
}

function legAngles(legPhase) {
  const swing = legPhase >= 0.5
  const u = swing ? (legPhase - 0.5) * 2 : legPhase * 2
  const e = smoothstep(u)
  if (swing) {
    return {
      hip: mix(0.30, -0.38, e),
      knee: 0.10 + 0.58 * Math.sin(u * Math.PI),
      ankle: -0.20 * Math.sin(u * Math.PI) + mix(-0.08, 0.10, e),
    }
  }
  return {
    hip: mix(-0.35, 0.28, e),
    knee: 0.08 + 0.08 * Math.sin(u * Math.PI),
    ankle: mix(0.12, -0.08, e),
  }
}

function armAngles(legPhase) {
  const a = legAngles(cycle01(legPhase + 0.5))
  return {
    shoulder: -a.hip * 0.72,
    elbow: 0.18 + Math.max(0, -a.hip) * 0.24,
  }
}

function addGround(vertices, colors, gait) {
  const offset = gait.rootDistanceM % 0.24
  for (let i = -8; i <= 8; i += 1) {
    const z = i * 0.24 - offset
    addQuad(vertices, colors, [-1.6, 0, z], [1.6, 0, z], [1.6, -0.012, z + 0.018], [-1.6, -0.012, z + 0.018], [0.18, 0.24, 0.21])
  }
  for (let i = -4; i <= 4; i += 1) {
    const x = i * 0.32
    addQuad(vertices, colors, [x, 0, -1.4], [x + 0.014, 0, -1.4], [x + 0.014, -0.012, 1.4], [x, -0.012, 1.4], [0.14, 0.20, 0.18])
  }
}

function addLeg(vertices, colors, root, side, gait, diagnostics) {
  const isLeft = side > 0
  const name = isLeft ? 'left' : 'right'
  const legPhase = cycle01(gait.phase + (isLeft ? 0 : 0.5))
  const angles = legAngles(legPhase)
  const sideColor = isLeft ? [0.88, 0.72, 0.28] : [0.68, 0.76, 0.90]
  const upperLen = NOETIX_VISUAL_RIG.lengths.upperLeg
  const lowerLen = NOETIX_VISUAL_RIG.lengths.lowerLeg
  let hip = mat4Translate(root, side * 0.095, -0.135, 0.005)
  hip = mat4RotateX(hip, angles.hip)
  hip = mat4RotateZ(hip, side * 0.025)
  addCube(vertices, colors, hip, [0, -upperLen * 0.5, 0], [0.065, upperLen, 0.075], sideColor)
  let knee = mat4Translate(hip, 0, -upperLen, 0)
  knee = mat4RotateX(knee, -angles.knee)
  addCube(vertices, colors, knee, [0, -lowerLen * 0.5, 0.008], [0.055, lowerLen, 0.065], [0.78, 0.70, 0.34])
  let ankle = mat4Translate(knee, 0, -lowerLen, 0.006)
  ankle = mat4RotateX(ankle, angles.ankle)
  addCube(vertices, colors, ankle, [0, -0.026, 0.075], [0.095, 0.052, 0.215], [0.50, 0.55, 0.50])
  const sole = transformPoint(ankle, [0, -0.056, 0.13])
  const marker = name === gait.supportFoot ? [0.30, 0.92, 0.50] : [0.94, 0.80, 0.24]
  addCube(vertices, colors, mat4Identity(), sole, [0.055, 0.022, 0.055], marker)
  diagnostics.feet.push({ name, x: sole[0], y: sole[1], z: sole[2] })
}

function addArm(vertices, colors, root, side, gait) {
  const isLeft = side > 0
  const legPhase = cycle01(gait.phase + (isLeft ? 0 : 0.5))
  const angles = armAngles(legPhase)
  const upperLen = NOETIX_VISUAL_RIG.lengths.upperArm
  const lowerLen = NOETIX_VISUAL_RIG.lengths.lowerArm
  let shoulder = mat4Translate(root, side * 0.155, 0.265, 0.0)
  shoulder = mat4RotateX(shoulder, angles.shoulder)
  shoulder = mat4RotateZ(shoulder, side * 0.07)
  addCube(vertices, colors, shoulder, [0, -upperLen * 0.5, 0], [0.045, upperLen, 0.055], [0.56, 0.72, 0.76])
  let elbow = mat4Translate(shoulder, 0, -upperLen, 0)
  elbow = mat4RotateX(elbow, angles.elbow)
  addCube(vertices, colors, elbow, [0, -lowerLen * 0.5, 0.015], [0.040, lowerLen, 0.050], [0.48, 0.64, 0.68])
}

function robotGeometry(time) {
  const vertices = []
  const colors = []
  const gait = gaitState(time)
  const diagnostics = { feet: [] }
  let root = mat4Identity()
  root = mat4Translate(root, gait.sway, 0.79 + gait.bob, 0)
  root = mat4RotateY(root, -0.45)
  root = mat4RotateZ(root, gait.sway * 0.8)
  addCube(vertices, colors, root, [0, -0.025, 0], [0.24, 0.18, 0.18], [0.40, 0.72, 0.70])
  addCube(vertices, colors, root, [0, 0.185, 0.01], [0.22, 0.18, 0.16], [0.46, 0.80, 0.76])
  addCube(vertices, colors, mat4Translate(root, 0, 0.37, 0.015), [0, 0, 0], [0.24, 0.20, 0.15], [0.54, 0.86, 0.80])
  addCube(vertices, colors, mat4Translate(root, 0, 0.52, 0.005), [0, 0, 0], [0.13, 0.12, 0.12], [0.72, 0.92, 0.86])
  for (const side of [-1, 1]) {
    addLeg(vertices, colors, root, side, gait, diagnostics)
    addArm(vertices, colors, root, side, gait)
  }
  addGround(vertices, colors, gait)
  return { vertices, colors, diagnostics: { ...diagnostics, ...gait } }
}

function initRobot(canvas) {
  const gl = canvas.getContext('webgl', { antialias: true })
  if (!gl) {
    canvas.dataset.sceneStatus = 'webgl-unavailable'
    return
  }
  const shader = createProgram(gl)
  const buffers = createBuffers(gl)
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
    canvas.dataset.supportFoot = geometry.diagnostics.supportFoot
    canvas.dataset.swingFoot = geometry.diagnostics.swingFoot
    canvas.dataset.rootDistanceM = geometry.diagnostics.rootDistanceM.toFixed(2)
    canvas.dataset.fkFootEndpoints = JSON.stringify(geometry.diagnostics.feet)
    canvas.dataset.visualLinkCount = String(NOETIX_VISUAL_RIG.linkCount)
    canvas.dataset.renderedFrames = String(Number(canvas.dataset.renderedFrames || 0) + 1)
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
