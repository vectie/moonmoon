# MoonMoon product contract

Class: domain product
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
