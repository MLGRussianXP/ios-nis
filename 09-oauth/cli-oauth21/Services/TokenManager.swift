import Foundation

final class TokenManager {
    static let shared = TokenManager()

    private let keychain: KeychainHelper
    private let config: AppConfig

    init(keychain: KeychainHelper = .shared, config: AppConfig = .shared) {
        self.keychain = keychain
        self.config = config
    }

    func accessToken() -> String? {
        keychain.load(for: config.accessTokenKey)
    }

    func refreshToken() -> String? {
        keychain.load(for: config.refreshTokenKey)
    }

    func saveTokens(accessToken: String?, refreshToken: String?) {
        if let accessToken {
            keychain.save(accessToken, for: config.accessTokenKey)
        }
        if let refreshToken {
            keychain.save(refreshToken, for: config.refreshTokenKey)
        }
    }

    func clearTokens() {
        keychain.delete(for: config.accessTokenKey)
        keychain.delete(for: config.refreshTokenKey)
    }
}
