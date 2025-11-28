//
//  LoginView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                HeaderView(
                    title: "Your Recipe Book",
                    subtitle: "All recipes in one place",
                    angle: 15,
                    background: Color(UIColor.systemIndigo)
                )
                
                Form {
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Email Address", text: $viewModel.email)
                        .textFieldStyle(DefaultTextFieldStyle())
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(DefaultTextFieldStyle())
                    
                    Button("Login") {
                        viewModel.login()
                    }
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    LoginView()
}
