import SwiftUI
import ZZNavBar

@main
struct NavBarDemoApp: App {
    var body: some Scene {
        WindowGroup { DemoView() }
    }
}

@MainActor
private enum DemoItems {
    static let all: [NavBarItem] = [
        NavBarItem(id: "home", image: UIImage(named: "nav-home")!, accessibilityLabel: "Home"),
        NavBarItem(id: "patterns", image: UIImage(named: "nav-patterns")!, accessibilityLabel: "Patterns"),
        NavBarItem(id: "settings", image: UIImage(named: "nav-settings")!, accessibilityLabel: "Settings"),
    ]
}

@MainActor
private struct DemoView: View {
    @State private var selection: String? = "home"
    @State private var alternateColors = false
    @State private var showUIKit = false

    private var appearance: NavBarAppearance {
        guard alternateColors else { return NavBarAppearance() }
        return NavBarAppearance(gradientColors: [.systemCyan, .systemBlue, .systemIndigo],
                                gradientLocations: [0, 0.5, 1])
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [Color.purple.opacity(0.3), .clear],
                           center: .topTrailing, startRadius: 10, endRadius: 600).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("ZZ Nav Bar").font(.system(size: 34, weight: .bold, design: .rounded))
                    Spacer()
                    Text("SwiftUI").font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                Text("A drop in motion.").font(.title2).foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: selectedSymbol).font(.system(size: 54, weight: .light))
                        .foregroundStyle(alternateColors ? Color.cyan : Color.pink)
                    Text(selection?.capitalized ?? "No selection").font(.largeTitle.bold())
                    Text("Switch tabs quickly to redirect the moving drop. The gradient stays continuous across the glass buttons.")
                        .font(.body).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(28)
                .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 28))
                Spacer()
                Toggle("Ocean colors", isOn: $alternateColors).tint(.cyan)
                Button("Open UIKit example") { showUIKit = true }
                    .buttonStyle(.bordered).frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom, spacing: 16) {
            NavBar(items: DemoItems.all, selection: $selection, appearance: appearance)
                .padding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showUIKit) {
            UIKitExample().ignoresSafeArea()
        }
    }

    private var selectedSymbol: String {
        switch selection {
        case "patterns": "waveform.path"
        case "settings": "gearshape.fill"
        default: "house.fill"
        }
    }
}

private struct UIKitExample: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> UIKitDemoController {
        UIKitDemoController()
    }

    func updateUIViewController(_: UIKitDemoController, context _: Context) {}
}

@MainActor
private final class UIKitDemoController: UIViewController {
    private let navigation = NavBarViewController(items: DemoItems.all, selectedID: "home")
    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.045, green: 0.035, blue: 0.065, alpha: 1)
        titleLabel.text = "UIKit · Home"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        addChild(navigation)
        navigation.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigation.view)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            navigation.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            navigation.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
        navigation.didMove(toParent: self)
        navigation.bar.onSelect = { [weak self] id in
            self?.navigation.bar.setSelectedID(id)
            self?.titleLabel.text = "UIKit · \(id.capitalized)"
        }
    }
}
