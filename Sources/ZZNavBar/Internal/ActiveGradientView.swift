import UIKit

@MainActor
final class ActiveGradientView: UIView {
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    static let radiusFactor: CGFloat = 1.167
    private var gradient: CAGradientLayer {
        layer as! CAGradientLayer
    }

    private var appearance = NavBarAppearance()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradient.type = .radial
        gradient.masksToBounds = true
        resetGradientGeometry()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Use init(frame:)")
    }

    func apply(_ appearance: NavBarAppearance) {
        self.appearance = appearance
        updateColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }

    private func updateColors() {
        gradient.colors = appearance.gradientColors.map { $0.resolvedColor(with: traitCollection).cgColor }
        gradient.locations = appearance.gradientLocations.map { NSNumber(value: Double($0)) }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func setGradientGeometry(center: CGPoint, radius: CGFloat) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        gradient.startPoint = CGPoint(x: center.x / bounds.width, y: center.y / bounds.height)
        gradient.endPoint = CGPoint(x: (center.x + radius) / bounds.width, y: (center.y + radius) / bounds.height)
    }

    func resetGradientGeometry() {
        gradient.startPoint = CGPoint(x: 0.5, y: 1)
        gradient.endPoint = CGPoint(x: 0.5 + Self.radiusFactor, y: 1 + Self.radiusFactor)
    }
}
