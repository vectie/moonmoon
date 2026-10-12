///|
fn corridor_svg(
  grid : AsciiGrid,
  path : Array[Int],
  selected : Array[Bool],
  estimates : Array[CellEstimate?],
  roughness_limit : Double,
  outside : Int,
) -> String {
  let size = (720.0 / grid.cols.to_double()).min(520.0 / grid.rows.to_double())
  let left = (860.0 - grid.cols.to_double() * size) / 2.0
  let top = 85.0
  let lines = [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"860\" height=\"760\" viewBox=\"0 0 860 760\" role=\"img\" aria-labelledby=\"title description\">",
    "<title id=\"title\">Terrain corridor screening</title>", "<desc id=\"description\">Square cell windows around the exact ordered path. Orange cells exceed a shape threshold; crossed gray cells have unknown shape. Blue cells have estimates within both limits. Outside-grid cells are counted but cannot be shown on this clipped map. No physical readiness.</desc>",
    "<rect width=\"860\" height=\"760\" fill=\"#111827\"/>", "<g font-family=\"sans-serif\" fill=\"#f9fafb\"><text x=\"28\" y=\"30\" font-size=\"22\">Terrain corridor screening</text><text x=\"28\" y=\"55\" font-size=\"14\">Rows increase down; columns right. White line: exact submitted path.</text></g>",
  ]
  for index, included in selected {
    let x = left + (index % grid.cols).to_double() * size
    let y = top + (index / grid.cols).to_double() * size
    let (color, label, unknown) = if !included {
      ("#1f2937", "outside selected corridor", false)
    } else {
      match estimates[index] {
        Some({ slope: Some(_), roughness: Some(r), screening, .. }) =>
          if screening == "threshold-exceeded" || r > roughness_limit {
            ("#fb923c", "known threshold exceedance", false)
          } else {
            ("#60a5fa", "estimated within thresholds", false)
          }
        _ => ("#94a3b8", "unknown shape estimate", true)
      }
    }
    lines.push(
      "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{size}\" height=\"\{size}\" fill=\"\{color}\" stroke=\"#111827\" stroke-width=\"0.5\"><title>row \{index / grid.cols}, col \{index % grid.cols}: \{label}</title></rect>",
    )
    if unknown {
      lines.push(
        "<path d=\"M \{x} \{y} l \{size} \{size} M \{x + size} \{y} l \{-size} \{size}\" stroke=\"#334155\" stroke-width=\"1\"/>",
      )
    }
  }
  let points = path
    .map(index => {
      let x = left + ((index % grid.cols).to_double() + 0.5) * size
      let y = top + ((index / grid.cols).to_double() + 0.5) * size
      "\{x},\{y}"
    })
    .join(" ")
  lines.push(
    "<polyline points=\"\{points}\" fill=\"none\" stroke=\"#111827\" stroke-width=\"6\"/><polyline points=\"\{points}\" fill=\"none\" stroke=\"#ffffff\" stroke-width=\"3\"/>",
  )
  let start = path[0]
  let start_x = left + ((start % grid.cols).to_double() + 0.5) * size
  let start_y = top + ((start / grid.cols).to_double() + 0.5) * size
  let radius = (size * 0.2).min(8.0).max(2.0)
  lines.push(
    "<circle cx=\"\{start_x}\" cy=\"\{start_y}\" r=\"\{radius}\" fill=\"white\" stroke=\"#111827\" stroke-width=\"2\"><title>First path occurrence</title></circle>",
  )
  lines.push(
    "<g font-family=\"sans-serif\" fill=\"#f9fafb\" font-size=\"14\"><text x=\"28\" y=\"645\">Orange: threshold exceeded. Blue: estimated within both thresholds.</text><text x=\"28\" y=\"670\">Crossed gray: unknown shape. Dark: outside selected corridor.</text><text x=\"28\" y=\"695\">Outside this grid: \{outside} distinct requested cells. See the report for coverage.</text><text x=\"28\" y=\"720\">Square sample band only; no robot footprint, clearance, energy or physical readiness.</text><text x=\"28\" y=\"745\">Local 3x3 shape uses source neighbors, including cells outside the band.</text></g></svg>",
  )
  lines.join("\n") + "\n"
}
