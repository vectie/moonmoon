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
    #|  moon run cmd/main -- data ingest-first-site [data-root] [json]
    #|  moon run cmd/main -- data ingest-robot-model [data-root] [source-dir] [model-id] [robot-id] [json]
    #|  moon run cmd/main -- data ingest-robot-episode [data-root] [source-dir] [dataset-id] [episode-id] [robot-id] [model-id] [json]
    #|  moon run cmd/main -- data robot-model-json [data-root] [model-id]
    #|  moon run cmd/main -- data site-json [data-root]
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
fn print_data_robot_model_json(args : Array[String]) -> Unit {
  let root = data_robot_model_json_root(args)
  let model_id = data_robot_model_json_id(args)
  match @robot_catalog.robot_model_catalog_dossier_from_root(root, model_id) {
    Ok(dossier) => println(dossier.to_json().stringify(indent=2))
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
fn main {
  let args = @env.args()
  let output_json = args.contains("json")
  if args.contains("help") {
    print_help()
  } else if args.contains("data") && args.contains("ingest-robot-episode") {
    print_data_robot_episode_ingest(args, output_json)
  } else if args.contains("data") && args.contains("robot-model-json") {
    print_data_robot_model_json(args)
  } else if args.contains("data") && args.contains("ingest-robot-model") {
    print_data_robot_model_ingest(args, output_json)
  } else if args.contains("data") && args.contains("site-json") {
    print_data_site_json(args)
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
