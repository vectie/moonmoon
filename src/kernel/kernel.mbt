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
        "src/ui/types.mbt", "src/ui/rabbita_moon/page.mbt", "output/ui/rabbita/first_trusted_square.html",
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
        "output/ui/rabbita/first_trusted_square.html",
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
        "output/ui/rabbita/first_trusted_square.html", "output/moonbook/workspaces/first-trusted-square/review_queue.json",
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
        "src/adapters/moonbook/export.mbt", "scripts/materialize_moonbook_workspace.py",
        "output/ui/rabbita/first_trusted_square.html",
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
        "output/ui/rabbita/first_trusted_square.html", "data/fixtures/rabbita_clearance_transitions_mixed.json",
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
      evidence: [
        "output/ui/rabbita/first_trusted_square.html", "scripts/check_rabbita_imported_gap_evidence_surface.py",
      ],
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
      priority: 70,
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
      done_when: "selected-route terrain readiness either clears against bounded local terrain evidence or records quantitative grade and roughness evidence explaining why it remains blocked",
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
