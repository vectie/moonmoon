# Browser-saved study library

In **Save and compare a digital study**, choose **Find saved studies**. The
library discovers revisions retained in this browser's local storage, verifies
their exact dossier and review identities, and offers **Open** for confirmed
records. Opening restores that revision's own digital review. It does not run a
mission, adopt a different review, or grant physical authority.

The library belongs to the existing JavaScript study-panel binder. Its controls
are created inside the existing panel, as the route-map controls are. No new
MoonBit markup, generated application, dependency, or storage schema is needed.

## Recovery and uncertainty

- Save or explicitly discard current edits before opening another revision.
  Library selection never discards work on the operator's behalf.
- If another tab changes a selected record, refresh the library and inspect the
  newer entry before opening it. Selection is bound to the exact inspected bytes.
- Interrupted journals, invalid records, disappeared revisions, storage errors,
  and inspection limits are visible; discovery never repairs or deletes them.
- Use the existing **Reconcile interrupted save** action for an interrupted
  record. Its existing semantics are unchanged: it targets the active study,
  or the manually entered Study ID and Revision when no study is open. To
  reconcile a different identity, first preserve current edits and restart the
  panel before entering that identity. Discovery does not retarget reconciliation.
- Browser-local records are separate from the native host's retained-run list.
  Finding a record does not establish native replay, receiving-product
  acknowledgement, physical readiness, or browser-storage durability.

## Bounded inspection

Discovery enumerates at most 512 browser-storage keys. If the origin exceeds
that limit, exact-ID controls remain available. Only keys in the canonical
`moonmoon.study.v1/<study>/<revision>` namespace and their `/pending` journals
are inspected; unrelated values are not read. Invalid study keys are counted
and left untouched.

A second bounded, key-only inventory pass detects additions, removals, and
same-count key replacements during asynchronous validation. A changed inventory
is disclosed as incomplete and asks the operator to refresh. Each record is
parsed from the exact immutable snapshot whose size was checked; changed bytes
are never parsed as a substitute. Opening a listed revision similarly rejects
different stored bytes before decoding them.

Up to 32 distinct identities are inspected in sorted key order. A record may
consume at most 24 MiB and the whole refresh at most 32 MiB of encoded saved
record content. Omitted or oversized records are disclosed as limited, not
corrupt. These are discovery budgets; the existing exact dossier contract and
8 MiB dossier limit remain unchanged.

## Executable checks

From `ui/rabbita-moon`, run directly with installed Node:

```sh
node --test mission-study-library.test.mjs mission-study.test.mjs mission-study-map.test.mjs
```

These tests exercise the real panel binder and stored-record validation with
DOM and Storage doubles and retained native-producer fixtures. They cover
multiple revisions, restart, inert untrusted labels, malformed and empty
journals, denied storage, changed/deleted selections, async edits, repeated
mounting/clicks, read-only behavior, and bounded inspection. They do not build
the Rabbita/Vite app or establish a browser, native replay, provider, or hardware
pass.

To inspect a previous dossier beside an open revision without replacing its
review, use [cross-revision study inspection](STUDY_REVISION_COMPARISON.md).
The previous dossier is an explicit local file choice; this does not add a
storage write or change library recovery behavior.

To retain this browser's exact dossier, digital review and ordered review history
in a portable file, use [reviewed-study archives](REVIEWED_STUDY_ARCHIVES.md).
The explicit restore writes only an unused identity; discovery, recovery and
existing records remain separate. Reviewer names are unauthenticated claims.
