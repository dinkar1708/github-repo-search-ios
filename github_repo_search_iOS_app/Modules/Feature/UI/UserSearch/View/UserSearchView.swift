//
//  UserSearchView.swift
//  github_repo_search_iOS_app
//
//  Created for User Search feature (Feature 1.2)
//

import SwiftUI

struct UserSearchView: View {
    @State private var viewModel = UserSearchViewModel()
    @State private var placeholder = "Search GitHub users..."

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Compact header with search
                headerView

                // Content
                ZStack {
                    contentView
                    messageView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Users")
            .accessibilityLabel("GitHub Users Search")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            // Search bar
            AppSearchBar(
                text: $viewModel.searchText,
                textDidChanged: { _ in
                    viewModel.searchUsers()
                },
                placeholder: $placeholder
            )
            .padding(.horizontal)

            // Results count if available
            if !viewModel.users.isEmpty {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .accessibilityHidden(true)
                        Text("\(viewModel.users.count) users")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("\(viewModel.users.count) users found")
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, 12)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }

    private var messageView: some View {
        Group {
            if viewModel.isLoading && viewModel.users.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(.blue)
                        .accessibilityLabel("Loading")
                    Text("Searching users...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Searching users")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text("Oops!")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Retry button
                    Button(action: {
                        viewModel.refresh()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.top, 8)
                    .accessibilityLabel("Retry search")
                    .accessibilityHint("Double tap to retry the search")
                }
                .frame(maxHeight: .infinity)
                .padding()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error: \(error)")
            } else if viewModel.users.isEmpty && !viewModel.searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .accessibilityHidden(true)
                    Text("No Users Found")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Try a different username")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
                .padding()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No users found. Try a different username")
            } else if viewModel.users.isEmpty {
                VStack(spacing: 20) {
                    // Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }

                    VStack(spacing: 8) {
                        Text("Search GitHub Users")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Find millions of developers worldwide")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Search GitHub Users. Find millions of developers worldwide")
            }
        }
    }

    private var contentView: some View {
        List {
            ForEach(viewModel.users) { user in
                NavigationLink(destination: UserProfileView(username: user.login)) {
                    UserCell(user: user)
                }
                .onAppear {
                    if user.id == viewModel.users.last?.id {
                        viewModel.loadMoreUsers()
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("User: \(user.login)")
                .accessibilityHint("Double tap to view profile")
            }

            if viewModel.isLoading && !viewModel.users.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading more...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .background(Color.clear)
        .refreshable {
            viewModel.refresh()
        }
    }
}

struct UserCell: View {
    let user: User

    var body: some View {
        HStack(spacing: 16) {
            // Avatar with shadow
            AsyncImage(url: URL(string: user.avatarUrl)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(user.login)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let score = user.score {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", score))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    UserSearchView()
}
