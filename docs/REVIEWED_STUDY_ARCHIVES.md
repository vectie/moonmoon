# Move a reviewed study to another browser

A completed study's review and review history previously remained in one
browser's storage. The selected-result export retained one simulation result;
the Book outcome handoff served a different receiving-product contract. Neither
could restore the complete browser-reviewed study in another browser.

In **Save and compare a digital study**, use **Move a reviewed study between
browsers** to carry the exact dossier, current named digital review (if any),
and ordered earlier reviews together. This is a file-based input/output workflow
for MN-W05, MOONMOON-B09, R01 and N01. It preserves context and scientific source
identities; it does not complete the broader native restart/replay release gate
or change the PRD's qualification statuses.

## Export, inspect, restore, reopen

1. Import or reopen a study in the existing panel. Save and confirm any review
   edits. Resolve any interrupted save before exporting.
2. Choose **Download saved reviewed-study archive**. The panel rereads and
   verifies the exact saved record and checks it has not changed. The filename
   is `STUDY-REVISION-reviewed-study.json`. It does not export unfinished edits.
3. Keep that JSON file and move it yourself to the intended browser. It includes
   every frozen source and private reviewer names, reasons and history. It is
   plaintext, unencrypted and unsigned. No upload or automatic sharing occurs.
   Preparing a download does not confirm that your browser saved the file.
4. In a fresh browser, choose that file under **Local reviewed-study archive
   JSON**. This only stages a preview; it writes nothing. Inspect the exact
   study/revision, archive/record/dossier digests, source frame and coverage,
   review claims, earlier history, result decisions and negative-energy blockers.
5. Choose **Restore reviewed archive into unused slot**. Save or explicitly
   discard any current review edits first. Restore writes only when both the
   target record and its pending journal are absent. Even identical existing
   records are refused. It never renames, merges or overwrites another revision.
6. After readback confirmation, choose **Find saved studies**, then **Open** for
   the restored identity. This uses the existing library and exact-revision
   reader. The current open study is never replaced by the restore itself.

Reopening through a new panel instance restores the original review and history.
Subsequent normal review saves append to that history. Exporting an unchanged
restored record produces the same archive bytes in this implementation. A study
without a current review stays unreviewed. Neither restoration nor possession of
an archive approves a recommendation or establishes the named reviewer's identity.
Both the preview and the open study explicitly label names as unauthenticated
digital claims, whether locally entered or imported.

## Archive contract and identity

`moonmoon.reviewed-study-archive.v1` contains:

- `authority: "digital-only"`, `physical_readiness: false`, and
  `reviewer_identity: "unverified"`
- exact `study_id`, `revision`, and `dossier_digest`
- `record_text`: the exact JSON string already saved by `StudyStore`, including
  the original dossier envelope string, current review and ordered review history
- `record_digest`: SHA-256 of the UTF-8 `record_text`

The reader rechecks the record digest, existing dossier/source/receipt contracts,
all current and historical review bindings and the outer identity. The exact
original record bytes are written under the same existing
`moonmoon.study.v1/STUDY/REVISION` key. No new persistence schema, origin identity,
review timestamp, authenticated signature or transfer-receipt claim is invented.
The preview's archive digest hashes the exact supplied UTF-8 file text, including
outer formatting; keep that original file if the transfer-byte identity matters.
Reformatting outer JSON is supported while retained record bytes must still match
their digest. A digest is an integrity reference, not provenance authentication.

The maximum archive is 32 MiB in UTF-8 and its inner record is at most 24 MiB.
The existing dossier's 8 MiB bound and source limits still apply. Escaping nested
JSON can reach the archive limit before the record limit; the exporter refuses
such a file and leaves the source untouched. No compression, selective history
truncation, attachment substitution or invented source is performed.

## Interrupted writes and conflicts

Restore uses the existing readback-confirmed journal format, with `previous`
set to null because the slot must be unused. Validation occurs before writes.
Repeated clicks cannot start concurrent restores from this panel, and the slot
is checked again after asynchronous preparation. Browser storage still has no
cross-tab compare-and-swap transaction; this feature does not introduce a
cross-tab lock or claim stronger durability than the existing save flow.

If persistence fails, keep the archive and any retained journal. Do not assume
that an error means no bytes were written. Use **Reconcile interrupted save** for
that exact study/revision. When a different study is open, preserve its work and
reload the panel first, then enter the archive's Study ID and Revision and choose
Reconcile. The existing reconciliation targets the open study when one exists.
A confirmed record can then be reopened; if the write was not applied, explicitly
stage and restore the original archive again. Discovery never repairs a journal.

A changed or occupied target is refused without replacing its bytes. There is no
merge or conflict-resolution UI. Preserve both browser records/files and inspect
them separately. The file preview can be cleared; a newer file selection or Clear
invalidates an older in-flight read. Restore does not erase the source file,
create an execution request or alter the current study's inputs or review.

## Focused verification and limits

From the repository root, using the already available Node runtime:

```sh
node --test ui/rabbita-moon/mission-study-archive.test.mjs ui/rabbita-moon/mission-study.test.mjs ui/rabbita-moon/mission-study-library.test.mjs
```

The focused tests use production codec, storage and panel handlers, retained
native-produced dossier fixtures, real SHA-256 and Blob bytes, and DOM/Storage
doubles. They exercise the completed export-to-fresh-storage-to-library-open
journey, null and named reviews, ordered history, collision refusal, edits during
export, stale file reads and interrupted-write reconciliation.

No graphical browser, real browser download/storage durability, native rebuild
or scientific replay, compiled Rabbita/Vite build, provider, external dataset,
Mac installation, MoonFlow delivery, Book receipt, robot hardware or physical
readiness is qualified by these tests. Frozen negative-energy rejection and
missing coverage remain unchanged. This is useful manual context transfer,
not a signed review system, cloud backup service or live evidence bridge.
