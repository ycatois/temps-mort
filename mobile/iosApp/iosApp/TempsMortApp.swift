import SwiftUI

@main
struct TempsMortApp: App {
    var body: some Scene {
        WindowGroup {
            MatchView()
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true } // écran allumé pendant le match
        }
    }
}
