///|
pub(all) struct Heightfield {
  field_id : String
  rows : Int
  cols : Int
  cell_size_m : Double
  elevations_m : Array[Double]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct HeightfieldSample {
  field_id : String
  row : Int
  col : Int
  x_m : Double
  y_m : Double
  elevation_m : Double
  local_grade_x : Double
  local_grade_y : Double
  surface_normal : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn heightfield(
  field_id : String,
  rows : Int,
  cols : Int,
  cell_size_m : Double,
  elevations_m : Array[Double],
) -> Heightfield {
  { field_id, rows, cols, cell_size_m, elevations_m }
}

///|
fn heightfield_cell(field : Heightfield, row : Int, col : Int) -> Double {
  if field.rows <= 0 || field.cols <= 0 || field.elevations_m.is_empty() {
    0.0
  } else {
    let safe_row = wrapped_index(row, field.rows)
    let safe_col = wrapped_index(col, field.cols)
    field.elevations_m[safe_row * field.cols + safe_col]
  }
}

///|
fn heightfield_floor_index(value : Double) -> Int {
  let truncated = value.to_int()
  if value < truncated.to_double() {
    truncated - 1
  } else {
    truncated
  }
}

///|
fn heightfield_fraction(value : Double, base : Int) -> Double {
  value - base.to_double()
}

///|
fn heightfield_surface_normal(grade_x : Double, grade_y : Double) -> Vec3 {
  let raw = vec3(0.0 - grade_x, 0.0 - grade_y, 1.0)
  let length = raw.length()
  if length > 0.0 {
    raw.scale(1.0 / length)
  } else {
    vec3(0.0, 0.0, 1.0)
  }
}

///|
pub fn sample_heightfield(
  field : Heightfield,
  x_m : Double,
  y_m : Double,
) -> HeightfieldSample {
  if field.rows <= 0 || field.cols <= 0 || field.cell_size_m <= 0.0 {
    {
      field_id: field.field_id,
      row: 0,
      col: 0,
      x_m,
      y_m,
      elevation_m: 0.0,
      local_grade_x: 0.0,
      local_grade_y: 0.0,
      surface_normal: vec3(0.0, 0.0, 1.0),
    }
  } else {
    let x_cell = x_m / field.cell_size_m
    let centered_y = y_m + field.rows.to_double() * field.cell_size_m * 0.5
    let y_cell = centered_y / field.cell_size_m
    let col_base = heightfield_floor_index(x_cell)
    let row_base = heightfield_floor_index(y_cell)
    let col = wrapped_index(col_base, field.cols)
    let row = wrapped_index(row_base, field.rows)
    let next_col = wrapped_index(col + 1, field.cols)
    let next_row = wrapped_index(row + 1, field.rows)
    let tx = heightfield_fraction(x_cell, col_base)
    let ty = heightfield_fraction(y_cell, row_base)
    let h00 = heightfield_cell(field, row, col)
    let h10 = heightfield_cell(field, row, next_col)
    let h01 = heightfield_cell(field, next_row, col)
    let h11 = heightfield_cell(field, next_row, next_col)
    let x0 = h00 + (h10 - h00) * tx
    let x1 = h01 + (h11 - h01) * tx
    let elevation_m = x0 + (x1 - x0) * ty
    let grade_x = ((h10 - h00) * (1.0 - ty) + (h11 - h01) * ty) /
      field.cell_size_m
    let grade_y = ((h01 - h00) * (1.0 - tx) + (h11 - h10) * tx) /
      field.cell_size_m
    {
      field_id: field.field_id,
      row,
      col,
      x_m,
      y_m,
      elevation_m,
      local_grade_x: abs_double(grade_x),
      local_grade_y: abs_double(grade_y),
      surface_normal: heightfield_surface_normal(grade_x, grade_y),
    }
  }
}
