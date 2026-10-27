import SwiftUI
import Shared

/// E05 — Match en direct. iPad paysage : terrain et panneau côte à côte ; iPhone : empilés.
struct MatchView: View {
    @StateObject private var model = MatchModel()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack(spacing: 0) {
            scoreBar
            Group {
                if sizeClass == .regular {
                    HStack(alignment: .top, spacing: 16) { court; panel }
                } else {
                    ScrollView { VStack(spacing: 12) { court; panel } }
                }
            }
            .padding(16)
            Spacer(minLength: 0)
        }
        .background(TmColor.groundApp.ignoresSafeArea())
    }

    private var scoreBar: some View {
        let s = model.state
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SET \(s.setIndex + 1) · \(model.team.format.label)").font(.barlow(13, .semibold)).foregroundStyle(TmColor.onNavyMuted)
                Text("Sets \(s.setsWon.us)–\(s.setsWon.them)").font(.barlow(15)).foregroundStyle(TmColor.onNavy)
            }
            Spacer()
            Text("\(s.score.us) – \(s.score.them)")
                .font(.barlowCondensed(56)).foregroundStyle(.white)
                .accessibilityLabel("Score \(s.score.us) à \(s.score.them)")
            Spacer()
            Button("Temps mort \(s.timeoutsUsed.us)/\(s.rules.timeoutsPerSet)") { model.timeout() }
                .font(.barlow(16, .bold)).foregroundStyle(TmColor.navy)
                .padding(.horizontal, 16).frame(minHeight: TmTouch.minTarget)
                .background(TmColor.yellow, in: RoundedRectangle(cornerRadius: TmRadius.md))
                .disabled(s.timeoutsLeft(side: .us) <= 0)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(TmColor.navy.ignoresSafeArea(edges: .top))
    }

    private var court: some View {
        let s = model.state
        let lineup = s.lineup
        // Avant (4 3 2) en haut, arrière (5 6 1) en bas ; index 0 = poste 1.
        let rows: [[Int]] = lineup.count == 6 ? [[3, 2, 1], [4, 5, 0]] : lineup.count == 4 ? [[2, 1], [3, 0]] : [Array(lineup.indices)]
        return VStack(alignment: .leading, spacing: 10) {
            Text("R\(s.rotation) · \(s.serving == .us ? "au service" : "en réception")").font(.barlow(16, .bold)).foregroundStyle(.white)
            VStack(spacing: 24) {
                ForEach(rows, id: \.self) { row in
                    HStack {
                        ForEach(row.filter { $0 < lineup.count }, id: \.self) { idx in
                            Spacer()
                            token(lineup[idx], serving: idx == 0 && s.serving == .us)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .background(TmColor.court)
            .border(.white, width: 2)
        }
        .padding(14)
        .background(TmColor.courtOut, in: RoundedRectangle(cornerRadius: TmRadius.lg))
    }

    private func token(_ id: String, serving: Bool) -> some View {
        let p = model.label(id)
        let libero = id == model.state.liberoId
        let selected = id == model.selectedPlayerId
        return Button { model.select(id) } label: {
            VStack(spacing: 0) {
                Text("\(p.number)").font(.barlowCondensed(24))
                Text(libero ? "\(p.name) · L" : p.name).font(.barlow(12, .semibold))
            }
            .foregroundStyle(libero ? TmColor.navy : .white)
            .frame(width: 76, height: 76)
            .background(libero ? Color.white : TmColor.navy, in: Circle())
            .overlay(Circle().stroke(selected ? TmColor.accent : serving ? TmColor.yellow : (libero ? TmColor.navy : .white), lineWidth: selected ? 4 : serving ? 3 : 2))
        }
        .accessibilityLabel("\(p.name), numéro \(p.number)\(serving ? ", au service" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if model.state.phase == .finished {
                Text(model.state.winner == .us ? "Match gagné \(model.state.setsWon)" : "Match perdu \(model.state.setsWon)")
                    .font(.barlowCondensed(28))
            } else if model.canStartNextSet {
                big("Set \(model.state.setIndex + 1) : même composition", bg: TmColor.yellow, fg: TmColor.navy) { model.startNextSet() }
            }
            Text(model.selectedPlayerId.map { "#\(model.label($0).number) \(model.label($0).name) : choisir l'action" } ?? "Touchez une joueuse, puis l'action")
                .font(.barlow(18, .bold))
            HStack(spacing: 8) {
                ForEach([RallyAction.attaque, .ace, .contre], id: \.self) { a in
                    big(a.label, bg: TmColor.accent, fg: .white) { model.action(a) }
                }
            }
            HStack(spacing: 8) {
                ForEach([RallyAction.attaqueFaute, .serviceFaute, .receptionFaute], id: \.self) { a in
                    Button { model.action(a) } label: {
                        Text(a.label).font(.barlow(15, .bold)).foregroundStyle(TmColor.navy)
                            .frame(maxWidth: .infinity, minHeight: TmTouch.primaryTarget)
                            .overlay(RoundedRectangle(cornerRadius: TmRadius.md).stroke(TmColor.error, lineWidth: 2))
                    }
                }
            }
            HStack(spacing: 8) {
                big("+1 faute adverse", bg: TmColor.navy, fg: .white) { model.opponentError() }
                big("+1 adversaire", bg: TmColor.surfaceAlt, fg: TmColor.navy) { model.opponentPoint() }
            }
            Button("Annuler la dernière saisie") { model.undo() }
                .font(.barlow(16, .bold)).frame(maxWidth: .infinity, minHeight: TmTouch.minTarget)
                .overlay(RoundedRectangle(cornerRadius: TmRadius.md).stroke(TmColor.navy, lineWidth: 2))
                .disabled(!model.canUndo)
            if let r = model.lastRejection {
                Text("Action refusée : \(String(describing: r))").font(.barlow(15)).foregroundStyle(TmColor.error)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func big(_ label: String, bg: Color, fg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.barlow(16, .bold)).foregroundStyle(fg)
                .frame(maxWidth: .infinity, minHeight: TmTouch.primaryTarget)
                .background(bg, in: RoundedRectangle(cornerRadius: TmRadius.md))
        }
    }
}
