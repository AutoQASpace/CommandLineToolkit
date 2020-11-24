// swift-tools-version:5.2
import PackageDescription
let package = Package(
    name: "CommandLineToolkit",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "AtomicModels", targets: ["AtomicModels"]),
        .library(name: "DateProvider", targets: ["DateProvider"]),
        .library(name: "DateProviderTestHelpers", targets: ["DateProviderTestHelpers"]),
        .library(name: "FileSystem", targets: ["FileSystem"]),
        .library(name: "FileSystemTestHelpers", targets: ["FileSystemTestHelpers"]),
        .library(name: "Graphite", targets: ["Graphite"]),
        .library(name: "GraphiteClient", targets: ["GraphiteClient"]),
        .library(name: "IO", targets: ["IO"]),
        .library(name: "Metrics", targets: ["Metrics"]),
        .library(name: "MetricsTestHelpers", targets: ["MetricsTestHelpers"]),
        .library(name: "MetricsUtils", targets: ["MetricsUtils"]),
        .library(name: "PathLib", targets: ["PathLib"]),
        .library(name: "PlistLib", targets: ["PlistLib"]),
        .library(name: "SocketModels", targets: ["SocketModels"]),
        .library(name: "Statsd", targets: ["Statsd"]),
        .library(name: "TestHelpers", targets: ["TestHelpers"]),
        .library(name: "Tmp", targets: ["Tmp"]),
        .library(name: "TmpTestHelpers", targets: ["TmpTestHelpers"]),
        .library(name: "Types", targets: ["Types"]),
        .library(name: "Waitable", targets: ["Waitable"]),
        .library(name: "XcodeLocator", targets: ["XcodeLocator"]),
        .library(name: "XcodeLocatorModels", targets: ["XcodeLocatorModels"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "AtomicModels",
            dependencies: [
            ],
            path: "Sources/AtomicModels"
        ),
        .target(
            name: "DateProvider",
            dependencies: [
            ],
            path: "Sources/DateProvider"
        ),
        .target(
            name: "DateProviderTestHelpers",
            dependencies: [
                "DateProvider",
            ],
            path: "Tests/DateProviderTestHelpers"
        ),
        .target(
            name: "FileSystem",
            dependencies: [
                "PathLib",
            ],
            path: "Sources/FileSystem"
        ),
        .target(
            name: "FileSystemTestHelpers",
            dependencies: [
                "FileSystem",
                "PathLib",
            ],
            path: "Tests/FileSystemTestHelpers"
        ),
        .testTarget(
            name: "FileSystemTests",
            dependencies: [
                "DateProvider",
                "FileSystem",
                "PathLib",
                "TestHelpers",
                "Tmp",
                "TmpTestHelpers",
            ],
            path: "Tests/FileSystemTests"
        ),
        .target(
            name: "Graphite",
            dependencies: [
                "GraphiteClient",
                "IO",
                "MetricsUtils",
                "SocketModels",
            ],
            path: "Sources/Graphite"
        ),
        .target(
            name: "GraphiteClient",
            dependencies: [
                "AtomicModels",
                "IO",
            ],
            path: "Sources/GraphiteClient"
        ),
        .testTarget(
            name: "GraphiteClientTests",
            dependencies: [
                "AtomicModels",
                "GraphiteClient",
                "IO",
            ],
            path: "Tests/GraphiteClientTests"
        ),
        .target(
            name: "IO",
            dependencies: [
                "AtomicModels",
            ],
            path: "Sources/IO"
        ),
        .testTarget(
            name: "IOTests",
            dependencies: [
                "IO",
                "TestHelpers",
            ],
            path: "Tests/IOTests"
        ),
        .target(
            name: "Metrics",
            dependencies: [
                "DateProvider",
                "Graphite",
                "Statsd",
            ],
            path: "Sources/Metrics"
        ),
        .target(
            name: "MetricsTestHelpers",
            dependencies: [
                "Graphite",
                "Metrics",
                "Statsd",
            ],
            path: "Tests/MetricsTestHelpers"
        ),
        .testTarget(
            name: "MetricsTests",
            dependencies: [
                "DateProviderTestHelpers",
                "Graphite",
                "Metrics",
                "MetricsTestHelpers",
                "Statsd",
                "TestHelpers",
            ],
            path: "Tests/MetricsTests"
        ),
        .target(
            name: "MetricsUtils",
            dependencies: [
                "IO",
            ],
            path: "Sources/MetricsUtils"
        ),
        .target(
            name: "PathLib",
            dependencies: [
            ],
            path: "Sources/PathLib"
        ),
        .testTarget(
            name: "PathLibTests",
            dependencies: [
                "PathLib",
            ],
            path: "Tests/PathLibTests"
        ),
        .target(
            name: "PlistLib",
            dependencies: [
            ],
            path: "Sources/PlistLib"
        ),
        .testTarget(
            name: "PlistLibTests",
            dependencies: [
                "PlistLib",
                "TestHelpers",
            ],
            path: "Tests/PlistLibTests"
        ),
        .target(
            name: "SocketModels",
            dependencies: [
                "Types",
            ],
            path: "Sources/SocketModels"
        ),
        .target(
            name: "Statsd",
            dependencies: [
                "AtomicModels",
                "IO",
                "MetricsUtils",
                "SocketModels",
                "Waitable",
            ],
            path: "Sources/Statsd"
        ),
        .testTarget(
            name: "StatsdTests",
            dependencies: [
                "Metrics",
                "Statsd",
            ],
            path: "Tests/StatsdTests"
        ),
        .testTarget(
            name: "TemporaryStuffTests",
            dependencies: [
                "PathLib",
                "TestHelpers",
                "Tmp",
            ],
            path: "Tests/TemporaryStuffTests"
        ),
        .target(
            name: "TestHelpers",
            dependencies: [
            ],
            path: "Tests/TestHelpers"
        ),
        .target(
            name: "Tmp",
            dependencies: [
                "PathLib",
            ],
            path: "Sources/Tmp"
        ),
        .target(
            name: "TmpTestHelpers",
            dependencies: [
                "TestHelpers",
                "Tmp",
            ],
            path: "Tests/TmpTestHelpers"
        ),
        .target(
            name: "Types",
            dependencies: [
            ],
            path: "Sources/Types"
        ),
        .testTarget(
            name: "TypesTests",
            dependencies: [
                "Types",
            ],
            path: "Tests/TypesTests"
        ),
        .target(
            name: "Waitable",
            dependencies: [
            ],
            path: "Sources/Waitable"
        ),
        .testTarget(
            name: "WaitableTests",
            dependencies: [
                "Waitable",
            ],
            path: "Tests/WaitableTests"
        ),
        .target(
            name: "XcodeLocator",
            dependencies: [
                "FileSystem",
                "PathLib",
                "PlistLib",
                "XcodeLocatorModels",
            ],
            path: "Sources/XcodeLocator"
        ),
        .target(
            name: "XcodeLocatorModels",
            dependencies: [
                "PathLib",
            ],
            path: "Sources/XcodeLocatorModels"
        ),
        .testTarget(
            name: "XcodeLocatorTests",
            dependencies: [
                "FileSystem",
                "FileSystemTestHelpers",
                "PlistLib",
                "TestHelpers",
                "TmpTestHelpers",
                "XcodeLocator",
                "XcodeLocatorModels",
            ],
            path: "Tests/XcodeLocatorTests"
        ),
    ]
)
