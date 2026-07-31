# MoonMoon Documentation Guide

Start with the [product contract](PRODUCT_CONTRACT.md) for current maturity,
evidence claims, the MoonRobo boundary and release gates.

MoonMoon is the MoonSuite lunar terrain and mission model. Its docs should keep
the product small and testable: lunar claims, data roots, terrain analysis,
mission scoring, robot-data adapters, and inspection UI belong here; desktop
shells, agent execution, and suite scheduling belong elsewhere.

## Scope And Boundary

MoonMoon owns:

- lunar coordinate, provenance, uncertainty, and source-claim contracts
- data-root persistence and validation for lunar and robot-derived evidence
- terrain source manifests, DEM fixtures, slope, roughness, and hazard
  classification
- mission corridor, horizon, remediation, energy, and route-clearance evidence
- renderer-neutral UI models and Rabbita terrain inspection app

MoonMoon does not own MoonDesk UI, MoonClaw execution, MoonTown scheduling,
MoonRobo control, or MoonGate observability. Adapters to those products should
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
6. [UI_UX_NEXT_PHASE.md](UI_UX_NEXT_PHASE.md): canonical lunar operator UI
   checkpoints and browser acceptance criteria.
7. [UI_SPATIAL_COCKPIT_PLAN.md](UI_SPATIAL_COCKPIT_PLAN.md): active feature-first
   cockpit upgrade, spatial modes, and quality gates.
8. [UI_GUIDE.md](UI_GUIDE.md): operator, evidence, Moonbook, and bookkeeper
   guide.
9. [UI_RELEASE_READINESS.md](UI_RELEASE_READINESS.md): browser and installed
   Lepusa acceptance evidence, artifact checksum, and public-signing status.
10. [CAPABILITY_PACK.md](CAPABILITY_PACK.md): versioned MoonFlow operations,
    durable simulation sessions, portable MoonRobo handoff, and claim limits.

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

- MoonMoon owns lunar world claims, not robot actuation.
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
