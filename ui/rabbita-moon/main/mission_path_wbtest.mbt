///|
test "mission path keeps blocked motion at the evidence gate" {
  inspect(mission_path_stage("blocked", "gated"), content="3")
  inspect(mission_path_stage("review", "gated"), content="4")
  inspect(mission_path_stage("ready", "ready"), content="5")
}

///|
#warnings("-alert_unstable")
test "mission path renders next action denial and physical boundary" {
  let model = init_model()
  let page = @rabbita.static_cell(mission_path(model))
  let html = @rabbita.render_to_string(page)
  inspect(html.contains("Choose a safe route window"), content="true")
  inspect(html.contains("Review blockers"), content="true")
  inspect(
    html.contains("Simulation evidence cannot authorize robot motion"),
    content="true",
  )
}
