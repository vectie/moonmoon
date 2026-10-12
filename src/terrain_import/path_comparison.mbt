///|
fn comparison_field(value : Json, key : String) -> Json raise ImportError {
  guard value is Object(fields) && fields.get(key) is Some(result) else {
    raise InvalidRaster("Missing comparison input field " + key)
  }
  result
}

///|
fn comparison_number(value : Json) -> Double? {
  match value {
    Number(n, ..) => Some(n)
    _ => None
  }
}

///|
fn comparison_delta(before : Json, after : Json) -> Json raise ImportError {
  match (before, after) {
    (Number(a, ..), Number(b, ..)) => {
      let delta = b - a
      need(finite(delta), "Comparison delta overflows; rescale the sources")
      delta.to_json()
    }
    _ => Json::null()
  }
}

///|
/// Compare an unchanged submitted path on two explicitly aligned terrain sources.
/// Deltas are candidate minus reference. Unknown data is never treated as zero.
pub fn compare_path_bundle(
  reference_bundle : String,
  candidate_bundle : String,
  path_cells_text : String,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> Json raise ImportError {
  let reference = reopen_bundle(reference_bundle)
  let candidate = reopen_bundle(candidate_bundle)
  need(
    json_text(reference, "coordinate_frame") ==
    json_text(candidate, "coordinate_frame"),
    "Cannot compare paths: coordinate frames differ; no reprojection is performed",
  )
  let a = route_grid(reference, max_grade_deg, uphill_weight)
  let b = route_grid(candidate, max_grade_deg, uphill_weight)
  need(
    a.rows == b.rows &&
    a.cols == b.cols &&
    a.cell_size == b.cell_size &&
    a.cell_center(0, 0) == b.cell_center(0, 0),
    "Cannot compare paths: grid dimensions, cell spacing or cell centers differ; no resampling is performed",
  )
  let before = assess_path_bundle(
    reference_bundle, path_cells_text, max_grade_deg, uphill_weight,
  )
  let after = assess_path_bundle(
    candidate_bundle, path_cells_text, max_grade_deg, uphill_weight,
  )
  guard comparison_field(before, "path") is Array(before_points) &&
    comparison_field(after, "path") is Array(after_points) else {
    raise InvalidRaster("Missing assessed path")
  }
  let changes : Array[Json] = []
  let lines = [
    "step,row,col,path_distance_m,reference_elevation_m,candidate_elevation_m,elevation_delta_m,coverage_change,reference_segment_status,candidate_segment_status,grade_delta_deg",
  ]
  let mut gained = 0
  let mut lost = 0
  let mut changed = 0
  let mut transitions = 0
  for step, point in before_points {
    let other = after_points[step]
    let old_z = comparison_field(point, "elevation_m")
    let new_z = comparison_field(other, "elevation_m")
    let coverage = match (old_z, new_z) {
      (Number(_, ..), Number(_, ..)) => "known-both"
      (Number(_, ..), _) => {
        lost += 1
        "coverage-lost"
      }
      (_, Number(_, ..)) => {
        gained += 1
        "coverage-gained"
      }
      _ => "unknown-both"
    }
    if old_z is Number(_, ..) && new_z is Number(_, ..) && old_z != new_z {
      changed += 1
    }
    let old_status = json_text(point, "segment_status")
    let new_status = json_text(other, "segment_status")
    if old_status != new_status {
      transitions += 1
    }
    let dz = comparison_delta(old_z, new_z)
    let dg = comparison_delta(
      comparison_field(point, "grade_deg"),
      comparison_field(other, "grade_deg"),
    )
    let row = comparison_field(point, "row")
    let col = comparison_field(point, "col")
    let distance = comparison_field(point, "path_distance_m")
    changes.push({
      "step": step,
      "row": row,
      "col": col,
      "path_distance_m": distance,
      "reference_elevation_m": old_z,
      "candidate_elevation_m": new_z,
      "elevation_delta_m": dz,
      "coverage_change": coverage,
      "reference_segment_status": old_status,
      "candidate_segment_status": new_status,
      "grade_delta_deg": dg,
    })
    let old_csv = csv_number(comparison_number(old_z))
    let new_csv = csv_number(comparison_number(new_z))
    let dz_csv = csv_number(comparison_number(dz))
    let dg_csv = csv_number(comparison_number(dg))
    lines.push(
      "\{step},\{row.stringify()},\{col.stringify()},\{distance.stringify()},\{old_csv},\{new_csv},\{dz_csv},\{coverage},\{old_status},\{new_status},\{dg_csv}",
    )
  }
  let old_summary = comparison_field(before, "summary")
  let new_summary = comparison_field(after, "summary")
  let summary : Json = if old_summary is Object(_) && new_summary is Object(_) {
    let deltas : Map[String, Json] = Map::new()
    for
      key in [
        "horizontal_distance_m", "piecewise_3d_distance_m", "ascent_m", "descent_m",
        "max_absolute_grade_deg", "objective_cost_m",
      ] {
      deltas[key] = comparison_delta(
        comparison_field(old_summary, key),
        comparison_field(new_summary, key),
      )
    }
    deltas.to_json()
  } else {
    Json::null()
  }
  let csv = lines.join("\n") + "\n"
  let report = [
      "# Exact-path terrain comparison",
      "Candidate minus reference on the same submitted path. Frames, grid dimensions, spacing and cell centers match exactly. No rerouting, reprojection or resampling.",
      "Reference source: " +
      json_text(reference, "source_digest") +
      ". Candidate source: " +
      json_text(candidate, "source_digest") +
      ".",
      "\{changed} known elevation point occurrences changed; \{gained} gained coverage; \{lost} lost coverage. \{transitions} incident segment statuses changed. Repeated visits count separately.",
      "Reference: " +
      json_text(before, "status") +
      ". Candidate: " +
      json_text(after, "status") +
      ".",
      if summary is Object(_) {
        "Whole-path deltas are available in summary_delta. A numeric delta is not an overall improvement ranking."
      } else {
        "INCOMPLETE COMPARISON: summary_delta is null because at least one source lacks whole-path coverage. Per-point unknown deltas remain null, never zero."
      },
      "path-comparison.csv records aligned point occurrences and incident segment transitions. Full independent assessments, parameters, exact path input and both reopened sources are embedded in terrain-path-comparison.json.",
      "Exploratory digital point-path comparison only. Inputs and frame names are declarations, not validated terrain. No uncertainty propagation, energy, footprint, robot suitability, mission acceptance or physical readiness. This does not establish that the sources have a parent-child revision relationship.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-path-comparison.v1",
    "delta_direction": "candidate-minus-reference",
    "reference_assessment": before,
    "candidate_assessment": after,
    "input_path_text": path_cells_text,
    "path_cells_text": comparison_field(before, "path_cells_text"),
    "changes": changes,
    "counts": {
      "changed_known_point_occurrences": changed,
      "coverage_gained_point_occurrences": gained,
      "coverage_lost_point_occurrences": lost,
      "segment_status_transitions": transitions,
    },
    "summary_delta": summary,
    "comparison_csv": csv,
    "comparison_csv_digest": digest(csv),
    "report_markdown": report,
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid comparison")
  }
  fields["comparison_digest"] = identity.to_json()
  result
}
