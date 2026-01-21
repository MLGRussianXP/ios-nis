//
//  GameState.swift
//  reversi
//
//  Created by dkqz on 21.01.2026.
//

import Foundation

@Observable
class GameState {
    // Игровое поле 8x8
    var board: [[CellType]]
    
    // Текущий игрок
    var currentPlayer: Player
    
    // Режим игры
    var gameMode: GameMode
    
    // Состояние игры
    var isGameOver: Bool
    var winner: Player?
    
    // MARK: - Initialization
    init(gameMode: GameMode = .humanVsHuman) {
        self.board = Array(repeating: Array(repeating: .empty, count: 8), count: 8)
        self.currentPlayer = .black
        self.gameMode = gameMode
        self.isGameOver = false
        self.winner = nil
        
        // Начальная расстановка фишек в центре
        setupInitialBoard()
    }
    
    // MARK: - Setup
    
    /// Установить начальную позицию фишек (4 фишки в центре по диагонали)
    private func setupInitialBoard() {
        // Белые фишки
        board[3][3] = .white
        board[4][4] = .white
        
        // Черные фишки
        board[3][4] = .black
        board[4][3] = .black
    }
    
    // MARK: - Computed Properties
    
    /// Количество черных фишек
    var blackCount: Int {
        board.flatMap { $0 }.filter { $0 == .black }.count
    }
    
    /// Количество белых фишек
    var whiteCount: Int {
        board.flatMap { $0 }.filter { $0 == .white }.count
    }
    
    /// Количество пустых клеток
    var emptyCount: Int {
        board.flatMap { $0 }.filter { $0 == .empty }.count
    }
    
    // MARK: - Helper Methods
    
    /// Получить тип клетки по позиции
    func cellAt(_ position: Position) -> CellType {
        guard position.isValid() else { return .empty }
        return board[position.row][position.col]
    }
    
    /// Установить тип клетки по позиции
    func setCell(_ position: Position, to type: CellType) {
        guard position.isValid() else { return }
        board[position.row][position.col] = type
    }
    
    // MARK: - Move Validation
    
    /// Проверить, является ли ход валидным для текущего игрока
    func isValidMove(_ position: Position, for player: Player) -> Bool {
        // Клетка должна быть свободна
        guard position.isValid(), cellAt(position) == .empty else {
            return false
        }
        
        // Должна быть хотя бы одна фишка противника, которую можно замкнуть
        return !getFlippedPieces(position, for: player).isEmpty
    }
    
    /// Получить список фишек, которые будут перевернуты при ходе
    func getFlippedPieces(_ position: Position, for player: Player) -> [Position] {
        var flippedPieces: [Position] = []
        let playerCell = player.cellType
        let opponentCell = player.opposite.cellType
        
        // Проверяем все 8 направлений
        for direction in Direction.all {
            var tempFlipped: [Position] = []
            var currentPos = Position(
                row: position.row + direction.rowOffset,
                col: position.col + direction.colOffset
            )
            
            // Идем в направлении, пока не достигнем края или пустой клетки
            while currentPos.isValid() {
                let cell = cellAt(currentPos)
                
                if cell == .empty {
                    // Встретили пустую клетку - этот путь не валиден
                    break
                } else if cell == opponentCell {
                    // Встретили фишку противника - добавляем в список
                    tempFlipped.append(currentPos)
                    currentPos = Position(
                        row: currentPos.row + direction.rowOffset,
                        col: currentPos.col + direction.colOffset
                    )
                } else if cell == playerCell {
                    // Встретили свою фишку - все фишки между замыкаются
                    if !tempFlipped.isEmpty {
                        flippedPieces.append(contentsOf: tempFlipped)
                    }
                    break
                }
            }
        }
        
        return flippedPieces
    }
    
    /// Получить все валидные ходы для игрока
    func getValidMoves(for player: Player) -> [Position] {
        var validMoves: [Position] = []
        
        for row in 0..<8 {
            for col in 0..<8 {
                let position = Position(row: row, col: col)
                if isValidMove(position, for: player) {
                    validMoves.append(position)
                }
            }
        }
        
        return validMoves
    }
    
    // MARK: - Game Actions
    
    /// Совершить ход
    func makeMove(_ position: Position) -> Bool {
        guard isValidMove(position, for: currentPlayer) else {
            return false
        }
        
        // Ставим фишку текущего игрока
        setCell(position, to: currentPlayer.cellType)
        
        // Переворачиваем фишки противника
        let flippedPieces = getFlippedPieces(position, for: currentPlayer)
        for piece in flippedPieces {
            setCell(piece, to: currentPlayer.cellType)
        }
        
        // Переходим к следующему игроку
        switchPlayer()
        
        return true
    }
    
    /// Переключить текущего игрока
    private func switchPlayer() {
        currentPlayer = currentPlayer.opposite
        
        // Проверяем, может ли новый игрок сделать ход
        let validMoves = getValidMoves(for: currentPlayer)
        
        if validMoves.isEmpty {
            // Текущий игрок не может ходить, передаем ход обратно
            currentPlayer = currentPlayer.opposite
            
            // Проверяем, может ли другой игрок ходить
            let otherPlayerMoves = getValidMoves(for: currentPlayer)
            
            if otherPlayerMoves.isEmpty {
                // Никто не может ходить - игра окончена
                endGame()
            }
        }
    }
    
    /// Завершить игру и определить победителя
    private func endGame() {
        isGameOver = true
        
        if blackCount > whiteCount {
            winner = .black
        } else if whiteCount > blackCount {
            winner = .white
        } else {
            winner = nil // Ничья
        }
    }
    
    /// Начать новую игру
    func resetGame() {
        board = Array(repeating: Array(repeating: .empty, count: 8), count: 8)
        currentPlayer = .black
        isGameOver = false
        winner = nil
        setupInitialBoard()
    }
}
