//
//  ProfileView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    @FirestoreQuery private var users: [User]
    @FirestoreQuery private var recipes: [Recipe]
    @FirestoreQuery private var notes: [RecipeCloudNote]
    
    private let userId: String
    
    var currentUserProfile: Bool {
        return userId == Auth.auth().currentUser?.uid
    }
    
    init(userId: String) {
        self.userId = userId
        
        self._users = FirestoreQuery(
            collectionPath: "users"
        )
        
        self._recipes = FirestoreQuery(
            collectionPath: "users/\(userId)/recipes"
        )
        
        self._notes = FirestoreQuery(
            collectionPath: "recipeCloudNotes"
        )
    }
    
    var body: some View {
        VStack {
            if let user = viewModel.user {
                profile(user: user)
                    .navigationTitle(user.username)
            } else {
                VStack {
                    if currentUserProfile {
                        Button("Log Out") {
                            do {
                                try Auth.auth().signOut()
                            } catch {}
                        }
                        .tint(.pink)
                        .padding(.top)
                        
                        Button("Remove Profile") {
                            guard let currentUser = Auth.auth().currentUser else {
                                return
                            }
                            
                            currentUser.delete()
                            do {
                                try Auth.auth().signOut()
                            } catch {}
                            Utils.db.collection("users").document(userId).delete()
                        }
                    }
                }
                .navigationTitle("Profile")
            }
        }
        .onAppear {
            viewModel.fetchUser(userId: userId)
        }
    }
    
    @ViewBuilder
    private func profile(user: User) -> some View {
        VStack(alignment: .leading) {
            Image(systemName: "person.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(.green)
                .padding()
            
            Text("Username: \(user.username)")
                .padding()
            
            Text("Email: \(user.email)")
                .padding()
            
            Text("Member since: \(Date(timeIntervalSince1970: user.joined).formatted(date: .abbreviated, time: .shortened))")
                .padding()
            
            HStack {
                Button("Log Out") {
                    do {
                        try Auth.auth().signOut()
                    } catch {}
                }
                .tint(.pink)
                .padding()
                
                Spacer()
                
                Button("Remove Profile") {
                    guard let currentUser = Auth.auth().currentUser else {
                        return
                    }
                    
                    currentUser.delete()
                    do {
                        try Auth.auth().signOut()
                    } catch {}
                    Utils.db.collection("users").document(userId).delete()
                }
                .tint(.red)
                .padding()
            }
            
            Form {
                ForEach(posts) { post in
                    RecipeView(userId: userId, recipe: post)
                }
            }
            
            Spacer()
        }
    }
    
    private var posts: [Recipe] {
        var result: [Recipe] = []
        
        recipes.forEach { recipe in
            if notes.contains(where: { $0.recipe.id == recipe.id && recipe.createdById.lowercased() == userId.lowercased() }) {
                result.append(recipe)
            }
        }
        
        return result
    }
}

#Preview {
    ProfileView(userId: "123")
}
