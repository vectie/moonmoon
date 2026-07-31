///|
fn usage() -> String {
  (
    #|MoonMoon MoonFlow adapter
    #|
    #|  moon run cmd/moonflow_adapter -- capability
    #|  moon run cmd/moonflow_adapter -- declaration
    #|  moon run cmd/moonflow_adapter -- readiness <workspace-root>
    #|  moon run cmd/moonflow_adapter -- health <workspace-root> <checked-at> <valid-until>
    #|  moon run cmd/moonflow_adapter -- source-bundle <pack.json> <workspace-root> <compiled-at> <valid-until>
    #|  moon run cmd/moonflow_adapter -- invoke <workspace-root> <request.json>
    #|  moon run cmd/moonflow_adapter -- reconcile <workspace-root> <request.json>
    #|  moon run cmd/moonflow_adapter -- reconcile-report <workspace-root> <request.json>
    #|
  )
}

///|
fn command_index(args : Array[String]) -> Int {
  for index, value in args {
    if [
        "capability", "declaration", "readiness", "health", "source-bundle", "invoke",
        "reconcile", "reconcile-report", "help",
      ].contains(value) {
      return index
    }
  }
  -1
}

///|
fn arg(args : Array[String], index : Int) -> String? {
  args.get(index)
}

///|
fn print_issue(issue : @mission_adapter.AdapterRuntimeIssue) -> Unit {
  let payload : Json = {
    "contract_id": "moonmoon.adapter-cli-error.v1",
    "error": issue,
  }
  println(payload.stringify(indent=2))
}

///|
fn load_request(
  path : String,
) -> Result[
  @mission_adapter.MoonflowAdapterRequest,
  @mission_adapter.AdapterRuntimeIssue,
] {
  let text = @fsx.read_file_to_string(path) catch {
    _ =>
      return Err({
        code: "read-adapter-request",
        path,
        message: "failed to read MoonFlow adapter request JSON",
      })
  }
  let value = @json.parse(text) catch {
    _ =>
      return Err({
        code: "parse-adapter-request",
        path,
        message: "failed to parse MoonFlow adapter request JSON",
      })
  }
  try @json.from_json(value) catch {
    _ =>
      Err({
        code: "decode-adapter-request",
        path,
        message: "failed to decode MoonFlow adapter request",
      })
  } noraise {
    request => Ok(request)
  }
}

///|
fn load_pack(
  path : String,
) -> Result[Json, @mission_adapter.AdapterRuntimeIssue] {
  let text = @fsx.read_file_to_string(path) catch {
    _ =>
      return Err({
        code: "read-pack-manifest",
        path,
        message: "failed to read MoonMoon pack manifest",
      })
  }
  try @json.parse(text) catch {
    _ =>
      Err({
        code: "parse-pack-manifest",
        path,
        message: "failed to parse MoonMoon pack manifest",
      })
  } noraise {
    value => Ok(value)
  }
}

///|
fn fail_cli(issue : @mission_adapter.AdapterRuntimeIssue, code : Int) -> Unit {
  print_issue(issue)
  @sys.exit(code)
}

///|
fn main {
  let args = @env.args()
  let index = command_index(args)
  if index < 0 {
    println(usage())
    return
  }
  let command = args[index]
  match command {
    "help" => println(usage())
    "capability" =>
      println(
        @mission_adapter.moonflow_adapter_capability_json().stringify(indent=2),
      )
    "declaration" =>
      println(@mission_adapter.adapter_declaration_json().stringify(indent=2))
    "readiness" =>
      match arg(args, index + 1) {
        Some(workspace) =>
          println(
            @mission_adapter.readiness(workspace).to_json().stringify(indent=2),
          )
        None => {
          println(usage())
          @sys.exit(2)
        }
      }
    "health" =>
      match (arg(args, index + 1), arg(args, index + 2), arg(args, index + 3)) {
        (Some(workspace), Some(checked_at), Some(valid_until)) =>
          match
            @mission_adapter.health_attestation(
              workspace, checked_at, valid_until,
            ) {
            Ok(value) => println(value.to_json().stringify(indent=2))
            Err(error) => fail_cli(error, 3)
          }
        _ => {
          println(usage())
          @sys.exit(2)
        }
      }
    "source-bundle" =>
      match
        (
          arg(args, index + 1),
          arg(args, index + 2),
          arg(args, index + 3),
          arg(args, index + 4),
        ) {
        (Some(pack_path), Some(workspace), Some(compiled_at), Some(valid_until)) =>
          match load_pack(pack_path) {
            Err(error) => fail_cli(error, 2)
            Ok(pack) =>
              match
                @mission_adapter.capability_source_bundle(
                  pack, workspace, compiled_at, valid_until,
                ) {
                Ok(value) => println(value.stringify(indent=2))
                Err(error) => fail_cli(error, 3)
              }
          }
        _ => {
          println(usage())
          @sys.exit(2)
        }
      }
    "invoke" | "reconcile" | "reconcile-report" =>
      match (arg(args, index + 1), arg(args, index + 2)) {
        (Some(workspace), Some(request_path)) =>
          match load_request(request_path) {
            Err(error) => fail_cli(error, 2)
            Ok(request) =>
              if command == "invoke" {
                match @mission_adapter.invoke(workspace, request) {
                  Ok(value) => println(value.to_json().stringify(indent=2))
                  Err(error) => fail_cli(error, 3)
                }
              } else {
                match @mission_adapter.reconcile(workspace, request) {
                  Ok(report) =>
                    if command == "reconcile" {
                      println(report.result.to_json().stringify(indent=2))
                    } else {
                      println(report.to_json().stringify(indent=2))
                    }
                  Err(error) => fail_cli(error, 3)
                }
              }
          }
        _ => {
          println(usage())
          @sys.exit(2)
        }
      }
    _ => println(usage())
  }
}
