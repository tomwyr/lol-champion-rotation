// swift-tools-version:6.1

import PackageDescription

let package = Package(
  name: "lol-champion-rotation",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    // 💧 A server-side Swift web framework.
    .package(url: "https://github.com/vapor/vapor.git", from: "4.106.5"),
    // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.77.0"),
    .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
    .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.0"),
    .package(url: "https://github.com/pointfreeco/swift-clocks.git", from: "1.0.6"),
    .package(url: "https://github.com/MihaelIsaev/FCM.git", from: "3.0.0-beta.1"),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.3"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.11.1"),
    .package(url: "https://github.com/attaswift/BigInt.git", from: "5.4.0"),
  ],
  targets: [
    .executableTarget(
      name: "App",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "FCM", package: "FCM"),
        .product(name: "CryptoSwift", package: "CryptoSwift"),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "BigInt", package: "BigInt"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "AppTests",
      dependencies: [
        .target(name: "App"),
        .product(name: "VaporTesting", package: "vapor"),
        .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
        .product(name: "Clocks", package: "swift-clocks"),
      ],
      swiftSettings: swiftSettings
    ),
  ]
)

var swiftSettings: [SwiftSetting] {
  [
    .enableExperimentalFeature("StrictConcurrency")
  ]
}
