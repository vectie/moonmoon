# First Trusted Square / Shackleton Rim rehearsal tile

Purpose: Software proof slice for lunar terrain, uncertainty, and robot traverse reasoning.

Summary: One small lunar site model with explicit provenance, uncertainty, terrain metrics, and first-pass hazard classification.

## Source Datasets

- fixture-first-trusted-square-dem-v1: Synthetic Shackleton Rim DEM fixture
  - trust: curated-fixture
  - review: accepted-for-software-proof
  - resolution: 10 m
  - source path: data/fixtures/first_trusted_square_dem.csv
  - source sha256: 45981303392c9be40ce224143409cb675d1a62bb541420a782c4397cce8fbdf7
  - extractor: scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt
  - checksum kind: inline-fixture-fingerprint
  - checksum: inline-grid-v1:tile=first-trusted-square:rows=4:cols=4:cell-size-m=10:cells=16:first=0:last=5.4

## Source Upgrade Candidates

- candidate-lro-lola-sldem-first-trusted-square: LRO LOLA derived gridded topography candidate
  - mission: Lunar Reconnaissance Orbiter
  - instrument: LOLA
  - product family: GDR/SLDEM derived gridded terrain
  - status: needs-source-upgrade
  - official source: https://pds-geosciences.wustl.edu/missions/lro/lola.htm
  - access: https://ode.rsl.wustl.edu/moon/
  - target path: data/sources/lro_lola/first_trusted_square_dem.csv
  - next action: Select a specific LOLA/SLDEM product, record its source URL and SHA-256, then regenerate the trusted-square fixture.

## Source Acquisition Plans

- acquire-lro-lola-gdr-south-pole-20m-v1: lro-lola-gdr-south-pole-selection
  - candidate: candidate-lro-lola-sldem-first-trusted-square
  - progress: planned:5-steps
  - discovery: https://ode.rsl.wustl.edu/moon/
  - source family: https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/
  - source metadata: https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/catalog/gdr_ds.cat
  - source metadata sha256: f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8
  - source metadata bytes: 5672
  - target region: Shackleton rim rehearsal tile near 89.88S, 0.12E
  - local source directory: data/sources/lro_lola/
  - local metadata path: data/sources/lro_lola/gdr_ds.cat
  - extracted fixture path: data/sources/lro_lola/first_trusted_square_dem.csv
  - trust gate: Do not replace the synthetic fixture until product family URL, metadata URL, selected product URL, SHA-256, extraction window, and generated CSV checksum are recorded.
  - steps:
    - discover: Confirm product family - The source candidate points to a named product family and the acquisition plan names a reachable PDS family root.
    - metadata: Fetch metadata first - The extractor can derive pixel coordinates for the trusted-square bounds without reading the full image into memory.
    - extract: Extract tiny tile - scripts/generate_moonmoon_fixture.py can regenerate MoonBit terrain from the authoritative CSV.
    - validate: Verify evidence chain - moon test passes while the dossier marks the authoritative dataset as accepted for software proof.
    - review: Human review before mission claims - The review queue no longer contains the source-upgrade blocker for this site.

## Source Validation

- fixture-first-trusted-square-dem-v1: verified
  - actual: inline-grid-v1:tile=first-trusted-square:rows=4:cols=4:cell-size-m=10:cells=16:first=0:last=5.4
  - note: source fingerprint matches manifest

## Terrain

- elevation range: 5.7 m (-0.3 to 5.4)
- max neighbor grade: 0.26000000000000006
- roughness: 0.9291666666666666 m
- hazard: caution - terrain needs operator review before traverse planning
- confidence: medium (0.6624)
- provenance: fixture-first-trusted-square-dem-v1 / terrain-metrics.v1

## Traverse Readiness

- profile: Conservative Lunar Rover (conservative-lunar-rover-v1)
- decision: review
- score: 54
- next action: operator should review route and source confidence before simulation
- reasons:
  - max neighbor grade needs route review
  - terrain confidence below traverse threshold

## Blockers

- needs operator review before robot traverse planning
- fixture confidence is not high enough for physical mission planning

## Next Questions

- Replace synthetic DEM with an authoritative LOLA/LROC-backed fixture.
- Add illumination windows for robot energy and thermal constraints.
- Export the dossier into a LunarBook workspace for review.

