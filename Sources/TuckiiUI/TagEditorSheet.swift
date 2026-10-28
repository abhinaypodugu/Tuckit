import SwiftUI
import TuckiiCore

struct TagEditorSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let bookmarkID: UUID

    @State private var newTag = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Tags")
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
                            .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    TextField("New tag", text: $newTag)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink.opacity(0.35), lineWidth: 2))
                    Button {
                        addTag()
                    } label: {
                        Text("Add")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.ctaYellow))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.danger)
                }

                if store.tags.isEmpty {
                    Text("No tags yet. Create your first one above.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(store.tags) { tag in
                                tagRow(tag)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
    }

    private func tagRow(_ tag: Tag) -> some View {
        let attached = store.bookmark(bookmarkID)?.tagIDs.contains(tag.id) ?? false
        return Button {
            if attached {
                store.detachTag(tag.id, from: bookmarkID)
            } else {
                store.attachTag(tag.id, to: bookmarkID)
            }
        } label: {
            HStack {
                Text("#\(tag.name)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: attached ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19))
                    .foregroundStyle(Theme.ink)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(attached ? Color(hex: 0xDFF3E9) : .white)
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func addTag() {
        do {
            let tag = try store.addTag(named: newTag)
            store.attachTag(tag.id, to: bookmarkID)
            newTag = ""
            errorMessage = nil
        } catch let error as LibraryError {
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
