///|
let revision_ascii = "ncols 3\nnrows 3\nxllcorner 100\nyllcorner 200\ncellsize 10\nNODATA_value -9999\n0 0 0\n0 0 0\n0 -9999 0\n"

///|
let revision_header = "row,col,expected_elevation_m,elevation_m\n"

///|
fn revision_source() -> Json raise {
  @terrain_import.import_bundle(
    revision_ascii, "editable", "Synthetic local frame", "m", "Synthetic only",
  )
}

///|
fn revision_field(value : Json, key : String) -> Json {
  guard value is Object(fields) && fields.get(key) is Some(result) else {
    abort("Missing revision test field " + key)
  }
  result
}

///|
fn reject_revision(source : Json, csv : String, reason : String) -> Unit raise {
  try @terrain_import.revise_bundle(source.stringify(), csv, reason) catch {
    @terrain_import.ImportError::InvalidRaster(_) => ()
  } noraise {
    _ => fail("Expected terrain revision rejection")
  }
}

///|
test "revision template preserves unknown and exact row order" {
  let source = revision_source()
  assert_eq(
    @terrain_import.revision_template(source.stringify()),
    revision_header +
    "0,0,0,0\n0,1,0,0\n0,2,0,0\n1,0,0,0\n1,1,0,0\n1,2,0,0\n2,0,0,0\n2,1,unknown,unknown\n2,2,0,0\n",
  )
  reject_revision(
    source,
    @terrain_import.revision_template(source.stringify()),
    "No change",
  )
}

///|
test "ASCII revision keeps original and declares numeric sentinel as real value" {
  let source = revision_source()
  let original = source.stringify()
  let edits = revision_header + "0,1,0,unknown\n2,1,unknown,-9999\n1,1,0,2.5\n"
  let revised = @terrain_import.revise_bundle(
    original, edits, "Caller-declared synthetic correction",
  )
  assert_eq(source.stringify(), original)
  assert_eq(revision_field(revised, "base_source_bundle"), source)
  assert_eq(revision_field(revised, "origin_kind"), "corner".to_json())
  assert_eq(revision_field(revised, "origin_x"), (100).to_json())
  assert_eq(
    revision_field(revised, "coordinate_frame"),
    revision_field(source, "coordinate_frame"),
  )
  assert_eq(
    revision_field(revised, "source_note"),
    revision_field(source, "source_note"),
  )
  assert_eq(revision_field(revised, "sample_count"), (8).to_json())
  assert_eq(revision_field(revised, "nodata_count"), (1).to_json())
  assert_eq(revision_field(revised, "nodata_value"), Json::null())
  assert_eq(revision_field(revised, "minimum_elevation_m"), (-9999).to_json())
  assert_eq(revision_field(revised, "changed_cells_in_revision"), (3).to_json())
  assert_eq(revision_field(revised, "physical_readiness"), false.to_json())
  assert_eq(revision_field(revised, "review_required"), true.to_json())
  assert_eq(@terrain_import.reopen_bundle(revised.stringify(indent=2)), revised)
  assert_eq(
    revision_field(revised, "terrain_csv"),
    "tile_id,row,col,elevation_m\neditable,0,0,0\neditable,0,2,0\neditable,1,0,0\neditable,1,1,2.5\neditable,1,2,0\neditable,2,0,0\neditable,2,1,-9999\neditable,2,2,0\n".to_json(),
  )
}

///|
test "revision chain reopens and binds prior bundle without nested history" {
  let source = revision_source()
  let first = @terrain_import.revise_bundle(
    source.stringify(),
    revision_header + "2,1,unknown,1\n",
    "Synthetic addition",
  )
  let second = @terrain_import.revise_bundle(
    first.stringify(indent=2),
    revision_header + "2,1,1,unknown\n",
    "Withdraw declared addition",
  )
  assert_eq(revision_field(second, "base_source_bundle"), source)
  assert_eq(revision_field(second, "revision_count"), (2).to_json())
  assert_eq(revision_field(second, "changed_cells_in_history"), (2).to_json())
  assert_eq(
    revision_field(second, "terrain_csv"),
    revision_field(source, "terrain_csv"),
  )
  assert_true(
    revision_field(second, "source_digest") !=
    revision_field(source, "source_digest"),
  )
  assert_true(
    revision_field(second, "source_digest") !=
    revision_field(first, "source_digest"),
  )
  let first_analysis = @terrain_import.analyze_bundle(
    first.stringify(),
    "row",
    1,
    10.0,
  )
  assert_eq(
    revision_field(second, "parent_bundle_digest"),
    revision_field(first_analysis, "source_bundle_digest"),
  )
  assert_eq(@terrain_import.reopen_bundle(second.stringify(indent=4)), second)
  assert_eq(
    @terrain_import.revise_bundle(
      first.stringify(),
      revision_header + "2,1,1,unknown\n",
      "Withdraw declared addition",
    ),
    second,
  )
  reject_revision(second, revision_header + "2,1,1,2\n", "Stale edit")
}

///|
test "editable full sheet accepts unchanged rows but checks their preconditions" {
  let source = revision_source()
  let template = @terrain_import.revision_template(source.stringify())
  let edited = template.replace(old="1,1,0,0", new="1,1,0,1")
  let revised = @terrain_import.revise_bundle(
    source.stringify(),
    edited,
    "One declared cell change",
  )
  assert_eq(revision_field(revised, "changed_cells_in_revision"), (1).to_json())
  let stale = template.replace(old="0,0,0,0", new="0,0,0,2")
  reject_revision(revised, stale, "Stale unchanged center must not be ignored")
}

///|
test "revision rejects invalid rows values duplicates and missing reasons" {
  let source = revision_source()
  for
    csv in [
      "row,col,elevation_m\n0,0,1\n",
      revision_header,
      revision_header + "0,0,0,1\n0,0,1,2\n",
      revision_header + "-1,0,0,1\n",
      revision_header + "3,0,0,1\n",
      revision_header + "0,3,0,1\n",
      revision_header + "0.5,0,0,1\n",
      revision_header + "0,0,0,\n",
      revision_header + "0,0,,1\n",
      revision_header + "0,0,unknown,1\n",
      revision_header + "0,0,0,nan\n",
      revision_header + "0,0,0,1e999\n",
      revision_header + "0,0,0,1,extra\n",
      revision_header + "0,0,0,\"1\"\n",
    ] {
    reject_revision(source, csv, "Synthetic invalid fixture")
  }
  reject_revision(source, revision_header + "0,0,0,1\n", " ")
  reject_revision(source, revision_header + "0,0,0,1\n", "x".repeat(2001))
}

///|
test "XYZ revisions fill and mask coverage consumed by existing analysis routes" {
  let spec = "{\"contract_id\":\"moonmoon.xyz-grid.v1\",\"tile_id\":\"edit-xyz\",\"coordinate_frame\":\"Synthetic\",\"horizontal_unit\":\"m\",\"source_note\":\"Synthetic\",\"rows\":3,\"cols\":3,\"origin_x\":0,\"origin_y\":0,\"cell_size\":10}"
  let points = "x,y,elevation_m\n0,20,0\n10,20,0\n20,20,0\n0,10,0\n20,10,0\n0,0,0\n10,0,0\n20,0,0\n"
  let source = @terrain_import.import_xyz_bundle(points, spec)
  let filled = @terrain_import.revise_bundle(
    source.stringify(),
    revision_header + "1,1,unknown,0\n",
    "Caller declares missing center",
  )
  let analysis = @terrain_import.analyze_bundle(
    filled.stringify(),
    "row",
    1,
    10.0,
  )
  assert_eq(revision_field(analysis, "source_bundle"), filled)
  assert_eq(
    revision_field(revision_field(analysis, "grid_summary"), "estimated_cells"),
    (1).to_json(),
  )
  assert_eq(
    revision_field(
      revision_field(analysis, "profile_summary"),
      "known_segments",
    ),
    (2).to_json(),
  )
  let route = @terrain_import.route_bundle(
    filled.stringify(),
    1,
    0,
    1,
    2,
    10.0,
    0.0,
  )
  assert_eq(revision_field(route, "source_bundle"), filled)
  assert_eq(
    revision_field(revision_field(route, "summary"), "horizontal_distance_m"),
    (20).to_json(),
  )
  let masked = @terrain_import.revise_bundle(
    filled.stringify(),
    revision_header + "1,1,0,unknown\n",
    "Suspect center withheld",
  )
  let detour = @terrain_import.route_bundle(
    masked.stringify(),
    1,
    0,
    1,
    2,
    10.0,
    0.0,
  )
  assert_eq(
    revision_field(revision_field(detour, "summary"), "horizontal_distance_m"),
    (40).to_json(),
  )
  let masked_analysis = @terrain_import.analyze_bundle(
    masked.stringify(),
    "row",
    1,
    10.0,
  )
  assert_eq(
    revision_field(
      revision_field(masked_analysis, "grid_summary"),
      "estimated_cells",
    ),
    (0).to_json(),
  )
  assert_eq(
    revision_field(
      revision_field(masked_analysis, "profile_summary"),
      "unknown_segments",
    ),
    (2).to_json(),
  )
  let waypoint = @terrain_import.route_waypoints_bundle(
    masked.stringify(),
    "row,col\n1,0\n1,1\n1,2\n",
    10.0,
    0.0,
  )
  assert_eq(revision_field(waypoint, "route_complete"), false.to_json())
  assert_eq(@terrain_import.reopen_bundle(masked.stringify()), masked)
}

///|
test "revision reopen rejects altered history parent original values and authority" {
  let source = revision_source()
  let revised = @terrain_import.revise_bundle(
    source.stringify(),
    revision_header + "1,1,0,1\n",
    "Synthetic",
  )
  for
    (key, value) in [
      ("terrain_csv", "changed".to_json()),
      ("source_text", "changed".to_json()),
      ("source_digest", "sha256:changed".to_json()),
      ("parent_bundle_digest", "sha256:changed".to_json()),
      ("base_source_bundle_digest", "sha256:changed".to_json()),
      ("changes_csv", "changed".to_json()),
      ("changes_csv_digest", "sha256:changed".to_json()),
      ("revision_count", (2).to_json()),
      ("physical_readiness", true.to_json()),
      ("base_source_bundle", revised),
      (
        "revisions",
        (
          [
            {
              "edits_csv": revision_header + "1,1,0,2\n",
              "reason": "Synthetic",
            },
          ] : Array[Json]).to_json(),
      ),
      (
        "revisions",
        (
          [
            {
              "edits_csv": revision_header + "1,1,0,1\n",
              "reason": "Changed declaration",
            },
          ] : Array[Json]).to_json(),
      ),
      ("revisions", ([] : Array[Json]).to_json()),
    ] {
    let changed = @json.parse(revised.stringify())
    guard changed is Object(fields) else { abort("Expected object") }
    fields[key] = value
    assert_true(
      @terrain_import.reopen_json(changed.stringify()).contains("\"ok\":false"),
    )
  }
}

///|
test "revised degree grid stays inspection only" {
  let source = @terrain_import.import_bundle(
    revision_ascii, "degrees", "Declared angular frame", "degrees", "Synthetic",
  )
  let revised = @terrain_import.revise_bundle(
    source.stringify(),
    revision_header + "1,1,0,1\n",
    "Synthetic",
  )
  assert_eq(revision_field(revised, "horizontal_unit"), "degrees".to_json())
  assert_eq(@terrain_import.reopen_bundle(revised.stringify()), revised)
  try
    @terrain_import.analyze_bundle(revised.stringify(), "row", 1, 10.0)
  catch {
    @terrain_import.ImportError::InvalidRaster(_) => ()
  } noraise {
    _ => fail("Expected metric degree-grid rejection")
  }
}

///|
test "revision history is bounded to 32 entries" {
  let mut source = revision_source()
  for i in 0..<32 {
    source = @terrain_import.revise_bundle(
      source.stringify(),
      revision_header + "1,1,\{i},\{i + 1}\n",
      "Synthetic revision \{i + 1}",
    )
  }
  assert_eq(revision_field(source, "revision_count"), (32).to_json())
  assert_eq(@terrain_import.reopen_bundle(source.stringify()), source)
  reject_revision(source, revision_header + "1,1,32,33\n", "Too many revisions")
}

///|
test "revision cumulative changes bound includes cells revised more than once" {
  let row = Array::make(64, "0").join(" ")
  let raster = "ncols 64\nnrows 64\nxllcenter 0\nyllcenter 0\ncellsize 1\n" +
    Array::make(64, row).join("\n") +
    "\n"
  let source = @terrain_import.import_bundle(
    raster, "limit", "Synthetic", "m", "Synthetic",
  )
  let edits = [revision_header.trim().to_owned()]
  for i in 0..<4096 {
    edits.push("\{i / 64},\{i % 64},0,1")
  }
  let revised = @terrain_import.revise_bundle(
    source.stringify(),
    edits.join("\n"),
    "Synthetic maximum-size edit",
  )
  assert_eq(
    revision_field(revised, "changed_cells_in_history"),
    (4096).to_json(),
  )
  assert_eq(@terrain_import.reopen_bundle(revised.stringify(indent=2)), revised)
  reject_revision(revised, revision_header + "0,0,1,2\n", "One more change")
}

///|
test "revision CRLF input keeps raw text and accepts finite scientific values" {
  let edits = "row,col,expected_elevation_m,elevation_m\r\n 1, 1, 0e0, 2.5e1 \r\n"
  let revised = @terrain_import.revise_bundle(
    revision_source().stringify(),
    edits,
    "Synthetic Unicode declaration: 月",
  )
  assert_eq(revision_field(revised, "maximum_elevation_m"), (25).to_json())
  guard revision_field(revised, "revisions") is Array(entries) else {
    abort("Expected history")
  }
  assert_eq(revision_field(entries[0], "edits_csv"), edits.to_json())
  assert_eq(@terrain_import.reopen_bundle(revised.stringify()), revised)
}
