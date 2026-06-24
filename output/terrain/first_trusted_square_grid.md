# Terrain Fixture: first-trusted-square

## Source

- dataset: fixture-first-trusted-square-dem-v1
- title: Synthetic Shackleton Rim DEM fixture
- trust: curated-fixture
- claim: simulated
- resolution: 10 m
- source path: data/fixtures/first_trusted_square_dem.csv
- source sha256: 45981303392c9be40ce224143409cb675d1a62bb541420a782c4397cce8fbdf7
- extractor: scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt
- checksum kind: inline-fixture-fingerprint
- checksum: inline-grid-v1:tile=first-trusted-square:rows=4:cols=4:cell-size-m=10:cells=16:first=0:last=5.4

## Source Validation

- status: verified
- actual: inline-grid-v1:tile=first-trusted-square:rows=4:cols=4:cell-size-m=10:cells=16:first=0:last=5.4
- note: source fingerprint matches manifest

## Grid

- rows: 4
- cols: 4
- cell size: 10 m
- cells: 16

## Derived Metrics

- elevation range: 5.7 m (-0.3 to 5.4)
- max neighbor grade: 0.26000000000000006
- roughness: 0.9291666666666666 m
- hazard: caution - terrain needs operator review before traverse planning

