///|
/// Trace user-selected elevations across the same complete NW-SE triangulated
/// sample neighborhoods used by the terrain OBJ exporter. These are independent
/// line segments, not smoothed lines or geographic coordinates.
pub fn contour_bundle(
  source_bundle : String,
  levels : Array[Double],
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  need(
    json_text(source, "horizontal_unit") == "m",
    "Contours require metre coordinates",
  )
  need(
    levels.length() > 0 && levels.length() <= 32,
    "Choose 1 through 32 contour elevations",
  )
  let sorted = levels.copy()
  for value in sorted {
    need(finite(value), "Contour elevations must be finite")
  }
  sorted.sort()
  for i in 1..<sorted.length() {
    need(sorted[i] != sorted[i - 1], "Contour elevations must be unique")
  }
  let grid = bundle_grid(source)
  for row in 0..<grid.rows {
    for col in 0..<grid.cols {
      let (x, y) = grid.cell_center(row, col)
      need(finite(x) && finite(y), "Contour centers overflow")
      if col > 0 {
        let (previous, _) = grid.cell_center(row, col - 1)
        need(x > previous, "Contour coordinate centers collapse")
      }
      if row > 0 {
        let (_, previous) = grid.cell_center(row - 1, col)
        need(y < previous, "Contour coordinate centers collapse")
      }
    }
  }
  let (left, bottom) = grid.cell_center(grid.rows - 1, 0)
  let (right, top) = grid.cell_center(0, grid.cols - 1)
  need(
    finite(left) && finite(right) && finite(top) && finite(bottom),
    "Contour coordinates overflow",
  )
  need(
    (grid.cols == 1 || right > left) && (grid.rows == 1 || top > bottom),
    "Contour coordinate centers collapse",
  )
  let width = (right - left).max(grid.cell_size)
  let height = (top - bottom).max(grid.cell_size)
  let scale = (780.0 / width).min(420.0 / height)
  need(finite(scale) && scale > 0.0, "Contour display scale overflows")
  let segments : Array[Json] = []
  let csv = ["level_m,quad_row,quad_col,triangle,x1_m,y1_m,x2_m,y2_m"]
  let svg = [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 900 600\" role=\"img\" aria-label=\"Source-bound terrain contours\">",
    "<rect width=\"900\" height=\"600\" fill=\"#101827\"/>", "<text x=\"40\" y=\"30\" fill=\"white\" font-family=\"sans-serif\" font-size=\"20\">Terrain contour exploration · metres · digital reference only</text>",
  ]
  let colors = [
    "#67e8f9", "#fbbf24", "#a7f3d0", "#f9a8d4", "#c4b5fd", "#fb923c",
  ]
  let mut known_quads = 0
  let mut missing_quads = 0
  for row in 0..<(grid.rows - 1) {
    for col in 0..<(grid.cols - 1) {
      let a = row * grid.cols + col
      if [a, a + 1, a + grid.cols, a + grid.cols + 1].all(i => {
          grid.values[i] is Some(_)
        }) {
        known_quads += 1
      } else {
        missing_quads += 1
        let (x, y) = grid.cell_center(row, col)
        let px = 50.0 + (x - left) * scale
        let py = 55.0 + (top - y) * scale
        let size = grid.cell_size * scale
        svg.push(
          "<rect x=\"\{px}\" y=\"\{py}\" width=\"\{size}\" height=\"\{size}\" fill=\"#475569\" stroke=\"#64748b\" stroke-width=\"0.5\"/>",
        )
      }
    }
  }
  let counts : Array[Json] = []
  for level_index, level in sorted {
    let seen : Map[String, Bool] = Map([])
    let mut count = 0
    let color = colors[level_index % colors.length()]
    for row in 0..<(grid.rows - 1) {
      for col in 0..<(grid.cols - 1) {
        let nw = row * grid.cols + col
        let ne = nw + 1
        let sw = nw + grid.cols
        let se = sw + 1
        if ![nw, ne, sw, se].all(i => grid.values[i] is Some(_)) {
          continue
        }
        for triangle, vertices in [[nw, sw, se], [nw, se, ne]] {
          let hits : Array[(Double, Double)] = []
          // Only an exact level vertex may legitimately be hit by two edges
          // at the same position. Track it independently of rounded positions.
          let exact_vertices : Array[Int] = []
          for edge in 0..<3 {
            let i = vertices[edge]
            let j = vertices[(edge + 1) % 3]
            let zi = grid.values[i].unwrap()
            let zj = grid.values[j].unwrap()
            if (zi <= level && zj > level) || (zj <= level && zi > level) {
              // Orient by elevation so shared edges use identical arithmetic.
              let low = if zi < zj { i } else { j }
              let high = if zi < zj { j } else { i }
              let zl = grid.values[low].unwrap()
              let zh = grid.values[high].unwrap()
              let t = (level - zl) / (zh - zl)
              need(
                finite(t) && t >= 0.0 && t <= 1.0 && finite(zh - zl),
                "Contour interpolation overflows",
              )
              let interior = level > zl
              need(
                !interior || (t > 0.0 && t < 1.0),
                "Contour interior interpolation collapses at this numeric precision",
              )
              let (xl, yl) = grid.cell_center(low / grid.cols, low % grid.cols)
              let (xh, yh) = grid.cell_center(
                high / grid.cols,
                high % grid.cols,
              )
              let x = xl + t * (xh - xl)
              let y = yl + t * (yh - yl)
              need(finite(x) && finite(y), "Contour interpolation overflows")
              need(
                !interior || ((x, y) != (xl, yl) && (x, y) != (xh, yh)),
                "Contour interior coordinates collapse to an edge endpoint",
              )
              hits.push((x, y))
              exact_vertices.push(if interior { -1 } else { low })
            }
          }
          if hits.length() == 2 && hits[0] == hits[1] {
            need(
              exact_vertices[0] >= 0 && exact_vertices[0] == exact_vertices[1],
              "Distinct contour intersections collapse to one coordinate",
            )
          }
          if hits.length() == 2 && hits[0] != hits[1] {
            let (x1, y1) = hits[0]
            let (x2, y2) = hits[1]
            let first = "\{x1},\{y1}"
            let second = "\{x2},\{y2}"
            let key = if first < second {
              first + ";" + second
            } else {
              second + ";" + first
            }
            if seen.contains(key) {
              continue
            }
            seen[key] = true
            count += 1
            need(
              segments.length() < 40000,
              "Contour export exceeds 40000 segments; choose fewer levels or crop the terrain",
            )
            segments.push({
              "level_m": level,
              "quad_row": row,
              "quad_col": col,
              "triangle": triangle + 1,
              "start_m": [x1, y1],
              "end_m": [x2, y2],
            })
            csv.push(
              "\{level},\{row},\{col},\{triangle + 1},\{x1},\{y1},\{x2},\{y2}",
            )
            let px1 = 50.0 + (x1 - left) * scale
            let py1 = 55.0 + (top - y1) * scale
            let px2 = 50.0 + (x2 - left) * scale
            let py2 = 55.0 + (top - y2) * scale
            svg.push(
              "<path d=\"M \{px1} \{py1} L \{px2} \{py2}\" fill=\"none\" stroke=\"\{color}\" stroke-width=\"1.7\"><title>\{level} m; quad \{row},\{col}</title></path>",
            )
            if count == 1 {
              svg.push(
                "<text x=\"\{(px1 + px2) / 2.0 + 4.0}\" y=\"\{(py1 + py2) / 2.0 - 4.0}\" fill=\"\{color}\" font-family=\"sans-serif\" font-size=\"12\">\{level} m</text>",
              )
            }
          }
        }
      }
    }
    counts.push({ "level_m": level, "segments": count })
  }
  svg.push(
    "<text x=\"40\" y=\"515\" fill=\"white\" font-family=\"sans-serif\">Grey: unknown neighborhoods. No contours across gaps. Source +Y is up.</text>",
  )
  svg.push(
    "<text x=\"40\" y=\"542\" fill=\"white\" font-family=\"sans-serif\">\{segments.length()} segments; \{known_quads} complete neighborhoods; \{missing_quads} unknown neighborhoods.</text>",
  )
  svg.push(
    "<text x=\"40\" y=\"570\" fill=\"white\" font-family=\"sans-serif\">NW-SE piecewise-planar interpolation; retain JSON and CSV for levels and source identity.</text></svg>",
  )
  let csv_text = csv.join("\n") + "\n"
  let svg_text = svg.join("\n") + "\n"
  let status = if known_quads == 0 {
    "no-surface"
  } else if segments.is_empty() {
    "no-crossings"
  } else if missing_quads > 0 {
    "partial-coverage"
  } else {
    "sampled-contours"
  }
  {
    "contract_id": "moonmoon.terrain-contours.v1",
    "source_bundle": source,
    "source_bundle_digest": digest(source.stringify()),
    "coordinate_frame": json_text(source, "coordinate_frame"),
    "horizontal_unit": "m",
    "elevation_unit": "m",
    "levels_m": sorted,
    "status": status,
    "complete_quads": known_quads,
    "unknown_quads": missing_quads,
    "segment_count": segments.length(),
    "level_counts": counts,
    "segments": segments,
    "segments_csv": csv_text,
    "segments_csv_digest": digest(csv_text),
    "contour_svg": svg_text,
    "contour_svg_digest": digest(svg_text),
    "interpolation": "complete-quads-nw-se-piecewise-planar-v1",
    "limitations": [
      "Synthetic interpolation between cell centers, not measured contour lines. Source frame and vertical datum remain unverified.",
      "Every 2x2 neighborhood touching NODATA is omitted. No outer half-cell rim, bridging, smoothing or extrapolation.",
      "Saddles follow the declared NW-SE diagonal, not a bilinear surface. Segments are not stitched into paths or polygons.",
      "Equal-level plateaus and isolated level vertices produce no lines. Edges use low-inclusive/high-exclusive crossing with duplicate segments removed.",
      "No geographic reprojection, mission feasibility, robot suitability, engineering accuracy or physical authority.",
    ],
    "physical_readiness": false,
  }
}
