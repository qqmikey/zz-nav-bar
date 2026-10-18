import Foundation

/// Elapsed-time motion, independent of refresh rate and UI lifecycle.
struct DropMotion {
    private(set) var head: CGFloat
    private(set) var tail: CGFloat
    private var headStart: CGFloat
    private var tailStart: CGFloat
    private var target: CGFloat
    private var startTime: TimeInterval
    let duration: TimeInterval

    init(start: CGFloat, target: CGFloat, startTime: TimeInterval, duration: TimeInterval) {
        head = start
        tail = start
        headStart = start
        tailStart = start
        self.target = target
        self.startTime = startTime
        self.duration = duration
    }

    /// Returns true when the destination has been reached.
    @discardableResult
    mutating func advance(to time: TimeInterval) -> Bool {
        let t = CGFloat(min(max((time - startTime) / duration, 0), 1))
        let tailT = min(max((t - 0.12) / 0.88, 0), 1)
        head = headStart + (target - headStart) * (1 - pow(1 - t, 3))
        let tailProgress = tailT < 0.5 ? 4 * tailT * tailT * tailT : 1 - pow(-2 * tailT + 2, 3) / 2
        tail = tailStart + (target - tailStart) * tailProgress
        return t >= 1
    }

    mutating func retarget(to target: CGFloat, at time: TimeInterval) {
        advance(to: time)
        headStart = head
        tailStart = tail
        self.target = target
        startTime = time
    }
}
