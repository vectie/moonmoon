///|
test "corridor digest binds exact inputs source every output and summary" {
  let source = import_bundle(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0", "sample", "Synthetic",
    "m", "Synthetic",
  ).stringify()
  let result = assess_corridor_bundle(
    source, "row,col\r\n0,0\r\n", 1, 15.0, 1.0,
  )
  for
    (value, hash) in [
      ("input_path_text", "input_path_digest"),
      ("path_cells_text", "path_cells_digest"),
      ("cells_csv", "cells_csv_digest"),
      ("stops_csv", "stops_csv_digest"),
      ("corridor_svg", "corridor_svg_digest"),
    ] {
    assert_eq(digest(json_text(result, value)), json_text(result, hash))
  }
  assert_eq(
    digest(route_field(result, "source_bundle").stringify()),
    json_text(result, "source_bundle_digest"),
  )
  let identity = json_text(result, "corridor_digest")
  guard result is Object(fields) else { fail("Expected object") }
  fields.remove("corridor_digest")
  assert_eq(identity, digest(result.stringify()))
  fields["summary"] = Json::null()
  assert_true(identity != digest(result.stringify()))
}
