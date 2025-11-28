//
//  RecipesView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI
import FirebaseFirestore

struct RecipesView: View {
    @StateObject private var viewModel = RecipesViewModel()
    
    @FirestoreQuery private var recipes: [Recipe]
    
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
        
        self._recipes = FirestoreQuery(
            collectionPath: "users/\(userId)/recipes"
        )
    }
    
    var body: some View {
        Form {
            ForEach(recipes) { recipe in
                RecipeView(userId: userId, recipe: recipe)
            }
        }
        .toolbar {
            Button {
                viewModel.showingNewRecipeView = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $viewModel.showingNewRecipeView) {
            EditRecipeView(newRecipePresented: $viewModel.showingNewRecipeView)
        }
    }
}

#Preview {
}
