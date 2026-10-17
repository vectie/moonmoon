# Import a detached PDS3 elevation clip

MoonMoon now accepts a bounded binary terrain source in addition to ASCII grids
and XYZ observations. Supply a local PDS3 label, its signed-16-bit IMG file, and
an explicit regular-grid declaration. Inspect decoded elevations and missing
coverage, edit a declared cell value, then export the same terrain through the
existing profile, contour, ASCII and OBJ workflows.

This is a native CLI and library workflow. It does not add browser intake,
register a mission, qualify external data, infer projection, or grant physical
authority. PRD alignment: MN-W01 / MOONMOON-B01 source-bound inputs and metadata;
MN-W02 / B03 calculations over declared coverage; MN-W04 / B07 inspectable CLI
outputs. R03 external dataset and distribution qualification remains unfulfilled.

## Small runnable example

Use a built `terrain_import` executable. Paths below assume the source root as
working directory and fresh output directories. Substitute the executable path
for `terrain_import` if it is not on PATH.

```text
terrain_import pds3 data/terrain_import/DEMO.LBL data/terrain_import/DEMO.IMG data/terrain_import/pds3-grid.json study-import
terrain_import reopen study-import/terrain-import.json
terrain_import analyze study-import/terrain-import.json study-profile row 1 30
terrain_import edit-template study-import/terrain-import.json edits.csv
```

Open `study-import/import-report.md` and `decoded-samples.csv` first. The
three-row/four-column synthetic fixture uses big-endian signed codes:

```text
    -4      0     4     8
    12 -32768    20    24
    28     32    36    40
```

The label declares `elevation_m = DN * 0.5 + 100`. Thus the first elevation is
98 m, not 32866 m from an unsigned interpretation. Code -32768 is declared
missing before scaling; it stays unknown. The lower-left center is (100, 200),
square spacing is 5 m, and row zero is the upper row at Y=210. There are 11
known samples, elevations 98–120 m. The middle-row profile has two unknown
segments. None of these values is acquired lunar terrain.

`DEMO.IMG` is exactly 24 bytes, hexadecimal:

```text
fffc000000040008000c800000140018001c002000240028
```

`DEMO_LE.LBL` and `DEMO_LE.IMG` describe identical values with little-endian
storage. Their inputs and source identities differ, while their samples match.
The IMG hex is `fcff0000040008000c000080140018001c00200024002800`.

## Edit and export a declared revision

The template includes expected old values. Change only values you can justify;
`unknown` marks missing coverage. The supplied `pds3-edit.csv` changes the gap
at row 1, column 1 from unknown to a synthetic declared 108 m. It is an example
of an analyst declaration, not a measurement or a recommendation to fill gaps.

```text
terrain_import revise study-import/terrain-import.json data/terrain_import/pds3-edit.csv study-revision "Synthetic declared gap replacement; not measured terrain"
terrain_import reopen study-revision/terrain-import.json
terrain_import analyze study-revision/terrain-import.json study-revised-profile row 1 30
terrain_import contours study-revision/terrain-import.json study-contours 100 105 110 115
terrain_import export-mesh study-revision/terrain-import.json study-mesh
terrain_import reopen-mesh study-mesh/terrain-mesh.json
terrain_import crop study-revision/terrain-import.json study-ascii 0 0 3 4 pds-exchange "Full-grid portable export; retain PDS3 parent receipt"
```

Inspect `study-contours/contours.svg`, `study-mesh/terrain.obj`, and
`study-ascii/source.asc`. The revision has 12 declared known samples. The original
import remains unchanged and is embedded in the revision. The unedited mesh
withholds faces around the gap; the revised mesh includes those neighborhoods.
The crop command with the full dimensions supplies a portable ASCII exchange
and a receipt binding it to the complete edited parent. Reimporting the ASCII
alone preserves samples, but does not carry the original binary provenance;
retain the crop and original receipts alongside it.

## Inputs and supported profile

All three input files are required. The IMG path is explicit; no file is fetched
or followed automatically from the label. Its basename must match the quoted
`^IMAGE` pointer exactly. The pointer is an uppercase simple filename ending in
`.IMG`, with only A–Z, digits, underscore and dot, and cannot begin with a dot.

Label and declaration bytes are strictly decoded as UTF-8 without stripping a
BOM or normalizing malformed bytes. Invalid encodings and leading BOMs are
refused before output; accepted input copies retain their exact bytes.

The label supports ASCII text, blank lines, CRLF or LF, block comments, and one
scalar assignment per line. Quoted values must fit on one line. Exactly one
non-nested `OBJECT = IMAGE`, matching `END_OBJECT = IMAGE`, and final `END` are
required. Duplicate keys, unknown fields, extra objects and content after END
are rejected. This is an intentionally limited interchange profile, not a full
ODL parser or PDS3 compliance validator.

Required root fields:

- `PDS_VERSION_ID = PDS3`
- `RECORD_TYPE = FIXED_LENGTH`
- `RECORD_BYTES = 2 * LINE_SAMPLES`, with no row padding
- `FILE_RECORDS = LINES`
- `^IMAGE = "NAME.IMG"`, pointing at the first byte by filename alone

Required IMAGE fields: positive integer `LINES` and `LINE_SAMPLES`,
`SAMPLE_TYPE = MSB_INTEGER` or `LSB_INTEGER`, `SAMPLE_BITS = 16`, `UNIT = METER`,
and finite explicit `SCALING_FACTOR` and `OFFSET`. Scale must be nonzero. Negative
scale is applied literally. Total cells cannot exceed 4096; the byte count must
be exactly `2 * rows * cols`, at most 8192 bytes. Labels are bounded to 64 KiB of
characters and grid declarations to 16 KiB.

`LINES` and `LINE_SAMPLES` retain the integer-only label syntax. `RECORD_BYTES`,
`FILE_RECORDS` and JSON `rows`/`cols` may use decimal or exponent notation only
when the exact mathematical token is a supported positive integer: `80e-1`
means 8, while `8.0000000000000001` is refused even if binary floating-point
conversion would round it to 8. Validation occurs on the raw numeric token.

Optional IMAGE fields accepted with the following interpretation:

- `MISSING_CONSTANT` and `INVALID_CONSTANT`: signed decimal -32768..32767;
  each matching raw code is withheld before scaling
- `BANDS = 1`, `BAND_STORAGE_TYPE = BAND_SEQUENTIAL`
- `LINE_PREFIX_BYTES = 0`, `LINE_SUFFIX_BYTES = 0`
- `ENCODING_TYPE = N/A`, `SAMPLE_BIT_MASK = 2#1111111111111111#`
- `MINIMUM`, `MAXIMUM`, `DERIVED_MINIMUM`, `DERIVED_MAXIMUM`, `DESCRIPTION`,
  and `NOTE`: retained text only; never substituted for computed results

Allowed informational root fields are `DATA_SET_ID`, `PRODUCT_ID`, `TARGET_NAME`,
`INSTRUMENT_HOST_NAME`, `INSTRUMENT_HOST_ID`, `INSTRUMENT_NAME`, `INSTRUMENT_ID`,
`PRODUCT_CREATION_TIME`, `DESCRIPTION`, and `NOTE`. Other fields are refused
instead of silently discarding potential layout or special-value semantics.
Missing codes are never guessed. Without either special-code field all signed
values are treated as samples, including -32768 and -9999.

The JSON declaration uses `moonmoon.pds3-grid.v1`. Copy `pds3-grid.json` and supply
the actual tile ID, frame, source/terms note, dimensions, lower-left center
`origin_x`/`origin_y`, square positive `cell_size`, `horizontal_unit` (`m` or
`degrees`), `vertical_datum`, `uncertainty_note`, and the explicit
`vertical_quantity = elevation`, `row_order = top-to-bottom`, and
`column_order = left-to-right` declarations. Dimensions must match the label.
Duplicate decoded declaration keys are refused, including identical values and
escaped equivalent names such as `rows` and `r\u006fws`. The declaration is a flat
object of scalar values; nested containers are unsupported.

These are caller declarations, not verified source facts. Origin and spacing
must be representable without collapsing any adjacent centers, including interior
centers on either axis. Degree sources can be
inspected and edited; metre-only analysis and OBJ export still refuse them.

Some planetary products encode radius or other physical quantities. A metre
unit and plausible elevation range do not prove the values are heights. Review
the source documentation before declaring `elevation`. A declaration of `radius`
is rejected. No reference-radius subtraction, datum conversion, unit conversion,
map projection, interpolation, bit-mask transformation, or row reversal occurs.
`IMAGE_MAP_PROJECTION` objects are unsupported. Do not simply delete unsupported
metadata to make an input pass; obtain a correctly documented supported clip.

## Saved outputs and refusal behavior

- `SOURCE.LBL`, the original named IMG, and `grid.json`: exact input copies
- `decoded-samples.csv`: every cell, raw signed code, converted elevation and
  known/missing/invalid classification
- `terrain.csv`: known samples only, ready for existing terrain consumers
- `import-report.md`: decoding, grid, source, datum and uncertainty declarations
- `terrain-import.json`: complete label, exact raw image in lowercase hex,
  declaration, sample values, reports and SHA-256 identities

`source_inputs` contains the label, image and declaration digests and image name.
`source_digest` binds that canonical input identity record. `reopen` decodes
the retained bytes again and compares every exported field. Reformatting saved
JSON does not change its meaning; tampered bytes, metadata or reports fail replay.

Attached labels, pointer tuples/offsets, mismatched filenames or sizes, packed or
compressed values, unsigned/floating samples, padded rows, multiband images,
unsupported missing-value formats and unknown fields fail before creating the
requested output directory. Existing output directories are refused. Filesystem
I/O failures after writing starts may leave a partial directory; inspect it and
use a fresh directory. The exporter is not a transactional durable store.

Scaling uses ordinary floating-point multiplication followed by addition. It
refuses nonfinite inputs/intermediates/results and zero scale, but does not make
an exact-arithmetic or source-accuracy claim. Digital output cannot establish
mission feasibility, clear negative-energy blockers, or authorize navigation.

## Primary format references

- NASA PDS3 Standards Reference, [Chapter 3, sections 3.2–3.4](https://pds.nasa.gov/datastandards/pds3/standards/sr/stdref3.7/Chapter03.pdf):
  explicit MSB/LSB storage and two's-complement signed integers.
- [Chapter 5, section 5.3.3.2](https://pds.nasa.gov/datastandards/pds3/standards/sr/stdref3.7/Chapter05.pdf):
  detached pointer forms; filename-only starts at the referenced file's beginning.
- [Appendix A, IMAGE A.20](https://pds.nasa.gov/datastandards/pds3/standards/sr/stdref3.7/AppendixA.pdf):
  IMAGE dimensions/sample keywords, optional storage features and scale/offset example.
- NASA/JPL [MESSENGER DEM SIS](https://planetarydata.jpl.nasa.gov/img/data/messenger/MDIS/messdem_1001/DOCUMENT/MSGR_DEM_SIS.HTM):
  DEM use of missing-value metadata. This is a format reference, not a claim that
  a MESSENGER or lunar dataset was imported or qualified.

Read-only specification review: 2026-10-13. Examples are newly authored synthetic
Apache-2.0 fixtures. No external dataset was downloaded, no provider account was
used, and no release/distribution or physical-runtime gate was exercised.
