//
//  LoginViewModel.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import Foundation
import FirebaseAuth
internal import Combine

class LoginViewModel : ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    
    func login() {
        guard validate() else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error != nil {
                self.errorMessage = "Error logging in"
            }
        }
    }
    
    func validate() -> Bool {
        errorMessage = ""
        
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter email and password"
            return false
        }
        
        return true
    }
}
