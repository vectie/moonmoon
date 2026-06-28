# Roadmap

## Now

1. Keep the first trusted square concise and fully MoonBit-owned.
2. Clear or explain the selected `northeast-stepout` route blockers.
3. Keep source fixtures reproducible through MoonBit tests and manifests.
4. Use `src/ui/page.mbt` as the current operator view until live interaction
   justifies a dedicated Rabbita-style UI package.

## Next

- Tighten mission clearance language around terrain, illumination, energy, and
  operator review.
- Add a second lunar site only after the first site has a clean route-gate
  story.
- Move live browser behavior into `ui/moonmoon/main` if the UI grows beyond a
  standalone generated page.
- Add explicit suite adapters later, but keep them out of the domain packages.

## Non-Goals

- No committed `output/` tree.
- No Python verification layer for core product behavior.
- No hidden browser bundle under `src/ui`.
- No robot- or job-runner-specific compatibility code in the standalone model.

