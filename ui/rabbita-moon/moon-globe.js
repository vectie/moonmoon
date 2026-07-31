import { startCanvasRenderLoop } from './render-lifecycle.js'

const DEG = Math.PI / 180
const LUNAR_TEXTURE_URL = new URL('./assets/lunar_global_texture.jpg', import.meta.url).href

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
}

function identity() {
  return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
}

function multiply(a, b) {
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

function translate(matrix, x, y, z) {
  const next = identity()
  next[12] = x
  next[13] = y
  next[14] = z
  return multiply(matrix, next)
}

function rotateX(matrix, angle) {
  const c = Math.cos(angle)
  const s = Math.sin(angle)
  return multiply(matrix, [1, 0, 0, 0, 0, c, s, 0, 0, -s, c, 0, 0, 0, 0, 1])
}

function rotateY(matrix, angle) {
  const c = Math.cos(angle)
  const s = Math.sin(angle)
  return multiply(matrix, [c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, 0, 0, 0, 1])
}

function perspective(fov, aspect, near, far) {
  const f = 1 / Math.tan(fov / 2)
  const nf = 1 / (near - far)
  return [f / aspect, 0, 0, 0, 0, f, 0, 0, 0, 0, (far + near) * nf, -1, 0, 0, 2 * far * near * nf, 0]
}

function compileProgram(gl, vertexSource, fragmentSource, attributes, uniforms) {
  const compile = (type, source) => {
    const shader = gl.createShader(type)
    gl.shaderSource(shader, source)
    gl.compileShader(shader)
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      throw new Error(gl.getShaderInfoLog(shader) || 'Moon shader compilation failed')
    }
    return shader
  }
  const vertex = compile(gl.VERTEX_SHADER, vertexSource)
  const fragment = compile(gl.FRAGMENT_SHADER, fragmentSource)
  const program = gl.createProgram()
  gl.attachShader(program, vertex)
  gl.attachShader(program, fragment)
  gl.linkProgram(program)
  gl.deleteShader(vertex)
  gl.deleteShader(fragment)
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    throw new Error(gl.getProgramInfoLog(program) || 'Moon shader linking failed')
  }
  return {
    program,
    attributes: Object.fromEntries(attributes.map(name => [name, gl.getAttribLocation(program, name)])),
    uniforms: Object.fromEntries(uniforms.map(name => [name, gl.getUniformLocation(program, name)])),
  }
}

function createSphere(latBands = 44, lonBands = 88) {
  const positions = []
  const uvs = []
  const point = (latitude, longitude) => {
    const latitudeCos = Math.cos(latitude)
    return [latitudeCos * Math.cos(longitude), Math.sin(latitude), latitudeCos * Math.sin(longitude)]
  }
  const push = (position, u, v) => {
    positions.push(...position)
    uvs.push(u, v)
  }
  for (let lat = 0; lat < latBands; lat += 1) {
    const lat0 = -Math.PI / 2 + (lat / latBands) * Math.PI
    const lat1 = -Math.PI / 2 + ((lat + 1) / latBands) * Math.PI
    for (let lon = 0; lon < lonBands; lon += 1) {
      const lon0 = (lon / lonBands) * Math.PI * 2
      const lon1 = ((lon + 1) / lonBands) * Math.PI * 2
      const a = point(lat0, lon0)
      const b = point(lat1, lon0)
      const c = point(lat1, lon1)
      const d = point(lat0, lon1)
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
  return { positions: new Float32Array(positions), uvs: new Float32Array(uvs) }
}

function createBuffer(gl, values) {
  const buffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.bufferData(gl.ARRAY_BUFFER, values, gl.STATIC_DRAW)
  return buffer
}

function createTexture(gl, canvas) {
  const texture = gl.createTexture()
  gl.bindTexture(gl.TEXTURE_2D, texture)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([86, 84, 78, 255]))
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

function resize(canvas, gl) {
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

export function initMoonGlobe(canvas, view) {
  const gl = canvas.getContext('webgl', { antialias: true })
  if (!gl) {
    canvas.dataset.sceneStatus = 'webgl-unavailable'
    return
  }
  const moonProgram = compileProgram(gl, `
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
  `, `
    precision mediump float;
    uniform sampler2D u_texture;
    uniform vec3 u_sun_direction;
    uniform float u_ambient_light;
    varying vec2 v_uv;
    varying vec3 v_normal;
    void main() {
      vec3 tex = texture2D(u_texture, v_uv).rgb;
      float daylight = max(dot(normalize(v_normal), normalize(u_sun_direction)), 0.0);
      float shade = u_ambient_light + daylight * (1.0 - u_ambient_light);
      gl_FragColor = vec4(tex * shade, 1.0);
    }
  `, ['a_position', 'a_uv'], ['u_mvp', 'u_texture', 'u_sun_direction', 'u_ambient_light'])
  const pointProgram = compileProgram(gl, `
    attribute vec3 a_position;
    uniform mat4 u_mvp;
    void main() {
      gl_Position = u_mvp * vec4(a_position, 1.0);
      gl_PointSize = 7.0;
    }
  `, `
    precision mediump float;
    void main() { gl_FragColor = vec4(0.94, 0.76, 0.25, 1.0); }
  `, ['a_position'], ['u_mvp'])
  const sphere = createSphere()
  const positionBuffer = createBuffer(gl, sphere.positions)
  const uvBuffer = createBuffer(gl, sphere.uvs)
  const siteLat = Number(view.site_latitude_deg || -89.88) * DEG
  const siteLon = Number(view.site_longitude_deg || 0.12) * DEG
  const siteRadius = 1.025
  const sitePosition = new Float32Array([
    siteRadius * Math.cos(siteLat) * Math.cos(siteLon),
    siteRadius * Math.sin(siteLat),
    siteRadius * Math.cos(siteLat) * Math.sin(siteLon),
  ])
  const siteBuffer = createBuffer(gl, sitePosition)
  const texture = createTexture(gl, canvas)
  const terrainSwitch = document.getElementById('moon-terrain-switch')
  const focusButton = document.getElementById('moon-focus-site')
  const resetButton = document.getElementById('moon-reset-view')
  const orbitButton = document.getElementById('moon-toggle-orbit')
  const lightingInput = document.getElementById('moon-lighting-time-index')
  const lightingModeButton = document.getElementById('moon-lighting-mode')
  const lighting = view.lighting || {}
  const lightingSamples = lighting.samples || []
  const storedLightingIndex = sessionStorage.getItem('moonmoon.lightingSampleIndex')
  let lightingSampleIndex = clamp(
    Number(storedLightingIndex ?? lighting.default_sample_index ?? 0),
    0,
    Math.max(0, lightingSamples.length - 1),
  )
  let readableLighting = sessionStorage.getItem('moonmoon.lightingMode') === 'readable'
  let sunDirection = [1, 0, 0]
  const defaultView = { yaw: 0.35, pitch: -0.92, distance: 4.05 }
  let { yaw, pitch, distance } = defaultView
  let orbit = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches !== true
  let dragging = false
  let lastX = 0
  let lastY = 0
  const updateOrbitButton = () => {
    if (!orbitButton) return
    const label = orbit ? 'Pause orbit' : 'Resume orbit'
    orbitButton.setAttribute('aria-label', label)
    orbitButton.setAttribute('aria-pressed', String(orbit))
    const tooltip = orbitButton.querySelector('.control-tooltip')
    if (tooltip) tooltip.textContent = label
  }
  const focusSite = () => {
    if (terrainSwitch) {
      terrainSwitch.checked = true
      sessionStorage.setItem('moonmoon.terrainView', 'terrain')
    }
  }
  const resetView = () => {
    if (terrainSwitch) {
      terrainSwitch.checked = false
      sessionStorage.setItem('moonmoon.terrainView', 'moon')
    }
    ;({ yaw, pitch, distance } = defaultView)
  }
  const toggleOrbit = () => {
    orbit = !orbit
    updateOrbitButton()
  }
  const updateLighting = () => {
    const sample = lightingSamples[lightingSampleIndex]
    if (!sample) return
    sunDirection = [sample.sun_body_x, sample.sun_body_z, sample.sun_body_y]
    const setText = (id, value) => {
      const element = document.getElementById(id)
      if (element) element.textContent = value
    }
    setText('moon-lighting-time', sample.timestamp_utc)
    setText('moon-lighting-altitude', `${Number(sample.sun_altitude_deg).toFixed(3)} deg`)
    setText('moon-lighting-azimuth', `${Number(sample.sun_azimuth_deg).toFixed(1)} deg`)
    setText('moon-earth-phase', `${Math.round(Number(sample.earth_illuminated_fraction) * 100)}%`)
    lightingInput?.setAttribute('aria-valuetext', sample.timestamp_utc)
    if (lightingInput) lightingInput.value = String(lightingSampleIndex)
    sessionStorage.setItem('moonmoon.lightingSampleIndex', String(lightingSampleIndex))
    canvas.dataset.lightingTimestamp = sample.timestamp_utc
    canvas.dataset.sunBodyFixed = JSON.stringify([sample.sun_body_x, sample.sun_body_y, sample.sun_body_z])
    canvas.dataset.earthBodyFixed = JSON.stringify([sample.earth_body_x, sample.earth_body_y, sample.earth_body_z])
    canvas.dataset.sunAltitudeDeg = String(sample.sun_altitude_deg)
    canvas.dataset.sunAzimuthDeg = String(sample.sun_azimuth_deg)
    canvas.dataset.earthAltitudeDeg = String(sample.earth_altitude_deg)
    canvas.dataset.earthAzimuthDeg = String(sample.earth_azimuth_deg)
    canvas.dataset.earthIlluminatedFraction = String(sample.earth_illuminated_fraction)
    canvas.dataset.lightingSampleIndex = String(lightingSampleIndex)
    window.dispatchEvent(new CustomEvent('moonmoon:lighting-sample-change', {
      detail: { sampleIndex: lightingSampleIndex, sample },
    }))
  }
  const changeLightingTime = event => {
    lightingSampleIndex = clamp(Number(event.currentTarget.value), 0, Math.max(0, lightingSamples.length - 1))
    event.currentTarget.value = String(lightingSampleIndex)
    updateLighting()
  }
  const setLightingFromPointer = event => {
    if (!lightingInput || lightingSamples.length < 2) return
    const bounds = lightingInput.getBoundingClientRect()
    const ratio = clamp((event.clientX - bounds.left) / Math.max(1, bounds.width), 0, 1)
    lightingInput.value = String(Math.round(ratio * (lightingSamples.length - 1)))
    changeLightingTime({ currentTarget: lightingInput })
  }
  const stepLightingFromKeyboard = event => {
    if (!lightingInput) return
    const delta = event.key === 'ArrowLeft' || event.key === 'ArrowDown'
      ? -1
      : event.key === 'ArrowRight' || event.key === 'ArrowUp'
        ? 1
        : 0
    if (delta === 0) return
    event.preventDefault()
    lightingInput.value = String(clamp(
      Number(lightingInput.value) + delta,
      0,
      Math.max(0, lightingSamples.length - 1),
    ))
    changeLightingTime({ currentTarget: lightingInput })
  }
  const toggleLightingMode = () => {
    readableLighting = !readableLighting
    lightingModeButton.textContent = readableLighting ? 'Readable' : 'Physical'
    lightingModeButton.setAttribute('aria-pressed', String(readableLighting))
    canvas.dataset.lightingMode = readableLighting ? 'readable' : 'physical'
    sessionStorage.setItem('moonmoon.lightingMode', canvas.dataset.lightingMode)
    window.dispatchEvent(new CustomEvent('moonmoon:lighting-mode-change', {
      detail: { mode: canvas.dataset.lightingMode },
    }))
  }
  const changeTerrainView = () => {
    if (!terrainSwitch) return
    sessionStorage.setItem('moonmoon.terrainView', terrainSwitch.checked ? 'terrain' : 'moon')
  }
  focusButton?.addEventListener('click', focusSite)
  resetButton?.addEventListener('click', resetView)
  orbitButton?.addEventListener('click', toggleOrbit)
  lightingInput?.addEventListener('input', changeLightingTime)
  lightingInput?.addEventListener('pointerdown', setLightingFromPointer)
  lightingInput?.addEventListener('keydown', stepLightingFromKeyboard)
  lightingModeButton?.addEventListener('click', toggleLightingMode)
  if (terrainSwitch) {
    terrainSwitch.checked = sessionStorage.getItem('moonmoon.terrainView') === 'terrain'
    terrainSwitch.addEventListener('change', changeTerrainView)
  }
  if (lightingModeButton && readableLighting) {
    lightingModeButton.textContent = 'Readable'
    lightingModeButton.setAttribute('aria-pressed', 'true')
  }
  updateOrbitButton()
  canvas.dataset.lightingModel = lighting.method_id || 'unavailable'
  canvas.dataset.lightingFrame = lighting.frame_id || 'unavailable'
  canvas.dataset.lightingSource = lighting.source_path || 'unavailable'
  canvas.dataset.lightingOrientationSource = lighting.orientation_source_path || 'unavailable'
  canvas.dataset.lightingMode = readableLighting ? 'readable' : 'physical'
  updateLighting()
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
    if (canvas.hasPointerCapture(event.pointerId)) canvas.releasePointerCapture(event.pointerId)
  }
  canvas.onpointercancel = () => {
    dragging = false
  }
  canvas.onwheel = event => {
    event.preventDefault()
    distance = clamp(distance + event.deltaY * 0.003, 2.45, 6.2)
  }
  const bindAttribute = (location, buffer, size) => {
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
    gl.enableVertexAttribArray(location)
    gl.vertexAttribPointer(location, size, gl.FLOAT, false, 0, 0)
  }
  startCanvasRenderLoop(canvas, () => {
    resize(canvas, gl)
    gl.clearColor(0.02, 0.026, 0.024, 1)
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.enable(gl.DEPTH_TEST)
    let model = identity()
    model = rotateX(model, pitch)
    model = rotateY(model, yaw)
    const viewMatrix = translate(identity(), 0, 0, -distance)
    const mvp = multiply(perspective(44 * DEG, canvas.width / Math.max(1, canvas.height), 0.1, 20), multiply(viewMatrix, model))
    gl.useProgram(moonProgram.program)
    gl.uniformMatrix4fv(moonProgram.uniforms.u_mvp, false, new Float32Array(mvp))
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.uniform1i(moonProgram.uniforms.u_texture, 0)
    gl.uniform3f(moonProgram.uniforms.u_sun_direction, sunDirection[0], sunDirection[1], sunDirection[2])
    gl.uniform1f(moonProgram.uniforms.u_ambient_light, readableLighting ? 0.28 : 0.035)
    bindAttribute(moonProgram.attributes.a_position, positionBuffer, 3)
    bindAttribute(moonProgram.attributes.a_uv, uvBuffer, 2)
    gl.drawArrays(gl.TRIANGLES, 0, sphere.positions.length / 3)
    gl.useProgram(pointProgram.program)
    gl.uniformMatrix4fv(pointProgram.uniforms.u_mvp, false, new Float32Array(mvp))
    bindAttribute(pointProgram.attributes.a_position, siteBuffer, 3)
    gl.drawArrays(gl.POINTS, 0, 1)
    canvas.dataset.sceneStatus = 'moon-globe-webgl-rendered'
    canvas.dataset.renderedFrames = String(Number(canvas.dataset.renderedFrames || 0) + 1)
    if (!dragging && orbit) yaw += 0.0015
  }, () => {
    focusButton?.removeEventListener('click', focusSite)
    resetButton?.removeEventListener('click', resetView)
    orbitButton?.removeEventListener('click', toggleOrbit)
    lightingInput?.removeEventListener('input', changeLightingTime)
    lightingInput?.removeEventListener('pointerdown', setLightingFromPointer)
    lightingInput?.removeEventListener('keydown', stepLightingFromKeyboard)
    lightingModeButton?.removeEventListener('click', toggleLightingMode)
    terrainSwitch?.removeEventListener('change', changeTerrainView)
    canvas.onpointerdown = null
    canvas.onpointermove = null
    canvas.onpointerup = null
    canvas.onpointercancel = null
    canvas.onwheel = null
    gl.deleteBuffer(positionBuffer)
    gl.deleteBuffer(uvBuffer)
    gl.deleteBuffer(siteBuffer)
    gl.deleteTexture(texture)
    gl.deleteProgram(moonProgram.program)
    gl.deleteProgram(pointProgram.program)
  })
}
