///|
fn energy_number(value : Json, name : String) -> Double raise ImportError {
  guard value is Object(fields) && fields.get(name) is Some(Number(number, ..)) else {
    raise InvalidRaster("Missing numeric energy field " + name)
  }
  need(finite(number), "Energy field must be finite: " + name)
  number
}

///|
fn energy_field(value : Json, name : String) -> Json raise ImportError {
  guard value is Object(fields) && fields.get(name) is Some(found) else {
    raise InvalidRaster("Missing energy assessment field " + name)
  }
  found
}

///|
fn energy_product(a : Double, b : Double) -> Double raise ImportError {
  let value = a * b
  need(
    finite(value) && (a == 0.0 || b == 0.0 || value > 0.0),
    "Energy arithmetic overflows or underflows; rescale the assumptions",
  )
  value
}

///|
/// Budget the exact submitted path with explicit, uncalibrated consumption rates.
/// No route search, robot-profile inference, charging or regeneration is done.
/// Unknown incident elevations withhold segment energy and downstream balance.
pub fn path_energy_bundle(
  source_bundle : String,
  path_cells_text : String,
  assumptions_text : String,
) -> Json raise ImportError {
  need(
    assumptions_text.length() <= 16384,
    "Energy assumptions exceed 16384 characters",
  )
  let assumptions = @json.parse(assumptions_text) catch {
    _ => raise InvalidRaster("Invalid energy assumptions JSON")
  }
  need(
    json_text(assumptions, "contract_id") ==
    "moonmoon.path-energy-assumptions.v1",
    "Unsupported energy assumptions contract",
  )
  let note = json_text(assumptions, "assumption_note")
  need(
    !note.trim().is_empty() && note.length() <= 2000,
    "Describe the energy rate source and limits in assumption_note (1–2000 characters)",
  )
  guard assumptions is Object(assumption_fields) else {
    raise InvalidRaster("Expected energy assumptions object")
  }
  let allowed = [
    "contract_id", "assumption_note", "drive_wh_per_m", "ascent_wh_per_m", "cruise_speed_mps",
    "auxiliary_power_w", "initial_energy_wh", "reserve_wh", "max_grade_deg",
  ]
  for name, _ in assumption_fields {
    need(allowed.contains(name), "Unknown energy assumption: " + name)
  }
  let drive_rate = energy_number(assumptions, "drive_wh_per_m")
  let ascent_rate = energy_number(assumptions, "ascent_wh_per_m")
  let speed = energy_number(assumptions, "cruise_speed_mps")
  let power = energy_number(assumptions, "auxiliary_power_w")
  let initial = energy_number(assumptions, "initial_energy_wh")
  let reserve = energy_number(assumptions, "reserve_wh")
  let cap = energy_number(assumptions, "max_grade_deg")
  need(
    drive_rate >= 0.0 &&
    ascent_rate >= 0.0 &&
    power >= 0.0 &&
    initial >= 0.0 &&
    reserve >= 0.0,
    "Energy rates, power, initial energy and reserve must be nonnegative",
  )
  need(speed > 0.0, "Cruise speed must be positive")
  // The established path assessor reopens all source types and validates exact
  // cardinal cells, coverage, coordinates, grade and finite geometry.
  let assessment = assess_path_bundle(source_bundle, path_cells_text, cap, 0.0)
  guard energy_field(assessment, "path") is Array(path) else {
    raise InvalidRaster("Missing assessed path")
  }
  let complete = energy_field(assessment, "coverage_complete") == true.to_json()
  let records : Array[Json] = []
  let csv_lines = [
    "step,row,col,x_m,y_m,elevation_m,segment_status,segment_time_s,drive_wh,ascent_wh,auxiliary_wh,segment_consumption_wh,cumulative_consumption_wh,remaining_energy_wh,reserve_margin_wh",
  ]
  let mut known_energy = 0.0
  let mut known_drive = 0.0
  let mut known_ascent = 0.0
  let mut known_auxiliary = 0.0
  let mut elapsed = 0.0
  let mut cumulative : Double? = Some(0.0)
  let mut first_insufficient : Int? = None
  let mut first_reserve : Int? = None
  for step, point in path {
    let span = if step == 0 {
      0.0
    } else {
      energy_number(point, "segment_horizontal_distance_m")
    }
    let time = span / speed
    need(
      finite(time) && (span == 0.0 || time > 0.0),
      "Travel time overflows or underflows; rescale the speed",
    )
    let drive = energy_product(span, drive_rate)
    let auxiliary = energy_product(time / 3600.0, power)
    need(
      time == 0.0 || time / 3600.0 > 0.0,
      "Travel hours underflow; rescale the speed",
    )
    let climb : Double? = if step == 0 {
      Some(0.0)
    } else {
      match energy_field(point, "rise_m") {
        Number(rise, ..) => Some(energy_product(rise.max(0.0), ascent_rate))
        _ => None
      }
    }
    let segment = climb.map(value => drive + value + auxiliary)
    elapsed += time
    if segment is Some(consumption) {
      need(
        finite(consumption),
        "Segment energy overflows; rescale the assumptions",
      )
      known_energy += consumption
      known_drive += drive
      known_ascent += climb.unwrap()
      known_auxiliary += auxiliary
      cumulative = cumulative.map(value => value + consumption)
    } else {
      // Never resume a battery balance after a coverage gap.
      cumulative = None
    }
    need(
      finite(elapsed) &&
      finite(known_energy) &&
      finite(known_drive) &&
      finite(known_ascent) &&
      finite(known_auxiliary),
      "Energy totals overflow; rescale the assumptions",
    )
    let remaining = cumulative.map(value => initial - value)
    let margin = remaining.map(value => value - reserve)
    if remaining is Some(value) {
      need(finite(value), "Remaining energy overflows")
      if value < 0.0 && first_insufficient is None {
        first_insufficient = Some(step)
      }
    }
    if margin is Some(value) {
      need(finite(value), "Reserve margin overflows")
      if value < 0.0 && first_reserve is None {
        first_reserve = Some(step)
      }
    }
    let status = json_text(point, "segment_status")
    let record : Json = {
      "step": step,
      "row": energy_field(point, "row"),
      "col": energy_field(point, "col"),
      "x_m": energy_field(point, "x_m"),
      "y_m": energy_field(point, "y_m"),
      "elevation_m": energy_field(point, "elevation_m"),
      "segment_status": status,
      "segment_time_s": time,
      "drive_wh": drive,
      "ascent_wh": nullable(climb),
      "auxiliary_wh": auxiliary,
      "segment_consumption_wh": nullable(segment),
      "cumulative_consumption_wh": nullable(cumulative),
      "remaining_energy_wh": nullable(remaining),
      "reserve_margin_wh": nullable(margin),
    }
    records.push(record)
    let values = [step.to_string()]
    for key in ["row", "col", "x_m", "y_m", "elevation_m"] {
      values.push(
        match energy_field(point, key) {
          Number(n, ..) => n.to_string()
          _ => ""
        },
      )
    }
    values.push(status)
    for
      value in [
        Some(time),
        Some(drive),
        climb,
        Some(auxiliary),
        segment,
        cumulative,
        remaining,
        margin,
      ] {
      values.push(csv_number(value))
    }
    csv_lines.push(values.join(","))
  }
  let observed_margin = initial - known_energy - reserve
  need(finite(observed_margin), "Observed reserve margin overflows")
  // Nonnegative rates mean known segments alone can prove insufficiency, even
  // when a gap prevents the exact total or the crossing location from being known.
  let status = if known_energy > initial {
    "insufficient-energy"
  } else if observed_margin < 0.0 {
    "below-reserve"
  } else if !complete {
    "incomplete-coverage"
  } else {
    "within-declared-budget"
  }
  let csv = csv_lines.join("\n") + "\n"
  let normalized_path = json_text(assessment, "path_cells_text")
  let source = energy_field(assessment, "source_bundle")
  let report = [
      "# Imported-terrain path energy: " + status,
      "Declared-rate exploration only. This is an energy budget for the submitted path, not a robot simulation, mission acceptance or physical-readiness decision.",
      "Source: " +
      json_text(source, "source_digest") +
      ". Declared frame: " +
      json_text(source, "coordinate_frame") +
      "; horizontal/elevation units: metres. Exact source bundle is retained in path_assessment.source_bundle.",
      "Assumption note: " + note,
      "## Results",
      "Complete elevation coverage: \{complete}. Geometric travel time: \{elapsed} s. Observed-segment energy: \{known_energy} Wh (drive \{known_drive}, ascent \{known_ascent}, auxiliary \{known_auxiliary}).",
      "Initial energy: \{initial} Wh; retained reserve: \{reserve} Wh. Grade cap: \{cap} degrees; grade screening: " +
      json_text(assessment, "grade_screening") +
      ". A within-budget result never overrides an exceeded or unknown grade screen.",
      if complete {
        "Whole-path energy and final battery balance are available in summary and energy-segments.csv. Negative balances are retained, never clamped to zero."
      } else {
        "INCOMPLETE COVERAGE: summary is null. Unknown incident segments have null energy; every balance after the first gap remains null. Later known-segment totals are disconnected observations, not a reachable prefix. Known consumption can still prove insufficient energy or a reserve shortfall; no exact crossing point is invented across a gap."
      },
      "The first insufficient and below-reserve steps are zero-based sampled endpoints within the known prefix only. Null means no known crossing, not proof that no crossing exists. No subsegment crossing location is inferred.",
      "## Model",
      "For each moving segment: duration = horizontal distance / \{speed} m/s; drive = horizontal distance × \{drive_rate} Wh/m; ascent = positive elevation rise × \{ascent_rate} Wh/m; auxiliary = duration / 3600 × \{power} W. Segment energy is their sum. Descent gets no regenerative credit. Known repeated cells have zero duration and consume zero in this model; dwell, turning and startup energy are not modeled.",
      "The exact assumptions JSON, full reopened source/path assessment, segment CSV and digests are retained in terrain-path-energy.json. inputs-path.txt and assumptions.json allow rerunning into a new directory. Change the assumption file or revise terrain to produce a separate study.",
      "## Limits",
      "Rates and usable starting energy are user declarations, not inferred from URDF, mass, battery capacity or measured robot performance. No charging/solar supply, acceleration, traction, thermal transients, aging, uncertainty propagation or physical validation. Horizontal speed is constant; it is not speed along the 3D surface. Existing frozen missions and negative-energy blockers remain unchanged. Source frame, units, quality and uncertainty remain unverified declarations. Floating-point precision limits apply; finite arithmetic overflow and detected underflow are rejected.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-path-energy.v1",
    "method": "declared-horizontal-drive-ascent-auxiliary-v1",
    "path_assessment": assessment,
    "assumptions": assumptions,
    "assumptions_text": assumptions_text,
    "assumptions_digest": digest(assumptions_text),
    "status": status,
    "coverage_complete": complete,
    "grade_screening": energy_field(assessment, "grade_screening"),
    "geometric_travel_time_s": elapsed,
    "observed_segments": {
      "drive_wh": known_drive,
      "ascent_wh": known_ascent,
      "auxiliary_wh": known_auxiliary,
      "consumption_wh": known_energy,
    },
    "summary": if complete {
      (
        {
          "consumption_wh": known_energy,
          "remaining_energy_wh": initial - known_energy,
          "reserve_margin_wh": observed_margin,
        } : Json)
    } else {
      Json::null()
    },
    "first_known_prefix_insufficient_step": first_insufficient
    .map(value => value.to_json())
    .unwrap_or(Json::null()),
    "first_known_prefix_below_reserve_step": first_reserve
    .map(value => value.to_json())
    .unwrap_or(Json::null()),
    "segments": records,
    "segments_csv": csv,
    "segments_csv_digest": digest(csv),
    "input_path_text": path_cells_text,
    "input_path_digest": digest(path_cells_text),
    "path_cells_text": normalized_path,
    "path_cells_digest": digest(normalized_path),
    "report_markdown": report,
    "report_digest": digest(report),
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid path energy result")
  }
  fields["energy_digest"] = identity.to_json()
  result
}
