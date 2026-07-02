// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "vectie/moonmoon"

version = "0.1.0"

readme = "README.mbt.md"

repository = "git@github.com:vectie/moonmoon.git"

license = "Apache-2.0"

keywords = [ "moonbit", "lunar", "terrain", "mission-planning", "robotics" ]

description = "MoonBit-native lunar world model for measured terrain evidence, mission constraints, and robot-facing MoonSuite boundaries."

import {
  "moonbitlang/x@0.4.46",
  "vectie/moonlib@0.1.7",
}
