import Foundation

struct AppConfig {
    static let shared = AppConfig()

    let baseURL: URL
    let redirectURI: String
    let clientName: String
    let scope: String
    let clientIdStorageKey: String
    let accessTokenKey: String
    let refreshTokenKey: String

    private init() {
        let values = AppConfigLoader.load()
        baseURL = values.baseURL
        redirectURI = values.redirectURI
        clientName = values.clientName
        scope = values.scope
        clientIdStorageKey = values.clientIdStorageKey
        accessTokenKey = values.accessTokenKey
        refreshTokenKey = values.refreshTokenKey
    }
}

private struct AppConfigValues {
    let baseURL: URL
    let redirectURI: String
    let clientName: String
    let scope: String
    let clientIdStorageKey: String
    let accessTokenKey: String
    let refreshTokenKey: String
}

private enum AppConfigKey {
    static let baseURL = "BaseURL"
    static let redirectURI = "RedirectURI"
    static let clientName = "ClientName"
    static let scope = "Scope"
    static let clientIdStorageKey = "ClientIdStorageKey"
    static let accessTokenKey = "AccessTokenKey"
    static let refreshTokenKey = "RefreshTokenKey"
}

private enum AppConfigLoader {
    static func load() -> AppConfigValues {
        guard let url = Bundle.main.url(forResource: "OAuthConfig", withExtension: "plist") else {
            fatalError("Missing OAuthConfig.plist")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Unable to read OAuthConfig.plist")
        }
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            fatalError("Invalid OAuthConfig.plist")
        }
        guard let baseURLString = plist[AppConfigKey.baseURL] as? String,
              let baseURL = URL(string: baseURLString) else {
            fatalError("Invalid BaseURL in OAuthConfig.plist")
        }
        guard let redirectURI = plist[AppConfigKey.redirectURI] as? String else {
            fatalError("Invalid RedirectURI in OAuthConfig.plist")
        }
        guard let clientName = plist[AppConfigKey.clientName] as? String else {
            fatalError("Invalid ClientName in OAuthConfig.plist")
        }
        guard let scope = plist[AppConfigKey.scope] as? String else {
            fatalError("Invalid Scope in OAuthConfig.plist")
        }
        guard let clientIdStorageKey = plist[AppConfigKey.clientIdStorageKey] as? String else {
            fatalError("Invalid ClientIdStorageKey in OAuthConfig.plist")
        }
        guard let accessTokenKey = plist[AppConfigKey.accessTokenKey] as? String else {
            fatalError("Invalid AccessTokenKey in OAuthConfig.plist")
        }
        guard let refreshTokenKey = plist[AppConfigKey.refreshTokenKey] as? String else {
            fatalError("Invalid RefreshTokenKey in OAuthConfig.plist")
        }

        return AppConfigValues(
            baseURL: baseURL,
            redirectURI: redirectURI,
            clientName: clientName,
            scope: scope,
            clientIdStorageKey: clientIdStorageKey,
            accessTokenKey: accessTokenKey,
            refreshTokenKey: refreshTokenKey
        )
    }
}
