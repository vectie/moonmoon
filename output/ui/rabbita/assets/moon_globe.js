(function () {
  const DEG = Math.PI / 180;

  function createShader(gl, type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      throw new Error(gl.getShaderInfoLog(shader) || 'shader compile failed');
    }
    return shader;
  }

  function createProgram(gl, vertexSource, fragmentSource) {
    const program = gl.createProgram();
    gl.attachShader(program, createShader(gl, gl.VERTEX_SHADER, vertexSource));
    gl.attachShader(program, createShader(gl, gl.FRAGMENT_SHADER, fragmentSource));
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Error(gl.getProgramInfoLog(program) || 'program link failed');
    }
    return program;
  }

  function identity() {
    return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
  }

  function multiply(a, b) {
    const out = new Array(16);
    for (let col = 0; col < 4; col += 1) {
      for (let row = 0; row < 4; row += 1) {
        out[col * 4 + row] =
          a[0 * 4 + row] * b[col * 4 + 0] +
          a[1 * 4 + row] * b[col * 4 + 1] +
          a[2 * 4 + row] * b[col * 4 + 2] +
          a[3 * 4 + row] * b[col * 4 + 3];
      }
    }
    return out;
  }

  function perspective(fov, aspect, near, far) {
    const f = 1 / Math.tan(fov / 2);
    const nf = 1 / (near - far);
    return [
      f / aspect, 0, 0, 0,
      0, f, 0, 0,
      0, 0, (far + near) * nf, -1,
      0, 0, 2 * far * near * nf, 0
    ];
  }

  function translate(matrix, x, y, z) {
    const t = identity();
    t[12] = x;
    t[13] = y;
    t[14] = z;
    return multiply(matrix, t);
  }

  function rotateX(matrix, angle) {
    const c = Math.cos(angle);
    const s = Math.sin(angle);
    return multiply(matrix, [
      1, 0, 0, 0,
      0, c, s, 0,
      0, -s, c, 0,
      0, 0, 0, 1
    ]);
  }

  function rotateY(matrix, angle) {
    const c = Math.cos(angle);
    const s = Math.sin(angle);
    return multiply(matrix, [
      c, 0, -s, 0,
      0, 1, 0, 0,
      s, 0, c, 0,
      0, 0, 0, 1
    ]);
  }

  function transform(matrix, point, w) {
    return [
      matrix[0] * point[0] + matrix[4] * point[1] + matrix[8] * point[2] + matrix[12] * w,
      matrix[1] * point[0] + matrix[5] * point[1] + matrix[9] * point[2] + matrix[13] * w,
      matrix[2] * point[0] + matrix[6] * point[1] + matrix[10] * point[2] + matrix[14] * w,
      matrix[3] * point[0] + matrix[7] * point[1] + matrix[11] * point[2] + matrix[15] * w
    ];
  }

  function sphereMesh(latBands, lonBands) {
    const vertices = [];
    const indices = [];
    for (let lat = 0; lat <= latBands; lat += 1) {
      const v = lat / latBands;
      const theta = (v - 0.5) * Math.PI;
      const cosLat = Math.cos(theta);
      const sinLat = Math.sin(theta);
      for (let lon = 0; lon <= lonBands; lon += 1) {
        const u = lon / lonBands;
        const phi = u * Math.PI * 2;
        const x = cosLat * Math.cos(phi);
        const y = sinLat;
        const z = cosLat * Math.sin(phi);
        vertices.push(x, y, z, 1 - u, 1 - v);
      }
    }
    for (let lat = 0; lat < latBands; lat += 1) {
      for (let lon = 0; lon < lonBands; lon += 1) {
        const a = lat * (lonBands + 1) + lon;
        const b = a + lonBands + 1;
        indices.push(a, b, a + 1, b, b + 1, a + 1);
      }
    }
    return {
      vertices: new Float32Array(vertices),
      indices: new Uint16Array(indices)
    };
  }

  function coordinatePoint(latDeg, lonDeg) {
    const lat = latDeg * DEG;
    const lon = lonDeg * DEG;
    const cosLat = Math.cos(lat);
    return [
      cosLat * Math.cos(lon),
      Math.sin(lat),
      cosLat * Math.sin(lon)
    ];
  }

  function initMoonGlobe(root) {
    const canvas = root.querySelector('.moon-globe-canvas');
    const marker = root.querySelector('.moon-globe-marker');
    const status = root.querySelector('.moon-globe-status');
    const view = JSON.parse(document.getElementById('moonmoon-view-model').textContent);
    const textureUrl = root.getAttribute('data-texture');
    const fallback = root.querySelector('.moon-globe-fallback');
    const gl = canvas.getContext('webgl', { antialias: true, alpha: true });
    if (!gl) {
      root.classList.add('moon-globe-no-webgl');
      if (status) status.textContent = 'static fallback';
      return;
    }

    const vertexSource = `
      attribute vec3 aPosition;
      attribute vec2 aUv;
      uniform mat4 uModel;
      uniform mat4 uMvp;
      varying vec2 vUv;
      varying vec3 vNormal;
      void main() {
        vUv = aUv;
        vNormal = normalize((uModel * vec4(aPosition, 0.0)).xyz);
        gl_Position = uMvp * vec4(aPosition, 1.0);
      }
    `;
    const fragmentSource = `
      precision mediump float;
      uniform sampler2D uTexture;
      varying vec2 vUv;
      varying vec3 vNormal;
      void main() {
        vec3 tex = texture2D(uTexture, vUv).rgb;
        vec3 light = normalize(vec3(-0.35, 0.42, 0.84));
        float shade = 0.28 + max(dot(normalize(vNormal), light), 0.0) * 0.86;
        float rim = pow(1.0 - max(dot(normalize(vNormal), vec3(0.0, 0.0, 1.0)), 0.0), 2.0);
        gl_FragColor = vec4(tex * shade + vec3(0.08, 0.11, 0.12) * rim, 1.0);
      }
    `;
    const program = createProgram(gl, vertexSource, fragmentSource);
    const mesh = sphereMesh(72, 144);
    const vertexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, mesh.vertices, gl.STATIC_DRAW);
    const indexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, mesh.indices, gl.STATIC_DRAW);

    const aPosition = gl.getAttribLocation(program, 'aPosition');
    const aUv = gl.getAttribLocation(program, 'aUv');
    const uModel = gl.getUniformLocation(program, 'uModel');
    const uMvp = gl.getUniformLocation(program, 'uMvp');
    const uTexture = gl.getUniformLocation(program, 'uTexture');

    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texImage2D(
      gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE,
      new Uint8Array([76, 76, 72, 255])
    );

    let textureReady = false;
    const image = new Image();
    image.onload = () => {
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
      textureReady = true;
      root.classList.add('moon-globe-ready');
      if (fallback) fallback.setAttribute('aria-hidden', 'true');
      if (status) status.textContent = 'live globe';
      render();
    };
    image.onerror = () => {
      root.classList.add('moon-globe-no-webgl');
      if (status) status.textContent = 'texture unavailable';
    };
    image.src = textureUrl;

    const site = {
      lat: Number(view.site_latitude_deg || -89.88),
      lon: Number(view.site_longitude_deg || 0.12)
    };
    const sitePoint = coordinatePoint(site.lat, site.lon);
    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const state = {
      rotationX: -1.18,
      rotationY: 0,
      zoom: 3.6,
      dragging: false,
      lastX: 0,
      lastY: 0,
      target: null
    };

    function modelMatrix() {
      return rotateX(rotateY(identity(), state.rotationY), state.rotationX);
    }

    function mvpMatrix() {
      const aspect = Math.max(0.5, canvas.clientWidth / Math.max(1, canvas.clientHeight));
      const proj = perspective(42 * DEG, aspect, 0.1, 20);
      const view = translate(identity(), 0, 0, -state.zoom);
      const viewModel = multiply(view, modelMatrix());
      return multiply(proj, viewModel);
    }

    function resizeCanvas() {
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      const width = Math.max(320, Math.floor(canvas.clientWidth * dpr));
      const height = Math.max(220, Math.floor(canvas.clientHeight * dpr));
      if (canvas.width !== width || canvas.height !== height) {
        canvas.width = width;
        canvas.height = height;
      }
      gl.viewport(0, 0, canvas.width, canvas.height);
    }

    function updateMarker(model, mvp) {
      if (!marker) return;
      const modelPoint = transform(model, sitePoint, 1);
      const clip = transform(mvp, sitePoint, 1);
      if (clip[3] <= 0 || modelPoint[2] < -0.05) {
        marker.hidden = true;
        return;
      }
      const ndcX = clip[0] / clip[3];
      const ndcY = clip[1] / clip[3];
      if (Math.abs(ndcX) > 1.05 || Math.abs(ndcY) > 1.05) {
        marker.hidden = true;
        return;
      }
      marker.hidden = false;
      marker.style.left = `${(ndcX * 0.5 + 0.5) * 100}%`;
      marker.style.top = `${(-ndcY * 0.5 + 0.5) * 100}%`;
    }

    function render() {
      resizeCanvas();
      const model = modelMatrix();
      const mvp = mvpMatrix();
      gl.clearColor(0.02, 0.025, 0.025, 1);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
      gl.enable(gl.DEPTH_TEST);
      gl.useProgram(program);
      gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
      gl.enableVertexAttribArray(aPosition);
      gl.vertexAttribPointer(aPosition, 3, gl.FLOAT, false, 20, 0);
      gl.enableVertexAttribArray(aUv);
      gl.vertexAttribPointer(aUv, 2, gl.FLOAT, false, 20, 12);
      gl.uniformMatrix4fv(uModel, false, new Float32Array(model));
      gl.uniformMatrix4fv(uMvp, false, new Float32Array(mvp));
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.uniform1i(uTexture, 0);
      gl.drawElements(gl.TRIANGLES, mesh.indices.length, gl.UNSIGNED_SHORT, 0);
      updateMarker(model, mvp);
      root.dataset.globeReady = textureReady ? 'true' : 'loading';
    }

    function animateTo(next) {
      if (reducedMotion) {
        Object.assign(state, next);
        render();
        return;
      }
      const start = {
        rotationX: state.rotationX,
        rotationY: state.rotationY,
        zoom: state.zoom
      };
      const started = performance.now();
      const duration = 760;
      function tick(now) {
        const t = Math.min(1, (now - started) / duration);
        const ease = 1 - Math.pow(1 - t, 3);
        state.rotationX = start.rotationX + (next.rotationX - start.rotationX) * ease;
        state.rotationY = start.rotationY + (next.rotationY - start.rotationY) * ease;
        state.zoom = start.zoom + (next.zoom - start.zoom) * ease;
        render();
        if (t < 1) requestAnimationFrame(tick);
      }
      requestAnimationFrame(tick);
    }

    function flyToSite() {
      if (Math.abs(site.lat) > 80) {
        animateTo({
          rotationX: site.lat < 0 ? -1.45 : 1.45,
          rotationY: 0,
          zoom: 3.1
        });
        return;
      }
      const lat = site.lat * DEG;
      const lon = site.lon * DEG;
      animateTo({
        rotationX: lat - 0.18,
        rotationY: lon - Math.PI / 2,
        zoom: 2.8
      });
    }

    function resetHome() {
      animateTo({ rotationX: -1.18, rotationY: 0, zoom: 3.6 });
    }

    canvas.addEventListener('pointerdown', event => {
      state.dragging = true;
      state.lastX = event.clientX;
      state.lastY = event.clientY;
      canvas.setPointerCapture(event.pointerId);
    });
    canvas.addEventListener('pointermove', event => {
      if (!state.dragging) return;
      const dx = event.clientX - state.lastX;
      const dy = event.clientY - state.lastY;
      state.lastX = event.clientX;
      state.lastY = event.clientY;
      state.rotationY += dx * 0.008;
      state.rotationX = Math.max(-1.48, Math.min(1.48, state.rotationX + dy * 0.008));
      render();
    });
    canvas.addEventListener('pointerup', event => {
      state.dragging = false;
      canvas.releasePointerCapture(event.pointerId);
    });
    canvas.addEventListener('wheel', event => {
      event.preventDefault();
      state.zoom = Math.max(2.05, Math.min(5.4, state.zoom + event.deltaY * 0.0025));
      render();
    }, { passive: false });

    root.querySelector('[data-globe-action="home"]')?.addEventListener('click', resetHome);
    root.querySelector('[data-globe-action="site"]')?.addEventListener('click', flyToSite);
    root.querySelector('[data-globe-action="zoom-in"]')?.addEventListener('click', () => {
      state.zoom = Math.max(2.05, state.zoom - 0.34);
      render();
    });
    root.querySelector('[data-globe-action="zoom-out"]')?.addEventListener('click', () => {
      state.zoom = Math.min(5.4, state.zoom + 0.34);
      render();
    });

    window.addEventListener('resize', render);
    render();
  }

  function initAll() {
    document.querySelectorAll('[data-moon-globe]').forEach(root => {
      try {
        initMoonGlobe(root);
      } catch (error) {
        root.classList.add('moon-globe-no-webgl');
        const status = root.querySelector('.moon-globe-status');
        if (status) status.textContent = 'static fallback';
        root.dataset.globeError = String(error && error.message ? error.message : error);
      }
    });
  }

  window.MoonMoonGlobe = { initAll };
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAll);
  } else {
    initAll();
  }
})();
