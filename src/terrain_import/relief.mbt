///|
/// Shade the imported sample surface with a caller-declared directional light.
/// Azimuth is clockwise from grid +Y toward +X; elevation is above the grid
/// plane. Relief scale affects display normals only, never source elevations.
/// Each shaded triangle requires all four samples in its NW-SE split quad.
pub fn relief_bundle(
  source_bundle : String,
  azimuth_deg : Double,
  elevation_deg : Double,
  relief_scale : Double,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  need(
    json_text(source, "horizontal_unit") == "m",
    "Relief requires declared metre coordinates",
  )
  need(
    finite(azimuth_deg) && azimuth_deg >= 0.0 && azimuth_deg < 360.0,
    "Light azimuth must be finite in [0, 360) degrees",
  )
  need(
    finite(elevation_deg) && elevation_deg >= 0.0 && elevation_deg <= 90.0,
    "Light elevation must be finite in [0, 90] degrees",
  )
  need(
    finite(relief_scale) && relief_scale >= 0.0 && relief_scale <= 100.0,
    "Display relief scale must be finite in [0, 100]",
  )
  let grid = bundle_grid(source)
  let azimuth = azimuth_deg * @math.PI / 180.0
  let elevation = elevation_deg * @math.PI / 180.0
  let horizontal = if elevation_deg == 90.0 {
    0.0
  } else {
    @math.cos(elevation)
  }
  let lx = horizontal * @math.sin(azimuth)
  let ly = horizontal * @math.cos(azimuth)
  let lz = @math.sin(elevation)
  let points : Array[(Double, Double)] = []
  for row in 0..<grid.rows {
    for col in 0..<grid.cols {
      let (x, y) = grid.cell_center(row, col)
      need(finite(x) && finite(y), "Relief coordinates overflow")
      let i = row * grid.cols + col
      need(
        (col == 0 || x > points[i - 1].0) &&
        (row == 0 || y < points[i - grid.cols].1),
        "Relief source coordinate centers collapse",
      )
      points.push((x, y))
    }
  }
  let faces : Array[Json] = []
  let csv = [
    "quad_row,quad_col,triangle,coverage,normal_x,normal_y,normal_z,diffuse,display_intensity,gray_8bit",
  ]
  let mut known = 0
  let mut unknown = 0
  for row in 0..<(grid.rows - 1) {
    for col in 0..<(grid.cols - 1) {
      let nw = row * grid.cols + col
      let ne = nw + 1
      let sw = nw + grid.cols
      let se = sw + 1
      if ![nw, ne, sw, se].all(i => grid.values[i] is Some(_)) {
        unknown += 1
        csv.push("\{row},\{col},,unknown,,,,,,")
        continue
      }
      known += 1
      let dx = points[ne].0 - points[nw].0
      let dy = points[nw].1 - points[sw].1
      need(
        finite(dx) && finite(dy) && dx > 0.0 && dy > 0.0,
        "Relief neighborhood spacing overflows",
      )
      for triangle, vertices in [[nw, sw, se], [nw, se, ne]] {
        let dzx = if triangle == 0 {
          grid.values[se].unwrap() - grid.values[sw].unwrap()
        } else {
          grid.values[ne].unwrap() - grid.values[nw].unwrap()
        }
        let dzy = if triangle == 0 {
          grid.values[nw].unwrap() - grid.values[sw].unwrap()
        } else {
          grid.values[ne].unwrap() - grid.values[se].unwrap()
        }
        need(
          finite(dzx) && finite(dzy),
          "Relief elevation differences overflow",
        )
        let gx = dzx / dx * relief_scale
        let gy = dzy / dy * relief_scale
        let length = @math.hypot(@math.hypot(gx, gy), 1.0)
        need(
          finite(gx) && finite(gy) && finite(length),
          "Relief normals overflow; reduce display relief or rescale the source",
        )
        let nx = -gx / length
        let ny = -gy / length
        let nz = 1.0 / length
        let diffuse = (nx * lx + ny * ly + nz * lz).max(0.0).min(1.0)
        let intensity = 0.15 + 0.85 * diffuse
        let gray = @math.floor(intensity * 255.0 + 0.5).to_int()
        faces.push({
          "quad_row": row,
          "quad_col": col,
          "triangle": triangle + 1,
          "vertices_m": vertices.map(i => {
            [points[i].0, points[i].1, grid.values[i].unwrap()]
          }),
          "display_normal": [nx, ny, nz],
          "diffuse": diffuse,
          "display_intensity": intensity,
          "gray_8bit": gray,
        })
        csv.push(
          "\{row},\{col},\{triangle + 1},known,\{nx},\{ny},\{nz},\{diffuse},\{intensity},\{gray}",
        )
      }
    }
  }
  let status = if known == 0 {
    "no-surface"
  } else if unknown > 0 {
    "partial-surface"
  } else {
    "complete-sampled-surface"
  }
  let source_digest = digest(source.stringify())
  let parameters : Json = {
    "light_azimuth_deg": azimuth_deg,
    "light_elevation_deg": elevation_deg,
    "display_relief_scale": relief_scale,
    "ambient_fraction": 0.15,
  }
  let identity : Json = {
    "source_bundle_digest": source_digest,
    "parameters": parameters,
    "algorithm": "complete-quads-nw-se-lambert-v1",
  }
  let relief_digest = digest(identity.stringify())
  let svg = relief_svg(
    grid, faces, azimuth_deg, elevation_deg, relief_scale, lx, ly, known, unknown,
    status, source_digest,
  )
  let csv_text = csv.join("\n") + "\n"
  let report = [
    "# Imported terrain relief shading",
    "",
    "Status: " + status,
    "Source bundle: " + source_digest,
    "Relief study: " + relief_digest,
    "Declared frame (unverified): " + json_text(source, "coordinate_frame"),
    "",
    "Light azimuth: \{azimuth_deg} degrees clockwise from source +Y toward +X; elevation: \{elevation_deg} degrees above the XY plane.",
    "Display relief scale: \{relief_scale}; original metre elevations are retained unchanged. Zero flattens display normals only.",
    "Light vector points from the surface toward the assumed light: (\{lx}, \{ly}, \{lz}).",
    "Per-triangle upward normal = normalize(-scale * dz/dx, -scale * dz/dy, 1). Diffuse = max(0, normal dot light).",
    "Display intensity = 0.15 + 0.85 * diffuse. Gray byte = floor(255 * intensity + 0.5); no gamma or albedo model.",
    "",
    "Complete neighborhoods: \{known}; unknown neighborhoods: \{unknown}; shaded triangles: \{faces.length()}.",
    "Open relief.svg for the map, relief-faces.csv for normals and intensities, and terrain-relief.json for full source and replay parameters.",
    "Compare another light direction or relief scale by writing a new output directory. Compare a revision by shading its terrain-import.json with the same parameters.",
    "",
    "## Limits",
    "Source +Y is up and +X is right in the SVG. Grid axes are caller declarations, not inferred geographic north/east.",
    "Each complete 2x2 neighborhood has two flat triangles split NW-SE, matching the existing OBJ/contour display convention.",
    "Every neighborhood touching NODATA is hatched unknown. There is no bridging, smoothing or outer half-cell rim.",
    "No surface means there are no supported 2D neighborhoods, including one-row or one-column rasters.",
    "This is local directional diffuse shading, not real lunar illumination, cast shadows, horizon occlusion or visibility.",
    "Relief exaggeration affects appearance only. Source frame, vertical datum, terrain truth and coverage are unverified.",
    "No navigation, energy, mission acceptance, robot suitability or physical readiness is established.",
    "",
  ].join("\n")
  let result : Json = {
    "contract_id": "moonmoon.terrain-relief.v1",
    "source_bundle": source,
    "source_bundle_digest": source_digest,
    "relief_digest": relief_digest,
    "coordinate_frame": json_text(source, "coordinate_frame"),
    "horizontal_unit": "m",
    "elevation_unit": "m",
    "axis_convention": "source-x/source-y/z-up",
    "light_convention": "clockwise-from-grid-positive-y-toward-positive-x; elevation-above-xy; vector-toward-light",
    "light_vector": [lx, ly, lz],
    "parameters": parameters,
    "algorithm": "complete-quads-nw-se-lambert-v1",
    "status": status,
    "complete_quads": known,
    "unknown_quads": unknown,
    "triangle_count": faces.length(),
    "faces": faces,
    "faces_csv": csv_text,
    "faces_csv_digest": digest(csv_text),
    "relief_svg": svg,
    "relief_svg_digest": digest(svg),
    "report_markdown": report,
    "report_digest": digest(report),
    "physical_readiness": false,
  }
  need(
    result.stringify(indent=2).length() + 1 <= 16777216,
    "Relief bundle exceeds 16 MiB character limit; crop the terrain",
  )
  result
}

///|
/// Verify retained relief parameters, source, numeric results and all exports
/// by recomputing the complete study. JSON whitespace/key order may differ.
pub fn reopen_relief_bundle(text : String) -> Json raise ImportError {
  need(
    text.length() <= 16777216,
    "Relief bundle exceeds 16 MiB character limit",
  )
  let saved = @json.parse(text) catch {
    _ => raise InvalidRaster("Invalid relief JSON")
  }
  guard saved is Object(fields) &&
    fields.get("source_bundle") is Some(source) &&
    fields.get("parameters") is Some(Object(parameters)) else {
    raise InvalidRaster("Relief requires its source bundle and parameters")
  }
  fn parameter(name : String) -> Double raise ImportError {
    guard parameters.get(name) is Some(Number(value, ..)) else {
      raise InvalidRaster("Missing relief parameter " + name)
    }
    value
  }
  let expected = relief_bundle(
    source.stringify(),
    parameter("light_azimuth_deg"),
    parameter("light_elevation_deg"),
    parameter("display_relief_scale"),
  )
  need(
    saved == expected,
    "Relief differs from its recomputed source, parameters or outputs",
  )
  expected
}
