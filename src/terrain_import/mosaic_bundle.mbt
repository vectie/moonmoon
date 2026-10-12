///|
fn build_mosaic_bundle(
  left : Json,
  right : Json,
  tile_id : String,
  source_note : String,
) -> Json raise ImportError {
  mosaic_input(left)
  mosaic_input(right)
  let a = reopen_bundle(left.stringify())
  let b = reopen_bundle(right.stringify())
  need(
    json_text(a, "horizontal_unit") == "m" &&
    json_text(b, "horizontal_unit") == "m",
    "Terrain mosaics require declared metre cells; reproject degree grids separately",
  )
  let frame = json_text(a, "coordinate_frame")
  need(
    frame == json_text(b, "coordinate_frame"),
    "Mosaic coordinate frames differ; no reprojection is performed",
  )
  let merged = merge_mosaic_grids(bundle_grid(a), bundle_grid(b))
  let left_digest = digest(a.stringify())
  let right_digest = digest(b.stringify())
  let recipe : Json = {
    "contract_id": "moonmoon.terrain-mosaic-recipe.v1",
    "left_bundle_digest": left_digest,
    "right_bundle_digest": right_digest,
    "method": "exact-grid-union-known-equal-v1",
  }
  let result = grid_bundle(
    merged.grid,
    recipe.stringify(),
    tile_id,
    frame,
    "m",
    source_note,
  )
  let report = [
    "# Imported terrain mosaic",
    "",
    "Tile: \{tile_id}. Declared frame: \{frame}. Horizontal coordinates and elevations are metres.",
    "",
    "Left source bundle: \{left_digest}",
    "Right source bundle: \{right_digest}",
    "",
    "Both complete source bundles and their prior revisions are retained. The new source note is a declaration; it does not replace their provenance or licenses.",
    "",
    "## Exact-grid composition",
    "",
    "The bounding grid has \{merged.grid.rows} rows and \{merged.grid.cols} columns. Every source cell center matches exactly. No reprojection, snapping, interpolation, averaging or vertical conversion occurs.",
    "",
    "Known + unknown uses the known observation. Two equal known values agree; unequal known values reject the join. A withheld value in one source may therefore be filled by the other; revise the mosaic to withhold it globally. This policy does not authenticate either source. Missing samples and cells outside both footprints remain unknown.",
    "",
    "Coverage summary: " + merged.summary.stringify(),
    "",
    "Read mosaic-cells.csv for every output cell and each source row/column/elevation. Blank source row/column means outside that source footprint; present row/column with blank elevation means source NODATA. Blank output elevation means unknown, never zero.",
    "",
    "## Use and limits",
    "",
    "Reopen terrain-import.json with the normal terrain importer, then analyze or route across the seam using existing commands. Revisions preserve the mosaic and both underlying inputs. A changed source requires a new mosaic and result directory; previous receipts stay unchanged.",
    "",
    "The grid is limited to 4096 cells including gaps. Two original ASCII/XYZ imports or revisions of those originals are supported; nested mosaics are not. Equality is exact, including elevations. Matching frame strings and units do not verify CRS equivalence, vertical datum, source quality or authority.",
    "",
    "Digital terrain exploration only. No mission energy, robot suitability, mission acceptance or physical readiness is inferred. Existing mission blockers remain unchanged.",
    "",
  ].join("\n")
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid internal mosaic")
  }
  fields["contract_id"] = "moonmoon.terrain-mosaic.v1".to_json()
  fields["format"] = "exact-grid-mosaic".to_json()
  fields["nodata_value"] = Json::null()
  fields["source_bundles"] = [a, b].to_json()
  fields["source_bundle_digests"] = [left_digest, right_digest].to_json()
  fields["method"] = "exact-grid-union-known-equal-v1".to_json()
  fields["mosaic_summary"] = merged.summary
  fields["mosaic_cells_csv"] = merged.cells_csv.to_json()
  fields["mosaic_cells_csv_digest"] = digest(merged.cells_csv).to_json()
  fields["report_markdown"] = report.to_json()
  fields["limitations"] = [
    "Source and coordinate declarations are unverified; retain and review both sources and their licenses.",
    "Exact metre-grid composition only. No snapping, reprojection, resampling, averaging or vertical conversion.",
    "Known values fill unknown overlap; unequal known overlap is rejected. Missing coverage stays unknown.",
    "Two original ASCII/XYZ inputs or their revisions only; nested mosaics are unsupported. Maximum 4096 cells including gaps.",
    "No mission acceptance, robot suitability, energy feasibility or physical readiness.",
  ].to_json()
  need(
    result.stringify(indent=2).length() + 1 <= 4194304,
    "Mosaic bundle exceeds 4 MiB character limit",
  )
  result
}

///|
/// Join two exactly aligned metre-frame imports into one source-bound grid.
/// Preserve both complete inputs and per-cell contribution mapping. Conflicting
/// known overlaps reject; absent cells remain unknown. No resampling is performed.
pub fn mosaic_bundle(
  left_bundle : String,
  right_bundle : String,
  tile_id : String,
  source_note : String,
) -> Json raise ImportError {
  fn read(text : String) -> Json raise ImportError {
    need(text.length() <= 4194304, "Mosaic input exceeds 4 MiB character limit")
    let source = @json.parse(text) catch {
      _ => raise InvalidRaster("Invalid mosaic source JSON")
    }
    mosaic_input(source)
    source
  }
  build_mosaic_bundle(
    read(left_bundle),
    read(right_bundle),
    tile_id,
    source_note,
  )
}

///|
fn reopen_mosaic(source : Json) -> Json raise ImportError {
  let (left, right) = mosaic_sources(source)
  build_mosaic_bundle(
    left,
    right,
    json_text(source, "tile_id"),
    json_text(source, "source_note"),
  )
}
