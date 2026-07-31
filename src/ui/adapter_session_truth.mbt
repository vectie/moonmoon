///|
pub(all) struct AdapterSessionTruth {
  protocol : String
  simulation_operation : String
  inspection_operation : String
  session_status : String
  replay_status : String
  provenance_status : String
  uncertainty_status : String
  evidence_root : String
  physical_readiness : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn adapter_session_truth() -> AdapterSessionTruth {
  {
    protocol: "moonflow.adapter.v2",
    simulation_operation: "simulation.robot-mission",
    inspection_operation: "simulation.mission-result.inspect",
    session_status: "no durable session loaded",
    replay_status: "required before acceptance",
    provenance_status: "workspace-relative and digest-bound",
    uncertainty_status: "conditional until run evidence is loaded",
    evidence_root: ".moonsuite/products/moonmoon/mission-sessions",
    physical_readiness: false,
  }
}
