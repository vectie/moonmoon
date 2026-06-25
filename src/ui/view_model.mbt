///|
pub(all) enum ViewLayerKind {
  ElevationLayer
  HazardLayer
  RouteLayer
  EvidenceLayer
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TerrainCellView {
  cell_id : String
  row : Int
  col : Int
  elevation_m : Double
  hazard : String
  confidence : Double
  source_dataset_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RouteView {
  route_id : String
  label : String
  selected : Bool
  decision : String
  score : Int
  max_grade : Double
  roughness_m : Double
  evidence_tile_id : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct InspectorFact {
  fact_id : String
  label : String
  value : String
  status : String
  evidence_path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TrustedSquareViewModel {
  view_id : String
  site_id : String
  title : String
  rows : Int
  cols : Int
  cell_size_m : Double
  layers : Array[ViewLayerKind]
  selected_route_id : String
  terrain_cells : Array[TerrainCellView]
  routes : Array[RouteView]
  inspector_facts : Array[InspectorFact]
  blockers : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn view_layer_kind_label(kind : ViewLayerKind) -> String {
  match kind {
    ElevationLayer => "elevation"
    HazardLayer => "hazard"
    RouteLayer => "route"
    EvidenceLayer => "evidence"
  }
}

///|
fn terrain_cell_views(grid : @terrain.TerrainGrid) -> Array[TerrainCellView] {
  let metrics = @terrain.analyze(grid)
  let hazard = @terrain.hazard_label(metrics.hazard_class)
  let cells : Array[TerrainCellView] = []
  for cell in grid.cells {
    cells.push({
      cell_id: "\{grid.tile_id}/r\{cell.row}-c\{cell.col}",
      row: cell.row,
      col: cell.col,
      elevation_m: cell.elevation_m,
      hazard,
      confidence: cell.uncertainty.confidence,
      source_dataset_id: grid.source_manifest.dataset_id,
    })
  }
  cells
}

///|
fn route_views(
  routes : Array[@mission.RouteCandidate],
  selected_route_id : String,
) -> Array[RouteView] {
  let views : Array[RouteView] = []
  for route in routes {
    views.push({
      route_id: route.route_id,
      label: route.label,
      selected: route.route_id == selected_route_id,
      decision: @mission.route_candidate_status_label(route),
      score: route.score,
      max_grade: route.expected_max_grade,
      roughness_m: route.expected_roughness_m,
      evidence_tile_id: route.evidence_tile_id,
      next_action: route.next_action,
    })
  }
  views
}

///|
fn inspector_facts(
  dossier : @site.SiteDossier,
  selected_route_id : String,
) -> Array[InspectorFact] {
  let best = dossier.corridor_scan[0]
  [
    {
      fact_id: "source-datasets",
      label: "Source datasets",
      value: "\{dossier.datasets.length()} checked datasets",
      status: "ready",
      evidence_path: "output/moonbook/workspaces/first-trusted-square/index.json",
    },
    {
      fact_id: "best-corridor-window",
      label: "Best corridor window",
      value: "\{best.window_id} -> \{selected_route_id}",
      status: @mission.corridor_scan_window_status_label(best),
      evidence_path: "mission/first-trusted-square/corridor-scan.json",
    },
    {
      fact_id: "power-window-evidence",
      label: "Power-window evidence",
      value: dossier.power_window_evidence.source_status,
      status: if dossier.power_window_evidence.has_time_window_ephemeris {
        "ready"
      } else {
        "blocked"
      },
      evidence_path: "mission/first-trusted-square/power-window-evidence.json",
    },
    {
      fact_id: "energy-window",
      label: "Energy window",
      value: "\{dossier.energy.margin_wh} Wh margin",
      status: @mission.energy_decision_label(dossier.energy),
      evidence_path: "mission/first-trusted-square/energy-window.json",
    },
  ]
}

///|
pub fn from_site_dossier(dossier : @site.SiteDossier) -> TrustedSquareViewModel {
  let grid = @terrain.first_trusted_square_grid()
  let best = dossier.corridor_scan[0]
  let selected_route_id = best.selected_route_id
  {
    view_id: "ui/first-trusted-square/operator-view-v1",
    site_id: dossier.site.site_id,
    title: dossier.site.name,
    rows: grid.rows,
    cols: grid.cols,
    cell_size_m: grid.cell_size_m,
    layers: [ElevationLayer, HazardLayer, RouteLayer, EvidenceLayer],
    selected_route_id,
    terrain_cells: terrain_cell_views(grid),
    routes: route_views(dossier.route_candidates, selected_route_id),
    inspector_facts: inspector_facts(dossier, selected_route_id),
    blockers: dossier.blockers,
  }
}

///|
pub fn first_trusted_square_view_model() -> TrustedSquareViewModel {
  from_site_dossier(@site.first_trusted_square_dossier())
}

///|
pub fn render_markdown(view : TrustedSquareViewModel) -> String {
  let mut text = "# \{view.title} View Model\n\n"
  text += "- view: \{view.view_id}\n"
  text += "- grid: \{view.rows}x\{view.cols} @ \{view.cell_size_m} m\n"
  text += "- selected route: \{view.selected_route_id}\n"
  text += "- layers: "
  let layer_labels : Array[String] = []
  for layer in view.layers {
    layer_labels.push(view_layer_kind_label(layer))
  }
  text += "\{layer_labels.join(", ")}\n\n"
  text += "## Routes\n\n"
  for route in view.routes {
    let marker = if route.selected { "*" } else { "-" }
    text += "\{marker} \{route.route_id}: \{route.decision}, score \{route.score}, grade \{route.max_grade}, roughness \{route.roughness_m} m\n"
  }
  text += "\n## Inspector\n\n"
  for fact in view.inspector_facts {
    text += "- \{fact.label}: \{fact.value} (\{fact.status})\n"
  }
  text += "\n## Terrain Cells\n\n"
  for cell in view.terrain_cells {
    text += "- r\{cell.row} c\{cell.col}: \{cell.elevation_m} m, \{cell.hazard}, confidence \{cell.confidence}\n"
  }
  text
}

///|
pub fn first_trusted_square_markdown() -> String {
  render_markdown(first_trusted_square_view_model())
}

///|
pub fn render_json(view : TrustedSquareViewModel) -> Json {
  view.to_json()
}

///|
pub fn first_trusted_square_json() -> Json {
  render_json(first_trusted_square_view_model())
}
