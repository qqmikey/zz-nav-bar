# ZZNavBar

A reusable iOS navigation bar with a stretching metaball selection indicator, coordinated radial gradient, and glass buttons.

- iOS 16+, Swift 6.2+, Xcode 26+ (iOS 26 SDK or newer).
- UIKit and SwiftUI; no third-party dependencies or required resources.
- Native glass on iOS 26+, dark ultra-thin material on iOS 16–25.
- VoiceOver labels and selected/disabled traits, Reduce Motion, optional haptics.
- Main-actor isolated UI and deterministic, refresh-rate-independent motion.

## Add the package

In Xcode, choose File → Add Package Dependencies, enter `https://github.com/qqmikey/zz-nav-bar.git`, select the `main` branch, and add the **ZZNavBar** product to your application target.

In a Swift package:

```swift
.package(url: "https://github.com/qqmikey/zz-nav-bar.git", branch: "main")
```

Then add `.product(name: "ZZNavBar", package: "zz-nav-bar")` to your target dependencies. Branch-based dependencies follow `main`; use a specific commit revision when you need a fixed dependency.

For local development, choose Add Local in Xcode or use `.package(path: "../zz-nav-bar")`.

## SwiftUI

```swift
import SwiftUI
import ZZNavBar

struct ContentView: View {
    @State private var selection: String? = "home"

    private var items: [NavBarItem] {
        [
            NavBarItem(id: "home", image: UIImage(systemName: "house")!,
                       accessibilityLabel: "Home"),
            NavBarItem(id: "settings", image: UIImage(systemName: "gearshape")!,
                       accessibilityLabel: "Settings"),
        ]
    }

    var body: some View {
        Text(selection ?? "No selection")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                NavBar(items: items, selection: $selection)
                    .padding(.bottom, 8)
            }
    }
}
```

Your application owns screen content, routing, safe-area policy and localization. The adapter writes tapped IDs to the binding; programmatic binding changes animate the same drop. `.transaction { $0.disablesAnimations = true }` disables that transition. An optional `onSelect` callback observes taps, including repeated taps on the selected item.

Keep the binding nil or set to an enabled item's ID. Unknown or disabled IDs are rejected: the bar retains its last valid selection, and the adapter does not rewrite the supplied binding. Removing or disabling the selected item clears the visual selection; the host should update its binding accordingly.

## UIKit

```swift
let navigation = NavBarViewController(items: items, selectedID: "home")
addChild(navigation)
navigation.view.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(navigation.view)
NSLayoutConstraint.activate([
    navigation.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    navigation.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                            constant: -8),
])
navigation.didMove(toParent: self)

navigation.bar.onSelect = { [weak self, weak navigation] id in
    navigation?.bar.setSelectedID(id)
    self?.showDestination(id)
}
```

Retain the child controller in your screen. Its view has an intrinsic size; no fixed width/height constraints are needed. Reserve content space above it using your own layout or additional safe-area insets. Remove the controller using standard `willMove(toParent: nil)`, `view.removeFromSuperview()`, `removeFromParent()` containment.

For an existing custom container, `NavBarView` can be used directly. After adding it to the view hierarchy, call `attachBackdrop(to: owner)`. Call `detachBackdrop()` before permanently removing it or reattaching to another owner. Without an owner it uses the blur fallback, including on iOS 26.

### Selection and item updates

- IDs are stable strings and must be unique. Duplicate IDs are a programmer error.
- UIKit taps **request** selection through `onSelect`. The host applies accepted changes with `setSelectedID`.
- Reapplying the current ID is a no-op and leaves an existing transition running.
- `setSelectedID` returns false for an unknown/disabled ID, retaining the existing selection. Passing nil clears selection. Selection is initially empty if the initial ID is invalid.
- `setItems` retains an enabled selected ID across reordering, otherwise clears it. Structural/content changes end any running transition. Passing identical items leaves a running transition intact.
- Disabled items remain visible and accessible but cannot be selected.
- Removing the view from a window, backgrounding the app, resizing, and enabling Reduce Motion settle the current transition at the selected item.
- Provide localized accessibility labels/hints. The visual bar is icon-only and intrinsically sized; it does not compress, scroll, or rearrange for RTL. Keep the count/size within the available width.

## Appearance and layout

```swift
let appearance = NavBarAppearance(
    gradientColors: [.systemCyan, .systemBlue, .systemIndigo],
    gradientLocations: [0, 0.5, 1],
    hapticsEnabled: false
)
let layout = NavBarLayout(slotDiameter: 60, ring: 5, spacing: 5,
                          bridgeFactor: 0.85, transitionDuration: 0.42)
```

Pass these to either initializer. In UIKit they can also be replaced with `setAppearance` / `setLayout`. Gradient stops must be ordered within 0...1 and match the colors (at least two). Touch diameter is at least 44 pt; geometry must be finite with nonnegative gaps/rings. Invalid configuration is a programmer error.

Dynamic UIColor values are supported. The default palette is designed for a dark background; the package does not force your application into dark mode. On iOS 26, the system renders the backdrop material and its rim. Backdrop tint/border colors configure the older blur fallback; button tint, icon colors and selection gradient are configurable on both paths.

## Motion

The head uses cubic ease-out. The tail waits for 12% of the 0.42-second default duration, then uses cubic ease-in-out. Stretch reduces head/tail radii by up to 8%/20%. Repeated taps retarget from the current positions. Position is continuous; velocity is restarted by the new easing curves.

The indicator is rendered across several coordinated layers: a gap layer and a masked gradient inside every glass button, beneath the icons. All use a common gradient center. A CADisplayLink requests up to 120 Hz only while moving; actual refresh rate depends on the device/system. Hosts can enable `CADisableMinimumFrameDurationOnPhone` in their Info.plist, as the demo does.

**Limitation:** distant jumps can split the indicator into two circles when the metaball bridge reaches its distance cutoff. With default layout, this can happen between the first and fifth tabs.

## Demo

Open [Examples/NavBarDemo/NavBarDemo.xcodeproj](Examples/NavBarDemo/NavBarDemo.xcodeproj). The project references `../..` as a local package and includes SwiftUI and UIKit examples, three navigation icons, and an alternate gradient.

The project is generated from `Examples/NavBarDemo/project.yml`. Regenerate with XcodeGen:

```sh
cd Examples/NavBarDemo
xcodegen generate
```

No development team or signing identity is selected. The checked-in project disables signing for simulator validation. Device installation requires the project's owner to select their approved team and signing settings.

## Verification

Run from the repository root:

```sh
xcodebuild -scheme ZZNavBar \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/tests CODE_SIGNING_ALLOWED=NO test

xcodebuild -project Examples/NavBarDemo/NavBarDemo.xcodeproj \
  -scheme NavBarDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/demo CODE_SIGNING_ALLOWED=NO test

swiftformat Package.swift Sources Tests \
  Examples/NavBarDemo/Sources Examples/NavBarDemo/Tests \
  --lint --swift-version 6.2
```

Choose an available simulator name on your machine. UIKit/SwiftUI require an iOS destination: `swift test` on macOS is not a supported test route for this package. Tests cover motion timing, retargeting, refresh-rate independence, geometry edge cases, selection and accessibility, item replacement, resizing, and controller containment/cleanup. Hosted demo tests exercise automatic SwiftUI `@State` updates after taps and programmatic binding changes, plus active-animation cancellation inside a real application process. SwiftFormat is an optional development tool, not a package dependency.

Visual acceptance checklist: tap adjacent and nonadjacent items rapidly; test iOS 26 glass and pre-26 fallback; toggle Reduce Motion; rotate/resize; background during motion; navigate with VoiceOver. Automated tests do not establish visual acceptance.

See [docs/verification.md](docs/verification.md) for executed checks and their limits.

## License

No license has been selected for this repository.
