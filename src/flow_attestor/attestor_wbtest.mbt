///|
test "MoonMoon owns deterministic nominal and adverse final evidence" {
  let workspace = "/tmp/moonmoon-flow-attestor-test"
  write_json(scoped_path(workspace, "runtime/request.json"), {
    "request_id": "request-simulate",
    "operation": "simulate-mission",
  })
  write_json(scoped_path(workspace, "runtime/result.json"), {
    "result_id": "result-simulate",
    "output_digest": "sha256:draft",
  })
  write_json(scoped_path(workspace, "drafts/simulate.json"), {
    "contract_id": "moonmoon.scenario-evidence.v1",
    "product_id": "moonmoon",
    "simulation_model": {
      "initial_energy_wh": 100.0,
      "reserve_energy_wh": 20.0,
      "scenarios": [
        {
          "scenario_id": "nominal",
          "kind": "nominal",
          "seed": 11,
          "initial_state": { "energy_wh": 1.0 },
          "unverified_result": { "energy_wh": 1.0 },
          "steps": [
            {
              "energy_use_wh": 10.0,
              "progress_delta": 1.0,
              "hazard": false,
              "recovery": "",
            },
          ],
        },
        {
          "scenario_id": "hazard",
          "kind": "adverse",
          "seed": 12,
          "steps": [
            {
              "energy_use_wh": 5.0,
              "progress_delta": 0.2,
              "hazard": true,
              "recovery": "enter safe hold",
            },
          ],
        },
      ],
    },
    "model_limitations": ["transition model is not calibrated hardware"],
    "uncertainty": ["energy use is a bounded design estimate"],
  })
  attest(
    workspace, "runtime/request.json", "runtime/result.json", "runtime/attestation.json",
    "moonmoon-native-attestor-v1", "drafts/simulate.json", "outputs/simulate.json",
  )
  let output = read_json(scoped_path(workspace, "outputs/simulate.json"))
  let text = output.stringify()
  assert_true(text.contains("\"deterministic_replay\":true"))
  assert_true(text.contains("\"physical_readiness\":false"))
  assert_true(text.contains("\"correct-refusal\""))
  assert_true(text.contains("\"resolved_inputs\""))
  assert_true(text.contains("\"hazard_script\""))
  assert_true(text.contains("\"initial_energy_wh\":100"))
  assert_false(text.contains("\"initial_state\""))
  assert_false(text.contains("\"unverified_result\""))
}
