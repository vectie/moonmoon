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
