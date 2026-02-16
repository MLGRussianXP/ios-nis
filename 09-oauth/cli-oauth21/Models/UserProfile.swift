import Foundation

struct UserProfile: Identifiable {
    let id: String
    let username: String
    let email: String?
    let updatedAt: Date?

    init(id: String, username: String, email: String?, updatedAt: Date?) {
        self.id = id
        self.username = username
        self.email = email
        self.updatedAt = updatedAt
    }

    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["sub"] as? String else {
            return nil
        }
        let username = dictionary["name"] as? String ?? NSLocalizedString("na_value", comment: "")
        let email = dictionary["email"] as? String
        let updatedAt = UserProfile.parseUpdatedAt(dictionary["updated_at"])

        self.init(id: id, username: username, email: email, updatedAt: updatedAt)
    }

    private static func parseUpdatedAt(_ value: Any?) -> Date? {
        if let timestamp = value as? Int {
            return Date(timeIntervalSince1970: TimeInterval(timestamp))
        }
        if let timestamp = value as? Double {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }
}
