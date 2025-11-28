//
//  RegisterViewModel.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
internal import Combine

class RegisterViewModel : ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    
    private let db = Firestore.firestore()
    
    func register() -> Bool {
        guard validate() else { return false }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let userId = result?.user.uid else {
                self?.errorMessage = "Error creating user"
                return
            }
            
            self?.insertRecord(id: userId)
        }
        
        return errorMessage.isEmpty
    }
    
    private func insertRecord(id: String) {
        let user = User(
            id: id,
            username: username,
            email: email,
            joined: Date().timeIntervalSince1970
        )
        
        db.collection("users").document(id).setData(user.asDictionary())
    }
    
    func validate() -> Bool {
        errorMessage = ""
        
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please fill in all fields"
            return false
        }
        
        guard username.count <= 15 else {
            errorMessage = "Username must be less than 15 characters"
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters long"
            return false
        }
        
        return true
    }
}
