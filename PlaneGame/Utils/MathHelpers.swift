import Foundation
import CoreGraphics
import SpriteKit

// MARK: - Angle Conversions

func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
    degrees * .pi / 180.0
}

func radiansToDegrees(_ radians: CGFloat) -> CGFloat {
    radians * 180.0 / .pi
}

// MARK: - CGPoint Math

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        hypot(point.x - x, point.y - y)
    }

    func angle(to point: CGPoint) -> CGFloat {
        atan2(point.y - y, point.x - x)
    }

    var length: CGFloat {
        hypot(x, y)
    }

    var normalized: CGPoint {
        let len = length
        guard len > 0 else { return .zero }
        return CGPoint(x: x / len, y: y / len)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        CGPoint(x: point.x * scalar, y: point.y * scalar)
    }

    static func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
        CGPoint(x: point.x / scalar, y: point.y / scalar)
    }

    static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs - rhs
    }
}

// MARK: - CGVector Math

extension CGVector {
    var length: CGFloat {
        hypot(dx, dy)
    }

    var normalized: CGVector {
        let len = length
        guard len > 0 else { return .zero }
        return CGVector(dx: dx / len, dy: dy / len)
    }

    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func * (vector: CGVector, scalar: CGFloat) -> CGVector {
        CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }

    func toPoint() -> CGPoint {
        CGPoint(x: dx, y: dy)
    }
}

// MARK: - Clamping

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Interpolation

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t.clamped(to: 0...1)
}

func smoothStep(_ edge0: CGFloat, _ edge1: CGFloat, _ x: CGFloat) -> CGFloat {
    let t = ((x - edge0) / (edge1 - edge0)).clamped(to: 0...1)
    return t * t * (3.0 - 2.0 * t)
}

func inverseLerp(_ a: CGFloat, _ b: CGFloat, _ value: CGFloat) -> CGFloat {
    guard b != a else { return 0 }
    return ((value - a) / (b - a)).clamped(to: 0...1)
}

// MARK: - Random Helpers

extension CGFloat {
    static func randomSign() -> CGFloat {
        Bool.random() ? 1.0 : -1.0
    }
}

// MARK: - Map Range

func mapRange(
    _ value: CGFloat,
    fromMin: CGFloat, fromMax: CGFloat,
    toMin: CGFloat, toMax: CGFloat
) -> CGFloat {
    let normalized = inverseLerp(fromMin, fromMax, value)
    return lerp(toMin, toMax, normalized)
}
