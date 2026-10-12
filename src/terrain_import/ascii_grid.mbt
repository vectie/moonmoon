///|
/// A bounded local elevation raster. Row zero is the top (north) input row.
pub struct AsciiGrid {
  rows : Int
  cols : Int
  origin_x : Double
  origin_y : Double
  origin_kind : String
  cell_size : Double
  nodata_value : Double
  nodata_declared : Bool
  values : Array[Double?]
} derive(Debug)

///|
pub(all) suberror ImportError {
  InvalidRaster(String)
} derive(Debug)

///|
fn need(condition : Bool, message : String) -> Unit raise ImportError {
  if !condition {
    raise InvalidRaster(message)
  }
}

///|
fn finite(value : Double) -> Bool {
  !value.is_inf() && !value.is_nan()
}

///|
fn number(value : String, label : String) -> Double raise ImportError {
  let parsed = @string.parse_double(value) catch {
    _ => raise InvalidRaster("Invalid number for " + label)
  }
  need(finite(parsed), "Nonfinite number for " + label)
  parsed
}

///|
fn dimension(value : String, label : String) -> Int raise ImportError {
  let parsed = @string.parse_int(value) catch {
    _ => raise InvalidRaster("Expected positive integer " + label)
  }
  need(parsed > 0 && parsed <= 4096, label + " must be between 1 and 4096")
  parsed
}

///|
/// Read the Esri ASCII exchange format with corner or center origin pairs.
/// NODATA defaults to -9999 when omitted. No interpolation or CRS inference.
pub fn parse_ascii_grid(text : String) -> AsciiGrid raise ImportError {
  need(text.length() <= 1048576, "ASCII raster exceeds 1 MiB character limit")
  let tokens = text
    .replace_all(old="\r", new=" ")
    .replace_all(old="\n", new=" ")
    .replace_all(old="\t", new=" ")
    .split(" ")
    .filter(part => !part.is_empty())
    .map(part => part.to_owned())
    .collect()
  let headers : Map[String, String] = Map([])
  let keys = [
    "ncols", "nrows", "xllcorner", "yllcorner", "xllcenter", "yllcenter", "cellsize",
    "nodata_value",
  ]
  let mut offset = 0
  while offset < tokens.length() {
    let key = tokens[offset].to_lower()
    if !keys.contains(key) {
      break
    }
    need(offset + 1 < tokens.length(), "Missing value for " + key)
    need(!headers.contains(key), "Duplicate header " + key)
    headers[key] = tokens[offset + 1]
    offset += 2
  }
  fn required(key : String) -> String raise ImportError {
    guard headers.get(key) is Some(value) else {
      raise InvalidRaster("Missing header " + key)
    }
    value
  }
  let cols = dimension(required("ncols"), "ncols")
  let rows = dimension(required("nrows"), "nrows")
  need(
    rows * cols <= 4096,
    "Raster supports at most 4096 cells; export a smaller clip",
  )
  let corner = headers.contains("xllcorner") && headers.contains("yllcorner")
  let center = headers.contains("xllcenter") && headers.contains("yllcenter")
  need(
    (corner && !headers.contains("xllcenter") && !headers.contains("yllcenter")) ||
    (center && !headers.contains("xllcorner") && !headers.contains("yllcorner")),
    "Use one matching XLLCORNER/YLLCORNER or XLLCENTER/YLLCENTER pair",
  )
  let origin_x = number(
    required(if corner { "xllcorner" } else { "xllcenter" }),
    "x origin",
  )
  let origin_y = number(
    required(if corner { "yllcorner" } else { "yllcenter" }),
    "y origin",
  )
  let cell_size = number(required("cellsize"), "cellsize")
  need(cell_size > 0.0, "cellsize must be positive")
  need(
    finite(origin_x + cols.to_double() * cell_size) &&
    finite(origin_y + rows.to_double() * cell_size),
    "Raster coordinate extent overflows",
  )
  let nodata_declared = headers.contains("nodata_value")
  let nodata_value = number(
    headers.get("nodata_value").unwrap_or("-9999"),
    "NODATA_VALUE",
  )
  need(
    tokens.length() - offset == rows * cols,
    "Raster cell count does not match nrows × ncols",
  )
  let values : Array[Double?] = []
  for index in offset..<tokens.length() {
    let value = number(tokens[index], "cell " + (index - offset).to_string())
    values.push(if value == nodata_value { None } else { Some(value) })
  }
  {
    rows,
    cols,
    origin_x,
    origin_y,
    origin_kind: if corner {
      "corner"
    } else {
      "center"
    },
    cell_size,
    nodata_value,
    nodata_declared,
    values,
  }
}

///|
/// Exact cell-center coordinate in the input coordinate units, without reprojection.
pub fn AsciiGrid::cell_center(
  self : AsciiGrid,
  row : Int,
  col : Int,
) -> (Double, Double) raise ImportError {
  need(
    row >= 0 && row < self.rows && col >= 0 && col < self.cols,
    "Cell outside imported raster",
  )
  let shift = if self.origin_kind == "corner" { 0.5 } else { 0.0 }
  (
    self.origin_x + (col.to_double() + shift) * self.cell_size,
    self.origin_y + ((self.rows - row - 1).to_double() + shift) * self.cell_size,
  )
}

///|
fn tile_id_valid(tile_id : String) -> Bool {
  !tile_id.is_empty() &&
  tile_id.length() <= 100 &&
  tile_id
  .iter()
  .all(c => {
    (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') ||
    c == '-' ||
    c == '_'
  })
}

///|
/// Emit only observed cells. NODATA remains absent, never zero-filled.
pub fn AsciiGrid::terrain_csv(
  self : AsciiGrid,
  tile_id : String,
) -> String raise ImportError {
  need(
    tile_id_valid(tile_id),
    "Tile ID needs 1–100 letters, digits, hyphens or underscores",
  )
  let lines = ["tile_id,row,col,elevation_m"]
  for index, value in self.values {
    if value is Some(elevation) {
      lines.push(
        "\{tile_id},\{index / self.cols},\{index % self.cols},\{elevation}",
      )
    }
  }
  lines.join("\n") + "\n"
}
