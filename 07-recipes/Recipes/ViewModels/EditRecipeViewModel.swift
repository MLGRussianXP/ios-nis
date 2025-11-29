//
//  EditRecipeViewModel.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseAuth
internal import Combine
internal import FirebaseFirestoreInternal

class EditRecipeViewModel : ObservableObject {
    @Published var recipe: Recipe = Preview.recipe
    @Published var pickerItems = [PhotosPickerItem]()
    @Published var errorMessage: String = ""
    @Published var showingErrorAlert: Bool = false
    
    func updateData(recipeOptional: Recipe?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        if let recipe = recipeOptional {
            self.recipe = recipe
        } else {
            self.recipe = Recipe(
                id: UUID().uuidString,
                title: "",
                author: "",
                difficulty: 5,
                createdById: userId,
                createdAt: Date().timeIntervalSince1970,
                timeToCookInSeconds: 0,
                type: "Starter",
                ingredients: [],
                recipeSteps: [RecipeStep(
                    id: UUID().uuidString,
                    text: "Prepare ingredients",
                    time: 1,
                    timeType: "Minutes"
                )],
                images: []
            )
        }
    }
    
    func addIngredient() {
        recipe.ingredients.append(
            Ingredient(
                id: UUID().uuidString,
                title: "",
                quantity: 1,
                foodQuantityType: 0
            )
        )
    }
    
    func addStep() {
        recipe.recipeSteps.append(
            RecipeStep(
                id: UUID().uuidString,
                text: "",
                time: 1,
                timeType: "Seconds"
            )
        )
    }
    
    func addImage(image: String) {
        recipe.images.append(image)
    }
    
    func removeIngredient(ingredientNumber: Int) {
        recipe.ingredients.remove(at: ingredientNumber)
    }
    
    func removeStep(stepNumber: Int) {
        recipe.recipeSteps.remove(at: stepNumber)
    }
    
    func save(oldRecipeOptional: Recipe?) {
        guard canSave(oldRecipeOptional: oldRecipeOptional) else {
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        recipe.timeToCookInSeconds = recipe.recipeSteps.map({ $0.timeToSeconds() }).reduce(.zero, +)
        
        if let oldRecipe = oldRecipeOptional {
            if recipe.title == oldRecipe.title &&
                recipe.author == oldRecipe.author &&
                recipe.difficulty == oldRecipe.difficulty &&
                recipe.timeToCookInSeconds == oldRecipe.timeToCookInSeconds &&
                recipe.type == oldRecipe.type &&
                recipe.ingredients == oldRecipe.ingredients &&
                recipe.recipeSteps == oldRecipe.recipeSteps &&
                recipe.images == oldRecipe.images {
                return
            }
        }
        
        var newRecipe = recipe
        newRecipe.createdById = userId
        
        saveRecipe(recipe: newRecipe)
    }
    
    private func saveRecipe(recipe: Recipe) {
        Utils.db.collection("recipeCloudNotes").document(recipe.id).updateData(["recipe" : recipe.asDictionary()])
        
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        Utils.db.collection("users")
            .document(userId)
            .collection("recipes")
            .document(recipe.id)
            .setData(recipe.asDictionary())
    }
    
    func canSave(oldRecipeOptional: Recipe?) -> Bool {
        self.errorMessage = ""
        
        guard !recipe.title.trimmingCharacters(in: .whitespaces).isEmpty &&
            !recipe.author.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.errorMessage = "Please fill in all fields"
            return false
        }
        
        guard recipe.recipeSteps.count > 0 else {
            self.errorMessage = "Add steps"
            return false
        }
        
        guard recipe.ingredients.count > 0 else {
            self.errorMessage = "Add ingredients"
            return false
        }
        
        for i in 0..<recipe.ingredients.count {
            if recipe.ingredients[i].title.trimmingCharacters(in: .whitespaces).isEmpty {
                self.errorMessage = "Please fill in all fields"
                return false
            }
            
            if recipe.ingredients[i].quantity <= 0 {
                self.errorMessage = "Set quantity for all ingredients"
                return false
            }
        }
        
        for i in 0..<recipe.recipeSteps.count {
            if recipe.recipeSteps[i].text.trimmingCharacters(in: .whitespaces).isEmpty {
                self.errorMessage = "Please fill in all fields"
                return false
            }
            
            if recipe.recipeSteps[i].time <= 0 {
                self.errorMessage = "Set time for all steps"
                return false
            }
        }
        
        return true
    }
}
