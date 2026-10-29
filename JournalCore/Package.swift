// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JournalCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14), // host-side `swift test` only
    ],
    products: [
        .library(name: "JournalDomain", targets: ["JournalDomain"]),
        .library(name: "JournalData", targets: ["JournalData"]),
    ],
    targets: [
        .target(
            name: "JournalDomain",
            path: "Sources/JournalDomain"
        ),
        .target(
            name: "JournalData",
            dependencies: ["JournalDomain"],
            path: "Sources/JournalData",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "JournalDomainTests",
            dependencies: ["JournalDomain"],
            path: "Tests/JournalDomainTests"
        ),
        .testTarget(
            name: "JournalDataTests",
            dependencies: ["JournalData", "JournalDomain"],
            path: "Tests/JournalDataTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
