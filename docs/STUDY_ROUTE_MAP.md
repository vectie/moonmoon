# Frozen study route map

Open **Save and compare a digital study**, import a completed native dossier, or
reopen a confirmed saved revision. The read-only map appears below the sensitivity
matrix. It has no simulation, authoring, storage, provider, or hardware actions.

## Inspecting the map

- Choose a session to inspect its route. **Overlay all alternatives** draws other
  alternatives on the same frozen source, with the selected session drawn last.
  Numbered S/E labels mark each route's start and end. Overlapping routes retain
  their exact positions; switch sessions to inspect each one independently.
- Horizontal position is column and vertical position is row, increasing down.
  The declared site frame is printed above the map. Detail offsets are the exact
  row/column indices multiplied by the declared `cell_size_m`, in metres relative
  to index zero. No geographic transformation or surveyed origin is invented.
- Dots show only enumerated samples, not inferred cell footprints or a filled
  terrain surface. Route bounds include missing endpoint cells and sparse gaps.
- Solid segments display exact native segment evidence. Red denotes native
  rejected segments. Amber dashed segments and hollow amber cells denote unknown
  coverage or missing, malformed, or ambiguous evidence.
- Use the route cell/segment selector, the terrain-sample selector, or Tab and
  Enter/Space on the selected route's SVG cells/segments. Each exposes exact
  coordinates, source elevation if available, and retained native segment
  distance, slope, elevation delta, and accepted flag. The expandable full text
  list contains every selected route occurrence and segment, including repeats.
  The same controls and full list work when SVG is unavailable.

## Evidence and bounded support

The map consumes only the already integrity-checked `readStudy` value. It looks
up the exact frozen `design.environment.terrain_source_path` in the dossier,
shows that source's digest, and uses the frozen `path_cells` as `[row,column]`.
It never fetches an unrelated terrain asset or uses the generic terrain canvas.

Supported CSV has header `tile_id,row,col,elevation_m` with four unquoted fields
per nonblank record. Rows and columns must be signed 32-bit integers, matching
native MoonBit `Int`; elevations must be finite decimal numbers. Whitespace,
CRLF, signs, negative coordinates, and decimal exponents are supported. Duplicate
terrain coordinates, even identical duplicate records, are ambiguous and make
the map unavailable rather than selecting a record. Malformed/unsupported data,
nonfinite or overflowing coordinates, and absent positive finite spacing are
likewise reported explicitly without affecting dossier review or export.

Limits are inclusive: **4096 terrain samples, 256 route cells per alternative,
8 alternatives**. The map stores only those samples and enumerated routes; it
never allocates a dense grid from coordinate extents. Exceeding a limit makes the
map unavailable rather than truncating, interpolating, clamping, or dropping
data. Very widely separated sparse coordinates can visually coincide at screen
resolution; all exact coordinates remain in the selectors and full text list.

Native `result.segment_evidence` is matched to exact directed endpoint pairs,
not zipped against a route index, because the native simulator omits unsupported
segments. Repeated traversals are matched in occurrence order only when the
number of retained records matches the number of traversals. Missing, duplicate
or ambiguous evidence remains unknown. A native entry retained for a segment
with missing exact terrain coverage is shown as retained evidence while the map
still labels coverage unknown. Slopes, segment acceptance, route acceptance,
and scientific criteria are never recomputed.

The inert `fixtures/mission-study-local.json` example is a useful regression:
q11-b continues from `[3,3]` to `[4,3]`; the CSV only contains rows 0–3. Its final
cell and segment must remain visibly unknown outside the measured extent.

## State and authority

Session, overlay, and inspection choices are ephemeral UI state scoped to the
exact dossier digest. A successfully opened different revision resets them.
Failed import/reopen preserves the previous map and unsaved review. An obsolete
control from a prior revision cannot update the new revision's map. No map action
marks a review dirty or writes any saved evidence. The map never grants whole
grid coverage, geographic truth, hazard clearance, or physical authority.

## Regression checks

Run `npm run test:study` for dependency-free Node unit and control-handler tests,
including `mission-study-map.test.mjs`. The normal production `npm run build`
pipeline must still be run for release verification: E1 preparation (honestly
unavailable when the optional archive is absent), live MoonRobo typed asset
generation, MoonBit Rabbita compilation, and Vite output. The built-host test in
`mission-run.test.mjs` verifies served production assets, not a source-only test
page. Existing native scientific and provenance checks remain unchanged.
