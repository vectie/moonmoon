///|
// Node-only product filesystem adapter. No provider, network or device access.
extern "js" fn read_text(path : String) -> String =
  #| function(path) {
  #|   const fs = require('node:fs');
  #|   if (fs.statSync(path).size > 8388608) throw new Error('Input exceeds 8 MiB');
  #|   const bytes = fs.readFileSync(path);
  #|   if (bytes.length > 8388608) throw new Error('Input exceeds 8 MiB');
  #|   return new TextDecoder('utf-8', {fatal: true}).decode(bytes);
  #| }

///|
extern "js" fn create_output(path : String) -> Unit =
  #| function(path) { require('node:fs').mkdirSync(path); }

///|
extern "js" fn write_text(path : String, text : String) -> Unit =
  #| function(path, text) { require('node:fs').writeFileSync(path, text, {encoding: 'utf8', flag: 'wx'}); }

///|
extern "js" fn report_error(message : String) -> Unit =
  #| function(message) { console.error(message); process.exitCode = 1; }

///|
fn field(value : Json, key : String) -> Json raise {
  guard value is Object(fields) && fields.get(key) is Some(v) else {
    fail("Missing output field " + key)
  }
  v
}

///|
fn write_field(value : Json, key : String, path : String) -> Unit raise {
  guard field(value, key) is String(text) else {
    fail("Invalid text output " + key)
  }
  write_text(path, text)
}

///|
fn run() -> Unit raise {
  match @env.args()[2:] {
    ["explore", input, output, sr, sc, grade, weight, budget] => {
      let study = @raster.roundtrip_bundle(
        read_text(input),
        @string.parse_int(sr),
        @string.parse_int(sc),
        @string.parse_double(grade),
        @string.parse_double(weight),
        @string.parse_double(budget),
      )
      create_output(output)
      write_text(
        output + "/terrain-roundtrip.json",
        study.stringify(indent=2) + "\n",
      )
      write_field(study, "cells_csv", output + "/reachability-cells.csv")
      write_field(study, "reachability_svg", output + "/reachability.svg")
      write_field(study, "report_markdown", output + "/reachability-report.md")
      println(output + "/terrain-roundtrip.json")
      println(
        "Choose a within-budget destination on reachability.svg, then select it. Combined objective cost, not energy or physical readiness.",
      )
    }
    ["select", input, output, gr, gc] => {
      let selection = @raster.roundtrip_path_bundle(
        read_text(input),
        @string.parse_int(gr),
        @string.parse_int(gc),
      )
      let outbound = field(selection, "outbound_route")
      let returning = field(selection, "return_route")
      create_output(output)
      write_text(
        output + "/terrain-roundtrip-path.json",
        selection.stringify(indent=2) + "\n",
      )
      write_text(
        output + "/terrain-import.json",
        field(outbound, "source_bundle").stringify(indent=2) + "\n",
      )
      for (prefix, route) in [("outbound", outbound), ("return", returning)] {
        write_text(
          output + "/" + prefix + "-route.json",
          route.stringify(indent=2) + "\n",
        )
        write_field(
          route,
          "path_cells_text",
          output + "/" + prefix + "-path-cells.txt",
        )
        write_field(route, "route_csv", output + "/" + prefix + "-route.csv")
        write_field(route, "route_svg", output + "/" + prefix + "-route.svg")
        write_field(
          route,
          "report_markdown",
          output + "/" + prefix + "-route-report.md",
        )
      }
      println(output + "/terrain-roundtrip-path.json")
      println(
        "Both exact directed paths retained. Assess each with assess-path, assess-corridor and energy-path. Separate energy results do not establish combined battery adequacy.",
      )
    }
    _ =>
      fail(
        "Usage: node terrain_roundtrip.js explore <terrain-import.json> <new-output-directory> <start-row> <start-col> <max-grade-degrees> <uphill-weight> <combined-budget>\n       node terrain_roundtrip.js select <terrain-roundtrip.json> <new-output-directory> <goal-row> <goal-col>",
      )
  }
}

///|
fn main {
  run() catch {
    error => report_error(error.to_string())
  }
}
