import SwiftUI

struct AvatarView: View {
  let login: String
  let avatarURL: URL?
  let initials: String
  var size: CGFloat = 24

  var body: some View {
    Group {
      if let avatarURL {
        AsyncImage(url: avatarURL) { phase in
          switch phase {
          case let .success(image):
            image.resizable().scaledToFill()
          default:
            fallback
          }
        }
      } else {
        fallback
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
  }

  private var fallback: some View {
    ZStack {
      Palette.color(for: login)
      Text(initials)
        .font(.mono(size * 0.35))
        .foregroundStyle(.white)
    }
  }
}
