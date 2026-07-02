///|
pub(all) struct RobotReadinessMetricView {
  metric_id : String
  label : String
  value : Int
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotReadinessEvidenceView {
  evidence_id : String
  label : String
  count : Int
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotReadinessViewModel {
  view_id : String
  root : String
  title : String
  status : String
  ready : Bool
  validation_status : String
  blocker_count : Int
  warning_count : Int
  data_ref_count : Int
  next_action : String
  summary : String
  validation_artifact_id : String
  validation_manifest_path : String
  metrics : Array[RobotReadinessMetricView]
  evidence : Array[RobotReadinessEvidenceView]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn readiness_count_status(value : Int) -> String {
  if value > 0 {
    "ready"
  } else {
    "missing"
  }
}

///|
fn readiness_metric(
  metric_id : String,
  label : String,
  value : Int,
) -> RobotReadinessMetricView {
  { metric_id, label, value, status: readiness_count_status(value) }
}

///|
fn readiness_evidence(
  evidence_id : String,
  label : String,
  count : Int,
) -> RobotReadinessEvidenceView {
  { evidence_id, label, count, status: readiness_count_status(count) }
}

///|
pub fn robot_readiness_view_model(
  readiness : @robot_catalog.RobotMigrationReadiness,
) -> RobotReadinessViewModel {
  {
    view_id: "ui/robot-migration-readiness/operator-view-v1",
    root: readiness.root,
    title: "Robot Migration Readiness",
    status: readiness.status,
    ready: readiness.ready,
    validation_status: @data_core.validation_status_label(
      readiness.validation_status,
    ),
    blocker_count: readiness.blocker_count,
    warning_count: readiness.warning_count,
    data_ref_count: readiness.data_ref_count,
    next_action: readiness.next_action,
    summary: readiness.summary,
    validation_artifact_id: readiness.validation_artifact.artifact_id,
    validation_manifest_path: readiness.validation_artifact.manifest_path,
    metrics: [
      readiness_metric("models", "models", readiness.model_count),
      readiness_metric("episodes", "episodes", readiness.episode_count),
      readiness_metric(
        "telemetry-streams",
        "telemetry streams",
        readiness.telemetry_stream_count,
      ),
      readiness_metric("gait-clips", "gait clips", readiness.gait_clip_count),
      readiness_metric(
        "gait-annotations",
        "gait annotations",
        readiness.gait_annotation_count,
      ),
      readiness_metric(
        "gait-alignments",
        "gait alignments",
        readiness.gait_alignment_count,
      ),
      readiness_metric("task-labels", "task labels", readiness.task_label_count),
      readiness_metric("rollouts", "rollout summaries", readiness.rollout_count),
    ],
    evidence: [
      readiness_evidence("signals", "signal refs", readiness.signal_ref_count),
      readiness_evidence("replays", "replay refs", readiness.replay_ref_count),
      readiness_evidence("quality", "quality refs", readiness.quality_ref_count),
      readiness_evidence(
        "telemetry",
        "telemetry refs",
        readiness.telemetry_ref_count,
      ),
      readiness_evidence("gait", "gait refs", readiness.gait_ref_count),
      readiness_evidence(
        "gait-annotations",
        "gait annotation refs",
        readiness.gait_annotation_ref_count,
      ),
      readiness_evidence(
        "gait-alignments",
        "gait alignment refs",
        readiness.gait_alignment_ref_count,
      ),
      readiness_evidence(
        "task-labels",
        "task label refs",
        readiness.task_label_ref_count,
      ),
      readiness_evidence(
        "rollouts",
        "rollout refs",
        readiness.rollout_ref_count,
      ),
    ],
  }
}

///|
pub fn robot_readiness_view_model_from_catalog_root(
  root : String,
) -> Result[RobotReadinessViewModel, CatalogBackedViewIssue] {
  let readiness = match
    @robot_catalog.robot_migration_readiness_from_root(root) {
    Ok(value) => value
    Err(error) =>
      return Err(
        catalog_backed_view_issue(error.code, error.path, error.message),
      )
  }
  Ok(robot_readiness_view_model(readiness))
}

///|
pub fn robot_readiness_catalog_json(
  root : String,
) -> Result[Json, CatalogBackedViewIssue] {
  let view = match robot_readiness_view_model_from_catalog_root(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(view.to_json())
}

///|
fn robot_metric_rows(metrics : Array[RobotReadinessMetricView]) -> String {
  let mut html = ""
  for metric in metrics {
    let row =
      $|<article class="row \{status_class(metric.status)}"><div><b>\{html_escape(metric.label)}</b><span>\{html_escape(metric.metric_id)}</span></div><strong>\{metric.value}</strong></article>
    html += row
  }
  html
}

///|
fn robot_evidence_rows(evidence : Array[RobotReadinessEvidenceView]) -> String {
  let mut html = ""
  for item in evidence {
    let row =
      $|<article class="row \{status_class(item.status)}"><div><b>\{html_escape(item.label)}</b><span>\{html_escape(item.evidence_id)}</span></div><strong>\{item.count}</strong></article>
    html += row
  }
  html
}

///|
pub fn render_robot_readiness_html(view : RobotReadinessViewModel) -> String {
  let title = html_escape(view.title)
  let status = html_escape(view.status)
  let next_action = html_escape(view.next_action)
  let summary = html_escape(view.summary)
  let validation = html_escape(view.validation_status)
  let validation_path = html_escape(view.validation_manifest_path)
  let view_json = view.to_json().stringify(indent=2)
  let html =
    $|<!doctype html>
    $|<html lang="en">
    $|<head>
    $|<meta charset="utf-8">
    $|<meta name="viewport" content="width=device-width, initial-scale=1">
    $|<title>Moonmoon - \{title}</title>
    $|\{app_styles()}
    $|</head>
    $|<body>
    $|<script id="moonmoon-robot-readiness-view-model" type="application/json">
    $|\{view_json}
    $|</script>
    $|<main class="shell">
    $|  <section class="workspace">
    $|    <header class="topbar"><div><h1>\{title}</h1><p class="summary">\{summary}</p></div><strong class="badge">\{status}</strong></header>
    $|    <section class="hero"><div class="surface"><h2>robot data root</h2><strong>\{view.data_ref_count}</strong><span>cataloged data refs, next action: \{next_action}</span></div><div class="panel metrics"><div class="metric"><span>validation</span><b>\{validation}</b></div><div class="metric"><span>blockers</span><b>\{view.blocker_count}</b></div><div class="metric"><span>warnings</span><b>\{view.warning_count}</b></div><div class="metric"><span>ready</span><b>\{if view.ready { "yes" } else { "no" }}</b></div></div></section>
    $|    <section class="card panel"><h2>dataset families</h2>\{robot_metric_rows(view.metrics)}</section>
    $|  </section>
    $|  <aside class="inspector">
    $|    <section class="card panel"><h2>validation</h2><article class="row \{status_class(view.status)}"><div><b>\{validation}</b><span>\{validation_path}</span></div><strong>\{status}</strong></article></section>
    $|    <section class="card panel"><h2>evidence refs</h2>\{robot_evidence_rows(view.evidence)}</section>
    $|  </aside>
    $|</main>
    $|</body>
    $|</html>
  html
}

///|
pub fn robot_readiness_catalog_html(
  root : String,
) -> Result[String, CatalogBackedViewIssue] {
  let view = match robot_readiness_view_model_from_catalog_root(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(render_robot_readiness_html(view))
}
