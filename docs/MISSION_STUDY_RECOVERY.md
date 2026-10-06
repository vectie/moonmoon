# Local digital mission studies

This path builds a self-contained dossier from **existing, complete MoonFlow
adapter mission sessions**. It does not run a device, contact a provider, fetch
external references, replace missing E1 assets, or acknowledge delivery to Robo.

## Create and reopen

Use the native MoonBit target from the MoonMoon module root:

```sh
moon run cmd/mission_study --target native -- create WORKSPACE STUDY REVISION none SITE.json SESSION_A SESSION_B
moon run cmd/mission_study --target native -- inspect WORKSPACE/.moonsuite/products/moonmoon/mission-studies/STUDY/REVISION/dossier.json
moon run cmd/mission_study --target native -- export-result DOSSIER.json SESSION_B NEW_RESULT.json
```

SITE.json has site_id, revision, frame, distance_unit, elevation_unit, coverage
and uncertainty strings. Both units must be `m`. IDs use 1–100 ASCII letters,
digits, hyphens or underscores. Use a prior dossier's SHA-256 digest instead of
`none` to declare a revision's parent. The parent is a declared link, not a claim
that another host has verified or accepted that revision.

The command freezes original source bytes plus result, replay, provenance and
evaluation records from `.moonsuite/products/moonmoon/mission-sessions`. Each
source's bytes and SHA-256 are retained. It checks robot profile, URDF and
validation digests, the simulation-only bridge, session identity, provenance,
replay identity and a fresh deterministic simulation of the frozen inputs.
Changed live inputs are rejected when creating a study from an old session.
Reopening an already frozen study reads no live source and recomputes its results.

The common comparison baseline includes site metadata, terrain digest, robot
artifact binding, calibration, cell size and whole-grid status/grade. A mismatch
refuses comparison. Route, energy and other assumptions remain in each exact
design; rejected routes, negative energy and missing source cells remain in the
result. No combined score or physical readiness is inferred.

## Browser workflow

Open **Save and compare a digital study** in the operator's decision rail.
Choose the local dossier file, inspect the alternatives, optionally enter a
digital reviewer name, a session ID (or `none`), and a reason. Save the study,
then reopen by its study ID and revision. A fresh page can reopen the same
browser-origin record. A changed revision starts with review required; prior
revision records remain intact. Updating a saved review retains the previous
review in that record's reviewHistory.

Import never fetches paths, URLs or calibration references. It checks embedded
source hashes and identity bindings; the browser does **not** rerun scientific
calculations. Use the native `inspect` command for an independent recomputation.
Neither the envelope digest nor a reviewer name is a cryptographic signature or
proof of external data quality.

Save/reopen/import refuse to replace a dirty draft. The explicit **Discard edits
and reopen saved revision** action only discards edits after the saved revision
has been successfully read and validated. The displayed import does not replace
the surrounding trusted-square mission selection or its blockers.

Select an exact session ID and **Export exact digital result** after saving.
The download is the exact frozen `moonmoon.robot-mission-result.v1` text, without
reserialization. Keep its dossier alongside it for source/replay lineage.
Export is a manual artifact, not a trial request. MoonFlow delivery, stable
receiver acknowledgement and Robo hardware/calibration admission remain separate
unqualified integration work.

## Interrupted persistence

Native saves use immutable study/revision paths with a digest intent before the
write. A repeat with exactly the same bytes can confirm or finish a missing
write; a different replacement is rejected. An existing truncated or divergent
file is preserved for investigation rather than overwritten. Existing confirmed
revisions remain usable. The CLI has no power-loss/fsync or concurrent-writer
qualification; use one native writer for a revision.

The browser journals previous and proposed serialized records, reads the journal
and record back, and marks confirmation only after journal cleanup. A denied
read, quota error, lost acknowledgement, or cleanup failure keeps the draft.
Use **Reconcile interrupted save**: exact proposed bytes confirm the save; exact
previous bytes prove it was not applied; any other bytes stay unresolved. Reopen
confirmed bytes after reconciliation. Stale observed records are refused before
writing and checked again after asynchronous digest preparation. This is a
bounded same-origin localStorage path; it is not a distributed transaction or
cross-process concurrency guarantee.

Limits are 2–8 alternatives, 64 text sources, 1 MiB per source, 4 MiB total frozen
source text and 8 MiB serialized envelope. Files are read before the native size
check; this is not an adversarial streaming-ingestion boundary. Browser quota
can be smaller than these bounds and includes journal overhead. Keep the native
dossier file as the portable recovery artifact.

## Local acceptance fixture and remaining gates

`ui/rabbita-moon/fixtures/mission-study-local.json` comes from the native adapter
regression. It is an explicitly inert, uncalibrated local test grid, not E1,
external lunar data, an actual robot trial or a customer-approved recommendation.
One alternative retains negative energy and an absent terrain cell.
`mission-study-revised.json` retains the same baseline, changes the declared
available-energy assumption in a new actual adapter session, and links the prior
dossier digest. Browser tests import this revision and reopen digital review.

No listeners, external providers, hardware, credentials, deployment or remote
fetch are needed for these tests. The repository's E1 asset preparer emits its
standard `ready: false` unavailable module when the optional archive is absent;
that build output contains no assembly meshes. Live browser/assistive-technology
qualification, real Robo receipt acknowledgement, signed clean-machine
distribution, external dataset rights/quality, and physical safety evidence are
still release gates.
