import SwiftUI

/// A Member's avatar: their CDN image when `avatarURL` is set, otherwise a
/// placeholder circle showing their initials (or a person glyph when unnamed).
/// Reused by the profile editor and (later) the Legend's Members view.
struct AvatarView: View {
    let profile: MemberProfile
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let url = URL(string: profile.avatarURL), !profile.avatarURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    default:
                        ProgressView()
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        ZStack {
            Circle().fill(Color.secondary.opacity(0.25))
            if profile.initials.isEmpty {
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: size * 0.5))
            } else {
                Text(profile.initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
