# MoonMoon UI-to-UI qualification

This guide covers MoonMoon's single published application. The primary
scenario is deliberately a blocked lunar mission: the product succeeds when it
makes evidence and authority limits understandable, not when it forces a
simulation to look ready.

## Published-entrypoint truth

| Manifest entrypoint | Runtime surface | Current release truth |
| --- | --- | --- |
| `lunar-operator` | `ui/rabbita-moon` | Rabbita/Vite 3D operator and Moonbook application; locally runnable and statically buildable. A local Lepusa candidate exists, while public distribution remains conditional on Developer ID signing/notarization. |

MoonMoon owns lunar models, route evidence, and bounded deterministic
simulation. It does not authorize physical robot motion.

## Prerequisites and launch

The UI build prepares its declared MoonRobo preview assets before compiling.
That preview remains non-authoritative.

```sh
cd /Users/kq/Workspace/moonmoon/ui/rabbita-moon
npm install
npm run dev
```

Open <http://127.0.0.1:8766/first_trusted_square.html>.

For a static release check:

```sh
cd /Users/kq/Workspace/moonmoon/ui/rabbita-moon
npm run build
npm run preview
```

## Use case MM-1: inspect a blocked lunar mission

Goal: understand why a route is blocked and inspect alternatives without
changing mission authority.

1. Open **Operator**.
2. Read **Mission decision**, **Next required action**, site score, energy
   margin, and controlling blockers before touching the 3D scene.
3. Choose **Review blocking evidence**.
4. Confirm the evidence/handoff disclosure opens and receives focus.
5. Switch from **Moon** to **Site terrain**, then choose **Focus site**.
6. Open **Compare route candidates**.
7. Select at least two different measured corridors.
8. Confirm the UI says the candidate is being inspected while the
   mission-selected route is unchanged.
9. Open **Illumination evidence** and compare the current and ranked windows.
10. Open **Evidence dossier** and select two terrain cells.
11. Confirm elevation, slope, roughness, hazard, confidence, and source update
    together.
12. Open **Adapter preview** and confirm it says **preview only** and
    **non-authoritative**.
13. Choose **Return to Moon view**.

Expected visible evidence:

- The decision remains `block`.
- Exactly one inspected route and one terrain cell are selected at a time.
- Candidate inspection never changes the mission-selected route.
- Readable/physical lighting and pause/resume change presentation only.
- Terrain provenance points to the registered LRO LOLA source.
- Robot animation does not clear terrain, power, illumination, or human-review
  blockers.

## Use case MM-2: ask the bounded Moonbook

1. Choose **Moonbook & Guide** in the header.
2. Select **Mission status**, **Terrain evidence**, **Illumination**,
   **Route authority**, **Robot boundary**, and **Project architecture** in
   turn.
3. Choose **Why is the mission blocked?**.
4. Confirm the answer classifies its fact type and lists evidence sources.
5. Choose **Can robot motion authorize a route?**.
6. Confirm the answer says no and cites the mission/adapter boundary.
7. Type a question unrelated to the loaded registry.
8. Choose **Ask bookkeeper** and confirm it says evidence is unavailable rather
   than inventing an answer.
9. Choose **Clear**.

Expected evidence:

- Exactly one guide topic is active.
- Known answers bind to the loaded mission model and source registry.
- Unknown questions are recoverable and do not trigger network access.
- The bookkeeper cannot grant route authority.

## Governed negative MM-N1: treating preview motion as clearance

The negative action is conceptual but visible: open **Adapter preview** while
the mission decision is blocked and attempt to interpret walking animation as
route approval. The UI must continue to show `block`, the controlling
evidence, and the non-authoritative preview label. No physical command control
should appear.

### Recovery

1. Choose **Review blocking evidence**.
2. Return to the exact terrain, illumination, energy, and operator-review
   blockers.
3. Keep the mission blocked until a new, versioned mission input clears every
   upstream gate.

Reloading is safe: inspection state may be restored, but authority remains
owned by the loaded mission record.

## Governed negative MM-N2: unknown Moonbook evidence

Submit a blank question, then an unrelated question. The UI should explain
what can be asked and report missing evidence. Recover by selecting a known
topic or one of the four quick questions.

## Artifact and integration boundary

MoonMoon's compatible outbound artifacts are versioned mission, route, and
simulation receipts for MoonRobo/MoonFlow:

- `moonmoon/mission-simulation-receipt@1.0.0`;
- `moonmoon/mission-inspection-receipt@1.0.0`.

They are not image, video, logo, edit-decision-list, or MoonCast delivery
artifacts. MoonMoon is therefore intentionally excluded from the
MoonVis-to-MoonCast creative handoff. A future creative integration requires
an explicit reviewed render/export contract; screenshots or browser canvas
pixels must not be silently promoted into production evidence.

## What was actually tested

Qualification date: 2026-07-31.

- Launch and manifest truth were checked against `pack.json`, the Rabbita
  package, and the documented local URL.
- Existing release evidence already covers Operator, Moonbook, route/cell
  inspection, blocking evidence, history, refresh, responsive layout, and the
  installed Lepusa candidate.
- The coordinating MoonSuite run replayed the blocked-mission, route/cell
  inspection, non-authoritative preview, and Moonbook evidence-boundary cases
  in the published UI and captured screenshots. The result was a visible pass.
