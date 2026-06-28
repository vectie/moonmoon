(function () {
  const VIEW_WIDTH = 420;
  const VIEW_HEIGHT = 170;
  const SCALE = 2;
  const WEBGL_SCALE = 2;

  function roleColor(role, kind) {
    if (kind === 'mesh') return { stroke: '#75d1c5', fill: 'rgba(117, 209, 197, 0.50)' };
    if (role === 'leg') return { stroke: '#f0c45d', fill: 'rgba(240, 196, 93, 0.46)' };
    if (role === 'arm') return { stroke: '#b7cfdb', fill: 'rgba(183, 207, 219, 0.44)' };
    return { stroke: '#8ee0d2', fill: 'rgba(142, 224, 210, 0.42)' };
  }

  function roleRgba(role, kind) {
    if (kind === 'mesh') return [0.46, 0.82, 0.77, 0.82];
    if (role === 'leg') return [0.94, 0.77, 0.36, 0.76];
    if (role === 'arm') return [0.72, 0.81, 0.86, 0.72];
    return [0.56, 0.88, 0.82, 0.76];
  }

  function projectedSpan(origin, xMeters, zMeters, project) {
    const center = project(origin);
    const xEdge = project({ x: origin.x + xMeters, y: origin.y, z: origin.z });
    const zEdge = project({ x: origin.x, y: origin.y, z: origin.z + zMeters });
    return {
      center,
      width: Math.max(4, Math.abs(xEdge.x - center.x)),
      height: Math.max(4, Math.abs(zEdge.y - center.y)),
    };
  }

  function meshAssetIndex(meshAssets) {
    const index = Object.create(null);
    for (const asset of meshAssets || []) {
      if (asset && asset.mesh_asset_id) index[asset.mesh_asset_id] = asset;
    }
    return index;
  }

  function meshTotals(meshAssets) {
    let vertices = 0;
    let faces = 0;
    for (const asset of meshAssets || []) {
      vertices += Number(asset.vertex_count || (asset.vertices || []).length || 0);
      faces += Number(asset.face_count || (asset.faces || []).length || 0);
    }
    return { vertices, faces };
  }

  function transformPoint(transform, point) {
    const basis = transform && transform.basis ? transform.basis : {};
    const translation = transform && transform.translation ? transform.translation : {};
    return {
      x:
        (basis.xx ?? 1) * point.x +
        (basis.xy ?? 0) * point.y +
        (basis.xz ?? 0) * point.z +
        (translation.x ?? 0),
      y:
        (basis.yx ?? 0) * point.x +
        (basis.yy ?? 1) * point.y +
        (basis.yz ?? 0) * point.z +
        (translation.y ?? 0),
      z:
        (basis.zx ?? 0) * point.x +
        (basis.zy ?? 0) * point.y +
        (basis.zz ?? 1) * point.z +
        (translation.z ?? 0),
    };
  }

  function meshVertexWorld(instance, vertex) {
    const origin = instance.local_origin_xyz_m || { x: 0, y: 0, z: 0 };
    return transformPoint(instance.world_transform, {
      x: (vertex.x ?? 0) + (origin.x ?? 0),
      y: (vertex.y ?? 0) + (origin.y ?? 0),
      z: (vertex.z ?? 0) + (origin.z ?? 0),
    });
  }

  function createShader(gl, type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      throw new Error(gl.getShaderInfoLog(shader) || 'Noetix rig shader compile failed');
    }
    return shader;
  }

  function createProgram(gl) {
    const vertex = createShader(gl, gl.VERTEX_SHADER, `
      attribute vec3 a_position;
      attribute vec4 a_color;
      varying vec4 v_color;
      void main() {
        gl_Position = vec4(a_position, 1.0);
        v_color = a_color;
      }
    `);
    const fragment = createShader(gl, gl.FRAGMENT_SHADER, `
      precision mediump float;
      varying vec4 v_color;
      void main() {
        gl_FragColor = v_color;
      }
    `);
    const program = gl.createProgram();
    gl.attachShader(program, vertex);
    gl.attachShader(program, fragment);
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Error(gl.getProgramInfoLog(program) || 'Noetix rig WebGL link failed');
    }
    return program;
  }

  function clipPoint(point, depth) {
    return {
      x: (point.x / VIEW_WIDTH) * 2 - 1,
      y: 1 - (point.y / VIEW_HEIGHT) * 2,
      z: Math.max(-0.95, Math.min(0.95, depth || 0)),
    };
  }

  function addVertex(vertices, colors, point, color, depth) {
    const clip = clipPoint(point, depth);
    vertices.push(clip.x, clip.y, clip.z);
    colors.push(color[0], color[1], color[2], color[3]);
  }

  function addTriangle(vertices, colors, a, b, c, color, depth) {
    addVertex(vertices, colors, a, color, depth);
    addVertex(vertices, colors, b, color, depth);
    addVertex(vertices, colors, c, color, depth);
  }

  function addRectTriangles(vertices, colors, x, y, width, height, color, depth) {
    const a = { x, y };
    const b = { x: x + width, y };
    const c = { x: x + width, y: y + height };
    const d = { x, y: y + height };
    addTriangle(vertices, colors, a, b, c, color, depth);
    addTriangle(vertices, colors, a, c, d, color, depth);
  }

  function addMeshTriangles(vertices, colors, instance, asset, project) {
    const meshVertices = asset && asset.vertices ? asset.vertices : [];
    const faces = asset && asset.faces ? asset.faces : [];
    if (meshVertices.length === 0 || faces.length === 0) return 0;
    const color = roleRgba(instance.role, instance.render_kind);
    let triangleCount = 0;
    for (const face of faces) {
      const points = [];
      let depth = 0;
      for (const index of face.vertex_indices || []) {
        const vertex = meshVertices[index];
        if (!vertex) continue;
        const world = meshVertexWorld(instance, vertex);
        depth += world.y || 0;
        points.push(project(world));
      }
      if (points.length >= 3) {
        const normalizedDepth = -0.2 + (depth / points.length) * 0.08;
        for (let index = 1; index < points.length - 1; index += 1) {
          addTriangle(vertices, colors, points[0], points[index], points[index + 1], color, normalizedDepth);
          triangleCount += 1;
        }
      }
    }
    return triangleCount;
  }

  function addBoxTriangles(vertices, colors, instance, project) {
    const origin = instance.world_origin_xyz_m;
    const span = projectedSpan(origin, instance.size_m.x, instance.size_m.z, project);
    const color = roleRgba(instance.role, instance.render_kind);
    addRectTriangles(
      vertices,
      colors,
      span.center.x - span.width * 0.5,
      span.center.y - span.height * 0.5,
      span.width,
      span.height,
      color,
      0.0
    );
    return 2;
  }

  function addCylinderTriangles(vertices, colors, instance, project) {
    const origin = instance.world_origin_xyz_m;
    const span = projectedSpan(origin, instance.radius_m * 2, instance.length_m, project);
    const color = roleRgba(instance.role, instance.render_kind);
    const steps = 18;
    let triangleCount = 0;
    for (let index = 0; index < steps; index += 1) {
      const a = (index / steps) * Math.PI * 2;
      const b = ((index + 1) / steps) * Math.PI * 2;
      addTriangle(
        vertices,
        colors,
        span.center,
        {
          x: span.center.x + Math.cos(a) * span.width * 0.5,
          y: span.center.y + Math.sin(a) * span.height * 0.5,
        },
        {
          x: span.center.x + Math.cos(b) * span.width * 0.5,
          y: span.center.y + Math.sin(b) * span.height * 0.5,
        },
        color,
        0.05
      );
      triangleCount += 1;
    }
    return triangleCount;
  }

  function webglBuffers(poseFrame, meshAssetsById, project) {
    const vertices = [];
    const colors = [];
    let meshTriangles = 0;
    let primitiveTriangles = 0;
    for (const instance of poseFrame.visual_instances || []) {
      if (!instance.world_origin_xyz_m) continue;
      if (instance.render_kind === 'mesh') {
        const asset = meshAssetsById[instance.mesh_asset_id] || null;
        meshTriangles += addMeshTriangles(vertices, colors, instance, asset, project);
      } else if (instance.render_kind === 'cylinder') {
        primitiveTriangles += addCylinderTriangles(vertices, colors, instance, project);
      } else {
        primitiveTriangles += addBoxTriangles(vertices, colors, instance, project);
      }
    }
    return { vertices, colors, meshTriangles, primitiveTriangles };
  }

  function drawWebgl(canvas, poseFrame, meshAssetsById, project) {
    if (typeof canvas.getContext !== 'function') return false;
    const gl = canvas.getContext('webgl', { antialias: true, alpha: false });
    if (!gl) return false;
    const buffers = webglBuffers(poseFrame, meshAssetsById, project);
    if (buffers.vertices.length === 0) return false;
    canvas.width = VIEW_WIDTH * WEBGL_SCALE;
    canvas.height = VIEW_HEIGHT * WEBGL_SCALE;
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.067, 0.094, 0.098, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    const program = createProgram(gl);
    gl.useProgram(program);
    const positionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(buffers.vertices), gl.STATIC_DRAW);
    const positionLocation = gl.getAttribLocation(program, 'a_position');
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 3, gl.FLOAT, false, 0, 0);
    const colorBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(buffers.colors), gl.STATIC_DRAW);
    const colorLocation = gl.getAttribLocation(program, 'a_color');
    gl.enableVertexAttribArray(colorLocation);
    gl.vertexAttribPointer(colorLocation, 4, gl.FLOAT, false, 0, 0);
    gl.drawArrays(gl.TRIANGLES, 0, buffers.vertices.length / 3);
    canvas.setAttribute('data-webgl-status', 'webgl-rigid-rendered');
    canvas.setAttribute('data-webgl-triangles', String(buffers.vertices.length / 9));
    canvas.setAttribute('data-webgl-mesh-triangles', String(buffers.meshTriangles));
    canvas.setAttribute('data-webgl-primitive-triangles', String(buffers.primitiveTriangles));
    return true;
  }

  function drawRoundedRect(ctx, x, y, width, height, radius) {
    const r = Math.min(radius, width * 0.5, height * 0.5);
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + width - r, y);
    ctx.quadraticCurveTo(x + width, y, x + width, y + r);
    ctx.lineTo(x + width, y + height - r);
    ctx.quadraticCurveTo(x + width, y + height, x + width - r, y + height);
    ctx.lineTo(x + r, y + height);
    ctx.quadraticCurveTo(x, y + height, x, y + height - r);
    ctx.lineTo(x, y + r);
    ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.closePath();
  }

  function drawMeshBoundsInstance(ctx, instance, span) {
    const palette = roleColor(instance.role, instance.render_kind);
    const x = span.center.x - span.width * 0.5;
    const y = span.center.y - span.height * 0.5;
    ctx.save();
    ctx.fillStyle = palette.fill;
    ctx.strokeStyle = palette.stroke;
    ctx.lineWidth = 1.6;
    ctx.setLineDash([5, 2]);
    drawRoundedRect(ctx, x, y, span.width, span.height, 3);
    ctx.fill();
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.beginPath();
    ctx.moveTo(x + span.width * 0.18, y + span.height * 0.72);
    ctx.lineTo(x + span.width * 0.50, y + span.height * 0.18);
    ctx.lineTo(x + span.width * 0.82, y + span.height * 0.72);
    ctx.stroke();
    ctx.restore();
  }

  function drawMeshAssetInstance(ctx, instance, asset, project) {
    const vertices = asset && asset.vertices ? asset.vertices : [];
    const faces = asset && asset.faces ? asset.faces : [];
    if (vertices.length === 0 || faces.length === 0) return false;
    const palette = roleColor(instance.role, instance.render_kind);
    const projectedFaces = [];
    for (const face of faces) {
      const projected = [];
      let depth = 0;
      for (const index of face.vertex_indices || []) {
        const vertex = vertices[index];
        if (!vertex) continue;
        const world = meshVertexWorld(instance, vertex);
        depth += world.y || 0;
        projected.push(project(world));
      }
      if (projected.length >= 3) {
        projectedFaces.push({ projected, depth: depth / projected.length });
      }
    }
    projectedFaces.sort((a, b) => a.depth - b.depth);
    ctx.save();
    ctx.fillStyle = palette.fill;
    ctx.strokeStyle = palette.stroke;
    ctx.lineWidth = 1.4;
    for (const face of projectedFaces) {
      ctx.beginPath();
      ctx.moveTo(face.projected[0].x, face.projected[0].y);
      for (let index = 1; index < face.projected.length; index += 1) {
        ctx.lineTo(face.projected[index].x, face.projected[index].y);
      }
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
    }
    ctx.restore();
    return projectedFaces.length > 0;
  }

  function drawBoxInstance(ctx, instance, span) {
    const palette = roleColor(instance.role, instance.render_kind);
    const x = span.center.x - span.width * 0.5;
    const y = span.center.y - span.height * 0.5;
    ctx.save();
    ctx.fillStyle = palette.fill;
    ctx.strokeStyle = palette.stroke;
    ctx.lineWidth = 1.25;
    drawRoundedRect(ctx, x, y, span.width, span.height, 2);
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  }

  function drawCylinderInstance(ctx, instance, span) {
    const palette = roleColor(instance.role, instance.render_kind);
    ctx.save();
    ctx.fillStyle = palette.fill;
    ctx.strokeStyle = palette.stroke;
    ctx.lineWidth = 1.25;
    ctx.beginPath();
    ctx.ellipse(
      span.center.x,
      span.center.y,
      span.width * 0.5,
      span.height * 0.5,
      0,
      0,
      Math.PI * 2
    );
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  }

  function drawInstance(ctx, instance, meshAssets, project) {
    const origin = instance.world_origin_xyz_m;
    if (!origin) return;
    if (instance.render_kind === 'cylinder') {
      const span = projectedSpan(origin, instance.radius_m * 2, instance.length_m, project);
      drawCylinderInstance(ctx, instance, span);
      return;
    }
    const span = projectedSpan(origin, instance.size_m.x, instance.size_m.z, project);
    if (instance.render_kind === 'mesh') {
      const meshAsset = meshAssets[instance.mesh_asset_id] || null;
      if (!drawMeshAssetInstance(ctx, instance, meshAsset, project)) {
        drawMeshBoundsInstance(ctx, instance, span);
      }
    } else {
      drawBoxInstance(ctx, instance, span);
    }
  }

  function drawGround(ctx) {
    ctx.save();
    ctx.strokeStyle = 'rgba(245, 247, 244, 0.32)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(28, 138);
    ctx.lineTo(392, 138);
    ctx.stroke();
    ctx.restore();
  }

  function draw(canvas, poseFrame, meshAssetsOrProject, maybeProject) {
    const meshAssets = Array.isArray(meshAssetsOrProject) ? meshAssetsOrProject : [];
    const project = typeof meshAssetsOrProject === 'function' ? meshAssetsOrProject : maybeProject;
    const instances = poseFrame.visual_instances || [];
    const totals = meshTotals(meshAssets);
    const meshAssetsById = meshAssetIndex(meshAssets);
    canvas.setAttribute('data-rig-layer', 'primary-rigid-canvas');
    canvas.setAttribute('data-render-source', 'robot-rig-visual-instances');
    canvas.setAttribute('data-rendered-visuals', String(instances.length));
    canvas.setAttribute('data-render-status', 'robot-rig-canvas-ready');
    canvas.setAttribute('data-rig-renderer-intent', 'webgl-rigid-link-renderer');
    canvas.setAttribute('data-webgl-status', 'webgl-not-attempted');
    canvas.setAttribute('data-mesh-loader', 'obj');
    canvas.setAttribute('data-mesh-asset-count', String(meshAssets.length));
    canvas.setAttribute('data-mesh-vertex-count', String(totals.vertices));
    canvas.setAttribute('data-mesh-face-count', String(totals.faces));
    canvas.setAttribute(
      'data-mesh-draw-source',
      meshAssets.length > 0 ? 'obj-face-projection' : 'bounds-fallback'
    );
    canvas.setAttribute('data-primitive-renderer', 'box-cylinder');
    try {
      if (drawWebgl(canvas, poseFrame, meshAssetsById, project)) {
        canvas.setAttribute('data-render-status', 'robot-rig-canvas-rendered');
        return;
      }
      canvas.setAttribute('data-webgl-status', 'webgl-context-unavailable');
    } catch (error) {
      canvas.setAttribute('data-webgl-status', 'webgl-render-failed');
      canvas.setAttribute('data-webgl-error', String(error && error.message ? error.message : error).slice(0, 96));
    }
    if (typeof canvas.getContext !== 'function') return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    canvas.width = VIEW_WIDTH * SCALE;
    canvas.height = VIEW_HEIGHT * SCALE;
    ctx.setTransform(SCALE, 0, 0, SCALE, 0, 0);
    ctx.clearRect(0, 0, VIEW_WIDTH, VIEW_HEIGHT);
    ctx.fillStyle = '#111819';
    ctx.fillRect(0, 0, VIEW_WIDTH, VIEW_HEIGHT);
    drawGround(ctx);
    for (const instance of instances) drawInstance(ctx, instance, meshAssetsById, project);
    canvas.setAttribute('data-render-status', 'robot-rig-canvas-rendered');
  }

  window.RabbitaNoetixRig = { draw };
})();
