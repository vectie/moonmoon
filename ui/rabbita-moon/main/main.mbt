///|
using @html {
  article,
  aside,
  b,
  button,
  canvas,
  details,
  div,
  h1,
  h2,
  header,
  input,
  label,
  li,
  main_,
  p,
  section,
  span,
  strong,
  summary,
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
#cfg(target="js")
extern "js" fn render_3d_scene(model_json : String) -> Unit = "(modelJson) => globalThis.__moonmoonRenderScene3d?.(modelJson)"

///|
#cfg(target="js")
extern "js" fn bind_operator_ui(model_json : String) -> Unit = "(modelJson) => globalThis.__moonmoonBindOperatorUi?.(modelJson)"

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
  div(class="metric", [b(value), span(label)])
}

///|
fn layer_legend(view : @ui.TrustedSquareViewModel) -> Html {
  let items : Array[Html] = []
  for layer in view.layers {
    let active = if layer.layer_id == view.active_layer_id {
      " active"
    } else {
      ""
    }
    items.push(span(class="legend-item\{active}", layer.label))
  }
  div(
    class="layer-legend",
    attrs=@html.Attrs::build().aria_label("available evidence layers"),
    items,
  )
}

///|
fn terrain_grid(view : @ui.TrustedSquareViewModel) -> Html {
  let items : Array[Html] = []
  for cell in view.terrain_cells {
    let selected = if cell.selected { " selected" } else { "" }
    items.push(
      button(
        id="terrain-cell-r\{cell.row}-c\{cell.col}",
        class="tile terrain-cell-choice \{status_class(cell.hazard)}\{selected}",
        type_="button",
        attrs=@html.Attrs::build()
          .data_set("cell-id", cell.cell_id)
          .aria_pressed(if cell.selected { "true" } else { "false" }),
        [
          span("r\{cell.row} c\{cell.col}"),
          b("\{cell.elevation_m} m"),
        ],
      ),
    )
  }
  section(
    class="grid",
    attrs=@html.Attrs::build().aria_label("terrain cell evidence"),
    items,
  )
}

///|
fn selected_route_view(view : @ui.TrustedSquareViewModel) -> @ui.RouteView {
  for route in view.routes {
    if route.selected {
      return route
    }
  }
  view.routes[0]
}

///|
fn route_picker(view : @ui.TrustedSquareViewModel) -> Html {
  let choices : Array[Html] = []
  for route in view.routes {
    let active = if route.selected { " active" } else { "" }
    let authority = if route.selected { "mission selected" } else { "candidate" }
    choices.push(
      button(
        id="route-inspect-\{route.route_id}",
        class="route-choice\{active}",
        type_="button",
        attrs=@html.Attrs::build()
          .data_set("route-id", route.route_id)
          .aria_pressed(if route.selected { "true" } else { "false" }),
        [
          div([b(route.label), span(route.route_id)]),
          div(class="route-choice-meta", [
            strong(class=status_class(route.decision), route.decision),
            span(class="route-authority", authority),
          ]),
        ],
      ),
    )
  }
  section(class="route-picker", [
    span(class="eyebrow", "Compare route candidates"),
    div(class="route-options", choices),
  ])
}

///|
fn illumination_gate(route : @ui.RouteView) -> Html {
  let evidence = route.illumination
  let horizon_sectors : Array[Html] = []
  for sample in evidence.horizon_profile {
    horizon_sectors.push(
      span(class="horizon-sector", [
        span(class="horizon-track", [
          span(
            id="operator-horizon-bar-\{sample.label}",
            class="horizon-bar",
            "",
          ),
        ]),
        b(sample.label),
        span(
          id="operator-horizon-angle-\{sample.label}",
          "\{sample.horizon_angle_deg}",
        ),
      ]),
    )
  }
  section(class="illumination-gate", [
    header([
      div([
        span(class="eyebrow", "Illumination gate"),
        b(id="operator-illumination-window", "\{evidence.time_start_utc} to \{evidence.time_end_utc}"),
      ]),
      strong(
        id="operator-illumination-status",
        class=status_class(evidence.decision),
        evidence.decision,
      ),
    ]),
    div(class="illumination-metrics", [
      span([
        b(id="operator-illumination-horizon", "\{evidence.max_horizon_angle_deg} deg"),
        span("max horizon"),
      ]),
      span([
        b(id="operator-illumination-sun", "\{evidence.max_sun_altitude_deg} deg"),
        span("max sun"),
      ]),
      span([
        b(id="operator-illumination-margin", "\{evidence.terrain_shadow_margin_deg} deg"),
        span("shadow margin"),
      ]),
      span([
        b(id="operator-illumination-confidence", "\{evidence.confidence}"),
        span("confidence"),
      ]),
    ]),
    div(
      class="horizon-profile",
      attrs=@html.Attrs::build().aria_label("azimuth horizon profile"),
      horizon_sectors,
    ),
    p(
      id="operator-illumination-evidence",
      evidence.horizon_evidence_path,
    ),
  ])
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
fn operator_scene(model : Model) -> Html {
  let view = model.view
  let selected_route = selected_route_view(view)
  section(
    class="operator-shell",
    attrs=@html.Attrs::build().aria_label("lunar site operator view"),
    [
      section(class="lunar-stage", [
        input(
          input_type=@html.Checkbox,
          id="moon-terrain-switch",
          class="view-switch-input",
        ),
        header(class="stage-header", [
          div([span(class="eyebrow", "Moonmoon"), b("Lunar operator")]),
          label(for_="moon-terrain-switch", class="view-switch", [
            span("Moon"),
            b("Site terrain"),
          ]),
        ]),
        div(class="stage-stack", [
          div(class="stage-view stage-moon", [
            canvas(
              id="moonmoon-globe-3d",
              class="scene-canvas moon-globe-canvas",
              attrs=@html.Attrs::build()
                .width(1280)
                .height(900)
                .aria_label("Movable source-backed Moon globe"),
              "",
            ),
          ]),
          div(class="stage-view stage-terrain", [
            canvas(
              id="moonmoon-terrain-3d",
              class="terrain-canvas",
              attrs=@html.Attrs::build()
                .width(1280)
                .height(900)
                .aria_label("LOLA terrain for the first trusted square"),
              "",
            ),
          ]),
        ]),
        div(
          class="stage-controls",
          attrs=@html.Attrs::build().aria_label("Moon view controls"),
          [
            button(
              id="moon-focus-site",
              class="control primary",
              type_="button",
              "Focus site",
            ),
            button(
              id="moon-reset-view",
              class="control",
              type_="button",
              "Reset",
            ),
            button(
              id="moon-toggle-orbit",
              class="control",
              type_="button",
              "Pause orbit",
            ),
          ],
        ),
        div(class="stage-source", [
          span("source \{view.globe_overlay.source_dataset_id}"),
          span("site \{view.site_latitude_deg}, \{view.site_longitude_deg}"),
        ]),
      ]),
      aside(class="decision-rail", [
        header(class="rail-header", [
          div([span(class="eyebrow", "First trusted square"), h1(view.title)]),
          strong(
            class="status \{status_class(view.scorecard.decision)}",
            view.scorecard.decision,
          ),
        ]),
        section(class="route-gate", [
          span(id="operator-route-context", "Mission selected route"),
          h2(id="operator-route-label", selected_route.label),
          span(id="operator-route-id", selected_route.route_id),
          strong(
            id="operator-route-decision",
            class="status \{status_class(selected_route.decision)}",
            selected_route.decision,
          ),
          div(class="route-inspection-metrics", [
            span([b(id="operator-route-score", "\{selected_route.score}"), span("score")]),
            span([
              b(id="operator-route-grade", "\{selected_route.max_grade}"),
              span("max grade"),
            ]),
            span([
              b(id="operator-route-roughness", "\{selected_route.roughness_m} m"),
              span("roughness"),
            ]),
          ]),
          p(id="operator-route-action", selected_route.next_action),
        ]),
        illumination_gate(selected_route),
        route_picker(view),
        div(class="rail-metrics", [
          metric("site score", "\{view.scorecard.score}"),
          metric("blocked routes", "\{view.scorecard.blocked_route_candidates}"),
          metric("energy margin Wh", "\{view.scorecard.energy_margin_wh}"),
        ]),
        section(class="next-evidence", [
          span(class="eyebrow", "Motion handoff"),
          strong(model.contract.status),
          p(model.contract.next_action),
        ]),
        section(class="source-claim", [
          span(class="eyebrow", "Evidence authority"),
          b(view.source_panel.source_title),
          p(view.source_panel.local_source_path),
        ]),
        section(class="rail-blockers", [
          span(class="eyebrow", "Current blockers"),
          blocker_list(view),
        ]),
      ]),
    ],
  )
}

///|
fn hero(view : @ui.TrustedSquareViewModel) -> Html {
  section(class="evidence-hero", [
    div([
      span(class="eyebrow", "Lunar site model"),
      strong("\{view.site_latitude_deg} deg"),
      p(
        "\{view.site_longitude_deg} deg longitude, selected route \{view.selected_route_id}",
      ),
    ]),
    div(class="evidence-metrics", [
      metric("score", "\{view.scorecard.score}"),
      metric("route candidates", "\{view.scorecard.route_candidates}"),
      metric("blocked routes", "\{view.scorecard.blocked_route_candidates}"),
      metric("energy margin Wh", "\{view.scorecard.energy_margin_wh}"),
    ]),
  ])
}

///|
fn motion_contract_panel(contract : @ui.TraverseMotionContract) -> Html {
  section(class="card", [
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
    section(
      id="operator-selected-cell",
      class="card selected-cell-card",
      attrs=@html.Attrs::build().aria_live("polite"),
      [
      h2("selected cell"),
        article(class="row", [
          div([
            b(id="operator-cell-id", view.selected_tile.cell_id),
            span(id="operator-cell-hazard", view.selected_tile.hazard),
          ]),
          strong(id="operator-cell-elevation", "\{view.selected_tile.elevation_m} m"),
        ]),
        div(class="cell-detail-grid", [
          span([span("slope"), b(id="operator-cell-slope", "\{view.selected_tile.slope_grade}")]),
          span([
            span("roughness"),
            b(id="operator-cell-roughness", "\{view.selected_tile.roughness_m} m"),
          ]),
          span([
            span("confidence"),
            b(id="operator-cell-confidence", "\{view.selected_tile.confidence}"),
          ]),
        ]),
      ],
    ),
    section(class="card", [h2("routes")] + route_rows(view)),
    section(class="card", [
      h2("source"),
      row(
        view.source_panel.source_title,
        view.source_panel.local_source_path,
        view.source_panel.review_status,
      ),
    ]),
    motion_contract_panel(model.contract),
    section(class="card", [h2("facts")] + fact_rows(view)),
    section(class="card", [h2("blockers"), blocker_list(view)]),
  ])
}

///|
fn evidence_dossier(model : Model) -> Html {
  let view = model.view
  details(class="evidence-dossier", [
    summary([
      div([
        b("Evidence dossier"),
        span("terrain, routes, source, and clearance"),
      ]),
      strong("Open"),
    ]),
    div(class="evidence-body", [
      header(class="evidence-header", [
        div([h1(view.title), p(view.scorecard.next_action)]),
        strong(
          class="status \{status_class(view.scorecard.decision)}",
          "mission \{view.scorecard.decision}",
        ),
      ]),
      hero(view),
      layer_legend(view),
      terrain_grid(view),
      inspector(model),
    ]),
  ])
}

///|
fn adapter_preview(model : Model) -> Html {
  details(id="moonmoon-adapter-preview", class="adapter-preview", [
    summary([
      div([
        b("Adapter preview"),
        span("Noetix E1 / explicit non-authoritative simulation"),
      ]),
      strong(class=status_class(model.contract.status), model.contract.status),
    ]),
    div(class="adapter-body", [
      div(class="adapter-copy", [
        span(class="eyebrow", "Preview boundary"),
        h2("Robot motion is not route authority"),
        p(model.contract.next_action),
      ]),
      div(class="adapter-viewport", [
        canvas(
          id="moonmoon-third-person-3d",
          class="scene-canvas third-person-canvas",
          attrs=@html.Attrs::build()
            .width(1280)
            .height(720)
            .aria_label("Mission-gated robot adapter preview"),
          "",
        ),
        div(class="adapter-readout", [
          b("preview only"),
          span(model.view.selected_route_id),
        ]),
      ]),
    ]),
  ])
}

///|
fn view(model : Model) -> Html {
  main_(class="moon-shell", [
    operator_scene(model),
    evidence_dossier(model),
    adapter_preview(model),
  ])
}

///|
#cfg(target="js")
fn start_renderer(model : Model) -> @rabbita.Cmd {
  @cmd.custom_cmd(
    _ => {
      render_terrain_canvas(model.model_json)
      render_3d_scene(model.model_json)
      bind_operator_ui(model.model_json)
    },
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
