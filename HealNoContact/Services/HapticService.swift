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

    static func xpGain() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    static func levelUp() {
        let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
        heavyGen.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let mediumGen = UIImpactFeedbackGenerator(style: .medium)
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                    mediumGen.impactOccurred(intensity: 0.5 + CGFloat(i) * 0.2)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    static func questComplete() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    static func badgeUnlock(_ rarity: String) {
        switch rarity {
        case "common":
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case "rare":
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                gen.impactOccurred()
            }
        case "epic":
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) {
                    gen.impactOccurred(intensity: 0.6 + CGFloat(i) * 0.15)
                }
            }
        case "legendary":
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                for i in 0..<3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                        gen.impactOccurred(intensity: 0.5 + CGFloat(i) * 0.2)
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        default:
            break
        }
    }
}
