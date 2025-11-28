//
//  RecipesApp.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI
import FirebaseCore

@main
struct RecipesApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
