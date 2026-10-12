///|
test "comparison digest binds both assessments path outputs and summaries" {
  let source = import_bundle(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0", "sample", "Synthetic",
    "m", "Synthetic",
  ).stringify()
  let result = compare_path_bundle(source, source, "0,0", 45.0, 0.0)
  assert_eq(
    digest(json_text(result, "comparison_csv")),
    json_text(result, "comparison_csv_digest"),
  )
  let identity = json_text(result, "comparison_digest")
  guard result is Object(fields) else { fail("Expected object") }
  fields.remove("comparison_digest")
  assert_eq(identity, digest(result.stringify()))
  fields["reference_assessment"] = Json::null()
  assert_true(identity != digest(result.stringify()))
}

///|
test "comparison rejects overflowing cross-source deltas" {
  let a = import_bundle(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 -1e308", "sample", "Synthetic",
    "m", "Synthetic",
  ).stringify()
  let b = import_bundle(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 1e308", "sample", "Synthetic",
    "m", "Synthetic",
  ).stringify()
  assert_true((try? compare_path_bundle(a, b, "0,0", 45.0, 0.0)) is Err(_))
}
