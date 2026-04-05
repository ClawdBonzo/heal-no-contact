import UIKit

enum HapticService {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func milestone() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    static func urgePulse() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8) {
                generator.impactOccurred(intensity: 0.4 + CGFloat(i) * 0.15)
            }
        }
    }
}
