import SwiftUI
import Foundation
import TuckiiCore

extension TuckiiCollection.Icon {
    var systemName: String {
        switch self {
        case .folder: return "folder"
        case .star: return "star"
        case .heart: return "heart"
        case .book: return "book"
        case .music: return "music.note"
        case .camera: return "camera"
        case .flag: return "flag"
        case .moon: return "moon"
        case .sun: return "sun.max"
        case .cloud: return "cloud"
        case .pin: return "mappin"
        case .calendar: return "calendar"
        case .globe: return "globe"
        case .gift: return "gift"
        case .leaf: return "leaf"
        case .briefcase: return "briefcase"
        case .cart: return "cart"
        case .plane: return "airplane"
        case .car: return "car"
        case .coffee: return "cup.and.saucer"
        case .film: return "film"
        case .headphones: return "headphones"
        case .palette: return "paintpalette"
        case .more: return "ellipsis"
        }
    }
}

enum PlaceholderStyle {
    private static let palette: [UInt32] = [
        0xFFCF5C, 0xF7A8B8, 0xB9A3F3, 0x8FB8F5, 0x8FE3D2, 0xF5E6C8, 0xC7F0A1, 0xF8B27A,
    ]

    static func color(for seed: UInt32) -> Color {
        Color(hex: palette[Int(seed % UInt32(palette.count))])
    }
}

struct CollectionCard: View {
    let collection: TuckiiCollection
    let itemCount: Int
    let hasNew: Bool

    private var accent: Color { Color(hex: collection.colorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                iconTile
                Text("\(itemCount) \(itemCount == 1 ? "item" : "items")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if hasNew {
                    Text("NEW")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.highlighter))
                }
            }
            Text(collection.name)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.ink, lineWidth: 2.5))
        )
        .padding(.top, 10)
        .background(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 5)
                .fill(accent)
                .frame(width: 96, height: 24)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 2.5))
                .offset(x: 12)
        }
    }

    private var iconTile: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(accent)
            .frame(width: 34, height: 34)
            .overlay(
                Image(systemName: collection.icon.systemName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
            )
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.ink, lineWidth: 2))
    }
}

struct BookmarkCard: View {
    let bookmark: Bookmark
    var collectionChip: (name: String, colorHex: UInt32)? = nil

    private var accent: Color { PlaceholderStyle.color(for: bookmark.placeholderSeed) }
    private var initial: String {
        let name = bookmark.sourceName ?? bookmark.domain
        guard let first = name.first(where: { $0.isLetter || $0.isNumber }) else { return "?" }
        return String(first).uppercased()
    }
    private var sourceLabel: String { bookmark.sourceName ?? bookmark.domain }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(accent)
                    .frame(height: 118)
                    .overlay(
                        Text(initial)
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(Theme.ink.opacity(0.8))
                    )
                if !bookmark.isSeen {
                    Text("NEW")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Theme.highlighter)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .rotationEffect(.degrees(-4))
                        .padding(7)
                }
                if let collectionChip {
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: collectionChip.colorHex))
                            .frame(width: 10, height: 10)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.ink, lineWidth: 1))
                        Text(collectionChip.name)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.ink, lineWidth: 1.5))
                    .padding(7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(bookmark.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 5) {
                    Text(initial)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(.gray.opacity(0.25)))
                    Text(sourceLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(10)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
        .overlay(alignment: .topTrailing) {
            if bookmark.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.card.opacity(0.92)))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.ink, lineWidth: 1.5))
                    .padding(6)
            }
        }
    }
}
