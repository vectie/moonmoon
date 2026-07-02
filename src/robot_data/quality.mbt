///|
pub type RobotQualityReportId = String

///|
pub(all) struct RobotQualityReport {
  report_id : RobotQualityReportId
  episode_id : RobotEpisodeId
  status : @data_core.ValidationStatus
  generated_at_ms : Int64
  accepted_frame_count : Int
  rejected_frame_count : Int
  findings : Array[@data_core.ValidationFinding]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_quality_report(
  report_id : RobotQualityReportId,
  episode_id : RobotEpisodeId,
  status : @data_core.ValidationStatus,
  generated_at_ms : Int64,
  accepted_frame_count : Int,
  rejected_frame_count : Int,
  findings? : Array[@data_core.ValidationFinding] = [],
) -> RobotQualityReport {
  {
    report_id,
    episode_id,
    status,
    generated_at_ms,
    accepted_frame_count,
    rejected_frame_count,
    findings,
  }
}

///|
pub fn robot_quality_validation_report(
  root : String,
  report : RobotQualityReport,
) -> @data_core.ValidationReport {
  @data_core.validation_report(
    report.report_id,
    root,
    report.generated_at_ms,
    report.status,
    findings=report.findings,
  )
}

///|
pub fn robot_quality_report_ref(
  report : RobotQualityReport,
  payload : RobotPayloadRef,
) -> @data_core.ArtifactRef {
  @data_core.artifact_ref(
    "validation-report",
    report.report_id,
    payload.path,
    status=match report.status {
      @data_core.ValidationStatus::BlockedValidation =>
        @data_core.DataStatus::Blocked
      @data_core.ValidationStatus::Warning => @data_core.DataStatus::Raw
      @data_core.ValidationStatus::Passed => @data_core.DataStatus::Verified
    },
    summary="robot episode quality report for \{report.episode_id}",
  )
}
