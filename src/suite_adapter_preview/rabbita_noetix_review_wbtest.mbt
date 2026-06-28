///|
struct RabbitaNoetixJointSpec {
  joint_id : String
  min_position_rad : Double
  max_position_rad : Double
  max_velocity_rad_s : Double
  max_torque_nm : Double
  phase_offset : Double
}

///|
fn noetix_urdf_joint_specs() -> Array[RabbitaNoetixJointSpec] {
  [
    {
      joint_id: "leg_l1_joint",
      min_position_rad: -1.2,
      max_position_rad: 1.2,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 90.0,
      phase_offset: 0.0,
    },
    {
      joint_id: "leg_l4_joint",
      min_position_rad: -1.8,
      max_position_rad: 1.8,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 100.0,
      phase_offset: 0.15,
    },
    {
      joint_id: "leg_l6_joint",
      min_position_rad: -0.8,
      max_position_rad: 0.8,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 80.0,
      phase_offset: 0.30,
    },
    {
      joint_id: "leg_r1_joint",
      min_position_rad: -1.2,
      max_position_rad: 1.2,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 90.0,
      phase_offset: 0.50,
    },
    {
      joint_id: "leg_r4_joint",
      min_position_rad: -1.8,
      max_position_rad: 1.8,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 100.0,
      phase_offset: 0.65,
    },
    {
      joint_id: "leg_r6_joint",
      min_position_rad: -0.8,
      max_position_rad: 0.8,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 80.0,
      phase_offset: 0.80,
    },
    {
      joint_id: "arm_l1_joint",
      min_position_rad: -1.8,
      max_position_rad: 1.8,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 45.0,
      phase_offset: 0.50,
    },
    {
      joint_id: "arm_l4_joint",
      min_position_rad: -1.6,
      max_position_rad: 1.6,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 30.0,
      phase_offset: 0.62,
    },
    {
      joint_id: "arm_r1_joint",
      min_position_rad: -1.8,
      max_position_rad: 1.8,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 45.0,
      phase_offset: 0.0,
    },
    {
      joint_id: "arm_r4_joint",
      min_position_rad: -1.6,
      max_position_rad: 1.6,
      max_velocity_rad_s: 3.0,
      max_torque_nm: 30.0,
      phase_offset: 0.12,
    },
  ]
}

///|
fn noetix_joint_position(
  spec : RabbitaNoetixJointSpec,
  phase : Double,
) -> Double {
  let tau = 6.283185307179586
  0.14 * @math.sin(tau * (phase + spec.phase_offset))
}

///|
fn noetix_joint_velocity(
  spec : RabbitaNoetixJointSpec,
  phase : Double,
) -> Double {
  let tau = 6.283185307179586
  let cycle_hz = 0.74
  0.14 * tau * cycle_hz * @math.cos(tau * (phase + spec.phase_offset))
}

///|
fn noetix_motion_frame(
  index : Int,
  field : @moonphys.Heightfield,
  material : @moonphys.MaterialContactModel,
) -> @moonphys.MotionFrameReview {
  let phase = index.to_double() / 24.0
  let center = @moonphys.vec3(
    0.015 * @math.sin(6.283185307179586 * phase),
    0.0,
    0.72,
  )
  let footprint = @moonphys.support_footprint(
    "support-foot",
    @moonphys.vec3(0.0, 0.0, 0.0),
    0.18,
    0.12,
  )
  let patch = @moonphys.heightfield_contact_patch(
    field,
    "support-foot-patch",
    @moonphys.vec3(0.0, 0.0, 0.0),
    0.18,
    0.12,
  )
  @moonphys.motion_frame_review(
    "rabbita-noetix-motion-frame/\{index}",
    @moonphys.lunar_environment(),
    material,
    center,
    @moonphys.vec3(0.0, 0.0, 0.0),
    [
      @moonphys.motion_contact_evidence(
        "support-contact",
        footprint,
        patch,
        @moonphys.vec3(0.0, 5.0, 87.75),
      ),
    ],
  )
}

///|
fn noetix_motion_trace_review() -> @moonphys.MotionFrameTraceReview {
  let field = @moonphys.heightfield("rabbita-noetix-flat-field", 1, 1, 1.0, [
    0.0,
  ])
  let material = @moonphys.material_contact_model(
    "lunar-regolith-review-model", 0.62, 0.04,
  )
  let frames : Array[@moonphys.MotionFrameReview] = []
  for index in 0..<24 {
    frames.push(noetix_motion_frame(index, field, material))
  }
  @moonphys.motion_frame_trace_review(
    "noetix-e1-lab-01/walk-cycle/moonphys-evidence", frames,
  )
}

///|
fn noetix_motion_body(
  body_id : String,
  position : @moonphys.Vec3,
) -> @moonphys.RigidBodyJointFrameBody {
  @moonphys.rigid_body_joint_frame_body(
    @moonphys.rigid_body_motion_state(
      body_id,
      1.0,
      0.04,
      position,
      @moonphys.vec3(0.0, 0.0, 0.0),
      @moonphys.identity_basis3(),
      @moonphys.vec3(0.0, 0.0, 0.0),
    ),
    @moonphys.rigid_body_inertia(body_id, @moonphys.vec3(1.0, 1.0, 1.0)),
  )
}

///|
fn noetix_hinge_world(
  field : @moonphys.Heightfield,
) -> @moonphys.RigidBodyHeightfieldWorld {
  let bodies : Array[@moonphys.RigidBodyWorldBody] = []
  let motion_bodies : Array[@moonphys.RigidBodyJointFrameBody] = []
  let hinges : Array[@moonphys.RigidBodyHingeJointConstraint] = []
  let specs = noetix_urdf_joint_specs()
  for index, spec in specs {
    let x = index.to_double() * 0.1
    let parent_id = "\{spec.joint_id}/parent"
    let child_id = "\{spec.joint_id}/child"
    let parent = noetix_motion_body(parent_id, @moonphys.vec3(x, 0.0, 0.2))
    let child = noetix_motion_body(child_id, @moonphys.vec3(x, 0.0, 0.2))
    motion_bodies.push(parent)
    motion_bodies.push(child)
    bodies.push(@moonphys.rigid_body_world_body(parent.state.linear))
    bodies.push(@moonphys.rigid_body_world_body(child.state.linear))
    hinges.push(
      @moonphys.rigid_body_hinge_joint_constraint(
        spec.joint_id,
        parent_id,
        child_id,
        local_axis_a=@moonphys.vec3(0.0, 1.0, 0.0),
        local_axis_b=@moonphys.vec3(0.0, 1.0, 0.0),
      ),
    )
  }
  @moonphys.rigid_body_heightfield_world(
    "rabbita-noetix-hinge-world",
    field,
    @moonphys.lunar_regolith_contact_model(),
    @moonphys.lunar_environment(),
    bodies,
    motion_bodies~,
    hinge_constraints=hinges,
  )
}

///|
fn noetix_motor_frame(index : Int, dt_s : Double) -> @moonphys.JointMotorFrame {
  let specs = noetix_urdf_joint_specs()
  let phase = index.to_double() / 24.0
  let next_phase = (index + 1).to_double() / 24.0
  let states : Array[@moonphys.JointMotorState] = []
  let commands : Array[@moonphys.JointMotorCommand] = []
  let configs : Array[@moonphys.JointServoConfig] = []
  let limits : Array[@moonphys.JointLimit] = []
  let inertias : Array[Double] = []
  for spec in specs {
    let position = noetix_joint_position(spec, phase)
    let target = noetix_joint_position(spec, next_phase)
    let velocity = noetix_joint_velocity(spec, next_phase)
    states.push(@moonphys.joint_motor_state(spec.joint_id, position, 0.0))
    commands.push(
      @moonphys.joint_motor_command(spec.joint_id, target, velocity, 0.0),
    )
    configs.push(@moonphys.joint_servo_config(spec.joint_id, 10.0, 0.4))
    limits.push(
      @moonphys.joint_limit(
        spec.joint_id,
        spec.min_position_rad,
        spec.max_position_rad,
        spec.max_velocity_rad_s,
        spec.max_torque_nm,
      ),
    )
    inertias.push(1.0)
  }
  @moonphys.integrate_joint_motor_frame(
    "rabbita-noetix-hinge-frame/\{index}",
    states,
    commands,
    configs,
    limits,
    inertias,
    dt_s,
  )
}

///|
fn noetix_hinge_trace(
  field : @moonphys.Heightfield,
) -> @moonphys.RigidBodyHeightfieldWorldHingeMotorTrace {
  let motor_frames : Array[@moonphys.JointMotorFrame] = []
  let dt_s = 1.0 / 0.74 / 24.0
  for index in 0..<24 {
    motor_frames.push(noetix_motor_frame(index, dt_s))
  }
  @moonphys.rigid_body_heightfield_world_hinge_motor_trace(
    "noetix-e1-lab-01/walk-cycle/hinge-motor-replay",
    noetix_hinge_world(field),
    field,
    motor_frames,
    note="Rabbita corrected-FK joint samples with Moonrobo Noetix URDF limits",
  )
}

///|
fn noetix_replay_review(
  trace : @moonphys.RigidBodyHeightfieldWorldHingeMotorTrace,
) -> @moonphys.RigidBodyWorldReplayReview {
  let footprint_frames : Array[Array[@moonphys.SupportFootprint]] = []
  let targets : Array[@moonphys.RigidBodyWorldCenterOfMassTarget] = []
  for _ in 0..<24 {
    footprint_frames.push([
      @moonphys.support_footprint(
        "support-foot",
        @moonphys.vec3(0.0, 0.0, 0.0),
        0.18,
        0.12,
      ),
    ])
    targets.push(
      @moonphys.rigid_body_world_center_of_mass_target(
        @moonphys.vec3(0.0, 0.0, 0.72),
        @moonphys.vec3(0.0, 0.0, 0.0),
        total_mass_kg=54.0,
        nominal_com_height_m=0.72,
      ),
    )
  }
  @moonphys.rigid_body_heightfield_world_hinge_motor_replay_review_with_targets(
    trace, footprint_frames, targets,
  )
}

///|
test "Rabbita Noetix evidence feeds compiled Moonphys combined review" {
  let field = @moonphys.heightfield("rabbita-noetix-flat-field", 1, 1, 1.0, [
    0.0,
  ])
  let motion = noetix_motion_trace_review()
  let hinge = noetix_hinge_trace(field)
  let replay = noetix_replay_review(hinge)
  let review = @moonphys.motion_hinge_replay_review_with_replay(
    "noetix-e1-lab-01/walk-cycle/compiled-motion-hinge-review", motion, hinge, replay,
  )
  assert_true(motion.ready)
  assert_eq(motion.frame_count, 24)
  assert_eq(hinge.frame_count, 24)
  assert_eq(hinge.motor_frame_count, 24)
  assert_eq(hinge.status, "world-heightfield-hinge-motor-trace-driven")
  assert_true(hinge.driven_joint_count >= 24)
  assert_eq(hinge.review_count, 0)
  assert_true(replay.ready)
  assert_true(review.ready)
  assert_eq(review.status, "motion-hinge-replay-review-ready")
  assert_eq(review.motion_frame_count, 24)
  assert_eq(review.hinge_frame_count, 24)
  assert_eq(review.frame_count_delta, 0)
  assert_eq(review.blocker_count, 0)
  assert_true(review.driven_joint_count >= 24)
  assert_true(review.max_motion_total_normal_force_n > 0.0)
  assert_true(review.max_replay_kinetic_energy_j >= 0.0)
}
