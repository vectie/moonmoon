///|
#cfg(target="js")
extern "js" fn bind_terrain_import(
  convert : (String, String, String, String, String) -> String,
  reopen : (String) -> String,
  analyze : (String, String, Int, Double) -> String,
  route : (String, Int, Int, Int, Int, Double, Double) -> String,
) -> Unit = "(convert, reopen, analyze, route) => globalThis.__moonmoonBindTerrainImport?.(convert, reopen, analyze, route)"

///|
fn terrain_import_panel() -> Html {
  details(id="terrain-import-panel", class="terrain-import-panel", [
    summary("Explore a local terrain raster"),
    p(
      "Open an Esri ASCII .asc clip (up to 4096 cells, 1 MiB). Inspect exact cell centers and missing coverage, analyze metric slopes, roughness and row/column profiles, then export CSV and source-bound evidence. This does not replace the frozen mission terrain or start a simulation.",
    ),
    label([
      span("Local ASCII grid or exported terrain-import JSON"),
      input(
        id="terrain-import-file",
        input_type=@html.File,
        accept=".asc,.txt,.json",
      ),
    ]),
    label([
      span("Tile ID"),
      input(id="terrain-import-tile", input_type=@html.Text, value="local-clip"),
    ]),
    label([
      span(
        "Source coordinate frame / CRS (required, copied without verification)",
      ),
      input(id="terrain-import-frame", input_type=@html.Text),
    ]),
    label([
      span("Horizontal coordinate units"),
      @html.select(id="terrain-import-unit", [
        @html.option(value="m", "Metres"),
        @html.option(value="degrees", "Degrees (no reprojection)"),
      ]),
    ]),
    label([
      span("Source filename or URL, license, and limitations (required)"),
      textarea(id="terrain-import-note", ""),
    ]),
    label([
      input(id="terrain-import-metres", input_type=@html.Checkbox),
      span(
        "The source elevation values are already metres. No vertical conversion is performed.",
      ),
    ]),
    button(
      id="terrain-import-open",
      type_="button",
      "Import and inspect terrain",
    ),
    button(
      id="terrain-import-sample",
      type_="button",
      "Explore synthetic example",
    ),
    button(id="terrain-import-clear", type_="button", "Clear imported terrain"),
    p(
      id="terrain-import-status",
      attrs=@html.Attrs::build().role("status").aria_live("polite"),
      "No terrain imported. Files stay in this page until explicitly downloaded.",
    ),
    div(id="terrain-import-results", ""),
  ])
}
