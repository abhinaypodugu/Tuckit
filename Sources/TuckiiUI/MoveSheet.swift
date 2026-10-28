import SwiftUI
import Foundation
import TuckiiCore

struct MoveSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    private let bookmarkIDs: [UUID]
    private let onMoved: (() -> Void)?

    @State private var selectedID: UUID?

    init(bookmarkID: UUID, onMoved: (() -> Void)? = nil) {
        self.bookmarkIDs = [bookmarkID]
        self.onMoved = onMoved
    }

    init(bookmarkIDs: [UUID], onMoved: (() -> Void)? = nil) {
        self.bookmarkIDs = bookmarkIDs
        self.onMoved = onMoved
    }

    private var currentCollectionIDs: Set<UUID> {
        Set(bookmarkIDs.compactMap { store.bookmark($0)?.collectionID })
    }

    private var options: [TuckiiCollection] {
        if bookmarkIDs.count == 1 {
            return store.collections.filter { !currentCollectionIDs.contains($0.id) }
        }
        return store.collections
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(bookmarkIDs.count > 1 ? "Move \(bookmarkIDs.count) Links" : "Move to Collection")
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

                if options.isEmpty {
                    Text("No other collections available.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 16)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(options) { option in
                                row(option)
                            }
                        }
                    }
                    .frame(maxHeight: 320)
                }

                Button {
                    move()
                } label: {
                    Text("Select a collection")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedID == nil ? Color.gray.opacity(0.2) : Theme.ctaYellow)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2.5))
                }
                .buttonStyle(.plain)
                .disabled(selectedID == nil)
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ collection: TuckiiCollection) -> some View {
        Button {
            selectedID = collection.id
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: collection.colorHex))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: collection.icon.systemName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 2))
                Text(collection.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if selectedID == collection.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 19))
                        .foregroundStyle(Theme.ink)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedID == collection.id ? Theme.selectedRow : Theme.card)
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func move() {
        guard let selectedID else { return }
        for id in bookmarkIDs {
            try? store.move(id, to: selectedID)
        }
        onMoved?()
        dismiss()
    }
}
