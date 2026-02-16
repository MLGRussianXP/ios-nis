import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var currentStep = 0
    @Published var isLoading = false
    @Published var tokenExpiresAt: Date?
    @Published var now = Date()
    @Published var activeAlert: AppAlert?

    @Published private(set) var isAuthenticated = false
    @Published private(set) var userProfile: UserProfile?

    private let oauthClient: OAuth21Client
    private let config: AppConfig

    init(oauthClient: OAuth21Client = OAuth21Client(), config: AppConfig = .shared) {
        self.oauthClient = oauthClient
        self.config = config
    }

    func updateNow(_ date: Date) {
        now = date
    }

    func tokenRemainingText() -> String {
        guard let expiresAt = tokenExpiresAt else {
            return NSLocalizedString("na_value", comment: "")
        }
        let remaining = max(0, Int(expiresAt.timeIntervalSince(now)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let restMinutes = minutes % 60
            return String(format: NSLocalizedString("token_remaining_hours_minutes", comment: ""), hours, restMinutes)
        }
        return String(format: NSLocalizedString("token_remaining_minutes_seconds", comment: ""), minutes, seconds)
    }

    func checkSessionOnLaunch() async {
        isLoading = true
        defer { isLoading = false }

        if let userInfo = await oauthClient.checkSession() {
            isAuthenticated = true
            userProfile = UserProfile(from: userInfo)
            currentStep = 3
            tokenExpiresAt = oauthClient.accessTokenExpiryDate()
            return
        }

        isAuthenticated = false
        userProfile = nil

        let hasClientId = UserDefaults.standard.string(forKey: config.clientIdStorageKey) != nil
        currentStep = hasClientId ? 2 : 0
    }

    func registerClient() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await oauthClient.registerClient(clientName: config.clientName)
            currentStep = 1
        } catch {
            presentError(error)
        }
    }

    func registerUser() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await oauthClient.registerUser(username: username, password: password)
            currentStep = 2
        } catch {
            presentError(error)
        }
    }

    func authenticate() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await oauthClient.authenticate(username: username, password: password)
            isAuthenticated = true
            currentStep = 3
            presentSuccess(NSLocalizedString("alert_logged_in", comment: ""))
            await loadProfileIfNeeded()
        } catch {
            presentError(error)
        }
    }

    func loadProfileIfNeeded() async {
        if userProfile == nil {
            await fetchUserProfile()
        } else {
            tokenExpiresAt = oauthClient.accessTokenExpiryDate()
        }
    }

    func refreshToken() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await oauthClient.refreshTokens()
            await fetchUserProfile()
            presentSuccess(NSLocalizedString("alert_token_refreshed", comment: ""))
        } catch {
            presentError(error)
        }
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }

        await oauthClient.logout()
        isAuthenticated = false
        userProfile = nil
        tokenExpiresAt = nil
        currentStep = 2
    }

    func resetFlow() async {
        isLoading = true
        defer { isLoading = false }

        await oauthClient.reset()
        username = ""
        password = ""
        isAuthenticated = false
        userProfile = nil
        tokenExpiresAt = nil
        currentStep = 0
    }

    private func fetchUserProfile() async {
        do {
            let userInfo = try await oauthClient.fetchUserInfo()
            userProfile = UserProfile(from: userInfo)
            isAuthenticated = true
            tokenExpiresAt = oauthClient.accessTokenExpiryDate()
        } catch {
            presentError(error)
        }
    }

    private func presentError(_ error: Error) {
        activeAlert = AppAlert(
            title: NSLocalizedString("alert_error_title", comment: ""),
            message: error.localizedDescription
        )
    }

    private func presentSuccess(_ message: String) {
        activeAlert = AppAlert(
            title: NSLocalizedString("alert_success_title", comment: ""),
            message: message
        )
    }
}

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
