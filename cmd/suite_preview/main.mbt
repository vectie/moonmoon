///|
fn usage() -> String {
  "Usage: moon run cmd/suite_preview -- --contract-json <moonrobo-contract.json>"
}

///|
fn arg_value(args : Array[String], flag : String) -> String? {
  for index, arg in args {
    if arg == flag && index + 1 < args.length() {
      return Some(args[index + 1])
    }
  }
  None
}

///|
fn main raise {
  let args = @env.args()
  if args.contains("help") || args.contains("--help") {
    println(usage())
    return
  }
  let contract_path = arg_value(args, "--contract-json").unwrap_or_error(
    Failure::Failure(usage()),
  )
  let contract_json = @fsx.read_file_to_string(contract_path)
  let payload = @suite_adapter_preview.moonrobo_noetix_suite_adapter_payload_from_live_json_text(
    contract_json,
  )
  println(payload.to_json().stringify(indent=2))
}
