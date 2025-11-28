//
//  EditRecipeView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI
import PhotosUI

struct EditRecipeView: View {
    @StateObject private var viewModel = EditRecipeViewModel()
    
    var recipeOptional: Recipe? = nil
    
    @Binding var newRecipePresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Text(recipeOptional == nil ? "New Recipe" : "Edit \(recipeOptional!.title)")
                    .font(.title)
                    .bold()
                    .padding(.top, 50)
                
                Form {
                    details()
                    ingredients()
                    recipeSteps()
                    images()
                }
                
                Button("Save") {
                    if viewModel.canSave(oldRecipeOptional: recipeOptional) {
                        viewModel.save(oldRecipeOptional: recipeOptional)
                        newRecipePresented = false
                    } else {
                        viewModel.showingErrorAlert = true
                    }
                }
                .padding()
                .frame(maxHeight: 80)
            }
        }
        .onAppear {
            viewModel.updateData(recipeOptional: recipeOptional)
        }
    }
    
    @ViewBuilder
    private func details() -> some View {
        Section("Details") {
            LabeledContent {
                TextField("Enter Title", text: $viewModel.recipe.title)
                    .textFieldStyle(DefaultTextFieldStyle())
                    .padding(.leading, 20)
            } label: {
                Text("Title")
            }
            
            LabeledContent {
                TextField("Enter Author", text: $viewModel.recipe.author)
                    .textFieldStyle(DefaultTextFieldStyle())
                    .padding(.leading, 20)
            } label: {
                Text("Author")
            }
            
            LabeledContent {
                RatingView(rating: $viewModel.recipe.difficulty)
            } label: {
                Text("Difficulty")
            }
            
            Picker(
                "Type",
                selection: $viewModel.recipe.type
            ) {
                ForEach(["Breakfast", "Lunch", "Dinner", "Dessert", "Drink"], id: \.self) { type in
                    Text("\(type)").tag(type)
                }
            }
            .frame(minWidth: 140)
            .pickerStyle(.automatic)
        }
    }
    
    @ViewBuilder
    private func ingredients() -> some View {
        Section("Ingredients") {
            Button {
                viewModel.addIngredient()
            } label: {
                Label("Add Ingredient", systemImage: "plus")
            }
            
            List(viewModel.recipe.ingredients) { ingredient in
                let ingredientNumber = viewModel.recipe.ingredients.firstIndex(of: ingredient)!
                
                IngredientView(
                    ingredient: $viewModel.recipe.ingredients[ingredientNumber]
                ) {
                    viewModel.removeIngredient(ingredientNumber: ingredientNumber)
                }
            }
        }
    }
    
    @ViewBuilder
    private func images() -> some View {
        Section("Images") {
            PhotosPicker(selection: $viewModel.pickerItems, matching: .images) {
                Label("Add Images", systemImage: "plus")
            }
            .onChange(of: viewModel.pickerItems) {
                Task {
                    viewModel.recipe.images.removeAll()
                    
                    for item in viewModel.pickerItems {
                        if let loadedImage = try await item.loadTransferable(type: Image.self) {
                            if let imageText = loadedImage.base64 {
                                viewModel.recipe.images.append(imageText)
                            }
                        }
                    }
                }
            }
            
            if !viewModel.recipe.images.isEmpty {
                ImagesView(imagesStrings: viewModel.recipe.images, height: 200)
            }
        }
    }
    
    @ViewBuilder
    private func recipeSteps() -> some View {
        Section("Recipe") {
            Button {
                viewModel.addStep()
            } label: {
                Label("Add Step", systemImage: "plus")
            }
        }
        
        ForEach(viewModel.recipe.recipeSteps) { recipeStep in
            let stepNumber = viewModel.recipe.recipeSteps.firstIndex(of: recipeStep)!
            
            Section("Step \(stepNumber + 1)") {
                RecipeStepView(recipeStep: $viewModel.recipe.recipeSteps[stepNumber]) {
                    viewModel.removeStep(stepNumber: stepNumber)
                }
            }
        }
    }
}

#Preview {
    EditRecipeView(
        newRecipePresented: Binding(
            get: { return true },
            set: { _ in }
        )
    )
}
