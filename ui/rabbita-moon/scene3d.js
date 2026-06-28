const DEG = Math.PI / 180

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

function sphereMesh(latBands, lonBands) {
  const vertices = []
  const colors = []
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
      const shade = 0.46 + Math.max(0, Math.cos(p0 - 0.8) * Math.cos(t0)) * 0.38
      const polar = Math.abs(Math.sin((t0 + t1) * 0.5))
      const color = [0.42 * shade + polar * 0.16, 0.43 * shade + polar * 0.15, 0.39 * shade + polar * 0.12]
      addQuad(vertices, colors, a, b, c, d, color)
    }
  }
  return { vertices, colors }
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

function initMoon(canvas, view) {
  const gl = canvas.getContext('webgl', { antialias: true })
  if (!gl) {
    canvas.dataset.sceneStatus = 'webgl-unavailable'
    return
  }
  const shader = createProgram(gl)
  const buffers = createBuffers(gl)
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
    upload(gl, shader, buffers, mesh.vertices, mesh.colors, mvp)
    gl.drawArrays(gl.TRIANGLES, 0, mesh.vertices.length / 3)

    const point = latLonPoint(site.lat, site.lon)
    upload(gl, shader, buffers, point, [0.94, 0.76, 0.25], mvp)
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

function limbMatrix(root, sideOffset, yaw, bend, lift) {
  let m = mat4Translate(root, sideOffset, 0, 0)
  m = mat4RotateX(m, yaw)
  m = mat4RotateZ(m, bend)
  m = mat4Translate(m, 0, lift, 0)
  return m
}

function robotGeometry(time) {
  const vertices = []
  const colors = []
  const step = time * 2.2
  const sway = Math.sin(step) * 0.055
  const bob = Math.abs(Math.sin(step)) * 0.07
  let root = mat4Identity()
  root = mat4Translate(root, 0, 0.92 + bob, 0)
  root = mat4RotateY(root, -0.45)
  root = mat4RotateZ(root, sway)
  const body = [0.18, 0.46, 0.12]
  const metal = [0.44, 0.82, 0.77]
  const leg = [0.94, 0.74, 0.30]
  const arm = [0.62, 0.72, 0.79]
  addCube(vertices, colors, root, [0, 0.18, 0], body, metal)
  addCube(vertices, colors, mat4Translate(root, 0, 0.54, 0), [0, 0, 0], [0.12, 0.12, 0.12], [0.70, 0.90, 0.86])
  for (const side of [-1, 1]) {
    const phase = Math.sin(step + (side < 0 ? 0 : Math.PI))
    const knee = Math.max(0, phase) * 0.42
    const hip = phase * 0.42
    let upper = limbMatrix(root, side * 0.075, hip, side * 0.03, -0.18)
    addCube(vertices, colors, upper, [0, -0.16, 0], [0.055, 0.30, 0.07], leg)
    let lower = mat4Translate(upper, 0, -0.32, 0)
    lower = mat4RotateX(lower, -knee)
    addCube(vertices, colors, lower, [0, -0.14, 0.025], [0.050, 0.28, 0.06], leg)
    addCube(vertices, colors, mat4Translate(lower, 0, -0.30, 0.075), [0, 0, 0], [0.075, 0.04, 0.16], [0.78, 0.64, 0.34])
    let shoulder = limbMatrix(root, side * 0.14, -hip * 0.58, side * 0.04, 0.22)
    addCube(vertices, colors, shoulder, [0, -0.15, 0], [0.045, 0.28, 0.055], arm)
  }
  for (let i = -4; i <= 4; i += 1) {
    addQuad(vertices, colors, [-1.4, 0, i * 0.22], [1.4, 0, i * 0.22], [1.4, -0.012, i * 0.22], [-1.4, -0.012, i * 0.22], [0.18, 0.24, 0.21])
  }
  return { vertices, colors }
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
    canvas.dataset.motionStatus = 'endless-visual-gait'
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
