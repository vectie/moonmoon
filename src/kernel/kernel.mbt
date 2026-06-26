///|
pub(all) enum ReadinessState {
  Ready
  NeedsEvidence
  Blocked
  Planned
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum BuildLane {
  DataLane
  TerrainLane
  MissionLane
  RobotLane
  ViewerLane
  SuiteLane
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct KernelLayer {
  layer_id : String
  label : String
  owns : String
  source_contract : String
  current_artifact : String
  readiness : ReadinessState
  next_output : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct EvidenceGate {
  gate_id : String
  label : String
  owner_package : String
  readiness : ReadinessState
  proof_artifact : String
  blocker : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteBoundary {
  product_id : String
  role : String
  consumes : String
  emits : String
  boundary_rule : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildTask {
  task_id : String
  priority : Int
  lane : BuildLane
  title : String
  outcome : String
  depends_on : Array[String]
  evidence : Array[String]
  done_when : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonMoonKernel {
  kernel_id : String
  product_name : String
  current_site_id : String
  thesis : String
  operating_rule : String
  layers : Array[KernelLayer]
  evidence_gates : Array[EvidenceGate]
  suite_boundaries : Array[SuiteBoundary]
  build_queue : Array[BuildTask]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn readiness_state_label(state : ReadinessState) -> String {
  match state {
    Ready => "ready"
    NeedsEvidence => "needs-evidence"
    Blocked => "blocked"
    Planned => "planned"
  }
}

///|
pub fn build_lane_label(lane : BuildLane) -> String {
  match lane {
    DataLane => "data"
    TerrainLane => "terrain"
    MissionLane => "mission"
    RobotLane => "robot"
    ViewerLane => "viewer"
    SuiteLane => "suite"
  }
}

///|
fn route_fixture_gate(dossier : @site.SiteDossier) -> EvidenceGate {
  let best = dossier.corridor_scan[0]
  let promoted = best.selected_route_id != ""
  {
    gate_id: "best-corridor-window-route-fixture",
    label: "Best measured corridor window promoted into a route fixture",
    owner_package: "src/terrain + src/mission",
    readiness: if promoted {
      Ready
    } else {
      Blocked
    },
    proof_artifact: "data/sources/lro_lola/first_trusted_square_corridor_scan_v2.csv#\{best.window_id}",
    blocker: if promoted {
      "none"
    } else {
      "best 9x9 measured window \{best.window_id} has no DEM fixture, route candidate, or MoonRobo handoff"
    },
    next_action: if promoted {
      "score promoted route against robot and energy gates"
    } else {
      "extract the \{best.window_id} LOLA window, generate the terrain fixture, and bind it to a route id"
    },
  }
}

///|
fn power_gate(dossier : @site.SiteDossier) -> EvidenceGate {
  let power = dossier.power_window_evidence
  {
    gate_id: "time-windowed-power-evidence",
    label: "Time-windowed solar and thermal evidence attached",
    owner_package: "src/mission",
    readiness: if power.has_time_window_ephemeris {
      Ready
    } else {
      Blocked
    },
    proof_artifact: power.local_source_path,
    blocker: if power.has_time_window_ephemeris {
      "none"
    } else {
      "computed power-window evidence is incomplete; verified available energy remains zero"
    },
    next_action: if power.has_time_window_ephemeris &&
      power.source_status == "ready" {
      "review energy margin, horizon confidence, and robot gates before simulation"
    } else {
      "pin exact ephemeris source files, compute the sunlit/dark window, and regenerate power-window evidence"
    },
  }
}

///|
fn robot_gate(dossier : @site.SiteDossier) -> EvidenceGate {
  {
    gate_id: "moonrobo-simulation-preconditions",
    label: "Robot-facing simulation packet remains safety gated",
    owner_package: "src/adapters/moonrobo",
    readiness: if dossier.energy.decision == @mission.TraverseDecision::Allow {
      Ready
    } else {
      Blocked
    },
    proof_artifact: "output/moonrobo/first_trusted_square_handoffs.json",
    blocker: "terrain, route, illumination, and energy gates must all clear before physical execution",
    next_action: "use the selected-route clearance plan to record accepted evidence or action requirements before simulation",
  }
}

///|
fn moonbook_gate(_dossier : @site.SiteDossier) -> EvidenceGate {
  {
    gate_id: "moonbook-evidence-workspace",
    label: "Durable review workspace and transition ledger materialized",
    owner_package: "src/adapters/moonbook",
    readiness: Ready,
    proof_artifact: "output/moonbook/workspaces/first-trusted-square/",
    blocker: "none",
    next_action: "materialize the imported MoonClaw remediation task as MoonBook workspace evidence",
  }
}

///|
fn kernel_layers(dossier : @site.SiteDossier) -> Array[KernelLayer] {
  [
    {
      layer_id: "source-registry",
      label: "Source registry",
      owns: "official source candidates, acquisition plans, product selections, extraction manifests",
      source_contract: "checksummed source files and generated MoonBit mirrors",
      current_artifact: "src/dataset/manifest.mbt",
      readiness: Ready,
      next_output: "shorter standalone source catalog with only active lunar modeling inputs",
    },
    {
      layer_id: "terrain-world",
      label: "Terrain world",
      owns: "DEM cells, terrain metrics, route-window fixtures, roughness and hazard derivations",
      source_contract: "LOLA byte-range CSV -> generated terrain fixture -> metrics",
      current_artifact: "src/terrain/generated_first_trusted_square_fixture.mbt",
      readiness: NeedsEvidence,
      next_output: "promoted DEM fixture for best 9x9 corridor window",
    },
    {
      layer_id: "mission-constraints",
      label: "Mission constraints",
      owns: "traverse, corridor, illumination, energy, route scoring",
      source_contract: "terrain metrics + ephemeris evidence + robot profile",
      current_artifact: "src/mission/traverse.mbt",
      readiness: if dossier.energy.decision == @mission.TraverseDecision::Allow {
        Ready
      } else {
        Blocked
      },
      next_output: "accepted-evidence transition capture for selected-route clearance",
    },
    {
      layer_id: "evidence-projection",
      label: "Evidence projection",
      owns: "MoonBook entries, review queue, MoonClaw tasks and receipts",
      source_contract: "typed MoonBit dossier -> materialized workspace files",
      current_artifact: "src/adapters/moonbook/export.mbt",
      readiness: Ready,
      next_output: "MoonBook materialization for imported MoonClaw remediation task",
    },
    {
      layer_id: "operator-viewer",
      label: "Operator viewer",
      owns: "renderer-neutral layer view models and Rabbita lunar inspection UI",
      source_contract: "site dossier -> terrain/hazard/route layer view state",
      current_artifact: "src/ui/types.mbt + src/ui/rabbita_moon/page.mbt",
      readiness: Ready,
      next_output: "imported transition summaries in route and robot readiness surfaces",
    },
  ]
}

///|
fn suite_boundaries() -> Array[SuiteBoundary] {
  [
    {
      product_id: "MoonBook",
      role: "durable lunar evidence memory",
      consumes: "site dossiers, source manifests, reviews, generated payloads",
      emits: "review queues, accepted evidence, operator notes",
      boundary_rule: "MoonMoon computes world claims; MoonBook stores and reviews them",
    },
    {
      product_id: "MoonClaw",
      role: "bounded modeling worker",
      consumes: "explicit task packets and acceptance criteria",
      emits: "receipts, source upgrades, generated artifacts",
      boundary_rule: "MoonClaw may propose and execute; MoonMoon validates before model state changes",
    },
    {
      product_id: "MoonTown",
      role: "standing-goal and multi-agent coordinator",
      consumes: "MoonMoon build queue and evidence gates",
      emits: "prioritized runs, cadence, escalation, cross-book routing",
      boundary_rule: "MoonTown schedules work; MoonMoon owns lunar physics and robot constraints",
    },
    {
      product_id: "MoonRobo",
      role: "physical robot boundary",
      consumes: "simulation precondition packets only",
      emits: "telemetry, replay, execution proof after safety gates clear",
      boundary_rule: "MoonMoon never commands hardware; it emits gated robot-facing evidence",
    },
    {
      product_id: "Moondesk",
      role: "human operating surface",
      consumes: "MoonBook workspace, MoonMoon viewer state, MoonClaw/MoonRobo packets",
      emits: "operator reviews, approvals, annotations, task launches",
      boundary_rule: "Moondesk is a control surface, not the lunar model owner",
    },
  ]
}

///|
fn rabbita_ui_artifact() -> String {
  "output/ui/rabbita/first_trusted_square.html"
}

///|
fn rabbita_mission_evidence_check_path() -> String {
  "scripts/check_rabbita_mission_evidence_queue.py"
}

///|
fn build_queue(dossier : @site.SiteDossier) -> Array[BuildTask] {
  let best = dossier.corridor_scan[0]
  let route_promoted = best.selected_route_id != ""
  [
    {
      task_id: "promote-best-9x9-route-fixture",
      priority: if route_promoted {
        45
      } else {
        100
      },
      lane: TerrainLane,
      title: "Promote the best measured 9x9 corridor window into terrain and route model",
      outcome: if route_promoted {
        "MoonMoon has a named route fixture for the best measured corridor window"
      } else {
        "MoonMoon stops reporting a discovered but unpromoted corridor window"
      },
      depends_on: [
        "data/sources/lro_lola/first_trusted_square_corridor_scan_v2.csv",
      ],
      evidence: [
        best.scan_id,
        best.window_id,
        "src/terrain/generated_first_trusted_square_fixture.mbt",
      ],
      done_when: if route_promoted {
        "done: \{best.window_id} now selects \{best.selected_route_id}"
      } else {
        "the \{best.window_id} DEM fixture, route candidate, MoonBook entry, MoonClaw receipt, and MoonRobo handoff all reference one route id"
      },
    },
    {
      task_id: "replace-missing-power-window",
      priority: if dossier.power_window_evidence.has_time_window_ephemeris {
        40
      } else {
        95
      },
      lane: DataLane,
      title: "Compute the pinned-source power window with ephemeris-backed evidence",
      outcome: "route decisions become time-window aware instead of permanently blocked by zero verified Wh",
      depends_on: [
        "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
      ],
      evidence: [
        dossier.power_window_evidence.evidence_id,
        dossier.power_window_evidence.source_status,
      ],
      done_when: if dossier.power_window_evidence.has_time_window_ephemeris {
        "done: power evidence names exact source files, SHA-256 checksums, sunlit hours, dark hours, and available Wh"
      } else {
        "power evidence names exact source files, SHA-256 checksums, sunlit hours, dark hours, and available Wh"
      },
    },
    {
      task_id: "rabbita-layer-view-model",
      priority: 35,
      lane: ViewerLane,
      title: "Build the renderer-neutral lunar layer view model before UI decoration",
      outcome: "Rabbita can render elevation, hazard, route, and evidence state from one typed model",
      depends_on: ["src/site/site.mbt", "src/ui/types.mbt"],
      evidence: [
        "src/ui/types.mbt", "src/ui/view_model.mbt", "output/ui/first_trusted_square_view.json",
      ],
      done_when: "done: renderer-neutral UI model exposes layers, selected tile inspector, source panel, scorecard, and route overlays",
    },
    {
      task_id: "moonrobo-simulation-contract-v2",
      priority: 30,
      lane: RobotLane,
      title: "Tighten MoonRobo packet semantics around simulation, replay, and hardware denial",
      outcome: "physical execution stays impossible until route, power, and review gates are all accepted",
      depends_on: ["src/adapters/moonrobo/handoff.mbt"],
      evidence: [
        "src/adapters/moonrobo/handoff.mbt", "output/moonrobo/first_trusted_square_handoffs.json",
      ],
      done_when: "done: each packet distinguishes simulation-ready, replay-ready, and hardware-denied states",
    },
    {
      task_id: "moonbook-review-transition-log",
      priority: 30,
      lane: SuiteLane,
      title: "Add append-only operator review transitions for MoonBook evidence",
      outcome: "MoonBook can record human review movement without mutating MoonMoon source facts",
      depends_on: ["src/adapters/moonbook/export.mbt"],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/review_queue.json", "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
      ],
      done_when: "done: review transitions include reviewer identity, timestamp policy, accepted/rejected state changes, and immutable source evidence references",
    },
    {
      task_id: "rabbita-browser-inspection-surface",
      priority: 25,
      lane: ViewerLane,
      title: "Build the browser-facing Rabbita lunar inspection surface",
      outcome: "Operators can inspect terrain, hazard, route, source, and review state from the generated view model",
      depends_on: [
        "src/ui/view_model.mbt", "output/ui/first_trusted_square_view.json", "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
      ],
      evidence: [
        "src/ui/types.mbt",
        "src/ui/rabbita_moon/page.mbt",
        rabbita_ui_artifact(),
      ],
      done_when: "done: Rabbita renders selectable cells, layer toggles, route overlays, source evidence, and MoonBook review status in one browser-facing inspection view",
    },
    {
      task_id: "mission-simulation-readiness-gate",
      priority: 20,
      lane: MissionLane,
      title: "Make simulation readiness a single mission-owned gate",
      outcome: "MoonRobo simulation packets depend on one reviewable mission readiness checklist instead of scattered route, power, and review blockers",
      depends_on: [
        "src/mission/readiness.mbt", "src/adapters/moonrobo/handoff.mbt", "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
      ],
      evidence: [
        "output/site/first_trusted_square.json", "output/moonrobo/first_trusted_square_handoffs.json",
      ],
      done_when: "done: selected route readiness names terrain, corridor, illumination, energy, MoonBook review, and robot-simulation status with one explicit allow/block result",
    },
    {
      task_id: "selected-route-blocker-clearance",
      priority: 20,
      lane: MissionLane,
      title: "Clear the selected-route blockers that keep simulation denied",
      outcome: "The primary route can move from blocked handoff evidence toward a reviewable simulation packet",
      depends_on: [
        "src/mission/readiness.mbt", "src/mission/clearance.mbt", "output/moonrobo/first_trusted_square_handoffs.json",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_handoffs.json", "output/moonbook/workspaces/first-trusted-square/review_queue.json",
      ],
      done_when: "done: selected northeast-stepout route has explicit clearance actions for terrain grade, illumination confidence, energy margin, and MoonBook review",
    },
    {
      task_id: "operator-clearance-transition-capture",
      priority: 20,
      lane: SuiteLane,
      title: "Let operator review transitions drive selected-route clearance status",
      outcome: "MoonBook accepted evidence can move clearance items from action-required toward accepted-evidence without changing source facts",
      depends_on: [
        "src/mission/clearance.mbt", "src/adapters/moonbook/export.mbt", "src/ui/rabbita_moon/page.mbt",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
        rabbita_ui_artifact(),
      ],
      done_when: "done: imported review transitions can accept/reject the selected-route terrain, illumination, energy, and MoonBook clearance items",
    },
    {
      task_id: "rabbita-clearance-review-controls",
      priority: 20,
      lane: ViewerLane,
      title: "Add Rabbita controls for selected-route clearance review decisions",
      outcome: "Operators can author accept, reject, or request-evidence transitions against the four selected-route clearance items from the browser surface",
      depends_on: [
        "src/ui/rabbita_moon/page.mbt", "src/adapters/moonbook/export.mbt", "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
      ],
      evidence: [
        rabbita_ui_artifact(),
        "output/moonbook/workspaces/first-trusted-square/review_queue.json",
      ],
      done_when: "done: Rabbita can emit an importable review transition for each selected-route terrain, illumination, energy, and MoonBook clearance item",
    },
    {
      task_id: "rabbita-transition-import-workflow",
      priority: 20,
      lane: SuiteLane,
      title: "Import Rabbita clearance review transitions into MoonBook regeneration",
      outcome: "Operator-exported clearance decisions can regenerate MoonBook, MoonRobo, and workspace payloads without manual source edits",
      depends_on: [
        "src/adapters/moonbook/export.mbt",
        "scripts/materialize_moonbook_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
        "output/moonrobo/first_trusted_square_handoffs.json",
      ],
      done_when: "done: a Rabbita-exported transition JSON file can be passed into the dossier build to update selected-route clearance status and materialized handoff evidence",
    },
    {
      task_id: "rabbita-import-feedback-state",
      priority: 20,
      lane: ViewerLane,
      title: "Initialize Rabbita clearance controls from imported review state",
      outcome: "Operators can reload imported clearance decisions without every item reverting to request-evidence controls",
      depends_on: [
        "src/ui/rabbita_moon/page.mbt", "scripts/import_rabbita_transitions.py",
        "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
      ],
      evidence: [
        rabbita_ui_artifact(),
        "data/fixtures/rabbita_clearance_transitions_mixed.json",
        "scripts/check_rabbita_feedback_state.py",
      ],
      done_when: "done: Rabbita renders accepted, rejected, and request-evidence imported states from the embedded MoonBook review queue and transitions",
    },
    {
      task_id: "moonrobo-imported-clearance-readiness-preview",
      priority: 20,
      lane: RobotLane,
      title: "Project imported clearance decisions into a MoonRobo readiness preview",
      outcome: "Accepted operator clearance can be inspected as robot-facing readiness evidence while hardware authority stays denied",
      depends_on: [
        "scripts/import_rabbita_transitions.py", "src/adapters/moonrobo/handoff.mbt",
        "output/moonrobo/first_trusted_square_handoffs.json",
      ],
      evidence: [
        "data/fixtures/rabbita_clearance_transitions_accept.json", "output/moonrobo/first_trusted_square_handoffs.json",
        "scripts/check_moonrobo_readiness_preview.py",
      ],
      done_when: "done: the all-accepted transition fixture regenerates a MoonRobo preview packet showing selected-route clearance allowed while physical execution remains denied until mission readiness gates clear",
    },
    {
      task_id: "moonrobo-clearance-gap-report",
      priority: 20,
      lane: RobotLane,
      title: "Report remaining MoonRobo blockers after imported clearance is accepted",
      outcome: "Operators can see exactly which mission gates still block simulation after all selected-route clearance items are accepted",
      depends_on: [
        "scripts/import_rabbita_transitions.py", "scripts/check_moonrobo_readiness_preview.py",
        "output/moonrobo/first_trusted_square_handoffs.json",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_readiness_preview.json", "data/fixtures/rabbita_clearance_transitions_accept.json",
        "scripts/check_moonrobo_readiness_preview.py",
      ],
      done_when: "done: the imported-clearance preview includes a concise blocker gap report naming remaining terrain, illumination, energy, MoonBook, and robot-simulation gates with evidence paths and next actions",
    },
    {
      task_id: "moonclaw-moonrobo-gap-remediation-task",
      priority: 20,
      lane: SuiteLane,
      title: "Emit a MoonClaw remediation task from MoonRobo readiness gaps",
      outcome: "The next modeling run can target remaining terrain, illumination, energy, MoonBook, and robot-simulation blockers from one task packet",
      depends_on: [
        "output/moonrobo/first_trusted_square_readiness_preview.json", "src/adapters/moonclaw",
        "scripts/import_rabbita_transitions.py",
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_moonrobo_gap_task.json", "output/moonrobo/first_trusted_square_readiness_preview.json",
        "scripts/check_moonclaw_gap_task.py",
      ],
      done_when: "done: a MoonClaw task packet consumes the imported-clearance gap report and names concrete remediation commands, acceptance checks, and robot-safety invariants",
    },
    {
      task_id: "moonbook-imported-moonclaw-gap-task-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize imported MoonClaw remediation task into MoonBook workspace",
      outcome: "Imported operator clearance produces durable MoonBook evidence for the MoonClaw task that resolves remaining MoonRobo blocker gaps",
      depends_on: [
        "output/moonclaw/first_trusted_square_moonrobo_gap_task.json", "scripts/materialize_moonbook_workspace.py",
        "scripts/import_rabbita_transitions.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-task.json",
        "output/moonclaw/first_trusted_square_moonrobo_gap_task.json",
      ],
      done_when: "done: imported transition builds materialize the MoonRobo gap remediation task into the MoonBook workspace index, manifest, and per-entry payloads",
    },
    {
      task_id: "moonclaw-gap-remediation-receipt-loop",
      priority: 20,
      lane: SuiteLane,
      title: "Close MoonRobo gap remediation with a MoonClaw receipt loop",
      outcome: "Each imported-clearance MoonRobo blocker gap can be proved cleared or carried forward with explicit evidence before simulation readiness changes",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-task.json",
        "output/moonrobo/first_trusted_square_readiness_preview.json", "scripts/import_rabbita_transitions.py",
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json", "scripts/check_moonclaw_gap_remediation_receipt.py",
      ],
      done_when: "done: MoonClaw emits a receipt for the imported gap task that maps every blocker gap to cleared evidence or a still-blocking next action while preserving MoonRobo hardware denial",
    },
    {
      task_id: "moonbook-imported-gap-receipt-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize imported MoonClaw gap receipts into MoonBook workspace",
      outcome: "Imported gap remediation receipts become durable MoonBook evidence next to the task and robot readiness preview they audit",
      depends_on: [
        "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json", "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-task.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-receipt.json",
        "scripts/check_moonbook_imported_gap_receipt_workspace.py",
      ],
      done_when: "done: imported transition builds materialize the MoonClaw gap remediation receipt into the MoonBook workspace index, manifest, and per-entry payloads",
    },
    {
      task_id: "rabbita-imported-gap-evidence-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Expose imported MoonClaw gap evidence in Rabbita",
      outcome: "Operators can inspect the imported MoonClaw task, receipt, remaining gaps, and hardware denial state without leaving the Rabbita review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-task.json",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-receipt.json",
        "src/ui/rabbita_moon/page.mbt",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders imported MoonClaw gap task and receipt summaries from embedded MoonBook evidence, including still-blocking gap count and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-gap-remediation-modeling-pass",
      priority: 20,
      lane: RobotLane,
      title: "Run the first modeling pass against MoonRobo blocker gaps",
      outcome: "The imported gap task drives bounded terrain, illumination, energy, MoonBook, and robot-simulation updates instead of only reporting blockers",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-task.json",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-receipt.json",
        "scripts/scan_lola_corridor.py", "scripts/compute_power_window.py",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_readiness_preview.json", "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json",
        "scripts/check_moonrobo_gap_remediation_modeling.py",
      ],
      done_when: "done: a bounded modeling pass consumes the imported gap task and either clears at least one MoonRobo blocker gap with regenerated evidence or records why every gap remains blocked",
    },
    {
      task_id: "moonbook-gap-remediation-modeling-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize MoonRobo remediation modeling pass into MoonBook",
      outcome: "The bounded gap remediation modeling pass becomes durable MoonBook evidence alongside the MoonClaw task and receipt",
      depends_on: [
        "output/moonrobo/first_trusted_square_gap_remediation_modeling.json", "scripts/materialize_moonbook_workspace.py",
        "scripts/import_rabbita_transitions.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/gap-remediation-modeling.json",
        "scripts/check_moonbook_gap_remediation_modeling_workspace.py",
      ],
      done_when: "done: imported transition builds materialize the MoonRobo gap remediation modeling pass into the MoonBook workspace index, manifest, and per-entry payloads",
    },
    {
      task_id: "moonrobo-illumination-local-horizon-remediation",
      priority: 20,
      lane: RobotLane,
      title: "Add local horizon evidence for the selected-route illumination gap",
      outcome: "MoonRobo illumination readiness is driven by explicit local terrain-shadow evidence instead of a standing blocker note",
      depends_on: [
        "data/sources/lro_lola/first_trusted_square_northeast_stepout_dem.csv", "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
        "src/mission",
      ],
      evidence: [
        "output/mission/first_trusted_square_northeast_stepout_horizon.json", "scripts/check_selected_route_horizon_model.py",
      ],
      done_when: "done: selected-route illumination readiness consumes a bounded local horizon model and records quantitative terrain-shadow evidence for why it remains blocked",
    },
    {
      task_id: "moonbook-selected-route-horizon-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize selected-route horizon evidence into MoonBook",
      outcome: "The selected-route local horizon artifact becomes durable MoonBook workspace evidence next to route, illumination, and robot readiness packets",
      depends_on: [
        "output/mission/first_trusted_square_northeast_stepout_horizon.json", "scripts/materialize_moonbook_workspace.py",
        "src/adapters/moonbook",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/northeast-stepout-horizon.json",
        "scripts/check_moonbook_selected_route_horizon_workspace.py",
      ],
      done_when: "done: selected-route horizon evidence is indexed, materialized, and validated in the MoonBook workspace",
    },
    {
      task_id: "moonrobo-selected-route-terrain-remediation",
      priority: 20,
      lane: RobotLane,
      title: "Remediate selected-route terrain blocker with bounded route evidence",
      outcome: "MoonRobo terrain readiness consumes a selected-route terrain remediation model instead of only carrying the original hard blocker forward",
      depends_on: [
        "data/sources/lro_lola/first_trusted_square_northeast_stepout_dem.csv", "output/moonrobo/first_trusted_square_readiness_preview.json",
        "scripts/scan_lola_corridor.py",
      ],
      evidence: [
        "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        "scripts/check_selected_route_terrain_remediation.py",
      ],
      done_when: "done: selected-route terrain readiness records quantitative grade and roughness evidence explaining why it remains blocked",
    },
    {
      task_id: "moonbook-selected-route-terrain-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize selected-route terrain remediation into MoonBook",
      outcome: "The selected-route terrain remediation artifact becomes durable MoonBook workspace evidence next to route, horizon, and robot readiness packets",
      depends_on: [
        "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        "scripts/materialize_moonbook_workspace.py", "src/adapters/moonbook",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/northeast-stepout-terrain-remediation.json",
        "scripts/check_moonbook_selected_route_terrain_workspace.py",
      ],
      done_when: "done: selected-route terrain remediation evidence is indexed, materialized, and validated in the MoonBook workspace",
    },
    {
      task_id: "moonrobo-energy-margin-remediation",
      priority: 20,
      lane: RobotLane,
      title: "Remediate selected-route energy blocker with bounded power-demand evidence",
      outcome: "MoonRobo energy readiness consumes an explicit remediation model for the negative energy margin instead of carrying a generic power blocker",
      depends_on: [
        "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        "output/mission/first_trusted_square_northeast_stepout_horizon.json", "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
        "src/mission",
      ],
      evidence: [
        "output/mission/first_trusted_square_energy_remediation.json", "scripts/check_energy_margin_remediation.py",
      ],
      done_when: "done: energy readiness records bounded selected-route power-demand evidence and quantitative margin evidence explaining why it remains blocked",
    },
    {
      task_id: "moonbook-energy-remediation-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize selected-route energy remediation into MoonBook",
      outcome: "The bounded selected-route energy remediation artifact becomes durable MoonBook workspace evidence next to route, horizon, terrain, and robot readiness packets",
      depends_on: [
        "output/mission/first_trusted_square_energy_remediation.json", "scripts/materialize_moonbook_workspace.py",
        "src/adapters/moonbook",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/energy-remediation.json",
        "scripts/check_moonbook_energy_remediation_workspace.py",
      ],
      done_when: "done: selected-route energy remediation evidence is indexed, materialized, and validated in the MoonBook workspace",
    },
    {
      task_id: "rabbita-remediation-evidence-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface selected-route remediation evidence in Rabbita",
      outcome: "Rabbita exposes the materialized terrain, horizon, and energy remediation artifacts from the selected-route review flow instead of only listing clearance status",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/northeast-stepout-terrain-remediation.json",
        "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/northeast-stepout-horizon.json",
        "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/energy-remediation.json",
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita review output links each selected-route remediation artifact and displays the quantitative blocker margin needed for operator review",
    },
    {
      task_id: "moonrobo-selected-route-simulation-review-packet",
      priority: 20,
      lane: RobotLane,
      title: "Assemble selected-route simulation review packet",
      outcome: "MoonRobo receives one review packet that joins selected-route terrain, horizon, energy remediation evidence, accepted clearance transitions, and hardware-denial invariants before any simulation handoff can be considered",
      depends_on: [
        rabbita_ui_artifact(),
        "output/moonrobo/first_trusted_square_handoffs.json",
        "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/energy-remediation.json",
        "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_simulation_review_packet.json", "scripts/check_moonrobo_simulation_review_packet.py",
      ],
      done_when: "done: selected-route simulation review packet names every blocking remediation margin, accepted clearance transition, and hardware-denied invariant",
    },
    {
      task_id: "moonbook-simulation-review-packet-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize selected-route simulation review packet into MoonBook",
      outcome: "The MoonRobo simulation review packet becomes durable MoonBook evidence beside the accepted clearance transitions, remediation margins, and hardware-denial invariants it audits",
      depends_on: [
        "output/moonrobo/first_trusted_square_simulation_review_packet.json", "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-review-packet.json",
        "scripts/check_moonbook_simulation_review_packet_workspace.py",
      ],
      done_when: "done: selected-route simulation review packet is indexed, materialized, and validated in the MoonBook workspace without changing hardware authority",
    },
    {
      task_id: "rabbita-simulation-review-packet-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface selected-route simulation review packet in Rabbita",
      outcome: "Operators can review the durable MoonRobo simulation packet, accepted clearance transitions, remediation margins, and hardware-denial invariants from Rabbita before any simulation handoff moves forward",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-review-packet.json",
        "output/moonrobo/first_trusted_square_simulation_review_packet.json", "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the simulation review packet summary with accepted clearance count, remediation margin count, and hardware-denial invariants from embedded MoonBook evidence",
    },
    {
      task_id: "moonrobo-simulation-review-closeout-decision",
      priority: 20,
      lane: RobotLane,
      title: "Emit selected-route simulation review closeout decision",
      outcome: "MoonRobo gets one explicit closeout decision derived from the simulation review packet, so blocked margins, accepted clearance evidence, and hardware-denial invariants produce a clear simulation-consumption result",
      depends_on: [
        "output/moonrobo/first_trusted_square_simulation_review_packet.json", "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-review-packet.json",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_simulation_review_decision.json", "scripts/check_moonrobo_simulation_review_decision.py",
      ],
      done_when: "done: selected-route simulation review decision records whether MoonRobo may consume the packet, why any blocker remains, and that hardware authority stays denied",
    },
    {
      task_id: "moonbook-simulation-review-decision-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize selected-route simulation review decision into MoonBook",
      outcome: "The MoonRobo closeout decision becomes durable MoonBook evidence beside the simulation packet it audits",
      depends_on: [
        "output/moonrobo/first_trusted_square_simulation_review_decision.json", "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-review-packet.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-review-decision.json",
        "scripts/check_moonbook_simulation_review_decision_workspace.py",
      ],
      done_when: "done: selected-route simulation review decision is indexed, materialized, and validated in the MoonBook workspace with hardware authority denied",
    },
    {
      task_id: "rabbita-simulation-review-decision-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface selected-route simulation review decision in Rabbita",
      outcome: "Operators can see the simulation consume/no-consume result, remaining blockers, and hardware denial state from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-review-decision.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the simulation review closeout decision with no-consume status, blocker counts, and HardwareDenied authority from embedded MoonBook evidence",
    },
    {
      task_id: "moonrobo-simulation-blocker-reduction-pass",
      priority: 20,
      lane: RobotLane,
      title: "Reduce selected-route simulation blockers from the closeout decision",
      outcome: "MoonRobo's no-consume decision stops carrying stale non-margin blockers once corridor, MoonBook review, and robot-simulation evidence have explicit closeout states",
      depends_on: [
        "output/moonrobo/first_trusted_square_simulation_review_decision.json", "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-review-decision.json",
        "src/mission/readiness.mbt",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_simulation_blocker_reduction.json",
        "scripts/check_moonrobo_simulation_blocker_reduction.py",
      ],
      done_when: "done: selected-route simulation decision records which non-margin blockers are closed by existing evidence, which remain active, and why hardware authority still stays denied",
    },
    {
      task_id: "moonbook-simulation-blocker-reduction-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize simulation blocker reduction into MoonBook",
      outcome: "The non-margin blocker reduction pass becomes durable MoonBook evidence next to the decision it updates",
      depends_on: [
        "output/moonrobo/first_trusted_square_simulation_blocker_reduction.json",
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-review-decision.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-blocker-reduction.json",
        "scripts/check_moonbook_simulation_blocker_reduction_workspace.py",
      ],
      done_when: "done: simulation blocker reduction is indexed, materialized, and validated in MoonBook with closed and active blocker counts preserved",
    },
    {
      task_id: "rabbita-simulation-blocker-reduction-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface simulation blocker reduction in Rabbita",
      outcome: "Operators can see the closed non-margin blockers, active robot-simulation blocker, and remaining remediation margins from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/simulation-blocker-reduction.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders blocker-reduction evidence with closed count 2, active count 1, active robot-simulation blocker, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-task-packet",
      priority: 20,
      lane: MissionLane,
      title: "Create a MoonClaw task packet for remaining remediation margins",
      outcome: "Terrain, local-horizon, and energy blockers become one executable evidence packet for collecting or modeling the next route-clearance inputs",
      depends_on: [
        "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        "output/mission/first_trusted_square_northeast_stepout_horizon.json", "output/mission/first_trusted_square_energy_remediation.json",
        "output/moonrobo/first_trusted_square_simulation_blocker_reduction.json",
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_task.json", "scripts/check_moonclaw_remediation_margin_task.py",
      ],
      done_when: "done: MoonClaw has one task packet that preserves all 3 active margin blockers, ranks terrain/horizon/energy work, and keeps hardware authority denied",
    },
    {
      task_id: "moonbook-remediation-margin-task-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin task into MoonBook",
      outcome: "The MoonClaw remediation-margin packet becomes durable workspace evidence linked to terrain, horizon, energy, and MoonRobo blocker reduction inputs",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_task.json", "output/moonbook/workspaces/first-trusted-square/index.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-task.json",
        "scripts/check_moonbook_remediation_margin_task_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin task with 3 active margin blockers and HardwareDenied authority preserved",
    },
    {
      task_id: "rabbita-remediation-margin-task-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin task in Rabbita",
      outcome: "Operators can see the MoonClaw margin task, three active remediation blockers, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-task.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin task with 3 active margins, terrain/horizon/energy blocker ids, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-receipt-loop",
      priority: 20,
      lane: SuiteLane,
      title: "Close remediation-margin task with a MoonClaw receipt loop",
      outcome: "Each active remediation-margin artifact can be carried forward or cleared with explicit evidence before MoonRobo simulation readiness changes",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_task.json", "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-task.json",
        "scripts/check_moonclaw_remediation_margin_task.py",
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_receipt.json", "scripts/check_moonclaw_remediation_margin_receipt.py",
      ],
      done_when: "done: MoonClaw emits a remediation-margin receipt that maps terrain, horizon, and energy artifacts to cleared evidence or still-blocking next actions while preserving HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-receipt-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin receipt in Rabbita",
      outcome: "Operators can inspect the remediation-margin receipt, still-blocking terrain/horizon/energy results, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-receipt.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin receipt with OpenMarginsCarriedForward state, 3 still-blocking margins, terrain/horizon/energy result ids, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-remediation-margin-modeling-pass",
      priority: 20,
      lane: RobotLane,
      title: "Run a bounded modeling pass against remediation margins",
      outcome: "MoonRobo can see whether the terrain, horizon, and energy margin receipt clears any blocker or must carry all margins forward under HardwareDenied authority",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-receipt.json",
        "output/moonclaw/first_trusted_square_remediation_margin_receipt.json", "src/adapters/moonrobo",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_remediation_margin_modeling.json",
        "scripts/check_moonrobo_remediation_margin_modeling.py",
      ],
      done_when: "done: MoonRobo emits a remediation-margin modeling pass that consumes the receipt, maps terrain/horizon/energy margins to cleared or still-blocking states, and preserves HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-modeling-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin modeling in Rabbita",
      outcome: "Operators can inspect the MoonRobo remediation-margin modeling pass, still-blocking terrain/horizon/energy results, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-modeling.json",
        "output/moonrobo/first_trusted_square_remediation_margin_modeling.json",
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the MoonRobo remediation-margin modeling pass with AllMarginsStillBlocking state, terrain/horizon/energy result ids, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-remediation-margin-clearance-projection",
      priority: 20,
      lane: RobotLane,
      title: "Project remediation-margin modeling into MoonRobo readiness",
      outcome: "MoonRobo can turn the modeling pass into an explicit no-consume projection that keeps simulation blocked while terrain, horizon, and energy margins remain open",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-modeling.json",
        "output/moonrobo/first_trusted_square_remediation_margin_modeling.json",
        "src/adapters/moonrobo",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_remediation_margin_projection.json",
        "scripts/check_moonrobo_remediation_margin_projection.py",
      ],
      done_when: "done: MoonRobo emits a remediation-margin projection that consumes the modeling pass, preserves no-consume simulation status, and keeps HardwareDenied authority while all three margins remain still-blocking",
    },
    {
      task_id: "moonbook-remediation-margin-projection-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin projection into MoonBook",
      outcome: "The MoonRobo no-consume remediation-margin projection becomes durable workspace evidence beside the modeling pass it consumes",
      depends_on: [
        "output/moonrobo/first_trusted_square_remediation_margin_projection.json",
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-modeling.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-projection.json",
        "scripts/check_moonbook_remediation_margin_projection_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin projection with no-consume simulation status, still-blocking margin ids, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-projection-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin projection in Rabbita",
      outcome: "Operators can inspect MoonRobo no-consume simulation status, still-blocking margin ids, and HardwareDenied authority from the Rabbita review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-projection.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin projection with NoConsumeSimulationBlocked status, AllMarginsStillBlocking source state, terrain/horizon/energy blockers, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-refresh-task",
      priority: 20,
      lane: SuiteLane,
      title: "Issue a refresh task from the no-consume remediation projection",
      outcome: "MoonClaw gets a new bounded task packet that targets the terrain, horizon, and energy evidence refreshes required before MoonRobo simulation can consume anything",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-projection.json",
        "output/moonrobo/first_trusted_square_remediation_margin_projection.json",
        "src/adapters/moonclaw",
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json",
        "scripts/check_moonclaw_remediation_margin_refresh_task.py",
      ],
      done_when: "done: MoonClaw emits a refresh task that consumes the no-consume projection, ranks terrain/horizon/energy evidence refreshes, and preserves HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-refresh-task-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin refresh task into MoonBook",
      outcome: "The projection-driven MoonClaw refresh packet becomes durable workspace evidence before Rabbita or downstream task loops inspect it",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json",
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-projection.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-task.json",
        "scripts/check_moonbook_remediation_margin_refresh_task_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin refresh task with ranked terrain/horizon/energy refreshes and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-refresh-task-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin refresh task in Rabbita",
      outcome: "Operators can inspect the projection-driven MoonClaw refresh order, target artifacts, commands, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-task.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin refresh task with NoConsumeSimulationBlocked status, ranked terrain/horizon/energy refreshes, target artifact paths, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-refresh-receipt-loop",
      priority: 20,
      lane: SuiteLane,
      title: "Close remediation-margin refresh task with a MoonClaw receipt",
      outcome: "Each projection-driven terrain, horizon, and energy refresh action can be proved executed or carried forward before MoonRobo remediation modeling changes",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-task.json",
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json",
        "scripts/check_moonclaw_remediation_margin_refresh_task.py",
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json",
        "scripts/check_moonclaw_remediation_margin_refresh_receipt.py",
      ],
      done_when: "done: MoonClaw emits a remediation-margin refresh receipt that maps each ranked terrain/horizon/energy refresh action to refreshed evidence or a still-blocking carry-forward while preserving HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-refresh-receipt-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin refresh receipt into MoonBook",
      outcome: "The projection-driven MoonClaw refresh receipt becomes durable workspace evidence before Rabbita or downstream modeling loops inspect it",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-task.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-receipt.json",
        "scripts/check_moonbook_remediation_margin_refresh_receipt_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin refresh receipt with terrain/horizon/energy result accounting and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-refresh-receipt-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin refresh receipt in Rabbita",
      outcome: "Operators can inspect the MoonClaw refresh receipt, still-blocking terrain/horizon/energy refresh results, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-receipt.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin refresh receipt with RefreshesCarriedForward state, 3 still-blocking refreshes, terrain/horizon/energy result ids, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-remediation-margin-refresh-modeling-pass",
      priority: 20,
      lane: RobotLane,
      title: "Run MoonRobo remediation-margin modeling from the refresh receipt",
      outcome: "MoonRobo can consume the MoonClaw refresh receipt as durable evidence and decide whether terrain, horizon, or energy margins remain blocked without changing hardware authority",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-receipt.json",
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json",
        "src/adapters/moonrobo",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json",
        "scripts/check_moonrobo_remediation_margin_refresh_modeling.py",
      ],
      done_when: "done: MoonRobo emits a remediation-margin refresh modeling pass that consumes the refresh receipt, maps terrain/horizon/energy refresh results to still-blocking or refreshed states, preserves no-consume simulation status, and keeps HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-refresh-modeling-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin refresh modeling into MoonBook",
      outcome: "The refresh modeling pass becomes durable MoonBook evidence beside the refresh receipt it audits",
      depends_on: [
        "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-receipt.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-modeling.json",
        "scripts/check_moonbook_remediation_margin_refresh_modeling_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin refresh modeling pass with still-blocking terrain/horizon/energy refresh results, no-consume simulation status, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-refresh-modeling-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin refresh modeling in Rabbita",
      outcome: "Operators can inspect the durable MoonRobo refresh modeling pass, still-blocking terrain/horizon/energy results, no-consume simulation status, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-modeling.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin refresh modeling pass with AllRefreshesStillBlocking state, terrain/horizon/energy refresh result ids, no-consume simulation status, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-remediation-margin-refresh-projection",
      priority: 20,
      lane: RobotLane,
      title: "Project refresh modeling into MoonRobo no-consume readiness",
      outcome: "MoonRobo turns the refresh modeling pass into an explicit projection that keeps simulation consumption blocked until terrain, horizon, and energy refresh evidence clears",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-modeling.json",
        rabbita_ui_artifact(),
        "src/adapters/moonrobo",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
        "scripts/check_moonrobo_remediation_margin_refresh_projection.py",
      ],
      done_when: "done: MoonRobo emits a remediation-margin refresh projection that consumes the refresh modeling pass, preserves AllRefreshesStillBlocking and no-consume simulation status, names the terrain/horizon/energy refresh blockers, and keeps HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-refresh-projection-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin refresh projection into MoonBook",
      outcome: "The refresh no-consume projection becomes durable MoonBook evidence beside the refresh modeling pass it consumes",
      depends_on: [
        "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-modeling.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-projection.json",
        "scripts/check_moonbook_remediation_margin_refresh_projection_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin refresh projection with AllRefreshesStillBlocking source state, no-consume simulation status, terrain/horizon/energy refresh blockers, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-refresh-projection-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin refresh projection in Rabbita",
      outcome: "Operators can inspect the durable MoonRobo refresh projection, no-consume simulation status, terrain/horizon/energy refresh blockers, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-projection.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin refresh projection with NoConsumeRefreshSimulationBlocked status, AllRefreshesStillBlocking source state, terrain/horizon/energy refresh blockers, no-consume simulation status, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-refresh-followup-task",
      priority: 20,
      lane: SuiteLane,
      title: "Issue the next remediation-margin refresh task from visible projection evidence",
      outcome: "MoonClaw gets the next bounded refresh packet only after the no-consume refresh projection is durable and visible in Rabbita",
      depends_on: [
        rabbita_ui_artifact(),
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-projection.json",
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json",
        "scripts/check_moonclaw_remediation_margin_refresh_followup_task.py",
      ],
      done_when: "done: MoonClaw emits the next remediation-margin refresh task from the durable refresh projection, preserving no-consume simulation status, terrain/horizon/energy blockers, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-refresh-followup-task-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin refresh follow-up task in Rabbita",
      outcome: "Operators can inspect the projection-derived MoonClaw follow-up refresh packet, blocking refresh ids, target commands, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-followup-task.json",
        "scripts/check_moonclaw_remediation_margin_refresh_followup_task.py",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin refresh follow-up task with NoConsumeRefreshSimulationBlocked status, AllRefreshesStillBlocking source state, terrain/horizon/energy refresh blockers, follow-up target commands, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-refresh-followup-receipt-loop",
      priority: 20,
      lane: SuiteLane,
      title: "Close remediation-margin refresh follow-up task with a MoonClaw receipt",
      outcome: "Each projection-derived terrain, horizon, and energy follow-up refresh action can be proved executed or carried forward before MoonRobo refresh modeling changes",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-followup-task.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json",
        "scripts/check_moonclaw_remediation_margin_refresh_followup_receipt.py",
      ],
      done_when: "done: MoonClaw emits a remediation-margin refresh follow-up receipt that maps each visible follow-up terrain/horizon/energy refresh action to refreshed evidence or a still-blocking carry-forward while preserving HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-refresh-followup-receipt-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin refresh follow-up receipt in Rabbita",
      outcome: "Operators can inspect the durable MoonClaw follow-up refresh receipt, still-blocking terrain/horizon/energy refresh results, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-followup-receipt.json",
        "scripts/check_moonclaw_remediation_margin_refresh_followup_receipt.py",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin refresh follow-up receipt with FollowupRefreshesCarriedForward state, 3 still-blocking follow-up refreshes, terrain/horizon/energy result ids, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-remediation-margin-refresh-followup-modeling-pass",
      priority: 20,
      lane: RobotLane,
      title: "Run MoonRobo modeling from the refresh follow-up receipt",
      outcome: "MoonRobo can consume the durable follow-up receipt and decide whether terrain, horizon, or energy refresh blockers remain before simulation consumption changes",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-followup-receipt.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json",
        "scripts/check_moonrobo_remediation_margin_refresh_followup_modeling.py",
      ],
      done_when: "done: MoonRobo emits a remediation-margin refresh follow-up modeling pass that consumes the follow-up receipt, maps terrain/horizon/energy follow-up refresh results to still-blocking or refreshed states, preserves no-consume simulation status, and keeps HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-refresh-followup-modeling-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin refresh follow-up modeling into MoonBook",
      outcome: "The MoonRobo follow-up modeling pass becomes durable evidence beside the MoonClaw follow-up receipt it audits",
      depends_on: [
        "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-refresh-followup-receipt.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-followup-modeling.json",
        "scripts/check_moonrobo_remediation_margin_refresh_followup_modeling.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin refresh follow-up modeling pass with AllFollowupRefreshesStillBlocking state, no-consume simulation status, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-refresh-followup-modeling-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin refresh follow-up modeling in Rabbita",
      outcome: "Operators can inspect the durable MoonRobo follow-up modeling pass, still-blocking terrain/horizon/energy follow-up results, no-consume simulation status, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-followup-modeling.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
        "scripts/check_moonrobo_remediation_margin_refresh_followup_modeling.py",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin refresh follow-up modeling pass with AllFollowupRefreshesStillBlocking state, terrain/horizon/energy follow-up result ids, no-consume simulation status, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-remediation-margin-refresh-followup-projection",
      priority: 20,
      lane: RobotLane,
      title: "Project follow-up refresh modeling into MoonRobo no-consume readiness",
      outcome: "MoonRobo turns the follow-up modeling pass into an explicit projection that keeps simulation consumption blocked until terrain, horizon, and energy follow-up refresh evidence clears",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-followup-modeling.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json",
        "scripts/check_moonrobo_remediation_margin_refresh_followup_projection.py",
      ],
      done_when: "done: MoonRobo emits a remediation-margin refresh follow-up projection that consumes the follow-up modeling pass, preserves AllFollowupRefreshesStillBlocking and no-consume simulation status, names the terrain/horizon/energy follow-up blockers, and keeps HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-refresh-followup-projection-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin refresh follow-up projection into MoonBook",
      outcome: "The follow-up no-consume projection becomes durable MoonBook evidence beside the follow-up modeling pass it consumes",
      depends_on: [
        "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json",
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-followup-modeling.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-followup-projection.json",
        "scripts/check_moonrobo_remediation_margin_refresh_followup_projection.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin refresh follow-up projection with AllFollowupRefreshesStillBlocking source state, no-consume simulation status, terrain/horizon/energy follow-up blockers, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-refresh-followup-projection-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin refresh follow-up projection in Rabbita",
      outcome: "Operators can inspect the durable follow-up projection, no-consume simulation status, terrain/horizon/energy follow-up blockers, and HardwareDenied authority from the review surface",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-followup-projection.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
        "scripts/check_moonrobo_remediation_margin_refresh_followup_projection.py",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin refresh follow-up projection with NoConsumeFollowupRefreshSimulationBlocked status, AllFollowupRefreshesStillBlocking source state, terrain/horizon/energy follow-up blockers, no-consume simulation status, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-remediation-margin-cycle-closeout-policy",
      priority: 20,
      lane: RobotLane,
      title: "Close the repeated remediation-margin refresh cycle with one policy packet",
      outcome: "MoonRobo stops growing one-off follow-up loops and emits one bounded closeout policy that names whether to retry, escalate, or freeze terrain/horizon/energy blockers",
      depends_on: [
        "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json",
        "scripts/check_moonrobo_remediation_margin_cycle_closeout.py",
      ],
      done_when: "done: MoonRobo emits a concise remediation-margin cycle closeout policy that consumes the first refresh and follow-up projections, preserves no-consume simulation and HardwareDenied authority, and gives terrain/horizon/energy blockers explicit retry/escalate/freeze dispositions",
    },
    {
      task_id: "moonbook-remediation-margin-cycle-closeout-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin cycle closeout into MoonBook",
      outcome: "The bounded closeout policy becomes durable workspace evidence beside the refresh projections it consumes",
      depends_on: [
        "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json",
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-refresh-followup-projection.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy.json",
        "scripts/check_moonrobo_remediation_margin_cycle_closeout.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin cycle closeout policy with no-consume status, retry/escalate/freeze dispositions, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-cycle-closeout-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin cycle closeout in Rabbita",
      outcome: "Operators can see the cycle closeout policy, three blocker dispositions, no-consume simulation status, and HardwareDenied authority before any new refresh task is issued",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin cycle closeout policy with NoConsumeCycleClosedForPolicy status, terrain/horizon/energy retry/escalate/freeze dispositions, no-consume simulation status, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-closeout-action-task",
      priority: 20,
      lane: SuiteLane,
      title: "Emit one bounded MoonClaw task from remediation-margin closeout",
      outcome: "The closeout policy turns into one operator-reviewable action packet with terrain escalation, horizon retry-with-new-evidence, and energy freeze dispositions instead of a new automatic refresh loop",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json",
        "scripts/check_moonclaw_remediation_margin_closeout_action_task.py",
      ],
      done_when: "done: MoonClaw emits one remediation-margin closeout action task that consumes the closeout policy, preserves no-consume simulation and HardwareDenied authority, and names the terrain escalate, horizon retry-with-new-evidence, and energy freeze actions with required evidence",
    },
    {
      task_id: "moonbook-remediation-margin-closeout-action-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize remediation-margin closeout action task into MoonBook",
      outcome: "The bounded MoonClaw closeout action task becomes durable workspace evidence beside the closeout policy it consumes",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json",
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy.json",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-closeout-action-task.json",
        "scripts/check_moonbook_remediation_margin_closeout_action_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the remediation-margin closeout action task with NeedsReview state, terrain escalate, horizon retry-with-new-evidence, energy freeze actions, no-consume simulation status, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-closeout-action-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface remediation-margin closeout action task in Rabbita",
      outcome: "Operators can review the bounded MoonClaw closeout action task, NeedsReview state, no-consume simulation status, and terrain/horizon/energy dispositions before any new remediation task is emitted",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-closeout-action-task.json",
        rabbita_ui_artifact(),
        "src/ui/rabbita_moon",
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the remediation-margin closeout action task with NeedsReview state, NoConsumeCycleClosedForPolicy source status, terrain escalate, horizon retry-with-new-evidence, energy freeze actions, no-consume simulation status, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-closeout-action-review-export",
      priority: 20,
      lane: ViewerLane,
      title: "Export operator review for remediation-margin closeout action",
      outcome: "Rabbita can emit an importable operator review transition for the closeout action task before MoonClaw schedules the explicit retry, escalation, and freeze work",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-closeout-action-task.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        rabbita_ui_artifact(),
        "scripts/check_rabbita_remediation_margin_closeout_action_review_export.py",
      ],
      done_when: "done: Rabbita exports an append-only closeout action review transition with Accept, RequestEvidence, and Defer choices, immutable MoonBook evidence refs, operator identity, timestamp policy, and no hardware authority change",
    },
    {
      task_id: "moonbook-remediation-margin-closeout-action-review-import",
      priority: 20,
      lane: SuiteLane,
      title: "Import remediation-margin closeout action review into MoonBook",
      outcome: "MoonBook can consume the Rabbita closeout-action review transition, preserve append-only evidence, and update the closeout action task review state without changing hardware authority",
      depends_on: [
        rabbita_ui_artifact(),
        "scripts/check_rabbita_remediation_margin_closeout_action_review_export.py",
        "scripts/import_rabbita_transitions.py",
      ],
      evidence: [
        "data/fixtures/rabbita_closeout_action_review_accept.json", "scripts/check_rabbita_closeout_action_review_import.py",
      ],
      done_when: "done: Imported closeout action review transitions accept, request evidence, or defer the MoonClaw closeout action task in MoonBook with immutable evidence refs, reviewer identity, timestamp policy, append-only semantics, and HardwareDenied authority preserved",
    },
    {
      task_id: "moonclaw-remediation-margin-reviewed-action-plan",
      priority: 20,
      lane: SuiteLane,
      title: "Emit reviewed remediation-margin action plan",
      outcome: "An accepted closeout-action review turns into one bounded MoonClaw action plan for terrain escalation, horizon retry-with-new-evidence, and energy freeze while preserving no-consume simulation and HardwareDenied authority",
      depends_on: [
        "data/fixtures/rabbita_closeout_action_review_accept.json", "scripts/check_rabbita_closeout_action_review_import.py",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-closeout-action-task.json",
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json",
        "scripts/check_moonclaw_remediation_margin_reviewed_action_plan.py",
      ],
      done_when: "done: MoonClaw emits a reviewed remediation-margin action plan only after an accepted closeout action review, carrying terrain escalation, horizon retry-with-new-evidence, and energy freeze actions with no automatic refresh loop and HardwareDenied authority preserved",
    },
    {
      task_id: "moonbook-remediation-margin-reviewed-action-plan-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize reviewed remediation-margin action plan into MoonBook",
      outcome: "The accepted MoonClaw reviewed action plan becomes durable MoonBook workspace evidence before terrain escalation, horizon retry, or energy freeze work is scheduled",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json",
        "scripts/check_moonclaw_remediation_margin_reviewed_action_plan.py", "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-action-plan.json",
        "scripts/check_moonbook_remediation_margin_reviewed_action_plan_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the reviewed remediation-margin action plan with accepted review provenance, terrain escalation, horizon retry-with-new-evidence, energy freeze actions, no automatic refresh loop, and HardwareDenied authority preserved",
    },
    {
      task_id: "rabbita-remediation-margin-reviewed-action-plan-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface reviewed remediation-margin action plan in Rabbita",
      outcome: "Operators can inspect the accepted MoonClaw reviewed action plan from MoonBook before terrain escalation, horizon retry, or energy freeze work is scheduled",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-action-plan.json",
        "scripts/check_moonbook_remediation_margin_reviewed_action_plan_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the reviewed remediation-margin action plan with accepted review provenance, terrain escalation, horizon retry-with-new-evidence, energy freeze actions, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-reviewed-work-items",
      priority: 20,
      lane: SuiteLane,
      title: "Emit reviewed remediation-margin work items",
      outcome: "The accepted reviewed action plan becomes three explicit MoonClaw work items for terrain escalation, horizon retry-with-new-evidence, and energy freeze without opening a refresh loop",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-action-plan.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json",
        "scripts/check_moonclaw_remediation_margin_reviewed_work_items.py",
      ],
      done_when: "done: MoonClaw emits three reviewed remediation-margin work items that preserve accepted review provenance, terrain escalation, horizon retry-with-new-evidence, energy freeze actions, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-reviewed-work-items-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize reviewed remediation-margin work items into MoonBook",
      outcome: "The three accepted MoonClaw reviewed work items become durable MoonBook workspace evidence before execution or downstream simulation review",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json",
        "scripts/check_moonclaw_remediation_margin_reviewed_work_items.py", "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-work-items.json",
        "scripts/check_moonbook_remediation_margin_reviewed_work_items_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the three reviewed remediation-margin work items with accepted review provenance, no automatic refresh loop, no simulation consumption, and HardwareDenied authority preserved",
    },
    {
      task_id: "rabbita-remediation-margin-reviewed-work-items-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface reviewed remediation-margin work items in Rabbita",
      outcome: "Operators can inspect the three accepted reviewed MoonClaw work items from MoonBook before execution or downstream simulation review",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-work-items.json",
        "scripts/check_moonbook_remediation_margin_reviewed_work_items_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the three reviewed remediation-margin work items with accepted review provenance, terrain escalation, horizon retry-with-new-evidence, energy freeze actions, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-reviewed-work-item-receipts",
      priority: 20,
      lane: SuiteLane,
      title: "Emit reviewed remediation-margin work item receipts",
      outcome: "Each accepted reviewed work item gets a MoonClaw receipt that records whether terrain escalation, horizon retry-with-new-evidence, and energy freeze remain pending or have fresh evidence",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-work-items.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json",
        "scripts/check_moonclaw_remediation_margin_reviewed_work_item_receipts.py",
      ],
      done_when: "done: MoonClaw emits reviewed remediation-margin work item receipts that preserve accepted review provenance, terrain escalation, horizon retry-with-new-evidence, energy freeze accounting, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-reviewed-work-item-receipts-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize reviewed remediation-margin work item receipts into MoonBook",
      outcome: "The three accepted MoonClaw reviewed work item receipts become durable MoonBook workspace evidence before fresh evidence execution or downstream simulation review",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json",
        "scripts/check_moonclaw_remediation_margin_reviewed_work_item_receipts.py",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-work-item-receipts.json",
        "scripts/check_moonbook_remediation_margin_reviewed_work_item_receipts_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the three reviewed remediation-margin work item receipts with pending fresh evidence state, accepted review provenance, no automatic refresh loop, no simulation consumption, and HardwareDenied authority preserved",
    },
    {
      task_id: "rabbita-remediation-margin-reviewed-work-item-receipts-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface reviewed remediation-margin work item receipts in Rabbita",
      outcome: "Operators can inspect the three accepted reviewed work item receipts from MoonBook before fresh evidence execution or downstream simulation review",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-work-item-receipts.json",
        "scripts/check_moonbook_remediation_margin_reviewed_work_item_receipts_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the three reviewed remediation-margin work item receipts with pending fresh evidence state, accepted review provenance, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-reviewed-fresh-evidence-task",
      priority: 20,
      lane: SuiteLane,
      title: "Emit reviewed remediation-margin fresh evidence task",
      outcome: "The three pending reviewed work item receipts become an explicit MoonClaw fresh-evidence task packet for terrain escalation, horizon retry-with-new-evidence, and energy freeze verification",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-work-item-receipts.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json",
        "scripts/check_moonclaw_remediation_margin_reviewed_fresh_evidence_task.py",
      ],
      done_when: "done: MoonClaw emits a reviewed remediation-margin fresh-evidence task that consumes pending work item receipts, preserves accepted review provenance, keeps no automatic refresh loop and no simulation consumption, and records HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-reviewed-fresh-evidence-task-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize reviewed remediation-margin fresh evidence task into MoonBook",
      outcome: "The reviewed fresh-evidence task becomes durable MoonBook workspace evidence before terrain escalation, horizon regeneration, or energy freeze verification runs",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json",
        "scripts/check_moonclaw_remediation_margin_reviewed_fresh_evidence_task.py",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-fresh-evidence-task.json",
        "scripts/check_moonbook_remediation_margin_reviewed_fresh_evidence_task_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the reviewed remediation-margin fresh-evidence task with source receipt provenance, pending terrain/horizon/energy actions, no automatic refresh loop, no simulation consumption, and HardwareDenied authority preserved",
    },
    {
      task_id: "rabbita-remediation-margin-reviewed-fresh-evidence-task-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface reviewed remediation-margin fresh evidence task in Rabbita",
      outcome: "Operators can inspect the accepted reviewed fresh-evidence task from MoonBook before terrain escalation, horizon regeneration, or energy freeze verification runs",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-fresh-evidence-task.json",
        "scripts/check_moonbook_remediation_margin_reviewed_fresh_evidence_task_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the reviewed remediation-margin fresh-evidence task with source receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-fresh-evidence-action-receipts",
      priority: 20,
      lane: SuiteLane,
      title: "Emit fresh-evidence action receipts",
      outcome: "Terrain escalation, local-horizon bounded regeneration, and energy freeze verification each produce an explicit MoonClaw receipt before reviewed work item receipt regeneration",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-reviewed-fresh-evidence-task.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json",
        "scripts/check_moonclaw_remediation_margin_fresh_evidence_action_receipts.py",
      ],
      done_when: "done: MoonClaw emits fresh-evidence action receipts that preserve source receipt provenance, record terrain/horizon/energy execution modes, keep no automatic refresh loop and no simulation consumption, and preserve HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-fresh-evidence-action-receipts-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize fresh-evidence action receipts into MoonBook",
      outcome: "Fresh-evidence action receipts become durable MoonBook workspace evidence before reviewed work item receipt regeneration or downstream simulation review",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json",
        "scripts/check_moonclaw_remediation_margin_fresh_evidence_action_receipts.py",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-fresh-evidence-action-receipts.json",
        "scripts/check_moonbook_remediation_margin_fresh_evidence_action_receipts_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes fresh-evidence action receipts with source receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-fresh-evidence-action-receipts-surface",
      priority: 20,
      lane: SuiteLane,
      title: "Surface fresh-evidence action receipts in Rabbita",
      outcome: "Operators can inspect the materialized fresh-evidence action receipts before reviewed work item receipt regeneration or downstream simulation review",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-fresh-evidence-action-receipts.json",
        "scripts/check_moonbook_remediation_margin_fresh_evidence_action_receipts_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the fresh-evidence action receipts with source receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no simulation consumption, pending reviewed work item state, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-remediation-margin-regenerated-reviewed-work-item-receipts",
      priority: 20,
      lane: SuiteLane,
      title: "Regenerate reviewed work item receipts from fresh evidence actions",
      outcome: "Fresh-evidence action receipts feed a new reviewed work item receipt pass before any downstream MoonRobo simulation review",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-fresh-evidence-action-receipts.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json",
        "scripts/check_moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts.py",
      ],
      done_when: "done: MoonClaw emits regenerated reviewed work item receipts that consume the fresh-evidence action receipts, preserve source receipt and review provenance, keep no automatic refresh loop and no simulation consumption, and preserve HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-regenerated-reviewed-work-item-receipts-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize regenerated reviewed work item receipts into MoonBook",
      outcome: "Regenerated reviewed work item receipts become durable MoonBook workspace evidence before Rabbita surface or downstream MoonRobo simulation review",
      depends_on: [
        "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json",
        "scripts/check_moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts.py",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts.json",
        "scripts/check_moonbook_remediation_margin_regenerated_reviewed_work_item_receipts_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes regenerated reviewed work item receipts with source action receipt provenance, source receipt and review provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-regenerated-reviewed-work-item-receipts-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface regenerated reviewed work item receipts in Rabbita",
      outcome: "Operators can inspect the materialized regenerated reviewed work item receipts before downstream MoonRobo simulation review",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts.json",
        "scripts/check_moonbook_remediation_margin_regenerated_reviewed_work_item_receipts_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders regenerated reviewed work item receipts with source action receipt provenance, source receipt and review provenance, terrain/horizon/energy execution modes, pending fresh evidence state, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-remediation-margin-regenerated-receipt-readiness-gate",
      priority: 20,
      lane: RobotLane,
      title: "Gate MoonRobo readiness on regenerated reviewed work item receipts",
      outcome: "MoonRobo can see that regenerated reviewed work item receipts still block simulation until terrain, horizon, and energy evidence checks pass",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts.json",
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.json",
        "scripts/check_moonrobo_remediation_margin_regenerated_receipt_readiness.py",
      ],
      done_when: "done: MoonRobo readiness records the regenerated reviewed work item receipts as pending fresh evidence, keeps simulation consumption blocked, preserves terrain/horizon/energy execution modes, and keeps HardwareDenied authority",
    },
    {
      task_id: "moonbook-remediation-margin-regenerated-receipt-readiness-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize regenerated receipt readiness into MoonBook",
      outcome: "MoonRobo regenerated receipt readiness becomes durable MoonBook evidence before Rabbita surface or any simulation review",
      depends_on: [
        "output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.json",
        "scripts/check_moonrobo_remediation_margin_regenerated_receipt_readiness.py",
        "scripts/materialize_moonbook_workspace.py",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-regenerated-receipt-readiness.json",
        "scripts/check_moonbook_remediation_margin_regenerated_receipt_readiness_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes regenerated receipt readiness with pending fresh evidence state, source action receipt provenance, terrain/horizon/energy execution modes, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-remediation-margin-regenerated-receipt-readiness-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface regenerated receipt readiness in Rabbita",
      outcome: "Operators can inspect the durable MoonRobo regenerated receipt readiness gate before any simulation review consumes it",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-regenerated-receipt-readiness.json",
        "scripts/check_moonbook_remediation_margin_regenerated_receipt_readiness_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders regenerated receipt readiness with pending fresh evidence state, source action receipt provenance, terrain/horizon/energy execution modes, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-regenerated-receipt-readiness-fresh-evidence-task",
      priority: 20,
      lane: SuiteLane,
      title: "Issue fresh-evidence task from regenerated receipt readiness",
      outcome: "MoonClaw converts the pending MoonRobo regenerated receipt readiness gate into explicit terrain, horizon, and energy fresh-evidence work before simulation review can resume",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-regenerated-receipt-readiness.json",
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json",
        "scripts/check_moonclaw_regenerated_receipt_readiness_fresh_evidence_task.py",
      ],
      done_when: "done: MoonClaw emits an explicit fresh-evidence task for the three pending regenerated receipts, preserving source action receipt provenance, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonbook-regenerated-receipt-readiness-fresh-evidence-task-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize regenerated readiness fresh-evidence task into MoonBook",
      outcome: "The MoonClaw fresh-evidence task emitted from regenerated receipt readiness becomes durable workspace evidence before Rabbita or downstream action receipts inspect it",
      depends_on: [
        "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json",
        "scripts/check_moonclaw_regenerated_receipt_readiness_fresh_evidence_task.py",
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-regenerated-receipt-readiness.json",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-task.json",
        "scripts/check_moonbook_regenerated_receipt_readiness_fresh_evidence_task_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes the regenerated readiness fresh-evidence task with source action receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-regenerated-receipt-readiness-fresh-evidence-task-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface regenerated readiness fresh-evidence task in Rabbita",
      outcome: "Operators can inspect the durable MoonClaw fresh-evidence task from regenerated receipt readiness before any downstream action receipts run",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-task.json",
        "scripts/check_moonbook_regenerated_receipt_readiness_fresh_evidence_task_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders the regenerated readiness fresh-evidence task with source action receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonclaw-regenerated-receipt-readiness-fresh-evidence-action-receipts",
      priority: 20,
      lane: SuiteLane,
      title: "Emit regenerated readiness fresh-evidence action receipts",
      outcome: "MoonClaw records operator-escalation, bounded-regeneration, and manual-freeze-verification receipts for the regenerated readiness fresh-evidence task before readiness is recomputed",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-task.json",
        rabbita_mission_evidence_check_path(),
      ],
      evidence: [
        "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json",
        "scripts/check_moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts.py",
      ],
      done_when: "done: MoonClaw emits fresh-evidence action receipts for the regenerated readiness task with source readiness gate provenance, source action receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonbook-regenerated-receipt-readiness-fresh-evidence-action-receipts-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize regenerated readiness action receipts into MoonBook",
      outcome: "Regenerated readiness fresh-evidence action receipts become durable MoonBook workspace evidence before Rabbita or readiness recomputation consumes them",
      depends_on: [
        "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json",
        "scripts/check_moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts.py",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-task.json",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-action-receipts.json",
        "scripts/check_moonbook_regenerated_receipt_readiness_fresh_evidence_action_receipts_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes regenerated readiness fresh-evidence action receipts with source readiness gate provenance, source action receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-regenerated-receipt-readiness-fresh-evidence-action-receipts-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface regenerated readiness action receipts in Rabbita",
      outcome: "Operators can inspect the durable regenerated readiness fresh-evidence action receipts and their source readiness/action receipt provenance before readiness recomputation proceeds",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-action-receipts.json",
        "scripts/check_moonbook_regenerated_receipt_readiness_fresh_evidence_action_receipts_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders regenerated readiness fresh-evidence action receipts with source readiness gate provenance, source action receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no simulation consumption, pending regenerated receipt state, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-regenerated-receipt-readiness-action-receipt-closeout",
      priority: 20,
      lane: SuiteLane,
      title: "Recompute regenerated receipt readiness from action receipts",
      outcome: "MoonRobo consumes visible fresh-evidence action receipts and records whether regenerated receipts remain pending or can advance without simulation consumption",
      depends_on: [
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-action-receipts.json",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout.json",
        "scripts/check_moonrobo_regenerated_receipt_readiness_action_receipt_closeout.py",
      ],
      done_when: "done: MoonRobo records regenerated receipt readiness after fresh-evidence action receipts with source readiness gate provenance, source action receipt provenance, pending/ready receipt accounting, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonbook-regenerated-receipt-readiness-action-receipt-closeout-workspace",
      priority: 20,
      lane: SuiteLane,
      title: "Materialize regenerated readiness action receipt closeout into MoonBook",
      outcome: "The MoonRobo closeout from regenerated readiness action receipts becomes durable MoonBook workspace evidence before Rabbita or any later simulation-review gate consumes it",
      depends_on: [
        "output/moonrobo/first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout.json",
        "scripts/check_moonrobo_regenerated_receipt_readiness_action_receipt_closeout.py",
        "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-action-receipts.json",
      ],
      evidence: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/regenerated-receipt-readiness-action-receipt-closeout.json",
        "scripts/check_moonbook_regenerated_receipt_readiness_action_receipt_closeout_workspace.py",
      ],
      done_when: "done: MoonBook indexes and materializes regenerated readiness action receipt closeout with source readiness gate provenance, source action receipt provenance, pending/ready receipt accounting, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "rabbita-regenerated-receipt-readiness-action-receipt-closeout-surface",
      priority: 20,
      lane: ViewerLane,
      title: "Surface regenerated readiness action receipt closeout in Rabbita",
      outcome: "Operators can inspect the durable MoonRobo closeout from regenerated readiness action receipts before any later simulation-review gate consumes it",
      depends_on: [
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/regenerated-receipt-readiness-action-receipt-closeout.json",
        "scripts/check_moonbook_regenerated_receipt_readiness_action_receipt_closeout_workspace.py",
        rabbita_ui_artifact(),
      ],
      evidence: [rabbita_ui_artifact(), rabbita_mission_evidence_check_path()],
      done_when: "done: Rabbita renders regenerated readiness action receipt closeout with source readiness gate provenance, source action receipt provenance, pending/ready receipt accounting, no automatic refresh loop, no simulation consumption, and HardwareDenied authority",
    },
    {
      task_id: "moonrobo-regenerated-receipt-readiness-closeout-simulation-gate",
      priority: 70,
      lane: SuiteLane,
      title: "Gate simulation review on regenerated readiness closeout",
      outcome: "MoonRobo consumes the visible regenerated readiness action receipt closeout and records whether simulation review remains blocked or can proceed without changing hardware authority",
      depends_on: [
        rabbita_ui_artifact(),
        rabbita_mission_evidence_check_path(),
        "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/regenerated-receipt-readiness-action-receipt-closeout.json",
      ],
      evidence: [
        "output/moonrobo/first_trusted_square_regenerated_receipt_readiness_closeout_simulation_gate.json",
        "scripts/check_moonrobo_regenerated_receipt_readiness_closeout_simulation_gate.py",
      ],
      done_when: "MoonRobo records simulation-review gate status from regenerated readiness action receipt closeout with pending/ready receipt accounting, no automatic refresh loop, no simulation consumption while receipts remain pending, and HardwareDenied authority",
    },
  ]
}

///|
pub fn system_kernel() -> MoonMoonKernel {
  let dossier = @site.first_trusted_square_dossier()
  {
    kernel_id: "moonmoon-standalone-kernel-v1",
    product_name: "MoonMoon",
    current_site_id: dossier.site.site_id,
    thesis: "A MoonBit-native lunar world model that turns source data into reviewable terrain, mission, energy, and robot-safety evidence before MoonRobo touches the physical world.",
    operating_rule: "Durable evidence first, explicit gates second, robot-facing packets last.",
    layers: kernel_layers(dossier),
    evidence_gates: [
      route_fixture_gate(dossier),
      power_gate(dossier),
      robot_gate(dossier),
      moonbook_gate(dossier),
    ],
    suite_boundaries: suite_boundaries(),
    build_queue: build_queue(dossier),
  }
}

///|
pub fn top_priority_task(kernel : MoonMoonKernel) -> BuildTask {
  let mut top = kernel.build_queue[0]
  for task in kernel.build_queue {
    if task.priority > top.priority {
      top = task
    }
  }
  top
}

///|
pub fn render_markdown(kernel : MoonMoonKernel) -> String {
  let top = top_priority_task(kernel)
  let mut text = "# \{kernel.product_name} Kernel\n\n"
  text += "\{kernel.thesis}\n\n"
  text += "Operating rule: \{kernel.operating_rule}\n\n"
  text += "Current site: \{kernel.current_site_id}\n\n"
  text += "## Layers\n\n"
  for layer in kernel.layers {
    text += "- \{layer.layer_id}: \{layer.label}\n"
    text += "  - readiness: \{readiness_state_label(layer.readiness)}\n"
    text += "  - owns: \{layer.owns}\n"
    text += "  - source contract: \{layer.source_contract}\n"
    text += "  - current artifact: \{layer.current_artifact}\n"
    text += "  - next output: \{layer.next_output}\n"
  }
  text += "\n## Evidence Gates\n\n"
  for gate in kernel.evidence_gates {
    text += "- \{gate.gate_id}: \{gate.label}\n"
    text += "  - package: \{gate.owner_package}\n"
    text += "  - readiness: \{readiness_state_label(gate.readiness)}\n"
    text += "  - proof: \{gate.proof_artifact}\n"
    text += "  - blocker: \{gate.blocker}\n"
    text += "  - next action: \{gate.next_action}\n"
  }
  text += "\n## Suite Boundaries\n\n"
  for boundary in kernel.suite_boundaries {
    text += "- \{boundary.product_id}: \{boundary.role}\n"
    text += "  - consumes: \{boundary.consumes}\n"
    text += "  - emits: \{boundary.emits}\n"
    text += "  - rule: \{boundary.boundary_rule}\n"
  }
  text += "\n## Build Queue\n\n"
  for task in kernel.build_queue {
    text += "- P\{task.priority} [\{build_lane_label(task.lane)}] \{task.task_id}: \{task.title}\n"
    text += "  - outcome: \{task.outcome}\n"
    text += "  - done when: \{task.done_when}\n"
  }
  text += "\n## Top Priority\n\n"
  text += "- \{top.task_id}: \{top.title}\n"
  text += "- done when: \{top.done_when}\n"
  text
}

///|
pub fn system_kernel_markdown() -> String {
  render_markdown(system_kernel())
}

///|
pub fn render_json(kernel : MoonMoonKernel) -> Json {
  kernel.to_json()
}

///|
pub fn system_kernel_json() -> Json {
  render_json(system_kernel())
}
