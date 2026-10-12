///|
// Pick a finite integer marker absent from known samples. At most 4096 known
// values can occupy consecutive candidates, so this search is bounded.
fn crop_nodata(values : Array[Double?]) -> Double {
  let mut marker = -9999.0
  while values.contains(Some(marker)) {
    marker -= 1.0
  }
  marker
}

///|
/// Extract an exact rectangular study window, preserving the complete verified
/// parent in a replayable receipt. The emitted ordinary ASCII import works with
/// existing analysis, routing, editing and export commands. No resampling.
pub fn crop_bundle(
  source_bundle : String,
  start_row : Int,
  start_col : Int,
  rows : Int,
  cols : Int,
  tile_id : String,
  reason : String,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  let grid = bundle_grid(source)
  need(
    start_row >= 0 &&
    start_row < grid.rows &&
    start_col >= 0 &&
    start_col < grid.cols,
    "Crop start row and column must be inside the source grid",
  )
  need(
    rows > 0 &&
    rows <= grid.rows - start_row &&
    cols > 0 &&
    cols <= grid.cols - start_col,
    "Crop rows and columns must describe a nonempty window inside the source grid",
  )
  need(
    !reason.trim().is_empty() && reason.length() <= 1500,
    "Record the crop purpose and limitations (1 to 1500 characters)",
  )
  let selected : Array[Double?] = []
  for row in 0..<rows {
    for col in 0..<cols {
      selected.push(
        grid.values[(start_row + row) * grid.cols + start_col + col],
      )
    }
  }
  let marker = crop_nodata(selected)
  let (origin_x, origin_y) = grid.cell_center(start_row + rows - 1, start_col)
  let lines = [
    "ncols \{cols}",
    "nrows \{rows}",
    "xllcenter \{origin_x}",
    "yllcenter \{origin_y}",
    "cellsize \{grid.cell_size}",
    "NODATA_value \{marker}",
  ]
  for row in 0..<rows {
    let samples : Array[String] = []
    for col in 0..<cols {
      samples.push(selected[row * cols + col].unwrap_or(marker).to_string())
    }
    lines.push(samples.join(" "))
  }
  let ascii = lines.join("\n") + "\n"
  let cropped = parse_ascii_grid(ascii)
  let mapping = ["row,col,source_row,source_col,x,y,elevation_m,coverage"]
  let mut known = 0
  for row in 0..<rows {
    for col in 0..<cols {
      let source_row = start_row + row
      let source_col = start_col + col
      let (x, y) = grid.cell_center(source_row, source_col)
      let (cx, cy) = cropped.cell_center(row, col)
      need(
        finite(x) && finite(y) && x == cx && y == cy,
        "Crop coordinates cannot be represented exactly in an independent ASCII grid; no snapping is performed",
      )
      if col > 0 {
        let (previous_x, _) = cropped.cell_center(row, col - 1)
        need(
          x > previous_x,
          "Crop X centers collapse at this origin and spacing",
        )
      }
      if row > 0 {
        let (_, previous_y) = cropped.cell_center(row - 1, col)
        need(
          y < previous_y,
          "Crop Y centers collapse at this origin and spacing",
        )
      }
      let elevation = selected[row * cols + col]
      need(
        cropped.values[row * cols + col] == elevation,
        "ASCII crop did not preserve an exact source sample",
      )
      let coverage = if elevation is Some(_) {
        known += 1
        "known"
      } else {
        "unknown"
      }
      mapping.push(
        "\{row},\{col},\{source_row},\{source_col},\{x},\{y},\{csv_number(elevation)},\{coverage}",
      )
    }
  }
  let source_digest = digest(source.stringify())
  let frame = json_text(source, "coordinate_frame")
  let unit = json_text(source, "horizontal_unit")
  let terrain = import_bundle(
    ascii,
    tile_id,
    frame,
    unit,
    "Derived rectangular clip from " +
    source_digest +
    ". Original source and license notes are retained in terrain-crop.json. Purpose: " +
    reason,
  )
  let status = if known == 0 {
    "unknown-only"
  } else if known < selected.length() {
    "partial-coverage"
  } else {
    "known-samples-only"
  }
  let cells_csv = mapping.join("\n") + "\n"
  let report = [
    "# Source-bound terrain study clip",
    "",
    "Status: " + status,
    "Parent bundle: " + source_digest,
    "Declared frame (unverified): " + frame,
    "Horizontal unit: " + unit + "; elevation unit: m.",
    "Purpose (caller declaration): " + reason,
    "",
    "Window: source row \{start_row}, column \{start_col}; \{rows} rows by \{cols} columns. All indices are zero-based; row zero is the top input row.",
    "Known samples: \{known}; unknown samples: \{selected.length() - known}; excluded source cells: \{grid.values.length() - selected.length()}.",
    "The new lower-left sample center is (\{origin_x}, \{origin_y}); spacing is \{grid.cell_size} \{unit}. Coordinates and elevations are unchanged.",
    "",
    "Use terrain-import.json with existing reopen, analyze, route, revise and export commands. Row/column inputs must use the new clip indices. crop-cells.csv maps every clip cell back to its immediate parent.",
    "source.asc is an Esri ASCII exchange raster with explicit center origin and a collision-free NODATA marker. The marker \{marker} is only an encoding; unknown is never zero-filled.",
    "Keep terrain-crop.json: it retains the complete parent, original provenance and license notes, selection, derived import and output digests. Reopen it with reopen-crop to recompute the receipt.",
    "",
    "## Limits",
    "No interpolation, reprojection, vertical conversion, edge padding or automatic route remapping occurs. A whole-grid window is allowed for portable ASCII export.",
    "Cropping removes neighborhood context: slope/roughness at the new boundary may become unknown, and routes cannot traverse excluded cells. Results from the parent do not automatically apply to this clip.",
    "ASCII alone does not carry verified CRS, units or licensing. The normal import binds this immediate crop; full parent lineage is retained separately in terrain-crop.json. Retain earlier crop receipts when chaining clips.",
    "Degree grids may be clipped but still cannot use metre-only analyses without separate reprojection. A representability mismatch is rejected rather than silently moving cell centers.",
    "Known samples describe the input, not verified terrain truth or complete physical coverage. No mission acceptance, energy feasibility, robot suitability or physical readiness.",
    "",
  ].join("\n")
  let result : Json = {
    "contract_id": "moonmoon.terrain-crop.v1",
    "method": "exact-rectangular-cell-window-v1",
    "status": status,
    "source_bundle": source,
    "source_bundle_digest": source_digest,
    "window": {
      "start_row": start_row,
      "start_col": start_col,
      "rows": rows,
      "cols": cols,
    },
    "tile_id": tile_id,
    "reason": reason,
    "coordinate_frame": frame,
    "horizontal_unit": unit,
    "elevation_unit": "m",
    "known_samples": known,
    "unknown_samples": selected.length() - known,
    "excluded_cells": grid.values.length() - selected.length(),
    "ascii_grid_text": ascii,
    "ascii_grid_digest": digest(ascii),
    "terrain_bundle": terrain,
    "terrain_bundle_digest": digest(terrain.stringify()),
    "cells_csv": cells_csv,
    "cells_csv_digest": digest(cells_csv),
    "report_markdown": report,
    "report_digest": digest(report),
    "physical_readiness": false,
  }
  need(
    result.stringify(indent=2).length() + 1 <= 8388608,
    "Terrain crop receipt exceeds 8 MiB character limit",
  )
  result
}

///|
/// Recompute the crop, emitted ASCII, ordinary import and maps from the retained
/// parent and selection. Formatting may change; changed derived content fails.
pub fn reopen_crop_bundle(text : String) -> Json raise ImportError {
  need(
    text.length() <= 8388608,
    "Terrain crop receipt exceeds 8 MiB character limit",
  )
  let saved = @json.parse(text) catch {
    _ => raise InvalidRaster("Invalid terrain crop JSON")
  }
  guard saved is Object(fields) &&
    fields.get("source_bundle") is Some(source) &&
    fields.get("window") is Some(Object(window)) else {
    raise InvalidRaster("Terrain crop needs its source bundle and window")
  }
  fn index(name : String) -> Int raise ImportError {
    guard window.get(name) is Some(Number(value, ..)) else {
      raise InvalidRaster("Missing numeric crop window field " + name)
    }
    need(
      finite(value) &&
      value >= 0.0 &&
      value <= 4096.0 &&
      @math.floor(value) == value,
      "Crop window fields must be bounded nonnegative integers",
    )
    value.to_int()
  }
  let current = crop_bundle(
    source.stringify(),
    index("start_row"),
    index("start_col"),
    index("rows"),
    index("cols"),
    json_text(saved, "tile_id"),
    json_text(saved, "reason"),
  )
  need(
    saved == current,
    "Terrain crop differs from its recomputed source, selection or outputs",
  )
  current
}
