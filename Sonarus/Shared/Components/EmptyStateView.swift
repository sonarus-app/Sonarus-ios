import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .padding(20)
                .background(AppTheme.accent.opacity(0.12), in: Circle())

            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
