# Imported terrain elevation-band exploration

MoonMoon's existing terrain import panel can now locate cells inside an inclusive elevation interval. It supports terrain analysts inspecting declared source evidence for MN-W01 and designers exploring terrain for MN-W02. It makes no slope, route feasibility or physical-safety decision.

1. Open Terrain import and import a supported ASCII raster or reopen its saved import JSON. The existing synthetic ridge example also works.
2. In **Explore an elevation band**, enter minimum and/or maximum elevations in metres. Leave either bound blank for an open interval.
3. Matching known cells stay bright on the existing raster map; other cells dim. NODATA cells never match. The status reports matching known cells, unknown cells, source digest and coordinate frame.
4. Use **Next matching cell** and **Previous matching cell** to inspect exact coordinates and elevation in the existing cell-detail view. Navigation follows source row-major order without wrapping. Bounds persist while changing cells.
5. Change either bound to explore another band. Invalid bounds remove highlighting and disable navigation. Opening another source resets the bounds.

For the synthetic ridge example, use minimum 110 and maximum 115 to inspect the elevated ridge cells. These are synthetic examples, not lunar observations. Degree-grid X/Y coordinates remain degrees; elevations remain the declared metres. No reprojection is performed.

Band selection does not mutate the source bundle, sparse CSV, terrain analysis, route or mission. Existing exports retain their existing meaning and are not filtered. The source may contain declared revisions rather than observations. Unknown coverage stays unknown, even when neighboring values match.

## Focused evidence and limits

`node --test ui/rabbita-moon/terrain-elevation-band.test.mjs` tests inclusive/open/negative bounds, unknowns, invalid inputs, the mounted production import adapter, map opacity, navigation, retained inputs and stale controls using DOM doubles and a declared synthetic parser result. Existing `terrain-analysis.test.mjs` covers the unchanged profile adapter. These tests do not requalify the native raster parser, a real browser, mission simulation, physical operations or full product release.
