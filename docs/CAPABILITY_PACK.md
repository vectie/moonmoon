# MoonMoon capability pack

MoonMoon is now a first-class MoonFlow pack rather than a canvas label or a
descriptive `adapter.v1` capability.

## Executable identities

| Operation | Input | Output | Authority | Claim ceiling |
|---|---|---|---|---|
| `moonmoon/simulation.robot-mission@0.1.0` | `moonmoon/robot-mission-run-request@1.0.0` | `moonmoon/mission-simulation-receipt@1.0.0` | `sandbox-execution` | `calibrated-digital-twin` |
| `moonmoon/simulation.mission-result.inspect@0.1.0` | `moonmoon/mission-result-ref@1.0.0` | `moonmoon/mission-inspection-receipt@1.0.0` | `observe` | `simulation-evidence` |

The first operation can return a lower claim such as
`bounded-digital-simulation` or `scenario-qualified`. Its ceiling is not a
promise about a particular run.

`MoonflowAdapterRequest.declaration_id` identifies the MoonFlow graph work-item
declaration (for example, `robotics-simulation-v2`). It is required and must be
a safe identifier, but it is intentionally independent of the installed
MoonMoon adapter ID. Adapter identity remains bound by the product, operation,
schema, catalog declaration and expiring health evidence.

`input_artifacts[0]` is the exact typed MoonMoon operation request. MoonFlow may
append immutable dependency evidence after it. The adapter validates every
reference as workspace-relative and verifies the ordered aggregate artifact-set
digest before it decodes the first artifact or reuses durable results.

## Portable MoonRobo handoff

The simulation request references
`moonrobo.digital-model-integration-receipt.v1`. MoonMoon checks that it is an
accepted, non-physical `robot.integrate-digital-model` receipt and that its
RoboBook, model and validation references match the serialized mission design.
No source package or sibling repository is loaded.

## Durable session

One session contains:

- `mission-result.json`
- `replay-result.json`
- `replay-receipt.json`
- `provenance.json`
- `evaluation.json`

The adapter result references these files and the immutable operation receipt.
On restart, reconciliation can recover a complete session, classify a partial
session as unknown, or prove that an operation was not applied.

## Evidence limits

Replay verifies deterministic behavior for the exact serialized inputs.
Provenance records source references and SHA-256 identities. Dataset evidence
is reported as conditional unless the host supplies an available,
license-classified, digest-bound record. Route evidence remains bounded to the
enumerated path and declared grid status. None of these records establish
physical readiness.

## Host commands

```bash
moon run cmd/moonflow_adapter -- capability
moon run cmd/moonflow_adapter -- declaration
moon run cmd/moonflow_adapter -- health /workspace \
  2026-07-31T00:00:00Z 2026-07-31T00:05:00Z
moon run cmd/moonflow_adapter -- source-bundle pack.json /workspace \
  2026-07-31T00:00:00Z 2026-07-31T00:05:00Z
moon run cmd/moonflow_adapter -- invoke /workspace request.json
moon run cmd/moonflow_adapter -- reconcile-report /workspace request.json
```

Health evidence is host-generated, workspace-relative, SHA-256 bound and
expiring. The host must verify the bytes before catalog compilation.
