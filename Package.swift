// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-svglib",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SVGLib", targets: ["SVGLib"]),
    ],
    targets: [
        .target(
            name: "SVGLib",
            path: "Sources/SVGLib"
        ),
    ]
)
