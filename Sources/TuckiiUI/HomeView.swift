import SwiftUI
import TuckiiCore

public struct HomeView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var urlText = ""
    @State private var showCreateCollection = false
    @State private var showCollectionSort = false
    @State private var alertInfo: HomeAlertInfo?
    @State private var path: [UUID] = []
    @State private var showSearch = false
    @State private var showSettings = false
    @State private var showFocus = false

    public init() {}

    public var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.cream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        title
                        quickSaveBar
                        if store.totalUnseenCount > 0 {
                            reviewBanner
                        }
                        collectionsHeader
                        collectionsContent
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: UUID.self) { id in
                CollectionScreen(collectionID: id)
            }
            .sheet(isPresented: $showCreateCollection) {
                CreateCollectionSheet()
                    .environmentObject(store)
            }
            .fullScreenCover(isPresented: $showSearch) {
                SearchView()
                    .environmentObject(store)
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
            }
            .fullScreenCover(isPresented: $showFocus) {
                FocusModeView(collectionID: nil)
                    .environmentObject(store)
            }
            .confirmationDialog("Sort collections", isPresented: $showCollectionSort, titleVisibility: .visible) {
                ForEach(CollectionSort.allCases, id: \.self) { sort in
                    Button(sort.displayName) {
                        store.setCollectionSort(sort)
                    }
                }
            }
            .alert(item: $alertInfo) { info in
                Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            iconButton("gearshape") {
                showSettings = true
            }
            Spacer()
            iconButton("folder.badge.gearshape") {
                showCreateCollection = true
            }
            iconButton("magnifyingglass") {
                showSearch = true
            }
        }
    }

    private var title: some View {
        Text("Save now.\nFind anytime.")
            .font(.system(size: 40, weight: .black, design: .rounded))
            .foregroundStyle(Theme.ink)
            .lineSpacing(2)
    }

    private var quickSaveBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "number")
                    .font(.system(size: 17, weight: .semibold))
                TextField("Paste link to quick save", text: $urlText)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.ink.opacity(0.7))
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.field))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.ink, lineWidth: 2.5))

            Button(action: quickAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 56, height: 56)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.ctaYellow))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.ink, lineWidth: 2.5))
            }
            .buttonStyle(.plain)
        }
    }

    private var reviewBanner: some View {
        Button {
            showFocus = true
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.green)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(store.totalUnseenCount) new \(store.totalUnseenCount == 1 ? "save" : "saves") waiting")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("Review now")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.ink.opacity(0.55))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.banner)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
            )
        }
        .buttonStyle(.plain)
    }

    private var collectionsHeader: some View {
        HStack {
            Text("My Collections")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button {
                showCollectionSort = true
            } label: {
                HStack(spacing: 4) {
                    Text(store.settings.collectionSort.displayName.components(separatedBy: " ").first ?? "Oldest")
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var collectionsContent: some View {
        if store.visibleCollections.isEmpty {
            emptyState
        } else {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                spacing: 20
            ) {
                ForEach(store.visibleCollections) { collection in
                    Button {
                        path.append(collection.id)
                    } label: {
                        CollectionCard(
                            collection: collection,
                            itemCount: store.bookmarkCount(in: collection.id),
                            hasNew: store.unseenCount(in: collection.id) > 0
                        )
                    }
                    .buttonStyle(.plain)
                }
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
                showCreateCollection = true
            } label: {
                Text("Create now")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.ctaYellow))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
    }

    private func iconButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.field))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
        }
        .buttonStyle(.plain)
    }

    private func quickAdd() {
        guard let url = URLNormalizer.normalize(urlText) else {
            alertInfo = HomeAlertInfo(title: "No URL", message: "Please enter a link to save")
            return
        }
        do {
            let bookmark = try store.addBookmark(url: url)
            urlText = ""
            path.append(store.unsorted.id)
            Task {
                await store.refreshMetadata(for: bookmark.id)
            }
        } catch let error as LibraryError {
            alertInfo = HomeAlertInfo(title: error.title, message: error.message)
        } catch {
            alertInfo = HomeAlertInfo(title: "Couldn't save", message: error.localizedDescription)
        }
    }
}

private struct HomeAlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
