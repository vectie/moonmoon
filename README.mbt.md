# Moonmoon

> MoonBit-native lunar world model for the Moon suite.

`MoonBit` `Lunar Digital Twin` `Terrain Modeling` `Mission Planning` `Rabbita` `Lepusa` `MoonClaw` `Moonrobo`

Moonmoon is the hard-world modeling layer for the Moon agent suite. It is the
place where lunar data, terrain assumptions, uncertainty, illumination,
resources, hazards, and robot-operational constraints become typed, testable,
and reviewable artifacts.

The wider suite already has the social and operational pieces:

- Moontown coordinates standing goals, schedules, resident agents, and mayor
  supervision.
- MoonClaw runs bounded agent jobs and produces evidence-backed artifacts.
- MoonBook stores durable knowledge, source material, datasets, and review
  queues.
- Moondesk gives humans a desktop surface for books, runs, inboxes, and tools.
- Moonrobo owns the physical robot gateway, safety boundary, telemetry, replay,
  and execution proof.

Moonmoon should become the lunar world those systems can reason against before a
Moonrobo ever touches real regolith.

```text
NASA / LROC / LOLA / PDS / mission data
  -> Moonmoon data + terrain + uncertainty model
  -> Rabbita/Lepusa lunar operator viewer
  -> MoonBook lunar evidence library
  -> MoonClaw modeling jobs
  -> Moontown long-running mission planning
  -> Moonrobo simulation, route, mining, construction, and safety gates
```

## Current Status

Moonmoon now has its first executable proof slice: one tiny trusted-square
terrain fixture with typed provenance, uncertainty, terrain metrics, hazard
classification, mission traverse readiness, a site dossier, and reproducible
Markdown/JSON CLI output.

Run it with:

```bash
moon run cmd/main
moon run cmd/main -- site summary
moon run cmd/main -- json
moon run cmd/main -- terrain fixture
moon run cmd/main -- terrain fixture json
moon run cmd/main -- moonbook dossier
moon run cmd/main -- moonbook dossier json
moon run cmd/main -- moonclaw proposals
moon run cmd/main -- moonclaw proposals json
moon run cmd/main -- moonclaw receipts
moon run cmd/main -- moonclaw receipts json
moon run cmd/main -- moonclaw ephemeris receipts
moon run cmd/main -- moonclaw ephemeris receipts json
moon run cmd/main -- moonclaw corridor receipts
moon run cmd/main -- moonclaw corridor receipts json
moon run cmd/main -- moonrobo handoff
moon run cmd/main -- moonrobo handoff json
python3 scripts/generate_moonmoon_fixture.py --check
python3 scripts/materialize_moonbook_workspace.py --check
bash scripts/build_moonmoon_dossier.sh
```

Reproducible site, terrain, MoonBook, MoonClaw, and Moonrobo handoff deliverables are
written to `output/site/`, `output/terrain/`, `output/moonbook/`, and
`output/moonclaw/`, and `output/moonrobo/`. The materialized MoonBook workspace lives at
`output/moonbook/workspaces/first-trusted-square/` and includes per-entry
payloads, review status, and review transitions.

MoonClaw outputs currently include bounded modeling proposals, a deterministic
route-scoring receipt, a deterministic corridor-expansion receipt, and a
needs-review ephemeris receipt. The receipts validate the current route set,
selected route, measured corridor windows, source checksums, proposal blockers,
energy blocker, and Moonrobo handoff compatibility. They record accepted terrain
and route results while the ephemeris receipt keeps the power gate in review
until a real time-windowed solar source is attached.

The current terrain fixture is sourced from the checked LOLA byte-range CSV at
`data/sources/lro_lola/first_trusted_square_dem.csv`, verified by
`scripts/verify_moonmoon_sources.sh`, and regenerated into MoonBit by
`scripts/generate_moonmoon_fixture.py`.

The current fixture is measured LOLA DEM evidence accepted for Moonmoon software
proof. It is still not mission-grade lunar planning data; the current
illumination and energy gates intentionally block until time-windowed
ephemeris-backed power evidence exists.

The first target is not a decorative Moon viewer. The first target is one
trusted lunar site model that can answer operational questions with source
provenance and uncertainty:

- What terrain data was used?
- What does this tile claim about elevation, slope, roughness, light, and risk?
- Which claims are measured, derived, or speculative?
- What would block a rover traverse, mining task, construction pad, or solar
  ridge plan?
- What evidence should be written back to MoonBook?

## Documents

- [Vision](docs/VISION.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)

## Reference Direction

Moonmoon should rebuild the useful lessons from the old `../tl-2022` terrain
work rather than porting it directly. The transferable ideas are DEM-centered
workflows, terrain exaggeration, ridge/gully/trench style analysis, queryable
terrain regions, and exportable visual evidence. The implementation should be
MoonBit-first and suite-native.

Relevant public data/tooling references include:

- [NASA Lunar Reconnaissance Orbiter](https://science.nasa.gov/mission/lro/)
- [PDS Geosciences LRO LOLA archive](https://pds-geosciences.wustl.edu/missions/lro/lola.htm)
- [LROC data and mapping tools](https://www.lroc.asu.edu/)
- [Ames Stereo Pipeline](https://stereopipeline.readthedocs.io/en/latest/introduction.html)
- [MoonAnything lunar vision benchmark](https://github.com/clementinegrethen/MoonAnything)
