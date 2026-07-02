///|
fn status_class(value : String) -> String {
  if value.contains("block") || value.contains("gated") {
    "is-blocked"
  } else if value.contains("review") || value.contains("caution") {
    "is-review"
  } else {
    "is-ready"
  }
}

///|
fn layer_nav(view : TrustedSquareViewModel) -> String {
  let mut html = ""
  for layer in view.layers {
    let active = if layer.layer_id == view.active_layer_id {
      " active"
    } else {
      ""
    }
    let row =
      $|<button class="seg\{active}" type="button">\{html_escape(layer.label)}</button>
    html += row
  }
  html
}

///|
fn terrain_grid(view : TrustedSquareViewModel) -> String {
  let mut html = ""
  for cell in view.terrain_cells {
    let selected = if cell.selected { " selected" } else { "" }
    let row =
      $|<button class="tile \{status_class(cell.hazard)}\{selected}" type="button" aria-label="row \{cell.row} column \{cell.col}"><span>r\{cell.row} c\{cell.col}</span><b>\{cell.elevation_m} m</b></button>
    html += row
  }
  html
}

///|
fn route_list(view : TrustedSquareViewModel) -> String {
  let mut html = ""
  for route in view.routes {
    let selected = if route.selected { " selected" } else { "" }
    let row =
      $|<article class="row \{status_class(route.decision)}\{selected}"><div><b>\{html_escape(route.label)}</b><span>\{html_escape(route.route_id)}</span></div><strong>\{html_escape(route.decision)}</strong></article>
    html += row
  }
  html
}

///|
fn fact_list(view : TrustedSquareViewModel) -> String {
  let mut html = ""
  for fact in view.inspector_facts {
    let row =
      $|<article class="row \{status_class(fact.status)}"><div><b>\{html_escape(fact.label)}</b><span>\{html_escape(fact.evidence_path)}</span></div><strong>\{html_escape(fact.value)}</strong></article>
    html += row
  }
  html
}

///|
fn blocker_list(view : TrustedSquareViewModel) -> String {
  if view.blockers.is_empty() {
    "<li>none</li>"
  } else {
    let mut html = ""
    for blocker in view.blockers {
      let row =
        $|<li>\{html_escape(blocker)}</li>
      html += row
    }
    html
  }
}

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
fn motion_contract_panel(contract : TraverseMotionContract) -> String {
  let html =
    $|<section class="card panel motion-contract"><h2>motion contract</h2><article class="row \{status_class(contract.status)}"><div><b>\{html_escape(contract.preview_kind)}</b><span>\{html_escape(contract.contract_id)}</span></div><strong>\{html_escape(contract.status)}</strong></article><article class="row"><div><b>physics core</b><span>\{html_escape(contract.physics_core_package)}</span></div><strong>generic</strong></article><article class="row"><div><b>motion owner</b><span>\{html_escape(contract.motion_owner_package)}</span></div><strong>\{html_escape(contract.gait_asset_status)}</strong></article><article class="row \{status_class(contract.simulation_status)}"><div><b>simulation</b><span>\{html_escape(contract.next_action)}</span></div><strong>\{html_escape(contract.simulation_status)}</strong></article></section>
  html
}

///|
fn app_styles() -> String {
  let css =
    #|<style>
    #|:root { font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #f7f7f4; color: #151917; }
    #|* { box-sizing: border-box; }
    #|body { margin: 0; min-height: 100vh; background: #f7f7f4; }
    #|button { font: inherit; }
    #|.shell { min-height: 100vh; display: grid; grid-template-columns: minmax(0, 1fr) 360px; }
    #|.workspace { padding: 24px; display: grid; gap: 18px; align-content: start; }
    #|.inspector { border-left: 1px solid #d8d8d0; background: #fbfbf8; padding: 20px; display: grid; gap: 16px; align-content: start; }
    #|.topbar { display: flex; justify-content: space-between; gap: 16px; align-items: start; }
    #|h1, h2, p { margin: 0; }
    #|h1 { font-size: 28px; line-height: 1.1; }
    #|h2 { font-size: 13px; text-transform: uppercase; letter-spacing: 0; color: #535b55; margin-bottom: 10px; }
    #|.summary { color: #555d57; max-width: 760px; margin-top: 8px; line-height: 1.45; }
    #|.badge { border: 1px solid #b9b9ae; background: #fff; padding: 7px 10px; font-size: 13px; white-space: nowrap; }
    #|.hero { min-height: 420px; display: grid; grid-template-columns: minmax(0, 1.25fr) minmax(260px, 0.75fr); gap: 18px; align-items: stretch; }
    #|.surface, .panel { border: 1px solid #d8d8d0; background: #fff; border-radius: 6px; }
    #|.moonstage { min-height: 420px; padding: 14px; display: grid; grid-template-rows: auto minmax(280px, 1fr) auto auto; gap: 10px; background: #090c0f; color: #f4f1e8; overflow: hidden; }
    #|.moonstage h2 { color: rgba(244,241,232,.7); margin-bottom: 3px; }
    #|.moonstage-head { display: flex; justify-content: space-between; gap: 12px; align-items: start; position: relative; z-index: 1; }
    #|.moonstage-head b { display: block; font-size: 18px; }
    #|.moonstage-head span, .moonclaim, .moonhud { color: rgba(244,241,232,.68); font-size: 12px; }
    #|.moonstage-head strong { border: 1px solid rgba(255,255,255,.26); border-radius: 5px; padding: 6px 8px; text-transform: uppercase; font-size: 12px; }
    #|.moonviewport { min-height: 280px; border: 1px solid rgba(255,255,255,.14); background: radial-gradient(circle at 50% 45%, #1a2025, #06080a 70%); border-radius: 5px; position: relative; overflow: hidden; touch-action: none; }
    #|#moon-globe-canvas { width: 100%; height: 100%; min-height: 280px; display: block; cursor: grab; }
    #|#moon-globe-canvas:active { cursor: grabbing; }
    #|.moonhud { position: absolute; left: 12px; right: 12px; bottom: 10px; display: flex; justify-content: space-between; gap: 10px; pointer-events: none; flex-wrap: wrap; }
    #|.mooncontrols { display: flex; gap: 8px; flex-wrap: wrap; }
    #|.mooncontrols button { border: 1px solid rgba(255,255,255,.22); color: #f4f1e8; background: rgba(255,255,255,.08); border-radius: 5px; padding: 7px 10px; }
    #|.mooncontrols button:hover { background: rgba(255,255,255,.16); }
    #|.moonclaim { line-height: 1.35; }
    #|.metrics { display: grid; grid-template-columns: repeat(2, minmax(0,1fr)); gap: 10px; padding: 14px; }
    #|.metric { border: 1px solid #e2e2dc; padding: 12px; border-radius: 5px; background: #fdfdfb; }
    #|.metric b { display: block; font-size: 20px; margin-top: 4px; }
    #|.metric span { color: #5b625c; font-size: 12px; }
    #|.toolbar { display: flex; gap: 8px; flex-wrap: wrap; }
    #|.seg { border: 1px solid #c9c9bf; background: #fff; border-radius: 5px; padding: 8px 10px; }
    #|.seg.active { background: #1f6f5b; color: #fff; border-color: #1f6f5b; }
    #|.grid { display: grid; grid-template-columns: repeat(4, minmax(80px, 1fr)); gap: 8px; }
    #|.tile { min-height: 78px; border: 1px solid #d2d2ca; background: #f9faf6; border-radius: 5px; padding: 10px; text-align: left; display: grid; align-content: space-between; }
    #|.tile b { font-size: 18px; }
    #|.tile span { color: #59615a; font-size: 12px; }
    #|.tile.selected { outline: 3px solid #1f6f5b; }
    #|.is-blocked { border-color: #c45f4c; background: #fff4ef; }
    #|.is-review { border-color: #bd9c30; background: #fff9e7; }
    #|.is-ready { border-color: #6ca38f; }
    #|.row { border: 1px solid #dfdfd8; border-radius: 5px; padding: 10px; display: flex; justify-content: space-between; gap: 10px; align-items: center; margin-bottom: 8px; }
    #|.row span { display: block; color: #626a64; font-size: 12px; margin-top: 3px; }
    #|.row strong { font-size: 12px; text-transform: uppercase; }
    #|.card { padding: 14px; }
    #|ul { margin: 0; padding-left: 18px; color: #4e5750; line-height: 1.45; }
    #|@media (max-width: 920px) { .shell { grid-template-columns: 1fr; } .inspector { border-left: 0; border-top: 1px solid #d8d8d0; } .hero { grid-template-columns: 1fr; } .grid { grid-template-columns: repeat(2, minmax(120px, 1fr)); } }
    #|</style>
  css
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

///|
pub fn render_html(view : TrustedSquareViewModel) -> String {
  let title = html_escape(view.title)
  let decision = html_escape(view.scorecard.decision)
  let next_action = html_escape(view.scorecard.next_action)
  let source_title = html_escape(view.source_panel.source_title)
  let source_path = html_escape(view.source_panel.local_source_path)
  let source_catalog_path = html_escape(view.source_panel.catalog_manifest_path)
  let source_authority = html_escape(view.source_panel.authority)
  let source_review = html_escape(view.source_panel.review_status)
  let view_json = render_json(view).stringify(indent=2)
  let motion_contract = traverse_motion_contract(view)
  let motion_contract_json = motion_contract.to_json().stringify(indent=2)
  let html =
    $|<!doctype html>
    $|<html lang="en">
    $|<head>
    $|<meta charset="utf-8">
    $|<meta name="viewport" content="width=device-width, initial-scale=1">
    $|<title>Moonmoon - \{title}</title>
    $|\{app_styles()}
    $|</head>
    $|<body>
    $|<script id="moonmoon-view-model" type="application/json">
    $|\{view_json}
    $|</script>
    $|<script id="moonmoon-motion-contract" type="application/json">
    $|\{motion_contract_json}
    $|</script>
    $|<main class="shell">
    $|  <section class="workspace">
    $|    <header class="topbar"><div><h1>\{title}</h1><p class="summary">\{next_action}</p></div><strong class="badge">mission \{decision}</strong></header>
    $|    <section class="hero">\{moon_view_panel(view)}<div class="panel metrics"><div class="metric"><span>score</span><b>\{view.scorecard.score}</b></div><div class="metric"><span>route candidates</span><b>\{view.scorecard.route_candidates}</b></div><div class="metric"><span>blocked routes</span><b>\{view.scorecard.blocked_route_candidates}</b></div><div class="metric"><span>energy margin Wh</span><b>\{view.scorecard.energy_margin_wh}</b></div></div></section>
    $|    <nav class="toolbar" aria-label="layers">\{layer_nav(view)}</nav>
    $|    <section class="grid" aria-label="terrain cells">\{terrain_grid(view)}</section>
    $|  </section>
    $|  <aside class="inspector">
    $|    <section class="card panel"><h2>selected cell</h2><article class="row"><div><b>\{html_escape(view.selected_tile.cell_id)}</b><span>\{html_escape(view.selected_tile.hazard)}</span></div><strong>\{view.selected_tile.elevation_m} m</strong></article></section>
    $|    <section class="card panel"><h2>routes</h2>\{route_list(view)}</section>
    $|    <section class="card panel"><h2>source</h2><article class="row"><div><b>\{source_title}</b><span>\{source_path}</span></div><strong>\{source_review}</strong></article><article class="row"><div><b>\{source_authority}</b><span>\{source_catalog_path}</span></div><strong>\{html_escape(view.source_panel.catalog_status)}</strong></article></section>
    $|    \{motion_contract_panel(motion_contract)}
    $|    <section class="card panel"><h2>facts</h2>\{fact_list(view)}</section>
    $|    <section class="card panel"><h2>blockers</h2><ul>\{blocker_list(view)}</ul></section>
    $|  </aside>
    $|</main>
    $|\{moon_globe_script()}
    $|</body>
    $|</html>
  html
}

///|
pub fn first_trusted_square_html() -> String {
  render_html(first_trusted_square_view_model())
}

///|
pub fn first_trusted_square_catalog_html(
  root : String,
) -> Result[String, CatalogBackedViewIssue] {
  let view = match first_trusted_square_view_model_from_catalog_root(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(render_html(view))
}
