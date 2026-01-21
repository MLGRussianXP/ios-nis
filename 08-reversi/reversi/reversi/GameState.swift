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
}
