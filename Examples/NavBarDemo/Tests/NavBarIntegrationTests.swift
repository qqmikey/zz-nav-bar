import SwiftUI
import Testing
import UIKit
import ZZNavBar

@MainActor
@Suite(.serialized)
struct NavBarIntegrationTests {
    private func items() -> [NavBarItem] {
        [
            NavBarItem(id: "a", image: UIImage(systemName: "house")!, accessibilityLabel: "Home"),
            NavBarItem(id: "b", image: UIImage(systemName: "gearshape")!, accessibilityLabel: "Settings"),
        ]
    }

    private func window(root: UIViewController) throws -> UIWindow {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = root
        window.isHidden = false
        root.view.layoutIfNeeded()
        return window
    }

    private func findBar(in view: UIView) -> NavBarView? {
        if let bar = view as? NavBarView { return bar }
        return view.subviews.lazy.compactMap { findBar(in: $0) }.first
    }

    private func findSelectionLabel(in view: UIView) -> UILabel? {
        if let label = view as? UILabel, label.accessibilityIdentifier == "selection" { return label }
        return view.subviews.lazy.compactMap { findSelectionLabel(in: $0) }.first
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(3))
        while !condition(), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        try #require(condition())
    }

    @Test func `swift UI binding propagates taps and programmatic updates`() async throws {
        let probe = SelectionProbe()
        let host = UIHostingController(rootView: SelectionHost(items: items(), probe: probe))
        let window = try window(root: host)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        try await waitUntil { findBar(in: host.view) != nil && probe.selection != nil }
        host.view.layoutIfNeeded()
        let bar = try #require(findBar(in: host.view))
        let label = try #require(findSelectionLabel(in: host.view))
        #expect(bar.selectedID == "a")
        #expect(label.text == "a")
        let button = try #require(bar.subviews.compactMap { $0 as? UIControl }
            .first { $0.accessibilityIdentifier == "ZZNavBar.item.b" })
        button.sendActions(for: .touchUpInside)
        #expect(probe.selection?.wrappedValue == "b")
        try await waitUntil { bar.selectedID == "b" && label.text == "b" }

        probe.selection?.wrappedValue = "a"
        try await waitUntil { bar.selectedID == "a" && label.text == "a" }
    }

    @Test func `active drop settles on background resize and removal`() async throws {
        let controller = NavBarViewController(items: items(), selectedID: "a")
        let window = try window(root: controller)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        try await Task.sleep(for: .milliseconds(100))
        let bar = controller.bar
        bar.layoutIfNeeded()
        let gap = try #require(bar.subviews.first { $0.layer is CAGradientLayer })
        #expect(bar.window != nil)
        bar.setSelectedID("b")
        if UIAccessibility.isReduceMotionEnabled {
            #expect(gap.isHidden)
            return
        }
        #expect(!gap.isHidden)
        bar.setSelectedID("a")
        #expect(!gap.isHidden)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        #expect(gap.isHidden)
        #expect(bar.selectedID == "a")

        bar.setSelectedID("b")
        #expect(!gap.isHidden)
        bar.frame.size.width -= 10
        bar.setNeedsLayout()
        bar.layoutIfNeeded()
        #expect(gap.isHidden)

        bar.setSelectedID("a")
        #expect(!gap.isHidden)
        window.rootViewController = nil
        #expect(bar.window == nil)
        #expect(gap.isHidden)
    }
}

@MainActor
private final class SelectionProbe {
    var selection: Binding<String?>?
}

@MainActor
private struct SelectionHost: View {
    let items: [NavBarItem]
    let probe: SelectionProbe
    @State private var selection: String? = "a"

    var body: some View {
        VStack {
            SelectionLabel(selection: selection)
            NavBar(items: items, selection: $selection)
        }
        .onAppear { probe.selection = $selection }
    }
}

private struct SelectionLabel: UIViewRepresentable {
    let selection: String?

    func makeUIView(context _: Context) -> UILabel {
        let label = UILabel()
        label.accessibilityIdentifier = "selection"
        return label
    }

    func updateUIView(_ label: UILabel, context _: Context) {
        label.text = selection ?? "No selection"
    }
}
