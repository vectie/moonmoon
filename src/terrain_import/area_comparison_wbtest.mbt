///|
test "area comparison binds complete result and exact exported texts" {
  let source = import_bundle(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 2 3", "cell", "Synthetic",
    "m", "Synthetic",
  ).stringify()
  let result = compare_area_bundle(source, source, 0.0)
  guard result is Object(fields) else { fail("Missing result") }
  for
    (text_key, digest_key) in [
      ("changes_csv", "changes_csv_digest"),
      ("change_map_svg", "change_map_svg_digest"),
      ("report_markdown", "report_markdown_digest"),
    ] {
    assert_eq(
      json_text(result, digest_key),
      digest(json_text(result, text_key)),
    )
  }
  let identity = json_text(result, "comparison_digest")
  fields.remove("comparison_digest")
  assert_eq(identity, digest(result.stringify()))
}
