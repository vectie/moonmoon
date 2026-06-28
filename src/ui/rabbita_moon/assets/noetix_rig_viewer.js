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

  function drawMeshInstance(ctx, instance, span) {
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

  function drawInstance(ctx, instance, project) {
    const origin = instance.world_origin_xyz_m;
    if (!origin) return;
    if (instance.render_kind === 'cylinder') {
      const span = projectedSpan(origin, instance.radius_m * 2, instance.length_m, project);
      drawCylinderInstance(ctx, instance, span);
      return;
    }
    const span = projectedSpan(origin, instance.size_m.x, instance.size_m.z, project);
    if (instance.render_kind === 'mesh') {
      drawMeshInstance(ctx, instance, span);
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

  function draw(canvas, poseFrame, project) {
    const instances = poseFrame.visual_instances || [];
    canvas.setAttribute('data-rig-layer', 'primary-rigid-canvas');
    canvas.setAttribute('data-render-source', 'robot-rig-visual-instances');
    canvas.setAttribute('data-rendered-visuals', String(instances.length));
    canvas.setAttribute('data-render-status', 'robot-rig-canvas-ready');
    canvas.setAttribute('data-mesh-loader', 'obj');
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
    for (const instance of instances) drawInstance(ctx, instance, project);
    canvas.setAttribute('data-render-status', 'robot-rig-canvas-rendered');
  }

  window.RabbitaNoetixRig = { draw };
})();
