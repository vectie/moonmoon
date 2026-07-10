# Canonical Lunar Operator Experience

This is the active UI/UX delivery phase for Moonmoon. It resolves the current
split between the generated inspection page and the Rabbita browser app by
making one product surface authoritative while preserving MoonBit-owned data
and mission policy.

## Product Decision

- `ui/rabbita-moon` is the canonical interactive operator product.
- `src/ui` owns the renderer-neutral view model, evidence projection, and
  route-motion contract.
- The generated HTML remains a static report and fast runtime boundary; it is
  not a second interactive product.
- The default experience is lunar-first. Robot motion is an explicit,
  mission-gated adapter preview and never the first product claim.

The first screen must answer one question: where is the trusted site on the
Moon, which route is selected, and why can it not yet be traversed?

## Checkpoint 1: Rebuild the First Viewport

1. Make the source-backed Moon globe the primary full-height spatial surface.
2. Keep site coordinates, selected route, mission decision, source identity,
   score, blockers, and energy margin visible without opening diagnostics.
3. Provide working controls for site focus, globe reset, orbit, and switching
   between global Moon and local terrain.
4. Remove inactive settings, chat, shortcut, layer, and terrain-cell controls.
   Read-only evidence must look read-only.
5. Put robot motion behind a closed `Adapter preview` disclosure that states
   the route gate before any animation is shown.

Acceptance:

- The Moon, not the robot, is the first-viewport object.
- No visible control is inert.
- The selected route cannot look traversal-ready while its decision is block.
- Desktop and mobile show the primary action and gate status without overlap.

## Checkpoint 2: Complete the Operator Workflow

1. Add real route selection state backed by the existing route projections.
2. Add real terrain-cell selection and update the evidence inspector from the
   selected cell.
3. Make evidence layers functional, or keep them as a compact legend until
   each layer has a real visual projection.
4. Preserve the workflow:

   `Moon -> trusted site -> selected route -> blocking gates -> evidence`

Acceptance:

- Route and cell selection update both spatial overlays and textual evidence.
- Focus and reset provide deterministic recovery from every camera state.
- Evidence paths remain tied to the MoonBit view model and catalog records.

## Checkpoint 3: Repair the Adapter Preview

1. Keep the adapter preview separate from lunar mission authority.
2. Fix E1 mesh attachment and materials until the robot reads as one rigid,
   recognizable assembly.
3. Start the preview only after the disclosure is opened and stop or pause it
   when hidden.
4. Keep a visible `mission-gated` state until route clearance allows the
   motion contract to become adapter-ready.

Acceptance:

- The preview never implies that a blocked route is approved.
- Browser screenshots show attached robot geometry rather than fragments.
- Closing the preview pauses its render work.

## Checkpoint 4: Responsive And Runtime Hardening

1. Use a spatial stage plus evidence rail on desktop and a stage plus normal
   document-flow evidence on mobile.
2. Use `100dvh`, bounded grid tracks, `min-width: 0`, and wrapping evidence
   paths; avoid fixed overlapping drawers.
3. Keep controls at least 44 px, preserve visible focus, and respect reduced
   motion.
4. Split the large scene runtime only at real lifecycle boundaries: globe,
   site terrain, adapter preview, and shared render lifecycle.
5. Pause hidden canvases and dispose renderer resources when a surface is no
   longer mounted.

Acceptance:

- No clipping or horizontal overflow at 390x844, 768x1024, or 1440x900.
- Canvas content is nonblank and framed at every required viewport.
- The production build has deliberate scene loading rather than one mandatory
  robot-heavy first-load path.

## Verification Gate

Every checkpoint keeps these checks green:

- `moon check`
- `moon test`
- `moon info`
- `moon fmt`
- `node scripts/check-standalone-ui-runtime.mjs`
- `npm run check:gait` in `ui/rabbita-moon`
- `npm run build` in `ui/rabbita-moon`

Browser acceptance adds one desktop, one tablet, and one mobile screenshot,
canvas nonblank checks, control reachability, focus/reset behavior, view
switching, reduced-motion behavior, and no-overflow assertions.

## Completion

This phase is complete when Moonmoon opens on a recognizable movable Moon,
reaches the first trusted square through an understandable global-to-local
flow, explains the selected route gate, contains no fake controls, and keeps
robot animation in a truthful, gated adapter preview.
