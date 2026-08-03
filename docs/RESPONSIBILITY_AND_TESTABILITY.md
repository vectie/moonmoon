# MoonMoon responsibility and testability

MoonMoon owns source-backed lunar world models, route and illumination
assessment, mission gates, and deterministic simulation evidence. Its primary
operator outcome is to choose a reviewable route window; it does not own robot
readiness or physical motion.

## Responsibility boundary

| Concern | Owner | MoonMoon seam |
| --- | --- | --- |
| Lunar source, coordinates, uncertainty and terrain | MoonMoon | Records provenance and derived evidence. |
| Route and mission-window decision | MoonMoon | Applies the mission gate and returns an explicit decision. |
| Generic orchestration and agent reasoning | MoonFlow / MoonClaw | Receives and returns typed contracts; creates no runtime. |
| Robot readiness and physical effects | MoonRobo | Provides non-authoritative simulation evidence only. |
| Accepted dossier and learning | MoonBook | Receives reviewed evidence and outcomes. |

The visible path lives in `ui/rabbita-moon/main/mission_path.mbt`; the globe,
terrain and evidence controls remain separate cohesive files in the same
Rabbita package. Inspecting a candidate never mutates the mission-selected
route, and the recovery action restores that selected route.

## Test seams

- `src/ui/` tests source, view-model, route, lighting and motion-boundary truth.
- `ui/rabbita-moon/main/mission_path_wbtest.mbt` asserts progress, denial and
  the non-authoritative motion statement.
- `docs/qualification/UI_TO_UI_USE_CASES.md` owns rendered success, denial,
  recovery and MoonRobo handoff evidence.

Physical readiness is never inferred from a scene, route score, rendered gait
or adapter preview.
