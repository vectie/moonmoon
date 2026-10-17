///|
/// Interactive endpoint selection uses the same source validation and discrete
/// route search as the native CLI. A no-path result is successful computation,
/// not a candidate and never physical authority.
///
/// ```mbt check
/// test {
///   let source = @terrain_import.import_bundle(
///     "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 1", "example", "Synthetic Cartesian frame",
///     "m", "Synthetic example only",
///   )
///   let response = @terrain_import.route_json(
///     source.stringify(),
///     0,
///     0,
///     0,
///     1,
///     20.0,
///     0.0,
///   )
///   assert_true(response.contains("\"candidate-found\""))
/// }
/// ```
pub fn route_json(
  source_bundle : String,
  start_row : Int,
  start_col : Int,
  goal_row : Int,
  goal_col : Int,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> String {
  try {
    let route = route_bundle(
      source_bundle, start_row, start_col, goal_row, goal_col, max_grade_deg, uphill_weight,
    )
    ({ "ok": true, "route": route } : Json).stringify()
  } catch {
    InvalidRaster(message) =>
      ({ "ok": false, "error": message } : Json).stringify()
  }
}
