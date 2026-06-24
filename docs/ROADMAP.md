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

- Add `src/core` with foundational types and tests.
- Add `src/terrain` with a tiny fixture and deterministic derivations.
- Add `cmd/main` commands for `site summary` and `terrain fixture`.
- Run `moon check`, `moon test`, `moon info`, and `moon fmt`.
- Review `.mbti` diffs to confirm intentional public API changes.
