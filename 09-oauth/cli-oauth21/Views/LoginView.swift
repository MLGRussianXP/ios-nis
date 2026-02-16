import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            credentialsSection

            if viewModel.currentStep < 1 {
                clientRegistrationSection
            } else if viewModel.currentStep == 1 {
                userRegistrationSection
            } else if viewModel.currentStep >= 2 {
                authenticationSection
            }

            if viewModel.currentStep > 0 {
                resetSection
            }
        }
    }

    private var credentialsSection: some View {
        VStack(spacing: 16) {
            Text("step1_title")
                .font(.headline)
                .foregroundColor(.primary)

            TextField("username_placeholder", text: $viewModel.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disabled(viewModel.isLoading)

            SecureField("password_placeholder", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(viewModel.isLoading)
        }
    }

    private var clientRegistrationSection: some View {
        VStack(spacing: 16) {
            Text("step2_title")
                .font(.headline)
                .foregroundColor(.primary)

            Text("step2_subtitle")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("step2_action") {
                Task { await viewModel.registerClient() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.username.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }

    private var userRegistrationSection: some View {
        VStack(spacing: 16) {
            Text("step3_title")
                .font(.headline)
                .foregroundColor(.primary)

            Text("step3_subtitle")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("step3_action") {
                Task { await viewModel.registerUser() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.username.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }

    private var authenticationSection: some View {
        VStack(spacing: 16) {
            Text(viewModel.currentStep == 2 ? "step4_title" : "reauth_title")
                .font(.headline)
                .foregroundColor(.primary)

            Text(viewModel.currentStep == 2 ? "step4_subtitle" : "reauth_subtitle")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(viewModel.currentStep == 2 ? "step4_action" : "reauth_action") {
                Task { await viewModel.authenticate() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.username.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }

    private var resetSection: some View {
        VStack(spacing: 8) {
            Button("reset_action") {
                Task { await viewModel.resetFlow() }
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
            .font(.caption)

            Text("reset_caption")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
