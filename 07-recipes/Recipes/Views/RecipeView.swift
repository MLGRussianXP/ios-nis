//
//  RecipeView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RecipeView: View {
    @StateObject private var viewModel = RecipeViewModel()
    
    @FirestoreQuery private var users: [User]
    @FirestoreQuery private var recipes: [Recipe]
    @FirestoreQuery private var notes: [RecipeCloudNote]
    @FirestoreQuery private var likes: [Id]
    
    private let userId: String
    private let recipe: Recipe
    
    init(userId: String, recipe: Recipe) {
        self.userId = userId
        self.recipe = recipe
        
        self._users = FirestoreQuery(
            collectionPath: "users"
        )
        
        self._recipes = FirestoreQuery(
            collectionPath: "users/\(userId)/recipes"
        )
        
        self._notes = FirestoreQuery(
            collectionPath: "recipeCloudNotes"
        )
        
        self._likes = FirestoreQuery(
            collectionPath: "recipeCloudNotes/\(recipe.id)/likes"
        )
    }
    
    var body: some View {
        VStack {
            recipeDescription()
            
            if let note = recipe.getNote(notes: notes) {
                noteDetails(note: note)
            }
        }
        .contextMenu {
            buttons()
        }
        .sheet(isPresented: $viewModel.showingWatchRecipeView) {
            WatchRecipeView(userId: userId, recipe: recipe)
        }
        .sheet(isPresented: $viewModel.showingCreatorProfile) {
            ProfileView(userId: recipe.createdById)
        }
        .sheet(isPresented: $viewModel.showingEditRecipeView) {
            EditRecipeView(
                recipeOptional: recipe,
                newRecipePresented: $viewModel.showingEditRecipeView
            )
        }
        .alert("Remove \(recipe.title) from my recipes?", isPresented: $viewModel.showingRemoveFromMyRecipesAlert) {
            Button("OK") {
                Utils.db.collection("users").document(userId).collection("recipes").document(recipe.id).delete()
            }
            
            Button("Cancel") {}
        }
        .alert("Remove \(recipe.title) from Recipe Cloud?", isPresented: $viewModel.showingRemoveFromRecipeCloudAlert) {
            if let note = recipe.getNote(notes: notes) {
                if note.authorId == userId {
                    Button("OK") {
                        Utils.db.collection("recipeCloudNotes").document(recipe.id).delete()
                    }
                }
            }
            
            Button("Cancel") {}
        }
        .alert("Publish \(recipe.title)", isPresented: $viewModel.showingShareWithRecipeCloudAlert) {
            TextField("Comment", text: $viewModel.comment)
                .textFieldStyle(DefaultTextFieldStyle())
            
            Button("Create note") {
                let note = RecipeCloudNote(
                    id: recipe.id,
                    authorId: userId,
                    recipe: recipe,
                    comment: viewModel.comment,
                    createdAt: Date().timeIntervalSince1970
                )
                
                Utils.db.collection("recipeCloudNotes").document(note.id).setData(note.asDictionary())
            }
            
            Button("Cancel") {}
        }
    }
    
    @ViewBuilder
    private func recipeDescription() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(recipe.title)")
                    .font(.title)
                    .fontWeight(.semibold)
                    .onTapGesture {
                        viewModel.watchRecipe()
                    }
                
                Spacer()
                
                Text("\(recipe.type)")
            }
            
            LabeledContent {
                RatingView(rating: Binding(
                    get: { recipe.difficulty },
                    set: { _ in }
                ))
                
                Spacer()
            } label: {
                Text("Difficulty:")
                    .foregroundColor(.secondary)
            }
            
            LabeledContent {
                Text("\(recipe.author)")
                    .foregroundColor(.blue)
            } label: {
                Text("Author:")
                    .foregroundColor(.secondary)
            }
            
            LabeledContent {
                if let creator = Utils.getUserById(users: users, userId: userId) {
                    Text("\(creator.username)")
                        .foregroundColor(.blue)
                }
            } label: {
                Text("Created by:")
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            .onTapGesture {
                viewModel.watchCreatorProfile()
            }
            
            if !recipe.images.isEmpty {
                ImagesView(imagesStrings: recipe.images, height: 100)
            }
        }
    }
    
    @ViewBuilder
    private func noteButtons(note: RecipeCloudNote) -> some View {
        if note.authorId == userId {
            Button {
                viewModel.removeFromRecipeCloud()
            } label: {
                Label("Remove Note", systemImage: "trash")
            }
            .tint(.red)
        } else {
            if recipes.contains(where: { $0.id == note.recipe.id }) {
                Button {
                    viewModel.removeFromMyRecipes()
                } label: {
                    Label("Remove from My Recipes", systemImage: "trash")
                }
                .tint(.red)
            } else {
                Button {
                    note.saveRecipe()
                } label: {
                    Label("Add to My Recipes", systemImage: "plus")
                }
                .tint(.green)
            }
        }
    }
    
    @ViewBuilder
    private func noteDetails(note: RecipeCloudNote) -> some View {
        HStack {
            Text(note.comment)
            
            Spacer()
            
            ReactionView(
                likes: likes,
                onImageTap: {
                    viewModel.likeNote(note: note)
                },
                onTextTap: {}
            )
        }
    }
    
    @ViewBuilder
    private func buttons() -> some View {
        if viewModel.showEditButton(recipe: recipe, notes: notes) {
            Button {
                viewModel.editRecipe()
            } label: {
                Label(
                    recipe.getNote(notes: notes) == nil ? "Edit Recipe" : "Edit Note",
                    systemImage: "pencil"
                )
            }
            .tint(.pink)
        }
        
        if let note = recipe.getNote(notes: notes) {
            noteButtons(note: note)
        }
        
        if userId == recipe.createdById {
            Button {
                viewModel.removeFromMyRecipes()
            } label: {
                Label("Remove from My Recipes", systemImage: "trash")
            }
            .tint(.red)
            
            if let note = recipe.getNote(notes: notes) {
                if note.authorId == userId {
                    if recipe.createdById == userId {
                        Button {
                            viewModel.removeFromRecipeCloud()
                        } label: {
                            Label("Remove from Cloud", systemImage: "eraser")
                        }
                        .tint(.orange)
                    }
                }
            } else {
                if recipe.createdById == userId {
                    Button {
                        viewModel.shareWithRecipeCloud()
                    } label: {
                        Label("Publish to Cloud", systemImage: "square.and.arrow.up")
                    }
                    .tint(.orange)
                }
            }
        }
    }
}

#Preview {
    RecipeView(userId: "123", recipe: Preview.recipe)
}
