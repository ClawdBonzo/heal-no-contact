import WidgetKit
import SwiftUI

@main
struct HealNoContactWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        SOSWidget()
        MantraWidget()
    }
}
