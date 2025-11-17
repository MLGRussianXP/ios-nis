import SwiftUI
import Combine

enum CellType {
    case normal
    case ladder(to: Int)
    case snake(to: Int)
}

struct Cell: Identifiable {
    let id: Int
    var type: CellType = .normal
}

struct Board {
    let width: Int
    let height: Int
    var cells: [Cell]

    var size: Int { cells.count }

    static func generate(width: Int = 5, height: Int = 5) -> Board {
        // Clamp reasonable board sizes to avoid extremely large grids
        let width = min(max(5, width), 12)
        let height = min(max(5, height), 12)
        let size = width * height
        var cells = (0..<size).map { Cell(id: $0, type: .normal) }
        // Safely add ladders and snakes without blocking or infinite loops.
        // Choose ladder starts from the lower half and ladder ends from the upper half.
        let maxPairs = max(1, size / 12)
        let ladderCount = min(8, maxPairs)
        let snakeCount = min(8, maxPairs)

        let mid = size / 2
        var available = Set(1..<(size - 1)) // cannot use 0 (start) or size-1 (finish)

        func randomFrom(_ set: Set<Int>, where predicate: (Int) -> Bool) -> Int? {
            let filtered = set.filter(predicate)
            return filtered.randomElement()
        }

        for _ in 0..<ladderCount {
            guard let start = randomFrom(available, where: { $0 < mid }),
                  let end = randomFrom(available, where: { $0 > mid && $0 > start })
            else { break }
            cells[start].type = .ladder(to: end)
            available.remove(start); available.remove(end)
        }

        for _ in 0..<snakeCount {
            guard let start = randomFrom(available, where: { $0 > mid }),
                  let end = randomFrom(available, where: { $0 < mid && $0 < start })
            else { break }
            cells[start].type = .snake(to: end)
            available.remove(start); available.remove(end)
        }

        return Board(width: width, height: height, cells: cells)
    }
}

struct Player: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var colorIndex: Int = 0
    var position: Int = 0

    static let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]

    var color: Color { Self.colors[colorIndex % Self.colors.count] }
}

struct GameResult: Identifiable, Codable {
    var id: UUID = UUID()
    let winnerName: String
    let playersDescription: String
    let date: Date
}

final class GameHistory: ObservableObject {
    @Published var results: [GameResult] = []

    init() {
        load()
    }

    func addResult(winner: Player, players: [Player]) {
        let desc = players.map { $0.name }.joined(separator: ", ")
        let r = GameResult(winnerName: winner.name, playersDescription: desc, date: Date())
        results.insert(r, at: 0)
        save()
    }

    func clear() {
        results.removeAll()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(data, forKey: "snake_history")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "snake_history"), let decoded = try? JSONDecoder().decode([GameResult].self, from: data) else { return }
        results = decoded
    }
}
