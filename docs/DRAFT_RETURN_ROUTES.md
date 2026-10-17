# Explicit out-and-back draft alternatives

The mission draft editor can append a retraced return to the selected route.
This is a bounded authoring convenience for MN-W02, MN-W05 and MOONMOON-R01,
not a new simulation capability or completion of those requirements.

## Keep an outbound comparison

1. Open a study and fork its exact parent session using the existing draft controls.
2. Select the outbound variant and use **Duplicate variant**. Give the copy a
   distinct name, such as “Out and back”, and explain its assumptions.
3. Under **Author an out-and-back route**, choose **Preview retraced return**.
   The preview lists only the appended return occurrences, numbered within the
   combined route. The authoritative route remains unchanged.
4. Review the occurrence count and authored straight-segment estimated distances.
   Choose **Apply retraced return**, or **Cancel return preview**. Apply changes
   only this selected variant. **Undo last route edit** restores the outbound
   text while the selected variant remains open.
5. Export the draft, discard it, then reopen the exported file to recover the
   exact named variants and frozen parent. Exporting does not run a simulation.
   Use the separate **Run digital mission** action when actual results are needed.

Existing v2 controls allow two to four variants. Duplication is unavailable at
four; select an existing variant or explicitly remove one first. Legacy v1
drafts can author a return and roundtrip as v1, but have no variant duplication.
Export the original separately before editing if it must be retained.

## Exact operation and bounds

For outbound occurrences A, B, C, the combined route is A, B, C, B, A.
Only the would-be duplicate turnaround occurrence C is omitted. All earlier
repeats are retained: A, A, B becomes A, A, B, A, A. Closed routes and repeated
cells are not silently deduplicated. Applying again treats the entire current
route as outbound; it is not an idempotent “make round trip” conversion.

The existing 256-occurrence bound applies to the combined route. A retrace can
therefore accept at most 128 outbound occurrences (255 combined). Oversized or
invalid routes produce an actionable error without editing the text. Missing
terrain does not invent samples or block exact route authoring.

Estimated distance is the sum of authored Euclidean row/column segment lengths
times declared cell size. It is a geometry estimate, not terrain-following
distance. The outbound and retraced return estimates are equal; this says
nothing about direction-dependent energy or feasibility. Without a finite,
positive representable scale, distance is shown as unavailable. Disconnected
segments, unsupported cells and missing coverage remain for native validation.

Preview state is temporary, bound to the current route text and render generation.
Switching variants, changing route text, changing context or discarding prevents
old controls from applying. Export retains ordinary exact path occurrences in
the existing contract, without a new planner/result schema or inherited approval.

## Evidence and limits

Node tests cover pure occurrence planning, bounds and distance failures; actual
production DOM handlers cover duplication, preview/cancel/apply/undo, stale
callbacks, download Blob export and reopen, other-variant preservation and
explicit host submission. The injected host deliberately fails, proving no
result is fabricated. These are DOM test doubles, not a browser qualification.

Existing mission-run tests already manually author reversed route segments.
This change does not claim reverse-route simulation is new. No native mission
journey, browser rendering qualification, external dataset, physical operation,
energy sufficiency or release gate is established by the authoring tests.
