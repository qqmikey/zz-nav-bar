import UIKit

@MainActor
final class NavBarButton: UIControl {
    private let effectView = UIVisualEffectView()
    private let gradientView = ActiveGradientView()
    private let imageView = UIImageView()
    private let dropMask = CAShapeLayer()
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    private var appearance = NavBarAppearance()
    private var filled = false

    init(item: NavBarItem, appearance: NavBarAppearance) {
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityLabel = item.accessibilityLabel
        accessibilityHint = item.accessibilityHint
        accessibilityIdentifier = "ZZNavBar.item.\(item.id)"
        isEnabled = item.isEnabled
        clipsToBounds = true
        effectView.isUserInteractionEnabled = false
        imageView.isUserInteractionEnabled = false
        imageView.image = item.image.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        addSubview(effectView)
        addSubview(gradientView)
        addSubview(imageView)
        gradientView.isHidden = true
        apply(appearance)
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(released), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(activated), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Use init(item:appearance:)")
    }

    func apply(_ appearance: NavBarAppearance) {
        self.appearance = appearance
        gradientView.apply(appearance)
        imageView.tintColor = appearance.iconColor
        imageView.alpha = isEnabled ? 1 : 0.4
        updateGlass()
        setNeedsLayout()
    }

    private func updateGlass() {
        layer.borderColor = appearance.buttonBorderColor.resolvedColor(with: traitCollection).cgColor
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            effect.isInteractive = true
            effect.tintColor = appearance.buttonTint
            effectView.effect = effect
            backgroundColor = .clear
            layer.borderWidth = 0
        } else {
            effectView.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            backgroundColor = appearance.buttonTint
            layer.borderWidth = 1
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateGlass()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        effectView.frame = bounds
        effectView.layer.cornerRadius = bounds.height / 2
        gradientView.frame = bounds
        imageView.frame = CGRect(x: bounds.midX - appearance.iconSize / 2,
                                 y: bounds.midY - appearance.iconSize / 2,
                                 width: appearance.iconSize, height: appearance.iconSize)
    }

    func setGradientFill(_ enabled: Bool) {
        filled = enabled
        gradientView.isHidden = !enabled
    }

    func showGradientDrop(path: CGPath, gradientCenter: CGPoint, gradientRadius: CGFloat) {
        gradientView.layer.mask = dropMask
        dropMask.frame = gradientView.bounds
        dropMask.path = path
        gradientView.setGradientGeometry(center: gradientCenter, radius: gradientRadius)
        gradientView.isHidden = false
    }

    func endGradientDrop() {
        gradientView.layer.mask = nil
        gradientView.resetGradientGeometry()
        gradientView.isHidden = !filled
    }

    @objc private func pressed() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(withDuration: 0.10) {
            self.alpha = 0.76
            self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }
    }

    @objc private func released() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            alpha = 1
            transform = .identity
            return
        }
        UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.4) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    @objc private func activated() {
        guard appearance.hapticsEnabled else { return }
        feedback.impactOccurred(intensity: 0.72)
        feedback.prepare()
    }
}
