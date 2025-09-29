import Foundation

print("Select number of players (2-6):")
let players = Int(readLine()!)!
var squares = [Int](repeating: 0, count: players)

let finalSquare = 25
var board = [Int](repeating: 0, count: finalSquare + 1)

// ladders
for _ in 1...3 {
    let start = Int.random(in: 2..<(finalSquare - 5))
    let end = Int.random(in: (start+1)...finalSquare-1)
    board[start] = end - start
}

// snakes
for _ in 1...3 {
    let head = Int.random(in: 6..<finalSquare)
    let tail = Int.random(in: 1..<(head-1))
    board[head] = tail - head
}

var diceRoll = 0
var playerIndex = -1

repeat {
    playerIndex = (playerIndex + 1) % players
    
    // roll the dice
    diceRoll = Int.random(in: 1...6)
    
    // keep player at the same square if the next move is more than 25
    if squares[playerIndex] + diceRoll > finalSquare {
        print("Player \(playerIndex + 1) jumps over and gets back to the same spot! (square \(squares[playerIndex]))")
        continue
    }
    
    // move by the rolled amount
    squares[playerIndex] += diceRoll
    print("Player \(playerIndex + 1) is on square \(squares[playerIndex]) with a roll of \(diceRoll).")
    
    // move up or down for a snake or ladder
    if board[squares[playerIndex]] != 0 {
        print("Player \(playerIndex + 1) goes \(board[squares[playerIndex]] > 0 ? "up" : "down") to square \(squares[playerIndex] + board[squares[playerIndex]])!")
        squares[playerIndex] += board[squares[playerIndex]]
    }
    
    // announce the win
    if squares[playerIndex] == finalSquare {
        print("Player \(playerIndex + 1) won!")
    }

} while (!squares.contains(where: { $0 == finalSquare }))

print("Game over!")
