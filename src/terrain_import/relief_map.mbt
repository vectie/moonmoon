///|
fn relief_svg(
  grid : AsciiGrid,
  faces : Array[Json],
  azimuth : Double,
  elevation : Double,
  relief : Double,
  lx : Double,
  ly : Double,
  known : Int,
  unknown : Int,
  status : String,
  source_digest : String,
) -> String raise ImportError {
  let (left, bottom) = grid.cell_center(grid.rows - 1, 0)
  let (right, top) = grid.cell_center(0, grid.cols - 1)
  let width = (right - left).max(grid.cell_size)
  let height = (top - bottom).max(grid.cell_size)
  let scale = (730.0 / width).min(370.0 / height)
  need(
    finite(width) && finite(height) && finite(scale) && scale > 0.0,
    "Relief display scale overflows",
  )
  let svg = [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 960 670\" role=\"img\" aria-label=\"Imported terrain relief, declared light and unknown coverage\">",
    "<defs><pattern id=\"unknown\" width=\"10\" height=\"10\" patternUnits=\"userSpaceOnUse\"><rect width=\"10\" height=\"10\" fill=\"#334155\"/><path d=\"M 0 10 L 10 0\" stroke=\"#67e8f9\" stroke-width=\"2\"/></pattern><marker id=\"arrow\" markerWidth=\"7\" markerHeight=\"7\" refX=\"5\" refY=\"3\" orient=\"auto\"><path d=\"M0 0 L6 3 L0 6\" fill=\"#fbbf24\"/></marker></defs>",
    "<rect width=\"960\" height=\"670\" fill=\"#101827\"/>",
    "<g fill=\"white\" font-family=\"sans-serif\"><text x=\"35\" y=\"33\" font-size=\"23\">Imported terrain relief · digital display only</text>",
    "<text x=\"35\" y=\"61\" font-size=\"15\">Azimuth \{azimuth}° from grid +Y clockwise · elevation \{elevation}° · relief ×\{relief}</text>",
    "<text x=\"35\" y=\"86\" font-size=\"13\">Grid +Y up; +X right. Metres. Cell-center surface, NW–SE triangles.</text></g>",
  ]
  for row in 0..<(grid.rows - 1) {
    for col in 0..<(grid.cols - 1) {
      let nw = row * grid.cols + col
      if ![nw, nw + 1, nw + grid.cols, nw + grid.cols + 1].all(i => {
          grid.values[i] is Some(_)
        }) {
        let (x, y) = grid.cell_center(row, col)
        let (x2, y2) = grid.cell_center(row + 1, col + 1)
        svg.push(
          "<rect x=\"\{45.0 + (x - left) * scale}\" y=\"\{120.0 + (top - y) * scale}\" width=\"\{(x2 - x) * scale}\" height=\"\{(y - y2) * scale}\" fill=\"url(#unknown)\"><title>Unknown neighborhood \{row},\{col}</title></rect>",
        )
      }
    }
  }
  for face in faces {
    guard face is Object(fields) &&
      fields.get("vertices_m") is Some(Array(vertices)) &&
      fields.get("gray_8bit") is Some(Number(gray, ..)) else {
      raise InvalidRaster("Invalid relief face")
    }
    let coordinates : Array[String] = []
    for vertex in vertices {
      guard vertex is Array(v) && v[0] is Number(x, ..) && v[1] is Number(y, ..) else {
        raise InvalidRaster("Invalid relief vertex")
      }
      coordinates.push(
        "\{45.0 + (x - left) * scale},\{120.0 + (top - y) * scale}",
      )
    }
    let color = gray.to_int()
    svg.push(
      "<polygon points=\"\{coordinates.join(" ")}\" fill=\"rgb(\{color},\{color},\{color})\"/>",
    )
  }
  if known == 0 {
    svg.push(
      "<text x=\"45\" y=\"510\" fill=\"#fbbf24\" font-family=\"sans-serif\" font-size=\"18\">No supported surface: no complete 2×2 sample neighborhoods.</text>",
    )
  }
  if elevation == 90.0 {
    svg.push(
      "<circle cx=\"875\" cy=\"166\" r=\"35\" fill=\"none\" stroke=\"#64748b\"/><circle cx=\"875\" cy=\"166\" r=\"5\" fill=\"#fbbf24\"/><text x=\"805\" y=\"267\" fill=\"#fbbf24\" font-family=\"sans-serif\" font-size=\"11\">Overhead: no XY direction</text>",
    )
  } else {
    svg.push(
      "<circle cx=\"875\" cy=\"166\" r=\"35\" fill=\"none\" stroke=\"#64748b\"/><path d=\"M875 166 L\{875.0 + lx * 32.0} \{166.0 - ly * 32.0}\" stroke=\"#fbbf24\" stroke-width=\"3\" marker-end=\"url(#arrow)\"/>",
    )
  }
  svg.push(
    "<g fill=\"white\" font-family=\"sans-serif\" font-size=\"13\"><text x=\"850\" y=\"120\">+Y</text><text x=\"916\" y=\"171\">+X</text><text x=\"817\" y=\"223\">Toward assumed light</text><text x=\"817\" y=\"243\">XY projection</text></g>",
  )
  svg.push(
    "<rect x=\"35\" y=\"538\" width=\"25\" height=\"18\" fill=\"url(#unknown)\"/><g fill=\"white\" font-family=\"sans-serif\" font-size=\"14\"><text x=\"72\" y=\"552\">Hatched = unknown; darkness = local diffuse shading, never a cast shadow.</text><text x=\"35\" y=\"578\">\{status} · \{known} complete neighborhoods · \{unknown} unknown · \{faces.length()} triangles</text><text x=\"35\" y=\"604\">No real lunar illumination, source qualification or physical readiness. Keep JSON + CSV.</text></g>",
  )
  svg.push(
    "<text x=\"35\" y=\"637\" fill=\"#cbd5e1\" font-family=\"monospace\" font-size=\"11\">Source \{source_digest}</text></svg>",
  )
  svg.join("\n") + "\n"
}
