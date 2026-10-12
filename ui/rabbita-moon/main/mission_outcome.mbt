///|
fn mission_outcome_panel() -> Html {
  details(id="mission-outcome-panel", [
    summary("Send a digital outcome to Book"),
    p(
      "1 · Save a named digital review above. 2 · Describe what the completed simulation means and its limits. 3 · Export and import the file in Book → Product outcomes. These statements are yours; simulation acceptance does not establish real-world performance, customer acceptance or cash.",
    ),
    label([
      span("Exact completed session ID"),
      input(id="study-outcome-session", input_type=@html.Text),
    ]),
    label([
      span("Observation time in UTC, e.g. 2026-10-06T12:00:00Z"),
      input(id="study-outcome-observed", input_type=@html.Text),
    ]),
    label([
      span("Your digital outcome interpretation and limits"),
      textarea(id="study-outcome-summary", ""),
    ]),
    @html.div(
      ["information", "recognition", "decisiveness"].map(key => {
        @html.div([
          label([
            span(key + " gap severity (0 explicitly absent; 1–5 present)"),
            input(
              id="study-outcome-" + key + "-severity",
              input_type=@html.Text,
            ),
          ]),
          label([
            span(key + " gap explanation, including why absent when zero"),
            textarea(id="study-outcome-" + key + "-summary", ""),
          ]),
        ])
      }),
    ),
    p(
      "If a gap is present, the existing Book contract requires your proposed capability change. All three fields are required together; this does not approve or activate it.",
    ),
    label([
      span("Proposed capability ID (optional when all gaps absent)"),
      input(id="study-outcome-capability-id", input_type=@html.Text),
    ]),
    label([
      span("Proposed capability version"),
      input(id="study-outcome-capability-version", input_type=@html.Text),
    ]),
    label([
      span("Proposed capability change"),
      textarea(id="study-outcome-capability-summary", ""),
    ]),
    button(
      id="study-outcome-export",
      type_="button",
      "Export outcome and retained sources for Book",
    ),
    label([
      span("Open a Book disposition receipt (up to 16 MiB)"),
      input(
        id="study-outcome-receipt",
        input_type=@html.File,
        accept="application/json,.json",
      ),
    ]),
    @html.pre(id="study-outcome-readback", "No Book receipt opened"),
    button(id="study-outcome-reopen", type_="button", "Reopen original study"),
    button(
      id="study-outcome-result",
      type_="button",
      "Download received original result",
    ),
    p(
      id="study-outcome-status",
      attrs=@html.Attrs::build().role("status").aria_live("polite"),
      "Manual file handoff. Source review is evidence; Book makes its own decision. No physical authority.",
    ),
  ])
}
