import Foundation
import CryptoKit

final class OAuth21Client {
    private let config: AppConfig
    private let tokenManager: TokenManager
    private let session: URLSession

    private var clientId: String?

    init(config: AppConfig = .shared, tokenManager: TokenManager = .shared, session: URLSession = .shared) {
        self.config = config
        self.tokenManager = tokenManager
        self.session = session
    }

    func registerClient(clientName: String) async throws -> String {
        let url = config.baseURL.appendingPathComponent("client-registration")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_name": clientName,
            "redirect_uris": [config.redirectURI],
            "client_type": "public"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, httpResponse) = try await performRequest(request)

        guard httpResponse.statusCode == 200 else {
            throw OAuthError.httpStatus(httpResponse.statusCode)
        }

        let clientInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        clientId = clientInfo?["client_id"] as? String

        guard let clientId else {
            throw OAuthError.serverError("Client ID not found in response")
        }

        UserDefaults.standard.set(clientId, forKey: config.clientIdStorageKey)
        return clientId
    }

    func registerUser(username: String, password: String) async throws {
        let url = config.baseURL.appendingPathComponent("user/register")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "username": username,
            "password": password
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, httpResponse) = try await performRequest(request)

        guard httpResponse.statusCode == 201 else {
            throw OAuthError.httpStatus(httpResponse.statusCode)
        }
    }

    func authenticate(username: String, password: String) async throws -> [String: Any] {
        if clientId == nil {
            clientId = UserDefaults.standard.string(forKey: config.clientIdStorageKey)
        }

        guard let clientId else {
            throw OAuthError.clientNotRegistered
        }

        let (codeVerifier, codeChallenge) = generatePKCE()

        let authResponse = try await requestAuthorizationCode(
            username: username,
            password: password,
            clientId: clientId,
            codeChallenge: codeChallenge
        )

        guard let authCode = authResponse["authorization_code"] as? String else {
            throw OAuthError.invalidResponse
        }

        let tokens = try await exchangeCodeForTokens(
            authCode: authCode,
            clientId: clientId,
            codeVerifier: codeVerifier
        )

        tokenManager.saveTokens(
            accessToken: tokens["access_token"] as? String,
            refreshToken: tokens["refresh_token"] as? String
        )

        return tokens
    }

    func refreshTokens() async throws -> [String: Any] {
        if clientId == nil {
            clientId = UserDefaults.standard.string(forKey: config.clientIdStorageKey)
        }

        guard let clientId else {
            throw OAuthError.clientNotRegistered
        }

        guard let refreshToken = tokenManager.refreshToken() else {
            throw OAuthError.notAuthenticated
        }

        let tokens = try await refreshAccessToken(clientId: clientId, refreshToken: refreshToken)

        tokenManager.saveTokens(
            accessToken: tokens["access_token"] as? String,
            refreshToken: tokens["refresh_token"] as? String
        )

        return tokens
    }

    func accessTokenPayload() -> [String: Any]? {
        guard let token = tokenManager.accessToken() else {
            return nil
        }

        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        let payloadPart = String(parts[1])
        guard let payloadData = base64URLDecode(payloadPart) else { return nil }

        return (try? JSONSerialization.jsonObject(with: payloadData)) as? [String: Any]
    }

    func accessTokenExpiryDate() -> Date? {
        guard let payload = accessTokenPayload() else { return nil }
        if let exp = payload["exp"] as? Double {
            return Date(timeIntervalSince1970: exp)
        }
        if let exp = payload["exp"] as? Int {
            return Date(timeIntervalSince1970: TimeInterval(exp))
        }
        return nil
    }

    func fetchUserInfo(allowRefresh: Bool = true) async throws -> [String: Any] {
        let url = config.baseURL.appendingPathComponent("userinfo")

        func loadAccessToken() throws -> String {
            guard let token = tokenManager.accessToken() else {
                throw OAuthError.notAuthenticated
            }
            return token
        }

        func performUserInfoRequest(accessToken: String) async throws -> (Data, HTTPURLResponse) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            return try await performRequest(request)
        }

        let accessToken = try loadAccessToken()
        var (data, httpResponse) = try await performUserInfoRequest(accessToken: accessToken)

        if httpResponse.statusCode == 401 {
            guard allowRefresh else {
                throw OAuthError.notAuthenticated
            }

            guard let refreshToken = tokenManager.refreshToken() else {
                throw OAuthError.notAuthenticated
            }

            if clientId == nil {
                clientId = UserDefaults.standard.string(forKey: config.clientIdStorageKey)
            }

            guard let clientId else {
                throw OAuthError.clientNotRegistered
            }

            let tokens = try await refreshAccessToken(clientId: clientId, refreshToken: refreshToken)

            tokenManager.saveTokens(
                accessToken: tokens["access_token"] as? String,
                refreshToken: tokens["refresh_token"] as? String
            )

            let updatedAccessToken = try loadAccessToken()
            (data, httpResponse) = try await performUserInfoRequest(accessToken: updatedAccessToken)
        }

        guard httpResponse.statusCode == 200 else {
            throw OAuthError.httpStatus(httpResponse.statusCode)
        }

        guard let userInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OAuthError.serverError("Invalid user info response format")
        }

        return userInfo
    }

    func checkSession() async -> [String: Any]? {
        do {
            return try await fetchUserInfo(allowRefresh: false)
        } catch {
            return nil
        }
    }

    func logout() async {
        if clientId == nil {
            clientId = UserDefaults.standard.string(forKey: config.clientIdStorageKey)
        }

        let refreshToken = tokenManager.refreshToken()
        let accessToken = tokenManager.accessToken()

        if let token = refreshToken, let clientId {
            try? await revokeToken(token: token, tokenTypeHint: "refresh_token", clientId: clientId)
        } else if let token = accessToken, let clientId {
            try? await revokeToken(token: token, tokenTypeHint: "access_token", clientId: clientId)
        }

        tokenManager.clearTokens()
    }

    func reset() async {
        await logout()
        clientId = nil
        UserDefaults.standard.removeObject(forKey: config.clientIdStorageKey)
    }

    private func generatePKCE() -> (verifier: String, challenge: String) {
        let verifier = generateRandomString(length: 43)
        let challenge = generateCodeChallenge(verifier: verifier)
        return (verifier, challenge)
    }

    private func generateCodeChallenge(verifier: String) -> String {
        let verifierData = Data(verifier.utf8)
        let hash = Data(SHA256.hash(data: verifierData))
        return base64URLEncode(hash)
    }

    private func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    private func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padding = 4 - (base64.count % 4)
        if padding < 4 {
            base64 += String(repeating: "=", count: padding)
        }

        return Data(base64Encoded: base64)
    }

    private func requestAuthorizationCode(
        username: String,
        password: String,
        clientId: String,
        codeChallenge: String
    ) async throws -> [String: Any] {
        let url = config.baseURL.appendingPathComponent("oauth/authorize")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "username": username,
            "password": password,
            "client_id": clientId,
            "redirect_uri": config.redirectURI,
            "code_challenge": codeChallenge,
            "code_challenge_method": "S256",
            "scope": config.scope
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, httpResponse) = try await performRequest(request)

        guard httpResponse.statusCode == 200 else {
            throw OAuthError.httpStatus(httpResponse.statusCode)
        }

        guard let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OAuthError.serverError("Invalid authorization response format")
        }

        return responseData
    }

    private func exchangeCodeForTokens(
        authCode: String,
        clientId: String,
        codeVerifier: String
    ) async throws -> [String: Any] {
        let url = config.baseURL.appendingPathComponent("oauth/token")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "grant_type": "authorization_code",
            "code": authCode,
            "client_id": clientId,
            "redirect_uri": config.redirectURI,
            "code_verifier": codeVerifier
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, httpResponse) = try await performRequest(request)

        guard httpResponse.statusCode == 200 else {
            throw OAuthError.httpStatus(httpResponse.statusCode)
        }

        guard let tokens = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OAuthError.serverError("Invalid token response format")
        }

        return tokens
    }

    private func refreshAccessToken(clientId: String, refreshToken: String) async throws -> [String: Any] {
        let url = config.baseURL.appendingPathComponent("oauth/token")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, httpResponse) = try await performRequest(request)

        guard httpResponse.statusCode == 200 else {
            throw OAuthError.httpStatus(httpResponse.statusCode)
        }

        guard let tokens = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OAuthError.serverError("Invalid refresh token response format")
        }

        return tokens
    }

    private func revokeToken(token: String, tokenTypeHint: String, clientId: String) async throws {
        let url = config.baseURL.appendingPathComponent("oauth/revoke")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "token": token,
            "token_type_hint": tokenTypeHint,
            "client_id": clientId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, httpResponse) = try await performRequest(request)

        guard httpResponse.statusCode == 200 else {
            throw OAuthError.httpStatus(httpResponse.statusCode)
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OAuthError.invalidResponse
            }
            return (data, httpResponse)
        } catch let urlError as URLError {
            throw OAuthError.network(urlError)
        } catch {
            throw error
        }
    }
}

enum OAuthError: LocalizedError {
    case invalidURL
    case clientNotRegistered
    case serverError(String)
    case invalidResponse
    case notAuthenticated
    case httpStatus(Int)
    case network(URLError)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error_invalid_url", comment: "")
        case .clientNotRegistered:
            return NSLocalizedString("error_client_not_registered", comment: "")
        case .serverError:
            return NSLocalizedString("error_server_generic", comment: "")
        case .invalidResponse:
            return NSLocalizedString("error_invalid_response", comment: "")
        case .notAuthenticated:
            return NSLocalizedString("error_not_authenticated", comment: "")
        case .httpStatus(let code):
            switch code {
            case 400:
                return NSLocalizedString("error_400", comment: "")
            case 401:
                return NSLocalizedString("error_401", comment: "")
            case 429:
                return NSLocalizedString("error_429", comment: "")
            default:
                return NSLocalizedString("error_server_generic", comment: "")
            }
        case .network:
            return NSLocalizedString("error_network", comment: "")
        }
    }
}
