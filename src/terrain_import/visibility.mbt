///|
// Exact fractions only describe grid intersection, not measured terrain. With
// at most 4096 cells, all doubled-coordinate cross products fit in Int.
priv struct SightFraction {
  numerator : Int
  denominator : Int
}

///|
fn sight_compare(a : SightFraction, b : SightFraction) -> Int {
  a.numerator * b.denominator - b.numerator * a.denominator
}

///|
fn SightFraction::value(self : SightFraction) -> Double {
  self.numerator.to_double() / self.denominator.to_double()
}

///|
// Convex interpolation preserves exact endpoint elevations despite very
// different magnitudes; start + (end - start) * t can lose the target.
fn sight_elevation(start : Double, end : Double, t : Double) -> Double {
  (1.0 - t) * start + t * end
}

///|
priv struct SightCell {
  row : Int
  col : Int
  entry : SightFraction
  exit : SightFraction
  elevation : Double?
  clearance : Double?
  status : String
}

///|
// Clip against closed squares. A corner touch deliberately includes all cells
// meeting there, including zero-length contacts; no diagonal gap is skipped.
fn sight_interval(
  start_row : Int,
  start_col : Int,
  end_row : Int,
  end_col : Int,
  row : Int,
  col : Int,
) -> (SightFraction, SightFraction)? {
  let mut entry = { numerator: 0, denominator: 1, }
  let mut exit = { numerator: 1, denominator: 1, }
  for
    (start, end, cell) in [(start_row, end_row, row), (start_col, end_col, col)] {
    let delta = end - start
    if delta == 0 {
      if cell != start {
        return None
      }
    } else {
      let low = 2 * (cell - start) - 1
      let high = low + 2
      let (lo, hi) = if delta > 0 {
        (
          { numerator: low, denominator: 2 * delta, },
          { numerator: high, denominator: 2 * delta, },
        )
      } else {
        (
          { numerator: -high, denominator: -2 * delta, },
          { numerator: -low, denominator: -2 * delta, },
        )
      }
      if sight_compare(lo, entry) > 0 {
        entry = lo
      }
      if sight_compare(hi, exit) < 0 {
        exit = hi
      }
      if sight_compare(entry, exit) > 0 {
        return None
      }
    }
  }
  Some((entry, exit))
}

///|
/// Screen a straight sightline through a declared, local Cartesian metre grid.
/// Each intersected closed cell is a constant-height prism, including corner
/// contacts. This is a bounded geometric model, not a radio or solar forecast.
pub fn visibility_bundle(
  source_bundle : String,
  observer_row : Int,
  observer_col : Int,
  target_row : Int,
  target_col : Int,
  observer_height_m : Double,
  target_height_m : Double,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  need(
    json_text(source, "horizontal_unit") == "m",
    "Visibility requires declared local Cartesian metre cells; reproject degree grids separately",
  )
  need(
    finite(observer_height_m) &&
    finite(target_height_m) &&
    observer_height_m >= 0.0 &&
    target_height_m >= 0.0,
    "Observer and target heights must be finite and nonnegative",
  )
  let grid = bundle_grid(source)
  let (ox, oy) = grid.cell_center(observer_row, observer_col)
  let (tx, ty) = grid.cell_center(target_row, target_col)
  need(
    observer_row != target_row || observer_col != target_col,
    "Observer and target must be different cells",
  )
  guard grid.values[observer_row * grid.cols + observer_col] is Some(oz) &&
    grid.values[target_row * grid.cols + target_col] is Some(tz) else {
    raise InvalidRaster("Observer and target need known terrain elevations")
  }
  let start_z = oz + observer_height_m
  let end_z = tz + target_height_m
  let rise = end_z - start_z
  let distance = @math.hypot(
      (target_row - observer_row).to_double(),
      (target_col - observer_col).to_double(),
    ) *
    grid.cell_size
  need(
    finite(start_z) &&
    finite(end_z) &&
    finite(rise) &&
    finite(distance) &&
    distance > 0.0,
    "Visibility geometry overflows or underflows; rescale the source or heights",
  )
  let cells : Array[SightCell] = []
  let mut unknown = 0
  let mut blocked = 0
  let mut grazing = 0
  let mut known_minimum : Double? = None
  for index, elevation in grid.values {
    let row = index / grid.cols
    let col = index % grid.cols
    guard sight_interval(
        observer_row, observer_col, target_row, target_col, row, col,
      )
      is Some((entry, exit)) else {
      continue
    }
    let a = sight_elevation(start_z, end_z, entry.value())
    let b = sight_elevation(start_z, end_z, exit.value())
    need(finite(a) && finite(b), "Sightline elevation overflows")
    let (clearance, status) = match elevation {
      None => {
        unknown += 1
        (None, "unknown")
      }
      Some(z) => {
        let minimum = a.min(b) - z
        need(finite(minimum), "Sightline clearance overflows")
        known_minimum = Some(
          known_minimum.map(v => v.min(minimum)).unwrap_or(minimum),
        )
        let status = if minimum < 0.0 {
          blocked += 1
          "blocked"
        } else if minimum == 0.0 {
          grazing += 1
          "grazing"
        } else {
          "clear"
        }
        (Some(minimum), status)
      }
    }
    cells.push({ row, col, entry, exit, elevation, clearance, status, })
  }
  cells.sort_by((a, b) => {
    let first = sight_compare(a.entry, b.entry)
    if first != 0 {
      first
    } else {
      let second = sight_compare(a.exit, b.exit)
      if second != 0 {
        second
      } else {
        a.row * grid.cols + a.col - (b.row * grid.cols + b.col)
      }
    }
  })
  let status = if blocked > 0 {
    "blocked-known-terrain"
  } else if unknown > 0 {
    "incomplete-coverage"
  } else if grazing > 0 {
    "grazing"
  } else {
    "clear-in-model"
  }
  let rows : Array[Json] = []
  let csv_lines = [
    "step,row,col,x_m,y_m,entry_fraction,exit_fraction,entry_distance_m,exit_distance_m,terrain_elevation_m,line_entry_elevation_m,line_exit_elevation_m,minimum_clearance_m,contact,status",
  ]
  let mut corner_contacts = 0
  for step, cell in cells {
    let (x, y) = grid.cell_center(cell.row, cell.col)
    let t0 = cell.entry.value()
    let t1 = cell.exit.value()
    let d0 = t0 * distance
    let d1 = t1 * distance
    let a = sight_elevation(start_z, end_z, t0)
    let b = sight_elevation(start_z, end_z, t1)
    let contact = if sight_compare(cell.entry, cell.exit) == 0 {
      corner_contacts += 1
      "corner"
    } else {
      "interval"
    }
    rows.push({
      "step": step,
      "row": cell.row,
      "col": cell.col,
      "x_m": x,
      "y_m": y,
      "entry_fraction": t0,
      "exit_fraction": t1,
      "entry_distance_m": d0,
      "exit_distance_m": d1,
      "terrain_elevation_m": nullable(cell.elevation),
      "line_entry_elevation_m": a,
      "line_exit_elevation_m": b,
      "minimum_clearance_m": nullable(cell.clearance),
      "contact": contact,
      "status": cell.status,
    })
    csv_lines.push(
      "\{step},\{cell.row},\{cell.col},\{x},\{y},\{t0},\{t1},\{d0},\{d1},\{csv_number(cell.elevation)},\{a},\{b},\{csv_number(cell.clearance)},\{contact},\{cell.status}",
    )
  }
  let csv = csv_lines.join("\n") + "\n"
  let svg = visibility_svg(cells, start_z, end_z, distance, status, unknown)
  let source_id = digest(source.stringify())
  let frame = json_text(source, "coordinate_frame")
  let report = [
      "# Imported terrain line of sight",
      "Result: \{status}. Known blocked cells: \{blocked}; grazing contacts: \{grazing}; unknown cells: \{unknown}. All \{cells.length()} intersected cells, including \{corner_contacts} corner-only contacts, remain in the trace.",
      "Source bundle: \{source_id}. Declared frame: \{frame}. Horizontal spacing and elevations are declared metres. The complete original/revised/mosaic source and its notes are retained in visibility.json.",
      "Observer: row \{observer_row}, col \{observer_col}, height \{observer_height_m} m above terrain, absolute elevation \{start_z} m. Target: row \{target_row}, col \{target_col}, height \{target_height_m} m above terrain, absolute elevation \{end_z} m. Horizontal span: \{distance} m.",
      "## Method",
      "A straight line joins the two elevated cell centers. Each intersected closed square cell has its declared constant terrain elevation over the entire footprint. Exact integer-ratio clipping includes edge/corner touches; both neighboring cells count at a shared boundary. The minimum clearance for each known cell is min(line at entry, line at exit) minus terrain elevation. A negative clearance blocks; exactly zero is grazing, never clear. No epsilon or interpolation is inferred. Cells are ordered by entry, exit, then row-major position.",
      "## Coverage and interpretation",
      "Any known negative clearance yields blocked-known-terrain even when another cell is unknown. Otherwise unknown coverage yields incomplete-coverage, then exact grazing yields grazing. Only complete coverage with strictly positive clearances yields clear-in-model. The known-cell minimum is not a whole-line clearance when coverage is missing; the whole-line minimum is null in that case. Endpoint cells are included, so a zero-height endpoint generally grazes terrain. Unrelated off-line gaps do not affect this particular segment.",
      "## Limits",
      "A local flat Cartesian geometric screening model only. Cell-center samples do not prove constant terrain within cells. Corner inclusion is conservative for this cell model, not a bound on actual terrain. No planetary curvature, refraction, uncertainty propagation, subcell obstruction, Fresnel zone, link budget, solar/ephemeris prediction, energy, robot suitability, physical readiness or terrain truth is established. Large-area and radio/illumination decisions need a qualified external model. Existing mission energy blockers are unchanged.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-visibility.v1",
    "method": "closed-cell-constant-height-line-of-sight-v1",
    "source_bundle": source,
    "source_bundle_digest": source_id,
    "parameters": {
      "observer_row": observer_row,
      "observer_col": observer_col,
      "target_row": target_row,
      "target_col": target_col,
      "observer_height_m": observer_height_m,
      "target_height_m": target_height_m,
    },
    "observer": {
      "x_m": ox,
      "y_m": oy,
      "terrain_elevation_m": oz,
      "line_elevation_m": start_z,
    },
    "target": {
      "x_m": tx,
      "y_m": ty,
      "terrain_elevation_m": tz,
      "line_elevation_m": end_z,
    },
    "status": status,
    "coverage_complete": unknown == 0,
    "summary": {
      "horizontal_distance_m": distance,
      "intersected_cells": cells.length(),
      "unknown_cells": unknown,
      "blocked_cells": blocked,
      "grazing_cells": grazing,
      "corner_contacts": corner_contacts,
      "known_minimum_clearance_m": nullable(known_minimum),
      "whole_line_minimum_clearance_m": if unknown == 0 {
        nullable(known_minimum)
      } else {
        Json::null()
      },
    },
    "cells": rows,
    "cells_csv": csv,
    "cells_csv_digest": digest(csv),
    "profile_svg": svg,
    "profile_svg_digest": digest(svg),
    "report_markdown": report,
    "report_markdown_digest": digest(report),
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid visibility result")
  }
  fields["visibility_digest"] = identity.to_json()
  result
}
