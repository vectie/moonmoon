///|
fn mission_path_stage(decision : String, handoff_status : String) -> Int {
  if decision.contains("block") || decision.contains("gated") {
    3
  } else if handoff_status.contains("block") || handoff_status.contains("gated") {
    4
  } else {
    5
  }
}

///|
fn mission_path_step(
  number : Int,
  label : String,
  icon_name : String,
  current : Int,
  blocked : Bool,
) -> Html {
  let state = if number < current {
    "complete"
  } else if number == current && blocked {
    "blocked"
  } else if number == current {
    "current"
  } else {
    "next"
  }
  div(class="mission-path-step is-\{state}", [
    icon(icon_name),
    div([
      b(label),
      span(
        match state {
          "complete" => "Done"
          "blocked" => "Blocked"
          "current" => "Current"
          _ => "Next"
        },
      ),
    ]),
  ])
}

///|
fn mission_path(model : Model) -> Html {
  let view = model.view
  let blocked = status_class(view.scorecard.decision) == "is-blocked"
  let stage = mission_path_stage(view.scorecard.decision, model.contract.status)
  section(
    class=if blocked { "mission-path is-blocked" } else { "mission-path" },
    attrs=@html.Attrs::build().aria_label("Mission decision path"),
    [
      div(class="mission-path-head", [
        div([
          span(class="eyebrow", "Your outcome"),
          h2("Choose a safe route window"),
          p(view.scorecard.next_action),
        ]),
        button(
          id="review-blocking-evidence",
          class="decision-primary-action",
          type_="button",
          attrs=@html.Attrs::build().aria_label("Review blocking evidence"),
          [icon("search-check"), span("Review blockers")],
        ),
      ]),
      div(class="mission-path-rail", [
        mission_path_step(1, "Source", "database", stage, blocked),
        mission_path_step(2, "Inspect", "map-pinned", stage, blocked),
        mission_path_step(3, "Gate", "shield-check", stage, blocked),
        mission_path_step(4, "Handoff", "route", stage, blocked),
      ]),
      div(
        class=if blocked {
          "mission-path-result is-denied"
        } else {
          "mission-path-result"
        },
        attrs=@html.Attrs::build().role("status").aria_live("polite"),
        [
          b(
            if blocked {
              "Motion denied safely"
            } else {
              "Mission evidence ready"
            },
          ),
          span(view.scorecard.decision),
          @html.small("Simulation evidence cannot authorize robot motion"),
        ],
      ),
    ],
  )
}
