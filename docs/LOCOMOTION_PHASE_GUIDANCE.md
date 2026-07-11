# Locomotion Phase Guidance

This document is the current phase guide for locomotion work after the
standalone MoonMoon refactor. It replaces the old Noetix/Rabbita-specific plan
that lived before the repository was simplified.

The guiding boundary is:

```text
route evidence first, motion handoff second, robot gait adapter later
```

Moonphys remains a clean physics library. MoonMoon may expose whether a route
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
- no MoonRobo, Noetix, Rabbita, MoonBook, or MoonClaw package inside the
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

- public Moonphys APIs stay reusable outside MoonMoon
- tests cover deterministic stepping and physics evidence
- no walk primitive is introduced into `src/moonphys`

## Phase 2: Route-Motion Contract

Status: implemented by `src/ui/motion_contract.mbt`.

MoonMoon exposes `TraverseMotionContract` as the current locomotion handoff.
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

A future MoonRobo adapter should consume:

- MoonMoon site dossier
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
- MoonMoon remains useful without the adapter installed
- hardware authority remains denied until explicit external gates clear

## Phase 5: Robot Gait Asset Contract

The first real walking adapter should begin with a motion asset, not raw
physics.

Status: active. The preview still executes through
`ui/rabbita-moon/gait-clip.js`, but MoonRobo now owns the first typed
source-side walk-clip authority in
`../moonrobo/src/moonmoon_adapter/noetix_walk_clip.mbt`. That contract records
the endless forward walk clip id, cycle rate, root speed, stride, sample count,
phase labels, foot phase specs, required motion joints, joint anchors, and
joint curve parameters. It now also evaluates those curve parameters into a
typed 24-frame authored joint sample table for hip, knee, ankle, shoulder, and
elbow targets on both sides, plus authored motion samples for root bob/sway,
torso counter-rotation, foot roll, and root-local foot targets. It also exports
typed authored FK/contact frames with support footprints, contact patches,
terrain probes, applied lunar loads, COM state, and review status, plus typed
authored motor frames with per-joint position, velocity, torque, work, limit,
and review status fields for the Moonphys hinge replay.
MoonMoon regenerates durable suite metadata from that contract through
`ui/rabbita-moon/export-moonrobo-contract.mjs`, which now also emits
`ui/rabbita-moon/generated-moonrobo-noetix-clip.js` as the committed
suite-preview snapshot. Rabbita runtime now imports
`ui/rabbita-moon/.generated/live-moonrobo-noetix-clip.js`, which is produced by
`ui/rabbita-moon/prepare-live-moonrobo-clip.mjs` from live MoonRobo typed
adapter commands before dev, build, export, and gait checks. That live runtime
bridge carries cycle rate, root speed, stride, foot phase sequence, foot roles,
support windows, curve metadata, authored joint samples, authored motion
samples, authored contact frames, authored motor frames, and the live suite
evidence summary. Rabbita now interpolates the live-generated sample tables
instead of owning the leg/arm, root bob/sway, torso, foot-roll, authored
foot-target, or hinge motor target formulas. The
compiled Moonphys review now consumes MoonRobo-authored contact frames and
MoonRobo-authored motor frames directly; Rabbita's generated evidence remains a
browser/UI freshness gate. The Phase 5 runtime data path is now live-generated
from MoonRobo rather than committed snapshots. The first live gate now exists:
`../moonrobo/cmd/moonmoon_suite_evidence` exports
`noetix_e1_moonmoon_live_suite_evidence()` directly from MoonRobo's typed
adapter, and `ui/rabbita-moon/check-live-moonrobo-suite.mjs` compares that live
authority against both the live runtime bridge and the committed MoonMoon
suite-preview snapshot. The MoonBit suite-preview payload now also carries that
live evidence summary as typed `SuiteAdapterLiveSuiteEvidence`, records the
live source ref, and blocks readiness if the live MoonRobo counts, status,
contract id, or walk-clip id diverge from the generated suite payload.

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
link dimensions and FK-derived foot endpoints. Full MoonRobo URDF import and
mesh attachment remain adapter work; MoonMoon core still does not depend on
MoonRobo. The preview now emits named `visualLinkAttachments` for each rendered
link fallback so link visuals can be audited separately from debug markers.

Deliverables:

- URDF joint tree or equivalent rigid model contract
- forward-kinematics link poses
- visual mesh or primitive attachment per link
- browser-facing visual attachment status
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
It exposes `footWorldMotionContinuityStatus` and
`footWorldMotionContinuity` so sudden forward-then-backward foot pops across
lift-off, release, or loop wrap are caught directly. It also exposes
`flatTerrainPreservationStatus` and `flatTerrainPreservation` so the same
FK/IK path proves zero-relief terrain keeps flat contact patches and smooth
foot motion. It renders root/phase timing rails beside the robot so clip timing
is visible without replacing the rigid FK pose.

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
The Rabbita adapter also applies a bounded swing-foot clearance correction
after toe-off so the airborne foot clears non-flat terrain without stretching
links. Support-foot IK now balances toe, heel, and center sole clearances so
the rendered foot reads as planted on terrain slopes instead of only matching a
single contact point. IK correction is phase-weighted through lift-off and
pre-contact release so landing alignment is prepared smoothly instead of being
applied as a one-frame push-back at the support switch. The preview now runs a
zero-relief preservation sweep through the same FK/IK path before trusting the
non-flat terrain response.

Deliverables:

- bounded foot target correction
- bounded pelvis/base height correction
- hip, knee, and ankle correction evidence
- support sole alignment evidence
- full foot world-motion continuity evidence
- swing-foot clearance evidence
- saturation evidence
- flat-terrain preservation tests and browser-facing evidence

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
Moonphys review of typed MoonRobo Noetix contact and motor evidence, with the
Rabbita generated artifact retained as a browser/UI freshness gate. `npm run
check:gait` is the fast viewport/runtime gate; `npm run check:gait:heavy`
verifies generated freshness and live integration paths. The current generated walk
now clears the compiled Moonphys motion, hinge, replay, support, capture,
contact, torque, pressure, velocity, effort, motion-side momentum, and
motion-side kinetic-energy review gate. The preview now also exposes a typed
`NoetixSuiteAdapterPayload` that binds the compiled review to MoonRobo source
references regenerated from `../moonrobo/src/moonmoon_adapter`, including
`../moonrobo/examples/noetix-e1/robot.json`,
`../moonrobo/examples/noetix-e1/e1_asm_251028/urdf/e1_asm.urdf`, and the
25 referenced E1 STL meshes. Rabbita mirrors that authority with
`ui/rabbita-moon/prepare-e1-asm-assets.mjs`, which extracts the local E1
archive into ignored `.generated` storage and renders a second 3D character
from all 25 URDF link visuals using Three.js scene-graph groups while keeping
the boxed walker as the diagnostic body. The viewport renders bounded
viewport-reduced STL geometry for the animated walk:
`viewport-voxel-area-silhouette-v1` buckets source triangles in mesh space,
keeps large-area representatives, and preserves axis-extreme silhouette
triangles for the small preview. Full STL source evidence is owned by the
generated asset bridge and `check:gait:heavy`; the live browser viewport only
reports indexed source-triangle metadata and must not parse full STL geometry
while walking. Full-detail mesh inspection should remain a separate mode so the
endless walking preview stays responsive.
The primary Rabbita scene is now `moonmoon-third-person-3d`: a combined
Three.js view where the reduced E1 mesh walks across the lunar heightfield used
by contact probes while a third-person camera follows from behind the robot.
`npm run check:gait` now stays fast for Rabbita viewport contracts, runtime
authored-sample consumption, gait phases, foot lock, terrain IK, motion
continuity, and mesh-reduction metadata. `npm run check:gait:heavy` runs the
Rabbita UI evidence freshness gate, the MoonRobo typed-contract freshness gate,
the live MoonRobo suite-evidence gate, the live suite payload command, and the
compiled Moonphys bridge over MoonRobo-authored contact and motor frames. The
next work is visual walk-cycle polish, better terrain IK, and using live
MoonRobo adapter output as the runtime data path instead of generated snapshots.

## Phase 10: Durable Suite Evidence

Only after the adapter produces stable motion evidence should MoonBook or
MoonClaw consume it.

Deliverables:

- durable simulation evidence entry
- explicit source references
- review status
- blocker and next-action records

Status: active. `src/suite_adapter_preview/noetix_suite_payload.mbt` defines
the typed durable suite evidence entry for the Rabbita/MoonRobo Noetix walk
cycle. It records robot id, platform, MoonRobo profile path, URDF path, mesh
refs, motion/hinge/review ids, driven joint ids, compiled review status,
blockers, and readiness. The MoonRobo source-side package
`../moonrobo/src/moonmoon_adapter` exposes a typed
`MoonmoonNoetixLocomotionContract` with Noetix profile, URDF, mesh, required
motion-joint, blocker, readiness, and typed walk-clip fields for MoonMoon
consumption. `../moonrobo/cmd/moonmoon_contract` exports that typed contract as
JSON. MoonMoon no longer commits the generated MoonBit table snapshot for that
contract; full MoonRobo source authority now enters through the native
`cmd/suite_preview` live JSON ingestion command. Rabbita runtime consumes the
live runtime bridge generated at
`ui/rabbita-moon/.generated/live-moonrobo-noetix-clip.js`, while the Rabbita
artifact remains a visual/browser evidence gate.
`../moonrobo/cmd/moonmoon_suite_evidence` now provides a live typed adapter
summary with sample counts, contact load counts, motor drive counts, review
counts, blockers, readiness, and regeneration mode. `npm run check:gait:heavy`
invokes `ui/rabbita-moon/check-live-moonrobo-suite.mjs`, which runs that command
and compares the live authority with the live runtime bridge and generated
MoonMoon suite-preview bridge. The MoonBit suite-preview payload now ingests the
live summary in its typed evidence entry, so stale or blocked live MoonRobo
adapter output becomes a payload blocker instead of only an external script
failure. `src/suite_adapter_preview/moonrobo_live_ingestion.mbt` now defines a
native MoonBit live-contract ingestion path that decodes the full MoonRobo
contract JSON, converts parsed contact frames into the compiled Moonphys review
shape, and builds a live suite payload from parsed joint, motion, contact, and
motor tables. `cmd/suite_preview` is the current native command path for that
ingestion: it reads live `../moonrobo/cmd/moonmoon_contract` JSON and emits the
MoonMoon suite-preview payload without using Rabbita-generated evidence.
`ui/rabbita-moon/check-live-suite-payload.mjs` gates that command path, and
`npm run check:gait:heavy` now requires it alongside the live MoonRobo suite
evidence gate and compiled Moonphys gate. Plain MoonBit tests now keep only
compact fixture coverage for live JSON parsing and compiled Moonphys review;
full MoonRobo integration coverage belongs to the native command gate.

Acceptance:

- evidence can be regenerated from typed source packages
- task orchestration consumes evidence; it does not become hidden motion logic

## Phase 11: Earthrise Observer Lighting

Status: implemented.

The third-person Earthrise scene consumes the same typed DE440/PCK11 observer
timeline as the canonical Moon globe. Local Sun and Earth altitude/azimuth map
into the scene's east/up/north frame. That geometry controls the Earth horizon
position and shader terminator, while the camera controls limb falloff. The
Earth sphere uses the approximate physical angular radius at the scene's lunar
distance scale.

The main lighting scrubber and Physical/Readable mode now update an already
opened adapter scene through explicit events. Physical mode keeps the night
side near black; Readable mode changes only presentation fill. UTC sidereal
rotation moves the texture underneath the geometry but is not lighting
authority.

Viewport metadata records the observer timestamp, sample index, frame, DE440
and PCK11 sources, Sun and Earth scene vectors, Earth altitude/azimuth, phase,
mode, and texture-rotation model.

Acceptance:

- Rabbita can display a bright readable preview mode and a physically grounded
  observer mode as separate scene states
- the real observer mode cites its ephemeris source and exposes the computed
  Sun/Earth/camera vectors in viewport metadata
- visual readability tuning does not overwrite the physical lighting contract
