import SwiftUI
import UIKit

/// Owns the material layers and the native glass controller's containment.
@MainActor
final class NavBarBackdropView: UIView {
    private let glass = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let maskLayer = CAShapeLayer()
    private let strokeLayer = CAShapeLayer()
    private let tintLayer = CAShapeLayer()
    private weak var owner: UIViewController?
    private var host: UIViewController?
    private var shape: MetaballShape?
    private var hostedShape: MetaballShape?
    private var appearance = NavBarAppearance()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(tintLayer)
        glass.layer.mask = maskLayer
        addSubview(glass)
        strokeLayer.fillColor = nil
        strokeLayer.lineWidth = 1
        layer.addSublayer(strokeLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Use init(frame:)")
    }

    func apply(_ appearance: NavBarAppearance) {
        self.appearance = appearance
        updateColors()
    }

    func setShape(_ shape: MetaballShape) {
        guard self.shape != shape else { return }
        self.shape = shape
        setNeedsLayout()
    }

    func attach(to owner: UIViewController) {
        guard self.owner !== owner else { return }
        detach()
        self.owner = owner
        setNeedsLayout()
    }

    func detach() {
        if let host {
            host.willMove(toParent: nil)
            host.view.removeFromSuperview()
            host.removeFromParent()
        }
        host = nil
        hostedShape = nil
        owner = nil
        updateFallbackVisibility()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let shape else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        glass.frame = bounds
        let path = shape.path(in: bounds).cgPath
        for layer in [maskLayer, strokeLayer, tintLayer] {
            layer.frame = bounds
            layer.path = path
        }
        updateNativeGlass(shape: shape)
        CATransaction.commit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }

    private func updateColors() {
        tintLayer.fillColor = appearance.backdropColor.resolvedColor(with: traitCollection).cgColor
        strokeLayer.strokeColor = appearance.backdropBorderColor.resolvedColor(with: traitCollection).cgColor
    }

    private func updateNativeGlass(shape: MetaballShape) {
        guard #available(iOS 26.0, *), bounds.width > 0, shape.slotCount > 0, let owner else {
            host?.view.isHidden = true
            updateFallbackVisibility()
            return
        }
        if let host = host as? UIHostingController<MetaballGlassBackdrop> {
            if hostedShape != shape {
                host.rootView = MetaballGlassBackdrop(shape: shape)
                hostedShape = shape
            }
            host.view.frame = bounds
            host.view.isHidden = false
        } else {
            let host = UIHostingController(rootView: MetaballGlassBackdrop(shape: shape))
            host.view.backgroundColor = .clear
            host.view.isUserInteractionEnabled = false
            host.view.frame = bounds
            owner.addChild(host)
            insertSubview(host.view, at: 0)
            host.didMove(toParent: owner)
            self.host = host
            hostedShape = shape
        }
        updateFallbackVisibility()
    }

    private func updateFallbackVisibility() {
        let hasGlassHost = host != nil && host?.view.isHidden == false
        glass.isHidden = hasGlassHost
        tintLayer.isHidden = hasGlassHost
        strokeLayer.isHidden = hasGlassHost
    }
}
