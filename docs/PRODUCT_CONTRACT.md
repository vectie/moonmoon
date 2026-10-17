# MoonMoon product contract

Class: domain pack
Visible surface: simulation cockpit
Maturity: digital simulation alpha
Last reviewed: 2026-07-30

## Outcome

MoonMoon converts lunar terrain and mission evidence into inspectable world
models, route assessments and deterministic robot-mission simulations.

## Users and jobs

- Mission designers inspect terrain, hazards, energy and route candidates.
- MoonRobo consumes bounded simulation results as digital evidence.
- Operators explore missions through the Rabbita 3D application.
- MoonBook retains reviewed dossiers and outcome evidence.

## Ownership

MoonMoon owns lunar data ingestion, provenance, terrain models, hazard and
route calculations, mission simulation and digital visualization. It does not
own physical robot control, device safety, general agent execution or
acceptance authority.

## Capability status

| Capability | Status |
| --- | --- |
| Terrain, slope, roughness and hazard models | available |
| Route/corridor and energy assessment | available |
| Deterministic robot-mission simulation | available |
| Reviewer-defined alternative screening | local dossier UI; explicit criteria and portable report; no approval |
| Rabbita 3D inspection | available locally |
| External lunar datasets | conditional on source availability and license |
| Physical-world validation | excluded from current claims |

## Evidence and claims

Every derived model records source, coordinate frame, units, coverage, digest
and known uncertainty. A rendered scene is a presentation of the model, not
proof of terrain truth. Simulation evidence may inform a MoonRobo decision but
cannot authorize or attest a physical action.

## Integration contract

MoonMoon returns versioned mission, route and simulation receipts. MoonRobo
must validate the contract and independently apply current hardware readiness
and safety policy. Cross-product execution should flow through MoonFlow rather
than source-level repository dependencies.

## Verification

```sh
moon check --target native
moon test --target native
moon info
moon fmt
```

Dataset releases additionally require provenance and rendered evidence checks
described in `docs/README.md`.

## Release gates and next milestones

- Expand terrain and fault fixtures without overstating coverage.
- Prove restart/replay of mission sessions.
- Stabilize the MoonRobo simulation-result contract.
- Package and sign the Rabbita/Lepusa operator application.

The study panel supports [alternative review screening](ALTERNATIVE_REVIEW_SCREENING.md):
compare retained observations against explicit numeric and coverage requirements,
preserve every native blocker, and reopen a report only against its exact original
dossier. Matching criteria does not select a mission, change its named review,
verify source declarations, or confer physical authority.

Draft authors can [preview and apply a known-cell detour](DRAFT_ROUTE_DETOURS.md)
inside the existing route editor. The deterministic geometric proposal preserves
unselected route occurrences and has explicit undo; it does not assess hazards,
energy or physical readiness. Native simulation and review remain separate.
