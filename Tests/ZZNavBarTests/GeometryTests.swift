import CoreGraphics
import Testing
@testable import ZZNavBar

struct GeometryTests {
    @Test func `empty and single item sizes`() {
        let layout = NavBarLayout()
        #expect(layout.size(forItemCount: 0) == .zero)
        #expect(layout.size(forItemCount: -1) == .zero)
        #expect(layout.size(forItemCount: 1) == CGSize(width: 70, height: 70))
        #expect(layout.size(forItemCount: 3) == CGSize(width: 200, height: 70))
    }

    @Test func `containment and distant circles do not need bridge`() {
        #expect(MetaballShape.bridge(.zero, 30, .zero, 30, 0.85) == nil)
        #expect(MetaballShape.bridge(.zero, 30, CGPoint(x: 5, y: 0), 10, 0.85) == nil)
        #expect(MetaballShape.bridge(.zero, 30, CGPoint(x: 200, y: 0), 30, 0.85) == nil)
    }

    @Test func `bridge is finite in both directions`() throws {
        for distance: CGFloat in [0.001, 40, 60, 65, 100, 149] {
            for direction: CGFloat in [-1, 1] {
                let path = MetaballShape.bridge(.zero, 30, CGPoint(x: distance * direction, y: 0), 30, 0.85)
                #expect(path != nil)
                let box = try #require(path?.boundingBoxOfPath)
                #expect(box.origin.x.isFinite && box.origin.y.isFinite)
                #expect(box.width.isFinite && box.height.isFinite)
            }
        }
    }

    @Test func `union has no holes at slot centers or gaps`() {
        let shape = MetaballShape(slotCount: 3, slotDiameter: 60, ring: 5, spacing: 5, bridgeFactor: 0.85)
        let path = shape.path(in: CGRect(x: 0, y: 0, width: 200, height: 70)).cgPath
        for x: CGFloat in [35, 67.5, 100, 132.5, 165] {
            #expect(path.contains(CGPoint(x: x, y: 35)))
        }
        #expect(!path.contains(CGPoint(x: 0, y: 0)))
    }
}
