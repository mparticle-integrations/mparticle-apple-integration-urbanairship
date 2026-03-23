// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "mParticle-UrbanAirship",
    platforms: [ .iOS(.v16) ],
    products: [
        .library(
            name: "mParticle-UrbanAirship",
            targets: ["mParticle-UrbanAirship"]),
    ],
    dependencies: [
      .package(name: "mParticle-Apple-SDK",
               url: "https://github.com/mParticle/mparticle-apple-sdk",
               .upToNextMajor(from: "8.41.1")),
      .package(name: "Airship",
               url: "https://github.com/urbanairship/ios-library",
               .upToNextMajor(from: "20.6.0")),
    ],
    targets: [
        .target(
            name: "mParticle-UrbanAirship",
            dependencies: [
                .byName(name: "mParticle-Apple-SDK"),
                .product(name: "AirshipObjectiveC", package: "Airship"),
            ],
            path: "mParticle-UrbanAirship",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."),
        .testTarget(
            name: "mParticle-UrbanAirshipTests",
            dependencies: ["mParticle-UrbanAirship"],
            path: "Tests"),
    ]
)
