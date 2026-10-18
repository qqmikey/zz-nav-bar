import Testing
import UIKit
@testable import ZZNavBar

@MainActor
struct NavBarViewTests {
    private func items() -> [NavBarItem] {
        [
            NavBarItem(id: "a", image: UIImage(), accessibilityLabel: "Alpha"),
            NavBarItem(id: "b", image: UIImage(), accessibilityLabel: "Beta"),
            NavBarItem(id: "c", image: UIImage(), accessibilityLabel: "Gamma", isEnabled: false),
        ]
    }

    private func buttons(in bar: NavBarView) -> [UIControl] {
        bar.subviews.compactMap { $0 as? UIControl }
    }

    @Test func `initial state creates buttons and selection traits`() {
        let bar = NavBarView(items: items(), selectedID: "a")
        let controls = buttons(in: bar)
        #expect(controls.count == 3)
        #expect(controls[0].accessibilityLabel == "Alpha")
        #expect(controls[0].accessibilityTraits.contains(.selected))
        #expect(controls[2].accessibilityTraits.contains(.notEnabled))
        #expect(!controls[2].isEnabled)
    }

    @Test func `selection rejects invalid and disabled items and can be cleared`() {
        let bar = NavBarView(items: items(), selectedID: "a")
        #expect(!bar.setSelectedID("missing"))
        #expect(!bar.setSelectedID("c"))
        #expect(bar.selectedID == "a")
        #expect(bar.setSelectedID("b", animated: false))
        #expect(buttons(in: bar)[1].accessibilityTraits.contains(.selected))
        #expect(bar.setSelectedID(nil))
        #expect(bar.selectedID == nil)
    }

    @Test func `taps request selection without mutating it`() {
        let bar = NavBarView(items: items(), selectedID: "a")
        var requested: String?
        bar.onSelect = { requested = $0 }
        buttons(in: bar)[1].sendActions(for: .touchUpInside)
        #expect(requested == "b")
        #expect(bar.selectedID == "a")
        requested = nil
        buttons(in: bar)[2].sendActions(for: .touchUpInside)
        #expect(requested == nil)
    }

    @Test func `replacing items retains stable selection and clears removed ID`() {
        let bar = NavBarView(items: items(), selectedID: "b")
        bar.setItems(Array(items().reversed()))
        #expect(bar.selectedID == "b")
        #expect(buttons(in: bar)[1].accessibilityTraits.contains(.selected))
        bar.setItems([])
        #expect(bar.selectedID == nil)
        #expect(bar.intrinsicContentSize == .zero)
        #expect(buttons(in: bar).isEmpty)
        bar.frame = CGRect(x: 0, y: 0, width: 200, height: 70)
        bar.layoutIfNeeded()
    }

    @Test func `changing layout updates intrinsic size and button frames`() {
        let bar = NavBarView(items: items(), selectedID: "a")
        bar.setLayout(NavBarLayout(slotDiameter: 48, ring: 4, spacing: 8))
        #expect(bar.intrinsicContentSize == CGSize(width: 168, height: 56))
        bar.frame = CGRect(origin: .zero, size: bar.intrinsicContentSize)
        bar.layoutIfNeeded()
        #expect(buttons(in: bar)[0].bounds.size == CGSize(width: 48, height: 48))
        #expect(buttons(in: bar)[2].center.x == 140)
    }

    @Test func `backdrop can detach and reattach without orphaned controllers`() {
        guard #available(iOS 26.0, *) else { return }
        let first = UIViewController()
        let second = UIViewController()
        let bar = NavBarView(items: items())
        first.view.addSubview(bar)
        bar.frame = CGRect(origin: .zero, size: bar.intrinsicContentSize)
        bar.attachBackdrop(to: first)
        bar.layoutIfNeeded()
        #expect(first.children.count == 1)
        bar.attachBackdrop(to: second)
        second.view.addSubview(bar)
        bar.layoutIfNeeded()
        #expect(first.children.isEmpty)
        #expect(second.children.count == 1)
        bar.detachBackdrop()
        #expect(second.children.isEmpty)
    }

    @Test func `controller and hosted view release together`() {
        weak var released: NavBarViewController?
        autoreleasepool {
            let controller = NavBarViewController(items: items(), selectedID: "a")
            released = controller
            controller.loadViewIfNeeded()
            controller.view.frame = CGRect(origin: .zero, size: controller.bar.intrinsicContentSize)
            controller.view.layoutIfNeeded()
        }
        #expect(released == nil)
    }

    @Test func `backdrop reuses its controller across empty items and resizing`() throws {
        guard #available(iOS 26.0, *) else { return }
        let owner = UIViewController()
        let bar = NavBarView(items: items(), selectedID: "a")
        owner.view.addSubview(bar)
        bar.frame = CGRect(origin: .zero, size: bar.intrinsicContentSize)
        bar.attachBackdrop(to: owner)
        bar.layoutIfNeeded()
        let host = try #require(owner.children.first)
        let backdrop = try #require(bar.subviews.first { $0 is NavBarBackdropView })
        let fallback = try #require(backdrop.subviews.first { $0 is UIVisualEffectView })
        #expect(!host.view.isHidden)
        #expect(fallback.isHidden)

        bar.setItems([])
        bar.layoutIfNeeded()
        #expect(host.view.isHidden)
        #expect(!fallback.isHidden)

        bar.setItems(items())
        bar.setLayout(NavBarLayout(slotDiameter: 48, ring: 4, spacing: 8))
        bar.frame.size = bar.intrinsicContentSize
        bar.layoutIfNeeded()
        #expect(owner.children.count == 1)
        #expect(owner.children.first === host)
        #expect(host.view.frame.size == bar.bounds.size)
        #expect(!host.view.isHidden)
        #expect(fallback.isHidden)

        bar.detachBackdrop()
        #expect(owner.children.isEmpty)
        #expect(!fallback.isHidden)
    }
}
