///|
pub(all) struct RobotCatalogRootDossier {
  root : String
  catalog_entry_count : Int
  validation_artifact : @data_core.ArtifactRef
  validation_status : @data_core.ValidationStatus
  blocker_count : Int
  warning_count : Int
  model_count : Int
  episode_count : Int
  telemetry_stream_count : Int
  gait_clip_count : Int
  data_ref_count : Int
  source_ids : Array[String]
  model_ids : Array[@robot_data.RobotModelId]
  episode_ids : Array[@robot_data.RobotEpisodeId]
  telemetry_stream_ids : Array[@robot_data.RobotTelemetryStreamId]
  gait_clip_ids : Array[@robot_data.RobotGaitClipId]
  model_dossiers : Array[RobotModelCatalogDossier]
  episode_dossiers : Array[RobotEpisodeCatalogDossier]
  telemetry_dossiers : Array[RobotTelemetryCatalogDossier]
  gait_clip_dossiers : Array[RobotGaitClipCatalogDossier]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn model_dataset_prefix() -> String {
  "robot-model-package-"
}

///|
fn model_id_from_dataset_id(dataset_id : String) -> String? {
  let prefix = model_dataset_prefix()
  if dataset_id.has_prefix(prefix) && dataset_id.length() > prefix.length() {
    Some(dataset_id[prefix.length():dataset_id.length()].to_owned())
  } else {
    None
  }
}

///|
fn push_unique_string(values : Array[String], value : String) -> Unit {
  if !values.contains(value) {
    values.push(value)
  }
}

///|
fn push_source_ids(
  source_ids : Array[String],
  dataset : @data_core.DatasetManifest,
) -> Unit {
  for source_id in dataset.source_ids {
    push_unique_string(source_ids, source_id)
  }
}

///|
pub fn robot_catalog_root_dossier_from_root(
  root : String,
) -> Result[RobotCatalogRootDossier, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let validation_entry = match latest_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-catalog-validation-not-cataloged", root, "robot data root has no cataloged validation report",
        ),
      )
  }
  let report = match
    @data_store.read_validation_report(root, validation_entry.artifact_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let model_ids : Array[@robot_data.RobotModelId] = []
  let episode_ids : Array[@robot_data.RobotEpisodeId] = []
  let telemetry_stream_ids : Array[@robot_data.RobotTelemetryStreamId] = []
  let gait_clip_ids : Array[@robot_data.RobotGaitClipId] = []
  let source_ids : Array[String] = []
  let model_dossiers : Array[RobotModelCatalogDossier] = []
  let episode_dossiers : Array[RobotEpisodeCatalogDossier] = []
  let telemetry_dossiers : Array[RobotTelemetryCatalogDossier] = []
  let gait_clip_dossiers : Array[RobotGaitClipCatalogDossier] = []
  let mut data_ref_count = 0
  for entry in catalog.entries {
    if entry.artifact_kind == "dataset" {
      let dataset = match @data_store.read_dataset(root, entry.artifact_id) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if dataset.kind == "robot-model-package" {
        let model_id = match model_id_from_dataset_id(dataset.dataset_id) {
          Some(value) => value
          None =>
            return Err(
              dossier_issue(
                "robot-model-dataset-id-unrecognized",
                dataset.dataset_id,
                "robot model package dataset id does not use the robot-model-package prefix",
              ),
            )
        }
        let dossier = match
          robot_model_catalog_dossier_from_root(root, model_id) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        push_unique_string(model_ids, model_id)
        push_source_ids(source_ids, dataset)
        data_ref_count += dossier.data_ref_count
        model_dossiers.push(dossier)
      } else if dataset.kind == "robot-episode" {
        let dossier = match
          robot_episode_catalog_dossier_from_root(root, dataset.dataset_id) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        push_unique_string(episode_ids, dataset.dataset_id)
        push_source_ids(source_ids, dataset)
        data_ref_count += dossier.data_ref_count
        episode_dossiers.push(dossier)
      } else if dataset.kind == "robot-telemetry-stream" {
        let dossier = match
          robot_telemetry_catalog_dossier_from_root(root, dataset.dataset_id) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        push_unique_string(telemetry_stream_ids, dataset.dataset_id)
        push_source_ids(source_ids, dataset)
        data_ref_count += dossier.data_ref_count
        telemetry_dossiers.push(dossier)
      } else if dataset.kind == "robot-gait-clip" {
        let dossier = match
          robot_gait_clip_catalog_dossier_from_root(root, dataset.dataset_id) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        push_unique_string(gait_clip_ids, dataset.dataset_id)
        push_source_ids(source_ids, dataset)
        data_ref_count += dossier.data_ref_count
        gait_clip_dossiers.push(dossier)
      }
    }
  }
  Ok({
    root,
    catalog_entry_count: catalog.entries.length(),
    validation_artifact: @data_core.catalog_entry_ref(validation_entry),
    validation_status: report.status,
    blocker_count: @data_core.validation_blocker_count(report),
    warning_count: warning_count(report),
    model_count: model_dossiers.length(),
    episode_count: episode_dossiers.length(),
    telemetry_stream_count: telemetry_dossiers.length(),
    gait_clip_count: gait_clip_dossiers.length(),
    data_ref_count,
    source_ids,
    model_ids,
    episode_ids,
    telemetry_stream_ids,
    gait_clip_ids,
    model_dossiers,
    episode_dossiers,
    telemetry_dossiers,
    gait_clip_dossiers,
  })
}
