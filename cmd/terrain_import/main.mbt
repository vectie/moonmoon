///|
fn run() -> Unit raise {
  match @env.args()[1:] {
    ["crop", path, output, row, col, rows, cols, tile_id, reason] => {
      let result = @raster.crop_bundle(
        @fsx.read_file_to_string(path),
        @string.parse_int(row),
        @string.parse_int(col),
        @string.parse_int(rows),
        @string.parse_int(cols),
        tile_id,
        reason,
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard result is Object(fields) &&
        fields.get("terrain_bundle") is Some(terrain) else {
        fail("Invalid terrain crop")
      }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("source.asc", "ascii_grid_text"),
          ("crop-cells.csv", "cells_csv"),
          ("crop-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing crop output " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-import.json",
        terrain.stringify(indent=2) + "\n",
      )
      @fsx.write_string_to_file(
        output + "/terrain-crop.json",
        result.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-import.json")
      println(
        "Exact study clip exported; retain terrain-crop.json for parent provenance. Use clip row/column indices; boundary analyses may change.",
      )
    }
    ["reopen-crop", path] =>
      println(
        @raster.reopen_crop_bundle(@fsx.read_file_to_string(path)).stringify(
          indent=2,
        ),
      )
    ["export-mesh", path, output] => {
      let result = @raster.export_mesh_bundle(@fsx.read_file_to_string(path))
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard result is Object(fields) else { fail("Invalid terrain mesh") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("terrain.obj", "obj_text"),
          ("mesh-cells.csv", "cells_csv"),
          ("mesh-faces.csv", "faces_csv"),
          ("mesh-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing mesh output " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-mesh.json",
        result.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-mesh.json")
      guard fields.get("status") is Some(String(status)) else {
        fail("Missing mesh status")
      }
      println(
        status +
        ": open terrain.obj with metres and Z-up; retain sidecars. Unknown neighborhoods remain holes; reference geometry only.",
      )
    }
    ["reopen-mesh", path] =>
      println(
        @raster.reopen_mesh_bundle(@fsx.read_file_to_string(path)).stringify(
          indent=2,
        ),
      )
    ["compare-area", reference, candidate, output, threshold] => {
      let result = @raster.compare_area_bundle(
        @fsx.read_file_to_string(reference),
        @fsx.read_file_to_string(candidate),
        @string.parse_double(threshold),
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard result is Object(fields) else { fail("Invalid area comparison") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("area-changes.csv", "changes_csv"),
          ("area-change.svg", "change_map_svg"),
          ("area-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing area comparison output " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-area-comparison.json",
        result.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-area-comparison.json")
      guard fields.get("status") is Some(String(status)) else {
        fail("Missing area comparison status")
      }
      println(
        status +
        ": inspect area-change.svg and area-changes.csv. Model-based input differences; no physical change or readiness claim.",
      )
    }
    ["energy-path", path, cells_path, assumptions_path, output] => {
      let result = @raster.path_energy_bundle(
        @fsx.read_file_to_string(path),
        @fsx.read_file_to_string(cells_path),
        @fsx.read_file_to_string(assumptions_path),
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard result is Object(fields) else { fail("Invalid path energy report") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("energy-segments.csv", "segments_csv"),
          ("energy-report.md", "report_markdown"),
          ("assumptions.json", "assumptions_text"),
          ("inputs-path.txt", "input_path_text"),
          ("path-cells.txt", "path_cells_text"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing energy output " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-path-energy.json",
        result.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-path-energy.json")
      guard fields.get("status") is Some(String(status)) else {
        fail("Missing energy status")
      }
      println(
        status +
        ": inspect energy-segments.csv and energy-report.md. Declared rates only; no mission acceptance or physical readiness.",
      )
      guard fields.get("grade_screening") is Some(String(grade_status)) else {
        fail("Missing grade screen")
      }
      println("Independent grade screening: " + grade_status)
    }
    [
      "visibility",
      path,
      output,
      observer_row,
      observer_col,
      target_row,
      target_col,
      observer_height,
      target_height,
    ] => {
      let result = @raster.visibility_bundle(
        @fsx.read_file_to_string(path),
        @string.parse_int(observer_row),
        @string.parse_int(observer_col),
        @string.parse_int(target_row),
        @string.parse_int(target_col),
        @string.parse_double(observer_height),
        @string.parse_double(target_height),
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard result is Object(fields) else { fail("Invalid visibility report") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("visibility-cells.csv", "cells_csv"),
          ("visibility-profile.svg", "profile_svg"),
          ("visibility-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing visibility field " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/visibility.json",
        result.stringify(indent=2) + "\n",
      )
      println(output + "/visibility.json")
      guard fields.get("status") is Some(String(status)) else {
        fail("Missing visibility status")
      }
      println(
        status +
        ": inspect visibility-profile.svg and visibility-cells.csv. Local geometric model only; no radio, illumination or physical readiness claim.",
      )
    }
    ["mosaic", left_path, right_path, output, tile_id, note] => {
      let bundle = @raster.mosaic_bundle(
        @fsx.read_file_to_string(left_path),
        @fsx.read_file_to_string(right_path),
        tile_id,
        note,
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard bundle is Object(fields) else { fail("Invalid terrain mosaic") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("terrain.csv", "terrain_csv"),
          ("mosaic-cells.csv", "mosaic_cells_csv"),
          ("mosaic-report.md", "report_markdown"),
          ("source-recipe.json", "source_text"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing mosaic field " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-import.json",
        bundle.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-import.json")
      println(
        "Two source clips joined on their exact metre grid. Inspect mosaic-cells.csv for contributors and unknown gaps; no mission or physical readiness claim.",
      )
    }
    ["assess-corridor", path, cells_path, output, radius, slope, roughness] => {
      let corridor = @raster.assess_corridor_bundle(
        @fsx.read_file_to_string(path),
        @fsx.read_file_to_string(cells_path),
        @string.parse_int(radius),
        @string.parse_double(slope),
        @string.parse_double(roughness),
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard corridor is Object(fields) else { fail("Invalid corridor") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("corridor-cells.csv", "cells_csv"),
          ("corridor-stops.csv", "stops_csv"),
          ("corridor.svg", "corridor_svg"),
          ("input-path.txt", "input_path_text"),
          ("path-cells.txt", "path_cells_text"),
          ("corridor-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing corridor field " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-corridor.json",
        corridor.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-corridor.json")
      guard fields.get("status") is Some(String(status)) else {
        fail("Missing corridor status")
      }
      println(
        status +
        ": inspect corridor-report.md for missing coverage and shape thresholds. No robot clearance claim.",
      )
    }
    ["compare-path", reference, candidate, cells_path, output, grade, uphill] => {
      let comparison = @raster.compare_path_bundle(
        @fsx.read_file_to_string(reference),
        @fsx.read_file_to_string(candidate),
        @fsx.read_file_to_string(cells_path),
        @string.parse_double(grade),
        @string.parse_double(uphill),
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard comparison is Object(fields) else { fail("Invalid comparison") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("path-comparison.csv", "comparison_csv"),
          ("input-path.txt", "input_path_text"),
          ("path-cells.txt", "path_cells_text"),
          ("comparison-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing comparison output " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-path-comparison.json",
        comparison.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-path-comparison.json")
      println(
        "Candidate minus reference; unchanged path. Inspect comparison-report.md for coverage and segment transitions.",
      )
    }
    ["assess-path", path, cells_path, output, grade, uphill] => {
      let assessment = @raster.assess_path_bundle(
        @fsx.read_file_to_string(path),
        @fsx.read_file_to_string(cells_path),
        @string.parse_double(grade),
        @string.parse_double(uphill),
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard assessment is Object(fields) else {
        fail("Invalid path assessment")
      }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("path-assessment.csv", "path_csv"),
          ("input-path.txt", "input_path_text"),
          ("path-cells.txt", "path_cells_text"),
          ("path-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing path assessment field " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-path-assessment.json",
        assessment.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-path-assessment.json")
      guard fields.get("status") is Some(String(status)) else {
        fail("Missing path assessment status")
      }
      println(
        status +
        ": submitted path assessed without rerouting; inspect path-report.md and path-assessment.csv.",
      )
      if fields.get("coverage_complete") == Some(false.to_json()) {
        println(
          "INCOMPLETE COVERAGE: whole-path totals unavailable; observed segments may be separated by unknown gaps.",
        )
      }
    }
    ["edit-template", path, output] => {
      let csv = @raster.revision_template(@fsx.read_file_to_string(path))
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new file")
      }
      @fsx.write_string_to_file(output, csv)
      println(output)
      println(
        "Edit elevation_m; retain expected_elevation_m. Use unknown to mark missing coverage.",
      )
    }
    ["revise", path, edits_path, output, reason] => {
      let edits = @fsx.read_file_to_string(edits_path)
      let bundle = @raster.revise_bundle(
        @fsx.read_file_to_string(path),
        edits,
        reason,
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard bundle is Object(fields) else { fail("Invalid revised terrain") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("terrain.csv", "terrain_csv"),
          ("revision-changes.csv", "changes_csv"),
          ("source-recipe.json", "source_text"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing revision output " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(output + "/edits.csv", edits)
      @fsx.write_string_to_file(output + "/revision-reason.txt", reason + "\n")
      @fsx.write_string_to_file(
        output + "/terrain-import.json",
        bundle.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-import.json")
      println(
        "Declared terrain revision saved with original source and edit history. Values require review; no validated measurement or physical readiness claim.",
      )
    }
    ["xyz", csv_path, specification_path, output] => {
      let text = @fsx.read_file_to_string(csv_path)
      let specification = @fsx.read_file_to_string(specification_path)
      let bundle = @raster.import_xyz_bundle(text, specification)
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard bundle is Object(fields) &&
        fields.get("terrain_csv") is Some(String(csv)) else {
        fail("Invalid XYZ terrain bundle")
      }
      @fsx.create_dir(output)
      @fsx.write_string_to_file(output + "/source.csv", text)
      @fsx.write_string_to_file(output + "/grid.json", specification)
      @fsx.write_string_to_file(output + "/terrain.csv", csv)
      @fsx.write_string_to_file(
        output + "/terrain-import.json",
        bundle.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-import.json")
      println(
        "Grid-aligned XYZ observations imported. Missing cells remain unknown; source and grid declarations require review.",
      )
    }
    [
      "waypoints"
      | "waypoints-xy" as command,
      path,
      csv_path,
      output,
      grade,
      uphill,
    ] => {
      let source = @fsx.read_file_to_string(path)
      let csv = @fsx.read_file_to_string(csv_path)
      let route = if command == "waypoints-xy" {
        @raster.route_coordinate_waypoints_bundle(
          source,
          csv,
          @string.parse_double(grade),
          @string.parse_double(uphill),
        )
      } else {
        @raster.route_waypoints_bundle(
          source,
          csv,
          @string.parse_double(grade),
          @string.parse_double(uphill),
        )
      }
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard route is Object(fields) else { fail("Invalid waypoint report") }
      let file_prefix = if fields.get("route_complete") == Some(true.to_json()) {
        "complete-"
      } else {
        "incomplete-prefix-"
      }
      @fsx.create_dir(output)
      for
        (name, field) in [
          (file_prefix + "route.csv", "connected_route_csv"),
          (file_prefix + "cells.txt", "connected_cells_text"),
          ("waypoint-legs.csv", "legs_csv"),
          ("waypoint-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing waypoint field " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      if command == "waypoints-xy" {
        for
          (name, field) in [
            ("coordinates.csv", "coordinate_waypoints_csv"),
            ("coordinate-mapping.csv", "coordinate_mapping_csv"),
            ("waypoints.csv", "waypoints_csv"),
          ] {
          guard fields.get(field) is Some(String(text)) else {
            fail("Missing coordinate waypoint field " + field)
          }
          @fsx.write_string_to_file(output + "/" + name, text)
        }
      }
      @fsx.write_string_to_file(
        output + "/terrain-waypoint-route.json",
        route.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-waypoint-route.json")
      guard fields.get("status") is Some(String(status)) else {
        fail("Missing waypoint status")
      }
      println(status + ": inspect waypoint-report.md and waypoint-legs.csv.")
      if fields.get("route_complete") == Some(false.to_json()) {
        println(
          "INCOMPLETE ROUTE: incomplete-prefix-* contains only the connected prefix; later legs are independent. Whole-route totals are unavailable.",
        )
      }
    }
    [
      "route",
      path,
      output,
      start_row,
      start_col,
      goal_row,
      goal_col,
      grade,
      uphill,
    ] => {
      let route = @raster.route_bundle(
        @fsx.read_file_to_string(path),
        @string.parse_int(start_row),
        @string.parse_int(start_col),
        @string.parse_int(goal_row),
        @string.parse_int(goal_col),
        @string.parse_double(grade),
        @string.parse_double(uphill),
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard route is Object(fields) else { fail("Invalid route report") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("route.csv", "route_csv"),
          ("path-cells.txt", "path_cells_text"),
          ("route.svg", "route_svg"),
          ("route-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing route field " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-route.json",
        route.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-route.json")
      guard fields.get("status") is Some(String(status)) else {
        fail("Missing route status")
      }
      println(
        status +
        ": exploratory metric grid routing; inspect route-report.md and route.svg.",
      )
    }
    ["analyze", path, output, axis, index, threshold] => {
      let analysis = @raster.analyze_bundle(
        @fsx.read_file_to_string(path),
        axis,
        @string.parse_int(index),
        @string.parse_double(threshold),
      )
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      guard analysis is Object(fields) else { fail("Invalid analysis report") }
      @fsx.create_dir(output)
      for
        (name, field) in [
          ("terrain-cells.csv", "cells_csv"),
          ("terrain-profile.csv", "profile_csv"),
          ("terrain-report.md", "report_markdown"),
        ] {
        guard fields.get(field) is Some(String(text)) else {
          fail("Missing report field " + field)
        }
        @fsx.write_string_to_file(output + "/" + name, text)
      }
      @fsx.write_string_to_file(
        output + "/terrain-analysis.json",
        analysis.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-analysis.json")
      println(
        "Metric terrain estimates exported. Unknown neighborhoods and transect gaps remain unknown; no mission or physical readiness claim.",
      )
    }
    ["reopen", path] =>
      println(
        @raster.reopen_bundle(@fsx.read_file_to_string(path)).stringify(
          indent=2,
        ),
      )
    ["inspect", path, tile_id, frame, unit, source_note] =>
      println(
        @raster.import_bundle(
          @fsx.read_file_to_string(path),
          tile_id,
          frame,
          unit,
          source_note,
        ).stringify(indent=2),
      )
    ["convert", path, output, tile_id, frame, unit, source_note] => {
      let text = @fsx.read_file_to_string(path)
      let bundle = @raster.import_bundle(
        text, tile_id, frame, unit, source_note,
      )
      let grid = @raster.parse_ascii_grid(text)
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new directory")
      }
      @fsx.create_dir(output)
      @fsx.write_string_to_file(output + "/source.asc", text)
      @fsx.write_string_to_file(
        output + "/terrain.csv",
        grid.terrain_csv(tile_id),
      )
      @fsx.write_string_to_file(
        output + "/terrain-import.json",
        bundle.stringify(indent=2) + "\n",
      )
      println(output + "/terrain-import.json")
      println(
        "Local terrain imported. NODATA stays unknown. Source/units need review; no mission acceptance or physical authority.",
      )
    }
    _ =>
      fail(
        "Study clip: terrain_import crop <terrain-import.json> <new-output-directory> <start-row> <start-col> <rows> <cols> <tile-id> <purpose-and-limitations>\nClip verification: terrain_import reopen-crop <terrain-crop.json>\nMesh export: terrain_import export-mesh <terrain-import.json> <new-output-directory>\nMesh verification: terrain_import reopen-mesh <terrain-mesh.json>\nCompare area: terrain_import compare-area <reference.json> <candidate.json> <new-output-directory> <change-threshold-m>\nEnergy: terrain_import energy-path <terrain-import.json> <path-cells.txt> <assumptions.json> <new-output-directory>\nVisibility: terrain_import visibility <terrain-import.json> <new-output-directory> <observer-row> <observer-col> <target-row> <target-col> <observer-height-m> <target-height-m>\nMosaic: terrain_import mosaic <left.json> <right.json> <new-output-directory> <tile-id> <source/license note>\nCorridor: terrain_import assess-corridor <terrain-import.json> <path-cells.txt> <new-output-directory> <radius-cells> <slope-limit-degrees> <roughness-limit-m>\nCompare path: terrain_import compare-path <reference.json> <candidate.json> <path-cells.txt> <new-output-directory> <max-grade-degrees> <uphill-weight>\nExact path: terrain_import assess-path <terrain-import.json> <path-cells.txt> <new-output-directory> <max-grade-degrees> <uphill-weight>\nPath input: 1–4096 row,col cells with optional header; consecutive cells must repeat or be cardinal neighbors. No rerouting.\nTerrain editing: terrain_import edit-template <terrain-import.json> <new-edits.csv>\n       terrain_import revise <terrain-import.json> <edits.csv> <new-output-directory> <revision-source-and-reason>\nXYZ intake: terrain_import xyz <points.csv> <grid.json> <new-output-directory>\n" +
        "Usage: terrain_import inspect <source.asc> <tile-id> <coordinate-frame> <m|degrees> <source/license note>\n       terrain_import convert <source.asc> <new-output-directory> <tile-id> <coordinate-frame> <m|degrees> <source/license note>\n       terrain_import reopen <terrain-import.json>\n       terrain_import analyze <terrain-import.json> <new-output-directory> <row|column> <zero-based-index> <slope-threshold-degrees>\n       terrain_import route <terrain-import.json> <new-output-directory> <start-row> <start-col> <goal-row> <goal-col> <max-grade-degrees> <uphill-weight>\n       terrain_import waypoints <terrain-import.json> <waypoints.csv> <new-output-directory> <max-grade-degrees> <uphill-weight>\n       terrain_import waypoints-xy <terrain-import.json> <coordinates.csv> <new-output-directory> <max-grade-degrees> <uphill-weight>\nCoordinate waypoint CSV: x,y header in the source metre frame, cell centers within 1e-7 cell units; no reprojection.\nWaypoint CSV: row,col header, then 2–32 ordered zero-based stops. Elevation values must already be metres. Up to 4096 cells. Analysis and routing require metre cells. No reprojection.",
      )
  }
}

///|
fn main {
  run() catch {
    @raster.ImportError::InvalidRaster(message) => {
      println("Terrain import: " + message)
      @sys.exit(2)
    }
    error => {
      println("Terrain import: " + error.to_string())
      @sys.exit(2)
    }
  }
}
