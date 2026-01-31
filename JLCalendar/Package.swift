// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "JLCalendar",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "JLCalendar",
            targets: ["JLCalendar"]
        ),
    ],
    targets: [
        .target(
            name: "JLCalendar",
            dependencies: [],
            path: "Sources/JLCalendar"
        ),
    ]
)

