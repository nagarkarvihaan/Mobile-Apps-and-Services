// swift-tools-version: 6.0
import PackageDescription

// Run the exact app domain/network/view-model tests on macOS without a simulator.
// The Xcode project additionally compiles the SwiftUI and camera screens for iOS.
let package = Package(
    name: "FoodTrackerCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "FoodTracker", targets: ["FoodTracker"])],
    targets: [
        .target(
            name: "FoodTracker",
            path: "FoodTracker",
            exclude: ["FoodTrackerApp.swift", "Assets.xcassets", "Auth", "Components", "Views", "Services/ImageService.swift"],
            sources: ["Models", "ViewModels", "Services/APIService.swift"]
        ),
        .testTarget(name: "FoodTrackerTests", dependencies: ["FoodTracker"], path: "FoodTrackerTests"),
    ],
    swiftLanguageModes: [.v5]
)
