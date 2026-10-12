# Frozen mission authoring

The study panel can fork a mission from a completed local study, edit supported
inputs, run an exact proposal through the loopback-only local host, and
automatically open the real native results. Offline export remains available.
The original dossier and its browser review are preserved. Every new dossier
requires its own review.

## User journey

1. Open **Save and compare a digital study** in the Rabbita Moon UI. Import a
   completed dossier and save it, with an optional digital review.
2. Open **Fork and edit a mission alternative**, enter an exact parent session
   shown in the comparison, and select **Fork mission inputs**.
3. Choose a new study/revision identity. Edit route row/column cells, assumed
   available energy in Wh, speed in m/s, positive deterministic seed and fault
   IDs. Describe changed assumptions and unresolved limits.
4. Optionally import a MoonRobo `moonrobo.simulation-input-envelope.v1` file.
   It supplies exact robot artifacts and the accepted digital integration
   receipt, not terrain, mission power physics, or simulation results.
5. Select **Run digital mission** in the UI served by the supported local host.
   It retains exact inputs, starts the real native runner, displays observed
   process phases, and independently replays the returned dossier. **Cancel
   native run** waits for the process to stop and retains partial evidence.
6. The completed result opens automatically in comparison when the view and
   edits still match the submitted draft. Otherwise use **Open completed result**
   after saving or discarding current review edits. A new named digital review
   is required before authoring a Book outcome; no parent review is inherited.
7. After reload use **Retained runs and reconnect**. The last run identity is
   remembered when browser storage is available; **List retained runs** also
   reads the host. Reopen exact inputs, or explicitly open completed evidence.
   Interrupted work never restarts automatically. See [local host setup and
   recovery](LOCAL_MISSION_HOST.md).

### Optional offline export

**Export frozen runnable inputs** remains available for a portable draft. Drafts
that have neither been submitted nor exported remain page-local. The existing
offline command still works from the MoonMoon source checkout:

   ```sh
   moon run --target native cmd/mission_study -- run-draft "local-study-r1-draft-draft.json" "./local-study-r1-draft-run"
   ```

   Use a new output directory. The CLI refuses any existing output workspace
   rather than overwriting or silently resuming a partial run.
Import the dossier path printed by the native command into **Local dossier
   JSON** above. Compare the two actual runs, inspect blockers, and save a new
   digital review. The old review never becomes approval for the new inputs.

`mission_study inspect-draft <draft.json>` checks a proposal without executing
it. `mission_study inspect <dossier.json>` independently replays exact frozen
results. The CLI can also be built once with `moon build --target native --strip
cmd/mission_study` and invoked directly.

## Scope and scientific meaning

- All calculations use the existing native `robot_mission.simulate` and
  `mission_adapter` replay/provenance/evaluation pipeline. Browser JavaScript
  validates and edits inputs; it performs no physics and produces no results.
- A proposal retains the source terrain, site, safety policy, mission power
  subsystem and constraints. Route cells absent from terrain, disconnected
  cells, speed/route constraints, unknown faults and insufficient energy still
  fail closed. Changing route length does not widen the inherited route limit.
- Numeric expected criteria are prepared from the native simulator before
  the actual adapter run. These computed expectations are not independent
  validation measurements. Calibration and source truth are not created by
  editing a number. The assumption note is included in the resulting dossier.
- When a robot package is adopted, both reference and edited missions are
  rerun on its exact artifact binding. The prior robot's result is incomparable.
  Prior calibration qualification and fault models are cleared. The inherited
  mission power model remains an explicit assumption; the native simulator
  does not infer a new energy model from URDF mass, geometry or actuators.
- Only compatible site/terrain/robot/calibration baselines compare. Negative
  energy margin remains a rejection, and unsupported fault models return
  fail-closed evidence. Nothing grants physical readiness or device authority.
- Source hashes establish byte identity, not trusted publisher authentication
  or external dataset qualification. Synthetic fixtures remain synthetic.
- The deterministic authoring runner labels receipt time `local-frozen-draft`;
  it does not assert a wall-clock execution time or external attestation.

## Current boundary

The supported host serves the built Vite/Rabbita UI and same-origin simulation
API on `127.0.0.1` only. Static-only Vite/preview use does not supply that API.
One local host launch is setup; repeated runs need no manual export, CLI command
or reimport. No live provider, telemetry source, physical transport, external
delivery or E1 assembly is introduced. No live browser or Mac validation is
claimed. Book handoff remains the existing explicit file export/import.

## Verification

`npm run test:study` checks study persistence and input-authoring behavior.
`moon test --target native --strip -j 1 src/mission_adapter src/robot_mission`
checks the native adapters and simulator. Native tests consume the actual
MoonRobo-produced robot envelope checked into the fixtures directory.

Set `MOONMOON_NATIVE_CLI` to the built `mission_study.exe` while running the JS
tests to additionally exercise the browser-export → actual native CLI → UI
reimport journey. Without it, that one integration check is explicitly skipped.
`MOONMOON_JOURNEY_DIR` optionally records the frozen input, actual returned
dossier and result receipt for review.

`npm run test:run` checks the production host, actual process cancellation,
same-origin transport, durable reconnect and production UI controller. With
`MOONMOON_NATIVE_CLI` it additionally crosses the actual UI handlers → host →
native simulation and replay → comparison/review → Book outcome authoring.
`MOONMOON_RUN_JOURNEY_DIR` retains those actual returned artifacts.

The four mission draft/result fixtures were generated by the native authoring
tests. `moonrobo-simulation-input.json` was copied byte-for-byte from MoonRobo's
real `design_workbench` producer, `excavation-haul/r1`; it was not independently
handwritten by this consumer.
