import SwiftUI
import UniformTypeIdentifiers
import TuckiiCore

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct BackupView: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    private enum ImporterMode: Identifiable {
        case importOther
        case restore

        var id: Int {
            switch self {
            case .importOther: return 0
            case .restore: return 1
            }
        }

        var types: [UTType] {
            switch self {
            case .importOther: return [.commaSeparatedText, .html, .json]
            case .restore: return [.json]
            }
        }
    }

    @State private var gatedFeature: ProFeature?
    @State private var importerMode: ImporterMode?
    @State private var exportDocument: BackupDocument?
    @State private var showExporter = false
    @State private var alertInfo: BackupAlert?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    sectionTitle("TUCKII BACKUPS")
                    backupRow(
                        icon: "square.and.arrow.up",
                        title: "Export Backup",
                        subtitle: "Export a backup file you can save anywhere",
                        gated: true
                    ) {
                        if store.isPro {
                            prepareExport()
                        } else {
                            gatedFeature = .exportBackup
                        }
                    }
                    backupRow(
                        icon: "arrow.down.circle",
                        title: "Restore from Backup",
                        subtitle: "Restore from a Tuckii backup (.json)",
                        gated: true
                    ) {
                        if store.isPro {
                            importerMode = .restore
                        } else {
                            gatedFeature = .exportBackup
                        }
                    }
                    sectionTitle("IMPORT FROM OTHER APPS")
                    Button {
                        importerMode = .importOther
                    } label: {
                        rowContent(
                            icon: "tray.and.arrow.down",
                            title: "Import Bookmarks",
                            subtitle: "From CSV, HTML, or JSON exports",
                            crown: false
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
        }
        .sheet(item: $gatedFeature) { feature in
            ProUpsellSheet(feature: feature)
                .environmentObject(store)
        }
        .fileImporter(
            isPresented: Binding(
                get: { importerMode != nil },
                set: { if !$0 { importerMode = nil } }
            ),
            allowedContentTypes: importerMode?.types ?? [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "Tuckii-backup"
        ) { result in
            switch result {
            case .success:
                alertInfo = BackupAlert(title: "Backup exported", message: "Your backup file has been saved.")
            case .failure(let error):
                alertInfo = BackupAlert(title: "Export failed", message: error.localizedDescription)
            }
        }
        .alert(item: $alertInfo) { info in
            Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
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
            Text("Backup & Restore")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(Theme.ink.opacity(0.55))
    }

    private func backupRow(
        icon: String,
        title: String,
        subtitle: String,
        gated: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            rowContent(icon: icon, title: title, subtitle: subtitle, crown: gated)
        }
        .buttonStyle(.plain)
    }

    private func rowContent(icon: String, title: String, subtitle: String, crown: Bool) -> some View {
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
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 8)
            if crown {
                Image(systemName: "crown.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.highlighter)
            }
            Image(systemName: "chevron.right")
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

    private func prepareExport() {
        guard let data = store.exportBackupData() else {
            alertInfo = BackupAlert(title: "Export failed", message: "Could not build a backup file.")
            return
        }
        exportDocument = BackupDocument(data: data)
        showExporter = true
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        let mode = importerMode
        importerMode = nil
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let ext = url.pathExtension
                let outcome = try store.importBookmarks(from: data, fileExtension: ext)
                let skippedText = outcome.skipped > 0 ? " Skipped \(outcome.skipped) duplicates." : ""
                let folderText = outcome.collectionsCreated > 0 ? " Created \(outcome.collectionsCreated) collections." : ""
                alertInfo = BackupAlert(
                    title: mode == .restore ? "Backup restored" : "Import complete",
                    message: "Imported \(outcome.imported) bookmarks.\(folderText)\(skippedText)"
                )
            } catch {
                alertInfo = BackupAlert(title: "Import failed", message: error.localizedDescription)
            }
        case .failure(let error):
            alertInfo = BackupAlert(title: "Import failed", message: error.localizedDescription)
        }
    }
}

private struct BackupAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

extension ProFeature: Identifiable {
    public var id: String { gateMessage }
}

struct HowToView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showGuide = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("SHARING")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Theme.ink.opacity(0.55))
                        Button {
                            showGuide = true
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(Theme.ink.opacity(0.07))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Theme.ink)
                                    )
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Save links with quick save")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Theme.ink)
                                    Text("Paste any link into Tuckii from the home screen")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right")
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
                    .padding(20)
                }
            }
            .navigationDestination(isPresented: $showGuide) {
                QuickSaveGuideView()
            }
        }
    }
}

struct QuickSaveGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Save links from any app")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("Copy a link anywhere, then paste it into Tuckii so you can pick a collection.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    step(1, "Copy a link in Chrome, Instagram, TikTok, X, or another app.")
                    step(2, "Open Tuckii and paste it into the quick save bar.")
                    step(3, "Put it in a collection: Unsorted, or one of your own.")
                    step(4, "Optionally pin the link, then tap the + button to save.")
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(Theme.ink)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.highlighter))
                .overlay(Circle().stroke(Theme.ink, lineWidth: 1.8))
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink.opacity(0.5), lineWidth: 2))
        )
    }
}
