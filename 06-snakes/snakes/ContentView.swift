//
//  ContentView.swift
//  snakes
//
//  Created by dkqz on 17.11.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showPlayerPicker = true
    @State private var selectedPlayerCount = 2
    @State private var players: [Player] = []
    @State private var board: Board = Board.generate(width: 5, height: 5)
    @State private var currentPlayer = 0
    @State private var lastRoll = 1
    @State private var winner: Player? = nil
    @State private var moveStatus: String = ""
    @State private var animating = false
    @State private var pulse = false
    @Namespace private var animation
    @State private var showHistory = false
    @StateObject var history = GameHistory()
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    showHistory = true
                } label: {
                    Text(NSLocalizedString("Game History", comment: "Button title for game history"))
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.horizontal)
            
            Text(NSLocalizedString("Snakes & Ladders / Змеи и Лестницы", comment: "Title"))
                .font(.title)
                .padding(.top)
            if showPlayerPicker {
                VStack(spacing: 8) {
                    Text(NSLocalizedString("Select number of players:", comment: "Player count prompt"))
                        .font(.headline)
                    Picker(NSLocalizedString("Players", comment: "Picker label"), selection: $selectedPlayerCount) {
                        ForEach(2...6, id: \.self) { n in
                            Text("\(n)")
                        }
                    }
                    .pickerStyle(.segmented)
                    Button(NSLocalizedString("Start Game", comment: "Button title to start game")) {
                        // Generate board off the main thread to avoid blocking UI
                        startNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                boardView
                HStack {
                    ForEach(players) { player in
                        VStack {
                            Circle()
                                .fill(player.color)
                                .frame(width: 24, height: 24)
                            Text(String(format: NSLocalizedString("Player %@", comment: "Player label"), player.name))
                                .font(.caption)
                        }
                        .frame(minWidth: 44)
                    }
                }
                statusBar
                if let winner = winner {
                    Text(String(format: NSLocalizedString("Player %@ wins!", comment: "Winner message"), winner.name))
                        .font(.headline)
                        .foregroundStyle(.green)
                        .padding()
                    Button(NSLocalizedString("New Game", comment: "Button title for new game")) {
                        showPlayerPicker = true
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        rollDice()
                    } label: {
                        Text(String(format: NSLocalizedString("Roll for Player %@", comment: "Roll prompt"), players[currentPlayer].name))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(animating)
                    .padding(.horizontal)
                }
            }
            Spacer()
        }
        .padding()
        .onAppear {
            // start subtle pulsing animation for ladder/snake badges
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .animation(.default, value: players)
        .sheet(isPresented: $showHistory) {
            NavigationView {
                VStack {
                    if history.results.isEmpty {
                        Text(NSLocalizedString("No game history available.", comment: "Empty history message"))
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    } else {
                        List {
                            ForEach(history.results) { result in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(format: NSLocalizedString("Winner: Player %@", comment: "Winner label in history"), result.winnerName))
                                        .font(.headline)
                                    Text(String(format: NSLocalizedString("Players: %@", comment: "Players list in history"), result.playersDescription))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(result.date.formatted(date: .numeric, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete { offsets in
                                history.results.remove(atOffsets: offsets)
                            }
                        }
                    }
                }
                .navigationTitle(NSLocalizedString("Game History", comment: "Navigation title for history"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("Close", comment: "Close sheet button")) {
                            showHistory = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !history.results.isEmpty {
                            Button(NSLocalizedString("Clear", comment: "Clear history button")) {
                                history.clear()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
    
    var statusBar: some View {
        VStack(spacing: 0) {
            Text(String(format: NSLocalizedString("Last roll: %d", comment: "Roll result"), lastRoll))
                .font(.caption)
                .padding(.bottom, 2)
            if !moveStatus.isEmpty {
                Text(moveStatus)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var boardView: some View {
        GeometryReader { geo in
                let width = board.width
                let height = board.height
                // larger spacing so tiles are visually separated
                let spacing: CGFloat = 10
                let horizontalPadding: CGFloat = 8
                let verticalPadding: CGFloat = 8

                // Try to use as much of the central area as possible.
                // Reserve a small top area for controls; give the rest to the board.
                let reservedTopFraction: CGFloat = 0.14
                let boardAreaH = max(0, geo.size.height * (1.0 - reservedTopFraction) - verticalPadding * 2)

                let totalHSpacing = CGFloat(width - 1) * spacing
                let totalVSpacing = CGFloat(height - 1) * spacing
                let availableW = max(0, geo.size.width - horizontalPadding * 2 - totalHSpacing)
                let availableH = max(0, boardAreaH - totalVSpacing)

                let cellW = availableW / CGFloat(width)
                let cellH = availableH / CGFloat(height)
                // fill center: choose smaller so square cells, cap high but allow large cells
                let cellSize = min(max(min(cellW, cellH), 48), 200)

                // Build the grid centered and sized to the computed full area
                VStack(spacing: 0) {
                    VStack(spacing: spacing) {
                        ForEach((0..<height).reversed(), id: \.self) { row in
                            HStack(spacing: spacing) {
                                ForEach(0..<width, id: \.self) { col in
                                    let idx = row * width + ((row % 2 == 0) ? col : (width - 1 - col))
                                    if idx < board.size {
                                        cellView(cell: board.cells[idx], size: cellSize)
                                    } else {
                                        Rectangle().opacity(0)
                                            .frame(width: cellSize, height: cellSize)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: CGFloat(width) * cellSize + totalHSpacing, height: CGFloat(height) * cellSize + totalVSpacing)
                }
                .frame(width: geo.size.width, height: boardAreaH + verticalPadding * 2, alignment: .center)
            }
    }
    
    func cellView(cell: Cell, size: CGFloat) -> some View {
        ZStack {
            // visual intensity based on how far the ladder/snake moves
            let bg = cellBackground(for: cell)
            RoundedRectangle(cornerRadius: max(8, size * 0.12), style: .continuous)
                .fill(bg)
                .overlay(
                    RoundedRectangle(cornerRadius: max(8, size * 0.12))
                        .stroke(Color.primary.opacity(0.06), lineWidth: max(1, size * 0.03))
                )
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

            // Use overlay for badge so it doesn't change cell's intrinsic size
            VStack(spacing: 6) {
                HStack {
                    Text("\(cell.id + 1)")
                        .font(.system(size: max(12, size * 0.14), weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    Spacer()
                }

                // tokens centered
                playerTokensGrid(at: cell.id, cellSize: size)
                    .frame(width: size * 0.8, height: size * 0.36)
                    .padding(.top, 4)

                Spacer()
            }
            .overlay(alignment: .bottom) {
                Group {
                    switch cell.type {
                    case .ladder(let to):
                        let steps = max(1, to - cell.id)
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: size * 0.18))
                                .foregroundColor(.green)
                            Text("+\(steps)")
                                .font(.system(size: max(12, size * 0.12), weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.green.opacity(0.09))
                        .clipShape(Capsule())
                        .scaleEffect(pulse ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
                        .padding(.bottom, 6)
                    case .snake(let to):
                        let steps = max(1, cell.id - to)
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: size * 0.18))
                                .foregroundColor(.red)
                            Text("-\(steps)")
                                .font(.system(size: max(12, size * 0.12), weight: .bold))
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.red.opacity(0.09))
                        .clipShape(Capsule())
                        .scaleEffect(pulse ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
                        .padding(.bottom, 6)
                    default:
                        EmptyView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size, height: size)
    }
    
    @ViewBuilder
    func playerTokensGrid(at cellId: Int, cellSize: CGFloat) -> some View {
        let playersHere = players.enumerated().filter { $0.element.position == cellId }
        let tokenSize = max(6, cellSize * 0.16)
        let columns = Array(repeating: GridItem(.fixed(tokenSize), spacing: 4), count: 3)
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<6, id: \.self) { idx in
                if idx < playersHere.count {
                    let p = playersHere[idx].element
                    Circle()
                        .fill(p.color)
                        .frame(width: tokenSize, height: tokenSize)
                        .matchedGeometryEffect(id: p.id, in: animation)
                } else {
                    Color.clear.frame(width: tokenSize, height: tokenSize)
                }
            }
        }
    }
    
    func cellBackground(for cell: Cell) -> LinearGradient {
        switch cell.type {
        case .normal:
            return LinearGradient(colors: [Color(.systemGray6), .white], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ladder(let to):
            let steps = max(1, to - cell.id)
            let ratio = min(0.9, Double(steps) / Double(max(1, board.size)))
            return LinearGradient(colors: [Color(.systemGreen).opacity(0.12 + ratio * 0.45), Color(.systemMint).opacity(0.08 + ratio * 0.25)], startPoint: .top, endPoint: .bottom)
        case .snake(let to):
            let steps = max(1, cell.id - to)
            let ratio = min(0.9, Double(steps) / Double(max(1, board.size)))
            return LinearGradient(colors: [Color(.systemRed).opacity(0.08 + ratio * 0.35), Color(.systemGray6).opacity(0.05)], startPoint: .top, endPoint: .bottom)
        }
    }
    
    func startNewGame() {
        // Create players synchronously
        players = (0..<selectedPlayerCount).map { i in
            Player(name: "\(i + 1)", colorIndex: i % Player.colors.count)
        }
        currentPlayer = 0
        lastRoll = 1
        winner = nil
        moveStatus = ""

        // Generate board on a background queue to avoid UI freeze for large generation
        DispatchQueue.global(qos: .userInitiated).async {
            let newBoard = Board.generate(width: 5, height: 5)
            DispatchQueue.main.async {
                self.board = newBoard
                // Only hide the picker after board is ready so the view renders smoothly
                self.showPlayerPicker = false
            }
        }
    }
    
    func rollDice() {
        guard winner == nil, !animating else { return }
        let roll = Int.random(in: 1...6)
        lastRoll = roll
        let playerIdx = currentPlayer
        let player = players[playerIdx]
        let oldPosition = player.position
        let finalUnwrapped = moveWithSnakesAndLadders(from: oldPosition, roll: roll)
        animateMove(playerIdx: playerIdx, from: oldPosition, path: finalUnwrapped.path) {
            if finalUnwrapped.destination == board.size - 1 {
                winner = player
                history.addResult(winner: player, players: players)
            } else {
                currentPlayer = (currentPlayer + 1) % players.count
            }
            moveStatus = String(format: NSLocalizedString("Player %@ moves: %d → %d (by %d)", comment: "Move result"), player.name, oldPosition+1, finalUnwrapped.destination+1, roll)
        }
    }
    
    struct MovePath {
        let path: [Int]
        let destination: Int
    }
    
    func moveWithSnakesAndLadders(from pos: Int, roll: Int) -> MovePath {
        var path = [Int]()
        var curr = min(pos + roll, board.size - 1)
        if pos + 1 <= curr {
            path.append(contentsOf: (pos+1...curr))
        }
        var loop = true
        while loop {
            loop = false
            switch board.cells[curr].type {
            case .ladder(let to):
                if curr != to { path.append(to); curr = to; loop = true }
            case .snake(let to):
                if curr != to { path.append(to); curr = to; loop = true }
            default: break
            }
        }
        return MovePath(path: path, destination: curr)
    }
    
    func animateMove(playerIdx: Int, from start: Int, path: [Int], completion: @escaping () -> Void) {
        guard path.count > 0 else { completion(); return }
        animating = true
        var localPlayers = players
        func step(_ i: Int) {
            if i >= path.count {
                players = localPlayers
                animating = false
                completion()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                localPlayers[playerIdx].position = path[i]
                withAnimation(.easeInOut(duration: 0.23)) {
                    players = localPlayers
                }
                step(i + 1)
            }
        }
        step(0)
    }
}

#Preview {
    ContentView()
}
