import UIKit

/// Embeddable controller that owns the bar and its iOS 26 glass backdrop.
/// Add/remove it with standard UIViewController child containment.
@MainActor
public final class NavBarViewController: UIViewController {
    public let bar: NavBarView

    public init(
        items: [NavBarItem] = [],
        selectedID: NavBarItem.ID? = nil,
        layout: NavBarLayout = NavBarLayout(),
        appearance: NavBarAppearance = NavBarAppearance(),
    ) {
        bar = NavBarView(items: items, selectedID: selectedID, layout: layout, appearance: appearance)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("Use init(items:selectedID:layout:appearance:)")
    }

    override public func loadView() {
        view = bar
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        bar.attachBackdrop(to: self)
    }
}
