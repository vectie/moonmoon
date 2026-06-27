///|
pub(all) struct PhysicsFrame {
  frame_index : Int
  time_s : Double
  body : KinematicBodyState
  contacts : Array[ContactProbe]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PhysicsTrace {
  trace_id : String
  environment : PhysicsEnvironment
  frames : Array[PhysicsFrame]
  note : String
} derive(Debug, Eq, ToJson, FromJson)
