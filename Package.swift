// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "mParticle-UrbanAirship",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-UrbanAirship",
            targets: ["mParticle-UrbanAirship"]),
    ],
    dependencies: [
      .package(name: "mParticle-Apple-SDK",
               url: "https://github.com/mParticle/mparticle-apple-sdk",
               .upToNextMajor(from: "8.22.0")),
      .package(name: "Airship",
               url: "https://github.com/urbanairship/ios-library",
               .upToNextMajor(from: "19.1.0")),
    ],
    targets: [
        .target(
            name: "mParticle-UrbanAirship",
            dependencies: [
                .byName(name: "mParticle-Apple-SDK"),
                .product(name: "AirshipCore", package: "Airship"),
            ],
            path: "mParticle-UrbanAirship",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."),
    ]
)
