// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "structured-queries-tagged",
  platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
  products: [
    .library(name: "StructuredQueriesTagged", targets: ["StructuredQueriesTagged"]),
    .library(name: "StructuredQueriesTaggedCore", targets: ["StructuredQueriesTaggedCore"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-structured-queries", from: "0.1.1"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0")
  ],
  targets: [
    .target(
      name: "StructuredQueriesTagged",
      dependencies: [
        "StructuredQueriesTaggedCore",
        .product(name: "StructuredQueries", package: "swift-structured-queries")
      ]
    ),
    .target(
      name: "StructuredQueriesTaggedCore",
      dependencies: [
        .product(name: "StructuredQueriesCore", package: "swift-structured-queries"),
        .product(name: "Tagged", package: "swift-tagged")
      ]
    ),
    .testTarget(
      name: "StructuredQueriesTaggedTests",
      dependencies: [
        "StructuredQueriesTagged",
        .product(name: "_StructuredQueriesSQLite", package: "swift-structured-queries"),
        .product(name: "StructuredQueriesTestSupport", package: "swift-structured-queries")
      ]
    )
  ]
)
