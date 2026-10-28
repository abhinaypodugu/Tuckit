import SwiftUI
import TuckiiCore

struct ProUpsellSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let feature: ProFeature

    @State private var showPaywall = false

    private let rows: [(feature: String, free: String, pro: String)] = [
        ("Saves", "4 links/day", "Unlimited links"),
        ("Collections", "3", "Unlimited"),
        ("Focus Mode", "check", "check"),
        ("Reminders", "check", "check"),
        ("Share collections", "dash", "check"),
        ("Tags & filters", "dash", "check"),
        ("Export & backup", "dash", "check"),
        ("Subfolders", "dash", "check"),
    ]

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            if showPaywall {
                PaywallView {
                    dismiss()
                }
                .environmentObject(store)
            } else {
                upsellContent
            }
        }
        .presentationDetents([.large])
    }

    private var upsellContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.ctaYellow)
                    .padding(.top, 8)

                Text("☆ GO PRO ☆")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)

                Text("\(feature.gateMessage)\nHere's what you get with Pro:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                    .multilineTextAlignment(.center)

                featureTable

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Maybe later")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2.5))
                    }
                    .buttonStyle(.plain)
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 6) {
                            Text("Show me")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.ctaYellow))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
    }

    private var featureTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Feature")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .frame(width: 96)
                    .background(Color(hex: 0xD8ECFA))
                Text("Pro")
                    .frame(width: 96)
                    .background(Color(hex: 0xFBE3A6))
            }
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(Theme.ink)
            .padding(.vertical, 8)
            .padding(.leading, 10)
            .background(.white)

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    Text(row.feature)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                    cell(row.free)
                        .frame(width: 96)
                    cell(row.pro)
                        .frame(width: 96)
                }
                .padding(.vertical, 7)
                .background(.white)
                Divider()
            }
        }
        .foregroundStyle(Theme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2.5))
    }

    @ViewBuilder
    private func cell(_ value: String) -> some View {
        if value == "check" {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Theme.green))
        } else if value == "dash" {
            Text("—")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
        } else {
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
    }
}

struct PaywallView: View {
    @EnvironmentObject private var store: LibraryStore

    let onClose: () -> Void

    private enum Plan: String, CaseIterable {
        case monthly, yearly
    }

    @State private var plan: Plan = .monthly

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                        Text("YOUR TUCKII IS READY")
                            .font(.system(size: 12, weight: .heavy))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.highlighter))
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 36, height: 36)
                            .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }

                Text("Your saves\ndeserve a system.")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)

                Text("Pro Plan — for those who treat bookmarking like building a second brain.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                planCard(
                    plan: .monthly,
                    badge: "3-DAY FREE TRIAL",
                    badgeColor: Theme.green,
                    title: "Monthly",
                    caption: "A coffee date...",
                    price: "₹199.00 / month",
                    captionPrice: nil,
                    icon: "calendar",
                    accent: Color(hex: 0xF49A9A)
                )
                planCard(
                    plan: .yearly,
                    badge: "SAVE 50%",
                    badgeColor: Theme.highlighter,
                    title: "Yearly",
                    caption: "Moving in together...",
                    price: "₹1,199.00 / year",
                    captionPrice: "₹99.91/month",
                    icon: "sparkles",
                    accent: Color(hex: 0x7C93F5)
                )

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.green)
                    Text("Cancel anytime")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity)

                Button {
                    store.setProSimulated(true)
                    onClose()
                } label: {
                    Text("Start your 3-day free trial")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 13).fill(Theme.ctaYellow))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.ink, lineWidth: 2.5))
                }
                .buttonStyle(.plain)

                Text("₹199.00/month after a 3-day free trial. Cancel anytime.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Button {
                    onClose()
                } label: {
                    Text("Start with Free")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 13).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.ink, lineWidth: 2.5))
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Text("Restore Purchases")
                    Text("|")
                    Text("Terms")
                    Text("|")
                    Text("Privacy")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .underline()
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
    }

    private func planCard(
        plan: Plan,
        badge: String,
        badgeColor: Color,
        title: String,
        caption: String,
        price: String,
        captionPrice: String?,
        icon: String,
        accent: Color
    ) -> some View {
        Button {
            self.plan = plan
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accent)
                    .frame(width: 46, height: 88)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: self.plan == plan ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.ink)
                        Text(title)
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                    }
                    Text(caption)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    if let captionPrice {
                        Text(captionPrice)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 6)
                Text(price)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(self.plan == plan ? Color(hex: 0xFDF3D6) : .white)
            )
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.ink, lineWidth: 2.5))
            .overlay(alignment: .topLeading) {
                Text(badge)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 5).fill(badgeColor))
                    .offset(x: 40, y: -9)
            }
        }
        .buttonStyle(.plain)
    }
}
