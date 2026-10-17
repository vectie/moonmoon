///|
fn reachability_svg(
  grid : AsciiGrid,
  costs : Array[Double?],
  start : Int,
  budget : Double,
) -> String {
  let size = (720.0 / grid.cols.to_double()).min(510.0 / grid.rows.to_double())
  let left = (880.0 - grid.cols.to_double() * size) / 2.0
  let top = 110.0
  let lines = [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"880\" height=\"780\" viewBox=\"0 0 880 780\" role=\"img\" aria-labelledby=\"title description\">",
    "<title id=\"title\">Terrain destination cost explorer</title>",
    "<desc id=\"description\">Green cells fit the one-way objective-cost budget; amber cells connect but exceed it. Red known cells are not connected in this graph. Crossed gray cells are unknown. Source rows increase down and columns right. Not physical traversability.</desc>",
    "<rect width=\"880\" height=\"780\" fill=\"#101827\"/>",
    "<g font-family=\"sans-serif\" fill=\"#f8fafc\"><text x=\"30\" y=\"34\" font-size=\"23\">Terrain destination cost explorer</text><text x=\"30\" y=\"61\" font-size=\"15\">Budget: \{budget} one-way metre-equivalent units. Hover cells for cost and row/column.</text><text x=\"30\" y=\"84\" font-size=\"14\">White circle = start. Rows increase down; columns right. Coordinates remain in the declared frame.</text></g>",
  ]
  for index, elevation in grid.values {
    let row = index / grid.cols
    let col = index % grid.cols
    let x = left + col.to_double() * size
    let y = top + row.to_double() * size
    let cost = costs[index]
    let status = reachability_status(elevation, cost, budget)
    let color = match status {
      "unknown" => "#64748b"
      "not-connected-in-model" => "#bc4b58"
      "over-budget" => "#b88a38"
      _ => {
        let fraction = if budget == 0.0 {
          0.0
        } else {
          cost.unwrap_or(0.0) / budget
        }
        let light = 65.0 - 35.0 * fraction
        "hsl(156,60%,\{light}%)"
      }
    }
    let cost_text = cost
      .map(c => "\{c} metre-equivalent")
      .unwrap_or("unavailable")
    lines.push(
      "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{size}\" height=\"\{size}\" fill=\"\{color}\" stroke=\"#101827\" stroke-width=\"0.6\"><title>row \{row}, col \{col}: \{status}; minimum cost \{cost_text}</title></rect>",
    )
    if elevation is None {
      lines.push(
        "<path d=\"M \{x} \{y} l \{size} \{size} M \{x + size} \{y} l \{-size} \{size}\" stroke=\"#233047\" stroke-width=\"1\"/>",
      )
    }
    if size >= 35.0 {
      lines.push(
        "<text x=\"\{x + size * 0.5}\" y=\"\{y + size * 0.65}\" text-anchor=\"middle\" fill=\"#101827\" font-family=\"sans-serif\" font-size=\"12\">\{row},\{col}</text>",
      )
    }
  }
  let sx = left + ((start % grid.cols).to_double() + 0.5) * size
  let sy = top + ((start / grid.cols).to_double() + 0.3) * size
  let radius = (size * 0.15).min(9.0).max(2.0)
  lines.push(
    "<circle cx=\"\{sx}\" cy=\"\{sy}\" r=\"\{radius}\" fill=\"white\" stroke=\"#101827\" stroke-width=\"2\"><title>Start row \{start / grid.cols}, col \{start % grid.cols}</title></circle>",
  )
  for
    (y, color, text) in [
      (
        651, "#42b58a", "Within budget: known-cell destinations (including start), boundary inclusive",
      ),
      (
        676, "#b88a38", "Over budget: connected, but minimum one-way objective cost is too high",
      ),
      (
        701, "#bc4b58", "Not connected in model: known cell; grade limits or coverage may prevent a path",
      ),
      (
        726, "#64748b", "Unknown: no elevation and no cost. Gaps are never filled.",
      ),
    ] {
    lines.push(
      "<rect x=\"30\" y=\"\{y - 12}\" width=\"15\" height=\"15\" fill=\"\{color}\"/><text x=\"55\" y=\"\{y}\" fill=\"#f8fafc\" font-family=\"sans-serif\" font-size=\"14\">\{text}</text>",
    )
  }
  lines.push(
    "<text x=\"30\" y=\"759\" fill=\"#cbd5e1\" font-family=\"sans-serif\" font-size=\"14\">One-way model only. No energy, return allowance, clearance, mission acceptance or physical readiness.</text></svg>",
  )
  lines.join("\n") + "\n"
}
