# Moonphys Feature Plan

Goal: build a clean MoonBit physics library called `moonphys`, then use it from
MoonSuite collaboration layers so the Noetix robot can walk endlessly in one
direction over Moonmoon terrain, with Moonrobo owning robot-specific simulation
evidence.

## Current Implementation Status

- `moonphys` has generic vector, transform, environment, heightfield, contact,
  kinematic, support-margin, and trace primitives.
- Moonrobo adapts Moonmoon terrain into a generic `moonphys` heightfield.
- The Noetix endless walk trace consumes `moonphys` heightfield/contact APIs
  instead of owning terrain math.
- Every walk frame includes 24 Noetix joint phases for animation/replay.
- The trace is exported as Markdown and JSON under `output/moonrobo`.
- MoonBook materializes the trace as a durable workspace entry.
- Moonrobo exports a Noetix physics-assumption profile and static COM/support
  report backed by generic Moonphys support assessment.
- Moonrobo exports a Noetix source-model audit that records the sibling
  Moonrobo URDF/profile paths, 25 links, 24 joints, 24 joint limits, six visual
  geometries, one placeholder mesh asset, and zero authoritative collision or
  inertial tags.
- Moonphys exports a generic capture-point assessment for dynamic-stability
  review, and Moonrobo exports a Noetix dynamic-stability report backed by it.
- Moonrobo exports URDF-reference Noetix link-pose evidence: body/limb links
  use compact URDF forward kinematics, and feet are bound to Moonphys contact
  probes with FK contact error. Each link-pose entry now also carries source
  visual-geometry evidence from the Noetix source-model audit, or an explicit
  missing-visual-geometry status when the URDF link has no visual block.
- Moonrobo exports Noetix inertial/collision review evidence backed by
  Moonphys diagonal inertia, collision bounds, terrain collision probes,
  contact torque, narrow-phase self-collision manifolds, and generic
  multi-contact manifold resolution with impulse accounting.
- MoonClaw exports a Noetix simulation review task that ties the walk trace,
  URDF-reference link poses, static support report, dynamic-stability report,
  joint-control report, inertial/collision report, and Rabbita playback into a
  hardware-denied review packet.
- `scripts/check_moonrobo_noetix_walk.py` verifies trace invariants.
- `scripts/check_moonrobo_noetix_source_model.py` verifies source-model audit
  invariants.
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

Status: first core slice implemented.

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

Status: first Noetix endless walk trace implemented in
`src/adapters/moonrobo/noetix_moon_walk.mbt`.

Keep this in `src/adapters/moonrobo`, not `moonphys`.

Current version already has the first shape:

- body moves in `+x`
- alternating left/right support
- swing foot clearance
- terrain elevation probe
- terrain grade review status
- finite trace prefix represents an endless periodic gait
- configurable heading, start position, stride frequency, body height, foot
  radius, and terrain source provenance

Next improvements:

- Keep the trace types robot-specific:
  - `NoetixMoonWalkTrace`
  - `NoetixMoonWalkFrame`
  - `NoetixFootContactProbe`
- Keep `frame_count` finite in exports, but make the gait mathematically endless
  through cycle indexing.
- Replace the kinematic phase generator with a controller-backed gait once
  Moonrobo supplies authoritative mass, inertia, collision, damping, stiffness,
  and actuator metadata.

Tests:

- frame `N + cycle` has the same gait phase
- body `x` strictly increases
- support foot alternates
- swing foot clears ground
- contact foot is on terrain
- trace includes lunar gravity from `moonphys`

## Phase 4: URDF-Aware Noetix Pose

Status: compact URDF-reference forward kinematics implemented in
`src/adapters/moonrobo/noetix_link_pose.mbt`; mesh geometry, collision
geometry, inertial metadata, and full dynamics remain future work; source
visual geometry is now carried in each link-pose entry for viewer/render use.

Use Moonrobo's URDF work as the robot-specific layer.

Input from sibling Moonrobo:

- `../moonrobo/examples/noetix-e1/robot.json`
- `../moonrobo/examples/noetix-e1/model/robot.urdf`
- Moonrobo's existing URDF parser and viewport simulation as reference material

In this repo, initially avoid copying full URDF parsing. Instead:

- keep Noetix metadata as references
- encode the compact Noetix URDF link tree in the Moonrobo adapter
- bind feet to Moonphys contact probes from the walking trace
- compute body/limb poses with the compact URDF link tree, joint origins, joint
  axes, and gait joint phases until Moonrobo supplies full mesh/inertial/
  collision metadata

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

This gives downstream viewers enough structure to draw the robot walking with a
real FK tree and approximate source shapes without claiming full dynamics.

## Phase 5: Rabbita Visualization

Status: first trace scrubber and link-pose playback implemented in Rabbita;
full mesh/URDF rendering remains future work.

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
- frame scrubber or autoplay
- status badges:
  - `walking`
  - `walking-needs-review`
  - `terrain-grade-review`
- explicit simulation-evidence-only label

Do not connect this to hardware controls.

## Phase 6: Evidence Export

Status: first source-model audit, walk, physics-profile, static-support,
dynamic-stability, joint-control, inertial/collision, link-pose, and MoonClaw
review-task exports and verifiers implemented.

Add generated outputs to the dossier build.

Candidate files:

```text
output/moonrobo/first_trusted_square_noetix_walk.json
output/moonrobo/first_trusted_square_noetix_walk.md
output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/noetix-walk.json
```

Add verifier:

```text
scripts/check_moonrobo_noetix_walk.py
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
source-model audit, walk trace, physics assumptions, dynamic-stability report,
joint-control report, inertial/collision report, link poses, and MoonClaw
review task.

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

Status: generic support-margin, capture-point, rigid-body gravity integration,
material contact, heightfield collision, single-body heightfield contact
resolution, deterministic rigid-body heightfield replay, diagonal-inertia
angular dynamics helpers, conservative sphere/capsule/box collision shape
bounds, narrow-phase sphere/capsule/box contact generation, contact manifold
summaries, multi-contact manifold resolution, generic traction/friction-cone
assessment, generic joint servo/limit integration, and joint mechanical
power/work accounting implemented;
Noetix static support, dynamic-stability, joint-control, and
inertial/collision review reports implemented; full multi-body simulation
remains future work. Moonrobo's Noetix source-model audit now records
URDF/profile paths, visual geometry, concrete joint-limit records, and the
absence of authoritative collision/inertial tags. Moonrobo's Noetix URDF joint
limits are carried from the source audit into the robot-specific profile as
Moonphys joint limits. Noetix
joint-control review evidence replays the gait phases through Moonphys joint
servo, torque, velocity, position limits, and mechanical power/work accounting.
Noetix inertial/collision review evidence maps the assumed profile onto
Moonphys diagonal inertia, collision bounds, terrain collision probes, contact
torque, narrow-phase self-collision manifolds, generic manifold resolution,
impulse accounting, and traction margin review. Mass, inertia, and
authoritative collision tags are still absent from the referenced model, so the
evidence remains review-only.

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
- conservative sphere/capsule/box collision shape bounds (implemented)
- diagonal inertia and angular velocity integration (implemented)
- support polygon / center of mass helper (implemented)
- capture point / linear inverted-pendulum review helper (implemented)
- semi-implicit rigid-body gravity integration (implemented)
- material/friction model (implemented)
- heightfield collision and simple contact response (implemented)
- deterministic rigid-body heightfield replay (implemented)

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

1. Replace assumed mass/sole/friction profile with Moonrobo inertial and
   authoritative collision metadata when available.
2. Replace review-only inertial/collision evidence with authoritative Moonrobo
   collision/inertia tags once the source model exposes them.
3. Add mesh/collision/inertial metadata to the FK output when Moonrobo exposes
   it.
4. Feed accepted Noetix review outcomes into downstream Moonrobo/MoonClaw gates.

This gives the project a clean physics library plus a credible first Noetix
walking-on-the-Moon demo without mixing product layers.
