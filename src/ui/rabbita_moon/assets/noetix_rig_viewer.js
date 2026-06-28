(function () {
  const VIEW_WIDTH = 420;
  const VIEW_HEIGHT = 170;
  const SCALE = 2;

  function roleColor(role, kind) {
    if (kind === 'mesh') return { stroke: '#75d1c5', fill: 'rgba(117, 209, 197, 0.50)' };
    if (role === 'leg') return { stroke: '#f0c45d', fill: 'rgba(240, 196, 93, 0.46)' };
    if (role === 'arm') return { stroke: '#b7cfdb', fill: 'rgba(183, 207, 219, 0.44)' };
    return { stroke: '#8ee0d2', fill: 'rgba(142, 224, 210, 0.42)' };
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
    canvas.setAttribute('data-mesh-loader', 'obj');
    canvas.setAttribute('data-mesh-asset-count', String(meshAssets.length));
    canvas.setAttribute('data-mesh-vertex-count', String(totals.vertices));
    canvas.setAttribute('data-mesh-face-count', String(totals.faces));
    canvas.setAttribute(
      'data-mesh-draw-source',
      meshAssets.length > 0 ? 'obj-face-projection' : 'bounds-fallback'
    );
    canvas.setAttribute('data-primitive-renderer', 'box-cylinder');
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
