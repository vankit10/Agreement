// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AgreementCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "AgreementCore", targets: ["AgreementCore"])],
    targets: [
        .target(name: "AgreementCore", path: "AdarshAgreement/Core"),
        .testTarget(name: "AgreementCoreTests", dependencies: ["AgreementCore"], path: "Tests")
    ]
)
