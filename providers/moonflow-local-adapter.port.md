# MoonFlow local adapter port

`moonmoon-local-v1` is MoonMoon's pack-owned implementation of
`moonflow.adapter.v2`.

The host passes a workspace root and a typed MoonFlow request to
`cmd/moonflow_adapter`. Inputs and outputs are serialized workspace-relative
artifacts. The adapter never imports a sibling checkout, discovers
`../moonrobo`, or calls a robot transport.

Supported operations:

- `simulation.robot-mission`
- `simulation.mission-result.inspect`

Every attempt persists its request, state, operation receipt and adapter result
under `.moonsuite/products/moonmoon/adapter-attempts/`. A mission session also
persists the first result, replay result, replay receipt, provenance and
evaluation under `.moonsuite/products/moonmoon/mission-sessions/`.

The host must generate health windows shortly before catalog compilation
(recommended maximum: five minutes), verify the evidence bytes named by the
health attestation, and pass the resulting source bundle to MoonFlow's
capability compiler.
