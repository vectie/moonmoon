///|
/// An empty file-backed workspace, not a seeded example or mission authority.
fn mission_study_panel() -> Html {
  details(id="mission-study-panel", class="mission-study-panel", [
    summary("Save and compare a digital study"),
    p(
      "Import a local dossier produced by the mission_study command. Frozen evidence stays in this browser; nothing is fetched or sent to a robot.",
    ),
    label([
      span("Local dossier JSON (up to 8 MiB)"),
      input(
        id="study-file",
        input_type=@html.File,
        accept="application/json,.json",
      ),
    ]),
    label([span("Study ID"), input(id="study-id", input_type=@html.Text)]),
    label([span("Revision"), input(id="study-revision", input_type=@html.Text)]),
    button(id="study-reopen", type_="button", "Reopen saved revision"),
    button(
      id="study-discard",
      type_="button",
      "Discard edits and reopen saved revision",
    ),
    p(id="study-comparison", class="study-comparison", "No study loaded"),
    label([
      span("Digital reviewer name"),
      input(id="study-reviewer", input_type=@html.Text),
    ]),
    label([
      span("Recommended session ID, or none"),
      input(id="study-choice", input_type=@html.Text),
    ]),
    label([
      span("Reason and unresolved limits"),
      textarea(id="study-rationale", ""),
    ]),
    button(id="study-save", type_="button", "Save study and digital review"),
    button(id="study-reconcile", type_="button", "Reconcile interrupted save"),
    label([
      span("Exact session ID to export"),
      input(id="study-export-session", input_type=@html.Text),
    ]),
    button(id="study-export", type_="button", "Export exact digital result"),
    p(
      id="study-status",
      attrs=@html.Attrs::build().role("status").aria_live("polite"),
      "No study loaded. Optional E1 assembly remains unavailable. No physical authority.",
    ),
  ])
}
