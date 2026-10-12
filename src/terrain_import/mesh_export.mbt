///|
/// Export source-bound Wavefront OBJ reference geometry. Only fully known 2x2
/// sample neighborhoods produce faces; unknown samples and their quads remain
/// holes. X/Y are translated to the lower-left sample center, Z is unscaled
/// source elevation in metres. The source frame is retained in the sidecar.
pub fn export_mesh_bundle(source_bundle : String) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  need(
    json_text(source, "horizontal_unit") == "m",
    "Terrain mesh requires declared metre coordinates; reproject degree grids separately",
  )
  let grid = bundle_grid(source)
  let (offset_x, offset_y) = grid.cell_center(grid.rows - 1, 0)
  need(finite(offset_x) && finite(offset_y), "Mesh origin overflows")
  let source_digest = digest(source.stringify())
  let obj_lines = [
    "# MoonMoon source-bound reference terrain; no physical readiness claim",
    "# Metres; Z-up; positive X/Y follow the declared source frame",
    "# Source X = OBJ X + \{offset_x}; source Y = OBJ Y + \{offset_y}; source elevation = OBJ Z",
    "# Sample centers only; complete 2x2 neighborhoods; NW-SE diagonal; upward winding",
    "# Missing samples omit entire neighboring quads; no outer half-cell rim or solid base",
    "# Source bundle " + source_digest,
    "o terrain",
  ]
  let vertex_indices = Array::make(grid.values.length(), 0)
  let used = Array::make(grid.values.length(), false)
  let local_x : Array[Double] = []
  let local_y : Array[Double] = []
  let source_x : Array[Double] = []
  let source_y : Array[Double] = []
  let mut vertices = 0
  for i, elevation in grid.values {
    let row = i / grid.cols
    let col = i % grid.cols
    let (x, y) = grid.cell_center(row, col)
    let lx = x - offset_x
    let ly = y - offset_y
    need(
      finite(x) && finite(y) && finite(lx) && finite(ly),
      "Mesh coordinates overflow; use a representable source grid",
    )
    need(
      (col == 0 || (x > source_x[i - 1] && lx > local_x[i - 1])) &&
      (row == 0 || (y < source_y[i - grid.cols] && ly < local_y[i - grid.cols])),
      "Mesh source centers collapse at this origin and spacing",
    )
    source_x.push(x)
    source_y.push(y)
    local_x.push(lx)
    local_y.push(ly)
    if elevation is Some(z) {
      vertices += 1
      vertex_indices[i] = vertices
      obj_lines.push("v \{lx} \{ly} \{z}")
    }
  }
  let mut quads = 0
  let face_lines = [
    "obj_face_index,quad_row,quad_col,triangle,vertex_1,vertex_2,vertex_3",
  ]
  for row in 0..<(grid.rows - 1) {
    for col in 0..<(grid.cols - 1) {
      let nw = row * grid.cols + col
      let ne = nw + 1
      let sw = nw + grid.cols
      let se = sw + 1
      let a = vertex_indices[nw]
      let b = vertex_indices[ne]
      let c = vertex_indices[sw]
      let d = vertex_indices[se]
      // Do not salvage a half-quad: all four source samples must be known.
      if a > 0 && b > 0 && c > 0 && d > 0 {
        obj_lines.push("f \{a} \{c} \{d}")
        obj_lines.push("f \{a} \{d} \{b}")
        face_lines.push("\{quads * 2 + 1},\{row},\{col},1,\{a},\{c},\{d}")
        face_lines.push("\{quads * 2 + 2},\{row},\{col},2,\{a},\{d},\{b}")
        for index in [nw, ne, sw, se] {
          used[index] = true
        }
        quads += 1
      }
    }
  }
  let cells = [
    "row,col,source_x_m,source_y_m,elevation_m,obj_vertex_index,obj_x_m,obj_y_m,used_by_face,coverage",
  ]
  let mut unreferenced = 0
  for i, elevation in grid.values {
    let row = i / grid.cols
    let col = i % grid.cols
    let x = source_x[i]
    let y = source_y[i]
    let lx = local_x[i]
    let ly = local_y[i]
    match elevation {
      Some(z) => {
        if !used[i] {
          unreferenced += 1
        }
        let index = vertex_indices[i]
        let used_by_face = used[i]
        cells.push(
          "\{row},\{col},\{x},\{y},\{z},\{index},\{lx},\{ly},\{used_by_face},known",
        )
      }
      None => cells.push("\{row},\{col},\{x},\{y},,,,,false,unknown")
    }
  }
  let possible_quads = (grid.rows - 1) * (grid.cols - 1)
  let missing_quads = possible_quads - quads
  let status = if quads == 0 {
    "no-surface"
  } else if missing_quads > 0 {
    "partial-surface"
  } else {
    "complete-sampled-surface"
  }
  let obj = obj_lines.join("\n") + "\n"
  let cells_csv = cells.join("\n") + "\n"
  let faces_csv = face_lines.join("\n") + "\n"
  let report = [
    "# Source-bound terrain OBJ export",
    "",
    "Status: " + status,
    "",
    "Source bundle: " + source_digest,
    "Declared source frame (unverified): " +
    json_text(source, "coordinate_frame"),
    "Geometry: metres on all axes; Z up. Positive X/Y follow the source frame.",
    "Source X = OBJ X + \{offset_x}; source Y = OBJ Y + \{offset_y}; source elevation = OBJ Z.",
    "Vertical datum is caller-declared/unverified; Z is not rebased or exaggerated.",
    "",
    "Known vertices: \{vertices}; unknown samples: \{grid.values.length() - vertices}.",
    "Exported quads: \{quads} of \{possible_quads}; omitted unknown quads: \{missing_quads}; triangles: \{quads * 2}.",
    "Known vertices unused by any face: \{unreferenced}. Some viewers hide isolated vertices.",
    "",
    "Open terrain.obj in a Wavefront OBJ viewer; set metres and Z-up explicitly if asked.",
    "mesh-cells.csv maps every source sample to its 1-based OBJ vertex index (blank for unknown).",
    "mesh-faces.csv maps each 1-based OBJ face to its source 2x2 neighborhood.",
    "Triangles use the NW-SE diagonal with upward winding. Each requires all four quad samples.",
    "",
    "## Limits",
    "Triangles are a piecewise-planar display assumption between declared samples, not new observations.",
    "Missing data creates holes; no bridging, gap filling, extrapolation, skirts or solid base.",
    "The mesh spans sample centers only, excluding the raster's outer half-cell rim.",
    "No UVs, materials or vertex normals are supplied. OBJ has no authoritative CRS or units metadata; keep the JSON and CSV sidecars.",
    "An empty-face export is not a usable surface. A complete sampled surface is not proof of complete real-world coverage.",
    "Source, frame, vertical datum and terrain truth are unverified. No robot suitability, mission acceptance or physical authority.",
    "",
  ].join("\n")
  let result : Json = {
    "contract_id": "moonmoon.terrain-mesh.v1",
    "format": "wavefront-obj",
    "status": status,
    "source_bundle": source,
    "source_bundle_digest": source_digest,
    "coordinate_frame": json_text(source, "coordinate_frame"),
    "horizontal_unit": "m",
    "vertical_unit": "m",
    "axis_convention": "source-x/source-y/z-up",
    "source_translation_m": { "x": offset_x, "y": offset_y, "z": 0 },
    "vertex_order": "known-samples-top-to-bottom-row-major",
    "index_base": 1,
    "triangulation": "complete-quads-nw-se-upward-v1",
    "extent": "sample-centers-only",
    "counts": {
      "source_cells": grid.values.length(),
      "known_vertices": vertices,
      "unknown_samples": grid.values.length() - vertices,
      "possible_quads": possible_quads,
      "exported_quads": quads,
      "omitted_unknown_quads": missing_quads,
      "triangles": quads * 2,
      "unreferenced_vertices": unreferenced,
    },
    "obj_text": obj,
    "obj_digest": digest(obj),
    "cells_csv": cells_csv,
    "cells_csv_digest": digest(cells_csv),
    "faces_csv": faces_csv,
    "faces_csv_digest": digest(faces_csv),
    "report_markdown": report,
    "report_digest": digest(report),
    "physical_readiness": false,
  }
  need(
    result.stringify(indent=2).length() + 1 <= 8388608,
    "Terrain mesh bundle exceeds 8 MiB character limit",
  )
  result
}

///|
/// Verify a saved mesh by recomputing its source, geometry, maps and report.
/// JSON whitespace/key order may change; any changed content is refused.
pub fn reopen_mesh_bundle(text : String) -> Json raise ImportError {
  need(
    text.length() <= 8388608,
    "Terrain mesh bundle exceeds 8 MiB character limit",
  )
  let saved = @json.parse(text) catch {
    _ => raise InvalidRaster("Invalid terrain mesh JSON")
  }
  guard saved is Object(fields) && fields.get("source_bundle") is Some(source) else {
    raise InvalidRaster("Terrain mesh requires its source bundle")
  }
  let expected = export_mesh_bundle(source.stringify())
  need(
    saved == expected,
    "Terrain mesh differs from its recomputed source or outputs",
  )
  expected
}
