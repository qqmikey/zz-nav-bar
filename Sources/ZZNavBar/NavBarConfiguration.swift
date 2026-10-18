import UIKit

/// Geometry and motion settings for the navigation bar.
public struct NavBarLayout: Equatable, Sendable {
    public let slotDiameter: CGFloat
    public let ring: CGFloat
    public let spacing: CGFloat
    public let bridgeFactor: CGFloat
    public let transitionDuration: TimeInterval

    public init(
        slotDiameter: CGFloat = 60,
        ring: CGFloat = 5,
        spacing: CGFloat = 5,
        bridgeFactor: CGFloat = 0.85,
        transitionDuration: TimeInterval = 0.42,
    ) {
        precondition(slotDiameter.isFinite && slotDiameter >= 44, "Touch targets must be at least 44 points.")
        precondition(ring.isFinite && ring >= 0)
        precondition(spacing.isFinite && spacing >= 0)
        precondition(bridgeFactor.isFinite && (0 ... 1).contains(bridgeFactor))
        precondition(transitionDuration.isFinite && transitionDuration > 0)
        self.slotDiameter = slotDiameter
        self.ring = ring
        self.spacing = spacing
        self.bridgeFactor = bridgeFactor
        self.transitionDuration = transitionDuration
    }

    var plateRadius: CGFloat {
        slotDiameter / 2 + ring
    }

    var step: CGFloat {
        slotDiameter + spacing
    }

    /// The bar is intrinsically sized; it does not compress or scroll its items.
    public func size(forItemCount count: Int) -> CGSize {
        guard count > 0 else { return .zero }
        return CGSize(width: plateRadius * 2 + step * CGFloat(count - 1), height: plateRadius * 2)
    }
}

/// Colors are resolved by UIKit, so callers may supply dynamic UIColor values.
@MainActor
public struct NavBarAppearance {
    public var gradientColors: [UIColor]
    public var gradientLocations: [CGFloat]
    public var iconColor: UIColor
    public var buttonTint: UIColor
    public var buttonBorderColor: UIColor
    public var backdropColor: UIColor
    public var backdropBorderColor: UIColor
    public var iconSize: CGFloat
    public var hapticsEnabled: Bool

    public init(
        gradientColors: [UIColor] = [
            UIColor(red: 0.945, green: 0.325, blue: 0.369, alpha: 1),
            UIColor(red: 0.937, green: 0.322, blue: 0.518, alpha: 1),
            UIColor(red: 0.929, green: 0.318, blue: 0.663, alpha: 1),
            UIColor(red: 0.910, green: 0.310, blue: 0.957, alpha: 1),
        ],
        gradientLocations: [CGFloat] = [0, 0.25, 0.5, 1],
        iconColor: UIColor = .white,
        buttonTint: UIColor = .white.withAlphaComponent(0.08),
        buttonBorderColor: UIColor = .white.withAlphaComponent(0.22),
        backdropColor: UIColor = UIColor(red: 0.086, green: 0.082, blue: 0.082, alpha: 1),
        backdropBorderColor: UIColor = .white.withAlphaComponent(0.12),
        iconSize: CGFloat = 19,
        hapticsEnabled: Bool = true,
    ) {
        self.gradientColors = gradientColors
        self.gradientLocations = gradientLocations
        self.iconColor = iconColor
        self.buttonTint = buttonTint
        self.buttonBorderColor = buttonBorderColor
        self.backdropColor = backdropColor
        self.backdropBorderColor = backdropBorderColor
        self.iconSize = iconSize
        self.hapticsEnabled = hapticsEnabled
    }

    func validate() {
        precondition(gradientColors.count >= 2 && gradientColors.count == gradientLocations.count)
        precondition(gradientLocations.allSatisfy { $0.isFinite && (0 ... 1).contains($0) })
        precondition(zip(gradientLocations, gradientLocations.dropFirst()).allSatisfy { $0 <= $1 })
        precondition(iconSize.isFinite && iconSize > 0)
    }
}

@MainActor
extension NavBarAppearance {
    func matches(_ other: NavBarAppearance) -> Bool {
        gradientColors == other.gradientColors && gradientLocations == other.gradientLocations
            && iconColor == other.iconColor && buttonTint == other.buttonTint
            && buttonBorderColor == other.buttonBorderColor && backdropColor == other.backdropColor
            && backdropBorderColor == other.backdropBorderColor && iconSize == other.iconSize
            && hapticsEnabled == other.hapticsEnabled
    }
}
