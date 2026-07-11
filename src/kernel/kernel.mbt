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
  ViewerLane
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
    ViewerLane => "viewer"
  }
}

///|
fn source_gate(dossier : @site.SiteDossier) -> EvidenceGate {
  let ready = dossier.validations.length() == dossier.datasets.length() &&
    dossier.catalog_evidence.length() >= 4
  {
    gate_id: "catalog-backed-source-evidence",
    label: "Cataloged lunar source evidence backs the model",
    owner_package: "src/data_core + src/lunar_data + src/terrain",
    readiness: if ready {
      Ready
    } else {
      Blocked
    },
    proof_artifact: "indexes/catalog.json + terrain fixture validation",
    blocker: if ready {
      "none"
    } else {
      "catalog evidence or terrain fixture validation is incomplete"
    },
    next_action: if ready {
      "connect more product labels directly to catalog refs"
    } else {
      "repair catalog evidence before changing terrain claims"
    },
  }
}

///|
fn route_gate(dossier : @site.SiteDossier) -> EvidenceGate {
  let best = dossier.corridor_scan[0]
  let promoted = best.selected_route_id != ""
  {
    gate_id: "promoted-corridor-route",
    label: "Best measured corridor window is promoted into route evidence",
    owner_package: "src/mission",
    readiness: if promoted {
      Ready
    } else {
      NeedsEvidence
    },
    proof_artifact: "src/mission/generated_first_trusted_square_corridor_scan.mbt#\{best.window_id}",
    blocker: if promoted {
      "none"
    } else {
      "best measured corridor has no selected route"
    },
    next_action: if promoted {
      "tighten the selected route blockers"
    } else {
      "bind the best corridor window to a named route candidate"
    },
  }
}

///|
fn energy_gate(dossier : @site.SiteDossier) -> EvidenceGate {
  let power = dossier.power_window_evidence
  {
    gate_id: "time-windowed-energy",
    label: "Power-window evidence is attached to route scoring",
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
      "missing time-windowed ephemeris evidence"
    },
    next_action: "review energy margin before allowing the selected traverse",
  }
}

///|
fn ui_gate(_dossier : @site.SiteDossier) -> EvidenceGate {
  {
    gate_id: "standalone-ui",
    label: "MoonBit-owned standalone operator UI renders from the view model",
    owner_package: "src/ui",
    readiness: Ready,
    proof_artifact: "src/ui/page.mbt",
    blocker: "none",
    next_action: "move to a Rabbita-style app only when interaction needs justify it",
  }
}

///|
fn kernel_layers(dossier : @site.SiteDossier) -> Array[KernelLayer] {
  [
    {
      layer_id: "source-registry",
      label: "Source registry",
      owns: "catalog refs, source manifests, checksums, acquisition notes, extraction candidates",
      source_contract: "lunar_data -> data_core catalog evidence -> product views",
      current_artifact: "src/site/catalog_evidence.mbt",
      readiness: Ready,
      next_output: "route remaining product evidence labels through catalog refs",
    },
    {
      layer_id: "terrain-world",
      label: "Terrain world",
      owns: "DEM cells, metrics, roughness, slope, hazard classification",
      source_contract: "LOLA evidence -> TerrainGrid -> TerrainMetrics",
      current_artifact: "src/terrain",
      readiness: if dossier.terrain.hazard_class ==
        @terrain.HazardClass::Blocked {
        Blocked
      } else {
        Ready
      },
      next_output: "promote a smoother corridor tile before expanding the world",
    },
    {
      layer_id: "mission-constraints",
      label: "Mission constraints",
      owns: "traverse scoring, corridor ranking, horizon, terrain remediation, energy gates",
      source_contract: "terrain metrics + power evidence -> route decision",
      current_artifact: "src/mission",
      readiness: if dossier.energy.decision == @mission.TraverseDecision::Allow {
        Ready
      } else {
        Blocked
      },
      next_output: "make the selected route clearance checklist smaller and stricter",
    },
    {
      layer_id: "site-dossier",
      label: "Site dossier",
      owns: "one inspectable lunar site model assembled from the domain packages",
      source_contract: "core + data_core + lunar_data + terrain + mission -> SiteDossier",
      current_artifact: "src/site/site.mbt",
      readiness: Ready,
      next_output: "add a second site only after the first site gates are clean",
    },
    {
      layer_id: "operator-view",
      label: "Operator view",
      owns: "renderer-neutral view model and standalone HTML inspection surface",
      source_contract: "SiteDossier -> TrustedSquareViewModel -> HTML/JSON",
      current_artifact: "src/ui",
      readiness: Ready,
      next_output: "Rabbita-style UI package when live controls outgrow static HTML",
    },
  ]
}

///|
fn catalog_artifact_ids(dossier : @site.SiteDossier) -> Array[String] {
  let ids : Array[String] = []
  for evidence in dossier.catalog_evidence {
    ids.push(
      "\{evidence.artifact.artifact_kind}/\{evidence.artifact.artifact_id}",
    )
  }
  ids
}

///|
fn build_queue(dossier : @site.SiteDossier) -> Array[BuildTask] {
  let best = dossier.corridor_scan[0]
  [
    {
      task_id: "clear-selected-route-blockers",
      priority: 100,
      lane: MissionLane,
      title: "Clear or explain the selected northeast-stepout route blockers",
      outcome: "the product can answer why the selected route is blocked without suite-side artifacts",
      depends_on: ["src/mission", "src/site/site.mbt"],
      evidence: [best.window_id, best.selected_route_id],
      done_when: "selected route blockers are represented by small MoonBit data structures and tests",
    },
    {
      task_id: "catalog-backed-product-evidence",
      priority: 80,
      lane: DataLane,
      title: "Keep product source evidence wired through catalog refs",
      outcome: "source labels and authority in the product come from catalog evidence, not standalone fixture constants",
      depends_on: ["src/data_core", "src/lunar_data", "src/site"],
      evidence: catalog_artifact_ids(dossier),
      done_when: "the UI source panel and kernel source gate name catalog artifacts and tests prove the refs",
    },
    {
      task_id: "moonmoon-ui-package",
      priority: 50,
      lane: ViewerLane,
      title: "Keep the live terrain viewer in the Rabbita UI package",
      outcome: "MoonMoon keeps browser behavior in an explicit Rabbita package without hiding assets in domain packages",
      depends_on: ["src/ui", "ui/rabbita-moon/main"],
      evidence: ["cd ui/rabbita-moon && moon build --target js"],
      done_when: "ui/rabbita-moon owns live browser behavior and src/ui remains renderer-neutral data",
    },
  ]
}

///|
pub fn system_kernel() -> MoonMoonKernel {
  let dossier = @site.first_trusted_square_dossier()
  {
    kernel_id: "moonmoon/kernel/standalone-v1",
    product_name: "MoonMoon",
    current_site_id: dossier.site.site_id,
    thesis: "MoonMoon is a MoonBit-native lunar terrain and mission model, not a generated artifact bundle.",
    operating_rule: "Domain claims live in typed MoonBit packages; generated outputs are build products, not source architecture.",
    layers: kernel_layers(dossier),
    evidence_gates: [
      source_gate(dossier),
      route_gate(dossier),
      energy_gate(dossier),
      ui_gate(dossier),
    ],
    build_queue: build_queue(dossier),
  }
}

///|
pub fn top_priority_task(kernel : MoonMoonKernel) -> BuildTask {
  let mut best = kernel.build_queue[0]
  for task in kernel.build_queue {
    if task.priority > best.priority {
      best = task
    }
  }
  best
}

///|
pub fn render_markdown(kernel : MoonMoonKernel) -> String {
  let mut text = "# \{kernel.product_name} Kernel\n\n"
  text += "\{kernel.thesis}\n\n"
  text += "Operating rule: \{kernel.operating_rule}\n\n"
  text += "## Layers\n\n"
  for layer in kernel.layers {
    text += "- \{layer.layer_id}: \{readiness_state_label(layer.readiness)}\n"
    text += "  - owns: \{layer.owns}\n"
    text += "  - artifact: \{layer.current_artifact}\n"
    text += "  - next: \{layer.next_output}\n"
  }
  text += "\n## Evidence Gates\n\n"
  for gate in kernel.evidence_gates {
    text += "- \{gate.gate_id}: \{readiness_state_label(gate.readiness)}\n"
    text += "  - owner: \{gate.owner_package}\n"
    text += "  - proof: \{gate.proof_artifact}\n"
    text += "  - blocker: \{gate.blocker}\n"
    text += "  - next: \{gate.next_action}\n"
  }
  text += "\n## Build Queue\n\n"
  for task in kernel.build_queue {
    text += "- P\{task.priority} \{task.task_id} [\{build_lane_label(task.lane)}]\n"
    text += "  - \{task.title}\n"
    text += "  - done: \{task.done_when}\n"
  }
  text
}

///|
pub fn render_json(kernel : MoonMoonKernel) -> Json {
  kernel.to_json()
}

///|
pub fn system_kernel_markdown() -> String {
  render_markdown(system_kernel())
}

///|
pub fn system_kernel_json() -> Json {
  render_json(system_kernel())
}
