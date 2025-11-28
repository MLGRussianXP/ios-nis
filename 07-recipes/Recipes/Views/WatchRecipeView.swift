//
//  WatchRecipeView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI

struct WatchRecipeView: View {
    let userId: String
    let recipe: Recipe
    
    var body: some View {
        VStack {
            Text("\(recipe.title)")
                .font(.title)
                .bold()
                .padding(.top, 50)
            
            RatingView(rating: Binding(
                get: { recipe.difficulty },
                set: { _ in }
            ))
            
            Text("by \(recipe.author)")
                .font(.body)
                .foregroundColor(.secondary)
            
            Form {
                details()
                ingredients()
                recipeSteps()
                images()
            }
        }
    }
    
    @ViewBuilder
    private func details() -> some View {
        Section("Details") {
            LabeledContent {
                Text("\(recipe.timeToCookString())")
                    .foregroundColor(.secondary)
            } label: {
                Text("Time")
            }
            
            LabeledContent {
                Text("\(recipe.type.capitalized)")
                    .foregroundColor(.secondary)
            } label: {
                Text("Type")
            }
        }
    }
    
    @ViewBuilder
    private func ingredients() -> some View {
        Section("Ingredients") {
            ForEach(recipe.ingredients) { ingredient in
                HStack {
                    Text("\(ingredient.title)")
                    
                    Spacer()
                    
                    Text("\(ingredient.quantity) \(Utils.foodQuantityType[ingredient.foodQuantityType].lowercased())")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func recipeSteps() -> some View {
        Section("Recipe") {
            ForEach(recipe.recipeSteps) { step in
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(step.text)")
                        
                        Spacer()
                        
                        Text("\(step.time) \(step.timeType)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func images() -> some View {
        if !recipe.images.isEmpty {
            Section("Images") {
                ImagesView(imagesStrings: recipe.images, height: 200)
            }
        }
    }
}
