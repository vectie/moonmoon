///|
pub(all) struct NoetixMoonWalkRobotProfile {
  robot_id : String
  label : String
  source_suite : String
  source_model_path : String
  source_profile_path : String
  joint_count : Int
  model_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixMoonWalkConfig {
  config_id : String
  gravity_mps2 : Double
  dt_s : Double
  speed_mps : Double
  step_length_m : Double
  step_height_m : Double
  cycle_frames : Int
  lateral_foot_offset_m : Double
  min_swing_clearance_m : Double
  caution_grade : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixFootContactProbe {
  foot_id : String
  position : @moonphys.Vec3
  terrain_elevation_m : Double
  clearance_m : Double
  in_contact : Bool
  local_grade : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixMoonWalkFrame {
  frame_index : Int
  time_s : Double
  body_position : @moonphys.Vec3
  support_phase : String
  left_foot : NoetixFootContactProbe
  right_foot : NoetixFootContactProbe
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixMoonWalkTrace {
  trace_id : String
  robot : NoetixMoonWalkRobotProfile
  config : NoetixMoonWalkConfig
  terrain_tile_id : String
  terrain_cell_size_m : Double
  frame_count : Int
  endless_axis : String
  frames : Array[NoetixMoonWalkFrame]
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn noetix_moon_walk_robot_profile() -> NoetixMoonWalkRobotProfile {
  {
    robot_id: "noetix-e1-lab-01",
    label: "Noetix E1 Lab 01",
    source_suite: "moonrobo",
    source_model_path: "../moonrobo/examples/noetix-e1/model/robot.urdf",
    source_profile_path: "../moonrobo/examples/noetix-e1/robot.json",
    joint_count: 24,
    model_status: "kinematic-urdf-reference; dynamics metadata pending",
  }
}

///|
pub fn default_noetix_moon_walk_config() -> NoetixMoonWalkConfig {
  {
    config_id: "moonrobo/noetix-e1/endless-forward-moon-walk-v0",
    gravity_mps2: @moonphys.lunar_environment().gravity_mps2,
    dt_s: 0.1,
    speed_mps: 0.12,
    step_length_m: 0.16,
    step_height_m: 0.045,
    cycle_frames: 20,
    lateral_foot_offset_m: 0.08,
    min_swing_clearance_m: 0.02,
    caution_grade: 0.18,
  }
}

///|
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    0.0 - value
  } else {
    value
  }
}

///|
fn wrapped_index(index : Int, length : Int) -> Int {
  if length <= 0 {
    0
  } else {
    let wrapped = index - index / length * length
    if wrapped < 0 {
      wrapped + length
    } else {
      wrapped
    }
  }
}

///|
fn center_row(grid : @terrain.TerrainGrid) -> Int {
  if grid.rows <= 0 {
    0
  } else {
    grid.rows / 2
  }
}

///|
fn terrain_cell(
  grid : @terrain.TerrainGrid,
  row : Int,
  col : Int,
) -> @core.TerrainCell {
  grid.cells[row * grid.cols + col]
}

///|
fn terrain_col_at_x(grid : @terrain.TerrainGrid, x : Double) -> Int {
  if grid.cols <= 0 || grid.cell_size_m <= 0.0 {
    0
  } else {
    wrapped_index((x / grid.cell_size_m).to_int(), grid.cols)
  }
}

///|
fn terrain_elevation_at_x(grid : @terrain.TerrainGrid, x : Double) -> Double {
  if grid.rows <= 0 || grid.cols <= 0 || grid.cells.is_empty() {
    0.0
  } else {
    let row = center_row(grid)
    let col = terrain_col_at_x(grid, x)
    terrain_cell(grid, row, col).elevation_m
  }
}

///|
fn terrain_grade_at_x(grid : @terrain.TerrainGrid, x : Double) -> Double {
  if grid.cols <= 1 || grid.cell_size_m <= 0.0 || grid.cells.is_empty() {
    0.0
  } else {
    let row = center_row(grid)
    let col = terrain_col_at_x(grid, x)
    let next_col = wrapped_index(col + 1, grid.cols)
    let here = terrain_cell(grid, row, col).elevation_m
    let next = terrain_cell(grid, row, next_col).elevation_m
    abs_double(next - here) / grid.cell_size_m
  }
}

///|
fn phase_index(frame_index : Int, cycle_frames : Int) -> Int {
  wrapped_index(frame_index, cycle_frames)
}

///|
fn phase_progress(phase : Int, half_cycle : Int) -> Double {
  if half_cycle <= 1 {
    0.0
  } else {
    phase.to_double() / (half_cycle - 1).to_double()
  }
}

///|
fn swing_lift(config : NoetixMoonWalkConfig, progress : Double) -> Double {
  config.step_height_m * @math.sin(progress * 3.141592653589793)
}

///|
fn foot_status(
  in_contact : Bool,
  clearance_m : Double,
  local_grade : Double,
  config : NoetixMoonWalkConfig,
) -> String {
  if local_grade > config.caution_grade {
    "terrain-grade-review"
  } else if !in_contact && clearance_m < config.min_swing_clearance_m {
    "low-clearance-review"
  } else {
    "ok"
  }
}

///|
fn foot_probe(
  foot_id : String,
  x : Double,
  y : Double,
  lift_m : Double,
  in_contact : Bool,
  grid : @terrain.TerrainGrid,
  config : NoetixMoonWalkConfig,
) -> NoetixFootContactProbe {
  let terrain_elevation_m = terrain_elevation_at_x(grid, x)
  let local_grade = terrain_grade_at_x(grid, x)
  let clearance_m = if in_contact { 0.0 } else { lift_m }
  {
    foot_id,
    position: @moonphys.vec3(x, y, terrain_elevation_m + clearance_m),
    terrain_elevation_m,
    clearance_m,
    in_contact,
    local_grade,
    status: foot_status(in_contact, clearance_m, local_grade, config),
  }
}

///|
fn frame_status(
  left : NoetixFootContactProbe,
  right : NoetixFootContactProbe,
) -> String {
  if left.status == "ok" && right.status == "ok" {
    "walking"
  } else {
    "walking-needs-review"
  }
}

///|
pub fn noetix_moon_walk_frame(
  grid : @terrain.TerrainGrid,
  config : NoetixMoonWalkConfig,
  frame_index : Int,
) -> NoetixMoonWalkFrame {
  let cycle_frames = if config.cycle_frames < 2 {
    2
  } else {
    config.cycle_frames
  }
  let half_cycle = cycle_frames / 2
  let phase = phase_index(frame_index, cycle_frames)
  let left_support = phase < half_cycle
  let local_phase = if left_support { phase } else { phase - half_cycle }
  let progress = phase_progress(local_phase, half_cycle)
  let body_x = frame_index.to_double() * config.speed_mps * config.dt_s
  let body_y = 0.0
  let body_z = terrain_elevation_at_x(grid, body_x) + 0.72
  let swing_offset = (progress - 0.5) * config.step_length_m
  let support_offset = 0.0 - config.step_length_m * 0.25
  let left = if left_support {
    foot_probe(
      "left-foot",
      body_x + support_offset,
      body_y + config.lateral_foot_offset_m,
      0.0,
      true,
      grid,
      config,
    )
  } else {
    foot_probe(
      "left-foot",
      body_x + swing_offset,
      body_y + config.lateral_foot_offset_m,
      swing_lift(config, progress),
      false,
      grid,
      config,
    )
  }
  let right = if left_support {
    foot_probe(
      "right-foot",
      body_x + swing_offset,
      body_y - config.lateral_foot_offset_m,
      swing_lift(config, progress),
      false,
      grid,
      config,
    )
  } else {
    foot_probe(
      "right-foot",
      body_x + support_offset,
      body_y - config.lateral_foot_offset_m,
      0.0,
      true,
      grid,
      config,
    )
  }
  {
    frame_index,
    time_s: frame_index.to_double() * config.dt_s,
    body_position: @moonphys.vec3(body_x, body_y, body_z),
    support_phase: if left_support {
      "left-support"
    } else {
      "right-support"
    },
    left_foot: left,
    right_foot: right,
    status: frame_status(left, right),
  }
}

///|
pub fn noetix_moon_walk_trace(
  grid : @terrain.TerrainGrid,
  frame_count : Int,
  config? : NoetixMoonWalkConfig = default_noetix_moon_walk_config(),
) -> NoetixMoonWalkTrace {
  let frames : Array[NoetixMoonWalkFrame] = []
  let count = if frame_count < 0 { 0 } else { frame_count }
  for index in 0..<count {
    frames.push(noetix_moon_walk_frame(grid, config, index))
  }
  {
    trace_id: "moonrobo/noetix-e1/endless-forward-moon-walk/\{grid.tile_id}",
    robot: noetix_moon_walk_robot_profile(),
    config,
    terrain_tile_id: grid.tile_id,
    terrain_cell_size_m: grid.cell_size_m,
    frame_count: frames.length(),
    endless_axis: "+x",
    frames,
    note: "Kinematic endless-walk trace for MoonSuite collaboration: Moonmoon terrain plus Moonrobo Noetix model references. This is simulation evidence only, not hardware authority.",
  }
}

///|
pub fn first_trusted_square_noetix_walk_trace(
  frame_count? : Int = 32,
) -> NoetixMoonWalkTrace {
  noetix_moon_walk_trace(
    @terrain.first_trusted_square_northeast_stepout_grid(),
    frame_count,
  )
}

///|
pub fn first_trusted_square_noetix_walk_json() -> Json {
  first_trusted_square_noetix_walk_trace().to_json()
}

///|
pub fn render_noetix_moon_walk_markdown(trace : NoetixMoonWalkTrace) -> String {
  let mut text = "# Noetix Endless Moon Walk\n\n"
  text += "- trace: \{trace.trace_id}\n"
  text += "- robot: \{trace.robot.robot_id} (\{trace.robot.label})\n"
  text += "- source model: \{trace.robot.source_model_path}\n"
  text += "- terrain: \{trace.terrain_tile_id}\n"
  text += "- gravity: \{trace.config.gravity_mps2} m/s^2\n"
  text += "- speed: \{trace.config.speed_mps} m/s\n"
  text += "- frames: \{trace.frame_count}\n"
  text += "- endless axis: \{trace.endless_axis}\n"
  text += "- note: \{trace.note}\n\n"
  text += "## Trace Prefix\n\n"
  for frame in trace.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s phase=\{frame.support_phase} body_x=\{frame.body_position.x} status=\{frame.status}\n"
    text += "  - left: x=\{frame.left_foot.position.x} z=\{frame.left_foot.position.z} contact=\{frame.left_foot.in_contact} clearance=\{frame.left_foot.clearance_m} status=\{frame.left_foot.status}\n"
    text += "  - right: x=\{frame.right_foot.position.x} z=\{frame.right_foot.position.z} contact=\{frame.right_foot.in_contact} clearance=\{frame.right_foot.clearance_m} status=\{frame.right_foot.status}\n"
  }
  text
}

///|
pub fn first_trusted_square_noetix_walk_markdown() -> String {
  render_noetix_moon_walk_markdown(first_trusted_square_noetix_walk_trace())
}
