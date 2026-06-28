# Locomotion Phase Guidance

This document is the current phase guide for locomotion work after the
standalone Moonmoon refactor. It replaces the old Noetix/Rabbita-specific plan
that lived before the repository was simplified.

The guiding boundary is:

```text
route evidence first, motion handoff second, robot gait adapter later
```

Moonphys remains a clean physics library. Moonmoon may expose whether a route
is ready for motion, but robot-specific walking style, URDF gait assets, and
live Rabbita animation belong in a future suite adapter.

For the detailed animation-first gait pipeline, see
`docs/ANIMATION_FIRST_LOCOMOTION_PLAN.md`. This phase guide is the boundary and
delivery checklist; that document is the motion-quality plan.

## Phase 0: Standalone Boundary

Status: current architecture.

Deliverables:

- no committed `output/` tree
- no hidden browser asset bundle under `src/ui`
- no Moonrobo, Noetix, Rabbita, MoonBook, or MoonClaw package inside the
  standalone domain model
- `src/moonphys` stays robot-agnostic
- `src/ui` owns the renderer-facing handoff contract

Acceptance:

- `moon check` and `moon test` pass without external scripts
- root docs name the standalone package boundaries
- robot-specific code is not needed to render the first trusted square

## Phase 1: Moonphys Core

Status: active core exists.

Moonphys owns generic primitives only:

- vectors and transforms
- lunar environment constants
- heightfield sampling and contact probes
- kinematics and articulated pose trees
- rigid bodies, contacts, constraints, hinges, motors, support, and replay
  reviews

Moonphys must not own:

- Noetix names
- URDF walking clips
- gait phase choices
- robot mesh rendering
- Rabbita browser overlays
- route-specific mission policy

Acceptance:

- public Moonphys APIs stay reusable outside Moonmoon
- tests cover deterministic stepping and physics evidence
- no walk primitive is introduced into `src/moonphys`

## Phase 2: Route-Motion Contract

Status: implemented by `src/ui/motion_contract.mbt`.

Moonmoon exposes `TraverseMotionContract` as the current locomotion handoff.
It records:

- selected site and route
- `src/moonphys` as the physics core
- `future-suite-adapter` as the motion owner
- gait asset status
- simulation preview status
- next action for clearing route blockers

Acceptance:

- the standalone HTML embeds `moonmoon-motion-contract`
- the UI shows a motion contract panel
- route blockers keep the contract `mission-gated`
- tests assert that robot gait assets remain outside the standalone model

## Phase 3: Route Clearance Before Motion

Route-motion should not become adapter-ready until mission gates allow it.

Deliverables:

- clearer terrain, illumination, energy, and operator-review checks
- one selected-route clearance result
- explicit reason when motion remains blocked
- no implicit hardware or robot authority

Acceptance:

- `TraverseMotionContract.status` can only become `suite-adapter-ready` when
  route evidence supports it
- blocked routes still render useful motion handoff evidence

## Phase 4: Suite Adapter Reintroduction

This phase is future work. Do not put it back into the standalone packages.

A future Moonrobo adapter should consume:

- Moonmoon site dossier
- selected route and route-motion contract
- Moonphys generic primitives
- robot source model and metadata

The adapter may own:

- Noetix identifiers
- URDF parsing or imported URDF model references
- rigid robot link and mesh mapping
- robot-specific gait assets
- robot-specific simulation packets

Acceptance:

- adapter packages import standalone packages, not the reverse
- Moonmoon remains useful without the adapter installed
- hardware authority remains denied until explicit external gates clear

## Phase 5: Robot Gait Asset Contract

The first real walking adapter should begin with a motion asset, not raw
physics.

Status: active in the Rabbita standalone preview. The local adapter-style
contract lives in `ui/rabbita-moon/gait-clip.js`, which owns phase labels,
root-motion stride, foot lock/support channels, bounded joint target samples,
and URDF joint limit metadata. Rendering and generated evidence consume this
contract instead of defining gait authority inline.

Deliverables:

- walk-cycle phase labels
- root-motion stride
- foot lock and release markers
- authored left/right foot targets
- bounded joint target samples
- cycle-repeat and mirroring tests

Acceptance:

- a flat-ground cycle reads as intentional biped motion
- root motion, feet, and phase markers explain the motion
- all joint targets respect the robot definition

## Phase 6: URDF/FK Rigid Pose

Robot rendering must use rigid link transforms, not stretchy debug sticks.

Status: active in the Rabbita 3D view as a standalone preview. The current
`ui/rabbita-moon` renderer uses a Noetix-shaped rigid visual adapter with fixed
link dimensions and FK-derived foot endpoints. Full Moonrobo URDF import and
mesh attachment remain adapter work; Moonmoon core still does not depend on
Moonrobo.

Deliverables:

- URDF joint tree or equivalent rigid model contract
- forward-kinematics link poses
- visual mesh or primitive attachment per link
- debug skeleton as an overlay only
- tests that catch link-length changes

Acceptance:

- rendered links remain attached to FK endpoints
- foot markers do not replace actual foot-link poses
- link offsets and joint axes are invariant during animation

## Phase 7: Visualization Diagnostics

Visualization should make wrong motion diagnosable.

Status: active in the Rabbita 3D view. The robot canvas now exposes data
attributes for robot source, root link, phase label, support foot, swing foot,
FK foot endpoints, root distance, and link-length status so browser checks can
separate gait timing issues from rendering or FK issues. The Rabbita 3D scene
also exposes semantic `footPhaseChannels`, `gaitPhaseLabel`, and
`footPhaseCoverageStatus`, root-space foot-lock correction evidence, and
stance-foot world drift. It also exposes `limbForwardBendStatus` so knee sign
mistakes are caught as FK convention failures instead of being hidden by a
passing knee-contrast metric. It also exposes
`rootCorrectionContinuityStatus` so support-transfer snaps are caught directly.
It renders root/phase timing rails beside the robot so clip timing is visible
without replacing the rigid FK pose.

Deliverables:

- phase label
- root path
- locked foot marker
- swing foot marker
- authored foot target
- FK foot endpoint
- terrain contact probe
- correction delta once terrain IK exists

Acceptance:

- a viewer can distinguish clip timing, FK, rendering, contact, and terrain
  correction problems
- overlays never become the primary robot pose authority

## Phase 8: Terrain IK

Terrain adaptation comes after the flat-ground gait reads correctly.

Status: active preview. Terrain IK now runs after root-space stance-foot
locking, so support soles are corrected to terrain while their world drift
stays bounded by the gait contract.

Deliverables:

- bounded foot target correction
- bounded pelvis/base height correction
- hip, knee, and ankle correction evidence
- saturation evidence
- flat-terrain preservation tests

Acceptance:

- terrain changes joint targets, not rendered link lengths
- corrections stay within robot limits
- support feet do not skate during stance

## Phase 9: Moonphys Validation

Physics should review a credible motion. It should not be the first source of
walking style.

Moonphys review should consume:

- FK link poses
- mass and inertia estimates
- joint targets and bounded positions
- hinge motor frames
- terrain contact probes and contact patches
- support and traction evidence

Moonphys review should emit:

- pass, warn, or fail evidence
- joint limit and motor saturation
- support/capture risk
- contact and slip risk
- energy and momentum accounting

Acceptance:

- unsafe frames are review evidence
- physics does not silently rewrite the gait asset
- Moonphys remains robot-agnostic

Status: active in `src/suite_adapter_preview` as a suite-side compiled
Moonphys review of a generated Rabbita/Moonrobo Noetix evidence artifact.
`npm run check:gait` verifies that artifact is fresh. The current generated
walk now clears the compiled Moonphys motion, hinge, replay, support, capture,
contact, torque, pressure, velocity, and effort review gate. The next work is
visual walk-cycle polish and eventual live Moonrobo adapter payloads.

## Phase 10: Durable Suite Evidence

Only after the adapter produces stable motion evidence should MoonBook or
MoonClaw consume it.

Deliverables:

- durable simulation evidence entry
- explicit source references
- review status
- blocker and next-action records

Acceptance:

- evidence can be regenerated from typed source packages
- task orchestration consumes evidence; it does not become hidden motion logic
