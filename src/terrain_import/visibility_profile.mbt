///|
fn visibility_svg(
  cells : Array[SightCell],
  start_z : Double,
  end_z : Double,
  distance : Double,
  status : String,
  unknown : Int,
) -> String raise ImportError {
  let mut low = start_z.min(end_z)
  let mut high = start_z.max(end_z)
  for cell in cells {
    if cell.elevation is Some(z) {
      low = low.min(z)
      high = high.max(z)
    }
  }
  let span = high - low
  need(finite(span), "Visibility profile elevation range overflows")
  let span = if span == 0.0 { 1.0 } else { span }
  fn y(z : Double) -> Double {
    390.0 - (z - low) / span * 290.0
  }
  let lines = [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"880\" height=\"550\" viewBox=\"0 0 880 550\" role=\"img\" aria-labelledby=\"title description\">",
    "<title id=\"title\">Imported terrain line-of-sight profile</title>",
    "<desc id=\"description\">Constant-height cell spans and the straight elevated sightline. Corner-only contacts are dots. Gray bands or dashed vertical lines indicate unknown coverage. Vertical scale is exaggerated; only clear-in-model has complete coverage and positive clearance. No physical readiness.</desc>",
    "<rect width=\"880\" height=\"550\" fill=\"#111827\"/>",
    "<g font-family=\"sans-serif\" fill=\"#f9fafb\"><text x=\"30\" y=\"30\" font-size=\"22\">Terrain line of sight: \{status}</text><text x=\"30\" y=\"57\" font-size=\"14\">\{distance} m horizontal span; \{unknown} unknown cells. Local flat-grid model.</text></g>",
  ]
  for cell in cells {
    let x0 = 60.0 + cell.entry.value() * 760.0
    let x1 = 60.0 + cell.exit.value() * 760.0
    let label = "row \{cell.row}, col \{cell.col}: \{cell.status}"
    match cell.elevation {
      None => {
        lines.push(
          "<rect x=\"\{x0}\" y=\"85\" width=\"\{x1 - x0}\" height=\"325\" fill=\"#475569\" opacity=\"0.6\"><title>\{label}</title></rect>",
        )
        lines.push(
          "<line x1=\"\{x0}\" x2=\"\{x0}\" y1=\"85\" y2=\"410\" stroke=\"#cbd5e1\" stroke-dasharray=\"4 4\"><title>\{label}</title></line>",
        )
      }
      Some(z) => {
        let color = if cell.status == "blocked" {
          "#fb923c"
        } else if cell.status == "grazing" {
          "#facc15"
        } else {
          "#60a5fa"
        }
        let height = y(z)
        lines.push(
          "<line x1=\"\{x0}\" x2=\"\{x1}\" y1=\"\{height}\" y2=\"\{height}\" stroke=\"\{color}\" stroke-width=\"5\"><title>\{label}; terrain \{z} m</title></line>",
        )
        if sight_compare(cell.entry, cell.exit) == 0 {
          lines.push(
            "<circle cx=\"\{x0}\" cy=\"\{height}\" r=\"4\" fill=\"\{color}\"><title>Corner contact: \{label}</title></circle>",
          )
        }
      }
    }
  }
  lines.push(
    "<line x1=\"60\" y1=\"\{y(start_z)}\" x2=\"820\" y2=\"\{y(end_z)}\" stroke=\"#ffffff\" stroke-width=\"2\"><title>Observer to target sightline</title></line>",
  )
  lines.push(
    "<g font-family=\"sans-serif\" fill=\"#f9fafb\" font-size=\"13\"><text x=\"60\" y=\"435\">Observer, 0 m</text><text x=\"650\" y=\"435\">Target, \{distance} m</text><text x=\"30\" y=\"465\">White: sightline. Orange: blocked. Yellow: grazing. Blue: positive cell clearance.</text><text x=\"30\" y=\"490\">Gray: unknown, including corner contacts. Elevation range: \{low} to \{high} m.</text><text x=\"30\" y=\"520\">Vertical exaggeration; no curvature, radio link, illumination or physical-readiness claim.</text></g></svg>",
  )
  lines.join("\n") + "\n"
}
