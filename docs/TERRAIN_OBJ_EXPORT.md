# Inspect imported terrain in a 3D tool

`terrain_import export-mesh` creates a Wavefront OBJ surface from a verified
ASCII, XYZ, revised or mosaic terrain bundle. Use it to inspect a terrain clip
in an OBJ-capable 3D application without needing MoonMoon's optional UI archive.
Keep the sidecars: OBJ itself does not carry authoritative units or a coordinate
reference system. This is source-bound reference geometry, not field evidence.

## Export and verify

```sh
terrain_import export-mesh INPUT/terrain-import.json NEW-MESH-DIRECTORY
terrain_import reopen-mesh NEW-MESH-DIRECTORY/terrain-mesh.json
```

The output directory must not already exist. Source verification and geometry
calculation occur before directory creation. Existing sources and exports stay
unchanged. Multi-file writes are not atomic across disk/I/O interruption; use a
fresh directory to retry and retain the JSON with its generated output digests.

Files:

- `terrain.obj`: portable vertices and triangle faces; no textures or materials
- `mesh-cells.csv`: every source cell, source coordinates, elevation, OBJ vertex,
  local coordinates, known/unknown state and whether a face uses the vertex
- `mesh-faces.csv`: every triangle's 1-based OBJ face and vertex indexes and the
  top-left row/column of the 2x2 sample neighborhood that produced it
- `mesh-report.md`: source identity, coordinate translation, counts and limits
- `terrain-mesh.json`: complete verified source, geometry, CSVs, report and hashes

Reopening regenerates every output from the embedded source and requires exact
content equality, while allowing JSON whitespace/key-order changes. It verifies
the embedded outputs, not files edited separately beside it; compare those bytes
to their sidecar SHA-256 hashes or regenerate into a fresh directory.

## Coordinates and faces

Only metre-coordinate inputs are supported; elevations must already be metres.
There is no CRS inference or reprojection. Select metres and Z-up in your OBJ
viewer. Positive X/Y follow the declared source frame, not an inferred lunar
longitude/latitude system. The file translates X/Y to the lower-left sample
center to make inspection convenient:

- source X = OBJ X + sidecar `source_translation_m.x`
- source Y = OBJ Y + sidecar `source_translation_m.y`
- source elevation = OBJ Z; no vertical rebasing or exaggeration

Vertex indices are 1-based, in known-cell row-major order, from the top input
row down. Every complete 2x2 neighborhood is split along its northwest/southeast
diagonal. Faces are `(NW, SW, SE)` and `(NW, SE, NE)`, counterclockwise when
viewed from above (+Z). Their interiors are a piecewise-planar display model
between the declared samples; they are not additional observations.

For this small source:

```text
ncols 2
nrows 2
xllcorner 100
yllcorner -20
cellsize 2
4 5
-1 0
```

The translation is `(101,-19,0)`. OBJ vertices are `(0,2,4)`, `(2,2,5)`,
`(0,0,-1)`, `(2,0,0)`, and faces are `1 3 4` and `1 4 2`.
The first source sample is at `(101,-17)`; its OBJ vertex is `(0,2,4)`.
Changing any one sample to NODATA removes both faces. It does not fabricate a
triangle from the remaining three observations.

## Read missing coverage correctly

Unknown cells have no vertex, and every 2x2 neighborhood touching an unknown
cell has no faces. Isolated known vertices remain in the OBJ and CSV but some
viewers hide them. Known zero and negative elevations are preserved. A true
-9999 imported through XYZ remains a vertex; unknown is determined by the
verified source's coverage, not by a hardcoded export sentinel.

- `complete-sampled-surface`: all possible 2x2 sample neighborhoods exported
- `partial-surface`: at least one exported and at least one omitted neighborhood
- `no-surface`: no triangles, including single-row/column or fully unknown grids

A complete sampled surface does not establish complete real-world coverage.
The mesh stops at outer sample centers and excludes the raster's half-cell rim.
There is no hole filling, bridging, skirt, solid base, UV, normal, or physical
suitability assertion. The exporter refuses nonfinite or collapsed coordinate
geometry. Inputs remain bounded to the existing 4096-cell terrain limit; the
self-contained mesh JSON is limited to 8 MiB characters.

External 3D applications may reinterpret axes, units, normals, or isolated
vertices. Inspect the supplied fixture in your chosen viewer before using an
export downstream. This local CLI workflow does not qualify an external viewer,
external lunar dataset, mission, robot, hardware, or application distribution.
