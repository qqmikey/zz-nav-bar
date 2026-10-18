import Foundation
import Testing
@testable import ZZNavBar

struct DropMotionTests {
    @Test func `endpoints are exact and time is clamped`() {
        var motion = DropMotion(start: 10, target: 140, startTime: 20, duration: 0.42)
        let beforeStart = motion.advance(to: 19)
        #expect(!beforeStart)
        #expect(motion.head == 10 && motion.tail == 10)
        let completed = motion.advance(to: 21)
        #expect(completed)
        #expect(motion.head == 140 && motion.tail == 140)
    }

    @Test func `tail waits while head moves`() {
        var motion = DropMotion(start: 0, target: 130, startTime: 0, duration: 0.42)
        motion.advance(to: 0.04)
        #expect(motion.head > 0)
        #expect(motion.tail == 0)
        motion.advance(to: 0.2)
        #expect(motion.head > motion.tail && motion.tail > 0)
    }

    @Test func `retargeting preserves current position and reaches new destination`() {
        var motion = DropMotion(start: 0, target: 130, startTime: 0, duration: 0.42)
        motion.advance(to: 0.18)
        let head = motion.head
        let tail = motion.tail
        motion.retarget(to: -65, at: 0.18)
        motion.advance(to: 0.18)
        #expect(abs(motion.head - head) < 0.00001)
        #expect(abs(motion.tail - tail) < 0.00001)
        let completed = motion.advance(to: 0.61)
        #expect(completed)
        #expect(motion.head == -65 && motion.tail == -65)
    }

    @Test func `sampling frequency does not change position`() {
        var sparse = DropMotion(start: 10, target: 140, startTime: 0, duration: 0.42)
        var frequent = sparse
        for frame in 0 ... 24 {
            frequent.advance(to: Double(frame) / 120)
        }
        sparse.advance(to: 0.2)
        #expect(sparse.head == frequent.head && sparse.tail == frequent.tail)
    }
}
