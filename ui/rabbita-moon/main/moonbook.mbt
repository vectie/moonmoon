///|
fn moonbook_topic(
  topic_id : String,
  title : String,
  detail : String,
  active? : Bool = false,
) -> Html {
  button(
    class=if active { "moonbook-topic active" } else { "moonbook-topic" },
    type_="button",
    attrs=@html.Attrs::build()
      .data_set("moonbook-topic", topic_id)
      .aria_pressed(if active { "true" } else { "false" }),
    [b(title), span(detail)],
  )
}

///|
fn quick_question(question_id : String, label : String) -> Html {
  button(
    class="quick-question",
    type_="button",
    attrs=@html.Attrs::build().data_set("bookkeeper-question", question_id),
    label,
  )
}

///|
fn moonbook_page(model : Model) -> Html {
  let view = model.view
  let selected_route = selected_route_view(view)
  section(
    id="moonbook-page",
    class="app-page moonbook-page",
    hidden=true,
    attrs=@html.Attrs::build().aria_label("Moonbook knowledge base and guide"),
    [
      header(class="moonbook-hero", [
        div([
          span(class="eyebrow", "Moonbook knowledge base"),
          h1("Ask what the Moon means for this mission"),
          p(
            "Evidence-grounded answers for lunar facts, mission decisions, and project boundaries.",
          ),
        ]),
        div(class="moonbook-trust", [
          span("Local knowledge"),
          strong("Source cited"),
          span("No network inference"),
        ]),
      ]),
      div(class="moonbook-layout", [
        section(class="moonbook-index", [
          header([
            span(class="eyebrow", "Browse the guide"),
            h2("Operational topics"),
          ]),
          div(class="moonbook-topics", [
            moonbook_topic(
              "mission",
              "Mission status",
              "Decision, blockers, and first action",
              active=true,
            ),
            moonbook_topic(
              "terrain", "Terrain evidence", "LOLA cells, hazards, and confidence",
            ),
            moonbook_topic(
              "lighting", "Illumination", "Current and ranked mission windows",
            ),
            moonbook_topic(
              "routes", "Route authority", "Selected route versus inspected candidates",
            ),
            moonbook_topic(
              "motion", "Robot boundary", "Why previews cannot authorize motion",
            ),
            moonbook_topic(
              "project", "Project architecture", "MoonBit, Rabbita, and evidence flow",
            ),
          ]),
        ]),
        section(
          class="moonbook-article",
          attrs=@html.Attrs::build().aria_live("polite"),
          [
            span(id="moonbook-topic-kind", class="eyebrow", "Mission guide"),
            h2(id="moonbook-topic-title", "Why the mission is blocked"),
            p(
              id="moonbook-topic-summary",
              "The current trusted-square decision is \{view.scorecard.decision}. Four controlling blockers must be cleared before route motion can be authorized.",
            ),
            div(class="moonbook-answer-grid", [
              article([
                span("First action"),
                b(id="moonbook-topic-action", view.scorecard.next_action),
              ]),
              article([
                span("Current authority"),
                b(
                  id="moonbook-topic-authority",
                  "Mission gate; not a robot preview",
                ),
              ]),
            ]),
            div(class="moonbook-source", [
              span("Evidence source"),
              p(id="moonbook-topic-source", view.source_panel.local_source_path),
            ]),
          ],
        ),
      ]),
      section(class="bookkeeper", [
        header(class="bookkeeper-header", [
          div([
            span(class="eyebrow", "Bookkeeper agent"),
            h2("Ask a Moon or project question"),
            p(
              "The bookkeeper answers only from the loaded mission model and the project knowledge registry.",
            ),
          ]),
          strong("Evidence-grounded local answer"),
        ]),
        div(class="quick-questions", [
          quick_question("blocked", "Why is the mission blocked?"),
          quick_question("window", "What is the best illumination window?"),
          quick_question("terrain-source", "Where does terrain data come from?"),
          quick_question(
            "robot-authority", "Can robot motion authorize a route?",
          ),
        ]),
        form(id="bookkeeper-form", class="bookkeeper-form", [
          textarea(
            id="bookkeeper-question",
            name="question",
            rows=3,
            maxlength=400,
            placeholder="Ask about the Moon, this mission, its evidence, or this project…",
            "",
          ),
          div(class="bookkeeper-actions", [
            button(
              id="bookkeeper-ask",
              class="bookkeeper-ask",
              type_="submit",
              "Ask bookkeeper",
            ),
            button(
              id="bookkeeper-clear",
              class="bookkeeper-clear",
              type_="button",
              "Clear",
            ),
          ]),
        ]),
        section(
          id="bookkeeper-answer",
          class="bookkeeper-answer is-empty",
          attrs=@html.Attrs::build()
            .aria_live("polite")
            .aria_label("Bookkeeper answer"),
          [
            span(id="bookkeeper-answer-kind", class="eyebrow", "Ready"),
            h2(id="bookkeeper-answer-title", "Ask a question to begin"),
            p(
              id="bookkeeper-answer-body",
              "Choose a common question or write your own. Answers distinguish Moon facts from project facts and cite their evidence.",
            ),
            ul(class="bookkeeper-citations", [
              li(id="bookkeeper-source-1", ""),
              li(id="bookkeeper-source-2", ""),
              li(id="bookkeeper-source-3", ""),
            ]),
          ],
        ),
      ]),
      section(class="moonbook-registry", [
        header([
          span(class="eyebrow", "Knowledge registry"),
          h2("What the bookkeeper is allowed to know"),
        ]),
        div([
          article([
            b("Moon facts"),
            p(
              "Terrain cells, coordinates, illumination geometry, and evidence provenance loaded in the trusted-square model.",
            ),
          ]),
          article([
            b("Mission facts"),
            p(
              "Decision gates, selected route \{selected_route.route_id}, candidates, blockers, and recommended actions.",
            ),
          ]),
          article([
            b("Project facts"),
            p(
              "MoonBit owns the domain model; Rabbita renders the UI; JavaScript adapters bind WebGL and browser events.",
            ),
          ]),
          article([
            b("Hard boundary"),
            p(
              "The bookkeeper does not invent telemetry, fetch remote sources, or grant route authority.",
            ),
          ]),
        ]),
      ]),
    ],
  )
}
