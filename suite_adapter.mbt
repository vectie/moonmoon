///|
/// Describe MoonMoon's product-owned MoonFlow adapter boundary.
/// Actual execution is provided by `src/mission_adapter`; this root facade
/// deliberately exposes only the portable capability description.
pub fn moonflow_adapter_capability_json() -> Json {
  {
    "adapter_id": "moonmoon-local-v1",
    "product_id": "moonmoon",
    "protocol": "moonflow.adapter.v2",
    "operations": [
      "simulation.robot-mission", "simulation.mission-result.inspect",
    ],
    "authority_classes": ["sandbox-execution", "observe"],
    "input_contracts": [
      "moonmoon/robot-mission-run-request@1.0.0", "moonmoon/mission-result-ref@1.0.0",
    ],
    "output_contracts": [
      "moonflow.adapter-result.v1", "moonmoon/mission-simulation-receipt@1.0.0",
      "moonmoon/mission-inspection-receipt@1.0.0",
    ],
    "claim_ceiling": "calibrated-digital-twin",
    "healthy": true,
    "supports_cancel": false,
    "supports_reconcile": true,
    "physical_deployment_claim_forbidden": true,
    "correct_refusal_is_success": true,
  }
}
