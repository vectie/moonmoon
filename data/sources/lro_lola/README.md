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
- Discovery URL: <https://ode.rsl.wustl.edu/moon/>
- Intended extraction: Shackleton rim rehearsal tile near 89.88S, 0.12E

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
