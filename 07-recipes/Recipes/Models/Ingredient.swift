//
//  Ingredient.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import Foundation

struct Ingredient: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var quantity: Int
    var foodQuantityType: Int
}
