///|
// Only numeric values and fixed labels enter markup, never source metadata.
fn area_change_svg(
  grid : AsciiGrid,
  cells : Array[Json],
  threshold : Double,
) -> String raise ImportError {
  let size = (720.0 / grid.cols.to_double()).min(500.0 / grid.rows.to_double())
  let left = (860.0 - grid.cols.to_double() * size) / 2.0
  let lines = [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"860\" height=\"790\" viewBox=\"0 0 860 790\" role=\"img\" aria-labelledby=\"title description\">",
    "<title id=\"title\">Whole-area terrain change</title>",
    "<desc id=\"description\">Candidate minus reference. Orange rises and blue falls exceed the declared threshold. Pale cells are within threshold. Green gained coverage, red lost coverage and gray unknown in both are crossed because no difference is known. Every square is one source cell.</desc>",
    "<rect width=\"860\" height=\"790\" fill=\"#111827\"/>",
    "<g font-family=\"sans-serif\" fill=\"#f9fafb\"><text x=\"28\" y=\"30\" font-size=\"22\">Whole-area terrain change</text><text x=\"28\" y=\"56\" font-size=\"14\">Candidate minus reference. Threshold: \{threshold} m. Equality is within threshold.</text><text x=\"28\" y=\"78\" font-size=\"14\">Rows increase down toward source -y; columns right toward source +x.</text></g>",
  ]
  for index, cell in cells {
    let coverage = json_text(cell, "coverage_change")
    let kind = json_text(cell, "change_class")
    let color = match coverage {
      "coverage-gained" => "#86efac"
      "coverage-lost" => "#fda4af"
      "unknown-both" => "#94a3b8"
      _ =>
        match kind {
          "rise-exceeds-threshold" => "#fb923c"
          "fall-exceeds-threshold" => "#60a5fa"
          _ => "#e2e8f0"
        }
    }
    let delta = csv_number(
      comparison_number(comparison_field(cell, "elevation_delta_m")),
    )
    let x = left + (index % grid.cols).to_double() * size
    let y = 100.0 + (index / grid.cols).to_double() * size
    lines.push(
      "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{size}\" height=\"\{size}\" fill=\"\{color}\" stroke=\"#111827\" stroke-width=\"0.5\"><title>row \{index / grid.cols}, col \{index % grid.cols}: \{coverage}; \{kind}; delta m: \{delta}</title></rect>",
    )
    if coverage != "known-both" {
      lines.push(
        "<path d=\"M \{x} \{y} l \{size} \{size} M \{x + size} \{y} l \{-size} \{size}\" stroke=\"#334155\" stroke-width=\"1\"/>",
      )
    }
  }
  lines.push(
    "<g font-family=\"sans-serif\" fill=\"#f9fafb\" font-size=\"14\"><text x=\"28\" y=\"630\">Orange: rise exceeds threshold. Blue: fall exceeds threshold.</text><text x=\"28\" y=\"655\">Pale: known difference within threshold, including zero.</text><text x=\"28\" y=\"680\">Crossed green: gained coverage. Crossed red: lost coverage.</text><text x=\"28\" y=\"705\">Crossed gray: unknown in both. Crossed cells have no delta or volume.</text><text x=\"28\" y=\"735\">See CSV for exact values. Colors indicate classes, not magnitude or significance.</text><text x=\"28\" y=\"760\">Declared square-cell model only. No terrain truth or physical readiness claim.</text></g></svg>",
  )
  lines.join("\n") + "\n"
}
