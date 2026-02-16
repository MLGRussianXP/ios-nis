import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AuthViewModel()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("oauth_flow_title")
                    .font(.headline)
                    .foregroundColor(.secondary)

                if viewModel.isAuthenticated {
                    ProfileView(viewModel: viewModel)
                } else {
                    LoginView(viewModel: viewModel)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("navigation_title")
            .overlay(loadingOverlay)
            .task { await viewModel.checkSessionOnLaunch() }
            .onReceive(timer) { viewModel.updateNow($0) }
            .alert(item: $viewModel.activeAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("alert_ok"))
                )
            }
        }
    }

    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("loading_title")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                }
            }
        }
    }
}
