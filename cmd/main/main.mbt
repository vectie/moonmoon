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
fn print_layout(args : Array[String]) -> Unit {
  let root = arg_after(args, "layout", ".")
  let book_id = arg_after(args, root, "<book-id>")
  let home = @moonmoon.moonsuite_product_home_for_workspace_root(root, book_id~)
  println(home.to_json().stringify(indent=2))
}

///|
fn main {
  let args = @env.args()
  let output_json = args.contains("json")
  if args.contains("help") {
    print_help()
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
