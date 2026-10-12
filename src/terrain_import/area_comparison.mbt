///|
/// Compare every cell of two exactly aligned metre grids, preserving unknowns.
/// Volumes use a declared constant-height square-cell model, not physical change.
pub fn compare_area_bundle(
  reference_bundle : String,
  candidate_bundle : String,
  change_threshold_m : Double,
) -> Json raise ImportError {
  need(
    finite(change_threshold_m) && change_threshold_m >= 0.0,
    "Area change threshold must be finite and nonnegative metres",
  )
  let reference = reopen_bundle(reference_bundle)
  let candidate = reopen_bundle(candidate_bundle)
  need(
    json_text(reference, "horizontal_unit") == "m" &&
    json_text(candidate, "horizontal_unit") == "m",
    "Area comparison requires declared metre grids; no reprojection is performed",
  )
  need(
    json_text(reference, "coordinate_frame") ==
    json_text(candidate, "coordinate_frame"),
    "Cannot compare areas: coordinate frames differ",
  )
  let a = bundle_grid(reference)
  let b = bundle_grid(candidate)
  need(
    a.rows == b.rows &&
    a.cols == b.cols &&
    a.cell_size == b.cell_size &&
    a.cell_center(0, 0) == b.cell_center(0, 0),
    "Cannot compare areas: grid dimensions, spacing or cell centers differ; no resampling is performed",
  )
  let area = a.cell_size * a.cell_size
  let total_area = area * a.values.length().to_double()
  need(
    finite(area) && area > 0.0 && finite(total_area),
    "Cell or total area overflows or underflows; rescale the source",
  )
  let changes : Array[Json] = []
  let lines = [
    "row,col,x_m,y_m,reference_elevation_m,candidate_elevation_m,elevation_delta_m,coverage_change,change_class,cell_area_m2,signed_volume_change_m3",
  ]
  let mut known = 0
  let mut gained = 0
  let mut lost = 0
  let mut neither = 0
  let mut rising = 0
  let mut falling = 0
  let mut within = 0
  let mut changed = 0
  let mut positive_volume = 0.0
  let mut negative_volume = 0.0
  let mut delta_sum = 0.0
  let mut min_delta : Double? = None
  let mut max_delta : Double? = None
  for index, old_z in a.values {
    let new_z = b.values[index]
    let row = index / a.cols
    let col = index % a.cols
    let (x, y) = a.cell_center(row, col)
    let (coverage, classification, delta, volume) = match (old_z, new_z) {
      (Some(before), Some(after)) => {
        known += 1
        let dz = after - before
        let dv = dz * area
        need(
          finite(dz) && finite(dv) && (dz == 0.0 || dv != 0.0),
          "Elevation difference or volume overflows or underflows; rescale the sources",
        )
        delta_sum += dz
        if dz > 0.0 {
          positive_volume += dv
        } else if dz < 0.0 {
          negative_volume += dv
        }
        need(
          finite(delta_sum) &&
          finite(positive_volume) &&
          finite(negative_volume),
          "Area comparison total overflows; rescale the sources",
        )
        min_delta = Some(min_delta.map(v => v.min(dz)).unwrap_or(dz))
        max_delta = Some(max_delta.map(v => v.max(dz)).unwrap_or(dz))
        if dz != 0.0 {
          changed += 1
        }
        let kind = if dz > change_threshold_m {
          rising += 1
          "rise-exceeds-threshold"
        } else if dz < -change_threshold_m {
          falling += 1
          "fall-exceeds-threshold"
        } else {
          within += 1
          "within-threshold"
        }
        ("known-both", kind, Some(dz), Some(dv))
      }
      (Some(_), None) => {
        lost += 1
        ("coverage-lost", "unknown", None, None)
      }
      (None, Some(_)) => {
        gained += 1
        ("coverage-gained", "unknown", None, None)
      }
      (None, None) => {
        neither += 1
        ("unknown-both", "unknown", None, None)
      }
    }
    changes.push({
      "row": row,
      "col": col,
      "x_m": x,
      "y_m": y,
      "reference_elevation_m": nullable(old_z),
      "candidate_elevation_m": nullable(new_z),
      "elevation_delta_m": nullable(delta),
      "coverage_change": coverage,
      "change_class": classification,
      "cell_area_m2": area,
      "signed_volume_change_m3": nullable(volume),
    })
    lines.push(
      "\{row},\{col},\{x},\{y},\{csv_number(old_z)},\{csv_number(new_z)},\{csv_number(delta)},\{coverage},\{classification},\{area},\{csv_number(volume)}",
    )
  }
  let observed : Json = if known == 0 {
    Json::null()
  } else {
    {
      "minimum_delta_m": nullable(min_delta),
      "maximum_delta_m": nullable(max_delta),
      "mean_delta_m": delta_sum / known.to_double(),
      "positive_volume_change_m3": positive_volume,
      "negative_volume_change_m3": negative_volume,
      "net_volume_change_m3": positive_volume + negative_volume,
    }
  }
  let complete = known == a.values.length()
  let status = if known == 0 {
    "no-shared-elevation-coverage"
  } else if !complete {
    "incomplete-comparison"
  } else {
    "complete-comparison"
  }
  let csv = lines.join("\n") + "\n"
  let svg = area_change_svg(a, changes, change_threshold_m)
  let report = [
      "# Whole-area terrain change comparison",
      "Candidate minus reference on every exactly aligned source cell. Status: " +
      status +
      ".",
      "Reference source: " +
      json_text(reference, "source_digest") +
      ". Candidate source: " +
      json_text(candidate, "source_digest") +
      ".",
      "Declared coordinate frame: " +
      json_text(reference, "coordinate_frame") +
      ". Horizontal and elevation units: metres. No reprojection or resampling.",
      "\{known} cells known in both sources; \{gained} gained coverage; \{lost} lost coverage; \{neither} unknown in both. Shared observed area: \{known.to_double() * area} m2 of \{total_area} m2.",
      "Threshold: \{change_threshold_m} m. \{rising} rises and \{falling} falls strictly exceed it; \{within} known cells are within it. Equality is within threshold. \{changed} known cells differ numerically. The threshold only classifies the map; all known changes enter statistics and volumes.",
      "Observed statistics (only shared known cells): " +
      observed.stringify() +
      ".",
      if complete {
        "Whole-grid statistics are available because every cell is known in both sources. Complete coverage is not proof of terrain truth or significance."
      } else {
        "Whole-grid statistics are null. Gained/lost/unknown cells have no delta or volume; an observed subset total is not a bound on unknown changes. No gap filling is performed."
      },
      "Volume model: each elevation represents a constant-height square cell of area cell_size squared. Signed cell volume = (candidate elevation - reference elevation) times cell area. Positive and negative volumes are retained separately; negative volume stays signed. This is a model-based comparison of inputs, not measured excavation, deposited material or physical change.",
      "Inspect area-changes.csv for every cell and area-change.svg for change and coverage patterns. The complete JSON embeds both independently reopened sources, outputs, parameters and result identity. Matching frame labels and grids do not establish datum compatibility, revision ancestry or external dataset truth.",
      "The threshold is an explicit exploratory magnitude, not measurement uncertainty or statistical significance. No uncertainty propagation, route/energy requalification, robot suitability, mission acceptance or physical readiness. Existing mission blockers remain unchanged.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-area-comparison.v1",
    "method": "aligned-square-cell-difference.v1",
    "delta_direction": "candidate-minus-reference",
    "reference_source": reference,
    "candidate_source": candidate,
    "change_threshold_m": change_threshold_m,
    "status": status,
    "coverage_complete": complete,
    "counts": {
      "total_cells": a.values.length(),
      "known_both_cells": known,
      "coverage_gained_cells": gained,
      "coverage_lost_cells": lost,
      "unknown_both_cells": neither,
      "changed_known_cells": changed,
      "rise_exceeds_threshold_cells": rising,
      "fall_exceeds_threshold_cells": falling,
      "within_threshold_cells": within,
    },
    "areas_m2": {
      "cell": area,
      "total": total_area,
      "known_both": known.to_double() * area,
      "coverage_gained": gained.to_double() * area,
      "coverage_lost": lost.to_double() * area,
      "unknown_both": neither.to_double() * area,
    },
    "observed_statistics": observed,
    "whole_grid_statistics": if complete {
      observed
    } else {
      Json::null()
    },
    "cells": changes,
    "changes_csv": csv,
    "changes_csv_digest": digest(csv),
    "change_map_svg": svg,
    "change_map_svg_digest": digest(svg),
    "report_markdown": report,
    "report_markdown_digest": digest(report),
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid area comparison")
  }
  fields["comparison_digest"] = identity.to_json()
  result
}
