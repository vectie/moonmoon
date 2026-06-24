# Moonmoon Fixtures

This directory holds tiny checked source fixtures used to prove Moonmoon data
contracts.

`first_trusted_square_dem.csv` is synthetic. It mirrors the current MoonBit
inline grid so the project has a real source-file boundary, checksum verifier,
and reproducible extractor shape before an authoritative LOLA/LROC-derived
fixture is selected.

Run `python3 scripts/generate_moonmoon_fixture.py` from the repository root to
regenerate `src/terrain/generated_first_trusted_square_fixture.mbt` from this
CSV. Run `python3 scripts/generate_moonmoon_fixture.py --check` to verify the
generated MoonBit file is current without rewriting it. Run
`bash scripts/build_moonmoon_dossier.sh` to verify the source hash, regenerate
the MoonBit fixture, and refresh the exported dossiers.

Do not treat this file as mission-grade lunar data.
