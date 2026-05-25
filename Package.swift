// swift-tools-version: 6.3

import PackageDescription
import CompilerPluginSupport



let package = Package(
    name: "SwiftReasync",
    platforms:
    [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products:
    [
        .library(
            name: "Reasync",
            targets: ["Reasync"]
        )
    ],
    dependencies:
    [
        .package(
            url: "https://github.com/swiftlang/swift-syntax",
            from: "603.0.0"
        )
    ],
    targets:
    [
        .target(
            name: "Reasync",
            dependencies: ["ReasyncMacro"]
        ),
        
        .target(
            name: "ReasyncMacroCore",
            dependencies:
            [
                .product(
                    name: "SwiftSyntax",
                    package: "swift-syntax"
                ),
                
                .product(
                    name: "SwiftSyntaxMacros",
                    package: "swift-syntax"
                )
            ]
        ),
        
        .macro(
            name: "ReasyncMacro",
            dependencies:
            [
                "ReasyncMacroCore",
                
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax"
                )
            ]
        ),
        
        .testTarget(
            name: "ReasyncTests",
            dependencies:
            [
                "Reasync",
                "ReasyncMacro",
                "ReasyncMacroCore",
                
                .product(
                    name: "SwiftSyntaxMacroExpansion",
                    package: "swift-syntax"
                ),
                
                .product(
                    name: "SwiftSyntaxMacrosTestSupport",
                    package: "swift-syntax"
                )
            ],
            swiftSettings:
            [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
