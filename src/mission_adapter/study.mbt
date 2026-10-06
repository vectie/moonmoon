///|
/// A local, self-contained digital study. These records confer no device authority.
pub(all) struct StudySite {
  site_id : String
  revision : String
  frame : String
  distance_unit : String
  elevation_unit : String
  coverage : String
  uncertainty : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct StudySource {
  artifact_ref : String
  digest : String
  text : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct StudyAlternative {
  session_id : String
  design_ref : String
  result_ref : String
  provenance_ref : String
  replay_ref : String
  evaluation_ref : String
  baseline_json : String
  baseline_digest : String
  result_digest : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionStudy {
  contract_id : String
  study_id : String
  revision : String
  parent_digest : String
  site : StudySite
  sources : Array[StudySource]
  alternatives : Array[StudyAlternative]
  review_required : Bool
  physical_readiness : Bool
  limitations : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// The embedded JSON bytes, rather than a reserialization, are the export identity.
pub(all) struct StudyEnvelope {
  contract_id : String
  dossier_digest : String
  dossier_json : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) suberror StudyError {
  InvalidStudy(String)
} derive(Debug)

///|
fn study_need(condition : Bool, message : String) -> Unit raise StudyError {
  if !condition {
    raise InvalidStudy(message)
  }
}

///|
fn study_component(value : String) -> Bool {
  value.length() > 0 &&
  value.length() <= 100 &&
  value
  .iter()
  .all(ch => {
    (ch >= 'a' && ch <= 'z') ||
    (ch >= 'A' && ch <= 'Z') ||
    ch.is_ascii_digit() ||
    ch == '-' ||
    ch == '_'
  })
}

///|
fn study_read(path : String) -> String raise StudyError {
  let text = @fsx.read_file_to_string(path) catch {
    _ => raise InvalidStudy("Cannot read local study evidence: " + path)
  }
  study_need(
    @utf8.encode(text).length() <= 8388608,
    "Local study file exceeds the 8 MiB limit: " + path,
  )
  text
}

///|
fn[T : @json.FromJson] study_decode(text : String) -> T raise StudyError {
  @json.from_json(@json.parse(text)) catch {
    _ => raise InvalidStudy("Invalid typed study evidence")
  }
}

///|
fn study_source(
  sources : Array[StudySource],
  reference : String,
) -> StudySource raise StudyError {
  for source in sources {
    if source.artifact_ref == reference {
      return source
    }
  }
  raise InvalidStudy("Missing frozen evidence: " + reference)
}

///|
fn study_freeze(
  root : String,
  sources : Array[StudySource],
  reference : String,
) -> Unit raise StudyError {
  study_need(
    safe_relative_ref(reference) && !reference.contains(":"),
    "Unsafe local evidence reference",
  )
  if sources.any(source => source.artifact_ref == reference) {
    return
  }
  study_need(sources.length() < 64, "Study exceeds 64 frozen text sources")
  let text = study_read(root + "/" + reference)
  study_need(
    @utf8.encode(text).length() <= 1048576,
    "Source exceeds the 1 MiB text-source limit: " + reference,
  )
  sources.push({ artifact_ref: reference, digest: sha256_text(text), text, })
}

///|
fn study_baseline_json(
  site : StudySite,
  design : @robot_mission.RobotMissionDesign,
  terrain_digest : String,
) -> String {
  let value : Json = {
    "site": site,
    "terrain_digest": terrain_digest,
    "robot_artifact": design.robot_artifact,
    "calibration": design.environment.calibration,
    "cell_size_m": design.environment.cell_size_m,
    "whole_grid_status": design.environment.whole_grid_status,
    "whole_grid_max_neighbor_grade_deg": design.environment.whole_grid_max_neighbor_grade_deg,
  }
  value.stringify()
}

///|
fn study_check_alternative(
  study : MissionStudy,
  alternative : StudyAlternative,
) -> Unit raise StudyError {
  let sources = study.sources
  let design_source = study_source(sources, alternative.design_ref)
  let design : @robot_mission.RobotMissionDesign = study_decode(
    design_source.text,
  )
  let result_source = study_source(sources, alternative.result_ref)
  let result : @robot_mission.RobotMissionResult = study_decode(
    result_source.text,
  )
  let provenance : MissionProvenanceRecord = study_decode(
    study_source(sources, alternative.provenance_ref).text,
  )
  let replay : MissionReplayReceipt = study_decode(
    study_source(sources, alternative.replay_ref).text,
  )
  let evaluation : MissionEvaluationReport = study_decode(
    study_source(sources, alternative.evaluation_ref).text,
  )
  let terrain = study_source(sources, design.environment.terrain_source_path)
  let integration_source = study_source(
    sources,
    provenance.moonrobo_integration_receipt_ref,
  )
  let integration : MoonroboDigitalIntegrationReceipt = study_decode(
    integration_source.text,
  )
  match validate_integration_binding(integration, design) {
    Ok(_) => ()
    Err(error) => raise InvalidStudy(error.message)
  }
  let binding = design.robot_artifact
  if design.environment.calibration.qualified {
    ignore(
      study_source(sources, design.environment.calibration.authoritative_source),
    )
  }
  study_need(
    safe_relative_ref(binding.artifact_root),
    "Unsafe robot artifact root",
  )
  for
    (path, digest) in [
      (binding.robot_json_path, binding.robot_json_sha256),
      (binding.robot_urdf_path, binding.robot_urdf_sha256),
      (binding.validation_receipt_path, binding.validation_receipt_sha256),
    ] {
    let source = study_source(sources, binding.artifact_root + "/" + path)
    study_need(
      source.digest == "sha256:" + digest,
      "Robot artifact digest changed: " + path,
    )
  }
  let bridge = study_source(
    sources,
    binding.artifact_root + "/" + binding.bridge_config_path,
  )
  let bridge_json : Json = study_decode(bridge.text)
  study_need(
    match bridge_json {
      Object(fields) =>
        fields.get("mode") == Some(Json::string("simulation-only")) &&
        fields.get("physical_transport_enabled") == Some(Json::boolean(false)) &&
        fields.get("design_id") == Some(Json::string(binding.robot_id))
      _ => false
    },
    "Bridge must remain simulation-only",
  )
  study_need(
    provenance.contract_id == "moonmoon.mission-provenance.v1" &&
    provenance.session_id == alternative.session_id &&
    provenance.mission_design_ref == alternative.design_ref &&
    provenance.result_ref == alternative.result_ref &&
    provenance.replay_receipt_ref == alternative.replay_ref &&
    provenance.terrain_ref == design.environment.terrain_source_path,
    "Session provenance identity mismatch",
  )
  study_need(
    provenance.source_digests.length() >= 4 &&
    provenance.source_digests[0] == integration_source.digest &&
    provenance.source_digests[1] == design_source.digest &&
    provenance.source_digests[2] == terrain.digest &&
    provenance.source_digests[3] == result_source.digest,
    "Frozen source no longer matches the simulation provenance",
  )
  for reference in provenance.source_refs {
    ignore(study_source(sources, reference))
  }
  for evidence in provenance.dataset_evidence {
    study_need(
      study_source(sources, evidence.evidence_ref).digest == evidence.digest,
      "Dataset evidence digest changed",
    )
  }
  study_need(
    replay.contract_id == "moonmoon.mission-replay-receipt.v1" &&
    replay.session_id == alternative.session_id &&
    replay.design_id == design.design_id &&
    replay.scenario_id == design.scenario.scenario_id &&
    replay.seed == design.scenario.seed &&
    replay.byte_equivalent &&
    replay.required_replays == result.replay_count &&
    replay.required_replays == design.verification_criteria.replay.required_runs &&
    replay.completed_replays >= 2 &&
    replay.completed_replays >= replay.required_replays &&
    replay.first_result_ref == alternative.result_ref &&
    replay.first_result_digest == result_source.digest &&
    replay.replay_result_digest == result_source.digest &&
    study_source(sources, replay.replay_result_ref).text == result_source.text,
    "Replay evidence is incomplete or changed",
  )
  study_need(
    result == @robot_mission.simulate(design, terrain.text),
    "Frozen result does not replay from its exact design and terrain",
  )
  study_need(
    !result.physical_readiness && result.authority == "digital-only",
    "Study cannot grant physical authority",
  )
  study_need(
    evaluation ==
    evaluate_result(
      alternative.session_id,
      alternative.result_ref,
      result,
      alternative.provenance_ref,
      provenance,
      alternative.replay_ref,
      replay,
      evaluation.recorded_at,
    ),
    "Evaluation does not match frozen evidence",
  )
  study_need(
    alternative.result_digest == result_source.digest &&
    alternative.baseline_json ==
    study_baseline_json(study.site, design, terrain.digest) &&
    alternative.baseline_digest == sha256_text(alternative.baseline_json),
    "Alternative identity mismatch",
  )
}

///|
/// Validates integrity and replays each alternative without reading external sources.
pub fn validate_study(study : MissionStudy) -> Unit raise StudyError {
  study_need(
    study.contract_id == "moonmoon.mission-study.v1" &&
    study_component(study.study_id) &&
    study_component(study.revision),
    "Unsupported study schema or identity",
  )
  study_need(
    study.parent_digest == "" || digest_valid(study.parent_digest),
    "Invalid parent revision digest",
  )
  study_need(
    !study.physical_readiness && study.review_required,
    "Every imported revision requires digital review and has no physical authority",
  )
  let site = study.site
  study_need(
    site.site_id.trim() != "" &&
    site.revision.trim() != "" &&
    site.frame.trim() != "" &&
    site.distance_unit == "m" &&
    site.elevation_unit == "m" &&
    site.coverage.trim() != "" &&
    site.uncertainty.trim() != "",
    "Site needs identity, frame, metre units, coverage and uncertainty",
  )
  study_need(
    study.alternatives.length() >= 2 &&
    study.alternatives.length() <= 8 &&
    study.sources.length() <= 64,
    "Study requires 2–8 alternatives and at most 64 sources",
  )
  let seen : Map[String, Bool] = {}
  let mut size = 0
  for source in study.sources {
    study_need(
      safe_relative_ref(source.artifact_ref) &&
      !source.artifact_ref.contains(":"),
      "Sources must be local relative paths",
    )
    study_need(!seen.contains(source.artifact_ref), "Duplicate frozen source")
    seen[source.artifact_ref] = true
    let bytes = @utf8.encode(source.text).length()
    study_need(
      bytes <= 1048576 && source.digest == sha256_text(source.text),
      "Frozen source size or digest mismatch",
    )
    size += bytes
  }
  study_need(size <= 4194304, "Study exceeds the 4 MiB frozen-source limit")
  let sessions : Map[String, Bool] = {}
  for alternative in study.alternatives {
    study_need(
      study_component(alternative.session_id) &&
      !sessions.contains(alternative.session_id),
      "Duplicate or invalid session",
    )
    sessions[alternative.session_id] = true
    study_check_alternative(study, alternative)
  }
  study_need(
    study.alternatives.all(item => {
      item.baseline_digest == study.alternatives[0].baseline_digest
    }),
    "Alternatives use different site, terrain, robot or calibration baselines; do not rank them",
  )
}

///|
/// Freeze complete product-owned adapter sessions while original sources still match.
pub fn create_study(
  root : String,
  study_id : String,
  revision : String,
  parent_digest : String,
  site : StudySite,
  sessions : Array[String],
) -> StudyEnvelope raise StudyError {
  let sources : Array[StudySource] = []
  let alternatives : Array[StudyAlternative] = []
  for session in sessions {
    study_need(study_component(session), "Invalid session id")
    for reference in session_artifact_refs(session) {
      study_freeze(root, sources, reference)
    }
    let provenance : MissionProvenanceRecord = study_decode(
      study_source(sources, provenance_ref(session)).text,
    )
    for reference in provenance.source_refs {
      study_freeze(root, sources, reference)
    }
    for evidence in provenance.dataset_evidence {
      study_freeze(root, sources, evidence.evidence_ref)
    }
    let design : @robot_mission.RobotMissionDesign = study_decode(
      study_source(sources, provenance.mission_design_ref).text,
    )
    let binding = design.robot_artifact
    if design.environment.calibration.qualified {
      study_freeze(
        root,
        sources,
        design.environment.calibration.authoritative_source,
      )
    }
    for
      path in [
        binding.robot_json_path,
        binding.robot_urdf_path,
        binding.validation_receipt_path,
        binding.bridge_config_path,
      ] {
      study_freeze(root, sources, binding.artifact_root + "/" + path)
    }
    let terrain = study_source(sources, design.environment.terrain_source_path)
    alternatives.push({
      session_id: session,
      design_ref: provenance.mission_design_ref,
      result_ref: mission_result_ref(session),
      provenance_ref: provenance_ref(session),
      replay_ref: replay_receipt_ref(session),
      evaluation_ref: evaluation_ref(session),
      baseline_json: study_baseline_json(site, design, terrain.digest),
      baseline_digest: sha256_text(
        study_baseline_json(site, design, terrain.digest),
      ),
      result_digest: study_source(sources, mission_result_ref(session)).digest,
    })
  }
  let study : MissionStudy = {
    contract_id: "moonmoon.mission-study.v1",
    study_id,
    revision,
    parent_digest,
    site,
    sources,
    alternatives,
    review_required: true,
    physical_readiness: false,
    limitations: [
      "Local digital simulation only; no physical dispatch authority.", "External dataset terms and source truth are not qualified by this dossier.",
      "Optional E1 assembly remains unavailable; no E1 archive is included.", "Export is a manual artifact; MoonFlow delivery and MoonRobo acknowledgement remain unverified.",
    ],
  }
  validate_study(study)
  let dossier_json = study.to_json().stringify(indent=2) + "\n"
  {
    contract_id: "moonmoon.mission-study-envelope.v1",
    dossier_digest: sha256_text(dossier_json),
    dossier_json,
  }
}

///|
/// Reopen exact bytes and independently validate/replay the frozen evidence.
pub fn decode_study(text : String) -> MissionStudy raise StudyError {
  study_need(@utf8.encode(text).length() <= 8388608, "Envelope exceeds 8 MiB")
  let envelope : StudyEnvelope = study_decode(text)
  study_need(
    envelope.contract_id == "moonmoon.mission-study-envelope.v1" &&
    envelope.dossier_digest == sha256_text(envelope.dossier_json),
    "Dossier envelope digest mismatch",
  )
  let study : MissionStudy = study_decode(envelope.dossier_json)
  validate_study(study)
  study
}

///|
/// Immutable revision path under the existing product-owned evidence root.
pub fn study_ref(
  study_id : String,
  revision : String,
) -> String raise StudyError {
  study_need(
    study_component(study_id) && study_component(revision),
    "Invalid study/revision identity",
  )
  ".moonsuite/products/moonmoon/mission-studies/" +
  study_id +
  "/" +
  revision +
  "/dossier.json"
}

///|
/// Intent precedes persistence. An interrupted save accepts only the identical bytes.
pub fn save_study(
  root : String,
  envelope : StudyEnvelope,
) -> String raise StudyError {
  let text = envelope.to_json().stringify(indent=2) + "\n"
  let study = decode_study(text)
  let reference = study_ref(study.study_id, study.revision)
  let path = root + "/" + reference
  let intent = path + ".pending"
  match ensure_directory_tree(@pathx.dirname(path).to_owned()) {
    Ok(_) => ()
    Err(error) => raise InvalidStudy(error.message)
  }
  if @fsx.path_exists(intent) {
    study_need(
      study_read(intent) == envelope.dossier_digest,
      "Unresolved save belongs to different bytes; reconcile the original revision first",
    )
  } else {
    match write_text(intent, envelope.dossier_digest) {
      Ok(_) => ()
      Err(error) => raise InvalidStudy(error.message)
    }
  }
  if @fsx.path_exists(path) {
    study_need(
      study_read(path) == text,
      "Existing revision differs or is incomplete; preserve it for investigation",
    )
  } else {
    match write_text(path, text) {
      Ok(_) => ()
      Err(error) => raise InvalidStudy(error.message)
    }
  }
  study_need(
    study_read(path) == text,
    "Save outcome unknown; reopen before accepting a replacement",
  )
  reference
}
