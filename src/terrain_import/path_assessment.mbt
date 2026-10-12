///|
fn assessment_cells(
  text : String,
  grid : AsciiGrid,
) -> Array[Int] raise ImportError {
  need(text.length() <= 65536, "Path input exceeds 65536 characters")
  let cells : Array[Int] = []
  let mut header_seen = false
  for line_index, raw in text.split("\n").collect() {
    let line = raw.trim()
    if line.is_empty() {
      continue
    }
    if line == "row,col" && cells.is_empty() && !header_seen {
      header_seen = true
      continue
    }
    let parts = line.split(",").collect()
    need(parts.length() == 2, "Path line \{line_index + 1}: expected row,col")
    let row = @string.parse_int(parts[0].trim()) catch {
      _ =>
        raise InvalidRaster(
          "Path line \{line_index + 1}: row must be an integer",
        )
    }
    let col = @string.parse_int(parts[1].trim()) catch {
      _ =>
        raise InvalidRaster(
          "Path line \{line_index + 1}: column must be an integer",
        )
    }
    need(
      row >= 0 && row < grid.rows && col >= 0 && col < grid.cols,
      "Path line \{line_index + 1}: cell is outside the source grid",
    )
    if !cells.is_empty() {
      let prior = cells[cells.length() - 1]
      let separation = (row - prior / grid.cols).abs() +
        (col - prior % grid.cols).abs()
      need(
        separation <= 1,
        "Path line \{line_index + 1}: each step must stay at the same cell or move to one cardinal neighbor; no skipped cells or diagonals",
      )
    }
    cells.push(row * grid.cols + col)
    need(
      cells.length() <= 4096,
      "Path assessment supports at most 4096 ordered cells",
    )
  }
  need(!cells.is_empty(), "Path assessment requires at least one cell")
  cells
}

///|
/// Assess the exact submitted cell path without optimizing or filling gaps.
/// Input is row,col lines with an optional header, including existing route
/// path-cells.txt exports. Repeated cells remain explicit stationary steps.
/// Unknown elevations yield unknown incident segments and null whole-path totals.
pub fn assess_path_bundle(
  source_bundle : String,
  path_cells_text : String,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  let grid = route_grid(source, max_grade_deg, uphill_weight)
  let cells = assessment_cells(path_cells_text, grid)
  let points : Array[Json] = []
  let lines = [
    "step,row,col,x_m,y_m,elevation_m,path_distance_m,segment_horizontal_distance_m,rise_m,grade_deg,segment_3d_distance_m,segment_status",
  ]
  let normalized : Array[String] = []
  let mut distance = 0.0
  let mut observed_distance = 0.0
  let mut surface_distance = 0.0
  let mut ascent = 0.0
  let mut descent = 0.0
  let mut peak_grade = 0.0
  let mut unknown_points = 0
  let mut unknown_segments = 0
  let mut known_segments = 0
  let mut stationary_segments = 0
  let mut exceeded_segments = 0
  for step, index in cells {
    let row = index / grid.cols
    let col = index % grid.cols
    let (x, y) = grid.cell_center(row, col)
    let z = grid.values[index]
    if z is None {
      unknown_points += 1
    }
    let mut horizontal : Double? = None
    let mut rise : Double? = None
    let mut grade : Double? = None
    let mut surface : Double? = None
    let mut segment_status = "start"
    if step > 0 {
      let previous = cells[step - 1]
      let stationary = previous == index
      let span = if stationary { 0.0 } else { grid.cell_size }
      horizontal = Some(span)
      distance += span
      if stationary {
        stationary_segments += 1
      }
      match (grid.values[previous], z) {
        (Some(before), Some(after)) => {
          known_segments += 1
          let dz = after - before
          let gradient = if stationary { 0.0 } else { dz / span }
          need(
            finite(dz) && finite(gradient),
            "Path elevation difference or grade overflows; rescale the source",
          )
          let angle = @math.atan(gradient) * 180.0 / @math.PI
          let length = @math.hypot(span, dz)
          rise = Some(dz)
          // A stationary point has no direction, so no grade is fabricated.
          grade = if stationary { None } else { Some(angle) }
          surface = Some(length)
          observed_distance += span
          surface_distance += length
          ascent += dz.max(0.0)
          descent += (-dz).max(0.0)
          peak_grade = peak_grade.max(angle.abs())
          segment_status = if stationary {
            "stationary"
          } else if angle.abs() > max_grade_deg {
            exceeded_segments += 1
            "grade-exceeded"
          } else {
            "within-grade-cap"
          }
        }
        _ => {
          unknown_segments += 1
          segment_status = "unknown-elevation"
        }
      }
    }
    let cost = observed_distance + uphill_weight * ascent
    need(
      finite(distance) &&
      finite(observed_distance) &&
      finite(surface_distance) &&
      finite(ascent) &&
      finite(descent) &&
      finite(cost),
      "Path totals overflow; rescale the source or cost",
    )
    points.push({
      "step": step,
      "row": row,
      "col": col,
      "x_m": x,
      "y_m": y,
      "elevation_m": nullable(z),
      "path_distance_m": distance,
      "segment_horizontal_distance_m": nullable(horizontal),
      "rise_m": nullable(rise),
      "grade_deg": nullable(grade),
      "segment_3d_distance_m": nullable(surface),
      "segment_status": segment_status,
    })
    lines.push(
      "\{step},\{row},\{col},\{x},\{y},\{csv_number(z)},\{distance},\{csv_number(horizontal)},\{csv_number(rise)},\{csv_number(grade)},\{csv_number(surface)},\{segment_status}",
    )
    normalized.push("\{row},\{col}")
  }
  let complete = unknown_points == 0
  let screening = if exceeded_segments > 0 {
    "exceeded"
  } else if !complete {
    "unknown"
  } else {
    "within-threshold"
  }
  let status = if !complete {
    "incomplete-coverage"
  } else if exceeded_segments > 0 {
    "grade-exceeded"
  } else {
    "within-grade-cap"
  }
  let measured : Json = {
    "horizontal_distance_m": observed_distance,
    "piecewise_3d_distance_m": surface_distance,
    "ascent_m": ascent,
    "descent_m": descent,
    "max_absolute_grade_deg": if observed_distance > 0.0 {
      peak_grade.to_json()
    } else {
      Json::null()
    },
    "objective_cost_m": observed_distance + uphill_weight * ascent,
  }
  let csv = lines.join("\n") + "\n"
  let normalized_text = normalized.join("\n") + "\n"
  let report = [
      "# Exact imported-terrain path assessment: \{status}",
      "This is the submitted path, in its original order. No path search, optimization, skipped-cell filling or rerouting was performed.",
      "Source: " +
      json_text(source, "source_digest") +
      ". Declared frame: " +
      json_text(source, "coordinate_frame") +
      ". Horizontal and elevation units are declared metres.",
      "## Coverage and screening",
      "\{cells.length()} submitted points; \{unknown_points} unknown point occurrences. \{known_segments} known segments and \{unknown_segments} unknown segments. \{stationary_segments} stationary steps are retained. Geometric path length is \{distance} m; it includes unknown segments and is not a traversability claim.",
      "Grade screening: \{screening}; \{exceeded_segments} known segments exceed the absolute \{max_grade_deg} degree cap. Unknown incident segments remain unknown even when later segments have data.",
      if complete {
        "Whole-path totals are available, including any over-cap segments. They do not mean the path meets the chosen grade cap."
      } else {
        "INCOMPLETE COVERAGE: whole-path summary is null. Observed-segment totals sum only known pairs, possibly separated by gaps; they are not a connected prefix or complete route."
      },
      "Observed segments: \{observed_distance} m horizontal distance, \{surface_distance} m piecewise 3D distance, \{ascent} m ascent and \{descent} m descent.",
      "## Method and files",
      "Cardinal adjacent cell centers only; repetitions are zero-length stationary steps with null grade. Each nonstationary signed grade is atan(rise / cell spacing) in degrees. Equality meets the cap. Cost = observed horizontal distance + \{uphill_weight} times observed positive rise; this is metre-equivalent preference, not energy. Reversing the path changes ascent cost. Finite arithmetic overflow is rejected.",
      "path-assessment.csv retains every point and incident segment outcome. input-path.txt retains the exact submitted text; path-cells.txt normalizes its row,col pairs for reuse. terrain-path-assessment.json binds all outputs, parameters and the fully reopened source. Reassess the same path on a revised source into a new directory to compare the changed evidence.",
      "## Limits",
      "Exploratory digital point path only. Source, frame, units and uncertainty remain declarations, not validated terrain. No diagonal or skipped-cell interpolation, surface slope, subcell hazard, clearance, footprint, roughness, illumination, energy, robot suitability, mission acceptance or physical readiness. Stationary samples do not model dwell duration or energy. Existing mission inputs and blockers remain unchanged.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-path-assessment.v1",
    "method": "submitted-four-neighbor-center-path-v1",
    "source_bundle": source,
    "source_bundle_digest": digest(source.stringify()),
    "parameters": {
      "max_grade_deg": max_grade_deg,
      "uphill_weight": uphill_weight,
    },
    "status": status,
    "coverage_complete": complete,
    "grade_screening": screening,
    "coverage": {
      "point_count": cells.length(),
      "unknown_point_count": unknown_points,
      "known_segment_count": known_segments,
      "unknown_segment_count": unknown_segments,
      "stationary_segment_count": stationary_segments,
      "grade_exceeded_segment_count": exceeded_segments,
      "geometric_path_distance_m": distance,
    },
    "summary": if complete {
      measured
    } else {
      Json::null()
    },
    "observed_segments_summary": measured,
    "path": points,
    "input_path_text": path_cells_text,
    "input_path_digest": digest(path_cells_text),
    "path_cells_text": normalized_text,
    "path_cells_digest": digest(normalized_text),
    "path_csv": csv,
    "path_csv_digest": digest(csv),
    "report_markdown": report,
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid path assessment")
  }
  fields["assessment_digest"] = identity.to_json()
  result
}
