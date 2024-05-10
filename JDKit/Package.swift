// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "JDKit",
  platforms: [.iOS(.v15)],
  products: [
    .library(
      name: "JDKit",
      // - Note: The MockServiceImplementation module should be excluded from release builds, but this
      // configuration is not currently available in SPM (pending: https://github.com/apple/swift-evolution/blob/main/proposals/0273-swiftpm-conditional-target-dependencies.md).
      // Though it can be manually excluded using a separate library, some custom project configurations,
      // and run script, I've elected to forgo these complications for this exercise.
      targets: ["Model", "ServiceImplementations", "MockServiceImplementations"]),
  ],
  targets: [
    .target(
      name: "Model"),
    .target(
      name: "ServiceImplementations",
      dependencies: ["Model"]),
    .target(
      name: "MockServiceImplementations",
      dependencies: ["Model"],
      resources: [.process("Fixtures")]),
    .testTarget(
      name: "ModelTests",
      dependencies: ["Model", "MockServiceImplementations"]),
  ]
)
