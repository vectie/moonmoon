# Budget energy for an imported-terrain path

`terrain_import energy-path SOURCE PATH ASSUMPTIONS NEW_OUTPUT_DIRECTORY` budgets
an exact ordered cell path, including exports from `route` and `waypoints`.
Use it to see where a proposed route consumes a declared battery budget, and
rerun different speed, rate or reserve assumptions as separate studies.

This fills the imported-terrain energy workflow in PRD MN-W02, B03 and N01.
It is an explicit-rate exploratory calculation. It does not change the existing
frozen robot mission or its negative-energy blocker, qualify a robot, or grant
physical authority. Existing mission simulation remains separate.

## Try the synthetic example

After building the native terrain_import executable (see BUILD.md), run from the
source checkout, choosing unused output directories:

```sh
terrain_import convert data/terrain_import/synthetic-energy.asc energy-source energy-demo "Synthetic local Cartesian" m "Synthetic arithmetic fixture, Apache-2.0; not observed lunar terrain"
terrain_import energy-path energy-source/terrain-import.json data/terrain_import/synthetic-energy-path.txt data/terrain_import/synthetic-energy-assumptions.json energy-study
```

The submitted path goes 20 horizontal metres, climbs 10 m and descends 10 m.
At 1 m/s, drive 1 Wh/m, ascent 2 Wh/m and 360 W auxiliary power, it takes 20 s
and uses 20 + 20 + 2 = 42 Wh. Starting with 50 Wh leaves 8 Wh, which is 2 Wh below
the declared 10 Wh reserve. The first sampled endpoint below reserve is step 2
(cell row 0, col 2). With starting energy changed to 20 Wh in a copied assumption
file, the study reports insufficient energy, preserves the final -22 Wh balance,
and identifies step 1 as the first sampled endpoint with negative energy.

Increasing speed to 2 m/s reduces declared auxiliary consumption to 1 Wh, for
41 Wh total. This is sensitivity within the chosen model, not evidence that a
real robot uses less energy at that speed. Drive/ascent rates stay unchanged.

## Assumption file

All fields are required. Unknown field names are refused to catch misspellings.
There are no implicit defaults or inferred robot parameters.

```json
{
  "contract_id": "moonmoon.path-energy-assumptions.v1",
  "assumption_note": "Explain the rate source, calibration status and limits.",
  "drive_wh_per_m": 1,
  "ascent_wh_per_m": 2,
  "cruise_speed_mps": 1,
  "auxiliary_power_w": 360,
  "initial_energy_wh": 50,
  "reserve_wh": 10,
  "max_grade_deg": 45
}
```

Rates, power, usable starting energy and reserve must be finite/nonnegative.
Speed must be finite/positive. Grade must be at least zero and less than 90°.
Reserve may exceed starting energy, yielding an immediate reserve shortfall.
Zero rates are permitted as explicit assumptions. The note is 1–2000 characters;
the entire JSON is limited to 16384 characters. No coefficient is a claim of
measured/calibrated robot performance merely because the file says so.

## Calculation and interpretation

For each cardinal step of horizontal distance d metres and rise h metres:

- Time t = d / cruise_speed_mps seconds
- Drive energy = d × drive_wh_per_m Wh
- Ascent energy = max(h, 0) × ascent_wh_per_m Wh
- Auxiliary energy = (t / 3600) × auxiliary_power_w Wh
- Total consumption = drive + ascent + auxiliary
- Remaining energy = initial energy minus cumulative consumption
- Reserve margin = remaining energy minus reserve

Descending receives no regenerative credit. Speed refers to horizontal distance,
not the 3D slope length. Known repeated cells represent zero distance/time/energy;
they do not encode dwell, charging, turn or startup costs. Grade screening from
the existing exact path assessor remains separate. A within-budget route may
still exceed its grade cap and is never labeled mission-ready. Equality meets
the budget/reserve; strictly negative values indicate shortfall. No clamping hides
negative values. Locations identify sampled endpoints, not a subsegment crossing.

Every source is reopened/recomputed. Original ASCII, XYZ, revised and mosaic
terrain bundles work without a new graph or Robo companion. Inputs must be metre
grids with at most 4096 cells. Paths retain the existing 1–4096 ordered row,col
input contract; cardinal neighbors or repetitions only. No rerouting, reprojection
or interpolation is performed. Existing frame/unit/quality declarations stay
visible and unverified. Overflow and detected underflow are refused.

## Missing data

An incident segment with unknown elevation has unknown ascent and total energy.
Its drive, travel time and auxiliary terms remain visible because horizontal
spacing is known. Once a gap occurs, cumulative consumption, battery balance and
reserve margin remain null for all later steps, even if later elevations resume.
The whole-path summary is null whenever a required elevation is missing.

Observed-segment totals include only fully known pairs and can be separated by
gaps. They are not a connected prefix. Because every rate is nonnegative, these
known segments alone can prove insufficient energy or a reserve shortfall. The
status precedence is insufficient-energy, below-reserve, incomplete-coverage,
then within-declared-budget. Coverage is always reported independently.
The first-known-prefix crossing fields stay null if the gap prevents locating a
crossing. A null crossing is not proof of no crossing. Unknown values are null in
JSON and empty cells in CSV, never fabricated zero.

## Retained outputs and reuse

- terrain-path-energy.json: full source/path assessment, original assumptions,
  segment records, summaries, all export texts and digest-bound identity
- energy-segments.csv: coordinates, energy components and per-step balances
- energy-report.md: source/frame, assumptions, outcome, equations and limits
- assumptions.json and inputs-path.txt: exact submitted text
- path-cells.txt: normalized reusable cell path

The exact original source is inside path_assessment.source_bundle. Rerun from
that retained source and the saved input/assumption texts into a new directory to
reproduce a result. There is no dedicated reopen command for the energy result.
Changing source, path or assumption bytes changes identity. SHA-256 identities
are integrity references, not signatures or authenticated provenance. Canonical
replay is bounded to the qualified toolchain. Keep the full JSON alongside CSV.
Validation completes before output creation; existing destinations are refused.
As with the existing CLI, multi-file persistence is not atomic under I/O failure.
Keep input evidence and retry into a fresh directory after an interrupted save.

## Scientific limits

The rates are constant and user declared. No solar/charging supply, regeneration,
acceleration, traction, thermal transients, aging, uncertainty propagation,
subcell terrain, rover footprint or actual battery discharge physics is modeled.
No hardware, URDF inference, provider, external dataset or physical validation is
involved. This is useful arithmetic for comparing explicit assumptions, with
source coverage carried through; it is not a validated robot energy prediction.
