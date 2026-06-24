# Terrain Fixture: first-trusted-square-lola

## Source

- dataset: lro-lola-first-trusted-square-dem-v1
- title: LOLA Shackleton Rim DEM byte-range fixture
- trust: authoritative
- claim: measured
- resolution: 20 m
- source path: data/sources/lro_lola/first_trusted_square_dem.csv
- source sha256: 7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c
- extractor: scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt
- checksum kind: inline-fixture-fingerprint
- checksum: inline-grid-v1:tile=first-trusted-square-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=499.693:last=441.521

## Source Validation

- status: verified
- actual: inline-grid-v1:tile=first-trusted-square-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=499.693:last=441.521
- note: source fingerprint matches manifest

## Grid

- rows: 4
- cols: 4
- cell size: 20 m
- cells: 16

## Derived Metrics

- elevation range: 58.17199999999997 m (441.521 to 499.693)
- max neighbor grade: 1.1593500000000005
- roughness: 9.250124999999999 m
- hazard: blocked - neighbor grade or roughness exceeds early rover traverse limits

