import SwiftUI
import TuckiiCore

struct MoveSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let bookmarkID: UUID

    @State private var selectedID: UUID?

    private var bookmark: Bookmark? { store.bookmark(bookmarkID) }
    private var options: [TuckiiCollection] {
        store.collections.filter { $0.id != bookmark?.collectionID }
    }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Move to Collection")
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
        try? store.move(bookmarkID, to: selectedID)
        dismiss()
    }
}
