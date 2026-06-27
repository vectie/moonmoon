///|
pub(all) struct NoetixHighControlLimits {
  source_profile_path : String
  capability_id : String
  command_class : String
  max_x_abs_mps : Double
  max_yaw_abs_rad_s : Double
  max_duration_ms : Int
  telemetry_freshness_ms : Int
  heartbeat_ms : Int
  default_mode : String
  requires_approval : Bool
  requires_dry_run : Bool
  hardware_authority : String
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixWalkCommandSegment {
  segment_id : String
  start_frame_index : Int
  end_frame_index : Int
  start_time_s : Double
  duration_s : Double
  command_x_mps : Double
  command_yaw_rad_s : Double
  expected_distance_m : Double
  within_x_limit : Bool
  within_yaw_limit : Bool
  within_duration_limit : Bool
  requires_approval : Bool
  requires_dry_run : Bool
  executable_on_hardware : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixWalkCommandPlan {
  plan_id : String
  trace_id : String
  robot_id : String
  capability_id : String
  command_class : String
  frame_count : Int
  segment_count : Int
  total_duration_s : Double
  total_expected_distance_m : Double
  max_command_x_abs_mps : Double
  max_command_yaw_abs_rad_s : Double
  high_control_limits : NoetixHighControlLimits
  segments : Array[NoetixWalkCommandSegment]
  hardware_authority : String
  executable_on_hardware : Bool
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn noetix_high_control_limits() -> NoetixHighControlLimits {
  let robot = noetix_moon_walk_robot_profile()
  {
    source_profile_path: robot.source_profile_path,
    capability_id: "control.high.walk",
    command_class: "HighControl",
    max_x_abs_mps: 0.25,
    max_yaw_abs_rad_s: 0.5,
    max_duration_ms: 1500,
    telemetry_freshness_ms: 250,
    heartbeat_ms: 100,
    default_mode: "read-only",
    requires_approval: true,
    requires_dry_run: true,
    hardware_authority: "moonmoon-safety-gate-only",
    source_status: "moonrobo-profile-limits; command plan is dry-run review evidence",
  }
}

///|
fn max_segment_frames(limits : NoetixHighControlLimits, dt_s : Double) -> Int {
  if dt_s <= 0.0 {
    1
  } else {
    let frames = (limits.max_duration_ms.to_double() / 1000.0 / dt_s)
      .floor()
      .to_int()
    if frames < 1 {
      1
    } else {
      frames
    }
  }
}

///|
fn segment_status(
  within_x_limit : Bool,
  within_yaw_limit : Bool,
  within_duration_limit : Bool,
) -> String {
  if within_x_limit && within_yaw_limit && within_duration_limit {
    "dry-run-command-review"
  } else {
    "command-limit-review"
  }
}

///|
fn noetix_walk_command_segment(
  trace : NoetixMoonWalkTrace,
  limits : NoetixHighControlLimits,
  start_frame : Int,
  end_frame : Int,
) -> NoetixWalkCommandSegment {
  let frame_span = end_frame - start_frame
  let duration = if frame_span > 0 {
    frame_span.to_double() * trace.config.dt_s
  } else {
    0.0
  }
  let command_x = trace.config.speed_mps
  let command_yaw = 0.0
  let within_x = abs_double(command_x) <= limits.max_x_abs_mps
  let within_yaw = abs_double(command_yaw) <= limits.max_yaw_abs_rad_s
  let within_duration = duration * 1000.0 <= limits.max_duration_ms.to_double()
  let status = segment_status(within_x, within_yaw, within_duration)
  {
    segment_id: "segment-\{start_frame}-\{end_frame}",
    start_frame_index: start_frame,
    end_frame_index: end_frame,
    start_time_s: start_frame.to_double() * trace.config.dt_s,
    duration_s: duration,
    command_x_mps: command_x,
    command_yaw_rad_s: command_yaw,
    expected_distance_m: command_x * duration,
    within_x_limit: within_x,
    within_yaw_limit: within_yaw,
    within_duration_limit: within_duration,
    requires_approval: limits.requires_approval,
    requires_dry_run: limits.requires_dry_run,
    executable_on_hardware: false,
    status,
  }
}

///|
pub fn noetix_walk_command_plan(
  trace : NoetixMoonWalkTrace,
  limits? : NoetixHighControlLimits = noetix_high_control_limits(),
) -> NoetixWalkCommandPlan {
  let segments : Array[NoetixWalkCommandSegment] = []
  let max_frames = max_segment_frames(limits, trace.config.dt_s)
  let mut start = 0
  while start < trace.frame_count {
    let end = if start + max_frames > trace.frame_count {
      trace.frame_count
    } else {
      start + max_frames
    }
    segments.push(noetix_walk_command_segment(trace, limits, start, end))
    start = end
  }
  let mut total_duration = 0.0
  let mut total_distance = 0.0
  let mut max_x = 0.0
  let mut max_yaw = 0.0
  let mut limit_review_count = 0
  for segment in segments {
    total_duration += segment.duration_s
    total_distance += segment.expected_distance_m
    let x = abs_double(segment.command_x_mps)
    if x > max_x {
      max_x = x
    }
    let yaw = abs_double(segment.command_yaw_rad_s)
    if yaw > max_yaw {
      max_yaw = yaw
    }
    if segment.status == "command-limit-review" {
      limit_review_count += 1
    }
  }
  {
    plan_id: "moonrobo/noetix-e1/high-control-walk-plan/\{trace.terrain_tile_id}",
    trace_id: trace.trace_id,
    robot_id: trace.robot.robot_id,
    capability_id: limits.capability_id,
    command_class: limits.command_class,
    frame_count: trace.frame_count,
    segment_count: segments.length(),
    total_duration_s: total_duration,
    total_expected_distance_m: total_distance,
    max_command_x_abs_mps: max_x,
    max_command_yaw_abs_rad_s: max_yaw,
    high_control_limits: limits,
    segments,
    hardware_authority: limits.hardware_authority,
    executable_on_hardware: false,
    status: if limit_review_count > 0 {
      "walk-command-limit-review"
    } else {
      "walk-command-dry-run-review"
    },
    note: "Moonrobo high-level walk command plan segments the Noetix finite trace prefix into dry-run approval windows that respect the sibling robot profile limits. It is not hardware authority and does not enable execution.",
  }
}

///|
pub fn first_trusted_square_noetix_walk_command_plan() -> NoetixWalkCommandPlan {
  noetix_walk_command_plan(first_trusted_square_noetix_walk_trace())
}

///|
pub fn first_trusted_square_noetix_walk_command_json() -> Json {
  first_trusted_square_noetix_walk_command_plan().to_json()
}

///|
pub fn render_noetix_walk_command_markdown(
  plan : NoetixWalkCommandPlan,
) -> String {
  let mut text = "# Noetix High-Control Walk Command Plan\n\n"
  text += "- plan: \{plan.plan_id}\n"
  text += "- trace: \{plan.trace_id}\n"
  text += "- robot: \{plan.robot_id}\n"
  text += "- capability: \{plan.capability_id}\n"
  text += "- command class: \{plan.command_class}\n"
  text += "- frames: \{plan.frame_count}\n"
  text += "- segments: \{plan.segment_count}\n"
  text += "- total duration: \{plan.total_duration_s} s\n"
  text += "- expected distance: \{plan.total_expected_distance_m} m\n"
  text += "- max x command: \{plan.max_command_x_abs_mps} m/s\n"
  text += "- max yaw command: \{plan.max_command_yaw_abs_rad_s} rad/s\n"
  text += "- requires approval: \{plan.high_control_limits.requires_approval}\n"
  text += "- requires dry run: \{plan.high_control_limits.requires_dry_run}\n"
  text += "- executable on hardware: \{plan.executable_on_hardware}\n"
  text += "- hardware authority: \{plan.hardware_authority}\n"
  text += "- status: \{plan.status}\n"
  text += "- note: \{plan.note}\n\n"
  text += "## Command Segments\n\n"
  for segment in plan.segments {
    text += "- \{segment.segment_id}: frames \{segment.start_frame_index}..\{segment.end_frame_index} duration=\{segment.duration_s}s x=\{segment.command_x_mps}m/s yaw=\{segment.command_yaw_rad_s}rad/s status=\{segment.status}\n"
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_walk_command_markdown() -> String {
  render_noetix_walk_command_markdown(
    first_trusted_square_noetix_walk_command_plan(),
  )
}
