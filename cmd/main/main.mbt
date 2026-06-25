///|
fn print_help() -> Unit {
  let help =
    #|Moonmoon CLI
    #|
    #|Commands:
    #|  moon run cmd/main
    #|  moon run cmd/main -- kernel
    #|  moon run cmd/main -- kernel json
    #|  moon run cmd/main -- site summary
    #|  moon run cmd/main -- site summary json
    #|  moon run cmd/main -- terrain fixture
    #|  moon run cmd/main -- terrain fixture json
    #|  moon run cmd/main -- mission horizon
    #|  moon run cmd/main -- mission horizon json
    #|  moon run cmd/main -- mission terrain
    #|  moon run cmd/main -- mission terrain json
    #|  moon run cmd/main -- mission energy
    #|  moon run cmd/main -- mission energy json
    #|  moon run cmd/main -- ui view
    #|  moon run cmd/main -- ui view json
    #|  moon run cmd/main -- ui rabbita
    #|  moon run cmd/main -- moonbook dossier
    #|  moon run cmd/main -- moonbook dossier json
    #|  moon run cmd/main -- moonclaw proposals
    #|  moon run cmd/main -- moonclaw proposals json
    #|  moon run cmd/main -- moonclaw ephemeris tasks
    #|  moon run cmd/main -- moonclaw ephemeris tasks json
    #|  moon run cmd/main -- moonclaw corridor tasks
    #|  moon run cmd/main -- moonclaw corridor tasks json
    #|  moon run cmd/main -- moonclaw remediation margins
    #|  moon run cmd/main -- moonclaw remediation margins json
    #|  moon run cmd/main -- moonclaw remediation refresh
    #|  moon run cmd/main -- moonclaw remediation refresh json
    #|  moon run cmd/main -- moonclaw remediation refresh followup
    #|  moon run cmd/main -- moonclaw remediation refresh followup json
    #|  moon run cmd/main -- moonclaw remediation refresh followup receipts
    #|  moon run cmd/main -- moonclaw remediation refresh followup receipts json
    #|  moon run cmd/main -- moonclaw remediation refresh receipts
    #|  moon run cmd/main -- moonclaw remediation refresh receipts json
    #|  moon run cmd/main -- moonclaw remediation receipts
    #|  moon run cmd/main -- moonclaw remediation receipts json
    #|  moon run cmd/main -- moonclaw receipts
    #|  moon run cmd/main -- moonclaw receipts json
    #|  moon run cmd/main -- moonclaw ephemeris receipts
    #|  moon run cmd/main -- moonclaw ephemeris receipts json
    #|  moon run cmd/main -- moonclaw corridor receipts
    #|  moon run cmd/main -- moonclaw corridor receipts json
    #|  moon run cmd/main -- moonrobo handoff
    #|  moon run cmd/main -- moonrobo handoff json
    #|  moon run cmd/main -- moonrobo remediation margins
    #|  moon run cmd/main -- moonrobo remediation margins json
    #|  moon run cmd/main -- moonrobo remediation refresh modeling
    #|  moon run cmd/main -- moonrobo remediation refresh modeling json
    #|  moon run cmd/main -- moonrobo remediation refresh followup modeling
    #|  moon run cmd/main -- moonrobo remediation refresh followup modeling json
    #|  moon run cmd/main -- moonrobo remediation refresh followup projection
    #|  moon run cmd/main -- moonrobo remediation refresh followup projection json
    #|  moon run cmd/main -- moonrobo remediation refresh projection
    #|  moon run cmd/main -- moonrobo remediation refresh projection json
    #|  moon run cmd/main -- moonrobo remediation projection
    #|  moon run cmd/main -- moonrobo remediation projection json
    #|
  println(help)
}

///|
fn main {
  let args = @env.args()
  let output_json = args.contains("json")
  if args.contains("help") {
    print_help()
  } else if args.contains("kernel") {
    if output_json {
      println(@kernel.system_kernel_json().stringify(indent=2))
    } else {
      println(@kernel.system_kernel_markdown())
    }
  } else if args.contains("moonclaw") &&
    args.contains("ephemeris") &&
    args.contains("tasks") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_ephemeris_tasks_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(@moonclaw.first_trusted_square_ephemeris_tasks_markdown())
    }
  } else if args.contains("moonclaw") &&
    args.contains("corridor") &&
    args.contains("tasks") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_corridor_tasks_json().stringify(indent=2),
      )
    } else {
      println(@moonclaw.first_trusted_square_corridor_tasks_markdown())
    }
  } else if args.contains("moonclaw") &&
    args.contains("remediation") &&
    args.contains("refresh") &&
    args.contains("followup") &&
    args.contains("receipts") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_remediation_margin_refresh_followup_receipts_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonclaw.first_trusted_square_remediation_margin_refresh_followup_receipts_markdown(),
      )
    }
  } else if args.contains("moonclaw") &&
    args.contains("remediation") &&
    args.contains("refresh") &&
    args.contains("followup") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_remediation_margin_refresh_followup_tasks_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonclaw.first_trusted_square_remediation_margin_refresh_followup_tasks_markdown(),
      )
    }
  } else if args.contains("moonclaw") &&
    args.contains("remediation") &&
    args.contains("refresh") &&
    args.contains("receipts") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_remediation_margin_refresh_receipts_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonclaw.first_trusted_square_remediation_margin_refresh_receipts_markdown(),
      )
    }
  } else if args.contains("moonclaw") &&
    args.contains("remediation") &&
    args.contains("refresh") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_remediation_margin_refresh_tasks_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonclaw.first_trusted_square_remediation_margin_refresh_tasks_markdown(),
      )
    }
  } else if args.contains("moonclaw") &&
    args.contains("remediation") &&
    args.contains("receipts") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_remediation_margin_receipts_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonclaw.first_trusted_square_remediation_margin_receipts_markdown(),
      )
    }
  } else if args.contains("moonclaw") &&
    args.contains("remediation") &&
    args.contains("margins") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_remediation_margin_tasks_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonclaw.first_trusted_square_remediation_margin_tasks_markdown(),
      )
    }
  } else if args.contains("moonclaw") &&
    args.contains("ephemeris") &&
    args.contains("receipts") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_ephemeris_receipts_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(@moonclaw.first_trusted_square_ephemeris_receipts_markdown())
    }
  } else if args.contains("moonclaw") &&
    args.contains("corridor") &&
    args.contains("receipts") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_corridor_receipts_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(@moonclaw.first_trusted_square_corridor_receipts_markdown())
    }
  } else if args.contains("moonclaw") && args.contains("receipts") {
    if output_json {
      println(
        @moonclaw.first_trusted_square_receipts_json().stringify(indent=2),
      )
    } else {
      println(@moonclaw.first_trusted_square_receipts_markdown())
    }
  } else if args.contains("moonclaw") && args.contains("proposals") {
    if output_json {
      println(@moonclaw.first_trusted_square_json().stringify(indent=2))
    } else {
      println(@moonclaw.first_trusted_square_markdown())
    }
  } else if args.contains("moonrobo") && args.contains("handoff") {
    if output_json {
      println(@moonrobo.first_trusted_square_json().stringify(indent=2))
    } else {
      println(@moonrobo.first_trusted_square_markdown())
    }
  } else if args.contains("moonrobo") &&
    args.contains("remediation") &&
    args.contains("refresh") &&
    args.contains("followup") &&
    args.contains("modeling") {
    if output_json {
      println(
        @moonrobo.first_trusted_square_remediation_margin_refresh_followup_modeling_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonrobo.first_trusted_square_remediation_margin_refresh_followup_modeling_markdown(),
      )
    }
  } else if args.contains("moonrobo") &&
    args.contains("remediation") &&
    args.contains("refresh") &&
    args.contains("modeling") {
    if output_json {
      println(
        @moonrobo.first_trusted_square_remediation_margin_refresh_modeling_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonrobo.first_trusted_square_remediation_margin_refresh_modeling_markdown(),
      )
    }
  } else if args.contains("moonrobo") &&
    args.contains("remediation") &&
    args.contains("refresh") &&
    args.contains("followup") &&
    args.contains("projection") {
    if output_json {
      println(
        @moonrobo.first_trusted_square_remediation_margin_refresh_followup_projection_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonrobo.first_trusted_square_remediation_margin_refresh_followup_projection_markdown(),
      )
    }
  } else if args.contains("moonrobo") &&
    args.contains("remediation") &&
    args.contains("refresh") &&
    args.contains("projection") {
    if output_json {
      println(
        @moonrobo.first_trusted_square_remediation_margin_refresh_projection_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonrobo.first_trusted_square_remediation_margin_refresh_projection_markdown(),
      )
    }
  } else if args.contains("moonrobo") &&
    args.contains("remediation") &&
    args.contains("projection") {
    if output_json {
      println(
        @moonrobo.first_trusted_square_remediation_margin_projection_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonrobo.first_trusted_square_remediation_margin_projection_markdown(),
      )
    }
  } else if args.contains("moonrobo") &&
    args.contains("remediation") &&
    args.contains("margins") {
    if output_json {
      println(
        @moonrobo.first_trusted_square_remediation_margin_modeling_json().stringify(
          indent=2,
        ),
      )
    } else {
      println(
        @moonrobo.first_trusted_square_remediation_margin_modeling_markdown(),
      )
    }
  } else if args.contains("moonbook") && args.contains("dossier") {
    if output_json {
      println(@moonbook.first_trusted_square_book_json().stringify(indent=2))
    } else {
      println(@moonbook.first_trusted_square_book_markdown())
    }
  } else if args.contains("terrain") && args.contains("fixture") {
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
  } else if args.contains("ui") && args.contains("rabbita") {
    println(@rabbita_moon.first_trusted_square_html())
  } else if args.contains("ui") && args.contains("view") {
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
