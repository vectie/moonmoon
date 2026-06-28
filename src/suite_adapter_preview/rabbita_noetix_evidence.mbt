///|
priv struct RabbitaNoetixGeneratedVec3 {
  x : Double
  y : Double
  z : Double
}

///|
priv struct RabbitaNoetixGeneratedFootprint {
  footprint_id : String
  center : RabbitaNoetixGeneratedVec3
  half_length_m : Double
  half_width_m : Double
  active : Bool
}

///|
priv struct RabbitaNoetixGeneratedContactProbe {
  probe_id : String
  position : RabbitaNoetixGeneratedVec3
  surface_elevation_m : Double
  surface_normal : RabbitaNoetixGeneratedVec3
  clearance_m : Double
  in_contact : Bool
  local_grade : Double
  status : String
}

///|
priv struct RabbitaNoetixGeneratedContactPatch {
  patch_id : String
  center : RabbitaNoetixGeneratedVec3
  half_length_m : Double
  half_width_m : Double
  sample_count : Int
  contact_count : Int
  min_clearance_m : Double
  max_clearance_m : Double
  average_surface_elevation_m : Double
  average_surface_normal : RabbitaNoetixGeneratedVec3
  samples : Array[RabbitaNoetixGeneratedContactProbe]
  status : String
}

///|
priv struct RabbitaNoetixGeneratedContact {
  contact_id : String
  footprint : RabbitaNoetixGeneratedFootprint
  patch : RabbitaNoetixGeneratedContactPatch
  applied_force_n : RabbitaNoetixGeneratedVec3
}

///|
priv struct RabbitaNoetixGeneratedMotionFrame {
  time_s : Double
  phase_label : String
  support_foot : String
  review_id : String
  center_of_mass : RabbitaNoetixGeneratedVec3
  center_of_mass_velocity : RabbitaNoetixGeneratedVec3
  total_mass_kg : Double
  contacts : Array[RabbitaNoetixGeneratedContact]
}

///|
priv struct RabbitaNoetixGeneratedJointStep {
  joint_id : String
  before_position_rad : Double
  target_position_rad : Double
  target_velocity_rad_s : Double
  min_position_rad : Double
  max_position_rad : Double
  max_velocity_rad_s : Double
  max_torque_nm : Double
  stiffness_nm_per_rad : Double
  damping_nm_s_per_rad : Double
}

///|
priv struct RabbitaNoetixGeneratedHingeFrame {
  frame_index : Int
  time_s : Double
  dt_s : Double
  steps : Array[RabbitaNoetixGeneratedJointStep]
}

///|
fn generated_rabbita_noetix_hinge_ui_gate() -> Bool {
  let frames = generated_rabbita_noetix_hinge_frames()
  if frames.length() != 24 {
    return false
  }
  for frame in frames {
    if frame.frame_index < 0 || frame.time_s < 0.0 || frame.dt_s <= 0.0 {
      return false
    }
    if frame.steps.length() == 0 {
      return false
    }
    for step in frame.steps {
      if step.joint_id == "" ||
        step.min_position_rad > step.max_position_rad ||
        step.max_velocity_rad_s <= 0.0 ||
        step.max_torque_nm <= 0.0 ||
        step.stiffness_nm_per_rad <= 0.0 ||
        step.damping_nm_s_per_rad < 0.0 ||
        step.target_velocity_rad_s < 0.0 - step.max_velocity_rad_s - 0.000001 ||
        step.target_velocity_rad_s > step.max_velocity_rad_s + 0.000001 ||
        step.before_position_rad < step.min_position_rad ||
        step.before_position_rad > step.max_position_rad ||
        step.target_position_rad < step.min_position_rad ||
        step.target_position_rad > step.max_position_rad {
        return false
      }
    }
  }
  true
}

///|
fn generated_vec3_to_moonphys(
  value : RabbitaNoetixGeneratedVec3,
) -> @moonphys.Vec3 {
  @moonphys.vec3(value.x, value.y, value.z)
}

///|
fn generated_footprint_to_moonphys(
  value : RabbitaNoetixGeneratedFootprint,
) -> @moonphys.SupportFootprint {
  @moonphys.support_footprint(
    value.footprint_id,
    generated_vec3_to_moonphys(value.center),
    value.half_width_m,
    value.half_length_m,
    active=value.active,
  )
}

///|
fn generated_contact_probe_to_moonphys(
  value : RabbitaNoetixGeneratedContactProbe,
) -> @moonphys.ContactProbe {
  {
    probe_id: value.probe_id,
    position: generated_vec3_to_moonphys(value.position),
    surface_elevation_m: value.surface_elevation_m,
    surface_normal: generated_vec3_to_moonphys(value.surface_normal),
    clearance_m: value.clearance_m,
    in_contact: value.in_contact,
    local_grade: value.local_grade,
    status: value.status,
  }
}

///|
fn generated_contact_patch_to_moonphys(
  value : RabbitaNoetixGeneratedContactPatch,
) -> @moonphys.HeightfieldContactPatch {
  let samples : Array[@moonphys.ContactProbe] = []
  for sample in value.samples {
    samples.push(generated_contact_probe_to_moonphys(sample))
  }
  {
    patch_id: value.patch_id,
    center: generated_vec3_to_moonphys(value.center),
    half_length_m: value.half_length_m,
    half_width_m: value.half_width_m,
    sample_count: value.sample_count,
    contact_count: value.contact_count,
    min_clearance_m: value.min_clearance_m,
    max_clearance_m: value.max_clearance_m,
    average_surface_elevation_m: value.average_surface_elevation_m,
    average_surface_normal: generated_vec3_to_moonphys(
      value.average_surface_normal,
    ),
    samples,
    status: value.status,
  }
}

///|
fn generated_contact_to_moonphys(
  value : RabbitaNoetixGeneratedContact,
) -> @moonphys.MotionContactEvidence {
  @moonphys.motion_contact_evidence(
    value.contact_id,
    generated_footprint_to_moonphys(value.footprint),
    generated_contact_patch_to_moonphys(value.patch),
    generated_vec3_to_moonphys(value.applied_force_n),
  )
}

///|
fn generated_motion_frame_to_moonphys(
  value : RabbitaNoetixGeneratedMotionFrame,
) -> @moonphys.MotionFrameReview {
  let contacts : Array[@moonphys.MotionContactEvidence] = []
  for contact in value.contacts {
    if contact.footprint.active {
      contacts.push(generated_contact_to_moonphys(contact))
    }
  }
  @moonphys.motion_frame_review(
    value.review_id,
    @moonphys.lunar_environment(),
    @moonphys.material_contact_model("lunar-regolith-review-model", 0.62, 0.04),
    generated_vec3_to_moonphys(value.center_of_mass),
    generated_vec3_to_moonphys(value.center_of_mass_velocity),
    contacts,
    allow_dynamic_support=true,
  )
}

///|
fn rabbita_noetix_generated_motion_trace_review() -> @moonphys.MotionFrameTraceReview {
  rabbita_noetix_motion_trace_review_from_contact_frames(
    generated_rabbita_noetix_motion_trace_id(),
    generated_moonrobo_noetix_contact_frames(),
  )
}

///|
fn rabbita_noetix_motion_trace_review_from_contact_frames(
  trace_id : String,
  contact_frames : Array[RabbitaNoetixGeneratedMotionFrame],
) -> @moonphys.MotionFrameTraceReview {
  let frames : Array[@moonphys.MotionFrameReview] = []
  for frame in contact_frames {
    frames.push(generated_motion_frame_to_moonphys(frame))
  }
  @moonphys.motion_frame_trace_review(trace_id, frames)
}

///|
fn generated_motion_body(
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
fn moonrobo_noetix_hinge_world_from_motor_frames(
  field : @moonphys.Heightfield,
  motor_frames : Array[SuiteAdapterMotorFrameSample],
) -> @moonphys.RigidBodyHeightfieldWorld {
  let bodies : Array[@moonphys.RigidBodyWorldBody] = []
  let motion_bodies : Array[@moonphys.RigidBodyJointFrameBody] = []
  let hinges : Array[@moonphys.RigidBodyHingeJointConstraint] = []
  let first_frame = motor_frames[0]
  for index, step in first_frame.steps {
    let x = index.to_double() * 0.1
    let parent_id = "\{step.joint_id}/parent"
    let child_id = "\{step.joint_id}/child"
    let parent = generated_motion_body(parent_id, @moonphys.vec3(x, 0.0, 0.2))
    let child = generated_motion_body(child_id, @moonphys.vec3(x, 0.0, 0.2))
    motion_bodies.push(parent)
    motion_bodies.push(child)
    bodies.push(@moonphys.rigid_body_world_body(parent.state.linear))
    bodies.push(@moonphys.rigid_body_world_body(child.state.linear))
    hinges.push(
      @moonphys.rigid_body_hinge_joint_constraint(
        step.joint_id,
        parent_id,
        child_id,
        local_axis_a=@moonphys.vec3(0.0, 1.0, 0.0),
        local_axis_b=@moonphys.vec3(0.0, 1.0, 0.0),
      ),
    )
  }
  @moonphys.rigid_body_heightfield_world(
    "rabbita-noetix-generated-hinge-world",
    field,
    @moonphys.lunar_regolith_contact_model(),
    @moonphys.lunar_environment(),
    bodies,
    motion_bodies~,
    hinge_constraints=hinges,
  )
}

///|
fn generated_moonrobo_motor_frame(
  frame : SuiteAdapterMotorFrameSample,
) -> @moonphys.JointMotorFrame {
  let states : Array[@moonphys.JointMotorState] = []
  let commands : Array[@moonphys.JointMotorCommand] = []
  let configs : Array[@moonphys.JointServoConfig] = []
  let limits : Array[@moonphys.JointLimit] = []
  let inertias : Array[Double] = []
  for step in frame.steps {
    states.push(
      @moonphys.joint_motor_state(step.joint_id, step.before_position_rad, 0.0),
    )
    commands.push(
      @moonphys.joint_motor_command(
        step.joint_id,
        step.target_position_rad,
        step.target_velocity_rad_s,
        0.0,
      ),
    )
    configs.push(
      @moonphys.joint_servo_config(
        step.joint_id,
        step.stiffness_nm_per_rad,
        step.damping_nm_s_per_rad,
      ),
    )
    limits.push(
      @moonphys.joint_limit(
        step.joint_id,
        step.min_position_rad,
        step.max_position_rad,
        step.max_velocity_rad_s,
        step.max_torque_nm,
      ),
    )
    inertias.push(1.0)
  }
  @moonphys.integrate_joint_motor_frame(
    "moonrobo-noetix-authored-hinge-frame/\{frame.frame_index}",
    states,
    commands,
    configs,
    limits,
    inertias,
    frame.dt_s,
  )
}

///|
fn rabbita_noetix_generated_hinge_trace(
  field : @moonphys.Heightfield,
) -> @moonphys.RigidBodyHeightfieldWorldHingeMotorTrace {
  rabbita_noetix_hinge_trace_from_motor_frames(
    generated_rabbita_noetix_hinge_trace_id(),
    field,
    generated_moonrobo_noetix_authored_motor_frames(),
    generated_moonrobo_noetix_contact_frame_source(),
  )
}

///|
fn rabbita_noetix_hinge_trace_from_motor_frames(
  trace_id : String,
  field : @moonphys.Heightfield,
  motor_frames_source : Array[SuiteAdapterMotorFrameSample],
  note : String,
) -> @moonphys.RigidBodyHeightfieldWorldHingeMotorTrace {
  let motor_frames : Array[@moonphys.JointMotorFrame] = []
  for frame in motor_frames_source {
    motor_frames.push(generated_moonrobo_motor_frame(frame))
  }
  @moonphys.rigid_body_heightfield_world_hinge_motor_trace(
    trace_id,
    moonrobo_noetix_hinge_world_from_motor_frames(field, motor_frames_source),
    field,
    motor_frames,
    note~,
  )
}

///|
fn generated_active_footprints(
  frame : RabbitaNoetixGeneratedMotionFrame,
) -> Array[@moonphys.SupportFootprint] {
  let footprints : Array[@moonphys.SupportFootprint] = []
  for contact in frame.contacts {
    if contact.footprint.active {
      footprints.push(generated_footprint_to_moonphys(contact.footprint))
    }
  }
  footprints
}

///|
fn rabbita_noetix_generated_replay_review(
  trace : @moonphys.RigidBodyHeightfieldWorldHingeMotorTrace,
) -> @moonphys.RigidBodyWorldReplayReview {
  rabbita_noetix_replay_review_from_contact_frames(
    trace,
    generated_moonrobo_noetix_contact_frames(),
  )
}

///|
fn rabbita_noetix_replay_review_from_contact_frames(
  trace : @moonphys.RigidBodyHeightfieldWorldHingeMotorTrace,
  contact_frames : Array[RabbitaNoetixGeneratedMotionFrame],
) -> @moonphys.RigidBodyWorldReplayReview {
  let footprint_frames : Array[Array[@moonphys.SupportFootprint]] = []
  let targets : Array[@moonphys.RigidBodyWorldCenterOfMassTarget] = []
  for frame in contact_frames {
    let center_of_mass = generated_vec3_to_moonphys(frame.center_of_mass)
    footprint_frames.push(generated_active_footprints(frame))
    targets.push(
      @moonphys.rigid_body_world_center_of_mass_target(
        center_of_mass,
        generated_vec3_to_moonphys(frame.center_of_mass_velocity),
        total_mass_kg=frame.total_mass_kg,
        nominal_com_height_m=center_of_mass.z,
      ),
    )
  }
  @moonphys.rigid_body_heightfield_world_hinge_motor_replay_review_with_targets(
    trace, footprint_frames, targets,
  )
}
