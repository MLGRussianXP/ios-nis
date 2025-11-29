//
//  RecipesApp.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
struct RecipesApp: App {
    init() {
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
