//
//  RecipeStep.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import Foundation

struct RecipeStep: Codable, Identifiable, Hashable {
    let id: String
    var text: String
    var time: Int
    var timeType: String
    
    func timeToSeconds() -> Int {
        let mult = self.timeType == "Seconds" ? 1 : self.timeType == "Minutes" ? 60 : 3600
        return self.time * mult
    }
}
