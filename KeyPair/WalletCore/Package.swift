// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "WalletCore",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "WalletCore", targets: ["WalletCore"]),
        .library(name: "SwiftProtobuf", targets: ["SwiftProtobuf"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "WalletCore",
            url: "https://github.com/trustwallet/wallet-core/releases/download/4.2.3/WalletCore.xcframework.zip",
            checksum: "99b263325dd67cee3c354e699aacbf76e31876717d41c917d8fd047c4b1d445c"
        ),
        .binaryTarget(
            name: "SwiftProtobuf",
            url: "https://github.com/trustwallet/wallet-core/releases/download/4.2.3/SwiftProtobuf.xcframework.zip",
            checksum: "c9847d30d0245ee4de4b9df1bd4bd53f6df994d623792dcdbfebcaa03a8c8353"
        )
    ]
)
