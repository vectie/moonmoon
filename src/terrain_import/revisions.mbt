///|
fn revision_value(text : String, label : String) -> Double? raise ImportError {
  if text == "unknown" {
    None
  } else {
    Some(number(text, label))
  }
}

///|
fn revision_cell(value : Double?) -> String {
  value.map(v => v.to_string()).unwrap_or("unknown")
}

///|
// A full exported sheet may include unchanged rows. Expected values are checked
// even for those rows, so a sheet from another revision cannot silently win.
fn apply_revision_edits(
  grid : AsciiGrid,
  text : String,
) -> (Int, String) raise ImportError {
  need(text.length() <= 262144, "Revision CSV exceeds 256 KiB character limit")
  let lines = text.split("\n").collect()
  need(
    !lines.is_empty() &&
    lines[0].trim() == "row,col,expected_elevation_m,elevation_m",
    "Revision CSV requires row,col,expected_elevation_m,elevation_m header",
  )
  let seen = Array::make(grid.values.length(), false)
  let changes = ["row,col,before_elevation_m,after_elevation_m,action"]
  let mut count = 0
  let mut records = 0
  for i in 1..<lines.length() {
    let line = lines[i].trim()
    if line.is_empty() {
      continue
    }
    records += 1
    need(records <= 4096, "Revision CSV supports at most 4096 rows")
    let fields = line.split(",").map(v => v.trim().to_owned()).collect()
    let label = "Revision CSV line " + (i + 1).to_string()
    need(fields.length() == 4, label + " needs four fields")
    fn index(text : String, size : Int) -> Int raise ImportError {
      let value = @string.parse_int(text) catch {
        _ => raise InvalidRaster(label + " needs integer row and column")
      }
      need(value >= 0 && value < size, label + " is outside the source grid")
      value
    }
    let row = index(fields[0], grid.rows)
    let col = index(fields[1], grid.cols)
    let offset = row * grid.cols + col
    need(!seen[offset], label + " repeats a cell")
    seen[offset] = true
    let expected = revision_value(fields[2], label + " expected elevation")
    let next = revision_value(fields[3], label + " elevation")
    need(
      grid.values[offset] == expected,
      label +
      " expected elevation differs from the source; export a fresh template",
    )
    if expected != next {
      count += 1
      grid.values[offset] = next
      let action = if next is None {
        "mark-unknown"
      } else {
        "set-declared-value"
      }
      changes.push(
        "\{row},\{col},\{revision_cell(expected)},\{revision_cell(next)},\{action}",
      )
    }
  }
  need(count > 0, "Revision must change at least one cell")
  (count, changes.join("\n") + "\n")
}

///|
fn revision_parts(source : Json) -> (Json, Array[Json]) raise ImportError {
  guard source is Object(fields) &&
    fields.get("base_source_bundle") is Some(base) &&
    fields.get("revisions") is Some(Array(revisions)) else {
    raise InvalidRaster(
      "Revision needs an original source bundle and revision list",
    )
  }
  // Flat history only: do not allow recursive or nested revision bundles.
  let contract = json_text(base, "contract_id")
  need(
    contract == "moonmoon.terrain-import.v1" ||
    contract == "moonmoon.terrain-xyz-import.v1" ||
    contract == "moonmoon.terrain-pds3-import.v1" ||
    contract == "moonmoon.terrain-mosaic.v1",
    "Revision base must be an original ASCII, XYZ, PDS3 or mosaic source bundle",
  )
  need(
    revisions.length() >= 1 && revisions.length() <= 32,
    "Revision history must contain 1 to 32 entries",
  )
  (base, revisions)
}

///|
fn revision_request(request : Json) -> (String, String) raise ImportError {
  guard request is Object(fields) && fields.length() == 2 else {
    raise InvalidRaster("Revision entry requires only edits_csv and reason")
  }
  let edits = json_text(request, "edits_csv")
  let reason = json_text(request, "reason")
  need(
    !reason.trim().is_empty() && reason.length() <= 2000,
    "Record the declared revision source and reason (1 to 2000 characters)",
  )
  (edits, reason)
}

///|
fn build_revision_bundle(
  original : Json,
  requests : Array[Json],
) -> Json raise ImportError {
  let base = reopen_bundle(original.stringify())
  let grid = bundle_grid(base)
  let history : Array[Json] = []
  let mut current = base
  let mut total_changes = 0
  let base_digest = digest(base.stringify())
  for request in requests {
    let (edits, reason) = revision_request(request)
    let (changed, changes_csv) = apply_revision_edits(grid, edits)
    total_changes += changed
    need(
      total_changes <= 4096,
      "Revision history supports at most 4096 changed cells",
    )
    let parent_digest = digest(current.stringify())
    // Rebuild request key order for stable identities after formatted JSON reopen.
    history.push({ "edits_csv": edits, "reason": reason })
    let recipe : Json = {
      "contract_id": "moonmoon.terrain-revision-recipe.v1",
      "base_source_bundle_digest": base_digest,
      "revisions": history.copy(),
    }
    current = grid_bundle(
      grid,
      recipe.stringify(),
      json_text(base, "tile_id"),
      json_text(base, "coordinate_frame"),
      json_text(base, "horizontal_unit"),
      json_text(base, "source_note"),
    )
    guard current is Object(fields) else {
      raise InvalidRaster("Invalid internal terrain revision")
    }
    fields["contract_id"] = "moonmoon.terrain-revision.v1".to_json()
    fields["format"] = "declared-cell-revisions".to_json()
    fields["nodata_value"] = Json::null()
    fields["nodata_declared"] = false.to_json()
    fields["base_source_bundle"] = base
    fields["base_source_bundle_digest"] = base_digest.to_json()
    fields["parent_bundle_digest"] = parent_digest.to_json()
    fields["revisions"] = history.copy().to_json()
    fields["revision_count"] = history.length().to_json()
    fields["changed_cells_in_revision"] = changed.to_json()
    fields["changed_cells_in_history"] = total_changes.to_json()
    fields["changes_csv"] = changes_csv.to_json()
    fields["changes_csv_digest"] = digest(changes_csv).to_json()
    fields["limitations"] = [
      "Original inputs and caller-declared revisions are retained; no measurement or terrain truth is authenticated.",
      "A numeric revision is a caller-declared value in metres, not a validated observation. Unknown cells remain absent from terrain CSV.",
      "Source frame, extent, cell geometry and units are unchanged. No reprojection, interpolation or vertical conversion is performed.",
      "Each CSV checks expected previous values. Revision reasons are user declarations, not independent review or approval.",
      "No mission acceptance, robot suitability or physical authority.",
    ].to_json()
  }
  need(
    current.stringify(indent=2).length() + 1 <= 4194304,
    "Revised terrain bundle exceeds 4 MiB character limit",
  )
  current
}

///|
fn reopen_revision(source : Json) -> Json raise ImportError {
  let (base, requests) = revision_parts(source)
  build_revision_bundle(base, requests)
}

///|
// Source has already passed complete replay in reopen_bundle.
fn revision_grid(source : Json) -> AsciiGrid raise ImportError {
  let (base, requests) = revision_parts(source)
  let grid = bundle_grid(base)
  for request in requests {
    let (edits, _) = revision_request(request)
    apply_revision_edits(grid, edits) |> ignore
  }
  grid
}

///|
/// Export a full editable cell sheet with exact current-value preconditions.
/// Set elevation_m to a finite metre value or the literal unknown. Rows may be
/// removed for a sparse edit. Unchanged rows are allowed when another row changes.
pub fn revision_template(source_bundle : String) -> String raise ImportError {
  let grid = bundle_grid(reopen_bundle(source_bundle))
  let lines = ["row,col,expected_elevation_m,elevation_m"]
  for i, value in grid.values {
    let text = revision_cell(value)
    lines.push("\{i / grid.cols},\{i % grid.cols},\{text},\{text}")
  }
  lines.join("\n") + "\n"
}

///|
/// Apply caller-declared values or unknown masks to a verified ASCII, XYZ, mosaic
/// or revised source. Preserve the original bundle and flat edit history, including
/// exact raw CSVs, reasons and previous-value preconditions. No data truth claim.
pub fn revise_bundle(
  source_bundle : String,
  edits_csv : String,
  reason : String,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  let (base, history) = if json_text(source, "contract_id") ==
    "moonmoon.terrain-revision.v1" {
    revision_parts(source)
  } else {
    (source, [])
  }
  need(history.length() < 32, "Revision history supports at most 32 revisions")
  let requests = history.copy()
  requests.push({ "edits_csv": edits_csv, "reason": reason })
  build_revision_bundle(base, requests)
}
