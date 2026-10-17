///|
fn coarsen_svg(
  fine : AsciiGrid,
  coarse : AsciiGrid,
  cells : Array[CoarseCell],
  factor : Int,
) -> String {
  let mut low = 0.0
  let mut high = 0.0
  let mut any = false
  for value in fine.values {
    if value is Some(z) {
      low = if any { low.min(z) } else { z }
      high = if any { high.max(z) } else { z }
      any = true
    }
  }
  let lines = [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1080\" height=\"700\" viewBox=\"0 0 1080 700\" role=\"img\" aria-labelledby=\"title description\">",
    "<title id=\"title\">Fine terrain and coarse overview</title><desc id=\"description\">Side-by-side source elevations and complete-block arithmetic means. Crossed grey blocks withhold any missing source coverage. Reduced relief may hide hazards. Digital overview only.</desc>",
    "<rect width=\"1080\" height=\"700\" fill=\"#101827\"/><g font-family=\"sans-serif\" fill=\"#f8fafc\"><text x=\"30\" y=\"38\" font-size=\"26\">Fine terrain / coarse overview</text><text x=\"30\" y=\"68\" font-size=\"16\">Aligned \{factor} x \{factor} block means. Same extent and shared source elevation scale.</text>",
  ]
  for
    (grid, left, title) in [
      (fine, 30.0, "Original samples"),
      (coarse, 570.0, "Complete-block means"),
    ] {
    let size = (470.0 / grid.cols.to_double()).min(
      420.0 / grid.rows.to_double(),
    )
    let top = 137.0
    lines.push(
      "<text x=\"\{left}\" y=\"114\" font-size=\"19\">\{title}: \{grid.rows} rows x \{grid.cols} columns</text>",
    )
    for index, value in grid.values {
      let row = index / grid.cols
      let col = index % grid.cols
      let x = left + col.to_double() * size
      let y = top + row.to_double() * size
      let color = match value {
        None => "#64748b"
        Some(z) => {
          // Scaling both ends avoids overflow in a wide signed elevation range.
          let fraction = if high == low {
            0.5
          } else if finite(high - low) {
            (z - low) / (high - low)
          } else {
            (z / 2.0 - low / 2.0) / (high / 2.0 - low / 2.0)
          }
          "hsl(\{210.0 - 170.0 * fraction},62%,58%)"
        }
      }
      let detail = if left == 570.0 {
        let cell = cells[index]
        "Known source samples \{cell.known}/\{factor * factor}; observed min \{csv_number(cell.minimum)}, max \{csv_number(cell.maximum)}; mean \{csv_number(cell.mean)}"
      } else {
        "Elevation \{csv_number(value)} m"
      }
      lines.push(
        "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{size}\" height=\"\{size}\" fill=\"\{color}\" stroke=\"#101827\" stroke-width=\"0.6\"><title>row \{row}, col \{col}. \{detail}</title></rect>",
      )
      if value is None {
        lines.push(
          "<path d=\"M \{x} \{y} l \{size} \{size} M \{x + size} \{y} l \{-size} \{size}\" stroke=\"#273449\" stroke-width=\"1.5\"/>",
        )
      }
      if size >= 50.0 {
        lines.push(
          "<text x=\"\{x + size / 2.0}\" y=\"\{y + size / 2.0 + 5.0}\" text-anchor=\"middle\" fill=\"#101827\" font-size=\"13\">\{row},\{col}</text>",
        )
      }
    }
  }
  let range = if any {
    "Observed source range: \{low} to \{high} m. Blue = low, gold = high; flat grids use midpoint color."
  } else {
    "All source elevations unknown; no elevation color range."
  }
  lines.push(
    "<text x=\"30\" y=\"594\" font-size=\"15\">\{range}</text><text x=\"30\" y=\"621\" font-size=\"15\">Crossed grey = unknown or withheld mean. Partial-block extrema are observations, not complete coverage.</text><text x=\"30\" y=\"648\" font-size=\"15\">Rows increase down; columns right. Hover cells for values and valid counts; CSV carries exact coordinates.</text><text x=\"30\" y=\"678\" font-size=\"16\" fill=\"#fbbf24\">Coarsening can hide fine-scale hazards. No navigation authority or physical readiness.</text></g></svg>",
  )
  lines.join("\n") + "\n"
}
