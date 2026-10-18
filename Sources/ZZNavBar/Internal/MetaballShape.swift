import SwiftUI

/// Контур подложки бара как SwiftUI-форма: окружности фиксированного радиуса
/// в центрах слотов плюс метаболловые мостики между соседями.
///
/// Нужен именно как `Shape`, а не маска: `glassEffect(_:in:)` принимает форму
/// параметром и ведёт зеркальный кант по её контуру.
struct MetaballShape: Shape, Equatable {
    let slotCount: Int
    let slotDiameter: CGFloat
    let ring: CGFloat
    let spacing: CGFloat
    /// Форма мостика. 0.5 — глубокая впуклость, 1.0 — почти прямая.
    let bridgeFactor: CGFloat

    private var plateRadius: CGFloat {
        slotDiameter / 2 + ring
    }

    private var step: CGFloat {
        slotDiameter + spacing
    }

    func path(in rect: CGRect) -> Path {
        guard slotCount > 0 else { return Path() }
        let radius = plateRadius
        let total = step * CGFloat(slotCount - 1)
        let centers = (0 ..< slotCount).map { index in
            CGPoint(x: rect.midX - total / 2 + step * CGFloat(index), y: rect.midY)
        }

        // Настоящее объединение, а не сложение подпутей: у окружностей и
        // мостиков противоположное направление обхода, и при non-zero заливке
        // пересечения вычитаются — форма распадается на полумесяцы и линзы.
        var union = Self.circle(centers[0], radius)
        for center in centers.dropFirst() {
            union = union.union(Self.circle(center, radius))
        }
        for index in 0 ..< max(slotCount - 1, 0) {
            if let bridge = Self.bridge(centers[index], radius,
                                        centers[index + 1], radius, bridgeFactor)
            {
                union = union.union(bridge)
            }
        }
        return Path(union)
    }

    static func circle(_ center: CGPoint, _ radius: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                 width: radius * 2, height: radius * 2), transform: nil)
    }

    /// Метаболловый мостик между двумя окружностями. Общий для подложки бара
    /// и капли подсветки.
    static func bridge(
        _ c1: CGPoint, _ r1: CGFloat,
        _ c2: CGPoint, _ r2: CGFloat,
        _ v: CGFloat,
    ) -> CGPath? {
        let handleRate: CGFloat = 2.4
        let d = hypot(c2.x - c1.x, c2.y - c1.y)
        // Круг внутри другого круга — мостик не нужен, а `acos` ниже ушёл бы в NaN.
        guard d > abs(r1 - r2), d < (r1 + r2) * 2.5 else { return nil }

        var r1 = r1, r2 = r2
        var u1: CGFloat = 0, u2: CGFloat = 0
        if d < r1 + r2 {
            u1 = acos((r1 * r1 + d * d - r2 * r2) / (2 * r1 * d))
            u2 = acos((r2 * r2 + d * d - r1 * r1) / (2 * r2 * d))
        }
        let a1 = atan2(c2.y - c1.y, c2.x - c1.x)
        let a2 = acos((r1 - r2) / d)
        let a1a = a1 + u1 + (a2 - u1) * v
        let a1b = a1 - u1 - (a2 - u1) * v
        let a2a = a1 + .pi - u2 - (.pi - u2 - a2) * v
        let a2b = a1 - .pi + u2 + (.pi - u2 - a2) * v

        func point(_ c: CGPoint, _ r: CGFloat, _ a: CGFloat) -> CGPoint {
            CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
        }
        let p1 = point(c1, r1, a1a), p2 = point(c1, r1, a1b)
        let p3 = point(c2, r2, a2a), p4 = point(c2, r2, a2b)

        var handle = min(v * handleRate, hypot(p3.x - p1.x, p3.y - p1.y) / (r1 + r2))
        handle *= min(1, d * 2 / (r1 + r2))
        r1 *= handle
        r2 *= handle

        let h1 = point(p1, r1, a1a - .pi / 2), h2 = point(p2, r1, a1b + .pi / 2)
        let h3 = point(p3, r2, a2a + .pi / 2), h4 = point(p4, r2, a2b - .pi / 2)

        let path = CGMutablePath()
        path.move(to: p1)
        path.addCurve(to: p3, control1: h1, control2: h3)
        path.addLine(to: p4)
        path.addCurve(to: p2, control1: h4, control2: h2)
        path.closeSubpath()
        return path
    }
}

/// Стеклянная подложка бара. Форма передаётся эффекту параметром,
/// поэтому кант идёт по контуру метаболла.
@available(iOS 26.0, *)
struct MetaballGlassBackdrop: View {
    let shape: MetaballShape

    var body: some View {
        Color.clear
            .glassEffect(.regular, in: shape)
    }
}
