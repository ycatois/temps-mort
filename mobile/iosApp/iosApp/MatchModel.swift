import Foundation
import Shared

/// Relais SwiftUI du MatchSession Kotlin (module shared) : même moteur que sur Android.
/// TODO V1 : persistance locale des événements (SQLite) et choix de l'équipe.
@MainActor
final class MatchModel: ObservableObject {
    let team: Team
    private let session: MatchSession

    @Published private(set) var state: MatchState
    @Published private(set) var selectedPlayerId: String?
    @Published private(set) var lastRejection: Rejection?

    init() {
        let players = [
            Player(id: "manon", firstName: "Manon", number: 5, gender: .f, role: .polyvalent),
            Player(id: "lucie", firstName: "Lucie", number: 7, gender: .f, role: .polyvalent),
            Player(id: "emma", firstName: "Emma", number: 12, gender: .f, role: .central),
            Player(id: "ines", firstName: "Inès", number: 3, gender: .f, role: .polyvalent),
            Player(id: "chloe", firstName: "Chloé", number: 9, gender: .f, role: .polyvalent),
            Player(id: "lea", firstName: "Léa", number: 14, gender: .f, role: .passeur),
            Player(id: "jade", firstName: "Jade", number: 1, gender: .f, role: .libero),
            Player(id: "zoe", firstName: "Zoé", number: 10, gender: .f, role: .polyvalent),
        ]
        team = Team(id: "demo", name: "M18 F", format: .six, gender: .feminine, category: .m18, players: players, minWomenOnCourt: 0)
        session = MatchSession(team: team, rules: MatchRules.Companion.shared.defaultFor(format: .six), events: [])
        state = session.state
        record(MatchEventStartSet(firstServer: .us, lineup: ["manon", "chloe", "emma", "ines", "lucie", "lea"], liberoId: "jade"))
    }

    var canUndo: Bool { session.canUndo }

    func select(_ id: String) { selectedPlayerId = selectedPlayerId == id ? nil : id }

    func action(_ action: RallyAction) {
        record(MatchEventRally(winner: action.scoring ? .us : .them, playerId: selectedPlayerId, action: action))
        selectedPlayerId = nil
    }

    func opponentError() { record(MatchEventRally(winner: .us, playerId: nil, action: .fauteAdverse)) }
    func opponentPoint() { record(MatchEventRally(winner: .them, playerId: nil, action: nil)) }
    func timeout() { record(MatchEventTimeout(side: .us)) }

    func undo() {
        session.undo()
        state = session.state
        lastRejection = nil
    }

    func label(_ id: String) -> (number: Int32, name: String) {
        guard let p = team.player(id: id) else { return (0, "?") }
        return (p.number, p.firstName)
    }

    private func record(_ event: MatchEvent) {
        lastRejection = session.record(event: event)
        state = session.state
    }
}
