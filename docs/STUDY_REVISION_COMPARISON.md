# Compare a previous frozen dossier with the current study

The existing **Save and compare a digital study** panel now includes
**Inspect changes from a previous dossier**. It helps a mission reviewer explain
what changed between a prior recommendation's inputs and a revised digital
study before writing the new revision's own review.

This is the cross-revision inspection step of PRD **MN-W05 / MOONMOON-R01**.
The existing sensitivity matrix compares alternatives inside one dossier; the
saved-study library opens a revision. Neither previously showed the old and new
mission inputs and retained results together without replacing the open study.

## Operator workflow

1. Import a native-produced current dossier through **Local dossier JSON**, or
   reopen it from the saved-study library or exact-ID controls.
2. Under **Inspect changes from a previous dossier**, choose a prior dossier
   JSON file from the native study output. This is the frozen
   `moonmoon.mission-study-envelope.v1` file, not a draft, browser-storage record
   or MoonBook outcome. The limit is the existing 8 MiB dossier contract.
3. Explicitly choose **Previous session** and **Current session**. IDs, names,
   ordering and route labels are never used to guess a correspondence. For the
   retained native-producer fixtures, open `mission-study-revised.json`, select
   `mission-study-local.json` as previous, and pair `q11-b` with `q11-c`.
4. Inspect the exact study/dossier identities, retained decisions, energy and
   coverage blockers, and expanded result/uncertainty limits. Expand the changed
   common-baseline fields, supporting-source identities and mission input
   sections to inspect the complete previous/current values. Exact design,
   result, provenance, replay and evaluation paths and digests are available.
5. When inputs permit comparison, metric deltas are **current minus previous**.
   The fixture pair has a +1 Wh energy-margin change; both margins remain
   negative and both retained decisions remain rejected. No recommendation is
   selected and no prior review is adopted. Write and save the current
   revision's named digital review using the existing controls.
6. **Clear comparison** removes the page-local previous snapshot. Opening a
   different current dossier also clears the comparison and both session
   selections. Save/reopen of the same exact dossier does not invalidate it.

Comparison can be used while the current review is unsaved: it never replaces
that review or changes stored evidence. Invalid, oversized or digest-mismatched
previous files preserve the existing comparison. Clear, a newer file choice,
or a newly opened current dossier supersedes an unfinished previous-file read.
Refreshing the page loses comparison state; the existing study save/recovery
workflow is unchanged.

## What makes two sessions comparable here

Both dossiers first pass the existing `readStudy` integrity/contract reader.
The comparison then requires:

- Equal parsed common baseline: declared site metadata, terrain digest, exact
  robot artifact binding, calibration metadata, cell size and whole-grid state.
- Equal supporting-source path/digest inventories. Only the dossiers' enumerated
  per-session design, result, provenance, replay, evaluation and replay-result
  artifacts are excluded, because they are the run products being inspected.
  Terrain, robot files, bridge configuration, calibration evidence, dataset
  evidence and any other supporting files remain in the identity gate.
- No conflicting dossier digests under the same study/revision identity.

This gate is conservative: even a supporting-file path rename or an added
supporting note makes the pair incomparable. It does not infer equivalence of
renamed datasets, source authenticity or semantic equivalence of source bytes.
Changed input sections are the full top-level frozen design sections, including
scenario, mission, environment, subsystems, constraints and verification
criteria. Arrays retain order; object key order does not imply a change.

An incomparable pair still shows the two retained observations and exact input
changes, but no numeric deltas. A nonfinite arithmetic difference is also shown
as unavailable. A direct-parent relationship is reported only when the current
dossier explicitly names the previous dossier's exact digest. Different IDs or
revision strings alone establish no lineage or chronology.

## Scope and qualification

This is a JavaScript module wired into the existing production study-panel
binder. It needs no new MoonBit markup, service, storage schema or dependency.
It reads one locally chosen previous dossier and the already-open current study.
It does not run simulation, fetch terrain, execute a provider, create or update
reviews, save evidence, export a new receipt, or call a physical device.

Metric subtraction is presentation arithmetic over retained native results,
not a new physics calculation, scientific replay, feasibility check or ranking.
Coverage, result limitations and negative-energy blockers remain visible. Prior
source hashes establish integrity, not external dataset truth. Changed evidence
still needs a new reviewed revision. MoonFlow acknowledgement, MoonRobo physical
readiness, optional E1 availability and signed distribution remain separate.

## Executable verification

From the repository root, with installed Node and no package installation:

```sh
node --test ui/rabbita-moon/mission-study-revision.test.mjs ui/rabbita-moon/mission-study.test.mjs ui/rabbita-moon/mission-study-library.test.mjs ui/rabbita-moon/mission-study-map.test.mjs ui/rabbita-moon/mission-authoring.test.mjs ui/rabbita-moon/mission-outcome.test.mjs ui/rabbita-moon/mission-draft-map.test.mjs
```

`npm run test:study` from `ui/rabbita-moon` also includes this module and the
saved-library regressions. The focused tests import actual modules, verify
retained native-producer fixture envelopes, and drive the real panel handlers
with DOM/Storage doubles. They do not launch a browser, build Rabbita/Vite,
compile MoonBit, replay native results, or qualify hardware or full-product
execution. The optional existing native-authoring journey remains skipped when
`MOONMOON_NATIVE_CLI` is not supplied. No new native fixture is represented as an
actual scientific run.
