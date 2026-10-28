import SwiftUI
import TuckiiCore
#if os(iOS)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

struct SettingsView: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var showCloudSyncUpsell = false
    @State private var showBackup = false
    @State private var showHowTo = false
    @State private var showReminderPrimer = false
    @State private var showDeleteConfirm = false
    @State private var alertInfo: SettingsAlert?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    planCard
                    preferencesSection
                    dataStorageSection
                    supportSection
                    accountSection
                    Text("Version 1.6.0")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            if showReminderPrimer {
                reminderPrimer
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView {
                showPaywall = false
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showCloudSyncUpsell) {
            ProUpsellSheet(feature: .cloudSync)
                .environmentObject(store)
        }
        .sheet(isPresented: $showBackup) {
            BackupView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showHowTo) {
            HowToView()
        }
        .alert(item: $alertInfo) { info in
            Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
        }
        .alert("Delete all data", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteAllData()
            }
        } message: {
            Text("Permanently erase all saves, collections, and tags on this device?")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 13).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.ink, lineWidth: 2.5))
            }
            .buttonStyle(.plain)
            Text("Settings")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 8)
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR PLAN")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                    Text(store.isPro ? "Tuckii Pro" : "Tuckii Free")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(store.isPro ? "Every feature, unlimited." : "Save smarter, every day.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.ink.opacity(0.65))
                }
                Spacer()
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color(hex: 0x111111).opacity(0.85))
            }
            HStack {
                Spacer()
                Text(store.isPro ? "PRO PLAN" : "FREE PLAN")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 1.5))
            }

            if !store.isPro {
                usageCard
            }

            Button {
                if store.isPro {
                    alertInfo = SettingsAlert(title: "Tuckii Pro", message: "Cloud sync and sharing are out of scope for this clone, so there is nothing to manage here.")
                } else {
                    showPaywall = true
                }
            } label: {
                HStack(spacing: 6) {
                    Text(store.isPro ? "Manage plan" : "Level up to Pro")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(RoundedRectangle(cornerRadius: 11).fill(store.isPro ? Theme.card : Theme.highlighter))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.ink, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.highlighter))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.ink, lineWidth: 2.5))
    }

    private var usageCard: some View {
        let summary = store.usageSummary()
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FREE PLAN USAGE")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("Links reset daily")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Resets in \(Self.countdown(to: summary.resetsAt, now: context.date))")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 1.5))
                }
            }
            usageRow(
                icon: "link",
                label: "Links today",
                used: summary.linksUsed,
                limit: summary.linksLimit
            )
            usageRow(
                icon: "photo",
                label: "Images saved",
                used: summary.imagesUsed,
                limit: summary.imagesLimit
            )
            usageRow(
                icon: "folder",
                label: "Collections",
                used: summary.collectionsUsed,
                limit: summary.collectionsLimit
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink.opacity(0.35), lineWidth: 2))
        )
    }

    private func usageRow(icon: String, label: String, used: Int, limit: Int?) -> some View {
        let fraction: Double = {
            guard let limit, limit > 0 else { return 0 }
            return min(1, Double(used) / Double(limit))
        }()
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.ink.opacity(0.07))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink.opacity(0.75))
                )
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(used)/\(limit.map(String.init) ?? "∞")")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.ink)
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.ink.opacity(0.12))
                        Capsule()
                            .fill(Theme.highlighter)
                            .frame(width: geometry.size.width * fraction)
                    }
                }
                .frame(height: 7)
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("PREFERENCES")
            toggleRow(
                icon: "bolt",
                title: "Haptic Feedback",
                subtitle: "Vibrate for actions and selections",
                isOn: Binding(
                    get: { store.settings.hapticsEnabled },
                    set: { store.setHapticsEnabled($0) }
                )
            )
            toggleRow(
                icon: "moon",
                title: "Dark Mode",
                subtitle: "Use a darker look for the app",
                isOn: Binding(
                    get: { store.settings.darkMode },
                    set: { store.setDarkMode($0) }
                )
            )
            toggleRow(
                icon: "bell",
                title: "New Save Reminders",
                subtitle: "Gentle reminders to review unseen saves",
                isOn: Binding(
                    get: { store.settings.remindersEnabled },
                    set: { newValue in
                        if newValue {
                            showReminderPrimer = true
                        } else {
                            store.setRemindersEnabled(false)
                            Self.cancelReminder()
                        }
                    }
                )
            )
        }
    }

    private var dataStorageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("DATA & STORAGE")
            linkRow(
                icon: "cloud",
                title: "Cloud Sync",
                subtitle: "Sync your library across devices",
                action: { showCloudSyncUpsell = true }
            )
            linkRow(
                icon: "archivebox",
                title: "Backup & Restore",
                subtitle: "Local backups and bookmark imports",
                action: { showBackup = true }
            )
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("SUPPORT")
            linkRow(
                icon: "book",
                title: "How To",
                subtitle: "Quick guides for getting more from Tuckii",
                action: { showHowTo = true }
            )
            linkRow(
                icon: "bubble.left",
                title: "Send Feedback",
                subtitle: "Got a bug or idea? We'd love to hear it!",
                action: {
                    if let url = URL(string: "mailto:support@example.com?subject=Tuckii%20Feedback") {
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #endif
                    }
                },
                external: true
            )
            linkRow(
                icon: "lock",
                title: "Privacy Policy",
                subtitle: nil,
                action: {
                    alertInfo = SettingsAlert(title: "Privacy Policy", message: "Add your privacy policy URL in SettingsView before shipping.")
                },
                external: true
            )
            linkRow(
                icon: "doc.text",
                title: "Terms of Service",
                subtitle: nil,
                action: {
                    alertInfo = SettingsAlert(title: "Terms of Service", message: "Add your terms URL in SettingsView before shipping.")
                },
                external: true
            )
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("ACCOUNT")
            Button {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Theme.danger.opacity(0.12))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.danger)
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Delete All Data")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.danger)
                        Text("Permanently erase all saves, collections, and tags on this device")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(Theme.ink.opacity(0.55))
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9)
                .fill(Theme.ink.opacity(0.07))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
        )
    }

    private func linkRow(
        icon: String,
        title: String,
        subtitle: String?,
        action: @escaping () -> Void,
        external: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Theme.ink.opacity(0.07))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: external ? "arrow.up.right" : "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink.opacity(0.45))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
            )
        }
        .buttonStyle(.plain)
    }

    private var reminderPrimer: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.green)
                Text("Allow Tuckii to send you notifications?")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Button {
                    showReminderPrimer = false
                    requestNotifications()
                } label: {
                    Text("Allow")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.green.opacity(0.45)))
                }
                .buttonStyle(.plain)
                Button {
                    showReminderPrimer = false
                    store.setRemindersEnabled(false)
                } label: {
                    Text("Don't allow")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.ink.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.ink, lineWidth: 2.5))
            .padding(.horizontal, 34)
        }
    }

    private func requestNotifications() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                store.setRemindersEnabled(granted)
                if granted {
                    Self.scheduleReminder()
                } else {
                    Self.cancelReminder()
                }
            }
        }
        #endif
    }

    private static func scheduleReminder() {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "Don't forget your saves"
        content.body = "Swipe through your unseen saves now."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "tuckii.reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        #endif
    }

    private static func cancelReminder() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["tuckii.reminder"])
        #endif
    }

    private static func countdown(to date: Date, now: Date) -> String {
        let remaining = max(0, Int(date.timeIntervalSince(now)))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

private struct SettingsAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
