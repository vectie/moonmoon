# Moonmoon

> MoonBit-native lunar world model for the Moon suite.

`MoonBit` `Lunar Digital Twin` `Terrain Modeling` `Mission Planning` `Rabbita` `Lepusa` `Moonrobo`

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

This repository is still a seed project. That is intentional: Moonmoon should
get the core shape right before accumulating code.

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
