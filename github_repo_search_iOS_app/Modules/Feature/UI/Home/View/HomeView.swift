//
//  HomeView.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//

import SwiftUI

/**
 Home view - display data for home screen with modern iOS design
 */
struct HomeView: View {
    @State private var homeViewModel = HomeViewModel()

    init() {
        // customize table view for modern appearance
        UITableViewCell.appearance().backgroundColor = .clear
        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().separatorStyle = .none
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Compact header with search
                headerView

                // Content
                ZStack {
                    SearchResultView
                    MessageView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Repositories")
            .accessibilityLabel("GitHub Repositories Search")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            // Search bar
            AppSearchBar(
                text: $homeViewModel.searchText,
                textDidChanged: { _ in
                    // Text is already updated via binding, no need to set again
                    // ViewModel's throttle will handle the API calls
                },
                placeholder: .constant("Search GitHub repositories...")
            )
            .padding(.horizontal)

            // Results count if available
            if !homeViewModel.searchItems.isEmpty {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .accessibilityHidden(true)
                        Text("\(homeViewModel.searchItems.count) repositories")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("\(homeViewModel.searchItems.count) repositories found")
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

    private var MessageView: some View {
        // display messages
        Group {
            switch homeViewModel.messageState {
            case .loading:
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(.blue)
                        .accessibilityLabel("Loading")
                    Text("Searching repositories...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Searching repositories")
            case .error(let error):
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
                        Task {
                            await homeViewModel.refresh()
                        }
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
            case .emptySearchResult:
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .accessibilityHidden(true)
                    Text("No Repositories Found")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Try a different search term")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
                .padding()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No repositories found. Try a different search term")
            case .loaded:
                if homeViewModel.searchItems.isEmpty {
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

                            Image(systemName: "book.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }

                        VStack(spacing: 8) {
                            Text("Search Repositories")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Find millions of open source projects")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Search Repositories. Find millions of open source projects")
                } else {
                    EmptyView()
                }
            }
        }
    }

    private var SearchResultView: some View {
        // show the search result with modern card design
        List {
            ForEach(homeViewModel.searchItems, id: \.self) { searchItem in
                SearchItemCell(searchItem: searchItem)
                    .onAppear {
                        homeViewModel.searchForNextPage(currentItem: searchItem)
                    }
                    .background(
                        NavigationLink(
                            destination: SearchItemDetailsView(searchItem: searchItem),
                            label: { EmptyView() }
                        )
                        .opacity(0)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Repository: \(searchItem.name), by \(searchItem.owner.login), \(searchItem.stargazersCount) stars")
                    .accessibilityHint("Double tap to view details")
            }

            // Loading indicator for pagination
            if homeViewModel.isSearchingCurrentPage && homeViewModel.searchItems.count > 0 {
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
            await homeViewModel.refresh()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
