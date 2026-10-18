# Extraction record

Date: 2026-10-17.

Only read operations were performed on the source application during extraction.

## Source mapping

| Original | Package |
| --- | --- |
| `Features/Shell/MetaballShape.swift` | `Internal/MetaballShape.swift`; bridge and glass shape preserved |
| `Features/Shell/MetaballPlateView.swift` | `NavBarView.swift`, `Internal/DropMotion.swift` |
| `Features/Main/Views/GlassCircleControl.swift` | `Internal/NavBarButton.swift`; bar-only behavior |
| `DesignSystem/ActiveGradientView.swift` | `Internal/ActiveGradientView.swift` |
| `DesignSystem/Palette.swift` | Original bar colors in `NavBarAppearance` |
| `Resources/Assets.xcassets/nav-{home,patterns,settings}.imageset` | Demo assets only; package requires no assets |

## Preserved

Metaball bridge equations and cutoff; cubic head/tail easing; 12% tail delay; 0.42 s duration; 8%/20% radius narrowing; separate but coordinated gradient layers; original glass/blur paths; button press scale and haptics.

## Adapted for reuse

Stable string IDs and supplied UIImage icons replace index/parallel-array configuration. Unknown/disabled selections are rejected. Empty items, mutable layout sizing, dynamic colors, child-controller attachment/detachment, reduced-motion cancellation, and background cancellation are handled. Retargeting samples current elapsed time before redirecting. UIKit UI is main-actor isolated with an isolated display-link deinitializer. SwiftUI uses a coordinator to update the latest binding without retaining the host.

The component does not import GameController, MonetizationCore, localization or application services. It does not perform screen transitions or own application navigation. The original shell's separate 20 pt content movement was not extracted: screen choreography remains with the host application.

## Review boundaries

No source application refactor, remote creation, commit, push, signing identity selection, device installation or release operation was included in the extraction. The source repository's license file was empty; no new license has been selected.
