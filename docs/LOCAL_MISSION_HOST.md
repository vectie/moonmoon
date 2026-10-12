# Run digital missions inside MoonMoon

## One-time build and local launch

Use a trusted matching MoonMoon source checkout, its pinned dependencies, Node
20.19+ and the matching MoonBit compiler. From the repository root build the
native runner once:

```sh
moon build --frozen --target native --release --strip -j 1 cmd/mission_study
```

In `ui/rabbita-moon`, install the existing locked npm dependencies and build the
UI using its existing build workflow. Then start the product host:

```sh
npm run build
npm run start:local
```

The existing full viewer build also requires the matching MoonRobo source and
dependencies as the sibling `../moonrobo` repository. Its prebuild regenerates
the existing Noetix typed clip/evidence; this requirement predates the mission
host. A previously built matching `dist` can instead be supplied through
`MOONMOON_UI_DIST`. R11 recovered that canonical sibling layout and verified
the full production asset build, compiled MoonBit rendering, HTTP asset serving
and real UI-controller/native run journey. Live browser acceptance is separate.

Open the exact `http://127.0.0.1:8766` address printed by the host. Keep that
terminal open. This is a foreground application host, not an installed service.
Ordinary Vite `dev`/`preview` and `file://` do not provide the run API. No Mac
installation, system service, reverse proxy, public listener or credentials are
part of this feature.

Defaults locate the native release executable at
`_build/native/release/build/cmd/mission_study/mission_study.exe`, built UI at
`ui/rabbita-moon/dist`, and private run storage at `output/ui-mission-runs`.
An operator may set `MOONMOON_NATIVE_CLI`, `MOONMOON_UI_DIST`,
`MOONMOON_RUN_ROOT`, or `MOONMOON_PORT` at launch. These are local trusted-host
settings, not browser inputs. There is deliberately no host/bind-address option:
the listener always binds `127.0.0.1`. Use the exact printed address, not
`localhost`, another hostname, or a proxy. The host does not request, inherit
provider credentials into the child environment, or grant hardware authority.

## Repeated operator workflow

1. Import/reopen and save a completed study in **Save and compare a digital study**
2. Fork an exact session, choose a new study/revision, edit supported inputs and
   explain assumptions; optionally adopt the existing Robo robot-input package
3. Choose **Run digital mission**. Exact input bytes are retained before the
   request is acknowledged. Duplicate identical requests reuse the same run
4. Read real phases: queued, starting, running, verifying, then completed,
   failed or cancelled. “Running” requires an observed native process spawn;
   no percentage or predicted completion time is invented. A rejected digital
   mission can be a successfully completed calculation
5. The host invokes fixed `mission_study run-draft`, then fixed `inspect` on
   its actual output. It verifies exact frozen-input/session binding, dossier
   identity and byte digest before exposing a completed result
6. The UI automatically imports that dossier if the view and review edits are
   still unchanged. Otherwise the completed output stays retained, and **Open
   completed result** is an explicit safe next step. Review inputs are never
   silently overwritten
7. Inspect the actual comparison, save a new digital review, and continue the
   existing **Send a digital outcome to Book** authoring. Book intake/receipt
   return remain explicit file handoffs and independent review decisions

Changing the same study/revision's frozen bytes is refused. Use a new revision
for edits or a new attempt after a failed/cancelled run. A prior study and its
review/history are unchanged. If this exact child result already has its own
saved digital review, reopening it retains that review rather than a parent's.

## Cancel, reload and interrupted runs

**Cancel native run** cancels queued work or asks the owned native process to
stop with SIGTERM, then SIGKILL after two seconds if needed. The UI displays
cancelling until actual process exit. Completed results win a late cancellation
race; cancelled outputs are never auto-imported. Files already written are
retained, not deleted or relabeled as successful evidence.

Leaving the page does not cancel the host's simulation. After reload, the last
run ID is remembered when browser storage works. Reconnect/list reads actual
host state; completed results are opened explicitly after reload. If the
submission reply is lost, the browser already knows the exact content-derived
run ID and can reconnect without sending another run. Clearing browser storage
does not delete host evidence; use **List retained runs**.

A stopped/restarted host labels nonterminal records interrupted. **Reconcile
interrupted output** independently inspects any complete retained dossier
without rerunning simulation. Recovered results explicitly state that the
original process exit was not observed. Missing/partial/invalid output remains
unconfirmed. A disconnected UI never claims the process stopped or completed.

Only one host may write a storage root. A hard host crash can leave `host.lock`
and potentially an orphan native process. Startup refuses the stale lock rather
than guessing or killing a reused PID. Stop any old native process, retain its
files, and explicitly remove that lock before restarting. Never remove the lock
while another host/process is using the directory. This exceptional recovery
step is not required between ordinary UI runs or graceful restarts.

## Storage and scope

Each content-derived run directory contains exact `draft.json`, readback state,
the native output workspace, and a final receipt binding accepted draft digest,
exact envelope digest, parent digest and returned dossier/bytes digests. A
recovered receipt does not pretend to have witnessed the original process exit.
Host writes are serialized and atomically renamed; this is local filesystem
retention, not an fsync-backed power-loss guarantee or signed attestation.

The host retains at most 32 distinct runs per storage root and executes one
simulation at a time. It never silently deletes evidence. Keep/archive completed
roots yourself and select a new private root when needed. Frozen inputs are
limited to the existing 16 MiB envelope and results to the existing 8 MiB bound.
The storage root must remain private and operator-controlled; this is not a
multi-user, authenticated network service. Arbitrary executables, shell text,
URLs and output paths cannot be supplied through the API. Host/origin and custom
request-header checks reject browser cross-origin requests; no CORS access is
granted.

All physics and replay remain in the existing native simulator/adapter. New
robot adoption still reruns the reference and edited mission, clears inherited
calibration qualification, and retains explicit power assumptions. Physical
execution stays false. Verification covers source, real native simulation,
compiled rendering and production-controller/HTTP fixtures; it does not claim
live browser, installed-app, actual human Book authority, physical or external
dataset qualification.
