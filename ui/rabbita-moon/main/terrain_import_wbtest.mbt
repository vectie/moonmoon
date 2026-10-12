///|
#warnings("-alert_unstable")
test "terrain import controls compile with real MoonBit parser and explicit units" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(terrain_import_panel()),
  )
  assert_true(html.contains("Explore a local terrain raster"))
  assert_true(html.contains("terrain-import-metres"))
  assert_true(html.contains("terrain-import-results"))
  assert_true(html.contains("does not replace the frozen mission terrain"))
  assert_true(html.contains("roughness and row/column profiles"))
  let result = @terrain_import.import_json(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 42", "ui-test", "local",
    "m", "Synthetic test",
  )
  assert_true(result.contains("\"elevation_m\":42"))
  let source = @terrain_import.import_bundle(
    "ncols 3 nrows 3 xllcenter 0 yllcenter 0 cellsize 10 40 50 60 20 30 40 0 10 20",
    "ui-plane", "synthetic Cartesian frame", "m", "Synthetic test",
  )
  let analysis = @terrain_import.analysis_json(
    source.stringify(),
    "row",
    1,
    60.0,
  )
  assert_true(analysis.contains("\"ok\":true"))
  assert_true(analysis.contains("threshold-exceeded"))
  assert_true(analysis.contains("\"unknown_cells\":8"))
}
