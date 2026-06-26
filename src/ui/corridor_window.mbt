///|
fn corridor_window_view(
  window : @mission.CorridorScanWindow,
) -> CorridorWindowView {
  {
    window_id: window.window_id,
    rank: window.rank,
    row_offset: window.row_offset,
    col_offset: window.col_offset,
    min_elevation_m: window.min_elevation_m,
    max_elevation_m: window.max_elevation_m,
    elevation_range_m: window.elevation_range_m,
    max_neighbor_grade: window.max_neighbor_grade,
    roughness_m: window.roughness_m,
    decision: @mission.corridor_scan_window_status_label(window),
    selected_route_id: window.selected_route_id,
  }
}

///|
fn corridor_window_views(
  windows : Array[@mission.CorridorScanWindow],
) -> Array[CorridorWindowView] {
  windows.map(corridor_window_view)
}
