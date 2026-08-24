//
//  SamplesHelperViews.swift
//  github_repo_search_iOS_app
//
//  Shared helper views for all sample examples
//

import SwiftUI

// MARK: - Example Card

struct ExampleCard<Content: View>: View {
    let title: String
    let description: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            content()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Code Example

struct CodeExample: View {
    let code: String

    init(_ code: String) {
        self.code = code
    }

    var body: some View {
        Text(code)
            .font(.system(size: 11, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.05))
            .cornerRadius(4)
    }
}
