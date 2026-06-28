# Moonphys Feature Plan

Goal: build a clean MoonBit physics library called `moonphys`, then use it from
MoonSuite collaboration layers so the Noetix robot can walk endlessly in one
direction over Moonmoon terrain, with Moonrobo owning robot-specific simulation
evidence.

## Current Implementation Status

- `moonphys` has generic vector, transform, environment, bilinear heightfield,
  terrain-normal point and patch contact, kinematic, convex support-polygon
  margin, quasistatic support-load distribution, terrain-normal traction
  projection, contact-patch pressure review, joint-frame motor replay, and trace
  primitives.
- Moonrobo adapts Moonmoon terrain into a generic `moonphys` heightfield.
- The Noetix endless walk trace consumes `moonphys` heightfield/contact APIs
  instead of owning terrain math.
- Every walk frame includes 24 Noetix joint phases for animation/replay; leg
  phases are derived from URDF-reference IK and clamped by source joint limits.
- The trace is exported as Markdown and JSON under `output/moonrobo`.
- Moonrobo exports a high-control Noetix walk command plan that segments the
  finite trace prefix into dry-run approval windows from the sibling robot
  profile limits; it is review evidence only and never hardware authority.
- Moonrobo exports explicit Noetix endless-gait evidence: frame `N + cycle`
  repeats support/contact phase while the body advances by the configured
  forward offset. The evidence now also carries sampled future cycles with
  per-sample phase/contact/forward-offset checks, proving finite trace exports
  are windows over a one-direction gait.
- The Noetix gait keeps support feet planted while in contact; swing feet move
  between plant anchors, eliminating the earlier sliding-contact artifact.
- MoonBook materializes the trace as a durable workspace entry.
- Moonrobo exports a Noetix physics-assumption profile with a generic
  `moonphys/review` physical-model readiness inventory, plus a static
  COM/support report backed by generic Moonphys convex support-polygon and
  support-load assessment.
  The physical-model readiness inventory now exposes stable blocker IDs for
  assumed and missing inputs, and the Noetix profile now carries a
  `physical_model_gaps` inventory that maps each blocker to required evidence,
  source path, target artifact, acceptance check, and next action so downstream
  review gates can target exact metadata gaps.
- Moonrobo exports a Noetix source-model audit that records the sibling
  Moonrobo URDF/profile paths, 25 links, 24 joints, 24 joint limits, six visual
  geometries, one placeholder mesh asset, zero authoritative collision or
  inertial tags, and explicit per-link collision/inertial metadata blockers.
  The blocker count is now backed by a generic `moonphys/review`
  model-metadata inventory contract with stable blocker IDs, keeping readiness
  semantics reusable and robot-agnostic. The Moonrobo source-model report now also
  carries a `source_metadata_gaps` inventory that maps every missing
  collision/inertial blocker to its link, source path, required evidence,
  target artifact, acceptance check, and next action.
- A source-sync verifier parses sibling Moonrobo `robot.json` and
  `model/robot.urdf` so Noetix joint limits, visual links, missing inertial/
  collision tags, and high-control limits cannot silently drift from the source.
  It also verifies visual geometry kind, origin, dimensions, mesh path, and
  placeholder mesh bounds from the referenced OBJ vertices.
- Sibling Moonrobo is already mesh-aware, not just stick-aware: its cockpit
  projection exports URDF `visuals` and `visual_instances`, resolves mesh asset
  paths, and records primitive box/cylinder visuals. The current Noetix source
  has one resolved OBJ mesh on `base_link` plus primitive torso/chest/limb
  visuals, so Rabbita should render rigid mesh and primitive link visuals as
  the primary robot body.
- Moonphys exports a generic capture-point assessment for dynamic-stability
  review, and Moonrobo exports a Noetix dynamic-stability report backed by it.
- Moonrobo exports URDF-reference Noetix link-pose evidence: body/limb links
  use a generic Moonphys articulated-chain pose evaluator fed by compact
  Noetix URDF reference data, and feet are bound to Moonphys contact probes
  with FK contact error. Each link-pose entry now also carries source
  visual-geometry evidence from the Noetix source-model audit, or an explicit
  missing-visual-geometry status when the URDF link has no visual block.
  Link poses also carry per-link collision/inertial source metadata status and
  blocker IDs, making the current missing authoritative physical metadata
  visible at the FK artifact boundary.
- Moonrobo exports Noetix inertial/collision review evidence backed by
  Moonphys composite primitive-shape mass properties, collision bounds,
  terrain collision probes, per-foot patch-load contact wrenches, narrow-phase
  self-collision manifolds, support-wrench motion preview with impulse and
  kinetic-energy accounting, generic multi-contact manifold resolution with
  impulse accounting, and Moonphys world body-pair contact response for
  self-contact correction evidence.
- Moonphys exports generic fixed-step multi-body heightfield world replay:
  multiple independent rigid bodies share one heightfield/material/environment,
  carry per-body external forces, resolve terrain contact, and report world
  contact counts plus kinetic-energy deltas. World bodies also carry generic
  collision shapes, broad-phase pair probes, scheduled narrow-phase body
  contacts, a body-pair contact manifold, and deterministic pair contact
  response with split penetration correction plus normal/friction impulse
  accounting. World replay also supports generic distance constraints between
  anchored points on named bodies with inverse-mass weighted correction and
  constraint-axis impulse accounting, plus generic hinge constraints over
  motion bodies with position/axis projection, inverse-inertia weighted angular
  correction, and impulse accounting.
  Moonphys also exposes generic hinge-axis alignment and
  inverse-inertia weighted correction estimates over angular body states.
  Generic world-trace envelopes include aggregate mass/center-of-mass,
  per-body and whole-world linear momentum bounds alongside position, speed,
  contact, hinge, and energy summaries.
  Generic world-support traces derive contact footprints from heightfield world
  replay frames and report COM support margin plus center-of-pressure error.
  Generic world dynamic-support traces feed replay COM velocity and contact
  footprints into Moonphys capture-point assessment for motion-aware support
  review.
  Generic world replay reviews compose envelope, static support, and dynamic
  support traces into one deterministic status surface with explicit ready,
  blocker-count, and blocker-id fields for downstream gates. The current
  Noetix gait clears the Moonphys world replay envelope, support, and
  dynamic-support blockers.
  Generic hinge-joint assessment composes anchor-position and hinge-axis
  correction evidence from rigid body motion states, and generic hinge-joint
  frame assessment aggregates multi-joint body graphs. Full rotational
  integration with actuated articulated coupled dynamics remains future work.
- Moonphys heightfield collision now samples interpolated terrain elevation and
  surface normals, so Noetix joint-control evidence exposes one right-leg
  velocity-limit review frame instead of hiding slope-induced motion.
- Moonrobo Noetix joint-control evidence now projects each URDF-reference link
  frame through Moonphys generic hinge-joint frame assessment and exports
  compact per-frame/report summaries for body count, joint count, position/axis
  error, impulse review, Moonphys world hinge constraint replay status, and
  motor-driven heightfield world replay contact/hinge-resolution summaries.
  Moonphys velocity-limited joint command shaping clamps unreachable per-frame
  targets to each URDF joint velocity limit before servo replay, clearing the
  prior Noetix terrain-normal velocity-limit frame. The same report also
  carries a generic Moonphys world-trace envelope for body sample count,
  position bounds, aggregate center-of-mass bounds, max speed, max kinetic
  energy, max body/world linear momentum, and max per-frame kinetic-energy
  delta, plus a generic world-support trace summary for contact-derived support
  margins and capture-point margins. A generic Moonphys world replay review
  status and blocker inventory now consolidate those evidence streams; the
  envelope is bounded and the replay blocker inventory is clear.
- Moonphys exports generic horizontal and oriented rectangular heightfield
  contact-patch sampling plus patch-load pressure review; Moonrobo Noetix
  static-support evidence records terrain-aligned per-foot sole patch samples,
  clearance ranges, averaged terrain normals, and sample-level pressure from
  assumed foot geometry. The Noetix static-support report now separates
  support-polygon stability from review-only terrain/contact/model status:
  all current gait frames are support-stable while the artifact still remains
  review-only.
- MoonClaw exports a Noetix simulation review task that ties endless-gait
  evidence, the walk trace, high-control dry-run command plan, URDF-reference
  link poses, static support report, dynamic-stability report, joint-control
  report, inertial/collision report, and Rabbita playback into a
  hardware-denied review packet. The review task carries the generic Moonphys
  `moonphys/review` metadata inventory, source-metadata blocker IDs,
  physical-model blocker IDs, and world-replay blocker IDs through to MoonClaw.
- MoonClaw exports a Noetix simulation readiness decision that blocks MoonRobo
  simulation consumption until all review artifacts are ready, the generic
  `moonphys/review` metadata inventory and physical-model readiness are ready,
  named world-replay blockers are resolved, and hardware remains denied.
- MoonClaw exports Noetix readiness work items that convert source metadata,
  physical-model, and review-artifact blockers into bounded follow-up evidence
  tasks while keeping MoonRobo simulation consumption and hardware authority
  denied. The previous world-replay work item is omitted after the Moonphys
  replay blocker inventory clears. The physical-model work item now targets the
  Moonrobo `physical_model_gaps` inventory instead of a flat blocker list, and
  the source-metadata work item targets the Moonrobo `source_metadata_gaps`
  inventory.
- Moonrobo selected-route simulation review packets now carry a first-class
  Noetix robot simulation gate with the MoonClaw readiness decision path,
  readiness work-item paths, source-metadata blocker count, physical-model
  blocker count, and blocked next action. This keeps the Noetix walking demo
  visible to MoonRobo consumers without letting MoonRobo consume simulation
  while authoritative source/physical metadata is still missing.
- MoonClaw review-task and readiness-decision evidence carries static
  support-stable frames and dynamic capture-stable frames separately from
  review-frame blockers, so downstream gates can distinguish passing Moonphys
  margins from unresolved provenance/model authority.
- MoonClaw now marks static-support and dynamic-stability margin artifacts
  ready when every frame is support-stable/capture-stable, while the source
  metadata and physical-model readiness gates continue to block simulation
  consumption until authoritative metadata replaces assumptions.
- MoonClaw now also marks the joint-control replay artifact ready when
  velocity/torque limits, saturation, support/capture replay, and Moonphys
  world replay blockers are clear; servo/inertia authority remains blocked by
  the physical-model gate.
- Moonrobo now filters adjacent URDF parent/child links out of the
  Noetix self-collision review, removing false self-contact corrections from
  visual proxy geometry. MoonClaw marks the inertial/collision artifact ready
  once terrain and filtered self-contact checks are clear, while source
  metadata and physical-model gates still block simulation consumption until
  authoritative mass, inertia, collision, sole, damping, stiffness, servo, and
  friction inputs are present.
- `scripts/check_moonrobo_noetix_walk.py` verifies trace invariants.
- `scripts/check_moonrobo_noetix_endless_gait.py` verifies endless-gait window
  invariants.
- `scripts/check_moonrobo_noetix_walk_command.py` verifies high-control
  dry-run command-plan invariants.
- `scripts/check_moonrobo_noetix_source_model.py` verifies source-model audit
  invariants.
- `scripts/check_moonrobo_noetix_source_sync.py` verifies Moonmoon Noetix
  evidence against sibling Moonrobo source files.
- `scripts/check_moonrobo_noetix_stability.py` verifies profile/stability
  invariants.
- `scripts/check_moonrobo_noetix_dynamics.py` verifies capture-point dynamic
  stability invariants.
- `scripts/check_moonrobo_noetix_link_poses.py` verifies link-pose trace
  invariants.
- `scripts/check_moonrobo_noetix_inertial_collision.py` verifies inertial and
  collision review invariants.
- `scripts/check_moonclaw_noetix_review_task.py` verifies review-task
  invariants.

## Boundary

`moonphys` should stay robot-agnostic.

Moonphys owns:

- math primitives: vectors, transforms, rotations
- physical environment constants: lunar gravity, later friction/material presets
- generic simulation primitives: body state, kinematic step, contact probe,
  heightfield query
- deterministic step/replay contracts
- no Moonmoon terrain dependency
- no Moonrobo robot dependency
- no Noetix names
- no walk behavior
- no source-model or readiness audit contracts

Moonphys review owns:

- reusable model-metadata inventories
- reusable physical-model readiness inventories
- blocker IDs for missing or assumed simulation inputs
- no solver, terrain, gait, or robot-specific behavior

Moonmoon owns:

- lunar terrain evidence
- LOLA-derived heightfields and terrain grids
- mission and route evidence
- terrain risk classification
- simulation review inputs derived from the lunar world

Moonrobo owns:

- robot profile/model references
- Noetix-specific gait/demo traces
- URDF/telemetry mapping
- simulation/replay/hardware authority state
- safety-gated handoff packets

MoonClaw and MoonBook come later as evidence and task orchestration layers, not
first implementation dependencies.

## Phase 0: Current Slice Cleanup

Status: done.

Deliverables:

- `src/moonphys` contains only neutral primitives:
  - `Vec3`
  - `PhysicsEnvironment`
  - `lunar_environment()`
- Noetix endless walking lives under:
  - `src/adapters/moonrobo/noetix_moon_walk.mbt`
- CLI route:
  - `moon run cmd/main -- moonrobo noetix walk`
  - `moon run cmd/main -- moonrobo noetix walk json`

Remaining cleanup:

- Keep the root facade export only if it remains useful.
- Consider whether `trusted_square_noetix_walk_*` belongs in root
  `moonmoon.mbt` or only under `@moonrobo`.
- Keep CLI/help text clear that this is a Moonrobo demo over Moonmoon terrain,
  not a core Moonphys command.

## Phase 1: Make Moonphys A Real Physics Core

Status: first core slice implemented; heightfield contact now uses bilinear
terrain sampling, y-grade evidence, surface normals, and normal-aware
sphere-heightfield response. Generic rectangular heightfield contact patches
sample sole center/corners and report clearance ranges plus averaged normals.

Add foundational physics files:

```text
src/moonphys/
  moon.pkg
  vector.mbt
  transform.mbt
  environment.mbt
  kinematics.mbt
  contact.mbt
  heightfield.mbt
  trace.mbt
  pkg.generated.mbti
```

Core APIs:

```text
Vec3
Quat or Basis3
Pose3
Velocity3
PhysicsEnvironment
KinematicBodyState
ContactProbe
HeightfieldSample
SimulationFrame
SimulationTrace
```

Important design rules:

- All stepping is deterministic.
- Simulation uses fixed `dt`.
- Public APIs are generic and reusable.
- No application-specific strings like `noetix`, `moonrobo`, or
  `first_trusted_square`.
- No direct import of `src/terrain`.
- Terrain comes through generic heightfield/sample interfaces.

Initial tests:

- vector addition/subtraction/scale/dot/length
- lunar gravity constant
- fixed-step kinematic integration
- heightfield sample behavior
- contact probe above/on/below surface
- bilinear terrain elevation and normal behavior
- slope-normal rigid-body contact response
- rectangular heightfield contact patch sampling
- deterministic trace prefix equality

## Phase 2: Generic Heightfield Bridge

Status: first bridge implemented in `src/adapters/moonrobo/terrain_bridge.mbt`.

`moonphys` should define generic heightfield types, while Moonmoon adapts its
terrain grids into those types.

In `moonphys`:

```text
Heightfield {
  field_id : String
  rows : Int
  cols : Int
  cell_size_m : Double
  elevations_m : Array[Double]
}
```

The Moonmoon/Moonrobo adapter converts:

```text
@terrain.TerrainGrid -> @moonphys.Heightfield
```

Possible bridge locations:

```text
src/adapters/moonrobo/moon_terrain_bridge.mbt
```

or:

```text
src/terrain/moonphys_bridge.mbt
```

Rules:

- `moonphys` does not know where the heightfield came from.
- Moonmoon keeps provenance, dataset id, confidence, and terrain source.
- The bridge preserves `tile_id`, `cell_size_m`, rows, cols, and elevations.

## Phase 3: Endless Kinematic Walker

Status: first Noetix endless walk trace and explicit endless-gait window
evidence implemented in `src/adapters/moonrobo/noetix_moon_walk.mbt`.

Keep this in `src/adapters/moonrobo`, not `moonphys`.

Current version already has the first shape:

- body moves in `+x`
- alternating left/right support
- planted support feet with no sliding while `in_contact`
- swing foot clearance
- terrain elevation probe
- terrain grade review status
- finite trace prefix represents an endless periodic gait
- explicit endless-gait evidence verifies frame `N + cycle` repeats support and
  contact phase while moving forward by the configured cycle offset
  and records sampled future cycles that preserve phase/contact while advancing
  by integer multiples of the cycle offset
- configurable heading, start position, stride frequency, body height, foot
  radius, and terrain source provenance

Next improvements:

- Keep the trace types robot-specific:
  - `NoetixMoonWalkTrace`
  - `NoetixMoonWalkFrame`
  - `NoetixFootContactProbe`
- Keep `frame_count` finite in exports, but make the gait mathematically
  endless through cycle indexing and durable endless-gait evidence.
- Replace the kinematic phase generator with a controller-backed gait once
  Moonrobo supplies authoritative mass, inertia, collision, damping, stiffness,
  and actuator metadata.

Tests:

- frame `N + cycle` has the same gait phase
- body `x` strictly increases
- support foot alternates
- swing foot clears ground
- contact foot is on terrain
- contact foot stays planted during each support half-cycle
- trace includes lunar gravity from `moonphys`

## Phase 4: URDF-Aware Noetix Pose

Status: generic articulated-chain pose evaluation implemented in Moonphys and
used by compact URDF-reference Noetix link poses in
`src/adapters/moonrobo/noetix_link_pose.mbt`; mesh geometry, collision
geometry, inertial metadata, and full dynamics remain future work; source
visual geometry is now carried in each link-pose entry for viewer/render use.

Use Moonrobo's URDF work as the robot-specific layer.

Input from sibling Moonrobo:

- `../moonrobo/examples/noetix-e1/robot.json`
- `../moonrobo/examples/noetix-e1/model/robot.urdf`
- Moonrobo's existing URDF parser and viewport simulation as reference material
- Moonrobo Cockpit's URDF viewport contract: `visuals`, `visual_instances`,
  resolved mesh paths, and primitive visual geometry

In this repo, initially avoid copying full URDF parsing. Instead:

- keep Noetix metadata as references
- encode the compact Noetix URDF link tree in the Moonrobo adapter
- bind feet to Moonphys contact probes from the walking trace
- compute body/limb poses with the compact URDF link tree, joint origins, joint
  axes, and URDF-reference leg IK phases until Moonrobo supplies full mesh/
  inertial/collision metadata

Implemented contract:

```text
NoetixReferenceLink
NoetixLinkPose
NoetixLinkPoseFrame
NoetixLinkPoseTrace
```

The first pose slice includes:

- all 25 URDF-reference links from the compact Noetix E1 model
- source walk trace id
- parent link and joint names
- nominal URDF origin offsets and joint axes
- world positions per frame
- FK world positions and contact error for terrain-bound feet
- explicit review-only status and no hardware authority
- source visual geometry per link when present, and explicit missing-visual
  status when absent
- a reusable Moonphys articulated pose tree rather than Noetix-local FK state

This gives downstream viewers enough structure to draw the robot walking with a
real FK tree and approximate source shapes without claiming full dynamics.

## Phase 5: Rabbita Visualization

Status: first trace scrubber, link-pose playback, and endless-gait loop
playback implemented in Rabbita; the current debug pose is not yet a correct
robot walking animation. Full rigid URDF-link rendering remains future work.

Add a viewer surface after the data contract is stable.

Options:

- Moonmoon Rabbita Moon viewer shows a path/trace overlay.
- Moonrobo Rabbita cockpit shows the Noetix robot walking over a terrain strip.
- Later, both share the same trace JSON.

First visualization target:

```text
output/moonrobo/first_trusted_square_noetix_walk.json
```

Viewer needs:

- terrain strip
- body marker
- left/right foot markers
- frame scrubber and autoplay loop backed by endless-gait evidence
- rigid URDF robot rig rendering:
  - one node per URDF link
  - one transform per URDF joint
  - visual geometry attached to the owning link's local frame
  - mesh visuals rendered from resolved URDF assets
  - box/cylinder primitive visuals rendered from URDF dimensions
  - sticks/bones shown only as a debug overlay, not as the primary robot body
- status badges:
  - `walking`
  - `walking-needs-review`
  - `terrain-grade-review`
- explicit simulation-evidence-only label

Do not connect this to hardware controls.

### Phase 5A: URDF Robot Rig Animation

Status: planned next; prioritize before more MoonClaw orchestration.

The current Rabbita pose uses URDF-reference FK plus contact-bound foot
correction. That is useful evidence, but it is not the same as how a walking
robot should be visualized. Games such as Piccolo animate by advancing a
normalized animation clip, sampling channels, applying them through a skeleton,
and rendering the resulting bone matrices. For Noetix, the equivalent skeleton
is the URDF link/joint tree, but the motion authority must be robot data rather
than an artist-authored random animation.

Robot animation bridge:

```text
Noetix URDF
  links + joints + origins + axes + limits
  visual meshes + visual primitives + visual origins
    -> Moonrobo RobotRig
       one rigid node per link
       one revolute transform per joint
       visual geometry attached to link-local frames
    -> RobotMotionFrame
       time
       floating base pose
       joint_name -> position_rad
       source = planned | simulated | telemetry
    -> FK link transforms
    -> Rabbita rigid-link renderer
```

Rules:

- Do not create a game-character skeleton with arbitrary bones.
- Do not skin or deform Noetix visual geometry; robot links are rigid.
- Do not reduce Moonrobo's model to sticks. Sticks are a link-tree diagnostic;
  the primary Rabbita body should be the rigid URDF visual geometry.
- Do not pull foot link positions directly to terrain contact after FK for the
  primary render. Contact should influence the gait/controller that produces
  joint positions; FK should then render the resulting robot.
- Keep sticks/bones as an optional debug overlay for link-tree inspection.
- Keep this outside core `moonphys`. Moonphys may provide generic transform,
  interpolation, and FK helpers, but Noetix rig construction, joint trajectory
  selection, and robot-motion authority live in Moonrobo.
- Keep MoonClaw aside until the Moonrobo/Rabbita rig visual is credible. Review
  gates should consume the improved evidence later, not drive this slice.

Immediate Phase 5A deliverables:

- Add a Moonrobo `RobotRig`/`RobotMotionFrame` contract for URDF-backed rigid
  robot animation.
- Convert the Noetix URDF-reference link tree and visual geometry into that
  contract:
  - one resolved `base_link` OBJ mesh from `meshes/base.obj`
  - existing URDF box visuals for torso/chest links
  - existing URDF cylinder visuals for arm/leg links
  - explicit missing-visual status for links without a visual block
- Rework the Rabbita Noetix viewer to render rigid link visuals from FK link
  transforms instead of the current contact-corrected stick pose.
- Support mesh assets by extension instead of assuming STL-only rendering:
  `OBJLoader` for `.obj`, `STLLoader` for `.stl`, and a clear unsupported-asset
  status for anything else. Moonrobo's current Three viewer resolves mesh
  assets but its loader path is STL-focused, while Noetix currently references
  an OBJ mesh.
- Render URDF primitive boxes and cylinders directly in Three.js so the current
  Noetix source can show more than the one base mesh even before full per-link
  meshes exist.
- Keep the endless gait loop source-backed by the existing Noetix walk command
  or simulated joint trajectory, with explicit `simulation evidence only` and
  `hardware denied` labels.
- Add verifier coverage that fails if rendered foot links are manually detached
  from the FK tree, if the viewer presents debug sticks as the primary robot,
  if the resolved OBJ base mesh is not represented in the render contract, or if
  URDF box/cylinder primitives disappear from the visual instance contract.

## Phase 6: Evidence Export

Status: first source-model audit, endless-gait evidence, walk, high-control
dry-run command plan, physics-profile, static-support, dynamic-stability,
joint-control, inertial/collision, link-pose, and MoonClaw review-task exports
and verifiers implemented. The dossier build also enforces sibling Moonrobo
source sync for robot.json, URDF joint limits, visual links, missing
inertial/collision tags, URDF visual geometry details, placeholder mesh
bounds, per-link metadata blockers, and high-control limits.

Add generated outputs to the dossier build.

Candidate files:

```text
output/moonrobo/first_trusted_square_noetix_walk.json
output/moonrobo/first_trusted_square_noetix_walk.md
output/moonrobo/first_trusted_square_noetix_endless_gait.json
output/moonrobo/first_trusted_square_noetix_endless_gait.md
output/moonrobo/first_trusted_square_noetix_walk_command.json
output/moonrobo/first_trusted_square_noetix_walk_command.md
output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/noetix-endless-gait.json
output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/noetix-walk.json
output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/noetix-walk-command.json
```

Add verifier:

```text
scripts/check_moonrobo_noetix_walk.py
scripts/check_moonrobo_noetix_endless_gait.py
scripts/check_moonrobo_noetix_walk_command.py
scripts/check_moonrobo_noetix_source_sync.py
```

Check invariants:

- trace id is stable
- robot id is `noetix-e1-lab-01`
- terrain tile is the selected Moonmoon terrain
- gravity is lunar
- body progresses forward
- frames alternate support
- hardware authority is not implied
- terrain risk remains review/block evidence

## Phase 7: MoonBook / MoonClaw Integration

Status: MoonBook entries and workspace payloads implemented for the Noetix
source-model audit, endless-gait evidence, walk trace, high-control dry-run
command plan, physics assumptions, dynamic-stability report, joint-control report,
inertial/collision report, link poses, and MoonClaw review task.
The MoonClaw Noetix task now includes source-sync and endless-gait artifacts
that verify Moonmoon evidence against the sibling Moonrobo robot book/URDF and
prove the exported finite trace remains a window over the cyclic forward gait
before any stronger physics claim.

After the trace is stable, make it durable evidence.

MoonBook entry:

- title: Noetix E1 endless moon-walk simulation trace
- kind: simulation evidence
- source: Moonmoon terrain + Moonrobo model reference + Moonphys primitives
- status: review-needed if terrain grade is risky

MoonClaw task:

- consume trace
- inspect terrain/contact/static-support/link-pose statuses
- inspect capture-point dynamic-stability statuses
- recommend next modeling task:
  - improve terrain sampling
  - add Noetix foot geometry
  - add mass/inertia metadata
  - compare against external physics engine
  - produce better gait controller
- preserve `HardwareDenied` and route the packet through review evidence only

Moonrobo simulation packet:

- include trace as review evidence
- keep hardware state `HardwareDenied`
- no route becomes executable from this alone

## Phase 8: Toward Real Physics

Status: generic convex support-polygon margin, quasistatic support-load
distribution, terrain-normal traction projection, contact-patch pressure
review, capture-point, rigid-body gravity integration, material contact,
bilinear heightfield collision, terrain-normal single-body heightfield contact
resolution, rectangular heightfield contact-patch sampling, deterministic
rigid-body heightfield replay, diagonal-inertia
angular dynamics helpers, conservative sphere/capsule/box collision shape
bounds, narrow-phase sphere/capsule/box contact generation, contact manifold
summaries, multi-contact manifold resolution, generic traction/friction-cone
  assessment, generic joint servo/limit integration, joint-frame motor replay,
  primitive-shape diagonal inertia, composite mass properties, rigid-body
  wrench integration with impulse and kinetic-energy accounting, fixed-step
  multi-body heightfield world replay, world broad-phase/narrow-phase body
  contact scheduling, world body-pair contact response, generic world distance
  constraints between anchored body points with inverse-mass weighted
  correction and impulse accounting, generic hinge-axis alignment assessment
  and correction estimates, generic hinge-joint assessment over rigid body
  motion states, generic hinge-joint frame assessment over multi-body joint
  sets, and joint mechanical power/work accounting implemented;
generic `moonphys/review` source-model metadata inventory/readiness with
missing collision-shape and inertial-link blocker accounting implemented;
generic `moonphys/review` physical-model readiness for authoritative,
assumed, and missing dynamics inputs implemented;
Noetix static support, dynamic-stability, joint-control, and
inertial/collision review reports implemented; full multi-body simulation
remains future work. Moonrobo's Noetix source-model audit now records
URDF/profile paths, visual geometry, concrete joint-limit records, and the
absence of authoritative collision/inertial tags through the generic
`moonphys/review` metadata inventory. Moonrobo's Noetix URDF joint limits are
carried from the
source audit into the robot-specific profile as Moonphys joint limits. Noetix
joint-control review evidence replays the gait
phases through Moonphys joint-frame motor integration, servo, torque, velocity,
position limits, mechanical power/work accounting, and compact Moonphys
hinge-joint frame assessment plus world hinge constraint replay summaries for
the URDF-reference body graph.
Noetix inertial/collision review evidence maps the assumed profile onto
Moonphys composite primitive-shape mass properties, collision bounds, terrain
collision probes, per-foot patch-load contact wrenches, narrow-phase
self-collision manifolds, support-wrench motion preview with impulse and
kinetic-energy accounting, adjacent-link self-collision exclusion, generic
manifold resolution, Moonphys world body-pair contact response, impulse
accounting, and traction margin review.
Mass, inertia, and authoritative collision tags are still absent from every
referenced link, so the evidence remains review-only and the source-model audit
exports the exact missing-link blocker sets.
Moonphys multi-body heightfield world replay currently composes rigid bodies
with shared terrain contact, scheduled body-pair contacts, pairwise contact
response, anchored-point distance constraints, and generic hinge constraints
over motion bodies; generic hinge motor replay can now drive matching world
hinge constraints from scalar joint motor frames, including sequential hinge
motor traces over a finite replay window. Moonphys also exposes an integrated
motor-driven heightfield world trace that applies hinge motor frames before each
fixed heightfield step, so motor drive, terrain contacts, world contacts,
constraints, energy deltas, and review counts live in one deterministic replay
artifact. Moonphys also summarizes deterministic world traces with generic
body-envelope bounds: sample counts, position bounds, aggregate
mass/center-of-mass bounds, max speed, max kinetic energy, max per-frame
kinetic-energy delta, contacts, hinge resolutions, and review counts. Full
coupled articulated dynamics remain future work. Generic world-support traces
now summarize heightfield contact support polygons, COM support margins, and
center-of-pressure error from the same replay frames. Generic world
dynamic-support traces also evaluate capture-point margins from replay COM
velocity and contact footprints.
Generic world replay reviews compose envelope, support, and dynamic-support
trace summaries so Moonrobo and MoonClaw consume one compact review status
with explicit blocker accounting and without owning physics aggregation logic.
Moonphys can now assess hinge-axis alignment, estimate inverse-inertia weighted
corrections from angular body states, compose hinge-joint position/axis
evidence from rigid body motion states into multi-joint frame evidence, and
project hinge position/orientation corrections inside world replay after motor
drive. Noetix joint-control evidence now consumes that generic world hinge motor
replay from Moonrobo-side gait phases and reports a sequential world hinge motor
trace over the gait window while keeping walking primitives outside the clean
Moonphys core.

Only after the kinematic trace is useful, expand `moonphys`.

Next `moonphys` capabilities:

- multi-contact manifold resolution (implemented)
- contact impulse accounting for manifold resolution (implemented)
- traction/friction-cone contact assessment (implemented)
- narrow-phase capsule/box contact generation for shape pairs (implemented)
- robot-specific inertia/collision profiles from Moonrobo data
- Noetix URDF joint limits mapped into Moonphys joint limits (implemented)
- Noetix joint-control review report over Moonphys servo limits (implemented)
- joint mechanical power/work accounting in motor integration (implemented)
- exact sphere/sphere contacts and generic contact manifold summaries
  (implemented)
- generic joint servo, torque limit, velocity limit, and position limit
  integration (implemented)
- generic joint-frame motor replay over multiple joints (implemented)
- conservative sphere/capsule/box collision shape bounds (implemented)
- diagonal inertia and angular velocity integration (implemented)
- primitive sphere/capsule/box diagonal inertia helpers (implemented)
- composite mass properties with parallel-axis inertia (implemented)
- rigid-body force/torque wrench integration with impulse and kinetic-energy
  accounting (implemented)
- fixed-step multi-body heightfield world replay with per-body forces,
  terrain-contact counts, and kinetic-energy accounting (implemented)
- world body collision shapes, broad-phase pair scheduling, narrow-phase body
  contact scheduling, and body-pair manifold summaries (implemented)
- world body-pair penetration correction plus normal/friction impulse response
  (implemented)
- generic world distance constraints between anchored body points with
  inverse-mass weighted correction and constraint-axis impulse accounting
  (implemented)
- generic hinge-axis alignment assessment over angular body states
  (implemented)
- inverse-inertia weighted hinge-axis correction and angular impulse estimates
  (implemented)
- generic hinge-joint assessment that composes anchored position and hinge-axis
  correction evidence from rigid body motion states (implemented)
- generic hinge-joint frame assessment over multi-body joint sets
  (implemented)
- generic hinge constraints inside heightfield world replay over motion bodies
  (implemented)
- generic hinge motor replay over world hinge constraints (implemented)
- generic sequential hinge motor trace replay over world hinge constraints
  (implemented)
- generic velocity-limited joint command shaping before servo/motor replay
  (implemented)
- generic motor-driven heightfield world trace replay that composes hinge motor
  drive with fixed-step world contact/constraint resolution (implemented)
- generic world-trace envelope summaries for body bounds, max speed, max
  kinetic energy, aggregate center of mass, linear momentum, frame energy
  delta, contacts, hinge resolutions, and review counts (implemented)
- generic world-support trace summaries for heightfield contact support
  margins and center-of-pressure error (implemented)
- generic world dynamic-support trace summaries for capture-point margins over
  heightfield world replay contacts (implemented)
- generic world replay review summaries that compose envelope, support, and
  dynamic-support trace status and blocker counts (implemented)
- convex support polygon / center of mass margin helper (implemented)
- quasistatic support-load distribution for normal force review (implemented)
- terrain-normal traction force projection (implemented)
- contact-patch pressure / center-of-pressure review (implemented)
- contact-patch wrench / support torque review (implemented)
- capture point / linear inverted-pendulum review helper (implemented)
- semi-implicit rigid-body gravity integration (implemented)
- material/friction model (implemented)
- bilinear heightfield collision and terrain-normal contact response
  (implemented)
- rectangular heightfield contact-patch sampling over center/corner probes,
  including oriented patch sampling over caller-provided surface bases
  (implemented)
- deterministic rigid-body heightfield replay (implemented)
- generic source-model metadata inventory/readiness for collision and inertial
  blockers with stable blocker IDs (implemented in `moonphys/review`)
- generic physical-model readiness for authoritative, assumed, and missing
  mass/inertia/collision/contact/friction/actuator inputs with stable blocker
  IDs (implemented in `moonphys/review`)

Robot-specific missing metadata:

```text
mass
center of mass
inertia
collision shapes
foot sole geometry
joint damping
joint stiffness
actuator limits
friction assumptions
```

This should live outside core `moonphys`, probably as:

```text
src/adapters/moonrobo/noetix_physics_profile.mbt
```

or as a data artifact beside the Noetix model.

## Immediate Next Steps

1. Pause new MoonClaw orchestration work and fix the Moonrobo/Rabbita Noetix
   rig visual first. The next implementation slice is Phase 5A: bridge the URDF
   link/joint tree into a rigid robot animation rig, render rigid link visuals
   from FK transforms, and keep sticks as debug overlay only.
2. Replace assumed mass/sole/friction profile with Moonrobo inertial and
   authoritative collision metadata when available.
3. Replace review-only inertial/collision evidence with authoritative Moonrobo
   collision/inertia tags once the source model exposes them.
4. Add mesh/collision/inertial metadata to the FK output when Moonrobo exposes
   it.
   Current FK output carries available visual mesh/shape metadata plus explicit
   missing collision/inertial metadata status from the source-model audit;
   authoritative tags still require Moonrobo source data.
5. Later, after the robot visual is credible, continue feeding accepted Noetix
   review outcomes into downstream Moonrobo/MoonClaw gates. The Moonphys
   world-replay blocker is already
   cleared and no longer appears as a readiness work item.
   The next gate slice has started by separating support-stable and
   capture-stable counts from review-only blocker counts in MoonClaw task and
   readiness artifacts.
   Static-support and dynamic-stability margin artifacts clear as artifacts
   once all frames pass.
   Joint-control replay checks now clear as an artifact once limit, saturation,
   support/capture, and world replay blockers are absent.
   Inertial/collision checks now clear as an artifact once terrain and filtered
   self-contact replay blockers are absent, leaving authoritative source and
   physical metadata as the remaining gates.

### Phase 1 Gate Added: Noetix Readiness Receipts

MoonClaw now emits Noetix readiness work item receipts that carry the two
remaining blocked readiness domains forward as accepted audit receipts while
keeping the underlying work item result pending fresh evidence. These receipts preserve
named blockers, target evidence paths, command/check pairs, `SimulationBlocked`,
`may_consume_simulation = false`, and `HardwareDenied` under
`moonmoon-safety-gate-only`.

The receipt gate lives in MoonClaw instead of Moonrobo so Moonrobo remains a
clean producer of robot simulation evidence. MoonBook materializes the receipts
as a first-class workspace entry, and the dossier build validates the generated
JSON before any downstream MoonRobo simulation consumption can be claimed.

### Phase 1 Control Improvement Added: Velocity-Limited Joint Commands

Moonphys now exposes a generic velocity-limited joint command shaper. Moonrobo
uses it before Noetix joint-control replay so terrain-normal IK targets that
would require more than a URDF joint's velocity limit are converted into
reachable per-frame commands. This clears the previous Noetix limit-review
frame and turns the hinge motor trace from review to driven, while keeping the
joint-control packet review-only because servo gains, joint inertias, source
metadata, and hardware authority are still unresolved.

The world replay blocker inventory has now dropped from
envelope/support/dynamic-support to empty. That keeps downstream MoonClaw work
items focused on remaining source metadata and physical-model problems instead
of stale replay or review-artifact blockers.

This gives the project a clean physics library plus a credible first Noetix
walking-on-the-Moon demo without mixing product layers.
