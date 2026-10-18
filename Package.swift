// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ZZNavBar",
    platforms: [.iOS(.v16)],
    products: [.library(name: "ZZNavBar", targets: ["ZZNavBar"])],
    targets: [
        .target(name: "ZZNavBar"),
        .testTarget(name: "ZZNavBarTests", dependencies: ["ZZNavBar"]),
    ],
)
