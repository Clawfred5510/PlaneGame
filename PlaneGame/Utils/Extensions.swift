import Foundation
import SpriteKit
import CoreGraphics

// MARK: - SKColor from Hex

extension SKColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - SKNode Helpers

extension SKNode {
    func shake(intensity: CGFloat = GameConfig.Camera.shakeIntensity,
               duration: TimeInterval = GameConfig.Camera.shakeDuration) {
        let steps = Int(duration / 0.02)
        var actions: [SKAction] = []
        for _ in 0..<steps {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.02))
        }
        actions.append(SKAction.move(to: position, duration: 0.02))
        run(SKAction.sequence(actions))
    }

    func fadeInFromScale(duration: TimeInterval = GameConfig.UI.animationDuration) {
        alpha = 0
        setScale(0.5)
        let group = SKAction.group([
            SKAction.fadeIn(withDuration: duration),
            SKAction.scale(to: 1.0, duration: duration)
        ])
        group.timingMode = .easeOut
        run(group)
    }

    func pulseForever(scale: CGFloat = GameConfig.UI.buttonScale,
                      duration: TimeInterval = 0.8) {
        let scaleUp = SKAction.scale(to: scale, duration: duration / 2)
        let scaleDown = SKAction.scale(to: 1.0, duration: duration / 2)
        scaleUp.timingMode = .easeInEaseOut
        scaleDown.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])),
            withKey: "pulse")
    }

    func stopPulse() {
        removeAction(forKey: "pulse")
        setScale(1.0)
    }
}

// MARK: - SKLabelNode Factory

extension SKLabelNode {
    static func styled(
        text: String,
        fontSize: CGFloat,
        fontName: String = GameConfig.UI.fontName,
        color: SKColor = .white
    ) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }
}

// MARK: - SKShapeNode Helpers

extension SKShapeNode {
    static func roundedRect(
        size: CGSize,
        cornerRadius: CGFloat,
        color: SKColor
    ) -> SKShapeNode {
        let shape = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        shape.fillColor = color
        shape.strokeColor = .clear
        return shape
    }

    static func circle(
        radius: CGFloat,
        color: SKColor
    ) -> SKShapeNode {
        let shape = SKShapeNode(circleOfRadius: radius)
        shape.fillColor = color
        shape.strokeColor = .clear
        return shape
    }
}

// MARK: - SKScene Helpers

extension SKScene {
    var screenCenter: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }
}

// MARK: - TimeInterval Formatting

extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Int Formatting

extension Int {
    var formattedWithCommas: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    var abbreviated: String {
        if self >= 1_000_000 {
            return String(format: "%.1fM", Double(self) / 1_000_000.0)
        } else if self >= 1_000 {
            return String(format: "%.1fK", Double(self) / 1_000.0)
        }
        return "\(self)"
    }
}

// MARK: - Date Helpers

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

// MARK: - SKTexture Placeholder Generator

extension SKTexture {
    /// Creates a solid-color texture as a placeholder for missing assets.
    static func placeholder(color: SKColor, size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }
}

// MARK: - SKAction Helpers

extension SKAction {
    static func floatUpDown(amplitude: CGFloat, duration: TimeInterval) -> SKAction {
        let moveUp = SKAction.moveBy(x: 0, y: amplitude, duration: duration / 2)
        let moveDown = SKAction.moveBy(x: 0, y: -amplitude, duration: duration / 2)
        moveUp.timingMode = .easeInEaseOut
        moveDown.timingMode = .easeInEaseOut
        return SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
    }
}
