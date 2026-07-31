# MoonRobo design to digital mission

1. MoonRobo integrates a digital design and emits
   `moonrobo.digital-model-integration-receipt.v1`.
2. A host writes `moonmoon.robot-mission-run-request.v1`, referencing that
   receipt and a MoonMoon mission design inside the same workspace.
3. MoonFlow binds the exact versioned operation
   `moonmoon/simulation.robot-mission@0.1.0`.
4. MoonMoon validates the serialized integration binding, runs the existing
   mission model twice, and persists byte-comparison replay evidence.
5. MoonMoon emits provenance and an uncertainty-aware evaluation. A correct
   digital refusal is a successful adapter execution with a rejected mission
   decision.
6. `simulation.mission-result.inspect` can independently regenerate a
   reviewable evaluation from the result, replay and provenance artifacts.
7. Any physical-readiness or command work must cross back into MoonRobo under
   separate authority; MoonMoon has no such operation.
