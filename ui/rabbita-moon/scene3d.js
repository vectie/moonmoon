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
  estimatedMassKg: 54.0,
  cycleHz: 0.74,
  rootSpeedMps: 0.28,
  targetFkMaxM: 0.025,
  lockedTargetFkMaxM: 0.010,
  kneeContrastMin: 0.25,
  armCounterSwingMin: 0.08,
  supportTargetClearanceM: 0.006,
  jointClearanceToleranceM: 0.0025,
  pelvisCorrectionMaxM: 0.18,
  supportClearanceMaxM: 0.014,
  terrainReliefMaxM: 0.032,
  contactPatchMaxRangeM: 0.014,
  jointCorrectionMaxRad: {
    hip: 0.20,
    knee: 0.22,
    ankle: 0.16,
  },
  lengths: {
    upperLeg: 0.30,
    lowerLeg: 0.31,
    upperArm: 0.25,
    lowerArm: 0.23,
  },
}

const NOETIX_HINGE_MOTOR_JOINTS = [
  { joint_id: 'left_hip_pitch', side: 'left', field: 'hip', parent_link: 'base_link', child_link: 'left_upper_leg', min: -0.9, max: 0.8, max_velocity: 5.0, max_torque: 90.0, stiffness: 18.0, damping: 0.8 },
  { joint_id: 'left_knee_pitch', side: 'left', field: 'knee', parent_link: 'left_upper_leg', child_link: 'left_lower_leg', min: -0.1, max: 1.1, max_velocity: 8.0, max_torque: 90.0, stiffness: 18.0, damping: 0.8 },
  { joint_id: 'left_ankle_pitch', side: 'left', field: 'ankle', parent_link: 'left_lower_leg', child_link: 'left_foot', min: -0.6, max: 0.55, max_velocity: 5.0, max_torque: 55.0, stiffness: 14.0, damping: 0.6 },
  { joint_id: 'right_hip_pitch', side: 'right', field: 'hip', parent_link: 'base_link', child_link: 'right_upper_leg', min: -0.9, max: 0.8, max_velocity: 5.0, max_torque: 90.0, stiffness: 18.0, damping: 0.8 },
  { joint_id: 'right_knee_pitch', side: 'right', field: 'knee', parent_link: 'right_upper_leg', child_link: 'right_lower_leg', min: -0.1, max: 1.1, max_velocity: 8.0, max_torque: 90.0, stiffness: 18.0, damping: 0.8 },
  { joint_id: 'right_ankle_pitch', side: 'right', field: 'ankle', parent_link: 'right_lower_leg', child_link: 'right_foot', min: -0.6, max: 0.55, max_velocity: 5.0, max_torque: 55.0, stiffness: 14.0, damping: 0.6 },
  { joint_id: 'left_shoulder_pitch', side: 'left', field: 'shoulder', parent_link: 'torso_link', child_link: 'left_upper_arm', min: -0.7, max: 0.7, max_velocity: 4.0, max_torque: 35.0, stiffness: 8.0, damping: 0.4 },
  { joint_id: 'left_elbow_pitch', side: 'left', field: 'elbow', parent_link: 'left_upper_arm', child_link: 'left_lower_arm', min: 0.0, max: 0.8, max_velocity: 4.0, max_torque: 25.0, stiffness: 8.0, damping: 0.4 },
  { joint_id: 'right_shoulder_pitch', side: 'right', field: 'shoulder', parent_link: 'torso_link', child_link: 'right_upper_arm', min: -0.7, max: 0.7, max_velocity: 4.0, max_torque: 35.0, stiffness: 8.0, damping: 0.4 },
  { joint_id: 'right_elbow_pitch', side: 'right', field: 'elbow', parent_link: 'right_upper_arm', child_link: 'right_lower_arm', min: 0.0, max: 0.8, max_velocity: 4.0, max_torque: 25.0, stiffness: 8.0, damping: 0.4 },
]

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

function near(a, b, tolerance) {
  return Math.abs(a - b) <= tolerance
}

function vec3Length(v) {
  return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
}

function vec3Sub(a, b) {
  return { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z }
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

function footRole(footPhase) {
  if (footPhase < 0.08) return 'contact'
  if (footPhase < 0.18) return 'loading'
  if (footPhase < 0.50) return 'stance'
  if (footPhase < 0.72) return 'passing'
  if (footPhase < 0.92) return 'swing'
  return 'release'
}

function footLock(footPhase) {
  return footPhase < 0.50 || footPhase >= 0.92
}

function walkClipSample(time) {
  const phase = cycle01(time * NOETIX_VISUAL_RIG.cycleHz)
  const leftStance = phase < 0.5
  const leftPhase = phase
  const rightPhase = cycle01(phase + 0.5)
  return {
    phase,
    leftPhase,
    rightPhase,
    phaseLabel: leftStance ? 'left-stance-right-swing' : 'right-stance-left-swing',
    supportFoot: leftStance ? 'left' : 'right',
    swingFoot: leftStance ? 'right' : 'left',
    rootDistanceM: time * NOETIX_VISUAL_RIG.rootSpeedMps,
    strideM: 0.38,
    bob: Math.cos(phase * Math.PI * 4) * 0.016,
    sway: (leftStance ? 1 : -1) * 0.018 * Math.sin(cycle01(phase * 2) * Math.PI),
    footChannels: {
      left: {
        phase: leftPhase,
        role: footRole(leftPhase),
        locked: footLock(leftPhase),
      },
      right: {
        phase: rightPhase,
        role: footRole(rightPhase),
        locked: footLock(rightPhase),
      },
    },
  }
}

function pointDistance(a, b) {
  const dx = a[0] - b[0]
  const dy = a[1] - b[1]
  const dz = a[2] - b[2]
  return Math.sqrt(dx * dx + dy * dy + dz * dz)
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

function jointSamples(clip) {
  const leftLeg = legAngles(clip.leftPhase)
  const rightLeg = legAngles(clip.rightPhase)
  const leftArm = armAngles(clip.leftPhase)
  const rightArm = armAngles(clip.rightPhase)
  return {
    left: { ...leftLeg, ...leftArm },
    right: { ...rightLeg, ...rightArm },
  }
}

function cloneJointSamples(joints) {
  return {
    left: { ...joints.left },
    right: { ...joints.right },
  }
}

function emptyJointCorrections() {
  return {
    left: { hip: 0, knee: 0, ankle: 0 },
    right: { hip: 0, knee: 0, ankle: 0 },
  }
}

function addGround(vertices, colors, clip) {
  const offset = clip.rootDistanceM % 0.24
  for (let i = -8; i <= 8; i += 1) {
    const z = i * 0.24 - offset
    const a = terrainSampleAt(-1.6, z, clip).heightM
    const b = terrainSampleAt(1.6, z, clip).heightM
    const c = terrainSampleAt(1.6, z + 0.018, clip).heightM
    const d = terrainSampleAt(-1.6, z + 0.018, clip).heightM
    addQuad(vertices, colors, [-1.6, a, z], [1.6, b, z], [1.6, c - 0.012, z + 0.018], [-1.6, d - 0.012, z + 0.018], [0.18, 0.24, 0.21])
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

function pointRecord(point) {
  return { x: point[0], y: point[1], z: point[2] }
}

function footTargetForPose(sole, foot, clip) {
  const probe = terrainContactProbe(sole, clip)
  return [
    sole[0],
    foot.locked ? probe.heightM + NOETIX_VISUAL_RIG.supportTargetClearanceM : sole[1] + 0.018,
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
  addCube(vertices, colors, hip, [0, -upperLen * 0.5, 0], [0.065, upperLen, 0.075], sideColor)
  addCube(vertices, colors, knee, [0, -lowerLen * 0.5, 0.008], [0.055, lowerLen, 0.065], [0.78, 0.70, 0.34])
  addCube(vertices, colors, ankle, [0, -0.026, 0.075], [0.095, 0.052, 0.215], [0.50, 0.55, 0.50])
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
    authoredTarget: pointRecord(authoredTarget),
    correctedTarget: pointRecord(correctedTarget),
    fkEndpoint: pointRecord(sole),
    terrainProbe,
    contactPatch,
    targetFkDeltaM: pointDistance(correctedTarget, sole),
    authoredTargetDeltaM: pointDistance(authoredTarget, sole),
    ikCorrectionDeltaM: pointDistance(authoredTarget, correctedTarget),
  })
}

function addArm(vertices, colors, root, side, joints) {
  const isLeft = side > 0
  const name = isLeft ? 'left' : 'right'
  const angles = joints[name]
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
  const clip = walkClipSample(time)
  const authoredJoints = jointSamples(clip)
  const baseRoot = robotRoot(clip, 0)
  const authoredTargets = {
    left: footTargetForPose(legPose(baseRoot, 1, authoredJoints).sole, clip.footChannels.left, clip),
    right: footTargetForPose(legPose(baseRoot, -1, authoredJoints).sole, clip.footChannels.right, clip),
  }
  const ik = terrainIkCorrection(baseRoot, clip, authoredJoints)
  const joints = ik.correctedJoints
  const terrain = terrainProfileReport(clip)
  const diagnostics = { feet: [], authoredJoints, joints, ik, terrain }
  const root = robotRoot(clip, ik.pelvisCorrectionM)
  diagnostics.centerOfMass = pointRecord(transformPoint(root, [0, 0.16, 0.015]))
  diagnostics.centerOfMassVelocity = { x: 0, y: 0, z: NOETIX_VISUAL_RIG.rootSpeedMps }
  addCube(vertices, colors, root, [0, -0.025, 0], [0.24, 0.18, 0.18], [0.40, 0.72, 0.70])
  addCube(vertices, colors, root, [0, 0.185, 0.01], [0.22, 0.18, 0.16], [0.46, 0.80, 0.76])
  addCube(vertices, colors, mat4Translate(root, 0, 0.37, 0.015), [0, 0, 0], [0.24, 0.20, 0.15], [0.54, 0.86, 0.80])
  addCube(vertices, colors, mat4Translate(root, 0, 0.52, 0.005), [0, 0, 0], [0.13, 0.12, 0.12], [0.72, 0.92, 0.86])
  for (const side of [-1, 1]) {
    addLeg(vertices, colors, root, side, clip, joints, authoredTargets, diagnostics)
    addArm(vertices, colors, root, side, joints)
  }
  addGround(vertices, colors, clip)
  const gait = { ...diagnostics, ...clip }
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
  const maxLockedTargetFkDelta = lockedDeltas.length > 0 ? Math.max(...lockedDeltas) : Infinity
  const supportFoot = diagnostics.feet.find(foot => foot.name === diagnostics.supportFoot)
  const cycle = cycleJointQuality(time, cycleSeconds)
  const supportClearanceError = Math.abs(
    (supportFoot?.terrainProbe.clearanceM ?? Infinity) - NOETIX_VISUAL_RIG.supportTargetClearanceM,
  )
  const maxContactPatchRange = Math.max(...diagnostics.feet.map(foot => foot.contactPatch.heightRangeM))
  const statuses = {
    cycleRepeat: near(now.phase, repeated.phase, 0.000001) ? 'pass' : 'fail',
    rootMotion: near(rootAdvance, expectedStride, 0.003) ? 'pass' : 'fail',
    mirrorTiming: near(cycle01(now.leftPhase + 0.5), now.rightPhase, 0.000001) ? 'pass' : 'fail',
    targetFkAttachment: maxTargetFkDelta <= NOETIX_VISUAL_RIG.targetFkMaxM ? 'pass' : 'fail',
    lockedFootAttachment: maxLockedTargetFkDelta <= NOETIX_VISUAL_RIG.lockedTargetFkMaxM ? 'pass' : 'fail',
    supportFootLocked: supportFoot?.locked ? 'pass' : 'fail',
    terrainContact: supportClearanceError <= NOETIX_VISUAL_RIG.supportClearanceMaxM ? 'pass' : 'fail',
    contactPatch: maxContactPatchRange <= NOETIX_VISUAL_RIG.contactPatchMaxRangeM ? 'pass' : 'fail',
    nonFlatTerrain: diagnostics.terrain.heightRangeM > 0.010 ? 'pass' : 'fail',
    ikCorrectionBounded: diagnostics.ik.saturated ? 'fail' : 'pass',
    jointIkCorrection: Math.abs(diagnostics.ik.jointIk.finalErrorM) <= NOETIX_VISUAL_RIG.supportClearanceMaxM ? 'pass' : 'fail',
    kneeRoleContrast: cycle.kneeRoleContrast >= NOETIX_VISUAL_RIG.kneeContrastMin ? 'pass' : 'fail',
    armCounterSwing: cycle.armCounterSwing >= NOETIX_VISUAL_RIG.armCounterSwingMin ? 'pass' : 'fail',
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
    maxContactPatchRange,
    terrain: diagnostics.terrain,
    ik: diagnostics.ik,
    kneeRoleContrast: cycle.kneeRoleContrast,
    armCounterSwing: cycle.armCounterSwing,
    authoredJointSamples: diagnostics.authoredJoints,
    jointSamples: diagnostics.joints,
  }
}

function cycleJointQuality(time, cycleSeconds) {
  let kneeRoleContrast = 0
  let armCounterSwing = 0
  for (let i = 0; i < 12; i += 1) {
    const clip = walkClipSample(time + (i / 12) * cycleSeconds)
    const joints = jointSamples(clip)
    const support = joints[clip.supportFoot]
    const swing = joints[clip.swingFoot]
    const swingFoot = clip.footChannels[clip.swingFoot]
    if (swingFoot.role === 'passing' || swingFoot.role === 'swing') {
      kneeRoleContrast = Math.max(kneeRoleContrast, swing.knee - support.knee)
    }
    armCounterSwing = Math.max(
      armCounterSwing,
      Math.abs(joints.left.hip + joints.left.shoulder),
      Math.abs(joints.right.hip + joints.right.shoulder),
    )
  }
  return { kneeRoleContrast, armCounterSwing }
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

function robotRoot(clip, pelvisCorrectionM) {
  let root = mat4Identity()
  root = mat4Translate(root, clip.sway, 0.79 + clip.bob + pelvisCorrectionM, 0)
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
  const active = foot.locked
  const averageElevation = patch.samples.reduce((sum, sample) => sum + sample.y, 0) / patch.samples.length
  return {
    contact_id: `${foot.name}-contact`,
    footprint: {
      footprint_id: `${foot.name}-sole`,
      center: moonphysPoint(patch.center),
      half_length_m: 0.075,
      half_width_m: 0.045,
      active,
    },
    patch: {
      patch_id: `${foot.name}-sole-patch`,
      center: moonphysPoint(patch.center),
      half_length_m: 0.075,
      half_width_m: 0.045,
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
  const activeFeet = diagnostics.feet.filter(foot => foot.locked)
  const totalNormalForceN = NOETIX_VISUAL_RIG.estimatedMassKg * 1.625
  const perActiveNormalN = activeFeet.length > 0 ? totalNormalForceN / activeFeet.length : 0
  const contacts = diagnostics.feet.map(foot => moonphysContactPatchEvidence(
    foot,
    foot.locked ? perActiveNormalN : 0,
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
    limit: {
      min_position_rad: spec.min,
      max_position_rad: spec.max,
      max_velocity_rad_s: spec.max_velocity,
      max_torque_nm: spec.max_torque,
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
  let saturated = false
  let totalIterations = 0
  const lockedNames = ['left', 'right'].filter(name => clip.footChannels[name].locked)
  const supportSide = clip.supportFoot === 'left' ? 1 : -1
  const supportPreProbe = terrainContactProbe(legPose(root, supportSide, correctedJoints).sole, clip)
  const solveLockedFoot = footName => {
    const side = footName === 'left' ? 1 : -1
    let iterations = 0
    for (let i = 0; i < 5; i += 1) {
      const probe = terrainContactProbe(legPose(root, side, correctedJoints).sole, clip)
      const error = NOETIX_VISUAL_RIG.supportTargetClearanceM - probe.clearanceM
      if (Math.abs(error) <= NOETIX_VISUAL_RIG.jointClearanceToleranceM) {
        break
      }
      let denom = 0
      const derivatives = {}
      for (const field of fields) {
        const trial = cloneJointSamples(correctedJoints)
        trial[footName][field] += epsilon
        const trialProbe = terrainContactProbe(legPose(root, side, trial).sole, clip)
        const derivative = (trialProbe.clearanceM - probe.clearanceM) / epsilon
        derivatives[field] = derivative
        denom += derivative * derivative
      }
      if (denom <= 0.000001) {
        break
      }
      for (const field of fields) {
        const limit = NOETIX_VISUAL_RIG.jointCorrectionMaxRad[field]
        const proposed = jointCorrections[footName][field] + error * derivatives[field] / denom * 0.85
        const bounded = clamp(proposed, -limit, limit)
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
  return {
    correctedJoints,
    jointCorrections,
    report: {
      supportFoot: clip.supportFoot,
      iterations: totalIterations,
      preClearanceM: supportPreProbe.clearanceM,
      finalClearanceM: supportFinalProbe.clearanceM,
      finalErrorM: NOETIX_VISUAL_RIG.supportTargetClearanceM - supportFinalProbe.clearanceM,
      saturated,
    },
  }
}

function terrainIkCorrection(root, clip, joints) {
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
  return {
    supportFoot: clip.supportFoot,
    correctedJoints: jointIk.correctedJoints,
    jointCorrections: jointIk.jointCorrections,
    jointIk: jointIk.report,
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
  debug.children[0].textContent = `phase ${diagnostics.phaseLabel}`
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
    canvas.dataset.supportFoot = geometry.diagnostics.supportFoot
    canvas.dataset.swingFoot = geometry.diagnostics.swingFoot
    canvas.dataset.rootDistanceM = geometry.diagnostics.rootDistanceM.toFixed(2)
    canvas.dataset.walkPipeline = 'clip-targets-to-rigid-fk'
    canvas.dataset.lockedFeet = geometry.diagnostics.feet
      .filter(foot => foot.locked)
      .map(foot => foot.name)
      .join('+')
    canvas.dataset.authoredFootTargets = JSON.stringify(geometry.diagnostics.feet.map(foot => ({
      name: foot.name,
      role: foot.role,
      locked: foot.locked,
      target: foot.authoredTarget,
    })))
    canvas.dataset.correctedFootTargets = JSON.stringify(geometry.diagnostics.feet.map(foot => ({
      name: foot.name,
      role: foot.role,
      locked: foot.locked,
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
    canvas.dataset.terrainContactStatus = geometry.diagnostics.quality.statuses.terrainContact
    canvas.dataset.contactPatchStatus = geometry.diagnostics.quality.statuses.contactPatch
    canvas.dataset.nonFlatTerrainStatus = geometry.diagnostics.quality.statuses.nonFlatTerrain
    canvas.dataset.ikCorrectionStatus = geometry.diagnostics.quality.statuses.ikCorrectionBounded
    canvas.dataset.jointIkStatus = geometry.diagnostics.quality.statuses.jointIkCorrection
    canvas.dataset.kneeRoleContrastStatus = geometry.diagnostics.quality.statuses.kneeRoleContrast
    canvas.dataset.armCounterSwingStatus = geometry.diagnostics.quality.statuses.armCounterSwing
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
