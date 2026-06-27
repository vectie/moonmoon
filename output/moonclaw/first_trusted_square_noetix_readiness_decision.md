# MoonClaw Noetix Simulation Readiness Decision

- decision: moonclaw/first-trusted-square/noetix-simulation-readiness-decision
- source task: moonclaw/first-trusted-square/noetix-review-task
- robot: noetix-e1-lab-01
- status: noetix-simulation-blocked
- may consume MoonRobo simulation: false
- reason: Noetix simulation remains blocked for MoonRobo consumption: 4 review artifacts are blocked, 50 source metadata blockers remain with status model-metadata-blocked, and 9 physical model blockers remain with status physical-model-assumption-review; hardware authority remains moonmoon-safety-gate-only
- ready artifacts: 7
- blocked artifacts: 4
- source metadata blockers: 50
- source metadata ready: false
- source metadata inventory: model-metadata-blocked
- physical model ready: false
- physical model blockers: 9
- physical model blocker ids:
  - assumed:mass
  - assumed:center-of-mass
  - assumed:link-inertia
  - assumed:collision-shapes
  - assumed:foot-sole-geometry
  - assumed:joint-servo-gains
  - assumed:friction
  - missing:joint-damping
  - missing:joint-stiffness
- static-support review frames: 32
- dynamic-stability review frames: 32
- joint-control review frames: 32
- joint-control world-support review frames: 11
- joint-control world-capture review frames: 32
- joint-control worst capture support margin: -1.9471892830999706 m
- joint-control world replay blockers: 3
- joint-control world replay blocker ids:
  - world-envelope-review
  - world-support-review
  - world-dynamic-support-review
- inertial-collision review frames: 32
- hardware state: hardware-denied
- hardware authority: moonmoon-safety-gate-only
- hardware denied: true
- next action: keep Noetix evidence in MoonClaw review; replace assumed source and physical model metadata, clear blocked review artifacts, regenerate the decision, and keep hardware denied

## Blocked Artifacts

- noetix-static-support-review
- noetix-dynamic-stability-review
- noetix-joint-control-review
- noetix-inertial-collision-review

## Ready Artifacts

- noetix-source-model-audit
- noetix-moonrobo-source-sync
- noetix-endless-gait-window
- noetix-endless-walk-trace
- noetix-high-control-walk-command-plan
- noetix-urdf-reference-link-poses
- noetix-rabbita-playback

## Hardware Denial Invariants

- hardware_state must remain HardwareDenied
- hardware_authority must remain moonmoon-safety-gate-only
- Noetix review decision must never issue hardware authority
- MoonRobo simulation consumption requires all review artifacts ready, source metadata inventory ready, and physical model readiness clear
