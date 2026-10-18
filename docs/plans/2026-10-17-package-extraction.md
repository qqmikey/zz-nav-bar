# ZZNavBar package extraction plan

**Goal:** Build an independent, reusable iOS navigation bar package and a local demo, without editing the source application.

**Architecture:** One dependency-free Swift Package, UIKit rendering with a controller that owns SwiftUI glass containment, and a SwiftUI adapter. Preserve the original metaball bridge, drop easing, gradient layering, and default appearance. Keep application navigation outside the package.

**Toolchain:** Swift 6.2, iOS 16+, Xcode with iOS 26 SDK or newer, XcodeGen for reproducible demo generation.

## 1. Package and public contract
- Create Package.swift, item/appearance/layout models and documentation.
- Use stable item IDs, caller-provided UIImage assets, validated layout inputs, and main-actor UI isolation.
- Treat selection as controlled state: taps request selection; the host applies it.

## 2. Rendering and animation
- Extract the bridge geometry into the package.
- Extract an elapsed-time drop model for deterministic tests.
- Extract the gradient and glass button without app-specific gamepad/localization dependencies.
- Implement NavBarView and NavBarViewController with correct child-controller containment and cleanup.
- Preserve the original 0.42-second motion and retargeting; document distant-transition splitting.

## 3. Integrations and demo
- Add the SwiftUI NavBar binding adapter.
- Add an independent demo with original styling, alternate styling, UIKit and SwiftUI examples.
- Generate a checked-in Xcode project referencing the root package locally.

## 4. Verification and delivery
- Test bridge edge cases, motion endpoints/retargeting, selection, item replacement, resizing, containment and accessibility.
- Build the demo for iOS Simulator with signing disabled.
- Run the package tests on simulator; inspect build warnings and public API documentation.
- Add CI, ignore local artifacts, and record extraction provenance.
- Verify the source application remains unchanged. No remote repository, commit or push is part of the extraction task.
