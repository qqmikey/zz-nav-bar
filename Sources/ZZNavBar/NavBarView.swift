import UIKit

/// Intrinsically sized navigation control. The host owns navigation and selection.
/// Use `NavBarViewController` for automatic glass-controller containment, or call
/// `attachBackdrop(to:)` after adding this view to your own controller hierarchy.
@MainActor
public final class NavBarView: UIView {
    public private(set) var items: [NavBarItem]
    public private(set) var selectedID: NavBarItem.ID?
    public private(set) var barLayout: NavBarLayout
    public private(set) var appearance: NavBarAppearance

    /// A tap requests selection; apply it with `setSelectedID(_:animated:)`.
    public var onSelect: ((NavBarItem.ID) -> Void)?

    private var buttons: [NavBarButton] = []
    private let backdrop = NavBarBackdropView()
    private let dropGap = ActiveGradientView()
    private let dropGapMask = CAShapeLayer()
    private var motion: DropMotion?
    private var displayLink: CADisplayLink?
    private var lastBounds: CGRect = .zero

    public init(
        items: [NavBarItem] = [],
        selectedID: NavBarItem.ID? = nil,
        layout: NavBarLayout = NavBarLayout(),
        appearance: NavBarAppearance = NavBarAppearance(),
    ) {
        precondition(Set(items.map(\.id)).count == items.count, "Item IDs must be unique.")
        appearance.validate()
        self.items = items
        self.selectedID = items.contains(where: { $0.id == selectedID && $0.isEnabled }) ? selectedID : nil
        barLayout = layout
        self.appearance = appearance
        super.init(frame: .zero)
        backgroundColor = .clear
        accessibilityIdentifier = "ZZNavBar"
        addSubview(backdrop)
        dropGap.isHidden = true
        dropGap.layer.mask = dropGapMask
        addSubview(dropGap)
        applyAppearance()
        rebuildButtons()
        NotificationCenter.default.addObserver(self, selector: #selector(stopMotion),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reduceMotionChanged),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
    }

    isolated deinit { displayLink?.invalidate() }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("Use init(items:selectedID:layout:appearance:)")
    }

    override public var intrinsicContentSize: CGSize {
        barLayout.size(forItemCount: items.count)
    }

    /// Replacing items stops motion and clears selection if its ID is missing or disabled.
    public func setItems(_ items: [NavBarItem]) {
        precondition(Set(items.map(\.id)).count == items.count, "Item IDs must be unique.")
        guard !sameItems(items) else { return }
        finishDrop()
        self.items = items
        if !items.contains(where: { $0.id == selectedID && $0.isEnabled }) { selectedID = nil }
        rebuildButtons()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    /// Unknown or disabled IDs are rejected without changing selection. `nil` clears it.
    @discardableResult
    public func setSelectedID(_ id: NavBarItem.ID?, animated: Bool = true) -> Bool {
        guard id == nil || items.contains(where: { $0.id == id && $0.isEnabled }) else { return false }
        guard id != selectedID else { return true }
        let previous = items.firstIndex { $0.id == selectedID }
        selectedID = id
        updateAccessibility()
        guard animated, let previous, let next = items.firstIndex(where: { $0.id == id }),
              window != nil, bounds.width > 0, !UIAccessibility.isReduceMotionEnabled
        else {
            finishDrop()
            return true
        }
        layoutIfNeeded()
        let now = CACurrentMediaTime()
        if var current = motion {
            current.retarget(to: centerX(next), at: now)
            motion = current
        } else {
            motion = DropMotion(start: centerX(previous), target: centerX(next),
                                startTime: now, duration: barLayout.transitionDuration)
        }
        if displayLink == nil {
            let link = CADisplayLink(target: DropLinkTarget(owner: self), selector: #selector(DropLinkTarget.step))
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
        stepDrop()
        return true
    }

    public func setLayout(_ layout: NavBarLayout) {
        guard layout != barLayout else { return }
        finishDrop()
        barLayout = layout
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    public func setAppearance(_ appearance: NavBarAppearance) {
        appearance.validate()
        guard !self.appearance.matches(appearance) else { return }
        self.appearance = appearance
        applyAppearance()
    }

    /// Establishes containment for the iOS 26 glass backdrop. Attach to the
    /// controller whose view hierarchy contains the bar; reattachment is supported.
    public func attachBackdrop(to parent: UIViewController) {
        backdrop.attach(to: parent)
        setNeedsLayout()
    }

    /// Call before permanently removing a raw NavBarView from its owner.
    public func detachBackdrop() {
        backdrop.detach()
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { finishDrop() }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if bounds != lastBounds {
            finishDrop()
            lastBounds = bounds
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backdrop.frame = bounds
        dropGap.frame = bounds
        dropGapMask.frame = bounds
        for (index, button) in buttons.enumerated() {
            button.bounds = CGRect(x: 0, y: 0, width: barLayout.slotDiameter, height: barLayout.slotDiameter)
            button.center = CGPoint(x: centerX(index), y: bounds.midY)
            button.layoutIfNeeded()
        }
        backdrop.setShape(metaballShape)
        backdrop.layoutIfNeeded()
        CATransaction.commit()
    }

    private var metaballShape: MetaballShape {
        MetaballShape(slotCount: items.count, slotDiameter: barLayout.slotDiameter,
                      ring: barLayout.ring, spacing: barLayout.spacing, bridgeFactor: barLayout.bridgeFactor)
    }

    private func sameItems(_ other: [NavBarItem]) -> Bool {
        items.count == other.count && zip(items, other).allSatisfy { a, b in
            a.id == b.id && a.image.isEqual(b.image) && a.accessibilityLabel == b.accessibilityLabel
                && a.accessibilityHint == b.accessibilityHint && a.isEnabled == b.isEnabled
        }
    }

    private func rebuildButtons() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = items.map { item in
            let button = NavBarButton(item: item, appearance: appearance)
            button.addAction(UIAction { [weak self] _ in
                guard item.isEnabled else { return }
                self?.onSelect?(item.id)
            }, for: .touchUpInside)
            addSubview(button)
            return button
        }
        updateAccessibility()
        finishDrop()
        setNeedsLayout()
    }

    private func updateAccessibility() {
        for (index, button) in buttons.enumerated() {
            var traits: UIAccessibilityTraits = .button
            if items[index].id == selectedID { traits.insert(.selected) }
            if !items[index].isEnabled { traits.insert(.notEnabled) }
            button.accessibilityTraits = traits
        }
    }

    private func applyAppearance() {
        backdrop.apply(appearance)
        dropGap.apply(appearance)
        buttons.forEach { $0.apply(appearance) }
    }

    private func centerX(_ index: Int) -> CGFloat {
        bounds.midX - barLayout.step * CGFloat(max(items.count - 1, 0)) / 2 + barLayout.step * CGFloat(index)
    }

    @objc private func reduceMotionChanged() {
        if UIAccessibility.isReduceMotionEnabled { finishDrop() }
    }

    @objc private func stopMotion() {
        finishDrop()
    }

    fileprivate func stepDrop() {
        guard var current = motion else { return }
        let finished = current.advance(to: CACurrentMediaTime())
        motion = current
        renderDrop(head: current.head, tail: current.tail)
        if finished { finishDrop() }
    }

    private func renderDrop(head: CGFloat, tail: CGFloat) {
        let radius = barLayout.slotDiameter / 2
        let stretch = min(abs(head - tail) / barLayout.step, 1)
        let headCenter = CGPoint(x: head, y: bounds.midY)
        let tailCenter = CGPoint(x: tail, y: bounds.midY)
        let headRadius = radius * (1 - 0.08 * stretch)
        let tailRadius = radius * (1 - 0.2 * stretch)
        var path = MetaballShape.circle(headCenter, headRadius).union(MetaballShape.circle(tailCenter, tailRadius))
        if let bridge = MetaballShape.bridge(tailCenter, tailRadius, headCenter, headRadius, barLayout.bridgeFactor) {
            path = path.union(bridge)
        }
        let gradientCenter = CGPoint(x: (head + tail) / 2, y: bounds.midY + radius)
        let gradientRadius = barLayout.slotDiameter * ActiveGradientView.radiusFactor
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dropGap.isHidden = false
        dropGapMask.path = path
        dropGap.setGradientGeometry(center: gradientCenter, radius: gradientRadius)
        for button in buttons {
            // Use untransformed geometry: the press animation scales the button.
            let origin = CGPoint(x: button.center.x - button.bounds.width / 2,
                                 y: button.center.y - button.bounds.height / 2)
            var shift = CGAffineTransform(translationX: -origin.x, y: -origin.y)
            guard let local = path.copy(using: &shift) else { continue }
            button.showGradientDrop(path: local,
                                    gradientCenter: CGPoint(x: gradientCenter.x - origin.x, y: gradientCenter.y - origin.y),
                                    gradientRadius: gradientRadius)
        }
        CATransaction.commit()
    }

    private func finishDrop() {
        displayLink?.invalidate()
        displayLink = nil
        motion = nil
        dropGap.isHidden = true
        for (index, button) in buttons.enumerated() {
            button.setGradientFill(items[index].id == selectedID)
            button.endGradientDrop()
        }
    }
}

@MainActor
private final class DropLinkTarget: NSObject {
    weak var owner: NavBarView?
    init(owner: NavBarView) {
        self.owner = owner
    }

    @objc func step() {
        owner?.stepDrop()
    }
}
