// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "PRRadar",
  platforms: [
    .macOS(.v14)
  ],
  targets: [
    .executableTarget(
      name: "PRRadar",
      resources: [
        .copy("Resources/Fonts")
      ]
    )
  ],
  swiftLanguageModes: [.v5]
)
