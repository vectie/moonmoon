///|
pub(all) struct MoonbookAnswer {
  kind : String
  title : String
  body : String
  sources : Array[String]
  state : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonbookLocalizedAnswer {
  en_us : MoonbookAnswer
  zh_hans : MoonbookAnswer
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonbookRegistry {
  empty : MoonbookLocalizedAnswer
  blocked : MoonbookLocalizedAnswer
  window : MoonbookLocalizedAnswer
  terrain_source : MoonbookLocalizedAnswer
  robot_authority : MoonbookLocalizedAnswer
  project : MoonbookLocalizedAnswer
  unknown : MoonbookLocalizedAnswer
} derive(Debug, Eq, ToJson, FromJson)

///|
fn moonbook_answer(
  kind : String,
  title : String,
  body : String,
  sources : Array[String],
  state : String,
) -> MoonbookAnswer {
  { kind, title, body, sources, state }
}

///|
fn moonbook_localized_answer(
  en_us : MoonbookAnswer,
  zh_hans : MoonbookAnswer,
) -> MoonbookLocalizedAnswer {
  { en_us, zh_hans }
}

///|
fn moonbook_selected_route(view : TrustedSquareViewModel) -> RouteView {
  for route in view.routes {
    if route.route_id == view.selected_route_id {
      return route
    }
  }
  view.routes[0]
}

///|
fn moonbook_rounded_3(value : Double) -> Double {
  (value * 1000.0).round() / 1000.0
}

///|
pub fn moonbook_registry(view : TrustedSquareViewModel) -> MoonbookRegistry {
  let route = moonbook_selected_route(view)
  let recommended = route.illumination.recommended_window
  let terrain_source = view.source_panel.local_source_path
  let horizon_source = route.illumination.horizon_evidence_path
  let blockers_en = view.blockers.join("; ")
  let blockers_zh = view.blockers.join("；")
  let available_energy_wh = moonbook_rounded_3(
    recommended.terrain_available_energy_wh,
  )
  let longest_dark_hours = moonbook_rounded_3(recommended.longest_dark_hours)
  {
    empty: moonbook_localized_answer(
      moonbook_answer(
        "Question needed",
        "Enter a question first",
        "Ask about mission blockers, illumination windows, terrain sources, route authority, or project architecture.",
        [],
        "is-warning",
      ),
      moonbook_answer(
        "需要问题",
        "请先输入一个问题",
        "可以询问任务阻碍、光照窗口、地形来源、路线权限或项目架构。",
        [],
        "is-warning",
      ),
    ),
    blocked: moonbook_localized_answer(
      moonbook_answer(
        "Mission facts",
        "The mission is held by \{view.blockers.length()} controlling blockers",
        "The current decision is \{view.scorecard.decision}. \{blockers_en}. Next action: \{view.scorecard.next_action}",
        [terrain_source, "src/ui/view_model.mbt", "src/ui/motion_contract.mbt"],
        "is-answered",
      ),
      moonbook_answer(
        "任务事实",
        "任务因 \{view.blockers.length()} 个控制性阻碍而暂停",
        "当前决策为 \{view.scorecard.decision}。\{blockers_zh}。下一步：\{view.scorecard.next_action}",
        [terrain_source, "src/ui/view_model.mbt", "src/ui/motion_contract.mbt"],
        "is-answered",
      ),
    ),
    window: moonbook_localized_answer(
      moonbook_answer(
        "Moon + mission facts",
        "The ranked window is \{recommended.time_start_utc} to \{recommended.time_end_utc}",
        "Route \{route.route_id} has \{available_energy_wh} Wh available and \{longest_dark_hours} h longest darkness in this candidate window. It remains a candidate until every mission gate passes.",
        [
          horizon_source,
          route.illumination.power_window_source_path,
          "src/ui/route_overlay.mbt",
        ],
        "is-answered",
      ),
      moonbook_answer(
        "月球与任务事实",
        "排名最高的窗口是 \{recommended.time_start_utc} 至 \{recommended.time_end_utc}",
        "路线 \{route.route_id} 在该候选窗口可获得 \{available_energy_wh} Wh，最长黑暗期 \{longest_dark_hours} 小时。它仍是候选窗口，必须通过全部任务门控。",
        [
          horizon_source,
          route.illumination.power_window_source_path,
          "src/ui/route_overlay.mbt",
        ],
        "is-answered",
      ),
    ),
    terrain_source: moonbook_localized_answer(
      moonbook_answer(
        "Moon facts",
        "Terrain comes from locally registered LRO LOLA evidence",
        "The loaded trusted square contains \{view.terrain_cells.length()} cells. Elevation, slope, roughness, hazard, and confidence remain traceable to \{view.source_panel.authority}.",
        [
          terrain_source,
          view.source_panel.catalog_manifest_path,
          "src/ui/inspector.mbt",
        ],
        "is-answered",
      ),
      moonbook_answer(
        "月球事实",
        "地形来自本地登记的 LRO LOLA 证据",
        "加载的可信区域包含 \{view.terrain_cells.length()} 个网格。每个网格的高程、坡度、粗糙度、危险等级和置信度均可追溯到 \{view.source_panel.authority}。",
        [
          terrain_source,
          view.source_panel.catalog_manifest_path,
          "src/ui/inspector.mbt",
        ],
        "is-answered",
      ),
    ),
    robot_authority: moonbook_localized_answer(
      moonbook_answer(
        "Project boundary",
        "No — robot motion cannot authorize a route",
        "The Noetix E1 view is a non-authoritative adapter preview. Only the mission gate can authorize a route after terrain, power, and illumination evidence passes.",
        [
          "src/ui/motion_contract.mbt", "ui/rabbita-moon/main/main.mbt", "ui/rabbita-moon/main/moonbook.mbt",
        ],
        "is-answered",
      ),
      moonbook_answer(
        "项目边界",
        "不能：机器人运动无权批准路线",
        "Noetix E1 视图只是非权威适配器预览。只有任务门控可以在地形、电力与光照证据全部通过后批准路线。",
        [
          "src/ui/motion_contract.mbt", "ui/rabbita-moon/main/main.mbt", "ui/rabbita-moon/main/moonbook.mbt",
        ],
        "is-answered",
      ),
    ),
    project: moonbook_localized_answer(
      moonbook_answer(
        "Project facts",
        "MoonBit and Rabbita form the product core",
        "MoonBit produces the mission domain and semantic view; Rabbita renders the interface. JavaScript is limited to WebGL, browser history, and input adapters.",
        [
          "src/ui/view_model.mbt", "ui/rabbita-moon/main/main.mbt", "ui/rabbita-moon/main/moonbook.mbt",
        ],
        "is-answered",
      ),
      moonbook_answer(
        "项目事实",
        "MoonBit 与 Rabbita 构成产品核心",
        "MoonBit 生成任务领域模型和语义视图，Rabbita 渲染界面；JavaScript 仅处理 WebGL、浏览器历史和输入适配。",
        [
          "src/ui/view_model.mbt", "ui/rabbita-moon/main/main.mbt", "ui/rabbita-moon/main/moonbook.mbt",
        ],
        "is-answered",
      ),
    ),
    unknown: moonbook_localized_answer(
      moonbook_answer(
        "Outside registry",
        "Moonbook does not have enough evidence for that question",
        "Rephrase it or ask about blockers, illumination, terrain provenance, route authority, the robot boundary, or project architecture.",
        ["ui/rabbita-moon/main/moonbook.mbt"],
        "is-unknown",
      ),
      moonbook_answer(
        "超出登记范围",
        "Moonbook 中没有足够证据回答这个问题",
        "请换一种问法，或询问任务阻碍、光照、地形来源、路线权限、机器人边界或项目架构。",
        ["ui/rabbita-moon/main/moonbook.mbt"],
        "is-unknown",
      ),
    ),
  }
}

///|
pub fn moonbook_registry_json(view : TrustedSquareViewModel) -> Json {
  moonbook_registry(view).to_json()
}
