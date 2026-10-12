# Named sensitivity studies

The local mission authoring panel can freeze and run one reference plus two to
four named variants. Each variant changes only the existing route, available
energy assumption, commanded speed, deterministic seed, injected fault IDs, and
assumption note. The site, terrain bytes, robot artifact, calibration, mission
constraints, power assumptions, and safety gates share one frozen baseline.

## Author, reopen, and run

1. Import or reopen a study, select an exact parent session, and fork it
2. Name each variant and document its assumptions. Switching variants retains
   edits. Add or duplicate up to four variants; retain at least two
3. Export one frozen batch to reopen later, or run it through the local native
   host. Changed inputs require a new study revision
4. Inspect the actual result matrix, deltas against the reference, and blockers
   before saving a named digital review. A rejected variant does not hide the
   results of the other variants

The optional offline command remains:

```text
moon run --target native cmd/mission_study -- run-draft batch-draft.json new-workspace
moon run --target native cmd/mission_study -- inspect-draft batch-draft.json
```

The workspace must not already exist. The parent dossier and review are never
overwritten. Retry with identical bytes reconnects to the same host run; altered
inputs cannot replace an existing study/revision. Cancellation and interrupted
run reconciliation retain the existing local host behavior.

## Versioned input

`moonmoon.mission-draft-envelope.v2` contains exact `draft_json` bytes and their
SHA-256 digest. `moonmoon.mission-draft.v2` replaces the v1 `edits` field with
`variants`, an array of `{variant_id, name, edits}`. All other shared draft fields
retain their v1 meaning. V1 two-alternative drafts still import and execute with
their original reference/alternative session IDs.

Variant IDs are unique ASCII letters, digits, underscores or hyphens, 1–64
characters, excluding `reference`. Display names contain 1–120 UTF-16 code
units and must not be blank. Existing edit validation and the 16 MiB draft
envelope limit remain in force. The study retains its v1 contract, maximum 64
sources, 1 MiB per source and 4 MiB total source bytes. No count or byte limit is
relaxed for sensitivity studies.

Sessions are ordered reference first, then variants in draft order. Identity is
`authored-<first 16 digest hex characters>-<reference or variant_id>`, where the
digest is over the exact outer draft bytes. The host checks the complete ordered
session list and every frozen design input against the accepted draft, then
performs the native replay inspection. Names and notes are retained as bounded
`Authored variant: { ... }` metadata in dossier limitations.

## Interpretation and limits

- The batch creates one common reference adapter session. Each session still
  performs the required deterministic replays and integrity checks. No speedup
  or wall-clock performance improvement is claimed
- The matrix reports native simulation results and arithmetic deltas, without
  an overall score or automatic ranking. Energy changes are author assumptions,
  not new terrain measurements. Prepared numeric criteria are not independent
  measured validation
- Unsupported fault models and routes fail closed with actual native blockers
- Adopting another robot applies it to the reference and every variant. All
  inherited calibration qualification and fault models are cleared. Comparison
  to the previous robot is unsupported; inherited mission power assumptions
  still need review
- All results require digital review and have no physical dispatch authority.
  Dataset qualification, optional E1 assets, MoonFlow delivery, and MoonRobo
  acknowledgement retain their existing limitations

## Regression entry points

`moon test src/mission_adapter --target native --frozen --strip -j 1` covers v1,
three/five-alternative native batches, deterministic export bytes, independent
variant failures, bounds, immutable parents, and all-variant robot reset.

`npm run test:study`, `npm run test:run`, and `npm run test:storage` run the browser
controller/host regressions. Set `MOONMOON_NATIVE_CLI` to the compiled local
`mission_study.exe` and `MOONMOON_BUILD_DIST` to the normal production `dist`
directory to enable real native and shipped-asset integration coverage.

To ask which existing alternatives meet several explicit review limits at once,
use [alternative review screening](ALTERNATIVE_REVIEW_SCREENING.md). It evaluates
the retained matrix without rerunning or approving any mission.
