import SwiftUI
import Foundation
import TuckiiCore

struct CollectionShareSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let collectionID: UUID

    private var shareText: String {
        let name = store.collection(collectionID)?.name ?? "Collection"
        let bookmarks = store.sortedBookmarks(in: collectionID)
        var lines = ["Tuckii — \(name) (\(bookmarks.count) saves)", ""]
        for bookmark in bookmarks {
            if let url = bookmark.url {
                lines.append("• \(bookmark.title) — \(url.absoluteString)")
            } else {
                lines.append("• \(bookmark.title)")
            }
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Share Collection")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 36, height: 36)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
                Text(shareText)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                    .lineLimit(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.card)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink.opacity(0.4), lineWidth: 2))
                    )
                ShareLink(item: shareText) {
                    Text("Share as text")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.ctaYellow))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2.5))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
    }
}
