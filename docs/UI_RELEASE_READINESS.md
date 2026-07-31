# MoonMoon UI Release Readiness

Audit date: 2026-07-24
Checklist source: `../moongate/docs/LEPUSA_APP_RELEASE_HANDOVER.md`
Test surfaces: Rabbita browser UI and the installed copy from the Lepusa DMG

## Outcome

The adopted operator UI and Moonbook/bookkeeper flow pass the browser product
acceptance portion of the handover. MoonMoon now also has a least-privilege,
static Lepusa desktop boundary, a macOS icon, an ad-hoc-signed application
bundle, a DMG with an Applications shortcut, and passing installed-copy smoke
evidence.

The local arm64 artifact is release-candidate ready. A frictionless public
release is still blocked by the absence of a Developer ID signing identity and
notarization credentials. Git tagging, pushing, and publishing were not
requested and were not performed.

## Page inventory

| Page | Purpose understood | All controls | Recovery state | Refresh/history | 720×900 |
| --- | --- | --- | --- | --- | --- |
| Operator | Pass | Pass | Pass | Pass | Pass |
| Moonbook & Guide | Pass | Pass | Pass | Pass | Pass |

Normal desktop was checked at 1440×900. Narrow desktop was checked at 720×900.
The narrow document width equaled its viewport width; no document-level
horizontal overflow was present.

## Visual evidence

- [Operator at 1440×900](ui-evidence/2026-07-23-operator.jpg)
- [Moonbook bookkeeper at 1440×900](ui-evidence/2026-07-23-moonbook.jpg)
- [Moonbook at 720×900](ui-evidence/2026-07-23-moonbook-720x900.jpg)
- [Installed Lepusa app at 1117×768](ui-evidence/2026-07-24-packaged-operator.jpg)

## Use-case evidence

| Use case | UI actions | Expected invariant | Result |
| --- | --- | --- | --- |
| Understand a blocked mission | Read decision; click Review blocking evidence | Four blockers and the evidence/handoff source are visible | Pass |
| Switch spatial context | Moon/Site terrain; Focus site; Return to Moon view | View changes without changing mission route | Pass |
| Control the Moon | Pause/Resume; Physical/Readable | Pressed state, label, and rendering agree | Pass |
| Scrub lighting | Pointer select; ArrowLeft/ArrowRight | Index, timestamp, readouts, lighting data, and adapter event agree | Pass after fix |
| Compare corridors | Open comparison; click all six route buttons | Exactly one inspected route; mission selection unchanged unless it is the selected route | Pass |
| Inspect terrain | Open dossier; click all 16 cells | Exactly one selected cell; card and terrain view agree | Pass |
| Read illumination | Open illumination disclosure after route changes | Current/ranked windows and horizon evidence update to the inspected route | Pass |
| Verify robot boundary | Open Adapter preview and evidence handoff | Preview remains explicitly non-authoritative and mission-gated | Pass |
| Use the guide | Navigate through header; click all six topics | Exactly one topic is pressed and its article/source changes | Pass |
| Ask common questions | Click all four quick questions | Answer is evidence-grounded and cites three sources | Pass |
| Recover from form errors | Submit blank; submit unknown; ask project question; Clear | Warning, unknown, answered, then empty states are understandable and usable | Pass |
| Change language | Select Simplified Chinese, ask a question, return to English | URL, selector, UI language, and answer language agree | Pass after fix |
| Browser history | Operator → Moonbook → Back → Forward | Visible page and active navigation item agree with the URL | Pass |
| Refresh inspection | Inspect a route/cell, set terrain/lighting modes, reload | Inspection state returns and stays separate from mission authority | Pass after fix |
| Installed desktop flow | Mount DMG; copy app; Operator → Moonbook → quick question → Operator → blocking evidence | Packaged assets render, sourced answer appears, and mission-gated evidence opens | Pass after fix |

## Complete control inventory

The UI run exercised:

- two header navigation links and the language selector;
- Moon/Site terrain, Focus site, Return to Moon view, Pause/Resume,
  Physical/Readable, and the lighting range;
- Review blocking evidence;
- illumination, route comparison, and evidence/handoff disclosures;
- six route buttons;
- the Evidence dossier disclosure and all 16 terrain-cell buttons;
- the Adapter preview disclosure;
- six Moonbook topic buttons;
- four quick-question buttons;
- Ask bookkeeper and Clear; and
- browser Back, Forward, and refresh.

The Moon globe’s pointer drag and visual camera reset are part of the final
visual pass. Canvas motion is an inspection affordance and does not mutate the
mission model.

## Defects found and fixed

### Lighting scrubber did not respond

The native range control exposed a value but did not update reliably through
pointer or keyboard input. The browser adapter now handles pointer position and
arrow keys explicitly, writes the canonical value back to the control, and the
CSS provides a 44 px hit area.

### Language selector and rendered language disagreed

The selector could show Simplified Chinese while the document and freshly
mounted Rabbita content remained English. Locale changes now navigate to an
explicit locale query, forcing a deterministic mount. The post-render path also
asks the shared translator to process the Rabbita tree. Chinese bookkeeper
answers come from the MoonBit answer registry.

### No obvious action for a blocked decision

The first screen described the next action but offered no direct control.
**Review blocking evidence** now opens and focuses the controlling source and
handoff disclosure.

### Ambiguous reset label

**Reset view** also switched from terrain back to the Moon. It is now labeled
**Return to Moon view** so the consequence is predictable.

### No navigation or guide

The application had no meaningful internal history and no in-product
explanation. The sticky header now exposes Operator and Moonbook & Guide.
History, refresh, and selected navigation state are synchronized.

### Inspection state was lost on refresh

The inspected route, selected cell, terrain/Moon view, lighting sample, and
lighting display mode now persist for the browser session. The stored inspected
route is always labeled separately from the mission-selected route.

### Packaged Lepusa window was blank

The first installed build opened a valid native window but its Vite output used
root-relative `/assets/...` URLs, which do not resolve beneath the
`lepusa://packaged/main/` asset root. The Rabbita Vite configuration now uses
`base: './'`. A rebuilt DMG rendered the complete operator and Moonbook flows in
the installed WKWebView.

## State and source consistency

- Site score `20`, energy margin `-12570 Wh`, six route candidates, and four
  blockers come from the loaded `TrustedSquareViewModel`.
- The route comparison list and blocked-route summary are derived from the same
  six route records.
- The terrain grid and selected-cell card consume the same 16 cell records.
- The ranked selected-route window is
  `2026-11-08T00:00:00Z` through `2026-11-22T00:00:00Z`, with
  `3997.259 Wh`, from the route illumination model.
- Terrain provenance is the registered NASA PDS Geosciences / LRO LOLA source
  at `data/sources/lro_lola/first_trusted_square_dem.csv`.
- The Moonbook answer registry is generated in
  `src/ui/moonbook.mbt`; the Rabbita product surface is
  `ui/rabbita-moon/main/moonbook.mbt`.
- Robot preview authority remains owned by the mission gate in
  `src/ui/motion_contract.mbt`.

## Runtime diagnostics

After the full interaction run, the browser reported no warning or error
console entries. Page resources rendered successfully in the local session.
The packaged WKWebView loaded `lepusa://packaged/main/index.html`, exposed the
complete accessibility tree, navigated between both pages, and rendered the
bookkeeper answer and blocking-evidence state. The static desktop package has
no localhost service, native command routes, runtime plugins, or network-backed
readiness endpoint.

## Lepusa release checklist

| Handover gate | Status | Evidence or blocker |
| --- | --- | --- |
| Published Rabbita dependency | Pass | `moonbit-community/rabbita@0.12.4` |
| Published Lepusa dependency | Pass | `vectie/lepusa@0.1.4` |
| `lepusa.json` | Pass | Static packaged assets, system WKWebView, devtools disabled |
| Service/readiness boundary | Not applicable | Static `lepusa://` package; initial asset render is the readiness gate |
| Central web logo | Pass for UI | Shared MoonSuite mark is used in the header |
| Padded rounded `.icns` | Pass | `assets/moonmoon.icns`, 1024×1024 source scale |
| In-app Guide and `docs/UI_GUIDE.md` | Pass | Moonbook route and this guide |
| UI normal/narrow exercise | Pass | 1440×900 and 720×900 |
| MoonBit release gate | Pass | Strict native check; 206/206 native and 202/202 JS tests |
| Runtime minimum macOS | Pass | arm64 `lepusa-runtime`, `minos 11.0`; no app service binary exists |
| Bundle/package/release plans | Pass | strict verify, bundle `verified: true`, package ready with no blockers |
| Signed/notarized app | Partial | Ad-hoc signature passes before and after launch; no Developer ID identity is installed |
| DMG with Applications shortcut | Pass | `MoonMoon-0.1.0-macos-arm64.dmg`; shortcut resolves to `/Applications` |
| Installed-copy UI smoke | Pass | DMG-mounted copy launched and completed the primary Operator/Moonbook flow |
| Storage/signature after launch | Pass | no `.moonsuite` under Resources; deep strict signature still valid |
| Git tag/release/checksum | Partial | Local SHA-256 exists; Git publishing was not requested |

## Desktop artifact

Local ignored outputs:

- `dist/release/MoonMoon-0.1.0-macos-arm64.dmg`
- `dist/release/MoonMoon-0.1.0-macos-arm64.dmg.sha256`
- SHA-256:
  `486d5929614047a5c9dc2f086f76acb4b18bb22d6f6e5511815ec1a659359228`

The DMG was mounted read-only, its Applications symlink was checked, and its app
was copied to a separate temporary install root before launch. Lepusa's
generated install-smoke script passed. The installed app had no remaining
process after close, did not write app state beneath `Contents/Resources`, and
passed `codesign --verify --deep --strict` both before and after the UI run.

## Public-release work still required

1. Install and configure a valid Developer ID Application identity.
2. Repackage with Developer ID signing, submit for notarization, staple, and
   run Gatekeeper assessment.
3. Review and commit only the intended dirty-tree changes.
4. Push the intended commit, create the matching tag, and publish the DMG and
   checksum when explicitly authorized.
