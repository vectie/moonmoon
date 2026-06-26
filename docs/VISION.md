# Moonmoon Vision

Moonmoon exists because the Moon suite needs a hard model of the physical world.
Moontown can organize agents, MoonClaw can run jobs, MoonBook can preserve
knowledge, Moondesk can expose a desktop, and Moonrobo can guard physical
execution. But when the mission crosses from Earth to the Moon, those systems
need a shared world model that is more concrete than conversation.

Moonmoon should provide that world model.

## North Star

Moonmoon is a lunar digital twin kernel. It should turn real lunar datasets and
carefully marked assumptions into operational surfaces for:

- landing site characterization
- rover traversal
- mining and resource scouting
- construction pad planning
- solar and shadow planning
- communications and power-aware mission design
- robot simulation before physical execution
- uncertainty-aware agent reasoning

The project should be ambitious, but its credibility comes from being explicit
about evidence. Every rendered terrain layer, route score, hazard flag, and
construction recommendation should be able to explain where it came from.

## What Moonmoon Is Not

Moonmoon is not a generic globe viewer. It is not just a pretty 3D Moon. It is
also not the robot gateway, scheduler, evidence book, or agent runtime. The
operator surface still needs a live, movable lunar globe because humans must
understand site context before trusting a local tile. The globe is a navigation
and evidence frame, not the source of mission truth.

Moonmoon owns the model of the lunar world:

- coordinate systems
- terrain cells and tiles
- dataset registry and provenance
- elevation, slope, roughness, hazard, and resource layers
- illumination and time windows
- uncertainty and confidence
- model-derived mission constraints
- renderer-facing projections for Rabbita and Lepusa

Other suite members consume these contracts.

The Rabbita surface should therefore open at Moon scale, let the operator move
and zoom the Moon, and then fly into the first trusted square. The local
trusted-square terrain, LOLA corridor windows, review blockers, and Moonrobo
safety gates remain MoonBit/MoonBook-owned evidence layers over that globe.

## Suite Fit

```text
MoonBook
  stores datasets, source notes, site dossiers, review queues, and accepted
  lunar knowledge.

MoonClaw
  runs bounded modeling jobs: derive terrain layers, compare landing sites,
  score routes, prepare evidence packets.

Moontown
  schedules repeated lunar modeling goals, supervises long-running research
  lanes, and coordinates mission-planning loops.

Moondesk
  lets humans browse MoonBook workspaces, inspect model evidence, and launch
  lunar tools.

Moonrobo
  consumes Moonmoon terrain and task constraints before simulation or physical
  execution.

Moonmoon
  provides the trusted lunar world model under all of the above.
```

## Design Temperament

Moonmoon should stay scientifically humble and operationally useful.

The Moon is partially known, not unknowable. NASA LRO, LOLA, LROC, PDS, QuickMap,
and related tools already provide strong public foundations. The work is to
turn that material into a model that agents and robots can use without hiding
its uncertainty.

The product should therefore prefer:

- typed contracts over screenshots
- provenance over vibes
- small verified tiles over huge untrusted maps
- live geospatial context over static hero images
- uncertainty labels over false confidence
- reproducible derivations over manual magic
- MoonBit core logic over UI-owned business rules

## First Dream Slice

The first meaningful demo is one trusted square of the Moon.

Pick one site. Load a small curated terrain fixture. Derive elevation, slope,
roughness, hazard hints, and one simple route score. Render it in Rabbita. Store
the source and derived evidence in MoonBook. Let MoonClaw run one bounded model
job. Let Moonrobo consume the route as a simulation precondition.

That is enough to prove the direction.
