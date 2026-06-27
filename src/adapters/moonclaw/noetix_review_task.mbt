///|
pub(all) struct MoonClawNoetixReviewTask {
  task_id : String
  site_id : @core.SiteId
  robot_id : String
  priority : MoonClawJobPriority
  state : MoonClawReceiptStatus
  objective : String
  source_walk_trace_id : String
  source_static_support_report_id : String
  source_dynamic_stability_report_id : String
  source_link_pose_trace_id : String
  frame_count : Int
  static_support_review_frame_count : Int
  dynamic_stability_review_frame_count : Int
  link_pose_count_per_frame : Int
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  inputs : Array[MoonClawJobInput]
  artifacts : Array[MoonClawTaskArtifact]
  commands : Array[String]
  acceptance_criteria : Array[MoonClawAcceptanceCriterion]
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn noetix_walk_artifact(
  trace : @moonrobo.NoetixMoonWalkTrace,
) -> MoonClawTaskArtifact {
  let ready = trace.frame_count > 0 && trace.endless_axis == "+x"
  task_artifact(
    "noetix-endless-walk-trace",
    "output/moonrobo/first_trusted_square_noetix_walk.json",
    "moon run cmd/main -- moonrobo noetix walk json",
    "endless +x Noetix trace with lunar gravity, contact probes, and joint phases",
    "\{trace.frame_count} frames over \{trace.terrain_tile_id}; axis \{trace.endless_axis}; \{trace.robot.joint_count} referenced joints",
    ready,
    if ready {
      "none"
    } else {
      "walk trace must advance in +x with at least one generated frame"
    },
    "python3 scripts/check_moonrobo_noetix_walk.py output/moonrobo/first_trusted_square_noetix_walk.json",
  )
}

///|
fn noetix_link_pose_artifact(
  trace : @moonrobo.NoetixLinkPoseTrace,
) -> MoonClawTaskArtifact {
  let ready = trace.frame_count > 0 && trace.links_per_frame >= 25
  task_artifact(
    "noetix-urdf-reference-link-poses",
    "output/moonrobo/first_trusted_square_noetix_link_poses.json",
    "moon run cmd/main -- moonrobo noetix poses json",
    "URDF-reference link poses are present for each Noetix walk frame",
    "\{trace.frame_count} frames; \{trace.links_per_frame} links per frame; status \{trace.status}",
    ready,
    if ready {
      "none"
    } else {
      "link poses must preserve the compact Noetix URDF-reference tree"
    },
    "python3 scripts/check_moonrobo_noetix_link_poses.py output/moonrobo/first_trusted_square_noetix_link_poses.json",
  )
}

///|
fn noetix_static_support_artifact(
  report : @moonrobo.NoetixWalkStabilityReport,
) -> MoonClawTaskArtifact {
  task_artifact(
    "noetix-static-support-review",
    "output/moonrobo/first_trusted_square_noetix_stability.json",
    "moon run cmd/main -- moonrobo noetix stability json",
    "static support evidence is reviewed before any dynamic-walk or hardware claim",
    "\{report.review_frame_count}/\{report.frame_count} frames require support review; worst planar margin \{report.worst_planar_margin_m} m; status \{report.status}",
    report.review_frame_count == 0 && report.status == "static-support-ok",
    "static COM support is review-only until dynamic stability and controller evidence exist",
    "python3 scripts/check_moonrobo_noetix_stability.py output/moonrobo/first_trusted_square_noetix_stability.json",
  )
}

///|
fn noetix_dynamic_stability_artifact(
  report : @moonrobo.NoetixDynamicStabilityReport,
) -> MoonClawTaskArtifact {
  task_artifact(
    "noetix-dynamic-stability-review",
    "output/moonrobo/first_trusted_square_noetix_dynamics.json",
    "moon run cmd/main -- moonrobo noetix dynamics json",
    "capture-point dynamic stability evidence is reviewed before any stronger walking claim",
    "\{report.review_frame_count}/\{report.frame_count} frames require capture-point review; worst capture margin \{report.worst_capture_margin_m} m; status \{report.status}",
    report.review_frame_count == 0 && report.status == "dynamic-stability-ok",
    "capture-point evidence is review-only until controller, actuator, inertia, and collision evidence exist",
    "python3 scripts/check_moonrobo_noetix_dynamics.py output/moonrobo/first_trusted_square_noetix_dynamics.json",
  )
}

///|
fn noetix_rabbita_artifact() -> MoonClawTaskArtifact {
  task_artifact(
    "noetix-rabbita-playback", "output/ui/rabbita/first_trusted_square.html", "scripts/build_rabbita_ui.sh",
    "Rabbita renders Noetix walk, link-pose skeleton, frame controls, and simulation-only authority",
    "Noetix panel consumes walk and link-pose JSON with skeleton playback", true,
    "none", "python3 scripts/check_rabbita_noetix_walk.py",
  )
}

///|
pub fn noetix_review_task_blocked_artifact_count(
  task : MoonClawNoetixReviewTask,
) -> Int {
  let mut count = 0
  for artifact in task.artifacts {
    if !artifact.ready {
      count += 1
    }
  }
  count
}

///|
pub fn first_trusted_square_noetix_review_task() -> MoonClawNoetixReviewTask {
  let walk = @moonrobo.first_trusted_square_noetix_walk_trace()
  let support = @moonrobo.first_trusted_square_noetix_stability_report()
  let dynamic = @moonrobo.first_trusted_square_noetix_dynamic_stability_report()
  let poses = @moonrobo.first_trusted_square_noetix_link_pose_trace()
  {
    task_id: "moonclaw/first-trusted-square/noetix-review-task",
    site_id: "first-trusted-square",
    robot_id: walk.robot.robot_id,
    priority: High,
    state: Accepted,
    objective: "Review the Noetix endless moon-walk simulation evidence as one MoonClaw work packet before any stronger dynamics or hardware-authority claim.",
    source_walk_trace_id: walk.trace_id,
    source_static_support_report_id: support.report_id,
    source_dynamic_stability_report_id: dynamic.report_id,
    source_link_pose_trace_id: poses.trace_id,
    frame_count: walk.frame_count,
    static_support_review_frame_count: support.review_frame_count,
    dynamic_stability_review_frame_count: dynamic.review_frame_count,
    link_pose_count_per_frame: poses.links_per_frame,
    hardware_state: @moonrobo.MoonroboExecutionState::HardwareDenied,
    hardware_authority: "moonmoon-safety-gate-only",
    hardware_denied: true,
    inputs: [
      input(
        "noetix-walk-trace",
        "output/moonrobo/first_trusted_square_noetix_walk.json",
        @core.ClaimKind::Simulated,
        "Kinematic endless +x Noetix walk trace over Moonmoon terrain.",
      ),
      input(
        "noetix-link-poses",
        "output/moonrobo/first_trusted_square_noetix_link_poses.json",
        @core.ClaimKind::Simulated,
        "URDF-reference link-pose trace bound to the walk frames and contact probes.",
      ),
      input(
        "noetix-static-support",
        "output/moonrobo/first_trusted_square_noetix_stability.json",
        @core.ClaimKind::Simulated,
        "Static COM/support report that explicitly remains review-only for dynamic walking.",
      ),
      input(
        "noetix-dynamic-stability",
        "output/moonrobo/first_trusted_square_noetix_dynamics.json",
        @core.ClaimKind::Simulated,
        "Capture-point dynamic stability report that remains review-only without controller and inertia evidence.",
      ),
      input(
        "noetix-rabbita-playback",
        "output/ui/rabbita/first_trusted_square.html",
        @core.ClaimKind::Derived,
        "Rabbita playback for inspecting the walk and link-pose skeleton.",
      ),
    ],
    artifacts: [
      noetix_walk_artifact(walk),
      noetix_link_pose_artifact(poses),
      noetix_static_support_artifact(support),
      noetix_dynamic_stability_artifact(dynamic),
      noetix_rabbita_artifact(),
    ],
    commands: [
      "python3 scripts/check_moonrobo_noetix_walk.py output/moonrobo/first_trusted_square_noetix_walk.json",
      "python3 scripts/check_moonrobo_noetix_link_poses.py output/moonrobo/first_trusted_square_noetix_link_poses.json",
      "python3 scripts/check_moonrobo_noetix_stability.py output/moonrobo/first_trusted_square_noetix_stability.json",
      "python3 scripts/check_moonrobo_noetix_dynamics.py output/moonrobo/first_trusted_square_noetix_dynamics.json",
      "python3 scripts/check_rabbita_noetix_walk.py", "python3 scripts/check_moonclaw_noetix_review_task.py output/moonclaw/first_trusted_square_noetix_review_task.json",
      "/Users/kq/.moon/bin/moon test",
    ],
    acceptance_criteria: [
      criterion(
        "all-noetix-evidence-linked", "Task links walk, link poses, static support, dynamic stability, and Rabbita playback evidence with concrete validation commands.",
      ),
      criterion(
        "review-only-static-support-preserved", "Static support review frames remain explicit blockers for dynamic walking evidence.",
      ),
      criterion(
        "review-only-dynamic-stability-preserved", "Capture-point review frames remain explicit blockers until controller and inertia evidence exist.",
      ),
      criterion(
        "hardware-denial-preserved", "MoonRobo hardware_state remains HardwareDenied and authority remains moonmoon-safety-gate-only.",
      ),
      criterion(
        "next-physics-step-clear", "Task names dynamic stability/controller evidence as the next requirement before stronger simulation claims.",
      ),
    ],
    safety_gate: "Do not convert the Noetix walk trace, link poses, or static support report into hardware authority. Dynamic stability and controller evidence must be added before any claim beyond simulation review.",
    next_action: "Use this task to review contact, link-pose, and static-support evidence; then add dynamic stability/controller evidence or keep hardware denied.",
  }
}

///|
pub fn first_trusted_square_noetix_review_tasks() -> Array[
  MoonClawNoetixReviewTask,
] {
  [first_trusted_square_noetix_review_task()]
}

///|
pub fn render_noetix_review_tasks_markdown(
  tasks : Array[MoonClawNoetixReviewTask],
) -> String {
  let mut text = "# MoonClaw Noetix Review Tasks\n\n"
  for task in tasks {
    text += "- \{task.task_id}\n"
    text += "  - priority: \{priority_label(task.priority)}\n"
    text += "  - state: \{receipt_status_label(task.state)}\n"
    text += "  - robot: \{task.robot_id}\n"
    text += "  - frames: \{task.frame_count}\n"
    text += "  - link poses per frame: \{task.link_pose_count_per_frame}\n"
    text += "  - static-support review frames: \{task.static_support_review_frame_count}\n"
    text += "  - dynamic-stability review frames: \{task.dynamic_stability_review_frame_count}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(task.hardware_state)}\n"
    text += "  - hardware authority: \{task.hardware_authority}\n"
    text += "  - safety gate: \{task.safety_gate}\n"
    text += "  - next action: \{task.next_action}\n"
    text += "  - inputs:\n"
    for input in task.inputs {
      text += "    - \{input.input_id}: \{input.evidence_path} - \{input.summary}\n"
    }
    text += "  - artifacts:\n"
    for artifact in task.artifacts {
      text += "    - \{artifact.artifact_id}: \{artifact.path}\n"
      text += "      - current: \{artifact.current_state}\n"
      text += "      - ready: \{artifact.ready}\n"
      text += "      - blocking: \{artifact.blocking_reason}\n"
      text += "      - gate: \{artifact.validation_gate}\n"
    }
    text += "  - commands:\n"
    for command in task.commands {
      text += "    - \{command}\n"
    }
    text += "  - acceptance:\n"
    for acceptance in task.acceptance_criteria {
      text += "    - \{acceptance.criterion_id}: \{acceptance.description}\n"
    }
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_review_tasks_markdown() -> String {
  render_noetix_review_tasks_markdown(
    first_trusted_square_noetix_review_tasks(),
  )
}

///|
pub fn render_noetix_review_tasks_json(
  tasks : Array[MoonClawNoetixReviewTask],
) -> Json {
  tasks.to_json()
}

///|
pub fn first_trusted_square_noetix_review_tasks_json() -> Json {
  render_noetix_review_tasks_json(first_trusted_square_noetix_review_tasks())
}
