import SwiftUI
import Foundation
import TuckiiCore

struct SortSavesSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let collectionID: UUID

    private var collectionName: String {
        store.collection(collectionID)?.name ?? "Unsorted"
    }

    private var currentSort: SaveSort {
        store.collection(collectionID)?.saveSort ?? .newestFirst
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text("Sort saves")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Remembered for \"\(collectionName)\"")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                VStack(spacing: 0) {
                    ForEach(SaveSort.allCases, id: \.self) { sort in
                        Button {
                            store.setSaveSort(sort, for: collectionID)
                            dismiss()
                        } label: {
                            HStack {
                                Text(sort.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                if currentSort == sort {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.ink)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                        if sort != SaveSort.allCases.last {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
                )
            }
            .padding(20)
        }
        .presentationDetents([.medium])
    }
}

struct SortCollectionsSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text("Sort collections")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                VStack(spacing: 0) {
                    ForEach(CollectionSort.allCases, id: \.self) { sort in
                        Button {
                            store.setCollectionSort(sort)
                            dismiss()
                        } label: {
                            HStack {
                                Text(sort.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                if store.settings.collectionSort == sort {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.ink)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                        if sort != CollectionSort.allCases.last {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
                )
            }
            .padding(20)
        }
        .presentationDetents([.medium])
    }
}
