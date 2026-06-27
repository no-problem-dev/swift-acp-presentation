// swift-tools-version: 6.0
import PackageDescription

// swift-acp-presentation — the host-owned presentation layer.
//
// It reduces ACP `session/update` notifications (the semantic agent-activity
// stream) into a UI-agnostic `SessionViewState`, and owns all user-facing
// wording (in a String Catalog). The domain (the agent) emits only semantics;
// every status phrase, label, and copy lives here, so wording is encapsulated
// out of the agent and the protocol.
let package = Package(
    name: "swift-acp-presentation",
    defaultLocalization: "ja",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: [
        .library(name: "ACPPresentation", targets: ["ACPPresentation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
        .package(url: "https://github.com/no-problem-dev/swift-acp.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "ACPPresentation",
            dependencies: [.product(name: "ACPCore", package: "swift-acp")]
        ),
        .testTarget(
            name: "ACPPresentationTests",
            dependencies: ["ACPPresentation"]
        ),
    ]
)
