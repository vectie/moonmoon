///|
/// Supported edits to one named variant. The parent and optional adopted robot
/// are frozen once at batch level, never overridden by a variant.
pub(all) struct MissionDraftVariant {
  variant_id : String
  name : String
  edits : MissionDraftEdits
} derive(Debug, Eq, ToJson, FromJson)

///|
/// A reference plus 2–4 sensitivity variants. This separate version preserves
/// the public v1 single-edit contract and its exact native session identities.
pub(all) struct SensitivityMissionDraft {
  contract_id : String
  study_id : String
  revision : String
  parent_envelope_json : String
  parent_digest : String
  base_session_id : String
  robot_envelope_json : String
  variants : Array[MissionDraftVariant]
  review_required : Bool
  physical_execution_allowed : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
fn sensitivity_single(draft : SensitivityMissionDraft) -> MissionDraft {
  {
    contract_id: "moonmoon.mission-draft.v1",
    study_id: draft.study_id,
    revision: draft.revision,
    parent_envelope_json: draft.parent_envelope_json,
    parent_digest: draft.parent_digest,
    base_session_id: draft.base_session_id,
    robot_envelope_json: draft.robot_envelope_json,
    edits: draft.variants[0].edits,
    review_required: draft.review_required,
    physical_execution_allowed: draft.physical_execution_allowed,
  }
}

///|
/// Validate every bounded variant before any workspace or adapter session is
/// created. No source, baseline or physical authority is supplied by a variant.
pub fn decode_sensitivity_draft(
  text : String,
) -> SensitivityMissionDraft raise StudyError {
  study_need(
    @utf8.encode(text).length() <= 16777216,
    "Draft envelope exceeds 16 MiB",
  )
  let envelope : MissionDraftEnvelope = study_decode(text)
  study_need(
    envelope.contract_id == "moonmoon.mission-draft-envelope.v2" &&
    envelope.draft_digest == sha256_text(envelope.draft_json),
    "Sensitivity draft digest mismatch",
  )
  let draft : SensitivityMissionDraft = study_decode(envelope.draft_json)
  let raw : Json = study_decode(envelope.draft_json)
  study_need(
    match raw {
      Object(fields) => !fields.contains("edits")
      _ => false
    },
    "V2 draft cannot contain legacy shared edits",
  )
  study_need(
    draft.contract_id == "moonmoon.mission-draft.v2",
    "Unsupported sensitivity draft",
  )
  study_need(
    draft.variants.length() >= 2 && draft.variants.length() <= 4,
    "Sensitivity draft requires 2–4 named variants plus one reference",
  )
  let ids : Map[String, Bool] = {}
  for variant in draft.variants {
    study_need(
      study_component(variant.variant_id) &&
      variant.variant_id.length() <= 64 &&
      variant.variant_id != "reference" &&
      !ids.contains(variant.variant_id),
      "Variant IDs must be unique safe names, at most 64 characters, and cannot be reference",
    )
    ids[variant.variant_id] = true
    study_need(
      variant.name.trim() != "" && variant.name.length() <= 120,
      "Variant name must be 1–120 characters",
    )
    draft_validate_edits(variant.edits)
  }
  // Common parent replay and adopted-robot binding are checked once, not once
  // for each variant. Adapter replay checks are intentionally not bypassed.
  validate_single_draft(sensitivity_single(draft))
  draft
}
