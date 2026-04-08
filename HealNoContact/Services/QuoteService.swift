import Foundation

@MainActor
final class QuoteService {
    static let shared = QuoteService()

    private init() {}

    struct HealingQuote: Identifiable {
        let id = UUID()
        let text: String
        let author: String
    }

    private let quotes: [HealingQuote] = [
        HealingQuote(text: "The wound is the place where the Light enters you.", author: "Rumi"),
        HealingQuote(text: "You can't start the next chapter if you keep re-reading the last one.", author: "Unknown"),
        HealingQuote(text: "Letting go doesn't mean giving up, it means moving on.", author: "Unknown"),
        HealingQuote(text: "Pain is inevitable. Suffering is optional.", author: "Haruki Murakami"),
        HealingQuote(text: "The only way out is through.", author: "Robert Frost"),
        HealingQuote(text: "Healing is not linear.", author: "Unknown"),
        HealingQuote(text: "You are allowed to be both a masterpiece and a work in progress.", author: "Sophia Bush"),
        HealingQuote(text: "What feels like the end is often the beginning.", author: "Unknown"),
        HealingQuote(text: "You survived what you thought would kill you. Now straighten your crown and move forward like the warrior you are.", author: "Unknown"),
        HealingQuote(text: "The strongest people are not those who show strength in front of us, but those who win battles we know nothing about.", author: "Unknown"),
        HealingQuote(text: "One day you will tell your story of how you overcame what you went through and it will be someone else's survival guide.", author: "Brené Brown"),
        HealingQuote(text: "Stars can't shine without darkness.", author: "D.H. Sidebottom"),
        HealingQuote(text: "Every next level of your life will demand a different version of you.", author: "Unknown"),
        HealingQuote(text: "Rock bottom became the solid foundation on which I rebuilt my life.", author: "J.K. Rowling"),
        HealingQuote(text: "Your heart knows the way. Run in that direction.", author: "Rumi"),
        HealingQuote(text: "Inhale the future. Exhale the past.", author: "Unknown"),
        HealingQuote(text: "No contact is not about them. It's about you choosing yourself.", author: "Unknown"),
        HealingQuote(text: "The person you're becoming will cost you people, relationships, spaces, and material things. Choose yourself anyway.", author: "Unknown"),
        HealingQuote(text: "Silence is the best reply to a fool.", author: "Imam Ali"),
        HealingQuote(text: "Not reaching out is a form of self-love.", author: "Unknown"),
        HealingQuote(text: "You don't need closure from them. You need peace from within.", author: "Unknown"),
        HealingQuote(text: "Missing someone is part of healing. It doesn't mean you should go back.", author: "Unknown"),
        HealingQuote(text: "Your value doesn't decrease based on someone's inability to see your worth.", author: "Unknown"),
        HealingQuote(text: "Sometimes the hardest part isn't letting go but learning to start over.", author: "Nicole Sobon"),
        HealingQuote(text: "Growth is painful. Change is painful. But nothing is as painful as staying stuck.", author: "Mandy Hale"),
    ]

    private let motivationalMessages: [String] = [
        "You're stronger than you think. Keep going.",
        "Every moment of resistance is a victory.",
        "Your future self will thank you for staying strong today.",
        "Healing happens one brave moment at a time.",
        "You chose yourself today. That takes courage.",
        "The urge is temporary. Your growth is permanent.",
        "You're not just surviving — you're becoming.",
        "Each day of no contact is a gift to yourself.",
        "Your peace of mind is worth more than any reply.",
        "Trust the process. Trust yourself.",
    ]

    private let copingStrategies: [String] = [
        "Take 5 deep breaths — in for 4 seconds, hold for 4, out for 6",
        "Write down what you want to say in an unsent letter",
        "Go for a 10-minute walk outside",
        "Call or text a friend who supports you",
        "Do 20 pushups or any physical movement",
        "Put on your favorite uplifting song and move",
        "Splash cold water on your face",
        "Write 3 things you're grateful for right now",
        "Open your journal and let it all out",
        "Remember why you started no contact",
        "Look at your streak — don't let it reset",
        "Set a 10-minute timer — the urge will pass",
        "Squeeze an ice cube — the sensation redirects your brain",
        "Read your personal mantra out loud 3 times",
        "Watch a funny video — laughter shifts your state",
    ]

    func dailyQuote() -> HealingQuote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return quotes[dayOfYear % quotes.count]
    }

    func randomQuote() -> HealingQuote {
        quotes.randomElement() ?? quotes[0]
    }

    func randomMotivational() -> String {
        motivationalMessages.randomElement() ?? motivationalMessages[0]
    }

    func randomCopingStrategy() -> String {
        copingStrategies.randomElement() ?? copingStrategies[0]
    }

    func copingStrategiesList() -> [String] {
        copingStrategies
    }
}
