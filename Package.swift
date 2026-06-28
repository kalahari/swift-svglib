// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-svglib",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SVGLib", targets: ["SVGLib"]),
        .executable(name: "SVGLibExample", targets: ["SVGLibExample"]),
    ],
    targets: [
        .target(
            name: "SVGLib",
            path: "Sources/SVGLib"
        ),
        .executableTarget(
            name: "SVGLibExample",
            dependencies: ["SVGLib"],
            path: "Sources/SVGLibExample"
        ),
    ]
)
