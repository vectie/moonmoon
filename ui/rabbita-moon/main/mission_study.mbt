///|
/// An empty file-backed workspace, not a seeded example or mission authority.
fn mission_study_panel() -> Html {
  details(id="mission-study-panel", class="mission-study-panel", [
    summary("Save and compare a digital study"),
    p(
      "Import a completed dossier or reopen a saved study. The supported local host can run edited frozen inputs in the native digital simulator; nothing is sent to a robot.",
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
    div(id="study-sensitivity-matrix", class="study-matrix-scroll", ""),
    div(id="study-route-map", class="study-route-map", ""),
    details([
      summary("Fork a multi-variant sensitivity study"),
      p(
        "Edit frozen mission inputs, then Run digital mission. The loopback-only local host retains exact inputs, runs the native simulator and returns its real dossier. The original evidence and review stay separate. Optional offline export remains available.",
      ),
      label([
        span("Exact parent session ID to fork"),
        input(id="study-draft-parent-session", input_type=@html.Text),
      ]),
      button(id="study-draft-fork", type_="button", "Fork mission inputs"),
      button(id="study-draft-discard", type_="button", "Discard input draft"),
      label([
        span("Reopen an exported draft JSON (up to 16 MiB)"),
        input(
          id="study-draft-file",
          input_type=@html.File,
          accept="application/json,.json",
        ),
      ]),
      p(
        id="study-draft-baseline",
        class="study-comparison",
        "No mission draft open",
      ),
      label([
        span("New study ID"),
        input(id="study-draft-id", input_type=@html.Text),
      ]),
      label([
        span("New revision"),
        input(id="study-draft-revision", input_type=@html.Text),
      ]),
      p(
        id="study-draft-variants-status",
        "New forks start with two named variants and one reference",
      ),
      label([
        span("Variant to edit"),
        @html.select(
          id="study-draft-variant",
          @html.option(value="", "Fork or reopen a draft"),
        ),
      ]),
      label([
        span("Variant ID (1–64 letters, digits, hyphens or underscores)"),
        input(id="study-draft-variant-id", input_type=@html.Text),
      ]),
      label([
        span("Variant name (up to 120 characters)"),
        input(id="study-draft-variant-name", input_type=@html.Text),
      ]),
      button(id="study-draft-variant-add", type_="button", "Add variant"),
      button(
        id="study-draft-variant-duplicate",
        type_="button",
        "Duplicate selected variant",
      ),
      button(
        id="study-draft-variant-remove",
        type_="button",
        "Remove selected variant",
      ),
      label([
        span("Alternative route ID"),
        input(id="study-draft-route", input_type=@html.Text),
      ]),
      label([
        span("Route cells, one row,column pair per line (2–256)"),
        textarea(id="study-draft-cells", ""),
      ]),
      div(id="study-draft-map", class="study-route-graphic", ""),
      label([
        span("Assumed available energy (Wh)"),
        input(id="study-draft-energy", input_type=@html.Text),
      ]),
      label([
        span("Commanded speed (m/s)"),
        input(id="study-draft-speed", input_type=@html.Text),
      ]),
      label([
        span("Positive deterministic seed"),
        input(id="study-draft-seed", input_type=@html.Text),
      ]),
      label([
        span("Injected fault IDs, one per line; unknown models fail closed"),
        textarea(id="study-draft-faults", ""),
      ]),
      label([
        span("Changed assumptions and unresolved limits (required)"),
        textarea(id="study-draft-note", ""),
      ]),
      label([
        span("Optional MoonRobo robot-input package (up to 8 MiB)"),
        input(
          id="study-draft-robot",
          input_type=@html.File,
          accept="application/json,.json",
        ),
      ]),
      button(
        id="study-draft-original-robot",
        type_="button",
        "Use original robot",
      ),
      p(
        id="study-draft-robot-status",
        class="study-comparison",
        "No robot input selected",
      ),
      button(id="study-run-start", type_="button", "Run digital mission"),
      button(id="study-run-cancel", type_="button", "Cancel native run"),
      p(
        id="study-run-status",
        attrs=@html.Attrs::build().role("status").aria_live("polite"),
        "Ready when the supported local host is running. Progress reports observed native process phases; no percentage is estimated.",
      ),
      details([
        summary("Retained runs and reconnect"),
        label([
          span("Exact retained run ID"),
          input(id="study-run-id", input_type=@html.Text),
        ]),
        button(
          id="study-run-reconnect",
          type_="button",
          "Reconnect to retained run",
        ),
        button(id="study-run-open", type_="button", "Open completed result"),
        button(id="study-run-restore", type_="button", "Reopen retained inputs"),
        button(
          id="study-run-reconcile",
          type_="button",
          "Reconcile interrupted output",
        ),
        button(id="study-run-list", type_="button", "List retained runs"),
        p(
          id="study-run-retained",
          class="study-comparison",
          "No retained runs requested",
        ),
        p(
          "After reload, reconnect reads actual host state. Completed results open explicitly to preserve current edits; interrupted runs never restart automatically. Keep the host running while a native process finishes.",
        ),
      ]),
      button(id="study-draft-export", type_="button", "Export one frozen batch"),
      p(
        id="study-draft-command",
        class="study-comparison",
        "Export a draft to see its exact native command",
      ),
      p(
        id="study-draft-status",
        attrs=@html.Attrs::build().role("status").aria_live("polite"),
        "Unsubmitted drafts are local to this page until exported. Submitted exact inputs and native results are retained by the local host. Digital-only; no physical authority.",
      ),
    ]),
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
    mission_outcome_panel(),
    p(
      id="study-status",
      attrs=@html.Attrs::build().role("status").aria_live("polite"),
      "No study loaded. Optional E1 assembly remains unavailable. No physical authority.",
    ),
  ])
}
