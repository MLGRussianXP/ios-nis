//
//  Models.swift
//  reversi
//
//  Created by dkqz on 21.01.2026.
//

import Foundation

// MARK: - Cell Type
enum CellType {
    case empty
    case black
    case white
    
    var opposite: CellType {
        switch self {
        case .black: return .white
        case .white: return .black
        case .empty: return .empty
        }
    }
}

// MARK: - Player
enum Player {
    case black
    case white
    
    var cellType: CellType {
        switch self {
        case .black: return .black
        case .white: return .white
        }
    }
    
    var opposite: Player {
        switch self {
        case .black: return .white
        case .white: return .black
        }
    }
    
    var name: String {
        switch self {
        case .black: return "Черные"
        case .white: return "Белые"
        }
    }
}

// MARK: - Game Mode
enum GameMode {
    case humanVsHuman
    case humanVsComputer(difficulty: AIDifficulty)
}

// MARK: - AI Difficulty
enum AIDifficulty {
    case beginner
    case professional
    
    var name: String {
        switch self {
        case .beginner: return "Новичок"
        case .professional: return "Профессионал"
        }
    }
}

// MARK: - Position
struct Position: Equatable, Hashable {
    let row: Int
    let col: Int
    
    func isValid() -> Bool {
        return row >= 0 && row < 8 && col >= 0 && col < 8
    }
}

// MARK: - Direction
struct Direction {
    let rowOffset: Int
    let colOffset: Int
    
    static let all: [Direction] = [
        Direction(rowOffset: -1, colOffset: -1), // верх-лево
        Direction(rowOffset: -1, colOffset: 0),  // верх
        Direction(rowOffset: -1, colOffset: 1),  // верх-право
        Direction(rowOffset: 0, colOffset: -1),  // лево
        Direction(rowOffset: 0, colOffset: 1),   // право
        Direction(rowOffset: 1, colOffset: -1),  // низ-лево
        Direction(rowOffset: 1, colOffset: 0),   // низ
        Direction(rowOffset: 1, colOffset: 1)    // низ-право
    ]
}
