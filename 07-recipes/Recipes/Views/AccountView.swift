//
//  AccountView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    
    let userId: String
    
    var body: some View {
        TabView {
            NavigationView {
                RecipesView(userId: userId)
            }
            .tabItem {
                Label("My Recipes", systemImage: "house")
            }
            
            NavigationView {
                RecipeCloudView(userId: userId)
            }
            .tabItem {
                Label("Recipe Cloud", systemImage: "cloud")
            }
            
            NavigationView {
                ProfileView(userId: userId)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
        }
    }
}

#Preview {
    AccountView(userId: "123")
}
