///|
fn print_help() -> Unit {
  let help =
    #|Moonmoon CLI
    #|
    #|Commands:
    #|  moon run cmd/main
    #|  moon run cmd/main -- json
    #|  moon run cmd/main -- kernel
    #|  moon run cmd/main -- kernel json
    #|  moon run cmd/main -- terrain
    #|  moon run cmd/main -- terrain json
    #|  moon run cmd/main -- mission horizon
    #|  moon run cmd/main -- mission horizon json
    #|  moon run cmd/main -- mission terrain
    #|  moon run cmd/main -- mission terrain json
    #|  moon run cmd/main -- mission energy
    #|  moon run cmd/main -- mission energy json
    #|  moon run cmd/main -- layout [workspace-root] [book-id]
    #|  moon run cmd/main -- data root-json [data-root]
    #|  moon run cmd/main -- data ingest-first-site [data-root] [json]
    #|  moon run cmd/main -- data ingest-robot-model [data-root] [source-dir] [model-id] [robot-id] [json]
    #|  moon run cmd/main -- data ingest-robot-episode [data-root] [source-dir] [dataset-id] [episode-id] [robot-id] [model-id] [json]
    #|  moon run cmd/main -- data ingest-robot-telemetry [data-root] [source-dir] [stream-id] [robot-id] [session-id] [json]
    #|  moon run cmd/main -- data ingest-robot-gait-clip [data-root] [source-dir] [clip-id] [robot-id] [model-id] [json]
    #|  moon run cmd/main -- data ingest-robot-gait-annotation [data-root] [source-dir] [annotation-id] [clip-id] [robot-id] [model-id] [json]
    #|  moon run cmd/main -- data ingest-robot-gait-alignment [data-root] [source-dir] [alignment-id] [episode-id] [clip-id] [annotation-id] [robot-id] [model-id] [json]
    #|  moon run cmd/main -- data ingest-robot-task-label [data-root] [source-dir] [task-label-id] [episode-id] [alignment-id] [robot-id] [model-id] [json]
    #|  moon run cmd/main -- data robot-json [data-root]
    #|  moon run cmd/main -- data robot-readiness-json [data-root]
    #|  moon run cmd/main -- data robot-model-json [data-root] [model-id]
    #|  moon run cmd/main -- data robot-episode-json [data-root] [episode-id]
    #|  moon run cmd/main -- data robot-telemetry-json [data-root] [stream-id]
    #|  moon run cmd/main -- data robot-gait-clip-json [data-root] [clip-id]
    #|  moon run cmd/main -- data robot-gait-annotation-json [data-root] [annotation-id]
    #|  moon run cmd/main -- data robot-gait-alignment-json [data-root] [alignment-id]
    #|  moon run cmd/main -- data robot-task-label-json [data-root] [task-label-id]
    #|  moon run cmd/main -- data site-json [data-root]
    #|  moon run cmd/main -- data ui-json [data-root]
    #|  moon run cmd/main -- data ui-html [data-root]
    #|  moon run cmd/main -- ui
    #|  moon run cmd/main -- ui json
    #|  moon run cmd/main -- ui html
    #|
  println(help)
}

///|
fn arg_after(
  args : Array[String],
  marker : String,
  fallback : String,
) -> String {
  for index in 0..<args.length() {
    if args[index] == marker && index + 1 < args.length() {
      return args[index + 1]
    }
  }
  fallback
}

///|
fn arg_offset(
  args : Array[String],
  marker : String,
  offset : Int,
  fallback : String,
) -> String {
  for index in 0..<args.length() {
    if args[index] == marker && index + offset < args.length() {
      return args[index + offset]
    }
  }
  fallback
}

///|
fn print_layout(args : Array[String]) -> Unit {
  let root = arg_after(args, "layout", ".")
  let book_id = arg_after(args, root, "<book-id>")
  let home = @moonmoon.moonsuite_product_home_for_workspace_root(root, book_id~)
  println(home.to_json().stringify(indent=2))
}

///|
fn data_ingest_root(args : Array[String]) -> String {
  arg_after(args, "ingest-first-site", "target/data-roots/first-trusted-square")
}

///|
fn data_site_root(args : Array[String]) -> String {
  arg_after(args, "site-json", "target/data-roots/first-trusted-square")
}

///|
fn data_ui_json_root(args : Array[String]) -> String {
  arg_after(args, "ui-json", "target/data-roots/first-trusted-square")
}

///|
fn data_ui_html_root(args : Array[String]) -> String {
  arg_after(args, "ui-html", "target/data-roots/first-trusted-square")
}

///|
fn data_root_json_root(args : Array[String]) -> String {
  arg_offset(args, "root-json", 1, "target/data-roots/first-trusted-square")
}

///|
fn data_robot_model_root(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-model", 1, "target/data-roots/robot-model")
}

///|
fn data_robot_model_source_dir(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-model", 2, "data/robot_models/input")
}

///|
fn data_robot_model_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-model", 3, "robot-model")
}

///|
fn data_robot_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-model", 4, "robot")
}

///|
fn data_robot_model_json_root(args : Array[String]) -> String {
  arg_offset(args, "robot-model-json", 1, "target/data-roots/robot-model")
}

///|
fn data_robot_model_json_id(args : Array[String]) -> String {
  arg_offset(args, "robot-model-json", 2, "robot-model")
}

///|
fn data_robot_episode_json_root(args : Array[String]) -> String {
  arg_offset(args, "robot-episode-json", 1, "target/data-roots/robot-episode")
}

///|
fn data_robot_episode_json_id(args : Array[String]) -> String {
  arg_offset(args, "robot-episode-json", 2, "robot-episode")
}

///|
fn data_robot_json_root(args : Array[String]) -> String {
  arg_offset(args, "robot-json", 1, "target/data-roots/robot")
}

///|
fn data_robot_readiness_json_root(args : Array[String]) -> String {
  arg_offset(args, "robot-readiness-json", 1, "target/data-roots/robot")
}

///|
fn data_robot_episode_root(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-episode", 1, "target/data-roots/robot-episode")
}

///|
fn data_robot_episode_source_dir(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-episode", 2, "data/robot_episodes/input")
}

///|
fn data_robot_episode_dataset_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-episode", 3, "robot-episode-dataset")
}

///|
fn data_robot_episode_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-episode", 4, "robot-episode")
}

///|
fn data_robot_episode_robot_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-episode", 5, "robot")
}

///|
fn data_robot_episode_model_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-episode", 6, "robot-model")
}

///|
fn data_robot_telemetry_root(args : Array[String]) -> String {
  arg_offset(
    args, "ingest-robot-telemetry", 1, "target/data-roots/robot-telemetry",
  )
}

///|
fn data_robot_telemetry_source_dir(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-telemetry", 2, "data/robot_telemetry/input")
}

///|
fn data_robot_telemetry_stream_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-telemetry", 3, "robot-telemetry-stream")
}

///|
fn data_robot_telemetry_robot_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-telemetry", 4, "robot")
}

///|
fn data_robot_telemetry_session_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-telemetry", 5, "robot-session")
}

///|
fn data_robot_telemetry_json_root(args : Array[String]) -> String {
  arg_offset(
    args, "robot-telemetry-json", 1, "target/data-roots/robot-telemetry",
  )
}

///|
fn data_robot_telemetry_json_id(args : Array[String]) -> String {
  arg_offset(args, "robot-telemetry-json", 2, "robot-telemetry-stream")
}

///|
fn data_robot_gait_clip_root(args : Array[String]) -> String {
  arg_offset(
    args, "ingest-robot-gait-clip", 1, "target/data-roots/robot-gait-clip",
  )
}

///|
fn data_robot_gait_clip_source_dir(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-clip", 2, "data/robot_gait_clips/input")
}

///|
fn data_robot_gait_clip_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-clip", 3, "robot-gait-clip")
}

///|
fn data_robot_gait_clip_robot_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-clip", 4, "robot")
}

///|
fn data_robot_gait_clip_model_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-clip", 5, "robot-model")
}

///|
fn data_robot_gait_clip_json_root(args : Array[String]) -> String {
  arg_offset(
    args, "robot-gait-clip-json", 1, "target/data-roots/robot-gait-clip",
  )
}

///|
fn data_robot_gait_clip_json_id(args : Array[String]) -> String {
  arg_offset(args, "robot-gait-clip-json", 2, "robot-gait-clip")
}

///|
fn data_robot_gait_annotation_root(args : Array[String]) -> String {
  arg_offset(
    args, "ingest-robot-gait-annotation", 1, "target/data-roots/robot-gait-annotation",
  )
}

///|
fn data_robot_gait_annotation_source_dir(args : Array[String]) -> String {
  arg_offset(
    args, "ingest-robot-gait-annotation", 2, "data/robot_gait_annotations/input",
  )
}

///|
fn data_robot_gait_annotation_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-annotation", 3, "robot-gait-annotation")
}

///|
fn data_robot_gait_annotation_clip_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-annotation", 4, "robot-gait-clip")
}

///|
fn data_robot_gait_annotation_robot_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-annotation", 5, "robot")
}

///|
fn data_robot_gait_annotation_model_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-annotation", 6, "robot-model")
}

///|
fn data_robot_gait_annotation_json_root(args : Array[String]) -> String {
  arg_offset(
    args, "robot-gait-annotation-json", 1, "target/data-roots/robot-gait-annotation",
  )
}

///|
fn data_robot_gait_annotation_json_id(args : Array[String]) -> String {
  arg_offset(args, "robot-gait-annotation-json", 2, "robot-gait-annotation")
}

///|
fn data_robot_gait_alignment_root(args : Array[String]) -> String {
  arg_offset(
    args, "ingest-robot-gait-alignment", 1, "target/data-roots/robot-gait-alignment",
  )
}

///|
fn data_robot_gait_alignment_source_dir(args : Array[String]) -> String {
  arg_offset(
    args, "ingest-robot-gait-alignment", 2, "data/robot_gait_alignments/input",
  )
}

///|
fn data_robot_gait_alignment_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-alignment", 3, "robot-gait-alignment")
}

///|
fn data_robot_gait_alignment_episode_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-alignment", 4, "robot-episode")
}

///|
fn data_robot_gait_alignment_clip_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-alignment", 5, "robot-gait-clip")
}

///|
fn data_robot_gait_alignment_annotation_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-alignment", 6, "robot-gait-annotation")
}

///|
fn data_robot_gait_alignment_robot_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-alignment", 7, "robot")
}

///|
fn data_robot_gait_alignment_model_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-gait-alignment", 8, "robot-model")
}

///|
fn data_robot_gait_alignment_json_root(args : Array[String]) -> String {
  arg_offset(
    args, "robot-gait-alignment-json", 1, "target/data-roots/robot-gait-alignment",
  )
}

///|
fn data_robot_gait_alignment_json_id(args : Array[String]) -> String {
  arg_offset(args, "robot-gait-alignment-json", 2, "robot-gait-alignment")
}

///|
fn data_robot_task_label_root(args : Array[String]) -> String {
  arg_offset(
    args, "ingest-robot-task-label", 1, "target/data-roots/robot-task-label",
  )
}

///|
fn data_robot_task_label_source_dir(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-task-label", 2, "data/robot_task_labels/input")
}

///|
fn data_robot_task_label_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-task-label", 3, "robot-task-label")
}

///|
fn data_robot_task_label_episode_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-task-label", 4, "robot-episode")
}

///|
fn data_robot_task_label_alignment_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-task-label", 5, "robot-gait-alignment")
}

///|
fn data_robot_task_label_robot_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-task-label", 6, "robot")
}

///|
fn data_robot_task_label_model_id(args : Array[String]) -> String {
  arg_offset(args, "ingest-robot-task-label", 7, "robot-model")
}

///|
fn data_robot_task_label_json_root(args : Array[String]) -> String {
  arg_offset(
    args, "robot-task-label-json", 1, "target/data-roots/robot-task-label",
  )
}

///|
fn data_robot_task_label_json_id(args : Array[String]) -> String {
  arg_offset(args, "robot-task-label-json", 2, "robot-task-label")
}

///|
fn print_data_ingest(args : Array[String], output_json : Bool) -> Unit {
  let root = data_ingest_root(args)
  match @lunar_catalog.ingest_first_trusted_square_catalog(root, 1L) {
    Ok(ingest) =>
      if output_json {
        println(ingest.to_json().stringify(indent=2))
      } else {
        let materialization = ingest.materialization
        println("Moonmoon first-site data ingest")
        println("- root: \{materialization.root}")
        println("- catalog: \{materialization.catalog_path}")
        println(
          "- validation: \{@data_core.validation_status_label(materialization.validation_status)}",
        )
        println("- blockers: \{materialization.blocker_count}")
        println("- warnings: \{materialization.warning_count}")
        println("- sources: \{ingest.sources.length()}")
        println("- datasets: \{ingest.datasets.length()}")
      }
    Err(error) =>
      if output_json {
        println(error.to_json().stringify(indent=2))
      } else {
        println("Moonmoon data ingest failed")
        println("- code: \{error.code}")
        println("- path: \{error.path}")
        println("- message: \{error.message}")
      }
  }
}

///|
fn print_data_robot_model_ingest(
  args : Array[String],
  output_json : Bool,
) -> Unit {
  let root = data_robot_model_root(args)
  let source_dir = data_robot_model_source_dir(args)
  let model_id = data_robot_model_id(args)
  let robot_id = data_robot_id(args)
  match
    @robot_catalog.import_robot_model_package(
      @robot_catalog.robot_model_package_import_request(
        root, source_dir, model_id, robot_id, 1L,
      ),
    ) {
    Ok(result) =>
      if output_json {
        println(result.to_json().stringify(indent=2))
      } else {
        let materialization = result.materialization
        println("Moonmoon robot model data ingest")
        println("- root: \{materialization.root}")
        println("- source: \{result.source_dir}")
        println("- model: \{result.model_id}")
        println("- assets: \{result.asset_count}")
        println("- catalog: \{materialization.catalog_path}")
        println(
          "- validation: \{@data_core.validation_status_label(materialization.validation_status)}",
        )
        println("- blockers: \{materialization.blocker_count}")
        println("- warnings: \{materialization.warning_count}")
      }
    Err(error) =>
      if output_json {
        println(error.to_json().stringify(indent=2))
      } else {
        println("Moonmoon robot model ingest failed")
        println("- code: \{error.code}")
        println("- path: \{error.path}")
        println("- message: \{error.message}")
      }
  }
}

///|
fn print_data_robot_episode_ingest(
  args : Array[String],
  output_json : Bool,
) -> Unit {
  let root = data_robot_episode_root(args)
  let source_dir = data_robot_episode_source_dir(args)
  let dataset_id = data_robot_episode_dataset_id(args)
  let episode_id = data_robot_episode_id(args)
  let robot_id = data_robot_episode_robot_id(args)
  let model_id = data_robot_episode_model_id(args)
  match
    @robot_catalog.import_robot_episode_directory(
      @robot_catalog.robot_episode_directory_import_request(
        root, source_dir, dataset_id, episode_id, robot_id, model_id, 1L,
      ),
    ) {
    Ok(result) =>
      if output_json {
        println(result.to_json().stringify(indent=2))
      } else {
        let materialization = result.materialization
        println("Moonmoon robot episode data ingest")
        println("- root: \{materialization.root}")
        println("- source: \{result.source_dir}")
        println("- episode: \{result.episode_id}")
        println("- signals: \{result.signal_count}")
        println("- catalog: \{materialization.catalog_path}")
        println(
          "- validation: \{@data_core.validation_status_label(materialization.validation_status)}",
        )
        println("- blockers: \{materialization.blocker_count}")
        println("- warnings: \{materialization.warning_count}")
      }
    Err(error) =>
      if output_json {
        println(error.to_json().stringify(indent=2))
      } else {
        println("Moonmoon robot episode ingest failed")
        println("- code: \{error.code}")
        println("- path: \{error.path}")
        println("- message: \{error.message}")
      }
  }
}

///|
fn print_data_robot_telemetry_ingest(
  args : Array[String],
  output_json : Bool,
) -> Unit {
  let root = data_robot_telemetry_root(args)
  let source_dir = data_robot_telemetry_source_dir(args)
  let stream_id = data_robot_telemetry_stream_id(args)
  let robot_id = data_robot_telemetry_robot_id(args)
  let session_id = data_robot_telemetry_session_id(args)
  match
    @robot_catalog.import_robot_telemetry_directory(
      @robot_catalog.robot_telemetry_directory_import_request(
        root, source_dir, stream_id, robot_id, session_id, 1L,
      ),
    ) {
    Ok(result) =>
      if output_json {
        println(result.to_json().stringify(indent=2))
      } else {
        let materialization = result.materialization
        println("Moonmoon robot telemetry data ingest")
        println("- root: \{materialization.root}")
        println("- source: \{result.source_dir}")
        println("- stream: \{result.stream_id}")
        println("- payloads: \{result.payload_count}")
        println("- catalog: \{materialization.catalog_path}")
        println(
          "- validation: \{@data_core.validation_status_label(materialization.validation_status)}",
        )
        println("- blockers: \{materialization.blocker_count}")
        println("- warnings: \{materialization.warning_count}")
      }
    Err(error) =>
      if output_json {
        println(error.to_json().stringify(indent=2))
      } else {
        println("Moonmoon robot telemetry ingest failed")
        println("- code: \{error.code}")
        println("- path: \{error.path}")
        println("- message: \{error.message}")
      }
  }
}

///|
fn print_data_robot_gait_clip_ingest(
  args : Array[String],
  output_json : Bool,
) -> Unit {
  let root = data_robot_gait_clip_root(args)
  let source_dir = data_robot_gait_clip_source_dir(args)
  let clip_id = data_robot_gait_clip_id(args)
  let robot_id = data_robot_gait_clip_robot_id(args)
  let model_id = data_robot_gait_clip_model_id(args)
  match
    @robot_catalog.import_robot_gait_clip_directory(
      @robot_catalog.robot_gait_clip_directory_import_request(
        root, source_dir, clip_id, robot_id, model_id, 1L,
      ),
    ) {
    Ok(result) =>
      if output_json {
        println(result.to_json().stringify(indent=2))
      } else {
        let materialization = result.materialization
        println("Moonmoon robot gait clip data ingest")
        println("- root: \{materialization.root}")
        println("- source: \{result.source_dir}")
        println("- clip: \{result.clip_id}")
        println("- payloads: \{result.payload_count}")
        println("- catalog: \{materialization.catalog_path}")
        println(
          "- validation: \{@data_core.validation_status_label(materialization.validation_status)}",
        )
        println("- blockers: \{materialization.blocker_count}")
        println("- warnings: \{materialization.warning_count}")
      }
    Err(error) =>
      if output_json {
        println(error.to_json().stringify(indent=2))
      } else {
        println("Moonmoon robot gait clip ingest failed")
        println("- code: \{error.code}")
        println("- path: \{error.path}")
        println("- message: \{error.message}")
      }
  }
}

///|
fn print_data_robot_gait_annotation_ingest(
  args : Array[String],
  output_json : Bool,
) -> Unit {
  let root = data_robot_gait_annotation_root(args)
  let source_dir = data_robot_gait_annotation_source_dir(args)
  let annotation_id = data_robot_gait_annotation_id(args)
  let clip_id = data_robot_gait_annotation_clip_id(args)
  let robot_id = data_robot_gait_annotation_robot_id(args)
  let model_id = data_robot_gait_annotation_model_id(args)
  match
    @robot_catalog.import_robot_gait_annotation_directory(
      @robot_catalog.robot_gait_annotation_directory_import_request(
        root, source_dir, annotation_id, clip_id, robot_id, model_id, 1L,
      ),
    ) {
    Ok(result) =>
      if output_json {
        println(result.to_json().stringify(indent=2))
      } else {
        let materialization = result.materialization
        println("Moonmoon robot gait annotation data ingest")
        println("- root: \{materialization.root}")
        println("- source: \{result.source_dir}")
        println("- annotation: \{result.annotation_id}")
        println("- clip: \{result.clip_id}")
        println("- payloads: \{result.payload_count}")
        println("- catalog: \{materialization.catalog_path}")
        println(
          "- validation: \{@data_core.validation_status_label(materialization.validation_status)}",
        )
        println("- blockers: \{materialization.blocker_count}")
        println("- warnings: \{materialization.warning_count}")
      }
    Err(error) =>
      if output_json {
        println(error.to_json().stringify(indent=2))
      } else {
        println("Moonmoon robot gait annotation ingest failed")
        println("- code: \{error.code}")
        println("- path: \{error.path}")
        println("- message: \{error.message}")
      }
  }
}

///|
fn print_data_robot_gait_alignment_ingest(
  args : Array[String],
  output_json : Bool,
) -> Unit {
  let root = data_robot_gait_alignment_root(args)
  let source_dir = data_robot_gait_alignment_source_dir(args)
  let alignment_id = data_robot_gait_alignment_id(args)
  let episode_id = data_robot_gait_alignment_episode_id(args)
  let clip_id = data_robot_gait_alignment_clip_id(args)
  let annotation_id = data_robot_gait_alignment_annotation_id(args)
  let robot_id = data_robot_gait_alignment_robot_id(args)
  let model_id = data_robot_gait_alignment_model_id(args)
  match
    @robot_catalog.import_robot_gait_alignment_directory(
      @robot_catalog.robot_gait_alignment_directory_import_request(
        root, source_dir, alignment_id, episode_id, clip_id, annotation_id, robot_id,
        model_id, 1L,
      ),
    ) {
    Ok(result) =>
      if output_json {
        println(result.to_json().stringify(indent=2))
      } else {
        let materialization = result.materialization
        println("Moonmoon robot gait alignment data ingest")
        println("- root: \{materialization.root}")
        println("- source: \{result.source_dir}")
        println("- alignment: \{result.alignment_id}")
        println("- episode: \{result.episode_id}")
        println("- clip: \{result.clip_id}")
        println("- annotation: \{result.annotation_id}")
        println("- payloads: \{result.payload_count}")
        println("- catalog: \{materialization.catalog_path}")
        println(
          "- validation: \{@data_core.validation_status_label(materialization.validation_status)}",
        )
        println("- blockers: \{materialization.blocker_count}")
        println("- warnings: \{materialization.warning_count}")
      }
    Err(error) =>
      if output_json {
        println(error.to_json().stringify(indent=2))
      } else {
        println("Moonmoon robot gait alignment ingest failed")
        println("- code: \{error.code}")
        println("- path: \{error.path}")
        println("- message: \{error.message}")
      }
  }
}

///|
fn print_data_robot_task_label_ingest(
  args : Array[String],
  output_json : Bool,
) -> Unit {
  let root = data_robot_task_label_root(args)
  let source_dir = data_robot_task_label_source_dir(args)
  let task_label_id = data_robot_task_label_id(args)
  let episode_id = data_robot_task_label_episode_id(args)
  let alignment_id = data_robot_task_label_alignment_id(args)
  let robot_id = data_robot_task_label_robot_id(args)
  let model_id = data_robot_task_label_model_id(args)
  match
    @robot_catalog.import_robot_task_label_directory(
      @robot_catalog.robot_task_label_directory_import_request(
        root, source_dir, task_label_id, episode_id, alignment_id, robot_id, model_id,
        1L,
      ),
    ) {
    Ok(result) =>
      if output_json {
        println(result.to_json().stringify(indent=2))
      } else {
        let materialization = result.materialization
        println("Moonmoon robot task label data ingest")
        println("- root: \{materialization.root}")
        println("- source: \{result.source_dir}")
        println("- task-label: \{result.task_label_id}")
        println("- episode: \{result.episode_id}")
        println("- alignment: \{result.alignment_id}")
        println("- payloads: \{result.payload_count}")
        println("- catalog: \{materialization.catalog_path}")
        println(
          "- validation: \{@data_core.validation_status_label(materialization.validation_status)}",
        )
        println("- blockers: \{materialization.blocker_count}")
        println("- warnings: \{materialization.warning_count}")
      }
    Err(error) =>
      if output_json {
        println(error.to_json().stringify(indent=2))
      } else {
        println("Moonmoon robot task label ingest failed")
        println("- code: \{error.code}")
        println("- path: \{error.path}")
        println("- message: \{error.message}")
      }
  }
}

///|
fn print_data_robot_model_json(args : Array[String]) -> Unit {
  let root = data_robot_model_json_root(args)
  let model_id = data_robot_model_json_id(args)
  match @robot_catalog.robot_model_catalog_dossier_from_root(root, model_id) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_robot_episode_json(args : Array[String]) -> Unit {
  let root = data_robot_episode_json_root(args)
  let episode_id = data_robot_episode_json_id(args)
  match
    @robot_catalog.robot_episode_catalog_dossier_from_root(root, episode_id) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_robot_telemetry_json(args : Array[String]) -> Unit {
  let root = data_robot_telemetry_json_root(args)
  let stream_id = data_robot_telemetry_json_id(args)
  match
    @robot_catalog.robot_telemetry_catalog_dossier_from_root(root, stream_id) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_robot_gait_clip_json(args : Array[String]) -> Unit {
  let root = data_robot_gait_clip_json_root(args)
  let clip_id = data_robot_gait_clip_json_id(args)
  match
    @robot_catalog.robot_gait_clip_catalog_dossier_from_root(root, clip_id) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_robot_gait_annotation_json(args : Array[String]) -> Unit {
  let root = data_robot_gait_annotation_json_root(args)
  let annotation_id = data_robot_gait_annotation_json_id(args)
  match
    @robot_catalog.robot_gait_annotation_catalog_dossier_from_root(
      root, annotation_id,
    ) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_robot_gait_alignment_json(args : Array[String]) -> Unit {
  let root = data_robot_gait_alignment_json_root(args)
  let alignment_id = data_robot_gait_alignment_json_id(args)
  match
    @robot_catalog.robot_gait_alignment_catalog_dossier_from_root(
      root, alignment_id,
    ) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_robot_task_label_json(args : Array[String]) -> Unit {
  let root = data_robot_task_label_json_root(args)
  let task_label_id = data_robot_task_label_json_id(args)
  match
    @robot_catalog.robot_task_label_catalog_dossier_from_root(
      root, task_label_id,
    ) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_robot_json(args : Array[String]) -> Unit {
  let root = data_robot_json_root(args)
  match @robot_catalog.robot_catalog_root_dossier_from_root(root) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_robot_readiness_json(args : Array[String]) -> Unit {
  let root = data_robot_readiness_json_root(args)
  match @robot_catalog.robot_migration_readiness_from_root(root) {
    Ok(readiness) => println(readiness.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_site_json(args : Array[String]) -> Unit {
  let root = data_site_root(args)
  match @site_catalog.first_trusted_square_dossier_from_catalog_root(root) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_ui_json(args : Array[String]) -> Unit {
  let root = data_ui_json_root(args)
  match @ui.first_trusted_square_catalog_json(root) {
    Ok(json) => println(json.stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_ui_html(args : Array[String]) -> Unit {
  let root = data_ui_html_root(args)
  match @ui.first_trusted_square_catalog_html(root) {
    Ok(html) => println(html)
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn print_data_root_json(args : Array[String]) -> Unit {
  let root = data_root_json_root(args)
  match @data_validate.data_root_validation_summary_from_root(root) {
    Ok(summary) => println(summary.to_json().stringify(indent=2))
    Err(error) => println(error.to_json().stringify(indent=2))
  }
}

///|
fn main {
  let args = @env.args()
  let output_json = args.contains("json")
  if args.contains("help") {
    print_help()
  } else if args.contains("data") && args.contains("ingest-robot-task-label") {
    print_data_robot_task_label_ingest(args, output_json)
  } else if args.contains("data") &&
    args.contains("ingest-robot-gait-alignment") {
    print_data_robot_gait_alignment_ingest(args, output_json)
  } else if args.contains("data") &&
    args.contains("ingest-robot-gait-annotation") {
    print_data_robot_gait_annotation_ingest(args, output_json)
  } else if args.contains("data") && args.contains("ingest-robot-gait-clip") {
    print_data_robot_gait_clip_ingest(args, output_json)
  } else if args.contains("data") && args.contains("ingest-robot-telemetry") {
    print_data_robot_telemetry_ingest(args, output_json)
  } else if args.contains("data") && args.contains("ingest-robot-episode") {
    print_data_robot_episode_ingest(args, output_json)
  } else if args.contains("data") && args.contains("robot-readiness-json") {
    print_data_robot_readiness_json(args)
  } else if args.contains("data") && args.contains("robot-json") {
    print_data_robot_json(args)
  } else if args.contains("data") && args.contains("robot-telemetry-json") {
    print_data_robot_telemetry_json(args)
  } else if args.contains("data") && args.contains("robot-gait-clip-json") {
    print_data_robot_gait_clip_json(args)
  } else if args.contains("data") && args.contains("robot-gait-annotation-json") {
    print_data_robot_gait_annotation_json(args)
  } else if args.contains("data") && args.contains("robot-gait-alignment-json") {
    print_data_robot_gait_alignment_json(args)
  } else if args.contains("data") && args.contains("robot-task-label-json") {
    print_data_robot_task_label_json(args)
  } else if args.contains("data") && args.contains("robot-episode-json") {
    print_data_robot_episode_json(args)
  } else if args.contains("data") && args.contains("robot-model-json") {
    print_data_robot_model_json(args)
  } else if args.contains("data") && args.contains("ingest-robot-model") {
    print_data_robot_model_ingest(args, output_json)
  } else if args.contains("data") && args.contains("ui-html") {
    print_data_ui_html(args)
  } else if args.contains("data") && args.contains("ui-json") {
    print_data_ui_json(args)
  } else if args.contains("data") && args.contains("site-json") {
    print_data_site_json(args)
  } else if args.contains("data") && args.contains("root-json") {
    print_data_root_json(args)
  } else if args.contains("data") && args.contains("ingest-first-site") {
    print_data_ingest(args, output_json)
  } else if args.contains("layout") {
    print_layout(args)
  } else if args.contains("kernel") {
    if output_json {
      println(@kernel.system_kernel_json().stringify(indent=2))
    } else {
      println(@kernel.system_kernel_markdown())
    }
  } else if args.contains("terrain") {
    if output_json {
      println(@terrain.first_trusted_square_fixture_json().stringify(indent=2))
    } else {
      println(@terrain.first_trusted_square_fixture_markdown())
    }
  } else if args.contains("mission") && args.contains("horizon") {
    if output_json {
      println(
        @mission.first_trusted_square_northeast_stepout_horizon_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @mission.first_trusted_square_northeast_stepout_horizon_markdown(),
      )
    }
  } else if args.contains("mission") && args.contains("terrain") {
    if output_json {
      println(
        @mission.first_trusted_square_northeast_stepout_terrain_remediation_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @mission.first_trusted_square_northeast_stepout_terrain_remediation_markdown(),
      )
    }
  } else if args.contains("mission") && args.contains("energy") {
    if output_json {
      println(
        @mission.first_trusted_square_energy_remediation_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(@mission.first_trusted_square_energy_remediation_markdown())
    }
  } else if args.contains("ui") && args.contains("html") {
    println(@ui.first_trusted_square_html())
  } else if args.contains("ui") {
    if output_json {
      println(@ui.first_trusted_square_json().stringify(indent=2))
    } else {
      println(@ui.first_trusted_square_markdown())
    }
  } else if output_json {
    println(@site.first_trusted_square_json().stringify(indent=2))
  } else {
    println(@site.first_trusted_square_markdown())
  }
}
