//
//  Recipe.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import Foundation

struct Recipe: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var author: String
    var difficulty: Int
    var createdById: String
    var createdAt: TimeInterval
    var timeToCookInSeconds: Int
    var type: String
    var ingredients: [Ingredient]
    var recipeSteps: [RecipeStep]
    var images: [String]
    
    func getNote(notes: [RecipeCloudNote]) -> RecipeCloudNote? {
        return notes.first(where: { $0.id == id })
    }
    
    func timeToCookString() -> String {
        guard self.recipeSteps.count > 0 else {
            return "0 s"
        }
        
        let time = self.recipeSteps.map({ $0.timeToSeconds() }).reduce(.zero, +)
        
        let h = time / 3600
        let m = (time - (time / 3600) * 3600) / 60
        let s = time % 60
        
        let hString: String = h > 0 ? "\(h) h\(s == 0 && m == 0 ? "" : ", ")" : ""
        let mString: String = m > 0 ? "\(m) m\(s == 0 ? "" : ", ")" : ""
        let sString: String = s > 0 || (m == 0 && h == 0) ? "\(s) s": ""
        
        return "\(hString)\(mString)\(sString)"
    }
}
