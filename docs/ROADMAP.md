# Roadmap

Moonmoon should advance through small proof slices. Each slice should leave
behind typed contracts, tests, and durable evidence.

## Milestone 0: Project Shape

Goal: make the repo express its purpose and first boundaries.

- Establish vision, architecture, and roadmap docs.
- Decide initial package layout under `src/`.
- Keep the root package thin.
- Align `moon.mod` with the suite baseline when implementation begins.
- Keep a standalone `src/kernel` package as the product spine for layers,
  evidence gates, suite boundaries, and the active build queue.

Done when a new contributor can understand what Moonmoon owns and what it
deliberately leaves to Moontown, MoonClaw, MoonBook, Moondesk, and Moonrobo.

Current rebuild stance:

- MoonMoon is a standalone lunar world-model project, not a stale port of
  `../tl-2022` and not a submodule of MoonTown.
- `../tl-2022` contributes the high-level lesson that terrain products should
  be DEM/source/evidence driven.
- `../moontown` contributes the high-level lesson that durable truth should
  live in documents, ledgers, review gates, and protocol boundaries.
- The highest-leverage next implementation is to make the live Rabbita Moon
  operator flow concise and evidence-first, because movable lunar context,
  blocker clearance, and robot authority need to work as one product surface
  instead of scattered generated artifacts.

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
- `src/terrain` builds one deterministic 4x4 trusted-square fixture plus
  measured route-window fixtures from the adjacent and first widened corridor
  scans, computes elevation range, neighbor grade, roughness, hazard class, and
  Markdown/JSON fixture exports.
- `data/sources/lro_lola/first_trusted_square_dem.csv` and the adjacent
  route-window and widened corridor CSVs are checked LOLA byte-range source
  fixtures, and `scripts/verify_moonmoon_sources.sh` validates their SHA-256
  before dossier generation.
- `data/sources/lro_lola/first_trusted_square_corridor_scan.csv` records the
  reproducible 5x5 LOLA corridor ranking, so route promotion is tied to the
  whole measured search surface rather than one manually chosen sample.
- `data/sources/lro_lola/first_trusted_square_corridor_scan_v2.csv` now pins
  the active 9x9 LOLA corridor scan as source evidence. It covers 81 measured
  windows and still blocks every sampled local window, while the best measured
  window is now promoted as `northeast-stepout`.
- `scripts/generate_moonmoon_fixture.py` regenerates the MoonBit fixture module
  from the checked CSV so terrain code does not hand-mirror source values; its
  `--check` mode verifies the generated file is current.
- `src/mission` scores the fixture against a conservative rover traverse
  profile and returns `allow`, `review`, or `block` with reasons.
- `src/mission` also scores route alternatives for the blocked LOLA patch:
  the direct measured window remains blocked, the measured west/north adjacent
  windows are blocked, and the first widened southwest/south corridor windows
  are lower risk but still blocked at this sampling scale.
- `src/mission` exposes the ranked 9x9 corridor scan as typed MoonBit data.
  The best measured window is `r-12-c+16`; it selects `northeast-stepout` and
  still blocks under conservative terrain and power gates.
- `src/mission` adds a conservative south-pole illumination/power gate for each
  route candidate. It uses measured local relief as an early shadow-risk proxy
  and blocks execution until time-windowed solar ephemeris is attached.
- `src/mission` also adds a conservative rover energy-window budget. It records
  estimated drive/dark-survival energy demand, verified available energy, and
  margin, then blocks until time-windowed ephemeris can prove available power.
- `src/dataset` now records that missing power source as a typed ephemeris
  source candidate and acquisition plan, so MoonBook can review exact SPICE or
  equivalent illumination inputs before the energy gate changes state.
- `data/sources/lunar_ephemeris/first_trusted_square_power_window.json` now
  stores a checked computed power-window fixture. `scripts/compute_power_window.py`
  computes it from the pinned DE440s SPK, and `scripts/generate_power_window.py`
  mirrors it into generated MoonBit evidence consumed by the mission energy and
  illumination gates.
- The power-window fixture now carries structured source-file and computation
  metadata. It pins the NAIF kernel inventory with local copies, byte counts,
  and checksums; ready evidence must report a computed local window instead of
  only flipping a status string.
- `src/site` combines site, dataset, terrain, traverse, blockers, and next
  questions into a site dossier.
- `src/adapters/moonrobo` exports robot-facing simulation precondition packets
  for each route candidate, using Moonmoon terrain, illumination, energy, and
  corridor blockers as a pre-physical safety gate.
- `src/adapters/moonclaw` exports bounded modeling proposals for ephemeris
  acquisition, widened corridor search, route scoring, and the first accepted
  route-scoring and corridor-expansion receipts plus a needs-review ephemeris
  receipt that still keeps Moonrobo blocked.
- `src/adapters/moonclaw` also emits a concrete ephemeris acquisition task
  packet. It names the current evidence inputs, source artifacts, generator
  commands, validation gates, artifact readiness, blocker reasons, and Moonrobo
  safety condition required before the missing power-window evidence can become
  a reviewed robot-facing input.
- `src/adapters/moonclaw` now emits a matching corridor expansion task packet
  for the promoted 9x9 search. It preserves the 5x5 scan as baseline evidence
  while marking the widened CSV, generated MoonBit scan, and MoonBook workspace
  ready.
- `cmd/main` exposes reproducible `site summary`, `terrain fixture`, and
  `moonbook dossier` commands, plus MoonClaw proposal and Moonrobo handoff
  Markdown/JSON.

The active fixture is now measured LOLA DEM evidence accepted for Moonmoon
software proof. It does not prove lunar mission validity; it currently blocks
the conservative rover profile and asks for alternate route modeling.

## Milestone 2: First Rabbita Moonviewer

Goal: make the trusted square inspectable.

- Add renderer-agnostic terrain view models.
- Build `src/ui/rabbita_moon` as a real operator surface.
- Open with a live, movable Moon-scale view before the local trusted-square
  detail view.
- Render elevation, slope, roughness, and hazard layers.
- Add tile selection and an inspector with source and uncertainty details.
- Keep UI logic separate from terrain derivation.

Done when a human can inspect one site without reading JSON.

Current implementation status:

- `src/ui` exposes a renderer-neutral trusted-square operator view with
  viewport geometry, layer toggles, per-cell layer intensities, route overlays,
  a selected-tile inspector, source panel, and scorecard.
- `cmd/main -- ui view` renders that model as Markdown, while `json` exposes
  the same contract for future Rabbita/Lepusa browser surfaces.
- `scripts/build_moonmoon_dossier.sh` publishes the current UI contract under
  `output/ui/first_trusted_square_view.{md,json}`.
- Rabbita Moon now initializes selected-route clearance controls from the
  embedded MoonBook review queue and transition ledger. Imported accepted,
  rejected, and request-evidence states render back into the controls and the
  next export JSON instead of resetting every clearance item to
  request-evidence.
- Imported Rabbita clearance decisions now also generate a MoonRobo readiness
  preview under `output/moonrobo/` during the import workflow. The preview lets
  an all-accepted clearance fixture show selected-route clearance as allowed
  while preserving blocked simulation readiness and denied hardware authority.
- That preview now includes a blocker gap report. It names the remaining
  terrain, illumination, energy, MoonBook, and robot-simulation gates with
  evidence paths, clearance status, and next actions after imported clearance
  has been accepted.
- The import workflow now emits a MoonClaw remediation task packet from that
  gap report. The packet names the accepted clearance input, remaining blocker
  artifacts, concrete remediation commands, acceptance checks, and robot-safety
  invariants that keep hardware authority denied.
- Imported transition builds now materialize that MoonClaw remediation task
  into the MoonBook workspace index, manifest, and per-entry payloads, giving
  the generated task the same durable evidence surface as baseline MoonClaw
  tasks.
- The import workflow also emits a MoonClaw remediation receipt. The receipt
  accounts for every current MoonRobo blocker gap as still blocking or cleared
  evidence, and preserves the denied hardware authority invariant.
- Imported transition builds now materialize the remediation receipt into the
  MoonBook workspace beside the generated task, making both the requested work
  and its current gap accounting durable evidence.
- Rabbita Moon now exposes the imported MoonClaw gap task and receipt entries
  from the embedded MoonBook dossier, including remaining gap count and denied
  hardware authority, so operators can inspect them in the review surface.
- The imported workflow now emits a MoonRobo gap remediation modeling pass. It
  consumes the MoonClaw gap task and readiness preview, evaluates the bounded
  terrain, illumination, energy, MoonBook, and simulation commands, and records
  that every current gap remains blocked under denied hardware authority.
- Imported transition builds now materialize that modeling pass into MoonBook
  beside the gap task and receipt, so the bounded all-still-blocked result is
  durable workspace evidence.
- Rabbita now starts with a live WebGL Moon globe backed by a local real-data
  texture and source metadata.
- The globe supports drag rotation, wheel/pinch zoom, reset/home, and
  fly-to-trusted-square controls.
- The opening viewport renders MoonBit-owned evidence as overlays: first
  trusted-square footprint, selected route trace, 81 measured LOLA corridor
  windows, blocker count, and hardware-denied authority state.
- The globe includes operator instruments: coordinate readout, compass, scale
  bar, and graticule with layer toggles.
- The mission evidence queue is now discovered from embedded MoonBook entries
  instead of maintained as a fixed browser-side list, keeping the operator deck
  aligned with generated evidence as new remediation and receipt packets land.
- `scripts/build_rabbita_ui.sh` now publishes the complete standalone Rabbita
  bundle and verifies that generated HTML asset references are source-synced,
  so the live operator page no longer depends on manual asset copying. The same
  build also smoke-checks runtime boot, evidence queue counts, and export
  invariants through the shared Rabbita harness.
- The existing NASA south-pole landscape and SVG LOLA corridor map remain the
  local detail and fallback context after the Moon-scale opening view.
- Browser-level verification now checks that the WebGL canvas is nonblank,
  controls work, overlays render, and text/controls do not overlap on desktop
  or mobile.

Next live-viewer slice:

- Reduce the Rabbita page into a smaller operator deck around the globe,
  trusted-square detail, evidence queue, and blocker clearance.
- Move presentation assets out of generated MoonBit strings where that improves
  maintainability without letting browser code own mission decisions.
- Preserve the MoonBit boundary: terrain derivation, route scoring, power
  gates, review state, and robot authority remain model outputs.

## Milestone 3: MoonBook Evidence Loop

Goal: make Moonmoon outputs durable.

- Define a MoonBook dossier layout.
- Export source manifests and derived layer reports into a MoonBook workspace.
- Record source links, checksums, assumptions, and review status.
- Add a review queue for low-confidence or simulated claims.

Done when MoonBook can preserve a site model as evidence, not only as a UI
state.

Current implementation status:

- `src/adapters/moonbook` converts the trusted-square site dossier into
  MoonBook entries and a review queue, including source validation entries.
- `scripts/build_moonmoon_dossier.sh` writes stable Markdown/JSON exports under
  `output/site/`, `output/terrain/`, and `output/moonbook/`.
- `scripts/materialize_moonbook_workspace.py` turns the aggregate site and
  MoonBook JSON dossiers into per-entry workspace files under
  `output/moonbook/workspaces/first-trusted-square/`.
- MoonBook review work now carries item status and a deterministic transition
  log, including accepted workspace materialization, rejected direct traverse,
  and needs-evidence mission blockers.
- The review queue currently includes fixture blockers, traverse review
  reasons, illumination/power blockers, and next questions for
  MoonClaw/operator follow-up.
- The current inline fixture fingerprint verifies successfully against its
  manifest, and the checked LOLA CSV fixture verifies against its SHA-256.
- `data/sources/lro_lola/gdr_ds.cat` pins the official PDS LOLA GDR catalog
  metadata, and `scripts/verify_moonmoon_sources.sh` verifies its SHA-256 and
  byte count alongside the active LOLA CSV fixture.
- `data/sources/lro_lola/ldem_875s_20m_float.xml` pins the selected south-polar
  20 m/pixel LOLA DEM product label, including projection, bounds, raster
  shape, unit, and raw image name.
- `data/sources/lro_lola/first_trusted_square_dem.csv` is the active tiny 4x4
  extraction generated from HTTP byte ranges against the selected IMG and
  verified by SHA-256; west-contour, north-rim, southwest-bypass, and
  south-stepout route-window CSVs use the same extractor and verifier.
- The first LOLA replacement path is tracked as a typed source-upgrade
  candidate in the site dossier and MoonBook export, with official PDS and ODE
  source links.
- The first LOLA acquisition plan now names the reachable south-polar GDR
  source family, catalog metadata, local source directory, extracted CSV path,
  and trust gate for the active software-proof fixture.
- The first product selection now names `ldem_875s_20m_float` as the concrete
  label-backed extraction target, while keeping the raw IMG uncommitted.
- The first extraction candidates now prove bounded raster access and produce
  the active fixture-shaped CSV plus adjacent and widened route evidence CSVs.
- The first 5x5 corridor scan found a lower-risk southwest bypass window, but
  it still exceeds conservative rover grade and roughness limits.
- The first 5x5 corridor scan is now a pinned CSV source artifact, generated by
  `scripts/scan_lola_corridor.py`, mirrored into MoonBit by
  `scripts/generate_corridor_scan.py`, and surfaced as a MoonBook
  `corridor-scan` entry.
- `scripts/scan_lola_corridor.py` can now plan wider scan surfaces offline with
  explicit `--radius` and `--step` settings, and the deterministic 9x9
  `--radius 16 --step 4` search is now a pinned v2 CSV source artifact and the
  active generated MoonBit corridor scan.
- Route alternatives now carry MoonBook-visible illumination assessments. The
  current gate is intentionally conservative: it records relief-shadow risk and
  blocks all route candidates until a time-windowed solar ephemeris source is
  connected.
- The site dossier and MoonBook export now carry a conservative energy-window
  assessment that turns the missing ephemeris problem into an explicit Wh
  budget and review item.
- The site dossier and MoonBook export now carry a separate ephemeris source
  candidate and acquisition plan. The plan names source discovery, checksum
  pinning, local JSON power-window evidence, generated MoonBit output, and the
  review gate required before Moonrobo power evidence can become credible.
- The energy-window and route illumination payloads now cite the generated
  power-window evidence id and source status, making the current block traceable
  to a concrete checked artifact rather than an implicit boolean.
- MoonBook now indexes that checked/generated power-window boundary as its own
  `power-window-evidence` entry and workspace payload before the derived energy
  assessment.
- MoonBook accepts the dedicated `power-window-evidence` entry while keeping
  low energy margin and local-horizon review as downstream blockers.
- Moonrobo simulation-precondition packets now include that same
  `power-window-evidence` blocker before `energy-window`, keeping source
  readiness visible at the robot boundary.
- MoonBook now indexes the Moonrobo simulation-precondition handoff, and the
  materialized workspace carries the robot-facing handoff payload.
- MoonBook now indexes MoonClaw modeling proposals, and the materialized
  workspace carries the proposal packet payload with acceptance criteria and
  expected outputs.
- MoonBook now indexes the first MoonClaw route-scoring, corridor-expansion, and
  ephemeris receipts, and the materialized workspace carries the validation
  checks, route scoreboard, corridor window proof, and computed ephemeris output
  contract.
- MoonBook now also indexes the MoonClaw ephemeris acquisition task, so the
  workspace contains the exact source files, generated files, validation
  commands, artifact blockers, and Moonrobo precondition gate that must move
  from computed evidence to reviewed robot-facing evidence.
- MoonBook now also indexes the corridor expansion task, so the workspace and
  review queue show that the 81-window `first-trusted-square-9x9-corridor-scan-v2`
  CSV is pinned, promoted into generated MoonBit, and materialized for review.

Remaining work:

- Implement the live 3D Rabbita Moonviewer plan above before adding more review
  panels. The product currently lacks the movable Moon context operators expect.
- Review the promoted northeast-stepout fixture and continue corridor search
  around it only if operators need wider local context.
- Execute the ephemeris acquisition plan and replace the relief-shadow proxy
  with time-windowed solar ephemeris and measured sun/thermal windows.
- Extend the materialized MoonBook workspace with operator-authored review
  transitions and append-only review history.
- Add persisted reviewer identity, timestamps, and manual accepted/rejected
  transitions once MoonBook storage has an editable layer.

## Milestone 4: MoonClaw Modeling Jobs

Goal: let agents run bounded lunar modeling tasks.

- Define MoonClaw proposal packets for terrain derivation and site comparison.
- Add result receipts for layer generation, validation, and dossier updates.
- Support a task like "score route candidates across this site under current
  constraints."

Done when MoonClaw can run a modeling job and Moonmoon can validate and ingest
the result.

Current implementation status:

- `src/adapters/moonclaw` defines proposal packets with job kind, priority,
  evidence inputs, blocked review items, acceptance criteria, and expected
  outputs.
- The first trusted square exports three bounded proposals: acquire
  ephemeris-backed power/thermal evidence, widen the LOLA corridor search, and
  score route candidates after terrain and power evidence improves.
- `cmd/main -- moonclaw proposals` emits Markdown/JSON proposal packets under
  `output/moonclaw/`.
- `cmd/main -- moonclaw receipts` emits the current route-scoring receipt under
  `output/moonclaw/`.
- `cmd/main -- moonclaw ephemeris receipts` emits the current missing-power
  evidence receipt under `output/moonclaw/`.
- `cmd/main -- moonclaw corridor receipts` emits the current corridor-expansion
  receipt under `output/moonclaw/`.
- MoonBook indexes the MoonClaw proposal and receipt packets and includes them
  in the materialized evidence workspace.

Remaining work:

- Add executable MoonClaw job runners for ephemeris and wider corridor proposal
  output.
- Validate future external receipts against source checksums and current review
  items before updating the Moonmoon model.
- Ingest the first successful receipt back into terrain, mission, and MoonBook
  outputs.

## Milestone 5: Moonrobo Simulation Handoff

Goal: connect terrain to robot action without crossing into unsafe physical
control.

- Define robot-facing route and hazard handoff contracts.
- Export traverse preconditions: slope limits, roughness limits, power budget,
  light window, and confidence.
- Add a simulated Moonrobo task that consumes one Moonmoon route candidate.

Done when Moonrobo can say why a simulated task is allowed, blocked, or needs
more evidence.

Current implementation status:

- `src/adapters/moonrobo` defines `MoonroboTaskHandoff` and
  `RobotPrecondition` contracts.
- The first trusted square exports one handoff per route candidate and a
  primary handoff selected from the best measured corridor route.
- Every handoff now carries a `MoonroboExecutionEnvelope` that separates
  simulation readiness, replay readiness, and hardware denial. Current packets
  are `simulation-blocked`, `replay-needs-review`, and `hardware-denied`
  because terrain, illumination, corridor, and energy preconditions are not
  safe for simulation.
- `scripts/build_moonmoon_dossier.sh` writes
  `output/moonrobo/first_trusted_square_handoffs.md` and `.json`.

## Milestone 6: Operational Moon Tile

Goal: move from static terrain to mission windows.

- Add time-based illumination windows.
- Replace first conservative energy assumptions with ephemeris-backed power
  windows.
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
- Replace the checked synthetic CSV with a tiny authoritative LOLA-derived
  extraction while preserving the same verify/generate/dossier pipeline.
- Add ephemeris-backed illumination and energy windows to the mission score.
- Add the Rabbita live 3D Moonviewer: local Moon texture, WebGL canvas,
  drag/zoom controls, fly-to-site, site marker, and fallback static context.
- Add Rabbita view models for terrain layers, inspector rows, route overlays,
  and globe projection overlays.
- Add persisted MoonBook review history and editable review status transitions.
- Keep running `moon check`, `moon test`, `moon info`, and `moon fmt` for each
  proof slice.
