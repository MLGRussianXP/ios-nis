import Foundation

enum Cell: String {
	case empty = " "
	case x = "X"
	case o = "O"
}

struct Game {
	let n: Int // board size
	var board: [Cell]
	var current: Cell = .x
	let vsComputer: Bool

	init(n: Int, vsComputer: Bool) {
		self.n = n
		self.vsComputer = vsComputer
		self.board = Array(repeating: .empty, count: n * n)
	}

	func printBoard() {
		for r in 0..<n {
			var parts: [String] = []
			for c in 0..<n {
				let i = r*n + c
				let s = board[i] == .empty ? String(i+1) : board[i].rawValue
				parts.append(s.count == 1 ? " \(s) " : "\(s) ")
			}
			print(parts.joined(separator: "|"))
			if r < n-1 {
				print(String(repeating: "-", count: n*4-1))
			}
		}
		print()
	}

	// Returns winner (X/O) if found, nil if no winner
	func winner(of b: [Cell]) -> Cell? {
		// check each row
		for r in 0..<n {
			let start = r*n
			if b[start] != .empty && (0..<n).allSatisfy({ b[start+$0] == b[start] }) {
				return b[start]
			}
		}
		// cols
		for c in 0..<n {
			if b[c] != .empty {
				var ok = true
				for r in 0..<n { if b[r*n + c] != b[c] { ok = false; break } }
				if ok { return b[c] }
			}
		}
		// diag
		if b[0] != .empty {
			var ok = true
			for i in 0..<n { if b[i*n + i] != b[0] { ok = false; break } }
			if ok { return b[0] }
		}
		// anti-diag
		if b[n-1] != .empty {
			var ok = true
			for i in 0..<n { if b[i*n + (n-1-i)] != b[n-1] { ok = false; break } }
			if ok { return b[n-1] }
		}
		return nil
	}

	func isFull(_ b: [Cell]) -> Bool { !b.contains(.empty) }

	mutating func play() {
		while true {
			printBoard()
			if let w = winner(of: board) { print("Result: \(w.rawValue) wins!"); break }
			if isFull(board) { print("Result: Draw"); break }

			if vsComputer && current == .o {
				let move = bestMove()
				board[move] = .o
				print("Computer: \(move+1)")
			} else {
				var idx: Int? = nil
				repeat {
					print("Player \(current.rawValue), enter cell (1..\(n*n)): ", terminator: "")
					if let s = readLine(), let v = Int(s.trimmingCharacters(in: .whitespaces)), v >= 1, v <= n*n {
						if board[v-1] == .empty { idx = v-1 } else { print("Occupied") }
					} else { print("Invalid") }
				} while idx == nil
				board[idx!] = current
			}
			current = current == .x ? .o : .x
		}
	}

	// smart ai using simple strategy
	func bestMove() -> Int {
		// get list of empty cells
		let empties = board.indices.filter { board[$0] == .empty }
		
		// 1. try to win in one move
		if let win = findWinningMove(for: .o) {
			return win
		}
		
		// 2. block opponent's win
		if let block = findWinningMove(for: .x) {
			return block
		}
		
		// 3. try to make a fork (two ways to win)
		if let fork = findForkMove() {
			return fork
		}
		
		// 4. take center if empty
		let center = (n*n - 1)/2
		if board[center] == .empty {
			return center
		}
		
		// 5. take corner if empty
		let corners = [0, n-1, n*(n-1), n*n-1]
		for corner in corners where board[corner] == .empty {
			return corner
		}
		
		// 6. take any empty cell
		return empties.randomElement()!
	}

	// check if we can win in one move
	func findWinningMove(for player: Cell) -> Int? {
		let empties = board.indices.filter { board[$0] == .empty }
		
		for cell in empties {
			var testBoard = board
			testBoard[cell] = player
			if winner(of: testBoard) == player {
				return cell
			}
		}
		return nil
	}

	// look for a move that creates two ways to win
	func findForkMove() -> Int? {
		let empties = board.indices.filter { board[$0] == .empty }
		
		for cell in empties {
			var winningWays = 0
			var testBoard = board
			testBoard[cell] = .o
			
			// check all lines
			for i in 0..<n {
				// check row
				let row = i * n
				if testBoard[row..<row+n].filter({ $0 == .o }).count == n-1 &&
				   testBoard[row..<row+n].contains(.empty) {
					winningWays += 1
				}
				
				// check column
				let col = (0..<n).map { testBoard[i + $0*n] }
				if col.filter({ $0 == .o }).count == n-1 &&
				   col.contains(.empty) {
					winningWays += 1
				}
			}
			
			// check diagonals
			let diag = (0..<n).map { testBoard[$0*n + $0] }
			if diag.filter({ $0 == .o }).count == n-1 &&
			   diag.contains(.empty) {
				winningWays += 1
			}
			
			let antiDiag = (0..<n).map { testBoard[$0*n + (n-1-$0)] }
			if antiDiag.filter({ $0 == .o }).count == n-1 &&
			   antiDiag.contains(.empty) {
				winningWays += 1
			}
			
			// if we found a fork (2+ ways to win), use this move
			if winningWays >= 2 {
				return cell
			}
		}
		return nil
	}
}

func prompt(_ text: String, range: ClosedRange<Int>) -> Int {
	while true {
		print(text, terminator: " ")
		if let s = readLine(), let v = Int(s.trimmingCharacters(in: .whitespaces)), range.contains(v) { return v }
		print("Enter number in \(range)")
	}
}

func main() {
	print("Tic-Tac-Toe")
	while true {
		let n = prompt("Board size (3..6):", range: 3...6)
		print("1) Human vs Human  2) Human vs Computer")
		let mode = prompt("Mode:", range: 1...2)
		var g = Game(n: n, vsComputer: mode == 2)
		g.play()
		print("Play again? (y/n)", terminator: " ")
		if let a = readLine()?.lowercased(), a == "y" { continue } else { break }
	}
}

main()