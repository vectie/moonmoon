///|
pub(all) struct RobotEpisodeCatalogDossier {
  root : String
  episode_id : @robot_data.RobotEpisodeId
  catalog_entry_count : Int
  source_artifact : @data_core.ArtifactRef
  dataset_artifact : @data_core.ArtifactRef
  version_artifact : @data_core.ArtifactRef
  validation_artifact : @data_core.ArtifactRef
  source : @data_core.DataSource
  dataset : @data_core.DatasetManifest
  version : @data_core.DatasetVersion
  validation_status : @data_core.ValidationStatus
  blocker_count : Int
  warning_count : Int
  data_ref_count : Int
  signal_ref_count : Int
  replay_ref_count : Int
  data_ref_uris : Array[String]
  model_ref_uris : Array[String]
  signal_ref_uris : Array[String]
  replay_ref_uris : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn episode_version_id(episode_id : @robot_data.RobotEpisodeId) -> String {
  "\{episode_id}-v1"
}

///|
fn refs_of_kind(
  refs : Array[@data_core.DataRef],
  kind : String,
) -> Array[@data_core.DataRef] {
  let out : Array[@data_core.DataRef] = []
  for data_ref in refs {
    if data_ref.kind == kind {
      out.push(data_ref)
    }
  }
  out
}

///|
pub fn robot_episode_catalog_dossier_from_root(
  root : String,
  episode_id : @robot_data.RobotEpisodeId,
) -> Result[RobotEpisodeCatalogDossier, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dataset_entry = match catalog_entry_for(catalog, "dataset", episode_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-episode-dataset-not-cataloged", episode_id, "robot episode dataset is not present in the data catalog",
        ),
      )
  }
  let version_id = episode_version_id(episode_id)
  let version_entry = match
    catalog_entry_for(catalog, "dataset-version", version_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-episode-version-not-cataloged", version_id, "robot episode version is not present in the data catalog",
        ),
      )
  }
  let dataset = match @data_store.read_dataset(root, episode_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if dataset.source_ids.is_empty() {
    return Err(
      dossier_issue(
        "robot-episode-source-missing", episode_id, "robot episode dataset has no source id",
      ),
    )
  }
  let source_id = dataset.source_ids[0]
  let source_entry = match catalog_entry_for(catalog, "source", source_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-episode-source-not-cataloged", source_id, "robot episode source is not present in the data catalog",
        ),
      )
  }
  let validation_entry = match latest_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-episode-validation-not-cataloged", root, "robot episode data root has no cataloged validation report",
        ),
      )
  }
  let source = match @data_store.read_source(root, source_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let version = match @data_store.read_dataset_version(root, version_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let report = match
    @data_store.read_validation_report(root, validation_entry.artifact_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let model_refs = refs_of_kind(dataset.data_refs, "urdf")
  let signal_refs = refs_of_kind(dataset.data_refs, "robot-signal-frame")
  let replay_refs = refs_of_kind(dataset.data_refs, "robot-replay")
  Ok({
    root,
    episode_id,
    catalog_entry_count: catalog.entries.length(),
    source_artifact: @data_core.catalog_entry_ref(source_entry),
    dataset_artifact: @data_core.catalog_entry_ref(dataset_entry),
    version_artifact: @data_core.catalog_entry_ref(version_entry),
    validation_artifact: @data_core.catalog_entry_ref(validation_entry),
    source,
    dataset,
    version,
    validation_status: report.status,
    blocker_count: @data_core.validation_blocker_count(report),
    warning_count: warning_count(report),
    data_ref_count: dataset.data_refs.length(),
    signal_ref_count: signal_refs.length(),
    replay_ref_count: replay_refs.length(),
    data_ref_uris: data_ref_uris(dataset.data_refs),
    model_ref_uris: data_ref_uris(model_refs),
    signal_ref_uris: data_ref_uris(signal_refs),
    replay_ref_uris: data_ref_uris(replay_refs),
  })
}
