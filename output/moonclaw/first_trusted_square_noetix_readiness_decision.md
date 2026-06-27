# MoonClaw Noetix Simulation Readiness Decision

- decision: moonclaw/first-trusted-square/noetix-simulation-readiness-decision
- source task: moonclaw/first-trusted-square/noetix-review-task
- robot: noetix-e1-lab-01
- status: noetix-simulation-blocked
- may consume MoonRobo simulation: false
- reason: Noetix simulation remains blocked for MoonRobo consumption: 4 review artifacts are blocked and 50 source metadata blockers remain; hardware authority remains moonmoon-safety-gate-only
- ready artifacts: 7
- blocked artifacts: 4
- source metadata blockers: 50
- static-support review frames: 32
- dynamic-stability review frames: 32
- joint-control review frames: 32
- inertial-collision review frames: 32
- hardware state: hardware-denied
- hardware authority: moonmoon-safety-gate-only
- hardware denied: true
- next action: keep Noetix evidence in MoonClaw review; replace assumed source metadata, clear blocked review artifacts, regenerate the decision, and keep hardware denied

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
- MoonRobo simulation consumption requires all review artifacts ready and zero source metadata blockers
