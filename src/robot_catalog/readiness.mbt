///|
pub(all) struct RobotMigrationReadiness {
  root : String
  status : String
  ready : Bool
  validation_artifact : @data_core.ArtifactRef
  validation_status : @data_core.ValidationStatus
  blocker_count : Int
  warning_count : Int
  model_count : Int
  episode_count : Int
  telemetry_stream_count : Int
  signal_ref_count : Int
  replay_ref_count : Int
  quality_ref_count : Int
  telemetry_ref_count : Int
  data_ref_count : Int
  next_action : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn robot_signal_ref_count(episodes : Array[RobotEpisodeCatalogDossier]) -> Int {
  let mut count = 0
  for episode in episodes {
    count += episode.signal_ref_count
  }
  count
}

///|
fn robot_replay_ref_count(episodes : Array[RobotEpisodeCatalogDossier]) -> Int {
  let mut count = 0
  for episode in episodes {
    count += episode.replay_ref_count
  }
  count
}

///|
fn robot_quality_ref_count(episodes : Array[RobotEpisodeCatalogDossier]) -> Int {
  let mut count = 0
  for episode in episodes {
    count += episode.quality_ref_count
  }
  count
}

///|
fn robot_telemetry_ref_count(
  streams : Array[RobotTelemetryCatalogDossier],
) -> Int {
  let mut count = 0
  for stream in streams {
    count += stream.telemetry_ref_count
  }
  count
}

///|
fn readiness_next_action(
  dossier : RobotCatalogRootDossier,
  signal_ref_count : Int,
  quality_ref_count : Int,
  telemetry_ref_count : Int,
) -> String {
  if dossier.blocker_count > 0 {
    "repair data-root validation blockers before migrating more robot data"
  } else if dossier.model_count == 0 {
    "import a robot model package"
  } else if dossier.episode_count == 0 {
    "import a robot episode directory against the cataloged model"
  } else if signal_ref_count == 0 {
    "stage signal-frame payloads for at least one robot episode"
  } else if quality_ref_count == 0 {
    "stage quality evidence for imported robot episodes"
  } else if telemetry_ref_count == 0 {
    "migrate a standalone robot telemetry stream into the generic data root"
  } else {
    "migrate the next robot dataset family only after this root stays green"
  }
}

///|
pub fn robot_migration_readiness_from_root(
  root : String,
) -> Result[RobotMigrationReadiness, @data_store.DataStoreIssue] {
  let dossier = match robot_catalog_root_dossier_from_root(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let signal_ref_count = robot_signal_ref_count(dossier.episode_dossiers)
  let replay_ref_count = robot_replay_ref_count(dossier.episode_dossiers)
  let quality_ref_count = robot_quality_ref_count(dossier.episode_dossiers)
  let telemetry_ref_count = robot_telemetry_ref_count(
    dossier.telemetry_dossiers,
  )
  let ready = dossier.validation_status == @data_core.ValidationStatus::Passed &&
    dossier.blocker_count == 0 &&
    dossier.model_count > 0 &&
    dossier.episode_count > 0 &&
    signal_ref_count > 0 &&
    quality_ref_count > 0 &&
    telemetry_ref_count > 0
  let status = if ready {
    "ready"
  } else if dossier.blocker_count > 0 {
    "blocked"
  } else {
    "needs-evidence"
  }
  let next_action = readiness_next_action(
    dossier, signal_ref_count, quality_ref_count, telemetry_ref_count,
  )
  Ok({
    root,
    status,
    ready,
    validation_artifact: dossier.validation_artifact,
    validation_status: dossier.validation_status,
    blocker_count: dossier.blocker_count,
    warning_count: dossier.warning_count,
    model_count: dossier.model_count,
    episode_count: dossier.episode_count,
    telemetry_stream_count: dossier.telemetry_stream_count,
    signal_ref_count,
    replay_ref_count,
    quality_ref_count,
    telemetry_ref_count,
    data_ref_count: dossier.data_ref_count,
    next_action,
    summary: "robot catalog has \{dossier.model_count} model(s), \{dossier.episode_count} episode(s), \{dossier.telemetry_stream_count} telemetry stream(s), \{signal_ref_count} signal ref(s), \{replay_ref_count} replay ref(s), \{quality_ref_count} quality ref(s), and \{telemetry_ref_count} telemetry ref(s)",
  })
}
