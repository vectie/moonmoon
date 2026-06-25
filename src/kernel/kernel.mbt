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
      "power-window source is \{power.source_status}; verified available energy remains zero"
    },
    next_action: "pin exact ephemeris source files, checksum them, and regenerate power-window evidence",
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
    next_action: "keep MoonRobo packets one-way until the world model proves route and power readiness",
  }
}

///|
fn moonbook_gate(_dossier : @site.SiteDossier) -> EvidenceGate {
  {
    gate_id: "moonbook-evidence-workspace",
    label: "Durable review workspace materialized",
    owner_package: "src/adapters/moonbook",
    readiness: Ready,
    proof_artifact: "output/moonbook/workspaces/first-trusted-square/",
    blocker: "none",
    next_action: "add editable reviewer identity and append-only review transitions",
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
      next_output: "ephemeris-backed power gate and promoted route scoring",
    },
    {
      layer_id: "evidence-projection",
      label: "Evidence projection",
      owns: "MoonBook entries, review queue, MoonClaw tasks and receipts",
      source_contract: "typed MoonBit dossier -> materialized workspace files",
      current_artifact: "src/adapters/moonbook/export.mbt",
      readiness: Ready,
      next_output: "operator-authored review transitions",
    },
    {
      layer_id: "operator-viewer",
      label: "Operator viewer",
      owns: "renderer-neutral layer view models and Rabbita lunar inspection UI",
      source_contract: "site dossier -> terrain/hazard/route layer view state",
      current_artifact: "planned src/ui/",
      readiness: Planned,
      next_output: "first terrain layer view model before any decorative viewer",
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
  [
    {
      task_id: "promote-best-9x9-route-fixture",
      priority: 100,
      lane: TerrainLane,
      title: "Promote the best measured 9x9 corridor window into terrain and route model",
      outcome: "MoonMoon stops reporting a discovered but unpromoted corridor window",
      depends_on: [
        "data/sources/lro_lola/first_trusted_square_corridor_scan_v2.csv",
      ],
      evidence: [
        best.scan_id,
        best.window_id,
        "src/terrain/generated_first_trusted_square_fixture.mbt",
      ],
      done_when: "the \{best.window_id} DEM fixture, route candidate, MoonBook entry, MoonClaw receipt, and MoonRobo handoff all reference one route id",
    },
    {
      task_id: "replace-missing-power-window",
      priority: 95,
      lane: DataLane,
      title: "Replace the missing-source power window with ephemeris-backed evidence",
      outcome: "route decisions become time-window aware instead of permanently blocked by zero verified Wh",
      depends_on: [
        "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
      ],
      evidence: [
        dossier.power_window_evidence.evidence_id,
        dossier.power_window_evidence.source_status,
      ],
      done_when: "power evidence names exact source files, SHA-256 checksums, sunlit hours, dark hours, and available Wh",
    },
    {
      task_id: "rabbita-layer-view-model",
      priority: 85,
      lane: ViewerLane,
      title: "Build the renderer-neutral lunar layer view model before UI decoration",
      outcome: "Rabbita can render elevation, hazard, route, and evidence state from one typed model",
      depends_on: ["src/site/site.mbt"],
      evidence: ["site dossier JSON", "terrain grid JSON"],
      done_when: "a UI package can inspect one site without parsing MoonBook or mission internals",
    },
    {
      task_id: "moonrobo-simulation-contract-v2",
      priority: 80,
      lane: RobotLane,
      title: "Tighten MoonRobo packet semantics around simulation, replay, and hardware denial",
      outcome: "physical execution stays impossible until route, power, and review gates are all accepted",
      depends_on: ["src/adapters/moonrobo/handoff.mbt"],
      evidence: [
        "MoonRobo handoff JSON", "energy assessment", "route candidate",
      ],
      done_when: "each packet distinguishes simulation-ready, replay-ready, and hardware-denied states",
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
