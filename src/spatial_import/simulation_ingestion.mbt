///|
pub(all) struct SimulationImportIssue {
  code : String
  message : String
} derive(Debug, Eq, ToJson)

///|
pub(all) struct SimulationSpatialInput {
  artifact_id : String
  artifact_digest : String
  engineering_parent_id : String
  engineering_parent_digest : String
  payload_ref : String
  units : String
  scale_to_meters : Double
  coordinate_system : String
  up_axis : String
  handedness : String
  transform_id : String
  assumptions : Array[String]
  declared_losses : Array[String]
  authority_envelope_id : String
  evidence_claim : String
} derive(Debug, Eq, ToJson)

///|
fn issue(
  code : String,
  message : String,
) -> Result[SimulationSpatialInput, SimulationImportIssue] {
  Err({ code, message })
}

///|
fn strings(values : Array[Json]) -> Array[String]? {
  let result : Array[String] = []
  for value in values {
    match value {
      String(text) => result.push(text)
      _ => return None
    }
  }
  Some(result)
}

///|
fn unit_scale(units : String) -> Double? {
  match units {
    "mm" => Some(0.001)
    "cm" => Some(0.01)
    "m" => Some(1.0)
    _ => None
  }
}

///|
fn valid_digest(value : String) -> Bool {
  value.has_prefix("sha256:") && value.length() == 71
}

///|
pub fn ingest_moonmold_simulation(
  text : String,
  expected_engineering_digest~ : String,
) -> Result[SimulationSpatialInput, SimulationImportIssue] {
  let parsed = @json.parse(text) catch {
    _ => return issue("invalid-json", "MoonMold envelope is not valid JSON")
  }
  match parsed {
    {
      "schema": String(schema),
      "manifest": {
        "contract_id": String(manifest_contract),
        "artifact_id": String(artifact_id),
        "representation": String(representation),
        "digest": String(artifact_digest),
        "payload_ref": String(payload_ref),
        "units": String(units),
        "coordinate_system": String(coordinate_system),
        "up_axis": String(up_axis),
        "handedness": String(handedness),
        "authority_envelope_id": String(authority_envelope_id),
        "assumptions": Array(assumption_values),
        "intended_consumers": Array(consumer_values),
        "forbidden_consumers": Array(forbidden_values),
        "claim_ceiling": String(claim_ceiling),
        ..
      },
      "transform": {
        "contract_id": String(transform_contract),
        "transform_id": String(transform_id),
        "parent_artifact_id": String(parent_artifact_id),
        "parent_digest": String(parent_digest),
        "parent_representation": String(parent_representation),
        "child_artifact_id": String(child_artifact_id),
        "child_digest": String(child_digest),
        "child_representation": String(child_representation),
        "lineage_relation": String(lineage_relation),
        "authority_ref": String(authority_ref),
        "declared_losses": Array(loss_values),
        ..
      },
      ..
    } => {
      let assumptions = match strings(assumption_values) {
        Some(value) => value
        None =>
          return issue(
            "invalid-string-array", "assumptions must contain strings",
          )
      }
      let consumers = match strings(consumer_values) {
        Some(value) => value
        None =>
          return issue("invalid-string-array", "consumers must contain strings")
      }
      let forbidden = match strings(forbidden_values) {
        Some(value) => value
        None =>
          return issue(
            "invalid-string-array", "forbidden consumers must contain strings",
          )
      }
      let losses = match strings(loss_values) {
        Some(value) => value
        None =>
          return issue(
            "invalid-string-array", "declared losses must contain strings",
          )
      }
      if schema != "moonmold-portable-ingestion-v1" ||
        manifest_contract != "moonmold.spatial-artifact.v1" ||
        transform_contract != "moonmold.representation-transform.v1" {
        return issue(
          "unsupported-contract", "portable MoonMold contract version is unsupported",
        )
      }
      if representation != "simulation-model" ||
        child_representation != "simulation-model" ||
        parent_representation != "engineering-model" ||
        lineage_relation != "physics-derived-from" {
        return issue(
          "wrong-simulation-lane", "MoonMoon accepts only simulation models derived from engineering geometry",
        )
      }
      if artifact_id != child_artifact_id || artifact_digest != child_digest {
        return issue(
          "child-lineage-mismatch", "manifest and transform child identity differ",
        )
      }
      if parent_digest != expected_engineering_digest {
        return issue(
          "stale-engineering-parent", "simulation parent is not the accepted engineering model",
        )
      }
      if !valid_digest(artifact_digest) || !valid_digest(parent_digest) {
        return issue(
          "invalid-digest", "artifact and parent digests must be sha256",
        )
      }
      if assumptions.is_empty() || losses.is_empty() {
        return issue(
          "missing-simulation-uncertainty", "simulation assumptions and representation losses must be explicit",
        )
      }
      if claim_ceiling != "simulation-evidence" {
        return issue(
          "claim-ceiling-mismatch", "simulation input cannot claim physical readiness or calibrated truth",
        )
      }
      if !consumers.contains("moonmoon") || forbidden.contains("moonmoon") {
        return issue(
          "consumer-policy-mismatch", "manifest does not authorize MoonMoon",
        )
      }
      if coordinate_system.trim().is_empty() ||
        (up_axis != "z" && up_axis != "y") ||
        (handedness != "right" && handedness != "left") {
        return issue(
          "unsupported-coordinate-frame", "coordinate system, up axis, and handedness must be explicit",
        )
      }
      let scale = match unit_scale(units) {
        Some(value) => value
        None =>
          return issue(
            "unsupported-units", "simulation units must be mm, cm, or m",
          )
      }
      if authority_envelope_id.trim().is_empty() ||
        authority_ref != authority_envelope_id {
        return issue(
          "authority-lineage-mismatch", "manifest and transform authority differ",
        )
      }
      if transform_id.trim().is_empty() || payload_ref.trim().is_empty() {
        return issue(
          "incomplete-spatial-contract", "transform and payload are required",
        )
      }
      Ok({
        artifact_id,
        artifact_digest,
        engineering_parent_id: parent_artifact_id,
        engineering_parent_digest: parent_digest,
        payload_ref,
        units,
        scale_to_meters: scale,
        coordinate_system,
        up_axis,
        handedness,
        transform_id,
        assumptions,
        declared_losses: losses,
        authority_envelope_id,
        evidence_claim: claim_ceiling,
      })
    }
    _ =>
      issue(
        "invalid-envelope", "required portable artifact or transform fields are missing",
      )
  }
}
