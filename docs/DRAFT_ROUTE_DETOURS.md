# Known-cell route detours

Mission designers can now connect or replace a draft route span without manually
entering each intermediate cell. This supports PRD MN-W02/MN-W05: prepare a
concrete alternative for the existing native digital-mission comparison.

1. Open a retained study, fork a draft and choose the variant to edit.
2. In **Draft route on frozen terrain**, find **Plan a known-cell detour**.
3. Choose start and end **occurrences**, not unique cell names. Start must precede
   end, and the endpoint cells must differ.
4. Optionally enter cells to avoid, one `row,column` pair per line.
5. Keep **Unrestricted sampled edge grade**, or explicitly choose **Limit maximum
   absolute sampled edge grade** and enter a nonnegative bound in m/m. For example,
   `0.1` means 10%, not 0.1 degrees; `0` permits only equal-height adjacent samples.
   The limit is inclusive and applies only to edges inside the replacement span.
6. Preview the replacement. The ordered cell list shows exactly what will replace
   the inclusive span. Prefix and suffix remain exact, including repeats. The
   message counts any exclusions that still occur outside the edited span.
   The preview also states the selected bound, proposed peak sampled grade and
   frozen declared cell size. No route edit occurs during preview.
7. Apply the preview, or clear it without changing the route. Existing route undo
   restores the previous text. Export/reopen retains the exact authored route;
   sibling variants and the original study/review remain unchanged.
8. Use the separate **Run digital mission** flow for native assessment.

The bounded breadth-first search uses only the frozen source's exact known cells,
cardinal adjacency and designer exclusions. In grade-limited mode, an edge is
eligible only when `abs(elevation_to - elevation_from) / cell_size_m <= bound`,
using the source's exact frozen elevations and declared positive cell size.
Upward and downward edges use the same absolute bound. Its objective is fewest
eligible index steps,
with deterministic tie order north, west, east, south (decreasing row, decreasing
column, increasing column, increasing row). It does not find a shortest 3D route,
compute hazard/energy/robot suitability, infer terrain grade between samples,
preserve intermediate waypoints inside
the replacement span, or establish physical readiness. Missing cells are never
interpolated, and a disconnected or grade-ineligible source yields no proposal.
Limited mode refuses invalid elevations, cell size, nonfinite arithmetic and
grade underflow rather than treating them as eligible. Unrestricted mode remains
independent of elevations. A constraint met by these digital samples does not
establish mission feasibility, hardware qualification or physical readiness.
Existing simulation
results and blockers are never rewritten.

At most 4096 terrain samples, 256 exclusions and 256 total route occurrences are
supported. A route exceeding that bound is refused rather than truncated. Closed
endpoint loops are not rewritten. Endpoint/exclusion/mode/bound changes invalidate the
preview; route edits, variant switches, discard or reopened sources invalidate
removed controls as well. Applying remains explicit and can be undone. Planner
mode and bound are temporary controls, not a new retained simulation assumption:
export/reopen preserves the exact applied route in the unchanged v1/v2 draft
contract. Reopening defaults to explicit unrestricted mode; choose and preview a
grade limit again to create another proposal. Prefix and suffix are unchanged and
are not checked against the bound, even when they contain unknown or steep edges.

Verification: `npm run test:study` from `ui/rabbita-moon`, or the delivered
cwd-independent `run-focused.sh`. Node DOM-harness tests exercise actual study
and authoring bindings plus export/reopen; they are not rendered browser or
native simulator qualification. The optional real native-host journey is unrun
without a separately hash-bound retained executable; a skipped case is not a pass.
No new dependencies or provider calls are used.
