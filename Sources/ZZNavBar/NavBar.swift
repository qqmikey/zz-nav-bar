import SwiftUI

/// SwiftUI adapter with controlled selection. Navigation content belongs to the host.
@MainActor
public struct NavBar: UIViewControllerRepresentable {
    public typealias UIViewControllerType = NavBarViewController
    private let items: [NavBarItem]
    @Binding private var selection: NavBarItem.ID?
    private let layout: NavBarLayout
    private let appearance: NavBarAppearance
    private let onSelect: ((NavBarItem.ID) -> Void)?

    public init(
        items: [NavBarItem],
        selection: Binding<NavBarItem.ID?>,
        layout: NavBarLayout = NavBarLayout(),
        appearance: NavBarAppearance = NavBarAppearance(),
        onSelect: ((NavBarItem.ID) -> Void)? = nil,
    ) {
        self.items = items
        _selection = selection
        self.layout = layout
        self.appearance = appearance
        self.onSelect = onSelect
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, onSelect: onSelect)
    }

    public func makeUIViewController(context: Context) -> NavBarViewController {
        let controller = NavBarViewController(items: items, selectedID: selection,
                                              layout: layout, appearance: appearance)
        controller.bar.onSelect = { [weak coordinator = context.coordinator] id in coordinator?.select(id) }
        return controller
    }

    public func updateUIViewController(_ controller: NavBarViewController, context: Context) {
        context.coordinator.selection = $selection
        context.coordinator.onSelect = onSelect
        controller.bar.setItems(items)
        controller.bar.setLayout(layout)
        controller.bar.setAppearance(appearance)
        controller.bar.setSelectedID(selection, animated: !context.transaction.disablesAnimations)
    }

    public func sizeThatFits(_: ProposedViewSize, uiViewController: NavBarViewController, context _: Context) -> CGSize? {
        uiViewController.bar.intrinsicContentSize
    }

    public static func dismantleUIViewController(_ controller: NavBarViewController, coordinator _: Coordinator) {
        controller.bar.onSelect = nil
        controller.bar.detachBackdrop()
    }

    @MainActor
    public final class Coordinator {
        fileprivate var selection: Binding<NavBarItem.ID?>
        fileprivate var onSelect: ((NavBarItem.ID) -> Void)?

        fileprivate init(selection: Binding<NavBarItem.ID?>, onSelect: ((NavBarItem.ID) -> Void)?) {
            self.selection = selection
            self.onSelect = onSelect
        }

        fileprivate func select(_ id: NavBarItem.ID) {
            selection.wrappedValue = id
            onSelect?(id)
        }
    }
}
