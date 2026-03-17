import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @EnvironmentObject var store: EntryStore
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var showAbout = false

    var entries: [Entry] { store.entries }

    var uniqueCountries: [String] {
        Array(Set(entries.map { $0.country }.filter { !$0.isEmpty })).sorted()
    }
    var uniqueCities: [String] {
        Array(Set(entries.map { $0.city }.filter { !$0.isEmpty })).sorted()
    }
    var categoryBreakdown: [(PlaceCategory, Int)] {
        PlaceCategory.allCases.compactMap { cat in
            let count = entries.filter { $0.category == cat }.count
            return count > 0 ? (cat, count) : nil
        }.sorted { $0.1 > $1.1 }
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
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(hex:"3D2010"), Color(hex:"8B6040")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Text("✈️").font(.system(size: 36))
            }
            Text("我的手账").font(.wanderSerif(24)).foregroundColor(.wanderInk)
            Text("记录每一个值得被记住的角落").font(.system(size: 13)).foregroundColor(.wanderMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var bigStatsRow: some View {
        HStack(spacing: 12) {
            BigStatCard(value: "\(entries.count)", label: "打卡总数", icon: "mappin.circle.fill")
            BigStatCard(value: "\(uniqueCities.count)", label: "城市", icon: "building.2.fill")
            BigStatCard(value: "\(uniqueCountries.count)", label: "国家", icon: "globe.asia.australia.fill")
        }
    }

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("品类分布").font(.system(size: 13, weight: .semibold)).tracking(0.5)
                .foregroundColor(.wanderMuted).textCase(.uppercase)
            ForEach(categoryBreakdown, id: \.0) { (cat, count) in
                VStack(spacing: 6) {
                    HStack {
                        HStack(spacing:4){Image(systemName:cat.icon).font(.system(size:10));Text(cat.rawValue)}.font(.system(size: 14)).foregroundColor(.wanderInk)
                        Spacer()
                        Text("\(count)").font(.system(size: 13, weight: .medium)).foregroundColor(.wanderMuted)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.wanderBlush).frame(height: 5)
                            Capsule().fill(Color.wanderAccent)
                                .frame(width: geo.size.width * CGFloat(count) / CGFloat(max(entries.count, 1)), height: 5)
                                .animation(.spring(duration: 0.5), value: count)
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
            Text("去过的国家 · \(uniqueCountries.count)").font(.system(size: 13, weight: .semibold))
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
            Text("存储").font(.system(size: 13, weight: .semibold)).tracking(0.5)
                .foregroundColor(.wanderMuted).textCase(.uppercase)
            HStack {
                Label("照片占用空间", systemImage: "photo.stack.fill").font(.system(size: 14)).foregroundColor(.wanderInk)
                Spacer()
                Text(PhotoRepository.shared.totalSizeFormatted).font(.system(size: 14, weight: .medium)).foregroundColor(.wanderMuted)
            }
            Text("所有数据仅保存在本设备，不上传任何服务器").font(.system(size: 12)).foregroundColor(.wanderMuted).padding(.top, 2)
        }
        .padding(20).cardStyle()
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            ActionRow(icon: "square.and.arrow.up.fill", label: "导出备份") { showExportSheet = true }
            Divider().padding(.horizontal, 16)
            ActionRow(icon: "square.and.arrow.down.fill", label: "导入备份") { showImportSheet = true }
            Divider().padding(.horizontal, 16)
            ActionRow(icon: "info.circle.fill", label: "关于 WANDER") { showAbout = true }
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
    @State private var isExporting = false
    @State private var exportURL: URL? = nil
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "square.and.arrow.up.fill").font(.system(size: 48)).foregroundColor(.wanderAccent)
                VStack(spacing: 8) {
                    Text("备份你的手账").font(.wanderSerif(24)).foregroundColor(.wanderInk)
                    Text("导出 .json 文件，包含所有打卡记录\n可通过 AirDrop 或文件 App 迁移到新设备")
                        .font(.system(size: 14)).foregroundColor(.wanderMuted)
                        .multilineTextAlignment(.center).lineSpacing(4)
                }
                VStack(spacing: 10) {
                    Text("\(store.entries.count) 条打卡记录").font(.system(size: 15, weight: .medium)).foregroundColor(.wanderInk)
                    Text("照片占用 \(PhotoRepository.shared.totalSizeFormatted)").font(.system(size: 13)).foregroundColor(.wanderMuted)
                }
                .padding(20).background(Color.wanderBlush.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 16))
                Button {
                    Task { await doExport() }
                } label: {
                    Group {
                        if isExporting {
                            ProgressView().tint(.white)
                        } else {
                            Label("导出备份", systemImage: "square.and.arrow.up")
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
            .navigationTitle("导出备份").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
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
                    Text("还原你的手账").font(.wanderSerif(24)).foregroundColor(.wanderInk)
                    Text("选择之前导出的 .json 备份文件\n已有记录不会重复导入")
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
                            Label("导入备份", systemImage: "square.and.arrow.down")
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
            .navigationTitle("导入备份").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
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
            resultMessage = "无法读取文件，请重试"; isSuccess = false; return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else {
            resultMessage = "文件读取失败"; isSuccess = false; return
        }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        guard let entries = try? decoder.decode([Entry].self, from: data) else {
            resultMessage = "格式不正确，请选择 WanderLog 导出的备份文件"; isSuccess = false; return
        }
        let existingIDs = Set(store.entries.map { $0.id })
        let newEntries = entries.filter { !existingIDs.contains($0.id) }
        for entry in newEntries { store.add(entry) }
        resultMessage = newEntries.isEmpty ? "没有新记录可导入" : "成功导入 \(newEntries.count) 条记录"
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
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Text("✦").font(.system(size: 48)).foregroundColor(.wanderAccent)
                Text("WANDER").font(.wanderSerif(32)).foregroundColor(.wanderInk)
                Text("全球探店电子手账").font(.system(size: 16)).foregroundColor(.wanderMuted)
                Text("版本 \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.system(size: 12)).foregroundColor(.wanderMuted)
                Divider().padding(.horizontal, 40)
                VStack(spacing: 10) {
                    AboutRow(icon: "lock.shield.fill", text: "所有数据仅保存在你的设备")
                    AboutRow(icon: "wifi.slash", text: "完全离线可用")
                    AboutRow(icon: "person.slash.fill", text: "无账号，无追踪，无广告")
                }
                .padding(.horizontal, 32)
                Spacer()
            }
            .background(Color.wanderWarm)
            .navigationTitle("关于").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
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
