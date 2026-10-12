///|
priv struct CorridorStats {
  cells : Int
  unknown_elevations : Int
  unknown_shapes : Int
  slope_exceeded : Int
  roughness_exceeded : Int
  max_slope : Double?
  max_roughness : Double?
}

///|
fn corridor_stats(
  grid : AsciiGrid,
  indices : Array[Int],
  estimates : Array[CellEstimate?],
  roughness_limit : Double,
) -> CorridorStats {
  let mut unknown_elevations = 0
  let mut unknown_shapes = 0
  let mut slope_exceeded = 0
  let mut roughness_exceeded = 0
  let mut max_slope : Double? = None
  let mut max_roughness : Double? = None
  for index in indices {
    if grid.values[index] is None {
      unknown_elevations += 1
    }
    match estimates[index] {
      Some({ slope: Some(slope), roughness: Some(roughness), screening, .. }) => {
        max_slope = Some(max_slope.map(v => v.max(slope)).unwrap_or(slope))
        max_roughness = Some(
          max_roughness.map(v => v.max(roughness)).unwrap_or(roughness),
        )
        if screening == "threshold-exceeded" {
          slope_exceeded += 1
        }
        if roughness > roughness_limit {
          roughness_exceeded += 1
        }
      }
      _ => unknown_shapes += 1
    }
  }
  {
    cells: indices.length(),
    unknown_elevations,
    unknown_shapes,
    slope_exceeded,
    roughness_exceeded,
    max_slope,
    max_roughness,
  }
}

///|
fn CorridorStats::status(self : CorridorStats, outside : Int) -> String {
  if self.slope_exceeded > 0 || self.roughness_exceeded > 0 {
    "threshold-exceeded"
  } else if self.unknown_shapes > 0 || outside > 0 {
    "incomplete-coverage"
  } else {
    "within-thresholds"
  }
}

///|
fn CorridorStats::json(self : CorridorStats, outside : Int) -> Json {
  {
    "in_grid_cell_count": self.cells,
    "outside_grid_cell_count": outside,
    "unknown_elevation_count": self.unknown_elevations,
    "unknown_shape_count": self.unknown_shapes,
    "estimated_shape_count": self.cells - self.unknown_shapes,
    "slope_exceeded_count": self.slope_exceeded,
    "roughness_exceeded_count": self.roughness_exceeded,
    "max_observed_slope_deg": nullable(self.max_slope),
    "max_observed_roughness_rms_m": nullable(self.max_roughness),
    "elevation_coverage_complete": outside == 0 && self.unknown_elevations == 0,
    "shape_coverage_complete": outside == 0 && self.unknown_shapes == 0,
    "status": self.status(outside),
  }
}

///|
/// Screen the union of square cell neighborhoods around an exact submitted path.
/// Radius is a discrete Chebyshev distance in cells, not a rover footprint.
/// Missing outside cells and incomplete 3x3 shape estimates remain explicit.
pub fn assess_corridor_bundle(
  source_bundle : String,
  path_cells_text : String,
  radius_cells : Int,
  slope_limit_deg : Double,
  roughness_limit_m : Double,
) -> Json raise ImportError {
  need(
    radius_cells >= 0 && radius_cells <= 8,
    "Corridor radius must be an integer from 0 to 8 cells",
  )
  need(
    finite(slope_limit_deg) && slope_limit_deg >= 0.0 && slope_limit_deg < 90.0,
    "Corridor slope limit must be finite, at least 0 and less than 90 degrees",
  )
  need(
    finite(roughness_limit_m) && roughness_limit_m >= 0.0,
    "Corridor roughness limit must be finite and nonnegative",
  )
  let source = reopen_bundle(source_bundle)
  need(
    json_text(source, "horizontal_unit") == "m",
    "Corridor screening requires declared metre cells",
  )
  let grid = bundle_grid(source)
  let half_width = radius_cells.to_double() * grid.cell_size
  need(finite(half_width), "Corridor cell-center half width overflows")
  let path = assessment_cells(path_cells_text, grid)
  let selected = Array::make(grid.values.length(), false)
  let on_path = Array::make(grid.values.length(), false)
  let estimates : Array[CellEstimate?] = Array::make(grid.values.length(), None)
  let outside_cells : Map[String, Bool] = Map([])
  let stops : Array[Json] = []
  let stop_lines = [
    "step,row,col,in_grid_cell_count,outside_grid_cell_count,unknown_elevation_count,unknown_shape_count,slope_exceeded_count,roughness_exceeded_count,max_observed_slope_deg,max_observed_roughness_rms_m,status",
  ]
  for step, index in path {
    on_path[index] = true
    let row = index / grid.cols
    let col = index % grid.cols
    let window : Array[Int] = []
    let mut outside = 0
    for dr in -radius_cells..<(radius_cells + 1) {
      for dc in -radius_cells..<(radius_cells + 1) {
        let r = row + dr
        let c = col + dc
        if r < 0 || r >= grid.rows || c < 0 || c >= grid.cols {
          outside += 1
          outside_cells["\{r},\{c}"] = true
        } else {
          let cell = r * grid.cols + c
          window.push(cell)
          selected[cell] = true
          if estimates[cell] is None {
            estimates[cell] = Some(estimate_cell(grid, r, c, slope_limit_deg))
          }
        }
      }
    }
    let stats = corridor_stats(grid, window, estimates, roughness_limit_m)
    stops.push({
      "step": step,
      "row": row,
      "col": col,
      "summary": stats.json(outside),
    })
    let status = stats.status(outside)
    stop_lines.push(
      "\{step},\{row},\{col},\{stats.cells},\{outside},\{stats.unknown_elevations},\{stats.unknown_shapes},\{stats.slope_exceeded},\{stats.roughness_exceeded},\{csv_number(stats.max_slope)},\{csv_number(stats.max_roughness)},\{status}",
    )
  }
  let indices : Array[Int] = []
  let cells : Array[Json] = []
  let cell_lines = [
    "row,col,x_m,y_m,on_path,elevation_m,estimate_status,slope_deg,roughness_rms_m,slope_screening,roughness_screening",
  ]
  for index, included in selected {
    if !included {
      continue
    }
    indices.push(index)
    let row = index / grid.cols
    let col = index % grid.cols
    let (x, y) = grid.cell_center(row, col)
    guard estimates[index] is Some(estimate) else {
      raise InvalidRaster("Missing corridor estimate")
    }
    let roughness_screening = match estimate.roughness {
      None => "unknown"
      Some(v) =>
        if v > roughness_limit_m {
          "threshold-exceeded"
        } else {
          "within-threshold"
        }
    }
    cells.push({
      "row": row,
      "col": col,
      "x_m": x,
      "y_m": y,
      "on_path": on_path[index],
      "elevation_m": nullable(grid.values[index]),
      "estimate_status": estimate.status,
      "slope_deg": nullable(estimate.slope),
      "roughness_rms_m": nullable(estimate.roughness),
      "slope_screening": estimate.screening,
      "roughness_screening": roughness_screening,
    })
    cell_lines.push(
      "\{row},\{col},\{x},\{y},\{on_path[index]},\{csv_number(grid.values[index])},\{estimate.status},\{csv_number(estimate.slope)},\{csv_number(estimate.roughness)},\{estimate.screening},\{roughness_screening}",
    )
  }
  let stats = corridor_stats(grid, indices, estimates, roughness_limit_m)
  let outside = outside_cells.length()
  let status = stats.status(outside)
  let cells_csv = cell_lines.join("\n") + "\n"
  let stops_csv = stop_lines.join("\n") + "\n"
  let normalized = path
    .map(index => "\{index / grid.cols},\{index % grid.cols}")
    .join("\n") +
    "\n"
  let svg = corridor_svg(
    grid, path, selected, estimates, roughness_limit_m, outside,
  )
  let report = [
      "# Imported-terrain corridor screening: \{status}",
      "Source: " +
      json_text(source, "source_digest") +
      ". Declared frame: " +
      json_text(source, "coordinate_frame") +
      ". All horizontal and elevation units are declared metres.",
      "## Selection and coverage",
      "\{path.length()} ordered path occurrences; radius \{radius_cells} cells (\{half_width} m from each center along either grid axis). The corridor is the union of square cell-center windows, including end stops. Repeated and overlapping windows count once in the global summary; corridor-stops.csv retains each occurrence separately.",
      "\{stats.cells} distinct in-grid cells and \{outside} distinct outside-grid cells. \{stats.unknown_elevations} in-grid cells lack elevation; \{stats.unknown_shapes} lack a complete 3x3 shape estimate. Missing coverage is not removed from the requested corridor. The map shows the clipped grid only; outside-grid counts must be read alongside it.",
      "## Shape screening",
      "\{stats.slope_exceeded} cells exceed \{slope_limit_deg} degrees local slope; \{stats.roughness_exceeded} cells exceed \{roughness_limit_m} m local RMS roughness. These sets may overlap. Maxima cover estimated cells only and are not full-corridor bounds when coverage is incomplete. Known exceedances remain visible even with unknown coverage.",
      "Each estimate fits the existing unweighted plane to all nine cells in its centered 3x3 neighborhood, including source cells outside the selected corridor. Slope is atan(gradient magnitude); roughness is RMS vertical residual. Outer grid edges and incomplete neighborhoods have null estimates. Equality meets each threshold. No interpolation or edge padding.",
      "## Outputs and limits",
      "corridor-cells.csv is the row-major deduplicated corridor; corridor-stops.csv locates affected ordered path occurrences; corridor.svg maps threshold and unknown-shape cells with the submitted centerline. terrain-corridor.json retains the verified source, exact input, normalized reusable path, both CSVs and map digests.",
      "Exploratory digital raster screening only. The square sample band is not a swept robot footprint or clearance test. Local slope differs from along-path segment grade. No subcell obstacles, vehicle geometry, traction, uncertainty propagation, energy, mission acceptance or physical readiness. Source declarations are unverified. Existing mission inputs and negative-energy blockers remain unchanged.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-corridor.v1",
    "method": "square-cell-union-3x3-plane-screen-v1",
    "source_bundle": source,
    "source_bundle_digest": digest(source.stringify()),
    "parameters": {
      "radius_cells": radius_cells,
      "cell_center_half_width_m": half_width,
      "slope_limit_deg": slope_limit_deg,
      "roughness_limit_m": roughness_limit_m,
    },
    "status": status,
    "summary": stats.json(outside),
    "cells": cells,
    "stops": stops,
    "input_path_text": path_cells_text,
    "input_path_digest": digest(path_cells_text),
    "path_cells_text": normalized,
    "path_cells_digest": digest(normalized),
    "cells_csv": cells_csv,
    "cells_csv_digest": digest(cells_csv),
    "stops_csv": stops_csv,
    "stops_csv_digest": digest(stops_csv),
    "corridor_svg": svg,
    "corridor_svg_digest": digest(svg),
    "report_markdown": report,
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid corridor output")
  }
  fields["corridor_digest"] = identity.to_json()
  result
}
