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
    const overlaySvg = root.querySelector('.moon-globe-overlay');
    const status = root.querySelector('.moon-globe-status');
    const authority = root.querySelector('[data-globe-authority]');
    const view = JSON.parse(document.getElementById('moonmoon-view-model').textContent);
    const overlay = view.globe_overlay || null;
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
    const overlayState = {
      footprint: true,
      route: true,
      corridor: true
    };
    if (authority && overlay) {
      authority.textContent = `${overlay.hardware_authority}: ${overlay.blocker_count} blockers`;
    }

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

    function svgEl(tag, attrs = {}) {
      const node = document.createElementNS('http://www.w3.org/2000/svg', tag);
      for (const [key, value] of Object.entries(attrs)) {
        node.setAttribute(key, value);
      }
      return node;
    }

    function projectedPoint(point, model, mvp) {
      const spherePoint = coordinatePoint(point.latitude_deg, point.longitude_deg);
      const modelPoint = transform(model, spherePoint, 1);
      const clip = transform(mvp, spherePoint, 1);
      if (clip[3] <= 0 || modelPoint[2] < -0.05) {
        return null;
      }
      const ndcX = clip[0] / clip[3];
      const ndcY = clip[1] / clip[3];
      if (Math.abs(ndcX) > 1.05 || Math.abs(ndcY) > 1.05) {
        return null;
      }
      return {
        x: (ndcX * 0.5 + 0.5) * root.clientWidth,
        y: (-ndcY * 0.5 + 0.5) * root.clientHeight
      };
    }

    function updateMarker(model, mvp) {
      if (!marker) return;
      const projected = projectedPoint({
        latitude_deg: site.lat,
        longitude_deg: site.lon
      }, model, mvp);
      if (!projected) {
        marker.hidden = true;
        return;
      }
      marker.hidden = false;
      marker.style.left = `${projected.x}px`;
      marker.style.top = `${projected.y}px`;
    }

    function projectedPoints(points, model, mvp) {
      return points.map(point => projectedPoint(point, model, mvp));
    }

    function bounds(points) {
      let minX = points[0].x;
      let maxX = points[0].x;
      let minY = points[0].y;
      let maxY = points[0].y;
      for (const point of points) {
        minX = Math.min(minX, point.x);
        maxX = Math.max(maxX, point.x);
        minY = Math.min(minY, point.y);
        maxY = Math.max(maxY, point.y);
      }
      return { minX, maxX, minY, maxY };
    }

    function centroid(points) {
      const total = points.reduce((sum, point) => {
        sum.x += point.x;
        sum.y += point.y;
        return sum;
      }, { x: 0, y: 0 });
      return {
        x: total.x / points.length,
        y: total.y / points.length
      };
    }

    function visibleFootprint(points) {
      const box = bounds(points);
      if (Math.max(box.maxX - box.minX, box.maxY - box.minY) >= 24) {
        return points;
      }
      const center = centroid(points);
      const size = 36;
      return [
        { x: center.x - size / 2, y: center.y + size / 2 },
        { x: center.x - size / 2, y: center.y - size / 2 },
        { x: center.x + size / 2, y: center.y - size / 2 },
        { x: center.x + size / 2, y: center.y + size / 2 }
      ];
    }

    function visibleRoute(points) {
      const box = bounds(points);
      if (Math.max(box.maxX - box.minX, box.maxY - box.minY) >= 34) {
        return points;
      }
      const start = points[0];
      const end = points[points.length - 1];
      let dx = end.x - start.x;
      let dy = end.y - start.y;
      const length = Math.hypot(dx, dy);
      if (length < 1) {
        dx = 30;
        dy = -18;
      } else {
        dx = dx / length * 44;
        dy = dy / length * 44;
      }
      return [
        start,
        { x: start.x + dx * 0.54, y: start.y + dy * 0.42 },
        { x: start.x + dx, y: start.y + dy }
      ];
    }

    function visibleCorridor(windows, points) {
      const visible = points.map((point, index) => ({ point, window: windows[index] }));
      if (visible.length === 0) return [];
      const valid = visible.filter(item => item.point);
      if (valid.length === 0) return [];
      const box = bounds(valid.map(item => item.point));
      if (Math.max(box.maxX - box.minX, box.maxY - box.minY) >= 54) {
        return valid.map(item => ({ ...item, point: item.point }));
      }
      const center = centroid(valid.map(item => item.point));
      const rows = windows.map(window => window.row_offset);
      const cols = windows.map(window => window.col_offset);
      const minRow = Math.min(...rows);
      const maxRow = Math.max(...rows);
      const minCol = Math.min(...cols);
      const maxCol = Math.max(...cols);
      const size = 68;
      return windows.map(window => {
        const x = center.x + ((window.col_offset - minCol) / Math.max(1, maxCol - minCol) - 0.5) * size;
        const y = center.y + ((window.row_offset - minRow) / Math.max(1, maxRow - minRow) - 0.5) * size;
        return { window, point: { x, y } };
      });
    }

    function renderOverlay(model, mvp) {
      if (!overlaySvg || !overlay) return;
      const width = Math.max(1, root.clientWidth);
      const height = Math.max(1, root.clientHeight);
      overlaySvg.setAttribute('viewBox', `0 0 ${width} ${height}`);
      const children = [];
      if (overlayState.footprint && overlay.footprint && overlay.footprint.length >= 3) {
        const footprint = projectedPoints(overlay.footprint, model, mvp);
        if (footprint.every(Boolean)) {
          const drawnFootprint = visibleFootprint(footprint);
          const d = drawnFootprint
            .map((point, index) => `${index === 0 ? 'M' : 'L'}${point.x.toFixed(2)} ${point.y.toFixed(2)}`)
            .join(' ');
          children.push(svgEl('path', {
            class: 'moon-globe-footprint',
            d: `${d} Z`,
            'data-overlay-id': overlay.overlay_id
          }));
        }
      }
      const windows = overlay.corridor_windows || [];
      if (overlayState.corridor && windows.length > 0) {
        const corridor = visibleCorridor(
          windows,
          windows.map(window => projectedPoint(window, model, mvp))
        );
        for (const item of corridor) {
          children.push(svgEl('circle', {
            class: item.window.selected
              ? 'moon-globe-corridor moon-globe-corridor-selected'
              : 'moon-globe-corridor',
            cx: item.point.x.toFixed(2),
            cy: item.point.y.toFixed(2),
            r: item.window.selected ? '4.6' : '2.3',
            'data-window-id': item.window.window_id,
            'data-rank': String(item.window.rank)
          }));
        }
      }
      const route = overlay.selected_route_trace;
      if (overlayState.route && route && route.points && route.points.length >= 2) {
        const trace = projectedPoints(route.points, model, mvp);
        if (trace.every(Boolean)) {
          const drawnTrace = visibleRoute(trace);
          const d = drawnTrace
            .map((point, index) => `${index === 0 ? 'M' : 'L'}${point.x.toFixed(2)} ${point.y.toFixed(2)}`)
            .join(' ');
          children.push(svgEl('path', {
            class: 'moon-globe-route',
            d,
            'data-route-id': route.path_id
          }));
          const end = drawnTrace[drawnTrace.length - 1];
          children.push(svgEl('circle', {
            class: 'moon-globe-route-end',
            cx: end.x.toFixed(2),
            cy: end.y.toFixed(2),
            r: '4',
            'data-route-id': route.path_id
          }));
        }
      }
      overlaySvg.replaceChildren(...children);
      root.dataset.overlayReady = children.length > 0 ? 'true' : 'hidden';
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
      renderOverlay(model, mvp);
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
    root.querySelectorAll('[data-globe-layer]').forEach(button => {
      const layer = button.getAttribute('data-globe-layer');
      button.addEventListener('click', () => {
        overlayState[layer] = !overlayState[layer];
        button.setAttribute('aria-pressed', String(overlayState[layer]));
        render();
      });
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
