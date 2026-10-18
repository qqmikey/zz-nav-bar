import UIKit

/// A navigation destination. IDs must be unique and stable across updates.
@MainActor
public struct NavBarItem: Identifiable {
    public typealias ID = String

    public let id: ID
    public let image: UIImage
    public let accessibilityLabel: String
    public let accessibilityHint: String?
    public let isEnabled: Bool

    /// Supply an image from your own asset bundle or SF Symbols.
    public init(
        id: ID,
        image: UIImage,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        isEnabled: Bool = true,
    ) {
        self.id = id
        self.image = image
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.isEnabled = isEnabled
    }
}
