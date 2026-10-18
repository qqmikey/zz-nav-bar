# Verification record

Date: 2026-10-17. Toolchain: Xcode 27.0 (27A266a), Swift 6 language mode, Swift tools 6.2 package manifest. All simulator commands used `CODE_SIGNING_ALLOWED=NO`; no certificate, team or signing identity was selected.

| Check | Result |
| --- | --- |
| Package unit tests, iPhone 17 Pro / iOS 26.2 | 16 passed, 0 failures |
| Standalone demo simulator build | Passed |
| Hosted integration tests, iPhone 17 Pro / iOS 26.2 | 2 passed, 0 failures |
| Hosted integration tests, iPhone 16e / iOS 18.4 | 2 passed, 0 failures |
| SwiftFormat lint | All 16 Swift files passed with `--swift-version 6.2` |
| Swift Package manifest validation | `swift package dump-package` passed |
| Source application working tree (extraction baseline) | Clean before and after extraction |

Integration tests use a real SwiftUI `@State` host: taps and programmatic binding changes update both the bar and dependent destination content without replacing `rootView`. They also cover in-window motion, rapid retargeting, and cancellation on app backgrounding, resizing and removal. The legacy material and native-glass paths were exercised on their respective runtimes. The test bundle requires iOS 17 because of the installed testing frameworks; the library and demo application still target iOS 16.

The review refactor separates backdrop containment/material rendering from selection and motion, shares circle geometry, and avoids assigning an unchanged native-glass `rootView` during layout. Unit tests additionally verify that emptying/repopulating items and resizing reuse the native controller, and that detachment restores the fallback without leaving a child controller. Independent read-only review of the final source found no new actionable defects. Local package and hosted tests above were rerun after the refactor.

The hostless package tests emit UIKit UIApp diagnostics for selector-based control actions; the actual app-hosted integration tests cover the tap path with UIApplication present. Xcode emits its standard metadata-extraction warning because the project has no AppIntents dependency. There are no remaining source compiler errors or test failures.

Visual equivalence to the source application has not been established with a side-by-side animation/video comparison. A standalone screenshot attempt could not run because that simulator was shut down; no screenshot artifact is provided. The geometry, easing, timings and layer order were checked against source, and an independent read-only code review found no blocking issues.

CI is configured but has not run remotely. Remote publication, device signing/installation and integration back into the source application have not been validated by these local checks.
