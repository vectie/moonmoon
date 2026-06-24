# First Trusted Square / Shackleton Rim rehearsal tile

Purpose: Software proof slice for lunar terrain, uncertainty, and robot traverse reasoning.

Summary: One small lunar site model with explicit provenance, uncertainty, terrain metrics, first-pass hazard classification, a reproducible measured 5x5 route-corridor scan, and a conservative rover energy-window budget.

## Source Datasets

- lro-lola-first-trusted-square-dem-v1: LOLA Shackleton Rim DEM byte-range fixture
  - trust: authoritative
  - review: accepted-for-software-proof
  - resolution: 20 m
  - source path: data/sources/lro_lola/first_trusted_square_dem.csv
  - source sha256: 7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c
  - extractor: scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt
  - checksum kind: inline-fixture-fingerprint
  - checksum: inline-grid-v1:tile=first-trusted-square-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=499.693:last=441.521
- lro-lola-first-trusted-square-west-contour-dem-v1: LOLA west-contour route-window DEM byte-range fixture
  - trust: authoritative
  - review: accepted-for-software-proof
  - resolution: 20 m
  - source path: data/sources/lro_lola/first_trusted_square_west_contour_dem.csv
  - source sha256: 1beb22d539285fe1cf1c83cedb268368e9ed67bd47919c75525e46639e0aa4f6
  - extractor: scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_west_contour_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt
  - checksum kind: inline-fixture-fingerprint
  - checksum: inline-grid-v1:tile=first-trusted-square-west-contour-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=544.454:last=492.629
- lro-lola-first-trusted-square-north-rim-dem-v1: LOLA north-rim route-window DEM byte-range fixture
  - trust: authoritative
  - review: accepted-for-software-proof
  - resolution: 20 m
  - source path: data/sources/lro_lola/first_trusted_square_north_rim_dem.csv
  - source sha256: 40b0ad0e3d85dc6cb9e98a35973efe42d892370a1a3494e66e4af3e200035b28
  - extractor: scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_north_rim_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt
  - checksum kind: inline-fixture-fingerprint
  - checksum: inline-grid-v1:tile=first-trusted-square-north-rim-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=506.517:last=460.176
- lro-lola-first-trusted-square-southwest-bypass-dem-v1: LOLA southwest-bypass corridor DEM byte-range fixture
  - trust: authoritative
  - review: accepted-for-software-proof
  - resolution: 20 m
  - source path: data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv
  - source sha256: c47b837a8ed5bb818c865782396d44dae01b15b03a2a6a83c372548092c1ace5
  - extractor: scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt
  - checksum kind: inline-fixture-fingerprint
  - checksum: inline-grid-v1:tile=first-trusted-square-southwest-bypass-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=548.224:last=505.456
- lro-lola-first-trusted-square-south-stepout-dem-v1: LOLA south-stepout corridor DEM byte-range fixture
  - trust: authoritative
  - review: accepted-for-software-proof
  - resolution: 20 m
  - source path: data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv
  - source sha256: dde783fcf74ac0567bb2d6bb8eead6c2f83b620603319690aa51011486d7a19c
  - extractor: scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt
  - checksum kind: inline-fixture-fingerprint
  - checksum: inline-grid-v1:tile=first-trusted-square-south-stepout-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=453.571:last=409.003

## Source Upgrade Candidates

- candidate-lro-lola-sldem-first-trusted-square: LRO LOLA derived gridded topography candidate
  - mission: Lunar Reconnaissance Orbiter
  - instrument: LOLA
  - product family: GDR/SLDEM derived gridded terrain
  - status: accepted-for-software-proof
  - official source: https://pds-geosciences.wustl.edu/missions/lro/lola.htm
  - access: https://ode.rsl.wustl.edu/moon/
  - target path: data/sources/lro_lola/first_trusted_square_dem.csv plus adjacent route-window CSVs
  - next action: Use the checked LOLA byte-range fixtures for software proof, then add illumination and wider corridor search before any rover claim.
- candidate-lunar-solar-ephemeris-first-trusted-square: Lunar solar ephemeris power-window candidate
  - mission: NASA NAIF SPICE / planetary ephemeris
  - instrument: SPICE kernels
  - product family: Sun/Moon ephemeris and lunar orientation kernels
  - status: needs-source-upgrade
  - official source: https://naif.jpl.nasa.gov/naif/data.html
  - access: https://naif.jpl.nasa.gov/pub/naif/generic_kernels/
  - target path: data/sources/lunar_ephemeris/first_trusted_square_power_window.json
  - next action: Select pinned SPICE kernels or an equivalent official illumination source, record checksums, and generate the MoonBit power-window module before clearing the energy gate.

## Source Acquisition Plans

- acquire-lro-lola-gdr-south-pole-20m-v1: lro-lola-gdr-south-pole-selection
  - candidate: candidate-lro-lola-sldem-first-trusted-square
  - progress: recorded:5-steps
  - discovery: https://ode.rsl.wustl.edu/moon/
  - source family: https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/
  - source metadata: https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/catalog/gdr_ds.cat
  - source metadata sha256: f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8
  - source metadata bytes: 5672
  - target region: Shackleton rim rehearsal tile near 89.88S, 0.12E
  - local source directory: data/sources/lro_lola/
  - local metadata path: data/sources/lro_lola/gdr_ds.cat
  - extracted fixture path: data/sources/lro_lola/first_trusted_square_dem.csv and adjacent route-window CSVs
  - trust gate: The active software-proof fixtures must keep product family URL, metadata URL, selected product URL, SHA-256, extraction windows, and generated CSV checksums recorded.
  - steps:
    - discover: Confirm product family - The source candidate points to a named product family and the acquisition plan names a reachable PDS family root.
    - metadata: Fetch metadata first - The extractor can derive pixel coordinates for the trusted-square bounds without reading the full image into memory.
    - extract: Extract tiny tile - scripts/generate_moonmoon_fixture.py regenerates MoonBit terrain from the authoritative CSV.
    - validate: Verify evidence chain - moon test passes while the dossier marks the authoritative dataset as accepted for software proof.
    - review: Human review before mission claims - The source-upgrade blocker is closed and remaining review focuses on terrain hazards, illumination, and route alternatives.
- acquire-lunar-solar-ephemeris-first-trusted-square-v1: lunar-solar-ephemeris-power-window
  - candidate: candidate-lunar-solar-ephemeris-first-trusted-square
  - progress: recorded:5-steps
  - discovery: https://naif.jpl.nasa.gov/naif/data.html
  - source family: https://naif.jpl.nasa.gov/pub/naif/generic_kernels/
  - source metadata: https://naif.jpl.nasa.gov/pub/naif/generic_kernels/
  - source metadata sha256: pending
  - source metadata bytes: 0
  - target region: First Trusted Square near Shackleton rim, 89.88S, 0.12E
  - local source directory: data/sources/lunar_ephemeris/
  - local metadata path: data/sources/lunar_ephemeris/README.md
  - extracted fixture path: data/sources/lunar_ephemeris/first_trusted_square_power_window.json
  - trust gate: Must cite official ephemeris/illumination source, pin source checksums, compute sunlit/dark hours, and regenerate src/mission/generated_first_trusted_square_power_window.mbt before energy can move out of block.
  - steps:
    - discover-source: Select official ephemeris source - The candidate names a concrete official source instead of a generic power assumption.
    - pin-kernels: Pin checksummed inputs - scripts/verify_moonmoon_sources.sh can reject missing or changed ephemeris inputs.
    - compute-local-window: Compute local power window - The JSON records time range, source checksums, local coordinate, sunlit hours, dark hours, and uncertainty.
    - generate-moonbit-window: Generate MoonBit evidence - moon test proves the mission energy gate reads generated ephemeris evidence instead of hard-coded zero Wh.
    - review-energy-gate: Review before unblocking Moonrobo - Moonrobo handoff remains blocked or becomes reviewable based on measured terrain plus accepted time-windowed power evidence.

## Source Product Selections

- select-ldem-875s-20m-float-v1: ldem_875s_20m_float
  - plan: acquire-lro-lola-gdr-south-pole-20m-v1
  - status: accepted-for-software-proof
  - product lid: urn:nasa:pds:lro_lola_rdr:data_gridded:ldem_875s_20m_float
  - image: https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img
  - label: https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.xml
  - local label path: data/sources/lro_lola/ldem_875s_20m_float.xml
  - label sha256: 10d62a66364276d544168949a11a93580e748aaff78f8cf946837d98d077ff53
  - label bytes: 11629
  - image bytes: 230068224
  - projection: Polar Stereographic
  - resolution: 20 m
  - bounds: -90..-87.5 lat, 0..360 lon
  - shape: 7584 lines x 7584 samples
  - data: IEEE754LSBSingle / KILOMETER, offset 1737.4 km
  - reason: Covers the first trusted square near 89.88S with south-polar 20 m/pixel LOLA DEM data and has a small pinned XML label for extractor development.
  - extraction risk: The image is about 230 MB and should be window-read from the float raster after projection math is tested; do not commit the raw image.

## Source Extraction Candidates

- extract-ldem-875s-20m-first-trusted-square-v1: first-trusted-square-lola
  - selection: select-ldem-875s-20m-float-v1
  - status: accepted-for-software-proof
  - generated by: scripts/extract_lola_trusted_square.py
  - output path: data/sources/lro_lola/first_trusted_square_dem.csv
  - output sha256: 7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c
  - output bytes: 636
  - center: -89.88, 0.12
  - source window: row 3972, col 3790, 4x4
  - cell size: 20 m
  - elevation unit: meters relative to 1737.4 km reference radius
  - claim: measured
  - notes:
    - Generated from HTTP byte ranges against ldem_875s_20m_float.img, not from a committed raw image.
    - This extraction is the active Moonmoon trusted-square fixture for software proof.
    - The output CSV keeps the small Moonmoon fixture shape while replacing synthetic values with measured LOLA DEM values.
- extract-ldem-875s-20m-west-contour-v1: first-trusted-square-west-contour-lola
  - selection: select-ldem-875s-20m-float-v1
  - status: accepted-for-software-proof
  - generated by: scripts/extract_lola_trusted_square.py
  - output path: data/sources/lro_lola/first_trusted_square_west_contour_dem.csv
  - output sha256: 1beb22d539285fe1cf1c83cedb268368e9ed67bd47919c75525e46639e0aa4f6
  - output bytes: 844
  - center: -89.88, 0.08
  - source window: row 3972, col 3786, 4x4
  - cell size: 20 m
  - elevation unit: meters relative to 1737.4 km reference radius
  - claim: measured
  - notes:
    - Generated from the west-adjacent HTTP byte ranges next to the active trusted-square window.
    - This window gives the west-contour route candidate measured terrain evidence rather than a hand-authored estimate.
    - The local window is still too small for mission-grade corridor planning.
- extract-ldem-875s-20m-north-rim-v1: first-trusted-square-north-rim-lola
  - selection: select-ldem-875s-20m-float-v1
  - status: accepted-for-software-proof
  - generated by: scripts/extract_lola_trusted_square.py
  - output path: data/sources/lro_lola/first_trusted_square_north_rim_dem.csv
  - output sha256: 40b0ad0e3d85dc6cb9e98a35973efe42d892370a1a3494e66e4af3e200035b28
  - output bytes: 796
  - center: -89.86, 0.12
  - source window: row 3968, col 3790, 4x4
  - cell size: 20 m
  - elevation unit: meters relative to 1737.4 km reference radius
  - claim: measured
  - notes:
    - Generated from the north-adjacent HTTP byte ranges next to the active trusted-square window.
    - This window gives the north-rim route candidate measured terrain evidence before illumination analysis exists.
    - The local window is still too small for mission-grade corridor planning.
- extract-ldem-875s-20m-southwest-bypass-v1: first-trusted-square-southwest-bypass-lola
  - selection: select-ldem-875s-20m-float-v1
  - status: accepted-for-software-proof
  - generated by: scripts/extract_lola_trusted_square.py
  - output path: data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv
  - output sha256: c47b837a8ed5bb818c865782396d44dae01b15b03a2a6a83c372548092c1ace5
  - output bytes: 908
  - center: -89.9, 0.04
  - source window: row 3980, col 3782, 4x4
  - cell size: 20 m
  - elevation unit: meters relative to 1737.4 km reference radius
  - claim: measured
  - notes:
    - Generated from the wider southwest HTTP byte ranges after the first adjacent west/north windows remained blocked.
    - This is the lowest-grade window in the first 5x5 corridor scan, but still exceeds the conservative rover traverse limits.
    - The local window is still too small for mission-grade corridor planning.
- extract-ldem-875s-20m-south-stepout-v1: first-trusted-square-south-stepout-lola
  - selection: select-ldem-875s-20m-float-v1
  - status: accepted-for-software-proof
  - generated by: scripts/extract_lola_trusted_square.py
  - output path: data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv
  - output sha256: dde783fcf74ac0567bb2d6bb8eead6c2f83b620603319690aa51011486d7a19c
  - output bytes: 860
  - center: -89.9, 0.12
  - source window: row 3980, col 3790, 4x4
  - cell size: 20 m
  - elevation unit: meters relative to 1737.4 km reference radius
  - claim: measured
  - notes:
    - Generated from the wider south HTTP byte ranges after the first adjacent west/north windows remained blocked.
    - This window is smoother than the active patch but still exceeds conservative rover traverse limits.
    - The local window is still too small for mission-grade corridor planning.

## Source Validation

- lro-lola-first-trusted-square-dem-v1: verified
  - actual: inline-grid-v1:tile=first-trusted-square-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=499.693:last=441.521
  - note: source fingerprint matches manifest
- lro-lola-first-trusted-square-west-contour-dem-v1: verified
  - actual: inline-grid-v1:tile=first-trusted-square-west-contour-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=544.454:last=492.629
  - note: source fingerprint matches manifest
- lro-lola-first-trusted-square-north-rim-dem-v1: verified
  - actual: inline-grid-v1:tile=first-trusted-square-north-rim-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=506.517:last=460.176
  - note: source fingerprint matches manifest
- lro-lola-first-trusted-square-southwest-bypass-dem-v1: verified
  - actual: inline-grid-v1:tile=first-trusted-square-southwest-bypass-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=548.224:last=505.456
  - note: source fingerprint matches manifest
- lro-lola-first-trusted-square-south-stepout-dem-v1: verified
  - actual: inline-grid-v1:tile=first-trusted-square-south-stepout-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=453.571:last=409.003
  - note: source fingerprint matches manifest

## Terrain

- elevation range: 58.17199999999997 m (441.521 to 499.693)
- max neighbor grade: 1.1593500000000005
- roughness: 9.250124999999999 m
- hazard: blocked - neighbor grade or roughness exceeds early rover traverse limits
- confidence: medium (0.7544)
- provenance: lro-lola-first-trusted-square-dem-v1 / terrain-metrics.v1

## Traverse Readiness

- profile: Conservative Lunar Rover (conservative-lunar-rover-v1)
- decision: block
- score: 20
- next action: choose alternate route or improve terrain evidence
- reasons:
  - max neighbor grade exceeds rover hard limit
  - roughness exceeds rover hard limit

## Corridor Scan

- scan: first-trusted-square-5x5-corridor-scan-v1
- windows ranked: 25
- best measured window: r+8-c-8 (rank 1)
- offset: row 8, col -8
- selected route: southwest-bypass
- decision: block
- max neighbor grade: 0.64845
- roughness: 7.056667 m
- note: lowest max-neighbor-grade window in this measured 5x5 scan; still blocked
- top windows:
  - #1 r+8-c-8: grade 0.64845, roughness 7.056667 m, decision block, route southwest-bypass
  - #2 r+4-c-8: grade 0.6913, roughness 9.079875 m, decision block
  - #3 r+0-c+8: grade 0.7054, roughness 8.517167 m, decision block
  - #4 r-4-c-8: grade 0.7091, roughness 8.112583 m, decision block
  - #5 r-4-c+8: grade 0.7125, roughness 8.56275 m, decision block

## Power Window Evidence

- evidence: first-trusted-square-power-window-missing-v1
- source status: missing-source
- source family: https://naif.jpl.nasa.gov/pub/naif/generic_kernels/
- local source path: data/sources/lunar_ephemeris/first_trusted_square_power_window.json
- source sha256: pending
- source bytes: 0
- time window: pending -> pending
- sunlit hours: 0
- dark hours: 0
- available energy: 0 Wh
- confidence: 0
- has time-windowed ephemeris: false
- reasons:
  - official ephemeris or illumination source is not pinned yet
  - source checksum and byte count are intentionally pending
  - energy gate must remain blocked until generated evidence carries a real time window

## Energy Window

- budget: Conservative South Pole Rover Energy Budget (conservative-south-pole-energy-v1)
- power-window evidence: first-trusted-square-power-window-missing-v1
- power-window source: data/sources/lunar_ephemeris/first_trusted_square_power_window.json
- power-window source status: missing-source
- time window: pending -> pending
- decision: block
- route candidates: 5
- blocked route candidates: 5
- estimated drive hours: 1.25
- estimated dark survival hours: 2
- required energy: 845 Wh
- verified available energy: 0 Wh
- energy margin: -845 Wh
- next action: attach time-windowed solar ephemeris and verify rover energy budget before simulation
- reasons:
  - no time-windowed solar ephemeris is attached for energy planning
  - power-window evidence first-trusted-square-power-window-missing-v1 has source status missing-source
  - estimated energy demand exceeds verified available energy
  - 5 route candidates remain blocked before energy simulation

## Route Candidates

- direct-lola-window: Direct traverse across measured LOLA patch
  - decision: block
  - score: 6
  - strategy: Use the active 4x4 measured window as-is.
  - evidence dataset: lro-lola-first-trusted-square-dem-v1
  - evidence tile: first-trusted-square-lola
  - evidence source: data/sources/lro_lola/first_trusted_square_dem.csv
  - evidence summary: blocked measured window; elevation range 58.17199999999997 m
  - expected max grade: 1.1593500000000005
  - expected roughness: 9.250124999999999 m
  - confidence: 0.7544
  - illumination decision: block
  - illumination evidence: first-trusted-square-power-window-missing-v1
  - illumination source status: missing-source
  - illumination risk: 0.3635749999999998
  - illumination confidence: 0.45263999999999993
  - illumination next action: attach time-windowed solar ephemeris and widen terrain evidence before route simulation
  - illumination reasons:
    - no time-windowed solar ephemeris is attached
    - power-window evidence first-trusted-square-power-window-missing-v1 has source status missing-source
    - local relief shadow proxy exceeds conservative limit
    - illumination confidence below power planning threshold
  - next action: do not traverse directly; use this as the baseline hazard case
  - reasons:
    - expected grade exceeds rover hard limit
    - expected roughness exceeds rover hard limit
    - active LOLA patch is blocked
    - illumination gate is block
- west-contour-detour: West contour detour candidate
  - decision: block
  - score: 6
  - strategy: Test the west-adjacent LOLA window as a possible contour route around the active patch.
  - evidence dataset: lro-lola-first-trusted-square-west-contour-dem-v1
  - evidence tile: first-trusted-square-west-contour-lola
  - evidence source: data/sources/lro_lola/first_trusted_square_west_contour_dem.csv
  - evidence summary: blocked measured window; elevation range 51.82499999999993 m
  - expected max grade: 0.7517000000000025
  - expected roughness: 8.52791666666666 m
  - confidence: 0.7544
  - illumination decision: block
  - illumination evidence: first-trusted-square-power-window-missing-v1
  - illumination source status: missing-source
  - illumination risk: 0.32390624999999956
  - illumination confidence: 0.45263999999999993
  - illumination next action: attach time-windowed solar ephemeris and widen terrain evidence before route simulation
  - illumination reasons:
    - no time-windowed solar ephemeris is attached
    - power-window evidence first-trusted-square-power-window-missing-v1 has source status missing-source
    - local relief shadow proxy exceeds conservative limit
    - illumination confidence below power planning threshold
  - next action: widen the west corridor extraction before simulation
  - reasons:
    - expected grade exceeds rover hard limit
    - expected roughness exceeds rover hard limit
    - west-adjacent LOLA window is measured but still blocked at this scale
    - illumination gate is block
- north-rim-stepout: North rim step-out candidate
  - decision: block
  - score: 6
  - strategy: Test the north-adjacent LOLA window as a possible step-out toward a smoother rim approach.
  - evidence dataset: lro-lola-first-trusted-square-north-rim-dem-v1
  - evidence tile: first-trusted-square-north-rim-lola
  - evidence source: data/sources/lro_lola/first_trusted_square_north_rim_dem.csv
  - evidence summary: blocked measured window; elevation range 46.34100000000001 m
  - expected max grade: 0.7280000000000001
  - expected roughness: 7.716124999999998 m
  - confidence: 0.7544
  - illumination decision: block
  - illumination evidence: first-trusted-square-power-window-missing-v1
  - illumination source status: missing-source
  - illumination risk: 0.28963125000000006
  - illumination confidence: 0.45263999999999993
  - illumination next action: attach time-windowed solar ephemeris and widen terrain evidence before route simulation
  - illumination reasons:
    - no time-windowed solar ephemeris is attached
    - power-window evidence first-trusted-square-power-window-missing-v1 has source status missing-source
    - local relief shadow proxy exceeds conservative limit
    - illumination confidence below power planning threshold
  - next action: widen the north corridor extraction and add illumination review
  - reasons:
    - expected grade exceeds rover hard limit
    - expected roughness exceeds rover hard limit
    - north-adjacent LOLA window is measured but still blocked at this scale
    - illumination gate is block
- southwest-bypass: Southwest widened bypass candidate
  - decision: block
  - score: 6
  - strategy: Use the lowest-grade measured window from the first 5x5 corridor scan as a possible bypass direction.
  - evidence dataset: lro-lola-first-trusted-square-southwest-bypass-dem-v1
  - evidence tile: first-trusted-square-southwest-bypass-lola
  - evidence source: data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv
  - evidence summary: blocked measured window; elevation range 42.76800000000003 m
  - expected max grade: 0.6484500000000025
  - expected roughness: 7.056666666666669 m
  - confidence: 0.7544
  - illumination decision: block
  - illumination evidence: first-trusted-square-power-window-missing-v1
  - illumination source status: missing-source
  - illumination risk: 0.2673000000000002
  - illumination confidence: 0.45263999999999993
  - illumination next action: attach time-windowed solar ephemeris and widen terrain evidence before route simulation
  - illumination reasons:
    - no time-windowed solar ephemeris is attached
    - power-window evidence first-trusted-square-power-window-missing-v1 has source status missing-source
    - local relief shadow proxy exceeds conservative limit
    - illumination confidence below power planning threshold
  - next action: continue corridor search beyond the southwest bypass before simulation
  - reasons:
    - expected grade exceeds rover hard limit
    - expected roughness exceeds rover hard limit
    - southwest widened corridor is measured and lower risk but still blocked
    - illumination gate is block
- south-stepout: South step-out candidate
  - decision: block
  - score: 6
  - strategy: Use the south measured window from the first 5x5 corridor scan as a second widened route direction.
  - evidence dataset: lro-lola-first-trusted-square-south-stepout-dem-v1
  - evidence tile: first-trusted-square-south-stepout-lola
  - evidence source: data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv
  - evidence summary: blocked measured window; elevation range 44.56800000000004 m
  - expected max grade: 0.7199500000000001
  - expected roughness: 7.154583333333335 m
  - confidence: 0.7544
  - illumination decision: block
  - illumination evidence: first-trusted-square-power-window-missing-v1
  - illumination source status: missing-source
  - illumination risk: 0.27855000000000024
  - illumination confidence: 0.45263999999999993
  - illumination next action: attach time-windowed solar ephemeris and widen terrain evidence before route simulation
  - illumination reasons:
    - no time-windowed solar ephemeris is attached
    - power-window evidence first-trusted-square-power-window-missing-v1 has source status missing-source
    - local relief shadow proxy exceeds conservative limit
    - illumination confidence below power planning threshold
  - next action: continue south corridor extraction and add ephemeris-backed illumination review
  - reasons:
    - expected grade exceeds rover hard limit
    - expected roughness exceeds rover hard limit
    - south widened corridor is measured and smoother than the active patch but still blocked
    - illumination gate is block

## Blockers

- terrain exceeds early traverse limits
- requires alternate route or stronger dataset

## Next Questions

- Attach time-windowed solar ephemeris for robot energy and thermal constraints.
- Continue widening the corridor search because the best measured southwest window is still blocked.
- Review the materialized LunarBook workspace entries and close accepted or rejected queue items.

