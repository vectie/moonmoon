///|
pub type ValidationReportId = String

///|
pub(all) struct ValidationFinding {
  rule_id : String
  severity : FindingSeverity
  artifact : ArtifactRef
  message : String
  recommendation : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ValidationReport {
  validation_report_id : ValidationReportId
  root : String
  generated_at_ms : Int64
  status : ValidationStatus
  findings : Array[ValidationFinding]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn validation_finding(
  rule_id : String,
  severity : FindingSeverity,
  artifact : ArtifactRef,
  message : String,
  recommendation? : String = "",
) -> ValidationFinding {
  { rule_id, severity, artifact, message, recommendation }
}

///|
pub fn validation_report(
  validation_report_id : ValidationReportId,
  root : String,
  generated_at_ms : Int64,
  status : ValidationStatus,
  findings? : Array[ValidationFinding] = [],
) -> ValidationReport {
  { validation_report_id, root, generated_at_ms, status, findings }
}

///|
pub fn validation_finding_count(report : ValidationReport) -> Int {
  report.findings.length()
}

///|
pub fn validation_blocker_count(report : ValidationReport) -> Int {
  let mut count = 0
  for finding in report.findings {
    if finding.severity == Blocker {
      count += 1
    }
  }
  count
}
