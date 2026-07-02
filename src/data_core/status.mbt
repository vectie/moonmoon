///|
pub(all) enum DataStatus {
  Raw
  Verified
  Curated
  Rejected
  Blocked
  UnknownStatus
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn data_status_label(status : DataStatus) -> String {
  match status {
    Raw => "raw"
    Verified => "verified"
    Curated => "curated"
    Rejected => "rejected"
    Blocked => "blocked"
    UnknownStatus => "unknown"
  }
}

///|
pub(all) enum ValidationStatus {
  Passed
  Warning
  BlockedValidation
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn validation_status_label(status : ValidationStatus) -> String {
  match status {
    Passed => "passed"
    Warning => "warning"
    BlockedValidation => "blocked"
  }
}

///|
pub(all) enum FindingSeverity {
  Info
  WarningSeverity
  Blocker
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn finding_severity_label(severity : FindingSeverity) -> String {
  match severity {
    Info => "info"
    WarningSeverity => "warning"
    Blocker => "blocker"
  }
}
