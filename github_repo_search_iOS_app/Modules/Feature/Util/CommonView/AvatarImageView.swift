//
//  AvatarImageView.swift
//  github_repo_search_iOS_app
//
//  Reusable avatar image component with AsyncImage loading
//  Eliminates duplicate AsyncImage patterns across the app
//

import SwiftUI

/**
 Reusable avatar image view with async loading, fallback, and customization
 Consolidates 5+ duplicate AsyncImage patterns into single component
 */
struct AvatarImageView: View {
    let url: String
    var size: CGFloat = 60
    var showBorder: Bool = true
    var borderColor: Color = .white
    var borderWidth: CGFloat = 2
    var shadowRadius: CGFloat = 3

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: size, height: size)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        showBorder ? Circle().stroke(borderColor, lineWidth: borderWidth) : nil
                    )
                    .shadow(radius: shadowRadius)
            case .failure:
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
    }
}

// MARK: - Preset Sizes
extension AvatarImageView {
    /// Small avatar (40x40)
    static func small(url: String, showBorder: Bool = true) -> AvatarImageView {
        AvatarImageView(url: url, size: 40, showBorder: showBorder)
    }

    /// Medium avatar (60x60) - Default
    static func medium(url: String, showBorder: Bool = true) -> AvatarImageView {
        AvatarImageView(url: url, size: 60, showBorder: showBorder)
    }

    /// Large avatar (120x120)
    static func large(url: String, showBorder: Bool = true) -> AvatarImageView {
        AvatarImageView(url: url, size: 120, showBorder: showBorder)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AvatarImageView.small(url: "https://avatars.githubusercontent.com/u/1?v=4")
        AvatarImageView.medium(url: "https://avatars.githubusercontent.com/u/1?v=4")
        AvatarImageView.large(url: "https://avatars.githubusercontent.com/u/1?v=4")
    }
    .padding()
}
