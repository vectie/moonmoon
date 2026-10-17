///|
priv struct CoarseCell {
  known : Int
  minimum : Double?
  maximum : Double?
  mean : Double?
}

///|
// Error-free two-sum splits retain small addends until cancellation is complete.
// Unsupported intermediate overflow and final zero-underflow are refused, never
// hidden by clamping. Constant blocks bypass summation: their exact mean is known.
fn coarsen_mean(
  values : Array[Double],
  minimum : Double,
  maximum : Double,
) -> Double raise ImportError {
  if minimum == maximum {
    return minimum
  }
  let mut partials : Array[Double] = []
  for value in values {
    let next : Array[Double] = []
    let mut x = value
    for partial in partials {
      let (large, small) = if x.abs() >= partial.abs() {
        (x, partial)
      } else {
        (partial, x)
      }
      let high = large + small
      need(
        finite(high),
        "Block mean intermediate sum overflows; rescale source elevations before coarsening",
      )
      let low = small - (high - large)
      if low != 0.0 {
        next.push(low)
      }
      x = high
    }
    next.push(x)
    partials = next
  }
  let mut sum = 0.0
  for offset in 0..<partials.length() {
    sum += partials[partials.length() - offset - 1]
  }
  need(
    finite(sum),
    "Block mean sum overflows; rescale source elevations before coarsening",
  )
  let mean = sum / values.length().to_double()
  need(
    sum == 0.0 || mean != 0.0,
    "Nonzero block mean underflows; rescale source elevations before coarsening",
  )
  need(
    finite(mean) && mean >= minimum && mean <= maximum,
    "Block mean is outside representable observed bounds; rescale source elevations before coarsening",
  )
  mean
}

///|
fn coarsen_cell(
  grid : AsciiGrid,
  row : Int,
  col : Int,
  factor : Int,
) -> CoarseCell raise ImportError {
  let mut known = 0
  let mut minimum : Double? = None
  let mut maximum : Double? = None
  let values : Array[Double] = []
  let total = factor * factor
  for dr in 0..<factor {
    for dc in 0..<factor {
      if grid.values[(row * factor + dr) * grid.cols + col * factor + dc]
        is Some(value) {
        known += 1
        minimum = Some(minimum.map(v => v.min(value)).unwrap_or(value))
        maximum = Some(maximum.map(v => v.max(value)).unwrap_or(value))
        values.push(value)
      }
    }
  }
  {
    known,
    minimum,
    maximum,
    mean: if known == total {
      Some(coarsen_mean(values, minimum.unwrap(), maximum.unwrap()))
    } else {
      None
    },
  }
}

///|
/// Aggregate aligned square blocks into a smaller, source-bound overview.
/// A mean is emitted only when every source cell in the block is known.
/// Min/max describe observed samples, including partially observed blocks.
/// Factor 1 preserves sample values and centers; ASCII encoding may differ.
///
/// ```mbt check
/// test {
///   let source = @terrain_import.import_bundle(
///     "ncols 2 nrows 2 xllcorner 0 yllcorner 0 cellsize 1 1 3 5 7", "fine", "Synthetic local frame",
///     "m", "Synthetic example",
///   )
///   let coarse = @terrain_import.coarsen_bundle(
///     source.stringify(),
///     2,
///     "overview",
///     "Scale comparison",
///   )
///   assert_eq(@terrain_import.reopen_coarsen_bundle(coarse.stringify()), coarse)
/// }
/// ```
pub fn coarsen_bundle(
  source_bundle : String,
  factor : Int,
  tile_id : String,
  reason : String,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  let grid = bundle_grid(source)
  need(
    factor >= 1 && factor <= grid.rows && factor <= grid.cols,
    "Aggregation factor must be a positive integer no larger than either grid dimension",
  )
  need(
    grid.rows % factor == 0 && grid.cols % factor == 0,
    "Both dimensions must divide exactly by the factor; choose an explicit crop first, no trimming or padding",
  )
  need(
    !reason.trim().is_empty() && reason.length() <= 1500,
    "Record the coarsening purpose and limitations (1 to 1500 characters)",
  )
  let rows = grid.rows / factor
  let cols = grid.cols / factor
  let spacing = grid.cell_size * factor.to_double()
  let offset = if grid.origin_kind == "corner" {
    0.0
  } else {
    (factor - 1).to_double() * grid.cell_size / 2.0
  }
  let origin_x = grid.origin_x + offset
  let origin_y = grid.origin_y + offset
  need(
    finite(spacing) && finite(origin_x) && finite(origin_y),
    "Coarse grid geometry overflows",
  )
  let cells : Array[CoarseCell] = []
  let means : Array[Double?] = []
  let mut known = 0
  for row in 0..<rows {
    for col in 0..<cols {
      let cell = coarsen_cell(grid, row, col, factor)
      cells.push(cell)
      means.push(cell.mean)
      if cell.mean is Some(_) {
        known += 1
      }
    }
  }
  let marker = crop_nodata(means)
  let kind = if grid.origin_kind == "corner" { "corner" } else { "center" }
  let lines = [
    "ncols \{cols}",
    "nrows \{rows}",
    "xll\{kind} \{origin_x}",
    "yll\{kind} \{origin_y}",
    "cellsize \{spacing}",
    "NODATA_value \{marker}",
  ]
  for row in 0..<rows {
    let samples : Array[String] = []
    for col in 0..<cols {
      samples.push(means[row * cols + col].unwrap_or(marker).to_string())
    }
    lines.push(samples.join(" "))
  }
  let ascii = lines.join("\n") + "\n"
  let coarse = parse_ascii_grid(ascii)
  let records : Array[Json] = []
  let csv = [
    "row,col,source_start_row,source_start_col,source_rows,source_cols,x,y,known_count,total_count,observed_min_m,observed_max_m,mean_elevation_m,coverage",
  ]
  for index, cell in cells {
    let row = index / cols
    let col = index % cols
    let (x, y) = coarse.cell_center(row, col)
    let (first_x, first_y) = grid.cell_center(row * factor, col * factor)
    let (last_x, last_y) = grid.cell_center(
      (row + 1) * factor - 1,
      (col + 1) * factor - 1,
    )
    let expected_x = first_x + (last_x - first_x) / 2.0
    let expected_y = last_y + (first_y - last_y) / 2.0
    need(
      finite(x) && finite(y) && x == expected_x && y == expected_y,
      "Coarse centers cannot represent the source block centers exactly; no coordinate snapping",
    )
    if col > 0 {
      let (previous, _) = coarse.cell_center(row, col - 1)
      need(x > previous, "Coarse X centers collapse at this origin and spacing")
    }
    if row > 0 {
      let (_, previous) = coarse.cell_center(row - 1, col)
      need(y < previous, "Coarse Y centers collapse at this origin and spacing")
    }
    need(coarse.values[index] == cell.mean, "ASCII output changed a block mean")
    let coverage = if cell.known == factor * factor {
      "complete-block"
    } else if cell.known == 0 {
      "unknown-block"
    } else {
      "partial-block-withheld"
    }
    records.push({
      "row": row,
      "col": col,
      "source_start_row": row * factor,
      "source_start_col": col * factor,
      "source_rows": factor,
      "source_cols": factor,
      "x": x,
      "y": y,
      "known_count": cell.known,
      "total_count": factor * factor,
      "observed_min_m": nullable(cell.minimum),
      "observed_max_m": nullable(cell.maximum),
      "mean_elevation_m": nullable(cell.mean),
      "coverage": coverage,
    })
    csv.push(
      "\{row},\{col},\{row * factor},\{col * factor},\{factor},\{factor},\{x},\{y},\{cell.known},\{factor * factor},\{csv_number(cell.minimum)},\{csv_number(cell.maximum)},\{csv_number(cell.mean)},\{coverage}",
    )
  }
  let parent_digest = digest(source.stringify())
  let frame = json_text(source, "coordinate_frame")
  let unit = json_text(source, "horizontal_unit")
  let terrain = import_bundle(
    ascii,
    tile_id,
    frame,
    unit,
    "Derived block-mean overview, factor \{factor}, parent " +
    parent_digest +
    ". Fine-scale hazards may disappear. No navigation or physical authority. Retain terrain-coarsening.json for source, license and statistics. Purpose: " +
    reason,
  )
  let status = if known == 0 {
    "unknown-only"
  } else if known < means.length() {
    "partial-coverage"
  } else {
    "complete-blocks"
  }
  let cells_csv = csv.join("\n") + "\n"
  let svg = coarsen_svg(grid, coarse, cells, factor)
  let report = [
    "# Source-bound coarse terrain overview",
    "",
    "Status: " + status,
    "Parent bundle: " + parent_digest,
    "Declared frame (unverified): " + frame,
    "Horizontal unit: " + unit + "; elevations: m.",
    "Purpose (caller declaration): " + reason,
    "",
    "\{grid.rows} by \{grid.cols} source cells become \{rows} by \{cols} cells using aligned \{factor} by \{factor} blocks. Spacing: \{grid.cell_size} to \{spacing} \{unit}. Extent is retained; no edge trimming, padding or reprojection.",
    "Known coarse means: \{known}; withheld coarse cells: \{means.length() - known}. A block mean is the arithmetic mean of all \{factor * factor} equally weighted source elevations, emitted only when all are known.",
    "coarse-cells.csv records each block's source window, center, valid sample count, observed minimum/maximum and mean. Observed extrema include only known samples; partial-block extrema are incomplete. No mean over the observed subset is substituted for missing coverage.",
    "source.asc and terrain-import.json are reusable ordinary ASCII/import outputs. The lower-left origin is explicit; corner origins remain fixed and center origins move to the coarse block center. Row zero stays the top row. Factor 1 preserves samples and centers, not original bytes.",
    "Open overview.svg to compare fine samples with coarse means. Crossed grey cells have no exported elevation. The common color scale is the source observed range, not terrain safety. Hover for row/column or inspect the CSV.",
    "Retain terrain-coarsening.json with the complete parent, source/license notes, parameters, block statistics and derived files. reopen-coarsening recomputes the saved result. Earlier derivation receipts remain separate when chaining operations.",
    "",
    "## Limits",
    "Coarsening can erase narrow ridges, craters, slope and roughness hazards. The derived mean is a synthetic overview value, not a measured point or validated traversable surface. Never transfer fine-resolution route, energy, visibility or hazard conclusions to this grid, or accept a coarse route as fine-resolution clearance.",
    "Existing contour, mesh and other digital tools can inspect the derived grid; they do not restore lost detail. Use the original source for detailed analysis. Degree grids are not area-weighted and remain ineligible for metre-only tools.",
    "Floating-point arithmetic applies. Constant blocks retain their exact value; other blocks use error-preserving partial summation before division. Nonfinite intermediate sums, nonzero means that round to zero, and means outside observed bounds are refused, never clamped. Some extreme mixed-sign orders are therefore unsupported even when their mathematical mean is finite. Unrepresentable alignment is refused. Inputs remain bounded to 4096 source cells and 1 MiB ASCII by the existing importer.",
    "Source/frame/units and coverage are unverified declarations. No navigation authority, mission acceptance, energy feasibility, robot suitability or physical readiness.",
    "",
  ].join("\n")
  let result : Json = {
    "contract_id": "moonmoon.terrain-coarsening.v1",
    "method": "aligned-complete-block-mean-v1",
    "status": status,
    "source_bundle": source,
    "source_bundle_digest": parent_digest,
    "factor": factor,
    "tile_id": tile_id,
    "reason": reason,
    "coordinate_frame": frame,
    "horizontal_unit": unit,
    "elevation_unit": "m",
    "known_coarse_cells": known,
    "unknown_coarse_cells": means.length() - known,
    "cells": records,
    "ascii_grid_text": ascii,
    "ascii_grid_digest": digest(ascii),
    "terrain_bundle": terrain,
    "terrain_bundle_digest": digest(terrain.stringify()),
    "cells_csv": cells_csv,
    "cells_csv_digest": digest(cells_csv),
    "overview_svg": svg,
    "overview_svg_digest": digest(svg),
    "report_markdown": report,
    "report_digest": digest(report),
    "navigation_authority": false,
    "physical_readiness": false,
  }
  need(
    result.stringify(indent=2).length() + 1 <= 8388608,
    "Terrain coarsening receipt exceeds 8 MiB character limit",
  )
  result
}

///|
/// Recompute a saved overview and all its exports from the retained fine grid.
pub fn reopen_coarsen_bundle(text : String) -> Json raise ImportError {
  need(
    text.length() <= 8388608,
    "Terrain coarsening receipt exceeds 8 MiB character limit",
  )
  let saved = @json.parse(text) catch {
    _ => raise InvalidRaster("Invalid terrain coarsening JSON")
  }
  guard saved is Object(fields) &&
    fields.get("source_bundle") is Some(source) &&
    fields.get("factor") is Some(Number(factor, ..)) else {
    raise InvalidRaster(
      "Coarsening receipt needs a source bundle and numeric factor",
    )
  }
  need(
    finite(factor) &&
    factor >= 1.0 &&
    factor <= 4096.0 &&
    @math.floor(factor) == factor,
    "Aggregation factor must be a bounded positive integer",
  )
  let current = coarsen_bundle(
    source.stringify(),
    factor.to_int(),
    json_text(saved, "tile_id"),
    json_text(saved, "reason"),
  )
  need(
    saved == current,
    "Coarsening receipt differs from recomputed source, parameters or outputs",
  )
  current
}
