import SwiftUI
import Foundation
import TuckiiCore

struct CreateCollectionSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    var parentID: UUID? = nil

    @State private var name = ""
    @State private var selectedColor: UInt32 = 0xFFB020
    @State private var selectedIcon: TuckiiCollection.Icon = .folder
    @State private var errorMessage: String?

    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)
    private let iconColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Add new collection")
                            .font(.system(size: 24, weight: .black, design: .rounded))
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

                    nameField

                    VStack(alignment: .leading, spacing: 10) {
                        Text("COLOR")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                        LazyVGrid(columns: colorColumns, spacing: 8) {
                            ForEach(Self.palette, id: \.self) { hex in
                                colorSwatch(hex)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("ICON")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                        LazyVGrid(columns: iconColumns, spacing: 8) {
                            ForEach(TuckiiCollection.Icon.allCases, id: \.self) { icon in
                                iconButton(icon)
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.danger)
                    }

                    Button(action: create) {
                        Text("Create collection")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isValid ? Theme.ctaYellow : Color.gray.opacity(0.2))
                            )
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid)
                }
                .padding(20)
            }
        }
        .presentationDetents([.large])
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("NAME")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                Spacer()
                Text("\(name.count)/40")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            TextField("e.g. Travel, Design Inspiration.", text: $name)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink.opacity(0.35), lineWidth: 2))
                .onChange(of: name) { newValue in
                    if newValue.count > 40 {
                        name = String(newValue.prefix(40))
                    }
                    errorMessage = nil
                }
        }
    }

    private func colorSwatch(_ hex: UInt32) -> some View {
        Button {
            selectedColor = hex
        } label: {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(hex: hex))
                .frame(height: 32)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.ink, lineWidth: 2))
                .overlay {
                    if selectedColor == hex {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Theme.ink)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func iconButton(_ icon: TuckiiCollection.Icon) -> some View {
        Button {
            selectedIcon = icon
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedIcon == icon ? Theme.ctaYellow : Theme.card)
                .frame(height: 34)
                .overlay(
                    Image(systemName: icon.systemName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func create() {
        do {
            _ = try store.createCollection(name: name, colorHex: selectedColor, icon: selectedIcon, parentID: parentID)
            dismiss()
        } catch let error as LibraryError {
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    static let palette: [UInt32] = [
        0xFFB020, 0xF65C8A, 0xA97BF5, 0x4E8DF5, 0x22BFA6, 0x4CAF50, 0x9CD94E, 0xF28C28,
        0xF2E3C6, 0xBFC4CC, 0x7C93B5, 0xC08ABC, 0xA97C5B, 0x2B2B2B, 0xF76E6E, 0x6B5BF5,
    ]
}
