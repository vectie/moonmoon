///|
pub(all) enum LunarReviewStatus {
  AcceptedForSoftwareProof
  NeedsSourceUpgrade
  NeedsHumanReview
  Rejected
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn lunar_review_status_label(status : LunarReviewStatus) -> String {
  match status {
    AcceptedForSoftwareProof => "accepted-for-software-proof"
    NeedsSourceUpgrade => "needs-source-upgrade"
    NeedsHumanReview => "needs-human-review"
    Rejected => "rejected"
  }
}
