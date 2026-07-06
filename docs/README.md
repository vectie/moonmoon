# Moonmoon Documentation Guide

Moonmoon is the MoonSuite lunar terrain and mission model. Its docs should keep
the product small and testable: lunar claims, data roots, terrain analysis,
mission scoring, robot-data adapters, and inspection UI belong here; desktop
shells, agent execution, and suite scheduling belong elsewhere.

## Scope And Boundary

Moonmoon owns:

- lunar coordinate, provenance, uncertainty, and source-claim contracts
- data-root persistence and validation for lunar and robot-derived evidence
- terrain source manifests, DEM fixtures, slope, roughness, and hazard
  classification
- mission corridor, horizon, remediation, energy, and route-clearance evidence
- renderer-neutral UI models and Rabbita terrain inspection app

Moonmoon does not own Moondesk UI, MoonClaw execution, Moontown scheduling,
MoonRobo control, or MoonStat observability. Adapters to those products should
be explicit boundary packages or exported records.

## Reading Order

1. [../README.mbt.md](../README.mbt.md): current shape, commands, and product
   rule.
2. [ARCHITECTURE.md](ARCHITECTURE.md): package ownership and locomotion
   boundary.
3. [DATA_LAYER.md](DATA_LAYER.md): data-root model and validation plan.
4. [ROADMAP.md](ROADMAP.md): current product milestones.
5. [STEP_BY_STEP_PLAN.md](STEP_BY_STEP_PLAN.md): implementation slices and
   gate criteria.

## Implementation Guidance

Keep the root package as a facade. New durable behavior should land in a named
package under `src/`, with tests close to the package that owns the contract.
Generated Markdown, JSON, HTML, screenshots, and browser bundles should stay
out of source unless they are checked-in fixtures with a clear test purpose.

## Testing Guidance

```sh
moon check
moon test
moon info
moon fmt
```

For data-layer changes, test unsafe refs, missing files, duplicate manifests,
checksum mismatches, lineage records, and validation reports. For UI or mission
changes, verify the CLI JSON/HTML paths and the Rabbita terrain app separately.

## Worth Noticing

- Moonmoon owns lunar world claims, not robot actuation.
- Robot data contracts are useful for MoonRobo, but MoonRobo owns safety,
  control, and bridge dispatch.
- Data roots should be inspectable and reproducible; avoid hidden generated
  output trees.
- Public API changes should be reviewed through `.mbti` diffs after
  `moon info`.

## Future Plan

- Harden first trusted square data-root validation.
- Keep mission route clearance tied to explicit terrain and source evidence.
- Add stronger UI smoke coverage for desktop and mobile inspection.
- Promote cross-product exports only when their consumer boundary is clear.
