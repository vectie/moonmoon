# Screen mission alternatives against review criteria

A reviewer can now ask which alternatives in one frozen study meet a combination
of their own duration, measured-slope and retained-energy-margin limits. The
existing sensitivity matrix shows values and deltas; this screen explains each
criterion and retains excluded alternatives so a reviewer can explain why no
candidate fits. It extends PRD MN-W05 / MOONMOON-R01 and its decision to specify
route/energy review criteria, without changing native simulation or approval.

## Use the existing study panel

1. In **Save and compare a digital study**, import a native-produced dossier or
   reopen one from the saved-study library. The usual dossier reader checks its
   exact source, baseline and receipt identities before it becomes available.
2. In **Screen alternatives against review criteria**, enter any combination of:
   - Minimum retained energy margin, in Wh
   - Maximum retained duration, in seconds
   - Maximum measured segment slope, in degrees
   - Require declared whole-grid verification
   - Require declared available dataset evidence
3. Optionally explain why these criteria matter. Choose **Apply review criteria**.
   Every alternative remains in original dossier order. Inspect the observed
   values, requested limits, criterion status, retained native decision, blockers
   and uncertainty. The screen never sets the study's review-choice control.
4. Tighten or relax your criteria and apply again. Editing a field clears the
   previous screening and disables its download, so an old result cannot appear
   to use new limits. **Clear screening** removes all page-local criteria/results.
5. Choose **Download screening report** to retain the explanation. Keep its
   exact original dossier separately. To resume later, open that same dossier,
   then choose the report under **Reopen screening report for this dossier**.
   The report reader verifies its digest and recomputes every row before
   restoring the criteria. A different revision needs a fresh screening.
6. Use the existing named digital-review controls separately if you want to
   record a recommendation. Screening does not save, change or inherit a review.

Unsaved review edits can stay open during screening and report import/export.
No browser-storage write, mission execution, source mutation or external request
is made by this feature. Refresh loses the page-local criteria unless you retain
its report. Saving or reopening the same exact dossier keeps the current screen;
opening another dossier clears it. A failed report import preserves the existing
screen. Clear, changed criteria, a new file choice or a changed current dossier
supersedes any unfinished report read/export.

## Try the retained native-producer example

Import `ui/rabbita-moon/fixtures/mission-study-local.json`. Enter minimum margin
`100`, maximum duration `600`, maximum measured slope `15`; leave both coverage
requirements unchecked. Apply:

- `q11-a` matches these review criteria: retained duration 600 s, maximum measured
  slope about 13.173 degrees, energy margin about 3373.925 Wh. Its native result
  is accepted only within its bounded digital model. Route coverage remains
  `enumerated-path-only` and dataset coverage `conditional-not-declared`.
- `q11-b` stays excluded. Its retained energy margin is about -622.333 Wh, native
  decision is rejected, and its missing path cell and other blockers stay visible.

Set maximum duration to `599` and apply: both alternatives are excluded. Restore
`600` and require declared available dataset evidence: `q11-a` becomes
`needs-evidence`, while `q11-b` stays excluded. No missing dataset is fabricated.
The examples use checked-in synthetic native-producer evidence; this workflow
does not run the native simulator again or qualify a lunar dataset.

## Exact screening semantics

- Numeric limits are optional. Blank means unselected, never zero. Explicit zero
  is a selected limit. At least one numeric or coverage criterion is required.
- Numeric values must be finite/nonnegative; slope must be at most 90 degrees.
  The UI accepts nonnegative decimal/scientific notation (at most 64 characters),
  rejects overflow and nonzero values that underflow to zero, and uses JavaScript
  numbers. The optional note is at most 2000 UTF-16 code units.
- Comparisons are inclusive: energy margin >= minimum, duration <= maximum,
  measured segment slope <= maximum. No rounding is used for comparison; the
  full retained values are displayed/exported. This does not calculate energy
  use, infer a battery reserve, resimulate a speed change or estimate any hazard.
- A numeric observation absent/nonfinite at the screening API is `unknown`, not
  zero. Normal dossier imports retain the existing reader's numeric validation;
  this does not add a new incomplete-dossier import format.
- Grid requirement passes only for retained route coverage
  `enumerated-path-with-declared-grid-verification`. Dataset requirement passes
  only for retained `declared-available`. Other/missing declarations are
  `unknown`. These labels remain declarations, not external authentication.
- `not-selected` is not a pass. Unselected coverage still appears in every row.
- A retained decision other than `accepted`, any native blocker, any negative
  retained energy margin, or any failing selected criterion yields `excluded`.
  Otherwise, an unknown selected criterion yields `needs-evidence`; otherwise
  the row `matches-review-criteria`. All individual checks and coverage remain
  visible even when the overall status is excluded.
- There is no weighted score, ranking, automatic selection, acceptance, physics
  change, safety certification or physical authority. These are reviewer-defined
  limits, not calibrated mission constraints. All native and dossier limitations
  remain expanded next to the screening. Slope does not cover obstacle, slip,
  sinkage or other unmodeled hazards.

## Portable report

`STUDY-REVISION-screening.json` is a UTF-8 JSON download, up to 2 MiB. The outer
`moonmoon.alternative-screen-envelope.v1` contains exact `report_json` text and
its SHA-256 `report_digest`. The inner `moonmoon.alternative-screen.v1` records:

- Study/revision, dossier digest, common baseline digest and declared site/frame
- Normalized explicit criteria, optional note and all alternatives in source order
- Per-criterion observed values, units, thresholds/required labels and status
- Retained decisions, blockers, uncertainty and limitations
- Exact design/result/provenance/replay/evaluation paths and source digests
- Status counts, digital-only authority, review required and no selection performed

Export revalidates the original dossier. Reopening checks the outer digest,
requires the exact current dossier identity, and compares the entire inner
report with a fresh computation. Even a rehashed edited result is refused.
Unchanged inputs/criteria produce identical report bytes in this implementation.

Hashes identify bytes, not the author or scientific truth. The report does not
embed source contents, original dossier or named review history. It is plaintext
and may include your private note and retained source labels; inspect it before
sharing. Download preparation does not confirm the browser saved a file. This
is local context retention, not cloud backup or a cross-product receipt.

## Focused executable verification

From the repository root, with the available Node runtime and no installation:

```sh
node --test ui/rabbita-moon/mission-study-screen.test.mjs
```

From `ui/rabbita-moon`, `npm run test:study` includes this new workflow and the
adjacent study, authoring, route-map, library, cross-revision and archive tests.
The optional real-native integration test stays skipped without its explicitly
configured native executable; a skipped test is not native qualification.

The focused tests use the production dossier reader, screening/report code and
study-panel event handlers, real SHA-256 and Blob bytes, retained producer
fixtures and DOM/Storage doubles. They exercise combination criteria, no-match
explanation, missing-coverage requirements, download-to-fresh-panel reopening,
continued review edits, revision changes and interrupted file/async export flows.
They do not qualify the graphical browser, compiled Rabbita/Vite application,
actual browser download/storage durability, native simulation/replay, provider,
MoonFlow/MoonRobo bridge, external data, Mac installation or physical hardware.
R50 remains the last fully verified cumulative release; R51–55 are separate.
