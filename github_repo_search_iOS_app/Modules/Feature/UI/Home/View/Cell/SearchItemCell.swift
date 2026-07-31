//
//  SearchItemCell.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//

import SwiftUI

/**
 Search item cell to show single item ui with modern design
 */
struct SearchItemCell: View {
    let searchItem: SearchItem

    var body : some View {
        HStack(spacing: 16) {
            // Owner Avatar
            AsyncImage(url: URL(string: searchItem.owner.avatarURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 3)
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }

            // Repository Info
            VStack(alignment: .leading, spacing: 8) {
                // Repository name
                Text(searchItem.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Owner name
                Text(searchItem.owner.login)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Description
                if let description = searchItem.itemDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Stats row
                HStack(spacing: 16) {
                    // Language
                    if let language = searchItem.language {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.languageColor(for: language))
                                .frame(width: 8, height: 8)
                            Text(language)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Stars
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(searchItem.stargazersCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Forks
                    HStack(spacing: 4) {
                        Image(systemName: "tuningfork")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(searchItem.forksCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
    }

    // Helper function to get language color
    // Removed: languageColor() now centralized in Color+Extensions
}

// Legacy support for name-only cell
extension SearchItemCell {
    init(name: String) {
        // Create a minimal SearchItem for preview/legacy support
        let owner = Owner(
            login: "user",
            id: 0,
            nodeID: "",
            avatarURL: "",
            gravatarID: "",
            url: "",
            htmlURL: "",
            followersURL: "",
            followingURL: "",
            gistsURL: "",
            starredURL: "",
            subscriptionsURL: "",
            organizationsURL: "",
            reposURL: "",
            eventsURL: "",
            receivedEventsURL: "",
            type: "User",
            siteAdmin: false
        )

        let item = SearchItem(
            id: 0,
            nodeID: "",
            name: name,
            fullName: "user/\(name)",
            itemPrivate: false,
            owner: owner,
            htmlURL: "",
            itemDescription: nil,
            fork: false,
            url: "",
            forksURL: "",
            keysURL: "",
            collaboratorsURL: "",
            teamsURL: "",
            hooksURL: "",
            issueEventsURL: "",
            eventsURL: "",
            assigneesURL: "",
            branchesURL: "",
            tagsURL: "",
            blobsURL: "",
            gitTagsURL: "",
            gitRefsURL: "",
            treesURL: "",
            statusesURL: "",
            languagesURL: "",
            stargazersURL: "",
            contributorsURL: "",
            subscribersURL: "",
            subscriptionURL: "",
            commitsURL: "",
            gitCommitsURL: "",
            commentsURL: "",
            issueCommentURL: "",
            contentsURL: "",
            compareURL: "",
            mergesURL: "",
            archiveURL: "",
            downloadsURL: "",
            issuesURL: "",
            pullsURL: "",
            milestonesURL: "",
            notificationsURL: "",
            labelsURL: "",
            releasesURL: "",
            deploymentsURL: "",
            createdAt: nil,
            updatedAt: nil,
            pushedAt: nil,
            gitURL: "",
            sshURL: "",
            cloneURL: "",
            svnURL: "",
            homepage: nil,
            size: 0,
            stargazersCount: 0,
            watchersCount: 0,
            language: nil,
            hasIssues: false,
            hasProjects: false,
            hasDownloads: false,
            hasWiki: false,
            hasPages: false,
            forksCount: 0,
            mirrorURL: nil,
            archived: false,
            disabled: false,
            openIssuesCount: 0,
            license: nil,
            forks: 0,
            openIssues: 0,
            watchers: 0,
            defaultBranch: "main",
            score: 0
        )

        self.searchItem = item
    }
}

struct SearchItemCell_Previews: PreviewProvider {
    static var previews: some View {
        SearchItemCell(name: "swift-xcode-playground-support")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
