import SwiftUI
import TuckiiCore

public struct HomeView: View {
    @State private var urlText = ""

    public init() {}

    public var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 12) {
                        iconButton("gearshape")
                        Spacer()
                        iconButton("folder.badge.gearshape")
                        iconButton("magnifyingglass")
                    }
                    Text("Save now.\nFind anytime.")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "number")
                            TextField("Paste link to quick save", text: $urlText)
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                #endif
                            Image(systemName: "doc.on.clipboard")
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.ink, lineWidth: 2.5))

                        Button {
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 56, height: 56)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.ctaYellow))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.ink, lineWidth: 2.5))
                        }
                    }
                    HStack {
                        Text("My Collections")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Oldest")
                            Image(systemName: "chevron.down")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.gray)
                    }
                    emptyState
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundStyle(.gray.opacity(0.45))
                .padding(.bottom, 8)
            Text("No Collections Yet")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("Start organizing your saves by creating your first collection.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
            } label: {
                Text("Create now")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.ctaYellow))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2))
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
    }

    private func iconButton(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .frame(width: 48, height: 48)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
    }
}
