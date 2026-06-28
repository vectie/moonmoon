///|
pub(all) struct TraverseMotionContract {
  contract_id : String
  site_id : String
  selected_route_id : String
  physics_core_package : String
  motion_owner_package : String
  preview_kind : String
  gait_asset_status : String
  simulation_status : String
  status : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn simulation_status_for_decision(decision : String) -> String {
  if decision == "allow" {
    "simulation-preview-ready"
  } else if decision == "review" {
    "simulation-preview-needs-review"
  } else {
    "simulation-preview-blocked"
  }
}

///|
fn motion_contract_status(decision : String) -> String {
  if decision == "allow" {
    "suite-adapter-ready"
  } else {
    "mission-gated"
  }
}

///|
fn motion_contract_next_action(view : TrustedSquareViewModel) -> String {
  if view.scorecard.decision == "allow" {
    "add a suite adapter that consumes this route and supplies robot-specific gait assets"
  } else {
    "clear terrain, illumination, energy, and review blockers before binding robot gait assets"
  }
}

///|
pub fn traverse_motion_contract(
  view : TrustedSquareViewModel,
) -> TraverseMotionContract {
  {
    contract_id: "ui/first-trusted-square/traverse-motion-contract-v1",
    site_id: view.site_id,
    selected_route_id: view.selected_route_id,
    physics_core_package: "src/moonphys",
    motion_owner_package: "future-suite-adapter",
    preview_kind: "standalone-route-motion-contract",
    gait_asset_status: "not-in-standalone-model",
    simulation_status: simulation_status_for_decision(view.scorecard.decision),
    status: motion_contract_status(view.scorecard.decision),
    next_action: motion_contract_next_action(view),
  }
}

///|
pub fn first_trusted_square_motion_contract() -> TraverseMotionContract {
  traverse_motion_contract(first_trusted_square_view_model())
}

///|
pub fn first_trusted_square_motion_contract_json() -> Json {
  first_trusted_square_motion_contract().to_json()
}
