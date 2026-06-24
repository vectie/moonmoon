# Roadmap

Moonmoon should advance through small proof slices. Each slice should leave
behind typed contracts, tests, and durable evidence.

## Milestone 0: Project Shape

Goal: make the repo express its purpose and first boundaries.

- Establish vision, architecture, and roadmap docs.
- Decide initial package layout under `src/`.
- Keep the root package thin.
- Align `moon.mod` with the suite baseline when implementation begins.

Done when a new contributor can understand what Moonmoon owns and what it
deliberately leaves to Moontown, MoonClaw, MoonBook, Moondesk, and Moonrobo.

## Milestone 1: One Trusted Square

Goal: model one small lunar site with explicit provenance.

- Add core types for site bounds, coordinates, terrain cells, provenance, and
  uncertainty.
- Add a tiny DEM fixture.
- Compute elevation range, slope, roughness, and a first hazard hint.
- Export a site dossier as JSON or Markdown.
- Add MoonBit tests for deterministic terrain derivations.
- Render a simple text summary from `cmd/main`.

Done when Moonmoon can answer: "what do we know about this square, where did
that claim come from, and how confident is it?"

Current implementation status:

- `src/core` defines site, bounds, coordinate, terrain cell, provenance,
  uncertainty, and claim-kind labels.
- `src/dataset` defines a dataset manifest contract with coverage, trust,
  checksum kind, checksum, citation, review status, and validation results.
- `src/terrain` builds one deterministic 4x4 trusted-square fixture, computes
  elevation range, neighbor grade, roughness, hazard class, and Markdown/JSON
  fixture exports.
- `data/fixtures/first_trusted_square_dem.csv` is the checked source fixture
  for the current grid, and `scripts/verify_moonmoon_sources.sh` validates its
  SHA-256 before dossier generation.
- `scripts/generate_moonmoon_fixture.py` regenerates the MoonBit fixture module
  from the checked CSV so terrain code does not hand-mirror source values; its
  `--check` mode verifies the generated file is current.
- `src/mission` scores the fixture against a conservative rover traverse
  profile and returns `allow`, `review`, or `block` with reasons.
- `src/site` combines site, dataset, terrain, traverse, blockers, and next
  questions into a site dossier.
- `cmd/main` exposes reproducible `site summary`, `terrain fixture`, and
  `moonbook dossier` commands.

The fixture is still synthetic. It proves the software and evidence contracts;
it does not prove lunar mission validity.

## Milestone 2: First Rabbita Moonviewer

Goal: make the trusted square inspectable.

- Add renderer-agnostic terrain view models.
- Build `src/ui/rabbita-moon` as a real operator surface.
- Render elevation, slope, roughness, and hazard layers.
- Add tile selection and an inspector with source and uncertainty details.
- Keep UI logic separate from terrain derivation.

Done when a human can inspect one site without reading JSON.

## Milestone 3: LunarBook Evidence Loop

Goal: make Moonmoon outputs durable.

- Define a LunarBook dossier layout.
- Export source manifests and derived layer reports into a MoonBook workspace.
- Record source links, checksums, assumptions, and review status.
- Add a review queue for low-confidence or simulated claims.

Done when MoonBook can preserve a site model as evidence, not only as a UI
state.

Current implementation status:

- `src/adapters/moonbook` converts the trusted-square site dossier into
  MoonBook-ready entries and a review queue, including source validation
  entries.
- `scripts/build_moonmoon_dossier.sh` writes stable Markdown/JSON exports under
  `output/site/`, `output/terrain/`, and `output/moonbook/`.
- The review queue currently includes fixture blockers, traverse review
  reasons, and next questions for MoonClaw/operator follow-up.
- The current inline fixture fingerprint verifies successfully against its
  manifest, and the checked CSV fixture verifies against its SHA-256, but the
  fixture is still synthetic.

Remaining work:

- Replace the synthetic manifest with an authoritative LOLA/LROC-backed
  manifest and checksum.
- Write actual MoonBook workspace files rather than only MoonBook-ready export
  summaries.
- Add accepted/rejected review transitions once MoonBook storage exists.

## Milestone 4: MoonClaw Modeling Jobs

Goal: let agents run bounded lunar modeling tasks.

- Define MoonClaw proposal packets for terrain derivation and site comparison.
- Add result receipts for layer generation, validation, and dossier updates.
- Support a task like "score route candidates across this site under current
  constraints."

Done when MoonClaw can run a modeling job and Moonmoon can validate and ingest
the result.

## Milestone 5: Moonrobo Simulation Handoff

Goal: connect terrain to robot action without crossing into unsafe physical
control.

- Define robot-facing route and hazard handoff contracts.
- Export traverse preconditions: slope limits, roughness limits, power budget,
  light window, and confidence.
- Add a simulated Moonrobo task that consumes one Moonmoon route candidate.

Done when Moonrobo can say why a simulated task is allowed, blocked, or needs
more evidence.

## Milestone 6: Operational Moon Tile

Goal: move from static terrain to mission windows.

- Add time-based illumination windows.
- Add basic energy assumptions.
- Add route planning across a small tile grid.
- Add construction-pad and mining-zone checks.
- Show blockers and confidence in Rabbita.

Done when an operator can ask whether a robot can cross from A to B in a given
window and get a cited, uncertainty-aware answer.

## Milestone 7: Moonbase Sandbox

Goal: support early lunar operations planning.

- Model candidate solar ridges, roads, pads, mining zones, and staging areas.
- Add multi-robot route/task simulation hooks.
- Let Moontown schedule repeated site-improvement experiments.
- Let Moonrobo use Moonmoon as a pre-physical safety gate.

Done when Moonmoon becomes the suite's shared lunar operations sandbox.

## Near-Term Engineering Checklist

- Replace the synthetic trusted-square DEM with a tiny authoritative fixture.
- Replace the inline fixture fingerprint with a source-file checksum and a
- Replace the checked synthetic CSV with a tiny authoritative LOLA-derived
  extraction while preserving the same verify/generate/dossier pipeline.
- Add illumination windows and energy assumptions to the mission score.
- Add Rabbita view models for terrain layers, inspector rows, and route
  overlays.
- Add MoonBook workspace materialization and review status transitions.
- Keep running `moon check`, `moon test`, `moon info`, and `moon fmt` for each
  proof slice.
