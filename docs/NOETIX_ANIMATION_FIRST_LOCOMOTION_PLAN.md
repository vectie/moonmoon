# Noetix Animation-First Locomotion Plan

This plan documents how to make the Noetix robot walk endlessly in a way that
reads as a believable biped while still respecting the real robot definition.
The guiding rule is:

```text
credible motion first, URDF/FK rigidity always, Moonphys validation after
```

Moonphys must remain a clean physics library. Noetix walk style, phase timing,
foot locks, and Rabbita visualization are Moonrobo/Rabbita responsibilities.

## Problem Statement

The current endless walk can expose URDF joints, contact probes, and terrain
interaction, but a robot does not look like it is walking just because every
pose is physically bounded. Games solve this by layering animation intent,
motion systems, IK correction, physics feedback, and human perception cues. For
Noetix, the same idea applies, but the "skeleton" is the URDF kinematic tree and
the rendered body is rigid robot links and meshes, not a skinned human avatar.

The immediate target is not full autonomy or reinforcement-learned control. The
target is a repeatable, inspectable endless walk in one direction:

- it uses the Noetix URDF joint tree as the source of link lengths and axes
- it renders rigid URDF visual geometry and meshes through FK
- it has a readable biped walk cycle with root motion and foot locking
- it exposes enough debug data for Rabbita to explain wrong-looking frames
- Moonphys reviews the result without owning Noetix-specific gait decisions

## Reference Model

Piccolo-style character walking looks human because it does not start from raw
physics. It starts from a motion asset and then layers correction and physics on
top. The Noetix version should follow this pipeline:

```text
Noetix walk clip
  -> root-motion and phase markers
  -> URDF-bounded joint samples
  -> RobotMotionFrame
  -> FK rigid link poses
  -> terrain IK correction
  -> Moonphys contact/support/motor validation
  -> Rabbita primary render and overlays
```

The robot-specific walk clip is the animation asset equivalent. It may be
procedural at first, but it must be inspectable as data: phase, root offset,
joint targets, foot targets, lock states, and semantic markers.

## Hard Boundaries

- `src/moonphys` owns generic math, transforms, terrain sampling, contact
  probes, support/capture review, joints, motors, and future constraints.
- `src/moonphys` must not contain `Noetix`, walk phases, gait style, animation
  clip choices, or Rabbita debug labels.
- `src/adapters/moonrobo` owns Noetix URDF ingestion, rigid robot rig, walk
  clips, joint target generation, foot locks, and terrain adaptation.
- `src/ui/rabbita_moon` owns visual inspection and browser overlays.
- MoonClaw stays aside for this slice. It should consume improved evidence
  after the walk is visually credible, not drive the motion work.

## URDF And Mesh Contract

The Noetix body is not an arbitrary character skeleton. The URDF is the rig:

- each URDF link is a rigid body segment
- each URDF joint defines the parent-child relation, axis, origin, and limits
- link lengths and local offsets must remain invariant during animation
- visual geometry comes from URDF primitives and mesh references
- sticks/bones are debug overlays only, never the primary render

The bridge from "URDF sticks" to "bones" is therefore not skinning. It is a
rigid FK pipeline:

```text
URDF joint tree + joint targets
  -> FK world transforms per link
  -> attach each link visual mesh/primitive to its own world transform
  -> optional debug line from parent joint to child joint
```

If a foot marker looks correct but the rendered foot link does not attach to it,
that is a contract bug: either the marker is not an FK foot endpoint, the render
uses a non-FK pose, or the debug target is being mistaken for the actual link.

## Layer 1: Walk Clip Asset

The foundation is the motion asset. Without a good walk cycle, physics and IK
will only make a bad walk more constrained.

The first Noetix walk clip should expose:

- normalized cycle progress
- phase labels: `contact`, `loading`, `stance`, `passing`, `swing`, `release`
- mirrored left/right timing
- root-motion stride per cycle
- left/right foot target curves
- foot lock and release markers
- pelvis/base lateral transfer over the support foot
- small vertical bob at loading/passing
- torso/waist counter-rotation
- shoulder/arm counter-swing against the opposite leg
- elbow lag rather than rigid pendulum arms
- stance knee nearly straight but not locked
- swing knee flexion peaking near passing/swing
- ankle/toe pitch across contact, foot-flat, and toe-off

Acceptance:

- the clip can be sampled without terrain or physics
- one cycle advances exactly one configured stride
- frame `N + cycle_frames` has the same phase as frame `N`
- left/right sides mirror cleanly
- all joint samples are bounded by URDF joint limits
- the clip can be inspected in tests and Rabbita overlays

## Layer 2: Root Motion And Playback

The walk clip should own forward displacement. The program requests direction,
playback rate, and stride scale; it should not independently drag the body
forward while the feet try to catch up.

Required behavior:

- root motion advances monotonically along the configured heading
- playback rate changes timing explicitly
- stride scale changes the clip stride explicitly
- feet are authored relative to root motion, not patched afterward
- the walk loops seamlessly over the Rabbita 32-frame demo window

Acceptance:

- no visible skating on flat terrain
- root path and phase labels are visible in Rabbita
- body advance can be derived from clip root motion alone

## Layer 3: Foot Locking

Foot locking is the first guard against skating. During stance, the support foot
must remain stable in world space until release.

Required behavior:

- each foot has an explicit `locked` channel
- stance foot world-position delta stays near zero
- swing foot is unlocked and follows an arc
- double-support windows are explicit
- lock/release markers are emitted for Rabbita
- tests fail if FK foot links are detached from the URDF tree to fake contact

Important distinction:

- authored foot target: where the walk clip expects the foot
- FK foot endpoint: where the URDF pose puts the actual link
- contact probe: where Moonphys samples the terrain
- corrected foot target: terrain-adapted target after IK

Rabbita must be able to show these separately.

## Layer 4: Terrain IK Correction

Terrain adaptation comes after the base walk reads correctly on flat ground.
The correction layer should modify joint targets within bounds; it should not
stretch links or move rendered feet independently from FK.

Inputs:

- walk clip foot target
- current FK foot endpoint
- sampled Moonphys height and normal
- foot lock state
- phase label and swing progress
- URDF joint limits

Outputs:

- bounded ankle pitch/roll correction
- bounded knee/hip correction
- bounded pelvis height correction
- correction evidence for reports and overlays

Acceptance:

- flat terrain preserves the authored clip closely
- uneven terrain changes joint targets, not link lengths
- support feet align with terrain without skating
- correction magnitude and saturation are visible in Rabbita

## Layer 5: Moonphys Validation

Physics should validate and constrain a credible motion. It should not be used
as the first source of walking style.

Moonphys review should consume:

- FK link poses
- mass/inertia estimates
- joint targets and actual bounded positions
- hinge motor frames
- terrain contact probes and contact patches
- support polygon/capture point evidence
- force, torque, and traction estimates

Moonphys review should emit:

- pass/fail/warn evidence
- limit and motor saturation
- support/capture risk
- foot contact and slip risk
- energy and momentum accounting

Acceptance:

- physics failures are reported as evidence
- physics does not silently rewrite the animation clip
- Moonphys core remains Noetix-agnostic

## Layer 6: Perception And Readability

The last part of "looks right" is perception. Noetix is a robot, not a human,
but the viewer still expects readable biped timing.

Required readability checks:

- contact frames are clear
- weight shifts onto the stance foot
- passing pose lifts the swing leg naturally
- right leg forward implies left arm forward with slight lag
- pelvis/base and torso counter-rotate
- start/stop are not in scope yet, but the endless loop must not pop
- breathing, gaze, emotion, and micro-actions are out of scope for the robot
  walk slice unless later mapped to robot-specific idle behaviors

The walk should be judged visually before adding more physics complexity.

## Implementation Phases

### Phase A: Clip Contract

Create or extend Moonrobo clip data around `NoetixWalkClipSample`.

Deliverables:

- explicit phase enum and labels
- root-motion stride
- per-foot samples with lock/contact/swing fields
- per-joint target samples with URDF-bounded positions
- tests for cycle repeat, mirroring, stride, and limits

Status: first version implemented as a compact procedural clip. Continue
expanding it as inspectable data rather than hiding new formulas inline.

### Phase B: Walk Frame Authority

Make `NoetixMoonWalkFrame` consume the walk clip as the authority for motion.

Deliverables:

- root-motion fields in walk frames
- gait phase in walk frames
- left/right foot lock fields
- no old inline gait authority in `noetix_moon_walk.mbt`
- generated Moonrobo/Rabbita output includes these fields

Status: first version implemented.

### Phase C: Rabbita Locomotion Overlay

Make wrong motion diagnosable in the browser.

Deliverables:

- current phase label
- root path
- locked foot marker
- swing foot marker
- authored foot target
- FK foot endpoint
- Moonphys contact probe
- correction delta once terrain IK exists
- selected joint values for hips/knees/ankles/arms

Acceptance:

- a viewer can tell whether the issue is clip timing, FK, rendering, contact,
  or terrain correction
- overlay never replaces rigid URDF rendering

Status: in progress. Rabbita now renders first-pass diagnostic overlays for
root motion, foot lock/swing state, walk targets, FK foot endpoints, Moonphys
contact probes, and FK/contact deltas. Moonrobo also exposes a
`NoetixLocomotionDiagnosticTrace` contract so this separation is testable as
robot evidence instead of being only a browser-side convention.

### Phase D: Motion-Curve Tuning

Tune for readable biped motion on flat terrain before adding terrain IK.

Deliverables:

- weight-transfer curve
- passing-position curve
- toe-off/contact ankle curve
- arm lag and counter-swing
- torso/waist counter-rotation
- loop continuity tests

Acceptance:

- the walk looks intentional without terrain correction
- swing and stance knees have clearly different roles
- no link length changes during animation

### Phase E: Terrain IK

Add bounded terrain adaptation after the clip and FK are credible.

Deliverables:

- foot target correction
- pelvis height correction
- hip/knee/ankle correction
- correction saturation evidence
- flat-terrain preservation tests

Acceptance:

- terrain changes joint targets, not rendered link transforms directly
- all corrections stay within URDF limits

### Phase F: Physics Review

Feed the improved motion through Moonphys.

Deliverables:

- support/capture checks on animation-first FK poses
- hinge motor replay checks
- contact/traction evidence
- force/torque envelopes

Acceptance:

- review flags unsafe frames
- review output does not become hidden motion authority

### Phase G: Future Asset System

After the procedural clip works, consider a real animation asset format.

Possible direction:

- authored keyframes for root, foot, pelvis, torso, and joints
- curve interpolation shared across robot clips
- optional clip library for idle, start, walk, stop, turn
- motion-matching style search only if there is enough asset data

This remains outside Moonphys.

## Current Next Slice

The highest-leverage next work is Rabbita visualization and clip tuning:

1. Show phase, root motion, lock state, and foot target/FK/contact separation in
   the browser.
2. Tune the flat-ground clip until the rigid URDF body reads like a biped walk.
3. Add tests that catch link-length changes and foot-marker/render detachment.
4. Only then add terrain IK correction.
5. Feed the corrected FK pose into Moonphys review.
