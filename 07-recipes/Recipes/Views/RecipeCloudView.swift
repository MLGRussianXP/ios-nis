//
//  RecipeCloudView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI
import FirebaseFirestore

struct RecipeCloudView: View {
    @StateObject private var viewModel = RecipeCloudViewModel()
    
    @FirestoreQuery private var notes: [RecipeCloudNote]
    
    let userId: String
    
    init(userId: String) {
        self.userId = userId
        
        self._notes = FirestoreQuery(
            collectionPath: "recipeCloudNotes"
        )
    }
    
    var body: some View {
        Form {
            ForEach(notes) { note in
                RecipeView(userId: userId, recipe: note.recipe)
            }
        }
    }
}

#Preview {
    RecipeCloudView(userId: "123")
}
