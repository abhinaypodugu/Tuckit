import SwiftUI
import Foundation
import TuckiiCore
#if canImport(UserNotifications)
import UserNotifications
#endif

public struct OnboardingView: View {
    @EnvironmentObject private var store: LibraryStore

    let onFinish: () -> Void

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    @State private var page = 0
    @State private var demoStage = 0
    @State private var demoCollection = "Unsorted"
    @State private var focusIndex = 0

    private let totalPages = 6

    private let demoCards: [(source: String, title: String, summary: String, tag: String, collection: String, color: UInt32)] = [
        ("social.example", "Quick dinner recipe", "5 vegetables, 1 pan, 15 minutes.", "", "Recipes", 0xFFCF5C),
        ("Pinterest", "Cozy reading corner ideas", "A lamp, a chair and a shelf. Everything else follows.", "interior", "Home ideas", 0xF8B27A),
        ("travel.example", "Kyoto travel tip: go early", "Visit Higashiyama at 7am to avoid the crowds.", "japan", "Travel", 0x8FB8F5),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 14) {
                topBar
                content
                    .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            if page > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        page -= 1
                        demoStage = 0
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 5) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Theme.highlighter : Theme.ink.opacity(0.15))
                        .frame(width: index == page ? 22 : 16, height: 7)
                        .overlay(Capsule().stroke(Theme.ink.opacity(0.6), lineWidth: 1.2))
                }
            }
            .frame(maxWidth: .infinity)
            if page >= 3 && page <= 4 {
                Button("Skip") {
                    withAnimation { page = totalPages - 1 }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
                .buttonStyle(.plain)
            } else if page > 0 {
                Color.clear.frame(width: 40, height: 40)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case 0:
            introPage
        case 1:
            problemPage
        case 2:
            meetPage
        case 3:
            demoPage
        case 4:
            focusDemoPage
        case 5:
            paywallPage
        default:
            introPage
        }
    }

    private var introPage: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 4)
            highlightedTitle("You saved it.", highlight: nil)
            highlightedTitle("Then lost it.", highlight: "lost it.")
            Text("Good stuff ends up everywhere.")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
            demoCardCluster
            Spacer(minLength: 0)
            primaryButton("That's me") {
                withAnimation { page = 1 }
            }
        }
    }

    private var demoCardCluster: some View {
        VStack(spacing: 12) {
            ForEach(Array(demoCards.enumerated()), id: \.offset) { index, card in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: card.color))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text(String(card.source.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(Theme.ink)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.ink.opacity(0.75))
                            .frame(width: 120, height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.ink.opacity(0.2))
                            .frame(width: 86, height: 8)
                    }
                    Spacer()
                    Image(systemName: "bookmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2))
                )
                .rotationEffect(.degrees(index == 0 ? -2 : (index == 2 ? 2 : 0)))
                .padding(.horizontal, CGFloat(index) * 14)
            }
        }
        .padding(.vertical, 8)
    }

    private var problemPage: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 4)
            highlightedTitle("Saved isn't\nthe same as used.", highlight: "used.")
            Text("Bookmarks in 7 apps. Screenshots in your camera roll. Tabs saved for \"later.\"")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.ink, lineWidth: 2.5))
                        .frame(height: 190)
                        .overlay(
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: 0xF8B27A).opacity(0.5))
                                    .frame(height: 110)
                                    .overlay(
                                        Text("Quick dinner recipe")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(Theme.ink.opacity(0.6))
                                    )
                                    .padding(.horizontal, 12)
                                Text("Never opened")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                        )
                    Text("NEVER OPENED")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Theme.danger)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.danger, lineWidth: 1.6))
                        .rotationEffect(.degrees(-6))
                        .padding(18)
                }
            }
            .padding(.top, 6)
            Spacer(minLength: 0)
            primaryButton("There's a better way") {
                withAnimation { page = 2 }
            }
        }
    }

    private var meetPage: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 4)
            highlightedTitle("Meet Tuckii.", highlight: "Tuckii.")
            Text("One home for everything you keep.\nTuck it in once. Find it when it counts.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            ZStack {
                Circle()
                    .fill(Theme.highlighter)
                    .frame(width: 150, height: 150)
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color(hex: 0x111111))
            }
            .padding(.vertical, 10)
            Spacer(minLength: 0)
            primaryButton("Show me how") {
                withAnimation { page = 3 }
            }
        }
    }

    private var demoPage: some View {
        VStack(spacing: 12) {
            demoReel
            demoStageContent
        }
    }

    private var demoReel: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: 0x14100C))
                .overlay(
                    VStack(spacing: 10) {
                        Spacer()
                        Text("@tuckii.demo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Quick dinner recipe")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("5 vegetables, 1 pan, 15 minutes.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(14),
                    alignment: .bottomLeading
                )
                .overlay(alignment: .top) {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 10))
                        Text("Try it · save this reel to Tuckii")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white.opacity(0.14)))
                    .padding(.top, 10)
                }
            if demoStage == 0 {
                Button {
                    withAnimation { demoStage = 1 }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(hex: 0x111111))
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(Theme.ctaYellow))
                        Text("Tap Share →")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 260)
    }

    @ViewBuilder
    private var demoStageContent: some View {
        switch demoStage {
        case 0:
            hintCard("This is a demo reel. Tap the yellow Share button to try saving it.")
        case 1:
            VStack(spacing: 10) {
                Text("Share with")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 14) {
                    mockAppTile("Messages", systemName: "message.fill", selected: false)
                    mockAppTile("Notes", systemName: "note.text", selected: false)
                    mockAppTile("Tuckii", systemName: "bookmark.fill", selected: true) {
                        withAnimation { demoStage = 2 }
                    }
                    mockAppTile("More", systemName: "ellipsis", selected: false)
                }
                hintCard("Tap Tuckii to save this reel.")
            }
        case 2:
            VStack(spacing: 10) {
                Text("Save to Tuckii")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("https://social.example/reel/quick-dinner-recipe")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(["Unsorted", "Recipes", "Home ideas", "Travel"], id: \.self) { name in
                    Button {
                        demoCollection = name
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(demoCollection == name ? Theme.highlighter : Theme.ink.opacity(0.08))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "folder")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Theme.ink)
                                )
                            Text(name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            if demoCollection == name {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.ink)
                            }
                        }
                        .padding(9)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(demoCollection == name ? Theme.selectedRow : Theme.card)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 1.6))
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    withAnimation { demoStage = 3 }
                } label: {
                    Text("Save to \"\(demoCollection)\"")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(RoundedRectangle(cornerRadius: 11).fill(Theme.ctaYellow))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.ink, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        default:
            VStack(spacing: 12) {
                Text("That's it. It's in \(demoCollection)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text("Title, preview and source — filled in for you.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    withAnimation {
                        page = 4
                        focusIndex = 0
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Now use it")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(RoundedRectangle(cornerRadius: 11).fill(Theme.ctaYellow))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.ink, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }

    private func mockAppTile(_ name: String, systemName: String, selected: Bool, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? Theme.card : Theme.ink.opacity(0.06))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: systemName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selected ? Theme.highlighter : Color.clear, lineWidth: 3)
                    )
                Text(name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .buttonStyle(.plain)
    }

    private func hintCard(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(.center)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.highlighter.opacity(0.5)))
    }

    private var focusDemoPage: some View {
        let card = demoCards[min(focusIndex, demoCards.count - 1)]
        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEW SAVES")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(String(format: "%02d", focusIndex + 1)) / \(String(format: "%02d", demoCards.count))")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Circle().fill(.gray.opacity(0.3)).frame(width: 20, height: 20)
                    Text(card.source)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                }
                .padding(12)
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: card.color))
                        .frame(height: 190)
                        .overlay(
                            Text(String(card.title.prefix(1)))
                                .font(.system(size: 54, weight: .black))
                                .foregroundStyle(Theme.ink.opacity(0.75))
                        )
                    Text(card.collection)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.ink, lineWidth: 1.5))
                        .padding(8)
                }
                .padding(.horizontal, 12)
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(card.summary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    if !card.tag.isEmpty {
                        Text("# \(card.tag)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.chipGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 1.4))
                    }
                }
                .padding(12)
            }
            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.ink.opacity(0.2), lineWidth: 1))
            Text("Focus Mode serves your saves one at a time.\nOpen what matters, skip the rest.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            HStack(spacing: 14) {
                Button {
                    focusIndex = max(0, focusIndex - 1)
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .disabled(focusIndex == 0)
                Button {
                    if focusIndex < demoCards.count - 1 {
                        focusIndex += 1
                    } else {
                        withAnimation { page = 5 }
                    }
                } label: {
                    Text(focusIndex < demoCards.count - 1 ? "Next" : "Continue")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: 0x111111))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.ctaYellow))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0x0C0C0E)))
    }

    private var paywallPage: some View {
        PaywallView {
            finish()
        }
        .environmentObject(store)
    }

    private func highlightedTitle(_ text: String, highlight: String?) -> some View {
        Group {
            if let highlight, let range = text.range(of: highlight) {
                (
                    Text(String(text[..<range.lowerBound]))
                        + Text(String(text[range]))
                        .foregroundColor(Color(hex: 0x111111))
                        + Text(String(text[range.upperBound...]))
                )
                .background(alignment: .bottom) {
                    GeometryReader { geometry in
                        let total = geometry.size.width
                        let lowerRatio = CGFloat(text.distance(from: text.startIndex, to: range.lowerBound)) / CGFloat(max(text.count, 1))
                        let upperRatio = CGFloat(text.distance(from: text.startIndex, to: range.upperBound)) / CGFloat(max(text.count, 1))
                        Rectangle()
                            .fill(Theme.highlighter)
                            .frame(width: max(0, (upperRatio - lowerRatio) * total * 0.9), height: 18)
                            .offset(x: lowerRatio * total)
                            .offset(y: -3)
                    }
                }
            } else {
                Text(text)
            }
        }
        .font(.system(size: 38, weight: .black, design: .rounded))
        .foregroundStyle(Theme.ink)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.ctaYellow))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
        }
        .buttonStyle(.plain)
    }

    private func finish() {
        onFinish()
    }
}
