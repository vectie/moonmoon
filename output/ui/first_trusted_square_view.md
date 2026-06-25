# First Trusted Square / Shackleton Rim rehearsal tile Operator View

- view: ui/first-trusted-square/operator-view-v2
- viewport: 4x4 cells, 352x224 px
- active layer: hazard
- selected cell: first-trusted-square-lola/r3-c2
- selected route: northeast-stepout

## Scorecard

- decision: block
- score: 20
- terrain hazard: blocked
- routes: 6 candidates, 6 blocked
- energy: 234.938073 Wh available, -1030.061927 Wh margin
- next action: revise rover power model, route count, or site window before simulation

## Layers

- elevation: Elevation, visible, measured, legend 441.521..499.693 m
- slope: Slope, visible, derived, legend 0..1.1593500000000005 grade
- roughness: Roughness, available, derived, legend 0..9.250124999999999 m
- hazard: Hazard, visible, blocked, legend 0..1 risk
- route: Routes, visible, blocked, legend 0..1 state
- evidence: Evidence, available, ready, legend 0..1 state
- power: Power, available, block, legend 0..234.938073 Wh

## Selected Tile Inspector

- cell: first-trusted-square-lola/r3-c2 (r3, c2)
- elevation: 454.027 m
- slope: 1.1593500000000005
- roughness: 15.122333333333339 m
- hazard: blocked
- source: lro-lola-first-trusted-square-dem-v1 / data/sources/lro_lola/first_trusted_square_dem.csv
- claim: measured
- uncertainty: medium, confidence 0.82
- layer values:
  - elevation: 454.027 m (measured, intensity 0.21498315340713708)
  - slope: 1.1593500000000005 grade (derived, intensity 1)
  - roughness: 15.122333333333339 m (derived, intensity 1)
  - hazard: blocked (blocked, intensity 1)
  - power: 234.938073 Wh (block, intensity 0.18572179683794465)

## Source Panel

- dataset: lro-lola-first-trusted-square-dem-v1
- title: LOLA Shackleton Rim DEM byte-range fixture
- source: https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img
- local path: data/sources/lro_lola/first_trusted_square_dem.csv
- claim: measured
- review: accepted-for-software-proof
- checksum: inline-grid-v1:tile=first-trusted-square-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=499.693:last=441.521

## Route Overlays

- direct-lola-window: block, evidence-window:first-trusted-square-lola, first-trusted-square-lola: grade 1.1593500000000005, roughness 9.250124999999999 m
- west-contour-detour: block, evidence-window:first-trusted-square-west-contour-lola, first-trusted-square-west-contour-lola: grade 0.7517000000000025, roughness 8.52791666666666 m
- north-rim-stepout: block, evidence-window:first-trusted-square-north-rim-lola, first-trusted-square-north-rim-lola: grade 0.7280000000000001, roughness 7.716124999999998 m
- southwest-bypass: block, evidence-window:first-trusted-square-southwest-bypass-lola, first-trusted-square-southwest-bypass-lola: grade 0.6484500000000025, roughness 7.056666666666669 m
- south-stepout: block, evidence-window:first-trusted-square-south-stepout-lola, first-trusted-square-south-stepout-lola: grade 0.7199500000000001, roughness 7.154583333333335 m
* northeast-stepout: block, evidence-window:first-trusted-square-northeast-stepout-lola, first-trusted-square-northeast-stepout-lola: grade 0.5139499999999998, roughness 5.95975 m

## Routes

- direct-lola-window: block, score 6, grade 1.1593500000000005, roughness 9.250124999999999 m
- west-contour-detour: block, score 6, grade 0.7517000000000025, roughness 8.52791666666666 m
- north-rim-stepout: block, score 6, grade 0.7280000000000001, roughness 7.716124999999998 m
- southwest-bypass: block, score 6, grade 0.6484500000000025, roughness 7.056666666666669 m
- south-stepout: block, score 6, grade 0.7199500000000001, roughness 7.154583333333335 m
* northeast-stepout: block, score 6, grade 0.5139499999999998, roughness 5.95975 m

## Inspector Facts

- Selected cell: first-trusted-square-lola/r3-c2 (inspecting)
- Source datasets: 6 checked datasets (ready)
- Best corridor window: r-12-c+16 -> northeast-stepout (block)
- Power-window evidence: ready (ready)
- Energy window: -1030.061927 Wh margin (block)

## Terrain Cells

- r0 c0: 499.693 m, slope 0.8539999999999992, roughness 13.367999999999995 m, blocked, confidence 0.82
- r0 c1: 482.613 m, slope 0.8729000000000013, roughness 13.603000000000009 m, blocked, confidence 0.82
- r0 c2: 465.155 m, slope 0.8729000000000013, roughness 12.944999999999993 m, blocked, confidence 0.82
- r0 c3: 448.988 m, slope 0.8083499999999987, roughness 9.079999999999984 m, blocked, confidence 0.82
- r1 c0: 490.037 m, slope 0.6847499999999996, roughness 9.164333333333332 m, blocked, confidence 0.82
- r1 c1: 476.342 m, slope 0.8198499999999995, roughness 9.308250000000001 m, blocked, confidence 0.82
- r1 c2: 459.945 m, slope 0.8198499999999995, roughness 8.58175 m, blocked, confidence 0.82
- r1 c3: 450.981 m, slope 0.44819999999999993, roughness 3.7123333333333335 m, blocked, confidence 0.82
- r2 c0: 485.895 m, slope 0.5211500000000001, roughness 5.596999999999999 m, blocked, confidence 0.82
- r2 c1: 475.472 m, slope 0.5885499999999979, roughness 6.201499999999996 m, blocked, confidence 0.82
- r2 c2: 463.701 m, slope 0.6450000000000017, roughness 9.525250000000014 m, blocked, confidence 0.82
- r2 c3: 450.801 m, slope 0.6450000000000017, roughness 7.453333333333338 m, blocked, confidence 0.82
- r3 c0: 483.669 m, slope 0.3227499999999992, roughness 4.340499999999992 m, blocked, confidence 0.82
- r3 c1: 477.214 m, slope 1.1593500000000005, roughness 10.461333333333338 m, blocked, confidence 0.82
* r3 c2: 454.027 m, slope 1.1593500000000005, roughness 15.122333333333339 m, blocked, confidence 0.82
- r3 c3: 441.521 m, slope 0.6252999999999986, roughness 10.892999999999972 m, blocked, confidence 0.82

