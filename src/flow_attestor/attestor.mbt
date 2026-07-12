///|
fn object(value : Json, label : String) -> Map[String, Json] raise {
  match value {
    Object(fields) => fields
    _ => fail("MoonMoon Flow attestor requires \{label} to be an object")
  }
}

///|
fn string_field(fields : Map[String, Json], name : String) -> String raise {
  match fields.get(name) {
    Some(String(value)) if !value.trim().is_empty() => value
    _ => fail("MoonMoon Flow attestor requires \{name}")
  }
}

///|
fn number_field(fields : Map[String, Json], name : String) -> Double raise {
  match fields.get(name) {
    Some(Number(value, ..)) => value
    _ => fail("MoonMoon Flow attestor requires numeric \{name}")
  }
}

///|
fn bool_field(fields : Map[String, Json], name : String) -> Bool raise {
  match fields.get(name) {
    Some(True) => true
    Some(False) => false
    _ => fail("MoonMoon Flow attestor requires boolean \{name}")
  }
}

///|
fn array_field(fields : Map[String, Json], name : String) -> Array[Json] raise {
  match fields.get(name) {
    Some(Array(values)) if !values.is_empty() => values
    _ => fail("MoonMoon Flow attestor requires non-empty \{name}")
  }
}

///|
fn safe_ref(reference : String) -> Bool {
  let value = reference.trim().replace(old="\\", new="/")
  !value.is_empty() &&
  !value.has_prefix("/") &&
  !value.split("/").any(part => part.is_empty() || part == "..")
}

///|
fn scoped_path(workspace : String, reference : String) -> String raise {
  if !safe_ref(reference) {
    fail("MoonMoon Flow artifact must be workspace-relative")
  }
  @pathx.join(@pathx.normalize(workspace), reference)
}

///|
fn read_json(path : String) -> Json raise {
  @json.parse(@fsx.read_file_to_string(path))
}

///|
fn ensure_directory(path : String) -> Unit raise {
  if @fsx.path_exists(path) {
    return
  }
  let parent = @pathx.dirname(path).to_owned()
  if parent != path && !@fsx.path_exists(parent) {
    ensure_directory(parent)
  }
  @fsx.create_dir(path)
}

///|
fn write_json(path : String, value : Json) -> Unit raise {
  ensure_directory(@pathx.dirname(path).to_owned())
  @fsx.write_string_to_file(path, value.stringify(indent=2) + "\n")
}

///|
fn simulate_scenario(
  scenario : Json,
  initial_energy_wh : Double,
  reserve_energy_wh : Double,
) -> Json raise {
  let fields = object(scenario, "scenario")
  let scenario_id = string_field(fields, "scenario_id")
  let kind = string_field(fields, "kind")
  if kind != "nominal" && kind != "adverse" {
    fail("MoonMoon scenario kind must be nominal or adverse")
  }
  let seed = match fields.get("seed") {
    Some(Number(value, ..)) => value.to_int()
    _ => fail("MoonMoon scenario requires integer seed")
  }
  let steps = array_field(fields, "steps")
  let mut energy = initial_energy_wh
  let mut progress = 0.0
  let mut safe = true
  let traces : Array[Json] = []
  for index, step in steps {
    let step_fields = object(step, "scenario step")
    let energy_use = number_field(step_fields, "energy_use_wh")
    let progress_delta = number_field(step_fields, "progress_delta")
    if energy_use < 0.0 || progress_delta < 0.0 {
      fail("MoonMoon scenario deltas must be non-negative")
    }
    let hazard = bool_field(step_fields, "hazard")
    let recovery = match step_fields.get("recovery") {
      Some(String(value)) => value
      _ => ""
    }
    energy -= energy_use
    progress += progress_delta
    if energy < reserve_energy_wh || (hazard && recovery.trim().is_empty()) {
      safe = false
    }
    traces.push({
      "step": index,
      "energy_remaining_wh": energy,
      "progress": progress,
      "hazard": hazard,
      "recovery": recovery,
      "safe": safe,
    })
  }
  (
    {
      "scenario_id": scenario_id,
      "kind": kind,
      "seed": seed,
      "result": if safe && progress >= 1.0 {
        "accepted"
      } else {
        "correct-refusal"
      },
      "safe": safe,
      "progress": progress,
      "energy_remaining_wh": energy,
      "reserve_energy_wh": reserve_energy_wh,
      "trace": traces.to_json(),
    } : Json)
}

///|
pub fn attest(
  workspace : String,
  request_ref : String,
  result_ref : String,
  attestation_ref : String,
  attestor_id : String,
  draft_ref : String,
  final_ref : String,
) -> Unit raise {
  let request = read_json(scoped_path(workspace, request_ref))
  let request_fields = object(request, "request")
  if string_field(request_fields, "operation") != "simulate-mission" {
    fail("MoonMoon does not own the requested Flow operation")
  }
  let result = read_json(scoped_path(workspace, result_ref))
  let result_fields = object(result, "draft result")
  let draft = read_json(scoped_path(workspace, draft_ref))
  let draft_fields = object(draft, "simulation draft")
  if string_field(draft_fields, "contract_id") !=
    "moonmoon.scenario-evidence.v1" ||
    string_field(draft_fields, "product_id") != "moonmoon" {
    fail("MoonMoon simulation draft has the wrong identity")
  }
  let model = match draft_fields.get("simulation_model") {
    Some(value) => object(value, "simulation_model")
    None => fail("MoonMoon simulation draft requires simulation_model")
  }
  let initial_energy_wh = number_field(model, "initial_energy_wh")
  let reserve_energy_wh = number_field(model, "reserve_energy_wh")
  if initial_energy_wh <= reserve_energy_wh || reserve_energy_wh < 0.0 {
    fail("MoonMoon simulation energy bounds are invalid")
  }
  let scenarios = array_field(model, "scenarios")
  if !scenarios.any(scenario => {
      object(scenario, "scenario").get("kind") == Some(Json::string("nominal"))
    }) ||
    !scenarios.any(scenario => {
      object(scenario, "scenario").get("kind") == Some(Json::string("adverse"))
    }) {
    fail("MoonMoon requires both nominal and adverse scenarios")
  }
  let first = scenarios.map(scenario => {
    simulate_scenario(scenario, initial_energy_wh, reserve_energy_wh)
  })
  let replay = scenarios.map(scenario => {
    simulate_scenario(scenario, initial_energy_wh, reserve_energy_wh)
  })
  if first != replay {
    fail("MoonMoon deterministic replay diverged")
  }
  let limitations = array_field(draft_fields, "model_limitations")
  let uncertainty = array_field(draft_fields, "uncertainty")
  let final_artifact : Json = {
    "contract_id": "moonmoon.scenario-evidence.v1",
    "product_id": "moonmoon",
    "operation": "simulate-mission",
    "scenario_results": first.to_json(),
    "deterministic_replay": true,
    "model_limitations": limitations.to_json(),
    "uncertainty": uncertainty.to_json(),
    "physical_deployment": false,
    "physical_readiness": false,
    "claim_ceiling": "scenario-qualified",
  }
  write_json(scoped_path(workspace, final_ref), final_artifact)
  write_json(scoped_path(workspace, attestation_ref), {
    "contract_id": "moonflow.product-attestation.v1",
    "attestor_id": attestor_id,
    "product_id": "moonmoon",
    "request_id": string_field(request_fields, "request_id"),
    "result_id": string_field(result_fields, "result_id"),
    "output_digest": string_field(result_fields, "output_digest"),
    "accepted": true,
    "native_final_artifact": final_ref,
    "operation": "simulate-mission",
  })
}
