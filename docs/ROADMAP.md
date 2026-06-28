# Roadmap

## Now

1. Keep the first trusted square concise and fully MoonBit-owned.
2. Clear or explain the selected `northeast-stepout` route blockers.
3. Keep source fixtures reproducible through MoonBit tests and manifests.
4. Use `src/ui/page.mbt` as the current operator view until live interaction
   justifies a dedicated Rabbita-style UI package.
5. Keep `src/ui/motion_contract.mbt` as the current locomotion handoff: it
   exposes route-motion readiness without placing robot gait primitives in
   Moonphys.
6. Follow `docs/LOCOMOTION_PHASE_GUIDANCE.md` for the route-motion to robot
   gait adapter phases.

## Next

- Tighten mission clearance language around terrain, illumination, energy, and
  operator review.
- Let the route-motion contract become `suite-adapter-ready` only after the
  route gates allow traversal.
- Add a second lunar site only after the first site has a clean route-gate
  story.
- Move live browser behavior into `ui/moonmoon/main` if the UI grows beyond a
  standalone generated page.
- Add explicit suite adapters later. Moonrobo can provide Noetix/URDF gait and
  Rabbita visualization there, but adapters stay out of the standalone domain
  packages. The current first step is the typed suite preview payload in
  `src/suite_adapter_preview`, which records Moonrobo Noetix profile, URDF, mesh,
  generated evidence, and compiled Moonphys review references without importing
  Moonrobo into standalone core packages.

## Non-Goals

- No committed `output/` tree.
- No Python verification layer for core product behavior.
- No hidden browser bundle under `src/ui`.
- No robot- or job-runner-specific compatibility code in the standalone model.
- No robot-specific gait asset, walk primitive, or URDF animation system inside
  `src/moonphys`.
