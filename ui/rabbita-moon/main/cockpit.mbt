///|
fn icon(name : String) -> Html {
  span(
    class="control-icon-glyph",
    attrs=@html.Attrs::build().data_set("lucide", name),
    "",
  )
}

///|
fn stage_control(
  id : String,
  label : String,
  icon_name : String,
  primary? : Bool = false,
) -> Html {
  let klass = if primary {
    "control icon-control primary"
  } else {
    "control icon-control"
  }
  button(
    id~,
    class=klass,
    type_="button",
    attrs=@html.Attrs::build().aria_label(label),
    [icon(icon_name), span(class="control-tooltip", label)],
  )
}

///|
fn suite_bar(view : @ui.TrustedSquareViewModel) -> Html {
  header(class="suite-bar", [
    div(class="suite-brand", [
      span(class="suite-wordmark", "MM"),
      div([b("Moonmoon"), span("Lunar operator")]),
    ]),
    div(class="suite-context", [
      span(class="eyebrow", "First trusted square"),
      b(view.title),
    ]),
    div(class="suite-health", [
      span(class="signal-dot", ""),
      span("Evidence loaded"),
      strong(
        class=status_class(view.scorecard.decision),
        view.scorecard.decision,
      ),
    ]),
  ])
}

///|
fn decision_overview(view : @ui.TrustedSquareViewModel) -> Html {
  section(class="decision-overview", [
    div(class="decision-action", [
      span(class="eyebrow", "Next required action"),
      p(view.scorecard.next_action),
    ]),
    div(class="decision-facts", [
      span([b("\{view.scorecard.score}"), span("Site score")]),
      span([b("\{view.scorecard.energy_margin_wh} Wh"), span("Energy margin")]),
      span([
        b("\{view.scorecard.blocked_route_candidates}"),
        span("Blocked routes"),
      ]),
    ]),
    div(class="controlling-blockers", [
      span(class="eyebrow", "Controlling blockers"),
      blocker_list(view),
    ]),
  ])
}

///|
fn evidence_handoff_disclosure(model : Model) -> Html {
  let view = model.view
  details(class="rail-disclosure evidence-handoff", [
    summary([
      div([
        b("Evidence and handoff"),
        span("source authority and adapter boundary"),
      ]),
      strong(class=status_class(model.contract.status), model.contract.status),
    ]),
    div(class="disclosure-body", [
      section(class="source-claim", [
        span(class="eyebrow", "Evidence authority"),
        b(view.source_panel.source_title),
        p(view.source_panel.local_source_path),
      ]),
      section(class="next-evidence", [
        span(class="eyebrow", "Motion handoff"),
        strong(model.contract.status),
        p(model.contract.next_action),
      ]),
    ]),
  ])
}
