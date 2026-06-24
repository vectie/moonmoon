# LRO LOLA Source Acquisition Plan

This directory is reserved for reproducible source evidence that upgrades
Moonmoon from a synthetic terrain fixture to a tiny authoritative lunar terrain
extraction.

The current repository does not commit the raw LOLA product. The active
first-trusted-square terrain remains `data/fixtures/first_trusted_square_dem.csv`
until a small extracted CSV is generated and checked from an official source.

## First Target

- Candidate: `candidate-lro-lola-sldem-first-trusted-square`
- Product family id: `lro-lola-gdr-south-pole-selection`
- Product family: LRO LOLA GDR, selected through ODE/PDS metadata
- Source family URL: <https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/>
- Source metadata URL: <https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/catalog/gdr_ds.cat>
- Source metadata path: `data/sources/lro_lola/gdr_ds.cat`
- Source metadata SHA-256: `f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8`
- Source metadata bytes: `5672`
- Discovery URL: <https://ode.rsl.wustl.edu/moon/>
- Intended extraction: Shackleton rim rehearsal tile near 89.88S, 0.12E

## First Product Selection

- Product id: `ldem_875s_20m_float`
- Product LID: `urn:nasa:pds:lro_lola_rdr:data_gridded:ldem_875s_20m_float`
- Image URL: <https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img>
- XML label URL: <https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.xml>
- XML label path: `data/sources/lro_lola/ldem_875s_20m_float.xml`
- XML label SHA-256: `10d62a66364276d544168949a11a93580e748aaff78f8cf946837d98d077ff53`
- XML label bytes: `11629`
- Image bytes from PDS listing: `230068224`
- Projection: Polar Stereographic
- Resolution: 20 m/pixel
- Bounds: 90S to 87.5S, 0E to 360E
- Shape: 7584 lines x 7584 samples
- Data type: `IEEE754LSBSingle`
- Unit: `KILOMETER`
- Value offset: `1737.4` km

## Reproduction

Fetch and verify the current pinned catalog:

```bash
bash scripts/fetch_lola_metadata.sh
```

Verify all pinned source evidence without network access:

```bash
bash scripts/verify_moonmoon_sources.sh
```

## Trust Gate

Do not replace the synthetic fixture until the following evidence is recorded:

- official source family URL and metadata URL
- selected product URL after ODE/PDS discovery
- source metadata SHA-256
- raw image SHA-256 when practical
- extraction window and projection math
- extracted CSV SHA-256
- generated inline grid fingerprint
- passing `scripts/verify_moonmoon_sources.sh`
- passing `moon test`

The expected extracted output path is
`data/sources/lro_lola/first_trusted_square_dem.csv`.
