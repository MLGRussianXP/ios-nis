//
//  RecipeViewModel.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import Foundation
import FirebaseAuth
internal import Combine
internal import FirebaseFirestoreInternal

class RecipeViewModel: ObservableObject {
    @Published var showingWatchRecipeView = false
    @Published var showingCreatorProfile = false
    @Published var showingEditRecipeView = false
    @Published var showingRemoveFromMyRecipesAlert = false
    @Published var showingRemoveFromRecipeCloudAlert = false
    @Published var showingShareWithRecipeCloudAlert = false
    @Published var comment: String = ""
    
    func watchRecipe() {
        self.showingWatchRecipeView = true
    }
    
    func watchCreatorProfile() {
        self.showingCreatorProfile = true
    }
    
    func editRecipe() {
        self.showingEditRecipeView = true
    }
    
    func removeFromMyRecipes() {
        self.showingRemoveFromMyRecipesAlert = true
    }
    
    func removeFromRecipeCloud() {
        self.showingRemoveFromRecipeCloudAlert = true
    }
    
    func shareWithRecipeCloud() {
        self.comment = "Look at this amazing recipe!"
        self.showingShareWithRecipeCloudAlert = true
    }
    
    func showEditButton(recipe: Recipe, notes: [RecipeCloudNote]) -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        
        if let note = recipe.getNote(notes: notes) {
            return note.authorId == userId
        } else {
            return true
        }
    }
    
    func likeNote(note: RecipeCloudNote) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Utils.db.collection("recipeCloudNotes").document(note.id).collection("likes").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                let id = Id(id: userId)
                
                if documents.first(where: { $0["id"] as? String == userId }) == nil {
                    Utils.db.collection("recipeCloudNotes").document(note.id).collection("likes").document(id.id).setData(id.asDictionary())
                } else {
                    Utils.db.collection("recipeCloudNotes").document(note.id).collection("likes").document(id.id).delete()
                }
            }
        }
    }
}
