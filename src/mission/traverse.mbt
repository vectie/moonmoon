///|
pub(all) enum TraverseDecision {
  Allow
  Review
  Block
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TraverseProfile {
  profile_id : String
  label : String
  max_grade : Double
  caution_grade : Double
  max_roughness_m : Double
  caution_roughness_m : Double
  min_confidence : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TraverseScore {
  profile : TraverseProfile
  decision : TraverseDecision
  score : Int
  reasons : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn conservative_rover_profile() -> TraverseProfile {
  {
    profile_id: "conservative-lunar-rover-v1",
    label: "Conservative Lunar Rover",
    max_grade: 0.35,
    caution_grade: 0.18,
    max_roughness_m: 2.5,
    caution_roughness_m: 1.2,
    min_confidence: 0.7,
  }
}

///|
pub fn traverse_decision_label(decision : TraverseDecision) -> String {
  match decision {
    Allow => "allow"
    Review => "review"
    Block => "block"
  }
}

///|
fn add_reason_if(
  reasons : Array[String],
  condition : Bool,
  reason : String,
) -> Unit {
  if condition {
    reasons.push(reason)
  }
}

///|
fn score_from_reasons(
  decision : TraverseDecision,
  reasons : Array[String],
) -> Int {
  match decision {
    Allow => 90
    Review => 70 - reasons.length() * 8
    Block => 30 - reasons.length() * 5
  }
}

///|
pub fn score_traverse(
  metrics : @terrain.TerrainMetrics,
  profile : TraverseProfile,
) -> TraverseScore {
  let reasons : Array[String] = []
  let grade_blocked = metrics.max_neighbor_grade >= profile.max_grade
  let roughness_blocked = metrics.roughness_m >= profile.max_roughness_m
  let grade_review = metrics.max_neighbor_grade >= profile.caution_grade
  let roughness_review = metrics.roughness_m >= profile.caution_roughness_m
  let confidence_review = metrics.uncertainty.confidence <
    profile.min_confidence
  add_reason_if(
    reasons, grade_blocked, "max neighbor grade exceeds rover hard limit",
  )
  add_reason_if(
    reasons, roughness_blocked, "roughness exceeds rover hard limit",
  )
  add_reason_if(
    reasons,
    !grade_blocked && grade_review,
    "max neighbor grade needs route review",
  )
  add_reason_if(
    reasons,
    !roughness_blocked && roughness_review,
    "roughness needs route review",
  )
  add_reason_if(
    reasons, confidence_review, "terrain confidence below traverse threshold",
  )
  let decision = if grade_blocked || roughness_blocked {
    Block
  } else if grade_review ||
    roughness_review ||
    confidence_review ||
    metrics.hazard_class == @terrain.HazardClass::Caution {
    Review
  } else {
    Allow
  }
  {
    profile,
    decision,
    score: score_from_reasons(decision, reasons),
    reasons,
    next_action: match decision {
      Allow => "candidate route may advance to simulation"
      Review =>
        "operator should review route and source confidence before simulation"
      Block => "choose alternate route or improve terrain evidence"
    },
  }
}

///|
pub fn first_trusted_square_traverse_score() -> TraverseScore {
  score_traverse(
    @terrain.first_trusted_square_metrics(),
    conservative_rover_profile(),
  )
}
