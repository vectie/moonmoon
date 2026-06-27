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
fn heightfield_col_at_x(field : Heightfield, x_m : Double) -> Int {
  if field.cols <= 0 || field.cell_size_m <= 0.0 {
    0
  } else {
    wrapped_index((x_m / field.cell_size_m).to_int(), field.cols)
  }
}

///|
fn heightfield_row_at_y(field : Heightfield, y_m : Double) -> Int {
  if field.rows <= 0 || field.cell_size_m <= 0.0 {
    0
  } else {
    let centered_y = y_m + field.rows.to_double() * field.cell_size_m * 0.5
    wrapped_index((centered_y / field.cell_size_m).to_int(), field.rows)
  }
}

///|
pub fn sample_heightfield(
  field : Heightfield,
  x_m : Double,
  y_m : Double,
) -> HeightfieldSample {
  let row = heightfield_row_at_y(field, y_m)
  let col = heightfield_col_at_x(field, x_m)
  let next_col = wrapped_index(col + 1, field.cols)
  let elevation_m = heightfield_cell(field, row, col)
  let next = heightfield_cell(field, row, next_col)
  let local_grade_x = if field.cell_size_m <= 0.0 {
    0.0
  } else {
    abs_double(next - elevation_m) / field.cell_size_m
  }
  { field_id: field.field_id, row, col, x_m, y_m, elevation_m, local_grade_x }
}
