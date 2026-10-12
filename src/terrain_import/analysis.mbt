///|
priv struct CellEstimate {
  status : String
  slope : Double?
  roughness : Double?
  screening : String
}

///|
fn nullable(value : Double?) -> Json {
  match value {
    Some(number) => number.to_json()
    None => Json::null()
  }
}

///|
fn csv_number(value : Double?) -> String {
  value.map(number => number.to_string()).unwrap_or("")
}

///|
fn digest(text : String) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(text)))
}

///|
fn json_text(value : Json, name : String) -> String raise ImportError {
  guard value is Object(fields) && fields.get(name) is Some(String(text)) else {
    raise InvalidRaster("Missing text field " + name)
  }
  text
}

///|
fn estimate_cell(
  grid : AsciiGrid,
  row : Int,
  col : Int,
  threshold : Double,
) -> CellEstimate raise ImportError {
  fn unknown(status : String) -> CellEstimate {
    { status, slope: None, roughness: None, screening: "unknown", }
  }
  guard grid.values[row * grid.cols + col] is Some(center) else {
    return unknown("nodata")
  }
  if row == 0 || col == 0 || row == grid.rows - 1 || col == grid.cols - 1 {
    return unknown("boundary")
  }
  let offsets : Array[Double] = []
  let mut mean = 0.0
  let mut east = 0.0
  let mut north = 0.0
  for dr in -1..<2 {
    for dc in -1..<2 {
      guard grid.values[(row + dr) * grid.cols + col + dc] is Some(z) else {
        return unknown("unknown-neighborhood")
      }
      let delta = z - center
      need(
        finite(delta),
        "Elevation differences overflow; rescale the source before analysis",
      )
      offsets.push(delta)
      mean += delta / 9.0
      east += delta * dc.to_double() / 6.0
      north -= delta * dr.to_double() / 6.0
    }
  }
  let mut residual_norm = 0.0
  for index, delta in offsets {
    let dr = index / 3 - 1
    let dc = index % 3 - 1
    let residual = delta - mean - east * dc.to_double() + north * dr.to_double()
    residual_norm = @math.hypot(residual_norm, residual)
  }
  let gradient = @math.hypot(east / grid.cell_size, north / grid.cell_size)
  let roughness = residual_norm / 3.0
  need(
    finite(gradient) && finite(roughness),
    "Terrain calculation overflows; rescale the source before analysis",
  )
  let slope = @math.atan(gradient) * 180.0 / @math.PI
  {
    status: "estimated",
    slope: Some(slope),
    roughness: Some(roughness),
    screening: if slope > threshold {
      "threshold-exceeded"
    } else {
      "within-threshold"
    },
  }
}

///|
/// Estimate local terrain shape and one complete row/column profile from a
/// verified source bundle. Metre coordinates are required. All nine cells must
/// be present for the local least-squares plane; no extrapolation or gap filling.
pub fn analyze_bundle(
  source_bundle : String,
  axis : String,
  index : Int,
  slope_threshold_deg : Double,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  need(
    json_text(source, "horizontal_unit") == "m",
    "Metric terrain analysis requires declared metre cells; reproject degree grids separately",
  )
  need(axis == "row" || axis == "column", "Transect axis must be row or column")
  need(
    finite(slope_threshold_deg) &&
    slope_threshold_deg >= 0.0 &&
    slope_threshold_deg < 90.0,
    "Slope screening threshold must be finite and at least 0 but less than 90 degrees",
  )
  let grid = bundle_grid(source)
  need(
    index >= 0 && index < (if axis == "row" { grid.rows } else { grid.cols }),
    "Transect index outside imported raster",
  )
  let cells : Array[Json] = []
  let cell_lines = [
    "row,col,x_m,y_m,elevation_m,estimate_status,slope_deg,roughness_rms_m,slope_screening",
  ]
  let mut estimated = 0
  let mut exceeded = 0
  for i, elevation in grid.values {
    let row = i / grid.cols
    let col = i % grid.cols
    let (x, y) = grid.cell_center(row, col)
    let estimate = estimate_cell(grid, row, col, slope_threshold_deg)
    if estimate.status == "estimated" {
      estimated += 1
    }
    if estimate.screening == "threshold-exceeded" {
      exceeded += 1
    }
    cells.push({
      "row": row,
      "col": col,
      "x_m": x,
      "y_m": y,
      "elevation_m": nullable(elevation),
      "estimate_status": estimate.status,
      "slope_deg": nullable(estimate.slope),
      "roughness_rms_m": nullable(estimate.roughness),
      "slope_screening": estimate.screening,
    })
    cell_lines.push(
      "\{row},\{col},\{x},\{y},\{csv_number(elevation)},\{estimate.status},\{csv_number(estimate.slope)},\{csv_number(estimate.roughness)},\{estimate.screening}",
    )
  }
  let points : Array[Json] = []
  let profile_lines = [
    "sample,row,col,distance_m,x_m,y_m,elevation_m,segment_status,rise_m,grade_percent,grade_deg",
  ]
  let count = if axis == "row" { grid.cols } else { grid.rows }
  let mut previous : Double? = None
  let mut ascent = 0.0
  let mut descent = 0.0
  let mut known_segments = 0
  let mut valid_samples = 0
  for step in 0..<count {
    let row = if axis == "row" { index } else { step }
    let col = if axis == "row" { step } else { index }
    let elevation = grid.values[row * grid.cols + col]
    let (x, y) = grid.cell_center(row, col)
    let distance = step.to_double() * grid.cell_size
    need(finite(distance), "Transect distance overflows")
    let mut rise : Double? = None
    let mut grade_percent : Double? = None
    let mut grade_deg : Double? = None
    let mut segment_status = if step == 0 { "start" } else { "unknown" }
    if elevation is Some(_) {
      valid_samples += 1
    }
    if step > 0 && previous is Some(a) && elevation is Some(b) {
      let delta = b - a
      let grade = delta / grid.cell_size
      need(
        finite(delta) && finite(grade * 100.0),
        "Profile grade overflows; rescale the source before analysis",
      )
      rise = Some(delta)
      grade_percent = Some(grade * 100.0)
      grade_deg = Some(@math.atan(grade) * 180.0 / @math.PI)
      segment_status = "measured"
      known_segments += 1
      if delta > 0.0 {
        ascent += delta
      } else {
        descent -= delta
      }
    }
    previous = elevation
    points.push({
      "sample": step,
      "row": row,
      "col": col,
      "distance_m": distance,
      "x_m": x,
      "y_m": y,
      "elevation_m": nullable(elevation),
      "segment_status": segment_status,
      "rise_m": nullable(rise),
      "grade_percent": nullable(grade_percent),
      "grade_deg": nullable(grade_deg),
    })
    profile_lines.push(
      "\{step},\{row},\{col},\{distance},\{x},\{y},\{csv_number(elevation)},\{segment_status},\{csv_number(rise)},\{csv_number(grade_percent)},\{csv_number(grade_deg)}",
    )
  }
  need(finite(ascent) && finite(descent), "Accumulated profile rise overflows")
  let cells_csv = cell_lines.join("\n") + "\n"
  let profile_csv = profile_lines.join("\n") + "\n"
  let unknown_segments = count - 1 - known_segments
  let span = (count - 1).to_double() * grid.cell_size
  let known_distance = known_segments.to_double() * grid.cell_size
  let summary : Json = {
    "estimated_cells": estimated,
    "unknown_cells": grid.values.length() - estimated,
    "threshold_exceeded_cells": exceeded,
    "within_threshold_cells": estimated - exceeded,
  }
  let profile_summary : Json = {
    "sample_count": count,
    "known_samples": valid_samples,
    "unknown_samples": count - valid_samples,
    "horizontal_span_m": span,
    "measured_segment_distance_m": known_distance,
    "known_segments": known_segments,
    "unknown_segments": unknown_segments,
    "observed_ascent_m": ascent,
    "observed_descent_m": descent,
    "complete_elevation_coverage": valid_samples == count,
  }
  let tile = json_text(source, "tile_id")
  let frame = json_text(source, "coordinate_frame")
  let source_digest = json_text(source, "source_digest")
  let report = [
      "# Local terrain analysis: \{tile}",
      "Source: \{source_digest}",
      "Declared frame: \{frame}",
      "Cells: \{grid.rows} rows by \{grid.cols} columns; \{grid.cell_size} m spacing. Elevations are declared metres.",
      "## Slope and roughness screening",
      "\{estimated} cells have a complete 3x3 neighborhood; \{grid.values.length() - estimated} cells are unknown for this estimator. \{exceeded} cells exceed the user screening threshold of \{slope_threshold_deg} degrees. Unknown and below-threshold cells are not a safety finding.",
      "Method: unweighted least-squares plane through nine cell-center elevations. Slope is atan of the plane gradient magnitude. Roughness is the RMS vertical residual from that plane in metres. Boundary and NODATA neighborhoods have no estimate.",
      "## \{axis} \{index} transect",
      "\{valid_samples}/\{count} known elevations; \{span} m horizontal span; \{known_distance} m of adjacent segments measured; \{unknown_segments} segments unknown. Observed ascent \{ascent} m and descent \{descent} m include only consecutive known samples and are partial when coverage is incomplete. Rows run toward increasing source x; columns run top-to-bottom (decreasing source y). No geographical orientation is inferred.",
      "## Limits",
      "Synthetic or user-declared input is not authenticated terrain. No reprojection, interpolation, uncertainty propagation, route energy, robot suitability, mission acceptance or physical readiness. The 3x3 estimator can smooth small hazards; this threshold is an exploratory screening choice, not a rover limit or hazard certification. Keep the source bundle and CSV beside this report.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-analysis.v1",
    "method": "unweighted-3x3-plane-rms-v1",
    "source_bundle": source,
    "source_bundle_digest": digest(source.stringify()),
    "parameters": {
      "axis": axis,
      "index": index,
      "slope_threshold_deg": slope_threshold_deg,
    },
    "grid_summary": summary,
    "profile_summary": profile_summary,
    "cells": cells,
    "profile": points,
    "cells_csv": cells_csv,
    "cells_csv_digest": digest(cells_csv),
    "profile_csv": profile_csv,
    "profile_csv_digest": digest(profile_csv),
    "report_markdown": report,
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid internal report")
  }
  fields["analysis_digest"] = identity.to_json()
  result
}

///|
/// Browser boundary uses the same metric calculations as the native command.
pub fn analysis_json(
  source_bundle : String,
  axis : String,
  index : Int,
  slope_threshold_deg : Double,
) -> String {
  try {
    let analysis = analyze_bundle(
      source_bundle, axis, index, slope_threshold_deg,
    )
    ({ "ok": true, "analysis": analysis } : Json).stringify()
  } catch {
    InvalidRaster(message) =>
      ({ "ok": false, "error": message } : Json).stringify()
  }
}
