///|
// Keep the source graph finite and inspectable: a mosaic contains two original
// imports or revisions of original imports, never another mosaic.
fn mosaic_input(source : Json) -> Unit raise ImportError {
  let contract = json_text(source, "contract_id")
  if contract == "moonmoon.terrain-revision.v1" {
    guard source is Object(fields) &&
      fields.get("base_source_bundle") is Some(base) else {
      raise InvalidRaster("Mosaic revision input needs its original source")
    }
    let base_contract = json_text(base, "contract_id")
    need(
      base_contract == "moonmoon.terrain-import.v1" ||
      base_contract == "moonmoon.terrain-xyz-import.v1",
      "Mosaic inputs must be original ASCII/XYZ imports or revisions of those originals; nested mosaics are unsupported",
    )
  } else {
    need(
      contract == "moonmoon.terrain-import.v1" ||
      contract == "moonmoon.terrain-xyz-import.v1",
      "Mosaic inputs must be original ASCII/XYZ imports or revisions of those originals; nested mosaics are unsupported",
    )
  }
}

///|
fn mosaic_sources(source : Json) -> (Json, Json) raise ImportError {
  guard source is Object(fields) &&
    fields.get("source_bundles") is Some(Array([left, right])) else {
    raise InvalidRaster("Mosaic requires exactly two retained source bundles")
  }
  mosaic_input(left)
  mosaic_input(right)
  (left, right)
}

///|
priv struct MosaicGrid {
  grid : AsciiGrid
  cells_csv : String
  summary : Json
}

///|
fn merge_mosaic_grids(
  left : AsciiGrid,
  right : AsciiGrid,
) -> MosaicGrid raise ImportError {
  need(
    left.cell_size == right.cell_size,
    "Mosaic cell spacing differs; no resampling is performed",
  )
  let spacing = left.cell_size
  let (lx, ly) = left.cell_center(left.rows - 1, 0)
  let (rx, ry) = right.cell_center(right.rows - 1, 0)
  let origin_x = lx.min(rx)
  let origin_y = ly.min(ry)
  fn offset(value : Double, origin : Double) -> Int raise ImportError {
    let cells = (value - origin) / spacing
    need(
      finite(cells) &&
      cells >= 0.0 &&
      cells <= 4095.0 &&
      @math.floor(cells) == cells,
      "Mosaic cell centers must align exactly on one bounded grid; no snapping or resampling is performed",
    )
    cells.to_int()
  }
  let lc = offset(lx, origin_x)
  let lb = offset(ly, origin_y)
  let rc = offset(rx, origin_x)
  let rb = offset(ry, origin_y)
  let cols = (lc + left.cols).max(rc + right.cols)
  let rows = (lb + left.rows).max(rb + right.rows)
  need(
    rows * cols <= 4096,
    "Mosaic bounding grid supports at most 4096 cells, including gaps",
  )
  let grid : AsciiGrid = {
    rows,
    cols,
    origin_x,
    origin_y,
    origin_kind: "center",
    cell_size: spacing,
    nodata_value: -9999.0,
    nodata_declared: false,
    values: Array::make(rows * cols, None),
  }
  // Check every corresponding center, not only origins. This refuses numerical
  // collapse and different floating-point cell geometry rather than silently snapping.
  let indices : Array[Array[Int?]] = []
  for (input, start_col, bottom) in [(left, lc, lb), (right, rc, rb)] {
    let mapped : Array[Int?] = Array::make(rows * cols, None)
    for index in 0..<input.values.length() {
      let row = rows - bottom - input.rows + index / input.cols
      let col = start_col + index % input.cols
      let (x, y) = grid.cell_center(row, col)
      need(finite(x) && finite(y), "Mosaic cell coordinates overflow")
      need(
        (cols == 1 || (x + spacing > x && x - spacing < x)) &&
        (rows == 1 || (y + spacing > y && y - spacing < y)),
        "Mosaic spacing is not representable at this origin",
      )
      need(
        (x, y) == input.cell_center(index / input.cols, index % input.cols),
        "Mosaic source centers differ from the combined grid; no coordinate tolerance is inferred",
      )
      mapped[row * cols + col] = Some(index)
    }
    indices.push(mapped)
  }
  let lines = [
    "row,col,x_m,y_m,elevation_m,contribution,left_row,left_col,left_elevation_m,right_row,right_col,right_elevation_m",
  ]
  let mut left_only = 0
  let mut right_only = 0
  let mut agreed = 0
  let mut gaps = 0
  let mut unknown = 0
  let mut overlap = 0
  for index in 0..<grid.values.length() {
    let li = indices[0][index]
    let ri = indices[1][index]
    let a = match li {
      Some(i) => left.values[i]
      None => None
    }
    let b = match ri {
      Some(i) => right.values[i]
      None => None
    }
    if li is Some(_) && ri is Some(_) {
      overlap += 1
    }
    if li is None && ri is None {
      gaps += 1
    }
    let row = index / cols
    let col = index % cols
    let contribution = match (a, b) {
      (Some(z), Some(other)) => {
        need(
          z == other,
          "Conflicting known elevations at mosaic row \{row}, col \{col}; revise a source explicitly before joining",
        )
        grid.values[index] = Some(z)
        agreed += 1
        "agreeing-overlap"
      }
      (Some(z), None) => {
        grid.values[index] = Some(z)
        left_only += 1
        "left-only"
      }
      (None, Some(z)) => {
        grid.values[index] = Some(z)
        right_only += 1
        "right-only"
      }
      (None, None) => {
        unknown += 1
        "unobserved"
      }
    }
    let (x, y) = grid.cell_center(row, col)
    let lrow = li.map(i => (i / left.cols).to_string()).unwrap_or("")
    let lcol = li.map(i => (i % left.cols).to_string()).unwrap_or("")
    let rrow = ri.map(i => (i / right.cols).to_string()).unwrap_or("")
    let rcol = ri.map(i => (i % right.cols).to_string()).unwrap_or("")
    lines.push(
      "\{row},\{col},\{x},\{y},\{csv_number(grid.values[index])},\{contribution},\{lrow},\{lcol},\{csv_number(a)},\{rrow},\{rcol},\{csv_number(b)}",
    )
  }
  {
    grid,
    cells_csv: lines.join("\n") + "\n",
    summary: {
      "left_only_known_cells": left_only,
      "right_only_known_cells": right_only,
      "agreeing_known_overlap_cells": agreed,
      "footprint_overlap_cells": overlap,
      "outside_both_footprints_cells": gaps,
      "unknown_cells": unknown,
      "known_cells": left_only + right_only + agreed,
      "elevation_coverage_complete": unknown == 0,
    },
  }
}

///|
// Called only after complete source replay and equality validation.
fn mosaic_grid(source : Json) -> AsciiGrid raise ImportError {
  let (left, right) = mosaic_sources(source)
  merge_mosaic_grids(bundle_grid(left), bundle_grid(right)).grid
}
