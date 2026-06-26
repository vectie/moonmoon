///|
pub fn from_site_dossier_with_selection(
  dossier : @site.SiteDossier,
  row : Int,
  col : Int,
) -> TrustedSquareViewModel {
  let grid = @terrain.first_trusted_square_grid()
  let metrics = @terrain.analyze(grid)
  let best = dossier.corridor_scan[0]
  let selected_route_id = best.selected_route_id
  let selected = selected_cell(grid, row, col)
  let selected_cell_id = cell_id(grid, selected.row, selected.col)
  {
    view_id: "ui/first-trusted-square/operator-view-v2",
    site_id: dossier.site.site_id,
    title: dossier.site.name,
    viewport: viewport_geometry(grid),
    layers: view_layers(metrics, dossier.energy),
    active_layer_id: "hazard",
    selected_cell_id,
    selected_route_id,
    terrain_cells: terrain_cell_views(grid, metrics, dossier.energy, selected),
    routes: route_views(dossier.route_candidates, selected_route_id),
    route_overlays: route_overlays(dossier.route_candidates, selected_route_id),
    corridor_windows: corridor_window_views(dossier.corridor_scan),
    selected_tile: tile_inspector(
      grid,
      metrics,
      dossier.energy,
      selected,
      selected_route_id,
    ),
    source_panel: source_panel(grid),
    scorecard: site_scorecard(dossier, selected_route_id),
    inspector_facts: inspector_facts(
      dossier, selected_route_id, selected_cell_id,
    ),
    blockers: dossier.blockers,
  }
}

///|
pub fn from_site_dossier(dossier : @site.SiteDossier) -> TrustedSquareViewModel {
  let grid = @terrain.first_trusted_square_grid()
  let selected = default_selected_cell(grid)
  from_site_dossier_with_selection(dossier, selected.row, selected.col)
}

///|
pub fn first_trusted_square_view_model() -> TrustedSquareViewModel {
  from_site_dossier(@site.first_trusted_square_dossier())
}

///|
pub fn first_trusted_square_view_model_at(
  row : Int,
  col : Int,
) -> TrustedSquareViewModel {
  from_site_dossier_with_selection(
    @site.first_trusted_square_dossier(),
    row,
    col,
  )
}
