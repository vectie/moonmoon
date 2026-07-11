///|
/// Describe MoonMoon's independent digital mission-gate boundary for MoonFlow.
/// Simulation success is evidence only and never implies deployment authority.
pub fn moonflow_adapter_capability_json() -> Json {
  {
    "adapter_id": "moonmoon-v1",
    "product_id": "moonmoon",
    "protocol": "moonflow.adapter.v1",
    "operations": [
      "ingest-identity-matched-design", "load-versioned-environment", "simulate-mission",
      "run-deterministic-replay", "evaluate-safety-gates", "record-correct-refusal",
      "reconcile-simulation",
    ],
    "authority_classes": ["observe", "sandbox-execution", "workspace-mutation"],
    "supports_cancel": false,
    "supports_reconcile": true,
    "receipt_contracts": [
      "moonmoon.simulation-receipt.v1", "moonmoon.mission-gate-receipt.v1", "moonmoon.replay-receipt.v1",
      "moonmoon.refusal-receipt.v1",
    ],
    "readiness_ceiling": "digital_mission_gate",
    "physical_deployment_claim_forbidden": true,
    "correct_refusal_is_success": true,
  }
}
