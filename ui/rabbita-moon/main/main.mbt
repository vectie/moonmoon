///|
using @html {
  article,
  aside,
  b,
  button,
  canvas,
  div,
  h1,
  h2,
  header,
  li,
  main_,
  nav,
  p,
  section,
  span,
  strong,
  ul,
}

///|
using @rabbita {type Html}

///|
struct Model {
  view : @ui.TrustedSquareViewModel
  contract : @ui.TraverseMotionContract
  model_json : String
}

///|
#cfg(target="js")
extern "js" fn render_terrain_canvas(model_json : String) -> Unit = "(modelJson) => globalThis.__moonmoonRenderTerrain?.(modelJson)"

///|
fn init_model() -> Model {
  let view = @ui.first_trusted_square_view_model()
  {
    view,
    contract: @ui.traverse_motion_contract(view),
    model_json: @ui.render_json(view).stringify(),
  }
}

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
fn metric(label : String, value : String) -> Html {
  div(class="metric", [span(label), b(value)])
}

///|
fn layer_nav(view : @ui.TrustedSquareViewModel) -> Html {
  let items : Array[Html] = []
  for layer in view.layers {
    let active = if layer.layer_id == view.active_layer_id {
      " active"
    } else {
      ""
    }
    items.push(button(class="seg\{active}", type_="button", layer.label))
  }
  nav(class="toolbar", attrs=@html.Attrs::build().aria_label("layers"), items)
}

///|
fn terrain_grid(view : @ui.TrustedSquareViewModel) -> Html {
  let items : Array[Html] = []
  for cell in view.terrain_cells {
    let selected = if cell.selected { " selected" } else { "" }
    items.push(
      button(
        class="tile \{status_class(cell.hazard)}\{selected}",
        type_="button",
        [span("r\{cell.row} c\{cell.col}"), b("\{cell.elevation_m} m")],
      ),
    )
  }
  section(
    class="grid",
    attrs=@html.Attrs::build().aria_label("terrain cells"),
    items,
  )
}

///|
fn row(label : String, detail : String, value : String, tone? : String) -> Html {
  let klass = match tone {
    Some(value) => "row \{status_class(value)}"
    None => "row"
  }
  article(class=klass, [div([b(label), span(detail)]), strong(value)])
}

///|
fn route_rows(view : @ui.TrustedSquareViewModel) -> Array[Html] {
  let rows : Array[Html] = []
  for route in view.routes {
    let selected = if route.selected { " selected" } else { "" }
    rows.push(
      article(class="row \{status_class(route.decision)}\{selected}", [
        div([b(route.label), span(route.route_id)]),
        strong(route.decision),
      ]),
    )
  }
  rows
}

///|
fn fact_rows(view : @ui.TrustedSquareViewModel) -> Array[Html] {
  let rows : Array[Html] = []
  for fact in view.inspector_facts {
    rows.push(row(fact.label, fact.evidence_path, fact.value, tone=fact.status))
  }
  rows
}

///|
fn blocker_list(view : @ui.TrustedSquareViewModel) -> Html {
  if view.blockers.is_empty() {
    ul([li("none")])
  } else {
    let items : Array[Html] = []
    for blocker in view.blockers {
      items.push(li(blocker))
    }
    ul(items)
  }
}

///|
fn terrain_scene(view : @ui.TrustedSquareViewModel) -> Html {
  section(
    class="terrain-panel panel",
    attrs=@html.Attrs::build().aria_label("3D lunar terrain view"),
    [
      canvas(
        id="moonmoon-terrain-3d",
        class="terrain-canvas",
        attrs=@html.Attrs::build().width(960).height(460),
        "",
      ),
      div(class="terrain-readout", [
        span([b("3D terrain"), span(" \{view.selected_route_id}")]),
        span("\{view.viewport.rows}x\{view.viewport.cols} LOLA cells"),
      ]),
    ],
  )
}

///|
fn hero(view : @ui.TrustedSquareViewModel) -> Html {
  section(class="hero", [
    div(class="surface", [
      h2("lunar site model"),
      strong("\{view.site_latitude_deg} deg"),
      span(
        "\{view.site_longitude_deg} deg longitude, selected route \{view.selected_route_id}",
      ),
    ]),
    div(class="panel metrics", [
      metric("score", "\{view.scorecard.score}"),
      metric("route candidates", "\{view.scorecard.route_candidates}"),
      metric("blocked routes", "\{view.scorecard.blocked_route_candidates}"),
      metric("energy margin Wh", "\{view.scorecard.energy_margin_wh}"),
    ]),
  ])
}

///|
fn motion_contract_panel(contract : @ui.TraverseMotionContract) -> Html {
  section(class="card panel", [
    h2("motion contract"),
    row(
      contract.preview_kind,
      contract.contract_id,
      contract.status,
      tone=contract.status,
    ),
    row("physics core", contract.physics_core_package, "generic"),
    row(
      "motion owner",
      contract.motion_owner_package,
      contract.gait_asset_status,
    ),
    row(
      "simulation",
      contract.next_action,
      contract.simulation_status,
      tone=contract.simulation_status,
    ),
  ])
}

///|
fn inspector(model : Model) -> Html {
  let view = model.view
  aside(class="inspector", [
    section(class="card panel", [
      h2("selected cell"),
      row(
        view.selected_tile.cell_id,
        view.selected_tile.hazard,
        "\{view.selected_tile.elevation_m} m",
      ),
    ]),
    section(class="card panel", [h2("routes")] + route_rows(view)),
    section(class="card panel", [
      h2("source"),
      row(
        view.source_panel.source_title,
        view.source_panel.local_source_path,
        view.source_panel.review_status,
      ),
    ]),
    motion_contract_panel(model.contract),
    section(class="card panel", [h2("facts")] + fact_rows(view)),
    section(class="card panel", [h2("blockers"), blocker_list(view)]),
  ])
}

///|
fn view(model : Model) -> Html {
  let view = model.view
  main_(class="moon-shell", [
    section(class="workspace", [
      header(class="topbar", [
        div([h1(view.title), p(class="summary", view.scorecard.next_action)]),
        strong(class="badge ready", "mission \{view.scorecard.decision}"),
      ]),
      hero(view),
      terrain_scene(view),
      layer_nav(view),
      terrain_grid(view),
    ]),
    inspector(model),
  ])
}

///|
#cfg(target="js")
fn start_renderer(model : Model) -> @rabbita.Cmd {
  @cmd.custom_cmd(
    _ => render_terrain_canvas(model.model_json),
    kind=@cmd.after_render,
  )
}

///|
#cfg(target="js")
#warnings("-alert_unstable")
fn main {
  let model = init_model()
  let app = @rabbita.new(@rabbita.static_cell(view(model)))
  app.with_init(start_renderer(model))
  app.mount("app")
}
