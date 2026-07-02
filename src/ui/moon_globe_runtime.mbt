///|
fn moon_view_panel(view : TrustedSquareViewModel) -> String {
  let source_id = html_escape(view.globe_overlay.source_dataset_id)
  let source_path = html_escape(view.globe_overlay.source_path)
  let route_id = html_escape(view.selected_route_id)
  let status = html_escape(view.globe_overlay.status)
  let summary = html_escape(view.globe_overlay.summary)
  let html =
    $|<section class="moonstage panel" aria-label="operable Moon globe"><div class="moonstage-head"><div><h2>Moon context</h2><b>\{route_id}</b><span>\{source_id}</span></div><strong class="\{status_class(status)}">\{status}</strong></div><div class="moonviewport"><canvas id="moon-globe-canvas" width="960" height="620" data-source="\{source_path}" data-route="\{route_id}" data-terrain-texture="lola-dem-elevation-hazard"></canvas><div class="moonhud"><span>source \{source_id}</span><span>LOLA DEM texture + route evidence</span><span>site \{view.site_latitude_deg}, \{view.site_longitude_deg}</span></div></div><div class="mooncontrols" aria-label="Moon view controls"><button type="button" data-moon-action="focus">focus site</button><button type="button" data-moon-action="reset">reset globe</button><button type="button" data-moon-action="orbit">orbit</button></div><p class="moonclaim">\{summary}</p></section>
  html
}

///|
fn moon_globe_script() -> String {
  let js =
    #|<script id="moonmoon-globe-runtime">
    #|(function () {
    #|  const modelNode = document.getElementById('moonmoon-view-model');
    #|  const canvas = document.getElementById('moon-globe-canvas');
    #|  if (!modelNode || !canvas) return;
    #|  const view = JSON.parse(modelNode.textContent);
    #|  const ctx = canvas.getContext('2d');
    #|  const overlay = view.globe_overlay;
    #|  const terrainCells = view.terrain_cells || [];
    #|  const terrainRows = Math.max(1, view.viewport?.rows || 1);
    #|  const terrainCols = Math.max(1, view.viewport?.cols || 1);
    #|  const state = {
    #|    centerLat: -58,
    #|    centerLon: view.site_longitude_deg,
    #|    zoom: 0.94,
    #|    dragging: false,
    #|    lastX: 0,
    #|    lastY: 0,
    #|    orbit: false
    #|  };
    #|  const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
    #|  const rad = deg => deg * Math.PI / 180;
    #|  const textureStats = terrainCells.reduce((stats, cell) => ({
    #|    minElevation: Math.min(stats.minElevation, cell.elevation_m),
    #|    maxElevation: Math.max(stats.maxElevation, cell.elevation_m),
    #|    maxSlope: Math.max(stats.maxSlope, cell.slope_grade),
    #|    maxRoughness: Math.max(stats.maxRoughness, cell.roughness_m)
    #|  }), {
    #|    minElevation: Number.POSITIVE_INFINITY,
    #|    maxElevation: Number.NEGATIVE_INFINITY,
    #|    maxSlope: 0,
    #|    maxRoughness: 0
    #|  });
    #|  function resize() {
    #|    const rect = canvas.getBoundingClientRect();
    #|    const dpr = Math.max(1, window.devicePixelRatio || 1);
    #|    const w = Math.max(320, Math.floor(rect.width * dpr));
    #|    const h = Math.max(260, Math.floor(rect.height * dpr));
    #|    if (canvas.width !== w || canvas.height !== h) {
    #|      canvas.width = w;
    #|      canvas.height = h;
    #|    }
    #|  }
    #|  function project(lat, lon, radius, cx, cy) {
    #|    const latR = rad(lat);
    #|    const lonR = rad(lon - state.centerLon);
    #|    const cLat = rad(state.centerLat);
    #|    const x = Math.cos(latR) * Math.sin(lonR);
    #|    const y = Math.cos(cLat) * Math.sin(latR) - Math.sin(cLat) * Math.cos(latR) * Math.cos(lonR);
    #|    const z = Math.sin(cLat) * Math.sin(latR) + Math.cos(cLat) * Math.cos(latR) * Math.cos(lonR);
    #|    if (z <= -0.04) return null;
    #|    return { x: cx + x * radius, y: cy - y * radius, z };
    #|  }
    #|  function terrainBounds() {
    #|    const lats = overlay.footprint.map(point => point.latitude_deg);
    #|    const lons = overlay.footprint.map(point => point.longitude_deg);
    #|    return {
    #|      south: Math.min(...lats),
    #|      north: Math.max(...lats),
    #|      west: Math.min(...lons),
    #|      east: Math.max(...lons)
    #|    };
    #|  }
    #|  function terrainCellCenter(cell, bounds) {
    #|    const latStep = (bounds.north - bounds.south) / terrainRows;
    #|    const lonStep = (bounds.east - bounds.west) / terrainCols;
    #|    return {
    #|      latitude_deg: bounds.north - (cell.row + 0.5) * latStep,
    #|      longitude_deg: bounds.west + (cell.col + 0.5) * lonStep
    #|    };
    #|  }
    #|  function terrainColor(cell) {
    #|    const range = Math.max(0.001, textureStats.maxElevation - textureStats.minElevation);
    #|    const elevationT = clamp((cell.elevation_m - textureStats.minElevation) / range, 0, 1);
    #|    const slopeT = clamp(cell.slope_grade / Math.max(0.001, textureStats.maxSlope), 0, 1);
    #|    const roughT = clamp(cell.roughness_m / Math.max(0.001, textureStats.maxRoughness), 0, 1);
    #|    const base = 92 + elevationT * 92;
    #|    const warm = cell.hazard === 'blocked' ? 28 + slopeT * 54 : 0;
    #|    const green = base - roughT * 22;
    #|    const blue = base - slopeT * 34;
    #|    return `rgba(${Math.round(base + warm)}, ${Math.round(green)}, ${Math.round(blue)}, 0.76)`;
    #|  }
    #|  function drawSourceTerrainTexture(radius, cx, cy) {
    #|    if (!terrainCells.length || !overlay.footprint.length) return;
    #|    const bounds = terrainBounds();
    #|    const projectedCells = [];
    #|    for (const cell of terrainCells) {
    #|      const center = terrainCellCenter(cell, bounds);
    #|      const p = project(center.latitude_deg, center.longitude_deg, radius, cx, cy);
    #|      if (!p) continue;
    #|      projectedCells.push({ cell, p });
    #|    }
    #|    projectedCells.sort((a, b) => a.p.z - b.p.z);
    #|    for (const entry of projectedCells) {
    #|      const size = Math.max(2.5, radius * (entry.cell.selected ? 0.026 : 0.017) * clamp(state.zoom, 0.8, 2.4));
    #|      ctx.beginPath();
    #|      ctx.arc(entry.p.x, entry.p.y, size, 0, Math.PI * 2);
    #|      ctx.fillStyle = terrainColor(entry.cell);
    #|      ctx.fill();
    #|      ctx.strokeStyle = entry.cell.selected ? '#2dba89' : 'rgba(255,255,255,.22)';
    #|      ctx.lineWidth = entry.cell.selected ? Math.max(1.5, radius * 0.006) : Math.max(0.8, radius * 0.0025);
    #|      ctx.stroke();
    #|    }
    #|  }
    #|  function drawMoon(radius, cx, cy) {
    #|    ctx.clearRect(0, 0, canvas.width, canvas.height);
    #|    const sky = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
    #|    sky.addColorStop(0, '#05070a');
    #|    sky.addColorStop(0.62, '#111821');
    #|    sky.addColorStop(1, '#201b16');
    #|    ctx.fillStyle = sky;
    #|    ctx.fillRect(0, 0, canvas.width, canvas.height);
    #|    ctx.save();
    #|    ctx.beginPath();
    #|    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    #|    ctx.clip();
    #|    const body = ctx.createRadialGradient(cx - radius * 0.3, cy - radius * 0.35, radius * 0.05, cx, cy, radius);
    #|    body.addColorStop(0, '#f1ede0');
    #|    body.addColorStop(0.35, '#b8b7ad');
    #|    body.addColorStop(0.72, '#6d716d');
    #|    body.addColorStop(1, '#24282b');
    #|    ctx.fillStyle = body;
    #|    ctx.fillRect(cx - radius, cy - radius, radius * 2, radius * 2);
    #|    ctx.globalAlpha = 0.22;
    #|    ctx.strokeStyle = '#2f3637';
    #|    ctx.lineWidth = Math.max(1, radius * 0.006);
    #|    for (let lat = -75; lat <= 75; lat += 15) {
    #|      ctx.beginPath();
    #|      let started = false;
    #|      for (let lon = -180; lon <= 180; lon += 4) {
    #|        const p = project(lat, lon, radius, cx, cy);
    #|        if (!p) { started = false; continue; }
    #|        if (!started) { ctx.moveTo(p.x, p.y); started = true; } else ctx.lineTo(p.x, p.y);
    #|      }
    #|      ctx.stroke();
    #|    }
    #|    for (let lon = -180; lon < 180; lon += 30) {
    #|      ctx.beginPath();
    #|      let started = false;
    #|      for (let lat = -86; lat <= 86; lat += 3) {
    #|        const p = project(lat, lon, radius, cx, cy);
    #|        if (!p) { started = false; continue; }
    #|        if (!started) { ctx.moveTo(p.x, p.y); started = true; } else ctx.lineTo(p.x, p.y);
    #|      }
    #|      ctx.stroke();
    #|    }
    #|    ctx.globalAlpha = 1;
    #|    const craters = [
    #|      [-43, -11, 0.08], [-58, 0, 0.045], [-67, 32, 0.055], [-25, 42, 0.035],
    #|      [-76, -48, 0.035], [-35, -72, 0.04], [12, 18, 0.05], [28, -24, 0.03]
    #|    ];
    #|    for (const crater of craters) {
    #|      const p = project(crater[0], crater[1], radius, cx, cy);
    #|      if (!p) continue;
    #|      const r = radius * crater[2] * (0.45 + p.z * 0.55);
    #|      ctx.beginPath();
    #|      ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
    #|      ctx.fillStyle = 'rgba(54,58,56,.28)';
    #|      ctx.fill();
    #|      ctx.strokeStyle = 'rgba(238,232,210,.28)';
    #|      ctx.lineWidth = Math.max(1, radius * 0.004);
    #|      ctx.stroke();
    #|    }
    #|    ctx.restore();
    #|    ctx.strokeStyle = 'rgba(255,255,255,.22)';
    #|    ctx.lineWidth = Math.max(1, radius * 0.008);
    #|    ctx.beginPath();
    #|    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    #|    ctx.stroke();
    #|  }
    #|  function drawPath(points, radius, cx, cy, color, width) {
    #|    ctx.beginPath();
    #|    let started = false;
    #|    for (const point of points) {
    #|      const p = project(point.latitude_deg, point.longitude_deg, radius, cx, cy);
    #|      if (!p) { started = false; continue; }
    #|      if (!started) { ctx.moveTo(p.x, p.y); started = true; } else ctx.lineTo(p.x, p.y);
    #|    }
    #|    ctx.strokeStyle = color;
    #|    ctx.lineWidth = width;
    #|    ctx.stroke();
    #|  }
    #|  function drawOverlay(radius, cx, cy) {
    #|    drawPath([...overlay.footprint, overlay.footprint[0]], radius, cx, cy, 'rgba(45, 186, 137, .95)', Math.max(2, radius * 0.011));
    #|    drawPath(overlay.selected_route_trace.points, radius, cx, cy, 'rgba(244, 184, 70, .95)', Math.max(2, radius * 0.012));
    #|    for (const win of overlay.corridor_windows) {
    #|      const p = project(win.latitude_deg, win.longitude_deg, radius, cx, cy);
    #|      if (!p) continue;
    #|      const size = win.selected ? radius * 0.022 : radius * 0.008;
    #|      ctx.beginPath();
    #|      ctx.arc(p.x, p.y, size, 0, Math.PI * 2);
    #|      ctx.fillStyle = win.selected ? '#f4b846' : 'rgba(202, 93, 75, .72)';
    #|      ctx.fill();
    #|    }
    #|    const site = project(view.site_latitude_deg, view.site_longitude_deg, radius, cx, cy);
    #|    if (site) {
    #|      ctx.beginPath();
    #|      ctx.arc(site.x, site.y, radius * 0.03, 0, Math.PI * 2);
    #|      ctx.strokeStyle = '#2dba89';
    #|      ctx.lineWidth = Math.max(2, radius * 0.012);
    #|      ctx.stroke();
    #|    }
    #|  }
    #|  function render() {
    #|    resize();
    #|    const radius = Math.min(canvas.width, canvas.height) * 0.39 * state.zoom;
    #|    const cx = canvas.width * 0.5;
    #|    const cy = canvas.height * 0.52;
    #|    drawMoon(radius, cx, cy);
    #|    drawSourceTerrainTexture(radius, cx, cy);
    #|    drawOverlay(radius, cx, cy);
    #|  }
    #|  function focusSite() {
    #|    state.centerLat = clamp(view.site_latitude_deg + 1.1, -89, 89);
    #|    state.centerLon = view.site_longitude_deg;
    #|    state.zoom = 2.65;
    #|    render();
    #|  }
    #|  function reset() {
    #|    state.centerLat = -58;
    #|    state.centerLon = view.site_longitude_deg;
    #|    state.zoom = 0.94;
    #|    render();
    #|  }
    #|  canvas.addEventListener('pointerdown', event => {
    #|    state.dragging = true;
    #|    state.lastX = event.clientX;
    #|    state.lastY = event.clientY;
    #|    canvas.setPointerCapture(event.pointerId);
    #|  });
    #|  canvas.addEventListener('pointermove', event => {
    #|    if (!state.dragging) return;
    #|    const dx = event.clientX - state.lastX;
    #|    const dy = event.clientY - state.lastY;
    #|    state.lastX = event.clientX;
    #|    state.lastY = event.clientY;
    #|    state.centerLon = ((state.centerLon - dx * 0.18 / state.zoom + 540) % 360) - 180;
    #|    state.centerLat = clamp(state.centerLat + dy * 0.18 / state.zoom, -89, 89);
    #|    render();
    #|  });
    #|  canvas.addEventListener('pointerup', event => {
    #|    state.dragging = false;
    #|    canvas.releasePointerCapture(event.pointerId);
    #|  });
    #|  canvas.addEventListener('wheel', event => {
    #|    event.preventDefault();
    #|    state.zoom = clamp(state.zoom * (event.deltaY > 0 ? 0.9 : 1.1), 0.72, 3.2);
    #|    render();
    #|  }, { passive: false });
    #|  document.querySelectorAll('[data-moon-action]').forEach(button => {
    #|    button.addEventListener('click', () => {
    #|      const action = button.getAttribute('data-moon-action');
    #|      if (action === 'focus') focusSite();
    #|      if (action === 'reset') reset();
    #|      if (action === 'orbit') {
    #|        state.orbit = !state.orbit;
    #|        button.classList.toggle('active', state.orbit);
    #|      }
    #|    });
    #|  });
    #|  function tick() {
    #|    if (state.orbit && !state.dragging) {
    #|      state.centerLon = ((state.centerLon + 0.08 + 540) % 360) - 180;
    #|      render();
    #|    }
    #|    requestAnimationFrame(tick);
    #|  }
    #|  window.addEventListener('resize', render);
    #|  render();
    #|  requestAnimationFrame(tick);
    #|})();
    #|</script>
  js
}
