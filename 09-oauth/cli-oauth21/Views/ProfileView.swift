import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 18) {
            header

            if let userProfile = viewModel.userProfile {
                profileCard(userProfile)
            }

            tokenExpiryCard

            VStack(spacing: 10) {
                Button {
                    Task { await viewModel.refreshToken() }
                } label: {
                    Label("refresh_token_action", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await viewModel.logout() }
                } label: {
                    Label("logout_action", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .task { await viewModel.loadProfileIfNeeded() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 4) {
                Text("profile_title")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("profile_subtitle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.bottom, 8)
    }

    private func profileCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            InfoRow(label: NSLocalizedString("profile_id", comment: ""), value: profile.id)
            InfoRow(label: NSLocalizedString("profile_username", comment: ""), value: profile.username)
            if let updatedAt = profile.updatedAt {
                InfoRow(
                    label: NSLocalizedString("profile_updated", comment: ""),
                    value: DateFormatter.localizedString(from: updatedAt, dateStyle: .medium, timeStyle: .short)
                )
            }
            if let email = profile.email {
                InfoRow(label: NSLocalizedString("userinfo_email", comment: ""), value: email)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private var tokenExpiryCard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text("token_expires_in")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text(viewModel.tokenRemainingText())
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .textSelection(.enabled)

            Spacer()
        }
    }
}
