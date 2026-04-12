import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var showAbout = false
    @State private var avatarImage: UIImage? = nil
    @State private var pickerItem: PhotosPickerItem? = nil
    @AppStorage("profile_name") private var profileName: String = ""
    @AppStorage("profile_tagline") private var profileTagline: String = ""
    @State private var isEditingName = false
    @State private var isEditingTagline = false

    var entries: [Entry] { store.entries }

    var uniqueCountries: [String] {
        Array(Set(entries.map { $0.country }.filter { !$0.isEmpty })).sorted()
    }
    var uniqueCities: [String] {
        Array(Set(entries.map { $0.city }.filter { !$0.isEmpty })).sorted()
    }
    var categoryBreakdown: [(name: String, icon: String, count: Int)] {
        var result: [(name: String, icon: String, count: Int)] = []
        for cat in store.customCategories {
            let count = entries.filter { $0.customCategoryID == cat.id }.count
            if count > 0 { result.append((store.displayName(for: cat, lang: lang.language), cat.icon, count)) }
        }
        for cat in PlaceCategory.allCases {
            let unmapped = entries.filter { $0.customCategoryID == nil }
            let count = unmapped.filter { $0.category == cat }.count
            if count > 0 { result.append((cat.localizedName(lang: lang.language), cat.icon, count)) }
        }
        return result.sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection.padding(.top, 20)
                    bigStatsRow
                    if !categoryBreakdown.isEmpty { categoryBreakdownCard }
                    if !uniqueCountries.isEmpty { countriesCard }
                    storageCard
                    actionsCard
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.wanderWarm)
            .sheet(isPresented: $showExportSheet) { ExportView() }
            .sheet(isPresented: $showImportSheet) { ImportView() }
            .sheet(isPresented: $showAbout) { AboutView() }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let img = avatarImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [Color(hex: "3D2010"), Color(hex: "8B6040")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(Text("✈️").font(.system(size: 36)))
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())

                    // Edit badge
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.wanderAccent)
                        .clipShape(Circle())
                        .offset(x: 2, y: 2)
                }
            }
            .onChange(of: pickerItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        avatarImage = img
                        saveAvatar(img)
                    }
                }
            }

            // Editable name
            Group {
                if isEditingName {
                    TextField("", text: $profileName)
                        .font(.wanderSerif(24))
                        .foregroundColor(.wanderInk)
                        .multilineTextAlignment(.center)
                        .onSubmit { isEditingName = false }
                } else {
                    Text(profileName.isEmpty ? lang.s.profileTitle : profileName)
                        .font(.wanderSerif(24))
                        .foregroundColor(.wanderInk)
                        .onTapGesture { isEditingName = true }
                }
            }

            // Editable tagline
            Group {
                if isEditingTagline {
                    TextField("", text: $profileTagline)
                        .font(.system(size: 13))
                        .foregroundColor(.wanderMuted)
                        .multilineTextAlignment(.center)
                        .onSubmit { isEditingTagline = false }
                } else {
                    Text(profileTagline.isEmpty ? lang.s.profileTagline : profileTagline)
                        .font(.system(size: 13))
                        .foregroundColor(.wanderMuted)
                        .onTapGesture { isEditingTagline = true }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { avatarImage = loadAvatar() }
    }

    private func avatarURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_avatar.jpg")
    }

    private func saveAvatar(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: avatarURL())
        }
    }

    private func loadAvatar() -> UIImage? {
        guard let data = try? Data(contentsOf: avatarURL()) else { return nil }
        return UIImage(data: data)
    }

    private var bigStatsRow: some View {
        HStack(spacing: 12) {
            BigStatCard(value: "\(entries.count)", label: lang.s.totalCheckIns, icon: "mappin.circle.fill")
            BigStatCard(value: "\(uniqueCities.count)", label: lang.s.cities, icon: "building.2.fill")
            BigStatCard(value: "\(uniqueCountries.count)", label: lang.s.countries, icon: "globe.asia.australia.fill")
        }
    }

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(lang.s.categoryBreakdown).font(.system(size: 13, weight: .semibold)).tracking(0.5)
                .foregroundColor(.wanderMuted).textCase(.uppercase)
            ForEach(categoryBreakdown, id: \.name) { item in
                VStack(spacing: 6) {
                    HStack {
                        HStack(spacing:4){Image(systemName:item.icon).font(.system(size:10));Text(item.name)}.font(.system(size: 14)).foregroundColor(.wanderInk)
                        Spacer()
                        Text("\(item.count)").font(.system(size: 13, weight: .medium)).foregroundColor(.wanderMuted)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.wanderBlush).frame(height: 5)
                            Capsule().fill(Color.wanderAccent)
                                .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(max(entries.count, 1)), height: 5)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: item.count)
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
        .padding(20).cardStyle()
    }

    private var countriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.s.visitedCountries(uniqueCountries.count)).font(.system(size: 13, weight: .semibold))
                .tracking(0.5).foregroundColor(.wanderMuted).textCase(.uppercase)
            FlowLayout(spacing: 8) {
                ForEach(uniqueCountries, id: \.self) { country in
                    Text(country).font(.system(size: 13, weight: .medium)).foregroundColor(.wanderInk)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.wanderBlush).clipShape(Capsule())
                }
            }
        }
        .padding(20).cardStyle()
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lang.s.storage).font(.system(size: 13, weight: .semibold)).tracking(0.5)
                .foregroundColor(.wanderMuted).textCase(.uppercase)
            HStack {
                Label(lang.s.photoStorage, systemImage: "photo.stack.fill").font(.system(size: 14)).foregroundColor(.wanderInk)
                Spacer()
                Text(PhotoRepository.shared.totalSizeFormatted).font(.system(size: 14, weight: .medium)).foregroundColor(.wanderMuted)
            }
            Text(lang.s.privacyNote).font(.system(size: 12)).foregroundColor(.wanderMuted).padding(.top, 2)
        }
        .padding(20).cardStyle()
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            ActionRow(icon: "square.and.arrow.up.fill", label: lang.s.exportBackup) { showExportSheet = true }
            Divider().padding(.horizontal, 16)
            ActionRow(icon: "square.and.arrow.down.fill", label: lang.s.importBackup) { showImportSheet = true }
            Divider().padding(.horizontal, 16)
            ActionRow(icon: "info.circle.fill", label: lang.s.aboutWander) { showAbout = true }
        }
        .cardStyle()
    }
}

struct BigStatCard: View {
    let value: String; let label: String; let icon: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(.wanderAccent)
            Text(value).font(.wanderSerif(26, weight: .bold)).foregroundColor(.wanderInk)
            Text(label).font(.system(size: 11)).foregroundColor(.wanderMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18).cardStyle()
    }
}

struct ActionRow: View {
    let icon: String; let label: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(.wanderAccent).frame(width: 24)
                Text(label).font(.system(size: 15)).foregroundColor(.wanderInk)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.wanderMuted)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
        }
    }
}

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    @State private var isExporting = false
    @State private var exportURL: URL? = nil
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "square.and.arrow.up.fill").font(.system(size: 48)).foregroundColor(.wanderAccent)
                VStack(spacing: 8) {
                    Text(lang.s.exportTitle).font(.wanderSerif(24)).foregroundColor(.wanderInk)
                    Text(lang.s.exportDesc)
                        .font(.system(size: 14)).foregroundColor(.wanderMuted)
                        .multilineTextAlignment(.center).lineSpacing(4)
                }
                VStack(spacing: 10) {
                    Text(lang.s.exportEntriesCount(store.entries.count)).font(.system(size: 15, weight: .medium)).foregroundColor(.wanderInk)
                    Text(lang.s.exportPhotoSize(PhotoRepository.shared.totalSizeFormatted)).font(.system(size: 13)).foregroundColor(.wanderMuted)
                }
                .padding(20).background(Color.wanderBlush.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 16))
                Button {
                    Task { await doExport() }
                } label: {
                    Group {
                        if isExporting {
                            ProgressView().tint(.white)
                        } else {
                            Label(lang.s.exportButton, systemImage: "square.and.arrow.up")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.wanderInk).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isExporting)
                Spacer()
            }
            .padding(24).background(Color.wanderWarm)
            .navigationTitle(lang.s.exportBackup).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(lang.s.close) { dismiss() } } }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL { ShareSheet(items: [url]) }
            }
        }
    }

    private func doExport() async {
        isExporting = true
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(store.entries) else { isExporting = false; return }
        let formatter = DateFormatter(); formatter.dateFormat = "yyyyMMdd"
        let filename = "WanderLog_\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        exportURL = url
        isExporting = false
        showShareSheet = true
    }
}

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    @State private var showFilePicker = false
    @State private var isImporting = false
    @State private var resultMessage: String? = nil
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "square.and.arrow.down.fill").font(.system(size: 48)).foregroundColor(.wanderAccent)
                VStack(spacing: 8) {
                    Text(lang.s.importTitle).font(.wanderSerif(24)).foregroundColor(.wanderInk)
                    Text(lang.s.importDesc)
                        .font(.system(size: 14)).foregroundColor(.wanderMuted)
                        .multilineTextAlignment(.center).lineSpacing(4)
                }
                if let msg = resultMessage {
                    Text(msg).font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSuccess ? .wanderAccent : .red)
                        .multilineTextAlignment(.center)
                        .padding(16).background(Color.wanderBlush.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button { showFilePicker = true } label: {
                    Group {
                        if isImporting {
                            ProgressView().tint(.white)
                        } else {
                            Label(lang.s.importButton, systemImage: "square.and.arrow.down")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.wanderInk).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isImporting)
                Spacer()
            }
            .padding(24).background(Color.wanderWarm)
            .navigationTitle(lang.s.importBackup).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(lang.s.close) { dismiss() } } }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.json]) { result in
                Task { await handleImport(result) }
            }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) async {
        isImporting = true
        defer { isImporting = false }
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else {
            resultMessage = lang.s.importErrCannotRead; isSuccess = false; return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else {
            resultMessage = lang.s.importErrReadFailed; isSuccess = false; return
        }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        guard let entries = try? decoder.decode([Entry].self, from: data) else {
            resultMessage = lang.s.importErrInvalidFormat; isSuccess = false; return
        }
        let existingIDs = Set(store.entries.map { $0.id })
        let newEntries = entries.filter { !existingIDs.contains($0.id) }
        for entry in newEntries { store.add(entry) }
        resultMessage = newEntries.isEmpty ? lang.s.importNoNew : lang.s.importSuccess(newEntries.count)
        isSuccess = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lang: LanguageManager
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Text("✦").font(.system(size: 48)).foregroundColor(.wanderAccent)
                Text("Kiro Book").font(.wanderSerif(32)).foregroundColor(.wanderInk)
                Text(lang.s.appSubtitle).font(.system(size: 16)).foregroundColor(.wanderMuted)
                Text(lang.s.version(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
                    .font(.system(size: 12)).foregroundColor(.wanderMuted)
                Divider().padding(.horizontal, 40)
                VStack(spacing: 10) {
                    AboutRow(icon: "lock.shield.fill", text: lang.s.aboutPrivacy1)
                    AboutRow(icon: "wifi.slash", text: lang.s.aboutPrivacy2)
                    AboutRow(icon: "person.slash.fill", text: lang.s.aboutPrivacy3)
                }
                .padding(.horizontal, 32)
                Spacer()
            }
            .background(Color.wanderWarm)
            .navigationTitle(lang.s.about).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(lang.s.close) { dismiss() } } }
        }
    }
}

struct AboutRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.wanderAccent).frame(width: 24)
            Text(text).font(.system(size: 14)).foregroundColor(.wanderInk)
            Spacer()
        }
    }
}
