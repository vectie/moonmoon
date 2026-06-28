# Animation-First Locomotion Plan

This restores the larger gait plan from the pre-standalone history and updates
it for the current Moonmoon boundary. The goal is to make the robot walk in a
way that reads as a believable biped while still respecting the real robot
definition.

The rule is:

```text
credible motion first, URDF/FK rigidity always, Moonphys validation after
```

Moonphys stays clean. Robot walking style, phase timing, foot locks, imported
URDF visuals, mesh attachments, and Rabbita diagnostics belong in the suite
adapter and UI layer.

## Problem

A robot does not look like it is walking just because every pose is physically
bounded. Games solve this by layering animation intent, motion systems, IK
correction, physics feedback, and perception cues. For Noetix-like robots the
same idea applies, except the rig is the URDF joint tree and the rendered body
is rigid links and meshes, not a skinned human avatar.

The immediate target is a repeatable endless walk in one direction:

- source robot definition provides link lengths, axes, limits, and visuals
- render uses rigid FK poses, not stretched sticks
- the walk has root motion, phase labels, foot locking, and readable biped
  timing
- Rabbita exposes enough diagnostics to explain bad frames
- Moonphys reviews the resulting motion without owning robot gait choices

## Pipeline

The current direction is:

```text
walk clip
  -> root-motion and phase markers
  -> authored foot targets and lock states
  -> bounded joint samples
  -> rigid FK link poses
  -> terrain IK correction
  -> Moonphys contact/support/motor validation
  -> Rabbita primary render and overlays
```

The walk clip can be procedural at first, but it must be inspectable as data:
phase, root offset, joint targets, foot targets, lock states, and semantic
markers.

## Boundaries

- `src/moonphys` owns generic math, transforms, terrain sampling, contact
  probes, support/capture review, joints, motors, and future constraints.
- `src/moonphys` must not contain robot names, walk phases, gait style,
  animation clip choices, or Rabbita labels.
- The future Moonrobo adapter owns robot model ingestion, URDF/FK rig mapping,
  gait clips, joint target generation, foot locks, and terrain adaptation.
- `ui/rabbita-moon` may host the current standalone preview and browser
  diagnostics, but it must label that preview as adapter-style evidence.
- MoonBook and MoonClaw consume durable evidence later; they do not drive the
  gait loop.

## URDF And Mesh Contract

The robot body is not an arbitrary character skeleton. The robot definition is
the rig:

- each link is a rigid body segment
- each joint defines parent, child, origin, axis, and limits
- link lengths and local offsets remain invariant during animation
- visual geometry comes from primitives or mesh references
- visual mesh or primitive attachment per link is a required render contract
- visual attachments are named by link id and reported separately from debug
  markers
- sticks and foot dots are debug overlays only

The bridge from sticks to bones is rigid FK:

```text
joint tree + joint targets
  -> FK world transform per link
  -> attach each link visual mesh or primitive to that link transform
  -> draw optional parent/child debug lines
```

If a foot marker looks correct but the rendered foot is detached, the contract
is broken. The marker must not replace the real FK foot link.

## Layer 1: Walk Clip Asset

The foundation is the motion asset. Without a readable cycle, physics and IK
only constrain a bad walk.

The first clip exposes:

- normalized cycle progress
- phase labels: `contact`, `loading`, `stance`, `passing`, `swing`, `release`
- mirrored left/right timing
- root-motion stride per cycle
- left/right authored foot target curves
- foot lock and release markers
- root correction remains continuous through support transfer
- pelvis/base lateral transfer over the support foot
- small vertical bob at loading and passing
- torso or waist counter-rotation
- shoulder and arm counter-swing against the opposite leg
- elbow lag rather than rigid pendulum arms
- stance knee nearly straight but not locked
- swing knee flexion peaking near passing
- swing hip/ankle arc keeps the visible foot from dragging through terrain
- swing foot clearance remains visible after toe-off through passing, swing,
  and release
- full foot world motion remains continuous through lift-off, release, and loop wrap
- flat-terrain preservation
- forward-bend convention: knee flexion places the knee forward of the
  hip-to-ankle chain, never visually back-folding the leg
- ankle/toe pitch across contact, foot-flat, and toe-off

Acceptance:

- the clip can be sampled without terrain or physics
- one cycle advances exactly one configured stride
- frame `N + cycle_frames` has the same phase as frame `N`
- left and right sides mirror cleanly
- all joint samples respect robot limits
- Rabbita can inspect the clip channels

## Layer 2: Root Motion And Playback

The walk clip owns forward displacement. The program requests direction,
playback rate, and stride scale; it does not drag the body forward while feet
try to catch up.

Acceptance:

- root motion advances monotonically along the configured heading
- feet are authored relative to root motion
- the loop is seamless over the Rabbita demo window
- full foot world motion does not jump backward when support changes or the
  cycle wraps
- a zero-relief terrain pass preserves flat contact patches and smooth foot
  motion
- root path and phase labels are visible

## Layer 3: Foot Locking

Foot locking is the first guard against skating.

Current status: active in the Rabbita preview. Support feet now get a
visible-space planted-foot stability check against their stance-start anchor,
and `check:gait` requires stance stability without feeding forward/back anchor
correction into the visible root.

Required behavior:

- each foot has an explicit `locked` channel
- visible stance foot world delta stays near zero
- swing foot is unlocked and follows an arc
- double-support windows are explicit
- lock and release markers are emitted

Rabbita must show these as separate concepts:

- authored foot target
- FK foot endpoint
- terrain contact probe
- terrain-corrected target

## Layer 4: Terrain IK Correction

Terrain adaptation comes after the flat-ground walk reads correctly. The
correction layer changes joint targets inside bounds; it does not stretch links
or move rendered feet independently from FK.

Inputs:

- walk clip foot target
- FK foot endpoint
- Moonphys terrain height and normal
- foot lock state
- phase label and swing progress
- joint limits

Outputs:

- bounded ankle pitch/roll correction
- bounded knee/hip correction
- support sole alignment
- bounded pelvis height correction
- correction status for reports and overlays

## Layer 5: Moonphys Validation

Physics validates a credible motion. It does not become the first source of
walking style.

Moonphys review consumes:

- FK link poses
- mass and inertia estimates
- joint targets and bounded positions
- hinge motor frames
- terrain contact probes and contact patches
- support polygon and capture-point evidence
- force, torque, traction, energy, and momentum estimates

Moonphys emits pass, warn, or fail evidence. It does not silently rewrite the
animation clip.

## Layer 6: Readability

Noetix is a robot, not a human, but viewers still expect readable biped timing.

Checks:

- contact frames are clear
- weight shifts onto the stance foot
- passing pose lifts the swing leg naturally
- right leg forward implies left arm forward with slight lag
- pelvis/base and torso counter-rotate
- endless loop does not pop
- terrain IK is not added until flat-ground motion looks intentional

## Implementation Phases

### Phase A: Clip Contract

Deliverables:

- phase enum or stable labels
- root-motion stride
- per-foot lock/contact/swing samples
- per-joint target samples
- cycle repeat, mirroring, stride, and limit tests

Current status: active preview in `ui/rabbita-moon`; future adapter should move
this into a typed Moonrobo clip package.

### Phase B: Walk Frame Authority

Deliverables:

- root-motion fields
- gait phase fields
- left/right foot lock fields
- no inline gait authority hidden inside render code
- generated output includes these fields

Current status: active preview. `ui/rabbita-moon/gait-clip.js` owns the local
adapter-style clip contract for root motion, phase labels, foot lock/support
channels, joint target samples, and URDF limit metadata. `scene3d.js` renders
and reviews that contract instead of owning hidden gait authority. The future
Moonrobo adapter should move the same contract shape into a typed adapter
package.

### Phase C: Rabbita Locomotion Overlay

Deliverables:

- current phase label
- root path
- locked foot marker
- swing foot marker
- authored foot target
- FK foot endpoint
- contact probe
- correction delta once IK exists
- selected hip, knee, ankle, and arm values

Acceptance:

- a viewer can tell whether an issue is clip timing, FK, rendering, contact, or
  terrain correction
- overlay never replaces rigid rendering

### Phase D: Motion-Curve Tuning

Deliverables:

- weight transfer curve
- passing-position curve
- toe-off/contact ankle curve
- arm lag and counter-swing
- torso/waist counter-rotation
- swing foot clearance
- loop continuity checks

Acceptance:

- the walk looks intentional without terrain correction
- swing and stance knees have clearly different roles
- after toe-off, the swing foot does not visibly drag through terrain
- knees keep the forward-bend convention throughout the cycle
- link lengths remain invariant

### Phase E: Terrain IK

Deliverables:

- foot target correction
- pelvis height correction
- hip/knee/ankle correction
- correction saturation evidence
- flat-terrain preservation tests
- non-flat terrain height and normal response
- contact patch evidence for support review

### Phase F: Physics Review

Deliverables:

- support/capture checks on animation-first FK poses
- hinge motor replay checks
- contact/traction evidence
- force/torque envelopes
- generic Moonphys motion-frame review types
- generic Moonphys motion-frame trace review types
- generic Moonphys motion and hinge replay combined review types
- Rabbita evidence export that can be consumed by those generic types

### Phase G: Future Asset System

After the procedural clip works, consider authored keyframes for root, feet,
pelvis, torso, and joints, plus a small clip library for idle, start, walk,
stop, and turn. Motion matching only makes sense after enough asset data exists.

## Current Next Slice

1. Strengthen Rabbita diagnostics for phase, root motion, lock state, authored
   target, FK endpoint, contact separation, and selected joint samples. Status:
   active in the Rabbita preview.
2. Tune the flat-ground clip until the rigid body reads like a biped walk.
3. Add tests or browser checks for cycle repeat, FK link-length invariance, and
   target/render detachment. Status: browser-facing runtime checks now expose
   cycle repeat, root motion, mirror timing, target/FK attachment, support-foot
   lock, knee role contrast, arm counter-swing, and link-length invariant
   statuses.
4. Add terrain IK only after the base walk is readable. Status: the Rabbita
   preview now has a flat-terrain contact probe, bounded support-leg
   hip/knee/ankle correction, bounded support-pelvis fallback correction,
   support sole alignment across toe, heel, and center contact probes,
   terrain-corrected foot targets, authored/corrected joint samples, and
   browser-facing IK/contact status datasets. Non-flat terrain height/normal
   response and per-foot contact patches are active in the preview.
5. Feed corrected FK poses into Moonphys review. Status: `src/moonphys` now has
   generic motion contact/frame review types that compose support, load,
   traction, contact-patch, wrench, and capture checks. Rabbita now exports a
   `moonphysReviewFrame` evidence payload from its FK/contact diagnostics.
   `src/moonphys` also has a generic motion-frame trace review that envelopes
   support, capture, normal/tangential force, contact torque, pressure, and
   friction utilization across sampled frame reviews. Rabbita exports a
   `moonphysReviewTrace` evidence payload over one walk cycle. `src/moonphys`
   now also has a generic motion/hinge replay combined review that accepts a
   motion-frame trace review plus a heightfield hinge motor trace or explicit
   replay review, checks frame alignment, driven joints, replay blockers, and
   exposes one ingestion-ready validation result. Rabbita now exports a
   `moonphysHingeMotorTrace` from corrected FK joint samples and a
   `moonphysMotionHingeReview` that checks frame alignment, driven joints,
   motor limit status, torque, velocity, and work envelopes against the
   motion-frame trace. The hinge replay table now cites the Moonrobo Noetix
   profile and URDF sources, uses URDF joint ids such as `leg_l1_joint`,
   `leg_l4_joint`, `leg_l6_joint`, `arm_l1_joint`, and `arm_l4_joint`, and
   verifies velocity and effort against those URDF limits. `src/suite_adapter_preview`
   now consumes a generated MoonBit evidence artifact emitted from
   `ui/rabbita-moon/scene3d.js#__moonmoonGaitDiagnostics`, then runs that live
   Rabbita/Moonrobo Noetix payload through compiled Moonphys using
   `motion_hinge_replay_review_with_replay`. `npm run check:gait` now verifies
   the generated artifact is fresh before invoking the compiled gate. The
   Rabbita preview now emits an explicit load-bearing support channel, wider
   rendered-sole support patches, and a small support-phase mass-transfer COM
   channel; the generated evidence now clears compiled Moonphys motion, hinge,
   replay, support, capture, contact, torque, pressure, velocity, effort,
   motion-side linear momentum, and motion-side kinetic-energy review for the
   sampled endless walk. Phase D visual polish is now being implemented in the
   Rabbita 3D preview itself: the endless walk clip has a
   toe-off/contact foot-roll channel rendered through separate toe/heel blocks,
   lagged arm counter-swing with visible hands, and torso/waist
   counter-rotation above the pelvis while the legs remain rigid FK from the
   Moonrobo Noetix proportions. The browser contract exposes `toeRollStatus`,
   `toeRollRad`, `torsoCounterRotationStatus`, and
   `torsoCounterRotationRad`, so this slice is measured as live motion, not as
   a separate fixture mirror. The Rabbita preview also promotes the six
   animation subphases (`contact`, `loading`, `stance`, `passing`, `swing`,
   `release`) into `footPhaseChannels`, `gaitPhaseLabel`, and
   `footPhaseCoverageStatus`, and renders root/phase timing rails in the 3D
   scene so the walk can be inspected like an animation asset. The preview now
   also blends terrain IK across lift-off and pre-contact release, and exposes
   `footWorldMotionContinuityStatus` plus `footWorldMotionContinuity` so sudden
   forward-then-backward foot pops are caught at the world-motion layer. It also
   exposes `flatTerrainPreservationStatus` and `flatTerrainPreservation` from a
   zero-relief terrain sweep through the same FK/IK path, so flat-terrain
   preservation is checked before non-flat terrain response is trusted. The
   renderer now reports named rigid visual attachments through
   `visualLinkAttachments` and `visualAttachmentStatus`, separating Noetix link
   visuals from foot markers, target cubes, terrain rails, and other debug
   overlays. `src/suite_adapter_preview` now wraps the generated review in a
   typed `NoetixSuiteAdapterPayload` that records Moonrobo source references
   for the Noetix robot profile, URDF, mesh asset, generated evidence source,
   driven joint ids, compiled review status, and blockers. Moonrobo now has a
   typed source-side `src/moonmoon_adapter` contract for the same Noetix
   profile, URDF, mesh, required motion joints, blockers, readiness fields, and
   a typed `noetix_walk_clip` authority for the endless forward walk cycle.
   Moonrobo also exposes `cmd/moonmoon_contract`, and
   `ui/rabbita-moon/export-moonrobo-contract.mjs` regenerates
   `src/suite_adapter_preview/generated_moonrobo_noetix_contract.mbt` and
   `ui/rabbita-moon/generated-moonrobo-noetix-clip.js` from that typed source
   package. The default suite payload now routes through the live contract
   ingestion path, carries authored contact frames as payload data, and can run
   compiled Moonphys review from its own parsed joint, motion, contact, and
   motor tables. Rabbita runtime imports the live/generated JS clip for cycle
   rate, root speed, stride, foot phase sequence, foot roles, support windows,
   curve metadata, the typed Moonrobo-authored joint sample table, typed
   authored motion samples for root bob/sway, torso counter-rotation, foot roll,
   root-local foot targets, typed authored FK/contact frames, and typed authored
   motor frames for Moonphys review. Rabbita interpolates those
   generated samples instead of owning the leg/arm, root, torso, foot-roll,
   authored foot-target, FK/contact, or hinge motor target formulas in
   `gait-clip.js` and `scene3d.js`. The compiled Moonphys bridge now consumes
   Moonrobo-authored contact frames and Moonrobo-authored motor frames directly;
   Rabbita-generated evidence remains a browser/UI freshness gate. `npm run
   check:gait` verifies the contract bridge freshness, runtime authored-sample
   consumption, Moonrobo-authored contact and hinge motor trace consumption,
   live Moonrobo typed adapter evidence, and Rabbita UI evidence freshness. The
   first live regeneration gate is `../moonrobo/cmd/moonmoon_suite_evidence`,
   checked by `ui/rabbita-moon/check-live-moonrobo-suite.mjs`.
   `ui/rabbita-moon/prepare-live-moonrobo-clip.mjs` now writes the live runtime
   bridge at `ui/rabbita-moon/.generated/live-moonrobo-noetix-clip.js`, and
   Rabbita imports that bridge for runtime gait data. The MoonBit suite-preview
   payload also carries the live Moonrobo evidence summary, records its typed
   source, and blocks readiness when the live summary diverges from the
   generated bridge. `src/suite_adapter_preview/moonrobo_live_ingestion.mbt`
   now accepts a full live Moonrobo contract JSON value, decodes the authored
   joint, motion, contact, and motor tables, and runs the compiled Moonphys
   review from the parsed contact/motor frames. The next Phase 10 target is to
   move the plain build/test fixture behind a live suite-preview command/build
   step and remove the committed generated MoonBit motion/contact/motor table
   snapshot.
