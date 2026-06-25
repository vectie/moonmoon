///|
pub(all) struct MoonClawRemediationMarginTask {
  task_id : String
  proposal_id : String
  site_id : @core.SiteId
  route_id : String
  priority : MoonClawJobPriority
  state : MoonClawReceiptStatus
  objective : String
  active_margin_count : Int
  active_margin_ids : Array[String]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  inputs : Array[MoonClawJobInput]
  artifacts : Array[MoonClawTaskArtifact]
  commands : Array[String]
  acceptance_criteria : Array[MoonClawAcceptanceCriterion]
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn active_margin_ids() -> Array[String] {
  [
    "terrain-northeast-stepout", "illumination-northeast-stepout", "energy-window",
  ]
}

///|
fn terrain_margin_artifact(
  terrain : @mission.TerrainRemediationEvidence,
) -> MoonClawTaskArtifact {
  task_artifact(
    "terrain-northeast-stepout",
    terrain.output_path,
    terrain.generated_by,
    "selected route terrain clears grade and roughness limits with reviewed source evidence",
    "grade margin \{terrain.grade_margin}, roughness margin \{terrain.roughness_margin_m} m, blocking edges \{terrain.blocking_edge_count}/\{terrain.edge_count}",
    terrain.decision != @mission.TraverseDecision::Block,
    terrain.next_action,
    "python3 scripts/generate_selected_route_terrain_remediation.py --check",
  )
}

///|
fn horizon_margin_artifact(
  horizon : @mission.LocalHorizonEvidence,
) -> MoonClawTaskArtifact {
  task_artifact(
    "illumination-northeast-stepout",
    horizon.output_path,
    horizon.generated_by,
    "selected route local horizon clears terrain-shadow margin against the power window",
    "terrain-shadow margin \{horizon.terrain_shadow_margin_deg} deg, max horizon \{horizon.max_horizon_angle_deg} deg, max sun altitude \{horizon.max_sun_altitude_deg} deg",
    horizon.decision != @mission.TraverseDecision::Block,
    horizon.next_action,
    "python3 scripts/generate_selected_route_horizon.py --check",
  )
}

///|
fn energy_margin_artifact(
  energy : @mission.EnergyRemediationEvidence,
) -> MoonClawTaskArtifact {
  task_artifact(
    "energy-window",
    energy.output_path,
    energy.generated_by,
    "selected route bounded energy demand leaves at least the conservative minimum margin",
    "bounded margin \{energy.bounded_margin_wh} Wh, margin gap \{energy.margin_gap_wh} Wh, available \{energy.verified_available_energy_wh} Wh",
    energy.decision != @mission.TraverseDecision::Block,
    energy.next_action,
    "python3 scripts/check_energy_margin_remediation.py",
  )
}

///|
pub fn remediation_margin_task_blocked_artifact_count(
  task : MoonClawRemediationMarginTask,
) -> Int {
  let mut count = 0
  for artifact in task.artifacts {
    if !artifact.ready {
      count = count + 1
    }
  }
  count
}

///|
pub fn first_trusted_square_remediation_margin_task() -> MoonClawRemediationMarginTask {
  let site_id = "first-trusted-square"
  let route_id = "northeast-stepout"
  let terrain = @mission.first_trusted_square_northeast_stepout_terrain_remediation()
  let horizon = @mission.first_trusted_square_northeast_stepout_horizon_evidence()
  let energy = @mission.first_trusted_square_energy_remediation()
  let artifacts = [
    terrain_margin_artifact(terrain),
    horizon_margin_artifact(horizon),
    energy_margin_artifact(energy),
  ]
  let margin_ids = active_margin_ids()
  {
    task_id: "moonclaw/\{site_id}/remediation-margin-v1/task",
    proposal_id: "moonclaw/\{site_id}/remediation-margin-v1",
    site_id,
    route_id,
    priority: Critical,
    state: Accepted,
    objective: "Convert the remaining selected-route terrain, local-horizon, and energy margins into one executable MoonClaw work packet before MoonRobo simulation consumption.",
    active_margin_count: margin_ids.length(),
    active_margin_ids: margin_ids,
    hardware_state: @moonrobo.MoonroboExecutionState::HardwareDenied,
    hardware_authority: "moonmoon-safety-gate-only",
    hardware_denied: true,
    inputs: [
      input(
        "selected-route-terrain-remediation",
        terrain.output_path,
        @core.ClaimKind::Derived,
        "Bounded selected-route terrain still blocks on grade, roughness, and blocking-edge margins.",
      ),
      input(
        "selected-route-local-horizon",
        horizon.output_path,
        @core.ClaimKind::Derived,
        "Bounded local horizon still blocks illumination because terrain-shadow margin exceeds the sampled sun altitude.",
      ),
      input(
        "selected-route-energy-remediation",
        energy.output_path,
        @core.ClaimKind::Derived,
        "Bounded route energy still blocks because available energy does not satisfy conservative reserve and survival demand.",
      ),
      input(
        "simulation-blocker-reduction",
        "output/moonrobo/first_trusted_square_simulation_blocker_reduction.json",
        @core.ClaimKind::Derived,
        "MoonRobo reduction closes stale non-margin blockers and preserves these three active remediation margins.",
      ),
    ],
    artifacts,
    commands: [
      "python3 scripts/generate_selected_route_terrain_remediation.py --check", "python3 scripts/generate_selected_route_horizon.py --check",
      "python3 scripts/check_energy_margin_remediation.py", "bash scripts/build_moonmoon_dossier.sh --review-transitions data/fixtures/rabbita_clearance_transitions_accept.json",
      "python3 scripts/check_moonrobo_simulation_blocker_reduction.py", "python3 scripts/check_moonclaw_remediation_margin_task.py",
      "/Users/kq/.moon/bin/moon test",
    ],
    acceptance_criteria: [
      criterion(
        "all-active-margins-preserved", "Task carries terrain-northeast-stepout, illumination-northeast-stepout, and energy-window as explicit active blockers.",
      ),
      criterion(
        "ranked-remediation-work", "Artifacts preserve current margin values and next actions so MoonClaw can work terrain, horizon, then energy without losing evidence paths.",
      ),
      criterion(
        "hardware-denial-preserved", "MoonRobo hardware_state remains HardwareDenied and authority remains moonmoon-safety-gate-only while the task is open.",
      ),
    ],
    safety_gate: "Do not allow MoonRobo simulation consumption or hardware execution until all three margin artifacts become ready under regenerated MoonMoon evidence; hardware authority stays moonmoon-safety-gate-only.",
    next_action: "Execute the terrain, local-horizon, and energy remediation commands, regenerate the dossier, and re-run the MoonRobo blocker-reduction checks.",
  }
}

///|
pub fn first_trusted_square_remediation_margin_tasks() -> Array[
  MoonClawRemediationMarginTask,
] {
  [first_trusted_square_remediation_margin_task()]
}

///|
pub fn render_remediation_margin_tasks_markdown(
  tasks : Array[MoonClawRemediationMarginTask],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Tasks\n\n"
  for task in tasks {
    text += "- \{task.task_id}\n"
    text += "  - proposal: \{task.proposal_id}\n"
    text += "  - priority: \{priority_label(task.priority)}\n"
    text += "  - state: \{receipt_status_label(task.state)}\n"
    text += "  - route: \{task.route_id}\n"
    text += "  - active margins: \{task.active_margin_count}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(task.hardware_state)}\n"
    text += "  - hardware authority: \{task.hardware_authority}\n"
    text += "  - safety gate: \{task.safety_gate}\n"
    text += "  - next action: \{task.next_action}\n"
    text += "  - margin ids:\n"
    for margin_id in task.active_margin_ids {
      text += "    - \{margin_id}\n"
    }
    text += "  - inputs:\n"
    for input in task.inputs {
      text += "    - \{input.input_id}: \{input.evidence_path} - \{input.summary}\n"
    }
    text += "  - artifacts:\n"
    for artifact in task.artifacts {
      text += "    - \{artifact.artifact_id}: \{artifact.path}\n"
      text += "      - producer: \{artifact.producer}\n"
      text += "      - current: \{artifact.current_state}\n"
      text += "      - ready: \{artifact.ready}\n"
      text += "      - blocking: \{artifact.blocking_reason}\n"
      text += "      - gate: \{artifact.validation_gate}\n"
    }
    text += "  - commands:\n"
    for command in task.commands {
      text += "    - \{command}\n"
    }
    text += "  - acceptance:\n"
    for acceptance in task.acceptance_criteria {
      text += "    - \{acceptance.criterion_id}: \{acceptance.description}\n"
    }
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_tasks_markdown() -> String {
  render_remediation_margin_tasks_markdown(
    first_trusted_square_remediation_margin_tasks(),
  )
}

///|
pub fn render_remediation_margin_tasks_json(
  tasks : Array[MoonClawRemediationMarginTask],
) -> Json {
  tasks.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_tasks_json() -> Json {
  render_remediation_margin_tasks_json(
    first_trusted_square_remediation_margin_tasks(),
  )
}
