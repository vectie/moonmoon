# Compare an exact path across terrain revisions

A terrain analyst can now see which submitted point occurrences changed after a
source revision, which incident segments cross the chosen grade cap, and where
coverage was gained or lost. This compares terrain effects on an unchanged path;
it does not optimize either path or rank missions.

After building `cmd/terrain_import`, use the native executable:

```sh
terrain_import compare-path REFERENCE/terrain-import.json CANDIDATE/terrain-import.json path-cells.txt NEW_COMPARISON 20 2
```

The last arguments are the absolute grade cap in degrees and the nonnegative
uphill cost weight. The path is the existing row,col format: optional header,
1–4096 occurrences, repeated cells or cardinal-neighbor steps only. Existing
`route` and `assess-path` path exports work directly. The public MoonBit API is
`compare_path_bundle(reference, candidate, path, max_grade_deg, uphill_weight)`.
Both sources are independently reopened and verified, including any revision
history. No caller-supplied cached assessment is trusted.

## Alignment and interpretation

Both sources must declare the same coordinate-frame string, metre units, grid
dimensions, spacing and first cell center. This identifies the same complete
regular grid; corner/center declarations describing exactly the same cells work.
No floating-point tolerance, reprojection, resampling or geographic equivalence
is inferred. An incompatible grid or frame rejects before creating outputs.
Matching declarations do not establish dataset truth or revision ancestry.

All deltas are candidate minus reference. Each original occurrence remains in
order, including stationary repetitions and return visits. Elevation deltas exist
only for known/known pairs; signed incident-grade deltas exist only where both
assessments have a moving known segment. Start points and stationary grades remain
null. Counts describe occurrences, not unique cells. Coverage is classified as
known-both, coverage-gained, coverage-lost, or unknown-both. Segment status columns
show the exact before/after outcomes, including unknown-elevation.

Whole-path summary deltas exist only when both paths have complete elevation
coverage. Otherwise `summary_delta` is null, even if partial observed totals happen
to be numeric. The complete individual assessments remain embedded for inspection.
A negative ascent/cost change is arithmetic, not a safety or overall improvement
claim. Overflow is rejected, never emitted as an infinite delta.

## Saved outputs

The destination must not exist. Inputs and earlier receipts are never overwritten.
- `terrain-path-comparison.json`: full independent reference/candidate assessments,
  both verified source bundles and their identities, parameters, exact and
  normalized paths, all aligned changes, whole-path deltas and output text
- `path-comparison.csv`: one row per occurrence, with elevation changes, coverage
  classification, segment status transitions and signed grade delta
- `input-path.txt` and `path-cells.txt`: exact submitted and normalized paths
- `comparison-report.md`: source identities, counts, coverage warning and limits

`comparison_digest` is SHA-256 over the canonical JSON before adding that field.
`comparison_csv_digest` separately binds the CSV. Null numeric CSV fields are
empty; they are never fabricated zeros. JSON is the authoritative rich output.

This is an exploratory digital point-path workflow: no uncertainty propagation,
footprint, energy, robot suitability, mission acceptance or physical readiness.
Existing mission blockers remain unchanged. The multi-file save is not atomic
across an I/O interruption; retain inputs and choose a new output directory to retry.
