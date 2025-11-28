//
//  User.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import Foundation

struct User : Codable, Identifiable, Hashable {
    let id: String
    var username: String
    var email: String
    var joined: TimeInterval
}
