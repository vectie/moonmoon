# Frozen-terrain draft route editor

Open a verified completed study, enter its exact parent session, then choose Fork.
Select the variant to edit. The separate **Draft route on frozen terrain** panel
changes only that variant's existing `path_cells`. The completed-study map and
saved parent review remain unchanged.

- Choose an exact frozen terrain sample and **Append selected frozen cell**.
  Clicking a cyan sample or focusing it and pressing Enter/Space does the same.
- Choose a numbered route occurrence, then remove it or move it earlier/later.
  Repeated coordinates and segments remain separate ordered occurrences.
- Undo restores the preceding route text, including unfinished manual text.
  Up to 64 edits are retained for the current selected variant while mounted.
  Switching variants or replacing/reopening a draft clears this local undo list.
- The row,column textarea is authoritative. It stays synchronized with the
  controls and is the fallback when terrain cannot be displayed. Invalid or
  unfinished text is retained without being replaced by a guessed route.
- The editor keeps the existing 2–256 route-cell bounds. Removing below two or
  appending above 256 is disabled. Native execution still validates the route.

The SVG uses exact source row/column indices: columns increase right, rows down.
Its dashed lines mean authored order, never validated route segments. Elevation
is copied from the frozen CSV, never interpolated. Missing samples are unknown;
disconnected routes can be drafted but are rejected by native validation. Sparse
and non-square sources do not allocate dense terrain grids. Ambiguous duplicate
terrain coordinates, absent sources, unsupported CSV and the existing 4096-sample
bound disable the map with an explanation; textual editing/export stays available.

Use the existing **Export** control to download the exact runnable v1/v2 draft
envelope. Discard the current draft, then reopen those same bytes to restore the
route and assumptions. A v1 input stays v1; a new fork uses named v2 variants.
Edits are in memory until exported or explicitly submitted to the local run host.
Reload alone does not preserve unsaved edits.

**Run digital mission** is a separate explicit action through the existing local
host/native runner. Appending cells never starts a run. Changed input generations
invalidate pending authoring/run callbacks, and detached map callbacks cannot
modify another selection. Results require their own exact-revision review.
No slopes, auto-routes, new terrain, coverage, physical readiness, automatic
acceptance, or new simulation semantics are added by this editor.

Qualification uses deterministic DOM/SVG handler tests and the actual retained
native host journey. This is not graphical-browser, pointer-layout, or complete
assistive-technology acceptance.

## Route CSV exchange (R475)

In the same draft panel, **Stage route CSV file** reads a local UTF-8 CSV into a
preview without changing the route. Review the target frozen source reference,
digest, cell size and known sample bounds, then the ordered occurrence preview
and missing-sample count. Select **Replace selected route** or **Append to
selected route**, then **Apply reviewed route CSV**. Only the selected variant
changes. Undo restores the exact preceding text, even unfinished manual input.
Other variants and the saved parent review remain unchanged.

Example file:

```csv
row,column
0,0
1,0
0,0
```

The header is exactly `row,column` (surrounding whitespace accepted). Coordinates
are zero-based nonnegative integer grid indices, not metres, geographic
coordinates, or one-based spreadsheet row labels. Spaces around values, UTF-8
BOM, LF and CRLF are supported. Each row is one ordered occurrence, including
repeats. Quoted fields, extra columns and blank interior rows are not supported.
There must be 2–256 imported occurrences, each index at most 1,000,000, in a file
at most 16 KiB. Append additionally requires a valid existing route and at most
256 resulting occurrences; it does not deduplicate shared endpoints. Replacement
can repair unfinished current route text. Invalid files leave inputs untouched.

**Download selected route CSV** exports only the current selected route. Edit
that file in a spreadsheet or other local tool, save UTF-8 CSV, stage it again,
and review before applying. Source identity, frame, units, assumptions and review
are deliberately not encoded in this narrow index exchange format. The target
source is shown at import time; the file cannot establish that it belongs to that
source. Retain and use the existing full draft JSON export for reproducibility.

Cells outside the known grid bounds or in coverage gaps are counted as missing
exact samples, never clamped, interpolated, or accepted as valid terrain. This
matches existing draft textarea semantics. A route can remain unvalidated or
infeasible, and a later native run may reject it. Terrain unavailability leaves
coverage explicitly unknown but allows draft index exchange. Imported cells do
not import terrain, trigger a simulation, save a review, or grant authority.

A pending file read is discarded if route text or selected variant changes or a
newer file is selected. Detached preview/apply/download controls cannot alter a
newer selection. Unsaved CSV edits share the existing draft lifetime: export the
full draft or explicitly submit it through the existing host before leaving.

R475 verification uses Node tests of production DOM handlers, CSV downloads,
full draft export/reopen, variant isolation and undo. No graphical browser,
spreadsheet application, native simulator or external dataset is qualified by
these focused tests.
