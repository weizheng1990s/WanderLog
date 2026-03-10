#!/bin/bash
# ============================================================
# WANDERLOG · 一次性初始化同步脚本
# 用法：把此脚本放到任意位置，终端运行：
#   bash sync_wanderlog.sh
# ============================================================

TARGET="/Users/mars/Desktop/WanderLog/WanderLog"
XCODEPROJ="/Users/mars/Desktop/WanderLog/WanderLog.xcodeproj"

echo "🗂  创建目录结构..."
mkdir -p "$TARGET"
mkdir -p "$XCODEPROJ"

# ── Assets ──
mkdir -p "$TARGET/Assets.xcassets/WandrInk.colorset"
mkdir -p "$TARGET/Assets.xcassets/WandrCream.colorset"
mkdir -p "$TARGET/Assets.xcassets/WandrAccent.colorset"
mkdir -p "$TARGET/Assets.xcassets/WandrMuted.colorset"
mkdir -p "$TARGET/Assets.xcassets/WandrWarm.colorset"
mkdir -p "$TARGET/Assets.xcassets/WandrBlush.colorset"
mkdir -p "$TARGET/Assets.xcassets/AppIcon.appiconset"

echo "🎨  写入 Assets..."

cat > "$TARGET/Assets.xcassets/Contents.json" << 'ASSET_EOF'
{ "info": { "author": "xcode", "version": 1 } }
ASSET_EOF

write_color() {
  local dir="$1" r="$2" g="$3" b="$4"
  cat > "$dir/Contents.json" << EOF
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": { "red": "$r", "green": "$g", "blue": "$b", "alpha": "1.000" }
      },
      "idiom": "universal"
    }
  ],
  "info": { "author": "xcode", "version": 1 }
}
EOF
}

write_color "$TARGET/Assets.xcassets/WandrInk.colorset"    "0.102" "0.090" "0.078"
write_color "$TARGET/Assets.xcassets/WandrCream.colorset"  "0.961" "0.941" "0.910"
write_color "$TARGET/Assets.xcassets/WandrAccent.colorset" "0.769" "0.659" "0.510"
write_color "$TARGET/Assets.xcassets/WandrMuted.colorset"  "0.549" "0.510" "0.471"
write_color "$TARGET/Assets.xcassets/WandrWarm.colorset"   "0.980" "0.973" "0.957"
write_color "$TARGET/Assets.xcassets/WandrBlush.colorset"  "0.910" "0.835" "0.769"

cat > "$TARGET/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'ASSET_EOF'
{
  "images": [{ "idiom": "universal", "platform": "ios", "size": "1024x1024" }],
  "info": { "author": "xcode", "version": 1 }
}
ASSET_EOF

echo "📝  写入 Swift 源文件..."

# ── WandrApp.swift ──
cat > "$TARGET/WandrApp.swift" << 'SWIFT_EOF'
import SwiftUI
import SwiftData

@main
struct WandrApp: App {

    let container: ModelContainer = {
        let schema = Schema([Entry.self, Tag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
SWIFT_EOF

# ── RootView.swift ──
cat > "$TARGET/RootView.swift" << 'SWIFT_EOF'
import SwiftUI

struct RootView: View {
    @State private var selectedTab: Tab = .home
    @State private var showAddEntry = false

    enum Tab {
        case home, map, collection, profile
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                MapTabView()
                    .tag(Tab.map)
                CollectionView()
                    .tag(Tab.collection)
                ProfileView()
                    .tag(Tab.profile)
            }
            .toolbar(.hidden, for: .tabBar)

            CustomTabBar(selectedTab: $selectedTab, showAddEntry: $showAddEntry)
        }
        .sheet(isPresented: $showAddEntry) {
            AddEntryView()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: RootView.Tab
    @Binding var showAddEntry: Bool

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "house.fill", label: "首页", tab: .home, selected: $selectedTab)
            TabBarItem(icon: "map.fill", label: "地图", tab: .map, selected: $selectedTab)

            Button {
                showAddEntry = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.wandrInk)
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.wandrCream)
                }
            }
            .offset(y: -12)
            .frame(maxWidth: .infinity)

            TabBarItem(icon: "bookmark.fill", label: "收藏", tab: .collection, selected: $selectedTab)
            TabBarItem(icon: "person.fill", label: "我的", tab: .profile, selected: $selectedTab)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea()
        )
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let tab: RootView.Tab
    @Binding var selected: RootView.Tab

    var isSelected: Bool { selected == tab }

    var body: some View {
        Button {
            selected = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .wandrAccent : .wandrMuted)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .wandrAccent : .wandrMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
SWIFT_EOF

# ── Entry.swift ──
cat > "$TARGET/Entry.swift" << 'SWIFT_EOF'
import SwiftData
import Foundation
import CoreLocation

@Model
final class Entry {
    var id: UUID
    var name: String
    var category: PlaceCategory
    var note: String
    var mood: Mood
    var rating: Int
    var city: String
    var country: String
    var latitude: Double?
    var longitude: Double?
    var photoFilenames: [String]
    var isFavorite: Bool
    var visitedAt: Date
    var createdAt: Date
    @Relationship(deleteRule: .nullify, inverse: \Tag.entries)
    var tags: [Tag]

    init(
        name: String,
        category: PlaceCategory,
        note: String = "",
        mood: Mood = .relaxed,
        rating: Int = 4,
        city: String = "",
        country: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        photoFilenames: [String] = [],
        isFavorite: Bool = false,
        visitedAt: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.note = note
        self.mood = mood
        self.rating = rating
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.photoFilenames = photoFilenames
        self.isFavorite = isFavorite
        self.visitedAt = visitedAt
        self.createdAt = Date()
        self.tags = []
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var firstPhotoFilename: String? { photoFilenames.first }
}

enum PlaceCategory: String, CaseIterable, Codable, Identifiable {
    case cafe       = "咖啡馆"
    case museum     = "博物馆"
    case bookstore  = "书店"
    case bar        = "酒吧"
    case gallery    = "展览 / 美术馆"
    case selectShop = "买手店"
    case restaurant = "餐厅"
    case other      = "其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cafe:       return "cup.and.saucer.fill"
        case .museum:     return "building.columns.fill"
        case .bookstore:  return "books.vertical.fill"
        case .bar:        return "wineglass.fill"
        case .gallery:    return "photo.artframe"
        case .selectShop: return "bag.fill"
        case .restaurant: return "fork.knife"
        case .other:      return "mappin.fill"
        }
    }

    var emoji: String {
        switch self {
        case .cafe:       return "☕"
        case .museum:     return "🏛"
        case .bookstore:  return "📚"
        case .bar:        return "🍸"
        case .gallery:    return "🖼"
        case .selectShop: return "🛍"
        case .restaurant: return "🍽"
        case .other:      return "📍"
        }
    }
}

enum Mood: String, CaseIterable, Codable {
    case loved   = "loved"
    case relaxed = "relaxed"
    case amazed  = "amazed"
    case neutral = "neutral"
    case tired   = "tired"

    var emoji: String {
        switch self {
        case .loved:   return "😍"
        case .relaxed: return "😌"
        case .amazed:  return "🤩"
        case .neutral: return "😐"
        case .tired:   return "😴"
        }
    }

    var label: String {
        switch self {
        case .loved:   return "很爱"
        case .relaxed: return "治愈"
        case .amazed:  return "震撼"
        case .neutral: return "一般"
        case .tired:   return "疲惫"
        }
    }
}
SWIFT_EOF

# ── Tag.swift ──
cat > "$TARGET/Tag.swift" << 'SWIFT_EOF'
import SwiftData
import Foundation

@Model
final class Tag {
    var id: UUID
    var name: String
    var entries: [Entry]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.entries = []
    }
}
SWIFT_EOF

# ── PhotoRepository.swift ──
cat > "$TARGET/PhotoRepository.swift" << 'SWIFT_EOF'
import UIKit
import Foundation

final class PhotoRepository {

    static let shared = PhotoRepository()
    private init() { createDirectoryIfNeeded() }

    var photosDirectory: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("photos", isDirectory: true)
    }

    private func createDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(
            at: photosDirectory,
            withIntermediateDirectories: true
        )
    }

    func save(_ images: [UIImage]) throws -> [String] {
        try images.map { image in
            let filename = UUID().uuidString + ".jpg"
            let url = photosDirectory.appendingPathComponent(filename)
            let resized = image.resized(maxDimension: 1200)
            guard let data = resized.jpegData(compressionQuality: 0.85) else {
                throw PhotoError.compressionFailed
            }
            try data.write(to: url)
            return filename
        }
    }

    func load(_ filename: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    func loadAll(_ filenames: [String]) -> [UIImage] {
        filenames.compactMap { load($0) }
    }

    func delete(_ filenames: [String]) {
        filenames.forEach { filename in
            let url = photosDirectory.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)
        }
    }

    var totalSizeBytes: Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: photosDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        return files.reduce(0) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return sum + Int64(size)
        }
    }

    var totalSizeFormatted: String {
        let bytes = Double(totalSizeBytes)
        if bytes < 1_000_000 { return String(format: "%.1f KB", bytes / 1000) }
        return String(format: "%.1f MB", bytes / 1_000_000)
    }
}

enum PhotoError: LocalizedError {
    case compressionFailed
    var errorDescription: String? { "照片压缩失败" }
}

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        guard max(size.width, size.height) > maxDimension else { return self }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
SWIFT_EOF

# ── LocationManager.swift ──
cat > "$TARGET/LocationManager.swift" << 'SWIFT_EOF'
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {

    static let shared = LocationManager()

    @Published var city: String = ""
    @Published var country: String = ""
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let placemark = placemarks?.first else { return }
            Task { @MainActor in
                self.city = placemark.locality ?? ""
                self.country = placemark.country ?? ""
                self.coordinate = location.coordinate
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse {
                manager.requestLocation()
            }
        }
    }
}
SWIFT_EOF

# ── DesignSystem.swift ──
cat > "$TARGET/DesignSystem.swift" << 'SWIFT_EOF'
import SwiftUI

extension Color {
    static let wandrInk      = Color("WandrInk")
    static let wandrCream    = Color("WandrCream")
    static let wandrAccent   = Color("WandrAccent")
    static let wandrMuted    = Color("WandrMuted")
    static let wandrWarm     = Color("WandrWarm")
    static let wandrBlush    = Color("WandrBlush")
}

extension Font {
    static func wandrSerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Georgia", size: size).weight(weight)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
SWIFT_EOF

# ── HomeView.swift ──
cat > "$TARGET/HomeView.swift" << 'SWIFT_EOF'
import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Entry.visitedAt, order: .reverse) private var entries: [Entry]
    @State private var selectedCategory: PlaceCategory? = nil
    @State private var selectedEntry: Entry? = nil

    var filteredEntries: [Entry] {
        guard let cat = selectedCategory else { return entries }
        return entries.filter { $0.category == cat }
    }

    var uniqueCities: Int {
        Set(entries.map { $0.city }.filter { !$0.isEmpty }).count
    }

    var uniqueCountries: Int {
        Set(entries.map { $0.country }.filter { !$0.isEmpty }).count
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    statsSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                    categoryFilter
                        .padding(.bottom, 20)

                    if filteredEntries.isEmpty {
                        emptyState
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                    } else {
                        entriesGrid
                            .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 100)
                }
            }
            .background(Color.wandrWarm)
            .navigationDestination(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("✦ WANDR")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundColor(.wandrAccent)
            Text("Hello,\nExplorer.")
                .font(.wandrSerif(36))
                .foregroundColor(.wandrInk)
                .lineSpacing(2)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatPill(value: "\(entries.count)", label: "打卡")
            StatPill(value: "\(uniqueCities)", label: "城市")
            StatPill(value: "\(uniqueCountries)", label: "国家")
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(label: "全部", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(PlaceCategory.allCases) { cat in
                    CategoryChip(
                        label: "\(cat.emoji) \(cat.rawValue)",
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var entriesGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(filteredEntries) { entry in
                EntryCard(entry: entry)
                    .onTapGesture { selectedEntry = entry }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("✈️").font(.system(size: 48))
            Text("还没有打卡记录").font(.wandrSerif(20)).foregroundColor(.wandrInk)
            Text("点击下方 + 开始记录你的第一个探店")
                .font(.system(size: 14))
                .foregroundColor(.wandrMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.wandrSerif(24, weight: .bold))
                .foregroundColor(.wandrInk)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(.wandrMuted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.7))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.wandrBlush, lineWidth: 1))
    }
}

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .wandrInk : .wandrMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color.wandrAccent : Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color.wandrBlush, lineWidth: 1))
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
SWIFT_EOF

# ── EntryCard.swift ──
cat > "$TARGET/EntryCard.swift" << 'SWIFT_EOF'
import SwiftUI

struct EntryCard: View {
    let entry: Entry
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img = thumbnail {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    categoryGradient
                }
            }
            .frame(height: 200)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center, endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.category.emoji) \(entry.category.rawValue)")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Capsule())

                Text(entry.name)
                    .font(.wandrSerif(15))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !entry.city.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin.fill").font(.system(size: 9))
                        Text([entry.city, entry.country].filter { !$0.isEmpty }.joined(separator: ", "))
                            .font(.system(size: 11)).lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .task {
            if let filename = entry.firstPhotoFilename {
                thumbnail = await Task.detached { PhotoRepository.shared.load(filename) }.value
            }
        }
    }

    private var categoryGradient: some View {
        Rectangle().fill(
            LinearGradient(colors: categoryColors(for: entry.category),
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private func categoryColors(for category: PlaceCategory) -> [Color] {
        switch category {
        case .cafe:       return [Color(hex:"3D2010"), Color(hex:"8B6040")]
        case .museum:     return [Color(hex:"1A2A3D"), Color(hex:"4A6A8A")]
        case .bar:        return [Color(hex:"2A1A3D"), Color(hex:"6A4A7A")]
        case .bookstore:  return [Color(hex:"3A2A1A"), Color(hex:"7A5C3E")]
        case .gallery:    return [Color(hex:"3A2010"), Color(hex:"C4956A")]
        case .selectShop: return [Color(hex:"1A1A2A"), Color(hex:"4A4A6A")]
        case .restaurant: return [Color(hex:"1A3020"), Color(hex:"4A7A5A")]
        case .other:      return [Color(hex:"2A2A2A"), Color(hex:"6A6A6A")]
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
SWIFT_EOF

# ── EntryDetailView.swift ──
cat > "$TARGET/EntryDetailView.swift" << 'SWIFT_EOF'
import SwiftUI
import SwiftData
import MapKit

struct EntryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: Entry

    @State private var photos: [UIImage] = []
    @State private var selectedPhotoIndex = 0
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                photoCarousel.frame(height: 320)

                VStack(alignment: .leading, spacing: 20) {
                    titleSection
                    Divider().foregroundColor(.wandrBlush)
                    if !entry.note.isEmpty { noteSection }
                    if !entry.tags.isEmpty { tagsSection }
                    infoGrid
                    if entry.coordinate != nil { mapSnippet }
                    Spacer(minLength: 100)
                }
                .padding(24)
            }
        }
        .background(Color.wandrWarm)
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) { backButton }
        .overlay(alignment: .topTrailing) { menuButton }
        .alert("删除这条打卡？", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) { deleteEntry() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作无法撤销，照片也会一并删除。")
        }
        .sheet(isPresented: $showEditSheet) { AddEntryView(editingEntry: entry) }
        .task { await loadPhotos() }
    }

    private var photoCarousel: some View {
        ZStack {
            if photos.isEmpty {
                LinearGradient(colors: categoryColors(for: entry.category),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { idx, img in
                        Image(uiImage: img).resizable().scaledToFill().clipped().tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(entry.category.emoji) \(entry.category.rawValue)")
                    .font(.system(size: 11, weight: .semibold)).tracking(0.5)
                    .foregroundColor(.wandrAccent)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Color.wandrBlush).clipShape(Capsule())
                Spacer()
                Button { entry.isFavorite.toggle() } label: {
                    Image(systemName: entry.isFavorite ? "bookmark.fill" : "bookmark")
                        .foregroundColor(entry.isFavorite ? .wandrAccent : .wandrMuted)
                        .font(.system(size: 20))
                }
            }
            Text(entry.name).font(.wandrSerif(28)).foregroundColor(.wandrInk)
            HStack(spacing: 16) {
                if !entry.city.isEmpty {
                    Label([entry.city, entry.country].filter { !$0.isEmpty }.joined(separator: ", "),
                          systemImage: "mappin.fill")
                        .font(.system(size: 13)).foregroundColor(.wandrMuted)
                }
                Label(entry.visitedAt.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar")
                    .font(.system(size: 13)).foregroundColor(.wandrMuted)
            }
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= entry.rating ? "star.fill" : "star")
                        .foregroundColor(star <= entry.rating ? .wandrAccent : .wandrBlush)
                        .font(.system(size: 16))
                }
                Text(entry.mood.emoji).font(.system(size: 18)).padding(.leading, 8)
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("我的笔记", systemImage: "pencil")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundColor(.wandrMuted).textCase(.uppercase)
            Text(entry.note)
                .font(.system(size: 15)).foregroundColor(.wandrInk)
                .lineSpacing(6).italic()
                .padding(16).background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var tagsSection: some View {
        FlowLayout(spacing: 6) {
            ForEach(entry.tags) { tag in
                Text("#\(tag.name)").font(.system(size: 12, weight: .medium))
                    .foregroundColor(.wandrAccent)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.wandrBlush).clipShape(Capsule())
            }
        }
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            InfoCard(label: "心情", value: "\(entry.mood.emoji) \(entry.mood.label)")
            InfoCard(label: "评分", value: "\(entry.rating) / 5 ⭐")
            if !entry.city.isEmpty { InfoCard(label: "城市", value: entry.city) }
            if !entry.country.isEmpty { InfoCard(label: "国家", value: entry.country) }
        }
    }

    private var mapSnippet: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("位置", systemImage: "map.fill")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundColor(.wandrMuted).textCase(.uppercase)
            if let coord = entry.coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))) {
                    Annotation(entry.name, coordinate: coord) {
                        ZStack {
                            Circle().fill(Color.wandrAccent).frame(width: 28, height: 28)
                            Text(entry.category.emoji).font(.system(size: 14))
                        }
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .allowsHitTesting(false)
            }
        }
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                .frame(width: 36, height: 36).background(.black.opacity(0.35)).clipShape(Circle())
        }
        .padding(.leading, 20).padding(.top, 56)
    }

    private var menuButton: some View {
        Menu {
            Button { showEditSheet = true } label: { Label("编辑", systemImage: "pencil") }
            Button(role: .destructive) { showDeleteAlert = true } label: { Label("删除", systemImage: "trash") }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                .frame(width: 36, height: 36).background(.black.opacity(0.35)).clipShape(Circle())
        }
        .padding(.trailing, 20).padding(.top, 56)
    }

    private func deleteEntry() {
        PhotoRepository.shared.delete(entry.photoFilenames)
        context.delete(entry)
        dismiss()
    }

    private func loadPhotos() async {
        let filenames = entry.photoFilenames
        let loaded = await Task.detached { PhotoRepository.shared.loadAll(filenames) }.value
        photos = loaded
    }

    private func categoryColors(for category: PlaceCategory) -> [Color] {
        switch category {
        case .cafe:       return [Color(hex:"3D2010"), Color(hex:"8B6040")]
        case .museum:     return [Color(hex:"1A2A3D"), Color(hex:"4A6A8A")]
        case .bar:        return [Color(hex:"2A1A3D"), Color(hex:"6A4A7A")]
        case .bookstore:  return [Color(hex:"3A2A1A"), Color(hex:"7A5C3E")]
        case .gallery:    return [Color(hex:"3A2010"), Color(hex:"C4956A")]
        case .selectShop: return [Color(hex:"1A1A2A"), Color(hex:"4A4A6A")]
        case .restaurant: return [Color(hex:"1A3020"), Color(hex:"4A7A5A")]
        case .other:      return [Color(hex:"2A2A2A"), Color(hex:"6A6A6A")]
        }
    }
}

struct InfoCard: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 10, weight: .semibold)).tracking(0.8)
                .foregroundColor(.wandrMuted).textCase(.uppercase)
            Text(value).font(.system(size: 14, weight: .medium)).foregroundColor(.wandrInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
            .reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentWidth += size.width + spacing
        }
        return rows
    }
}
SWIFT_EOF

# ── AddEntryView.swift ──
cat > "$TARGET/AddEntryView.swift" << 'SWIFT_EOF'
import SwiftUI
import SwiftData
import PhotosUI

struct AddEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared

    var editingEntry: Entry? = nil

    @State private var name: String = ""
    @State private var category: PlaceCategory = .cafe
    @State private var note: String = ""
    @State private var mood: Mood = .relaxed
    @State private var rating: Int = 4
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var visitedAt: Date = Date()
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var isEditing: Bool { editingEntry != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    photoSection
                    categorySection
                    basicInfoSection
                    locationSection
                    ratingMoodSection
                    noteSection
                    tagsSection
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color.wandrWarm)
            .navigationTitle(isEditing ? "编辑打卡" : "新建打卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }.foregroundColor(.wandrMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await save() } } label: {
                        if isSaving {
                            ProgressView().tint(.wandrInk)
                        } else {
                            Text("保存").font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16).padding(.vertical, 7)
                                .background(name.isEmpty ? Color.wandrMuted : Color.wandrInk)
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .alert("保存失败", isPresented: $showError) {
                Button("好") {}
            } message: { Text(errorMessage) }
        }
        .onAppear { populateIfEditing() }
        .onChange(of: selectedItems) { _, items in Task { await loadSelectedPhotos(items) } }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("照片")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, img in
                        photoThumb(img, index: idx)
                    }
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.wandrBlush.opacity(0.5))
                                .frame(width: 90, height: 90)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.wandrAccent.opacity(0.5),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [5])))
                            VStack(spacing: 4) {
                                Image(systemName: "plus").font(.system(size: 20))
                                Text("添加").font(.system(size: 11))
                            }
                            .foregroundColor(.wandrAccent)
                        }
                    }
                }
            }
        }
    }

    private func photoThumb(_ image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image).resizable().scaledToFill()
                .frame(width: 90, height: 90).clipShape(RoundedRectangle(cornerRadius: 14))
            Button { selectedImages.remove(at: index) } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 18))
                    .foregroundColor(.white).shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("类型")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(PlaceCategory.allCases) { cat in
                    Button { category = cat } label: {
                        VStack(spacing: 6) {
                            Text(cat.emoji).font(.system(size: 22))
                            Text(cat.rawValue).font(.system(size: 10, weight: .medium))
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .foregroundColor(category == cat ? .white : .wandrInk)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(category == cat ? Color.wandrInk : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(category == cat ? Color.clear : Color.wandrBlush, lineWidth: 1))
                    }
                    .animation(.easeInOut(duration: 0.15), value: category)
                }
            }
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("名称")
            TextField("店名或地点", text: $name).textFieldStyle(WandrTextFieldStyle())
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("位置")
                Spacer()
                Button { locationManager.requestLocation() } label: {
                    Label("自动定位", systemImage: "location.fill")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(.wandrAccent)
                }
            }
            HStack(spacing: 10) {
                TextField("城市", text: $city).textFieldStyle(WandrTextFieldStyle())
                TextField("国家", text: $country).textFieldStyle(WandrTextFieldStyle())
            }
            DatePicker("探访日期", selection: $visitedAt, displayedComponents: .date)
                .font(.system(size: 14)).tint(.wandrAccent)
        }
        .onChange(of: locationManager.city) { _, val in if !val.isEmpty { city = val } }
        .onChange(of: locationManager.country) { _, val in if !val.isEmpty { country = val } }
    }

    private var ratingMoodSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("评分")
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { star in
                        Button { rating = star } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(star <= rating ? .wandrAccent : .wandrBlush)
                                .font(.system(size: 22))
                        }
                        .animation(.spring(duration: 0.2), value: rating)
                    }
                }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("心情")
                HStack(spacing: 8) {
                    ForEach(Mood.allCases, id: \.self) { m in
                        Button { mood = m } label: {
                            Text(m.emoji).font(.system(size: 22))
                                .padding(6)
                                .background(mood == m ? Color.wandrBlush : Color.clear)
                                .clipShape(Circle())
                        }
                        .animation(.easeInOut(duration: 0.15), value: mood)
                    }
                }
            }
        }
        .padding(16).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("我的感受")
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("写下你的感受，只给自己看...")
                        .font(.system(size: 14)).foregroundColor(.wandrMuted)
                        .padding(.horizontal, 16).padding(.top, 14)
                }
                TextEditor(text: $note).font(.system(size: 14)).foregroundColor(.wandrInk)
                    .frame(minHeight: 100).scrollContentBackground(.hidden).padding(10)
            }
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.wandrBlush, lineWidth: 1))
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("标签")
            HStack {
                TextField("添加标签，按回车确认", text: $tagInput)
                    .textFieldStyle(WandrTextFieldStyle()).onSubmit { addTag() }
                Button("添加") { addTag() }
                    .foregroundColor(.wandrAccent).font(.system(size: 14, weight: .medium))
            }
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)").font(.system(size: 12, weight: .medium)).foregroundColor(.wandrAccent)
                            Button { tags.removeAll { $0 == tag } } label: {
                                Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(.wandrMuted)
                            }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.wandrBlush).clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .semibold)).tracking(1)
            .foregroundColor(.wandrMuted).textCase(.uppercase)
    }

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tags.contains(trimmed) { tags.append(trimmed) }
        tagInput = ""
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) { images.append(img) }
        }
        selectedImages = images
    }

    private func populateIfEditing() {
        guard let entry = editingEntry else { return }
        name = entry.name; category = entry.category; note = entry.note
        mood = entry.mood; rating = entry.rating; city = entry.city
        country = entry.country; visitedAt = entry.visitedAt
        tags = entry.tags.map { $0.name }
        Task {
            let loaded = await Task.detached { PhotoRepository.shared.loadAll(entry.photoFilenames) }.value
            selectedImages = loaded
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let newFilenames = try PhotoRepository.shared.save(selectedImages)
            if let entry = editingEntry {
                PhotoRepository.shared.delete(entry.photoFilenames)
                entry.name = name; entry.category = category; entry.note = note
                entry.mood = mood; entry.rating = rating; entry.city = city
                entry.country = country; entry.visitedAt = visitedAt
                entry.photoFilenames = newFilenames; entry.tags = resolveTags()
            } else {
                let entry = Entry(name: name, category: category, note: note, mood: mood,
                                  rating: rating, city: city, country: country,
                                  latitude: LocationManager.shared.coordinate?.latitude,
                                  longitude: LocationManager.shared.coordinate?.longitude,
                                  photoFilenames: newFilenames, visitedAt: visitedAt)
                entry.tags = resolveTags()
                context.insert(entry)
            }
            try context.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription; showError = true
        }
    }

    @MainActor
    private func resolveTags() -> [Tag] {
        tags.map { tagName in
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == tagName })
            if let existing = try? context.fetch(descriptor).first { return existing }
            let newTag = Tag(name: tagName); context.insert(newTag); return newTag
        }
    }
}

struct WandrTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.font(.system(size: 14)).foregroundColor(Color.wandrInk)
            .padding(.horizontal, 16).padding(.vertical, 13)
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.wandrBlush, lineWidth: 1))
    }
}
SWIFT_EOF

# ── MapTabView.swift ──
cat > "$TARGET/MapTabView.swift" << 'SWIFT_EOF'
import SwiftUI
import SwiftData
import MapKit

struct MapTabView: View {
    @Query(sort: \Entry.visitedAt, order: .reverse) private var entries: [Entry]
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedEntry: Entry? = nil
    @State private var selectedCategory: PlaceCategory? = nil
    @State private var showDetail = false

    var filteredEntries: [Entry] {
        let geoEntries = entries.filter { $0.latitude != nil && $0.longitude != nil }
        guard let cat = selectedCategory else { return geoEntries }
        return geoEntries.filter { $0.category == cat }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position, selection: $selectedEntry) {
                ForEach(filteredEntries) { entry in
                    if let coord = entry.coordinate {
                        Annotation(entry.name, coordinate: coord, anchor: .bottom) {
                            EntryMapPin(entry: entry, isSelected: selectedEntry?.id == entry.id)
                        }
                        .tag(entry)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .all)
            .onChange(of: selectedEntry) { _, entry in if entry != nil { showDetail = true } }

            VStack(spacing: 10) {
                HStack {
                    Text("地图").font(.wandrSerif(22)).foregroundColor(.wandrInk)
                    Spacer()
                    Text("\(filteredEntries.count) 个打卡").font(.system(size: 13)).foregroundColor(.wandrMuted)
                }
                .padding(.horizontal, 20).padding(.top, 60)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(label: "全部", isSelected: selectedCategory == nil) { selectedCategory = nil }
                        ForEach(PlaceCategory.allCases) { cat in
                            CategoryChip(label: "\(cat.emoji) \(cat.rawValue)", isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(LinearGradient(colors: [Color.wandrWarm, Color.wandrWarm.opacity(0)],
                                       startPoint: .top, endPoint: .bottom).ignoresSafeArea())

            if filteredEntries.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("🗺").font(.system(size: 40))
                        Text("暂无地图打卡").font(.wandrSerif(16)).foregroundColor(.wandrInk)
                        Text("打卡时开启定位，记录就会出现在地图上")
                            .font(.system(size: 13)).foregroundColor(.wandrMuted).multilineTextAlignment(.center)
                    }
                    .padding(24).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 20)).padding(40)
                    Spacer()
                }
            }
        }
        .navigationDestination(isPresented: $showDetail) {
            if let entry = selectedEntry {
                EntryDetailView(entry: entry).onDisappear { selectedEntry = nil }
            }
        }
    }
}

struct EntryMapPin: View {
    let entry: Entry
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Capsule().fill(isSelected ? Color.wandrInk : Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                HStack(spacing: 4) {
                    Text(entry.category.emoji).font(.system(size: 12))
                    if isSelected {
                        Text(entry.name).font(.system(size: 11, weight: .medium))
                            .foregroundColor(.wandrCream).lineLimit(1)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
            }
            .frame(height: 30)
            Circle().fill(isSelected ? Color.wandrInk : Color.white)
                .frame(width: 6, height: 6).shadow(color: .black.opacity(0.15), radius: 1)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}
SWIFT_EOF

# ── CollectionView.swift ──
cat > "$TARGET/CollectionView.swift" << 'SWIFT_EOF'
import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query(sort: \Entry.visitedAt, order: .reverse) private var entries: [Entry]
    @State private var viewMode: ViewMode = .category
    @State private var selectedEntry: Entry? = nil

    enum ViewMode: String, CaseIterable {
        case category = "品类"
        case country  = "国家"
        case favorite = "收藏"
    }

    var favoriteEntries: [Entry] { entries.filter { $0.isFavorite } }

    var entriesByCategory: [PlaceCategory: [Entry]] {
        Dictionary(grouping: entries, by: { $0.category })
    }

    var entriesByCountry: [String: [Entry]] {
        Dictionary(grouping: entries.filter { !$0.country.isEmpty }, by: { $0.country })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("收藏").font(.wandrSerif(28)).foregroundColor(.wandrInk)
                        .padding(.horizontal, 24).padding(.top, 20)
                    Picker("视图", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).padding(.horizontal, 24)
                }
                .padding(.bottom, 16).background(Color.wandrWarm)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        switch viewMode {
                        case .category: categorySection
                        case .country:  countrySection
                        case .favorite: favoriteSection
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16).padding(.top, 8)
                }
                .background(Color.wandrWarm)
            }
            .navigationDestination(item: $selectedEntry) { EntryDetailView(entry: $0) }
        }
    }

    private var categorySection: some View {
        VStack(spacing: 16) {
            ForEach(PlaceCategory.allCases) { cat in
                let catEntries = entriesByCategory[cat] ?? []
                if !catEntries.isEmpty {
                    CategoryGroupCard(category: cat, entries: catEntries) { selectedEntry = $0 }
                }
            }
        }
    }

    private var countrySection: some View {
        VStack(spacing: 16) {
            ForEach(entriesByCountry.keys.sorted(), id: \.self) { country in
                CountryGroupCard(country: country, entries: entriesByCountry[country] ?? []) { selectedEntry = $0 }
            }
            if entriesByCountry.isEmpty { emptyStateView(icon: "🌍", message: "打卡时填写城市/国家，就能在这里看到") }
        }
    }

    private var favoriteSection: some View {
        VStack(spacing: 12) {
            if favoriteEntries.isEmpty {
                emptyStateView(icon: "🔖", message: "在打卡详情页点击书签，收藏你最爱的地方").padding(.top, 40)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(favoriteEntries) { EntryCard(entry: $0).onTapGesture { selectedEntry = $0 } }
                }
            }
        }
    }

    private func emptyStateView(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Text(icon).font(.system(size: 40))
            Text(message).font(.system(size: 14)).foregroundColor(.wandrMuted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(32)
    }
}

struct CategoryGroupCard: View {
    let category: PlaceCategory
    let entries: [Entry]
    let onTap: (Entry) -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() } } label: {
                HStack {
                    HStack(spacing: 10) {
                        Text(category.emoji).font(.system(size: 22))
                        Text(category.rawValue).font(.system(size: 16, weight: .semibold)).foregroundColor(.wandrInk)
                    }
                    Spacer()
                    Text("\(entries.count)").font(.system(size: 13, weight: .medium)).foregroundColor(.wandrMuted)
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium))
                        .foregroundColor(.wandrMuted).rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }
            if isExpanded {
                Divider().padding(.horizontal, 16)
                VStack(spacing: 0) {
                    ForEach(entries.prefix(5)) { entry in
                        Button { onTap(entry) } label: { EntryRowItem(entry: entry) }
                        if entry.id != entries.prefix(5).last?.id { Divider().padding(.horizontal, 16) }
                    }
                    if entries.count > 5 {
                        Text("查看全部 \(entries.count) 条").font(.system(size: 13))
                            .foregroundColor(.wandrAccent).frame(maxWidth: .infinity).padding(14)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
    }
}

struct CountryGroupCard: View {
    let country: String
    let entries: [Entry]
    let onTap: (Entry) -> Void
    @State private var isExpanded = false

    var cities: String {
        Array(Set(entries.map { $0.city }.filter { !$0.isEmpty })).prefix(3).joined(separator: "、")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() } } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(country).font(.system(size: 16, weight: .semibold)).foregroundColor(.wandrInk)
                        if !cities.isEmpty { Text(cities).font(.system(size: 12)).foregroundColor(.wandrMuted) }
                    }
                    Spacer()
                    Text("\(entries.count) 个打卡").font(.system(size: 12)).foregroundColor(.wandrMuted)
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.wandrMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }
            if isExpanded {
                Divider().padding(.horizontal, 16)
                ForEach(entries.prefix(5)) { entry in
                    Button { onTap(entry) } label: { EntryRowItem(entry: entry) }
                    if entry.id != entries.prefix(5).last?.id { Divider().padding(.horizontal, 16) }
                }
            }
        }
        .cardStyle()
    }
}

struct EntryRowItem: View {
    let entry: Entry
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let img = thumbnail {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Rectangle().fill(LinearGradient(colors: [Color(hex:"3A2A1A"), Color(hex:"8B6040")],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name).font(.system(size: 14, weight: .medium)).foregroundColor(.wandrInk).lineLimit(1)
                HStack(spacing: 8) {
                    Text("\(entry.category.emoji) \(entry.city)").font(.system(size: 12)).foregroundColor(.wandrMuted)
                    Text(entry.visitedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12)).foregroundColor(.wandrMuted)
                }
            }
            Spacer()
            HStack(spacing: 1) {
                ForEach(1...5, id: \.self) { s in
                    Image(systemName: s <= entry.rating ? "star.fill" : "star").font(.system(size: 9))
                        .foregroundColor(s <= entry.rating ? .wandrAccent : .wandrBlush)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12).contentShape(Rectangle())
        .task {
            if let filename = entry.firstPhotoFilename {
                thumbnail = await Task.detached { PhotoRepository.shared.load(filename) }.value
            }
        }
    }
}
SWIFT_EOF

# ── ProfileView.swift ──
cat > "$TARGET/ProfileView.swift" << 'SWIFT_EOF'
import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var entries: [Entry]
    @State private var showExportSheet = false
    @State private var showAbout = false

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
            .background(Color.wandrWarm)
            .sheet(isPresented: $showExportSheet) { ExportView() }
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
            Text("我的手账").font(.wandrSerif(24)).foregroundColor(.wandrInk)
            Text("记录每一个值得被记住的角落").font(.system(size: 13)).foregroundColor(.wandrMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var bigStatsRow: some View {
        HStack(spacing: 12) {
            BigStatCard(value: "\(entries.count)", label: "打卡总数", icon: "mappin.fill")
            BigStatCard(value: "\(uniqueCities.count)", label: "城市", icon: "building.2.fill")
            BigStatCard(value: "\(uniqueCountries.count)", label: "国家", icon: "globe.asia.australia.fill")
        }
    }

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("品类分布").font(.system(size: 13, weight: .semibold)).tracking(0.5)
                .foregroundColor(.wandrMuted).textCase(.uppercase)
            ForEach(categoryBreakdown, id: \.0) { (cat, count) in
                VStack(spacing: 6) {
                    HStack {
                        Text("\(cat.emoji) \(cat.rawValue)").font(.system(size: 14)).foregroundColor(.wandrInk)
                        Spacer()
                        Text("\(count)").font(.system(size: 13, weight: .medium)).foregroundColor(.wandrMuted)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.wandrBlush).frame(height: 5)
                            Capsule().fill(Color.wandrAccent)
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
                .tracking(0.5).foregroundColor(.wandrMuted).textCase(.uppercase)
            FlowLayout(spacing: 8) {
                ForEach(uniqueCountries, id: \.self) { country in
                    Text(country).font(.system(size: 13, weight: .medium)).foregroundColor(.wandrInk)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.wandrBlush).clipShape(Capsule())
                }
            }
        }
        .padding(20).cardStyle()
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("存储").font(.system(size: 13, weight: .semibold)).tracking(0.5)
                .foregroundColor(.wandrMuted).textCase(.uppercase)
            HStack {
                Label("照片占用空间", systemImage: "photo.stack.fill").font(.system(size: 14)).foregroundColor(.wandrInk)
                Spacer()
                Text(PhotoRepository.shared.totalSizeFormatted).font(.system(size: 14, weight: .medium)).foregroundColor(.wandrMuted)
            }
            Text("所有数据仅保存在本设备，不上传任何服务器").font(.system(size: 12)).foregroundColor(.wandrMuted).padding(.top, 2)
        }
        .padding(20).cardStyle()
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            ActionRow(icon: "square.and.arrow.up.fill", label: "导出备份") { showExportSheet = true }
            Divider().padding(.horizontal, 16)
            ActionRow(icon: "square.and.arrow.down.fill", label: "导入备份") { showExportSheet = true }
            Divider().padding(.horizontal, 16)
            ActionRow(icon: "info.circle.fill", label: "关于 WANDR") { showAbout = true }
        }
        .cardStyle()
    }
}

struct BigStatCard: View {
    let value: String; let label: String; let icon: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(.wandrAccent)
            Text(value).font(.wandrSerif(26, weight: .bold)).foregroundColor(.wandrInk)
            Text(label).font(.system(size: 11)).foregroundColor(.wandrMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18).cardStyle()
    }
}

struct ActionRow: View {
    let icon: String; let label: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(.wandrAccent).frame(width: 24)
                Text(label).font(.system(size: 15)).foregroundColor(.wandrInk)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.wandrMuted)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
        }
    }
}

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var entries: [Entry]
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "square.and.arrow.up.fill").font(.system(size: 48)).foregroundColor(.wandrAccent)
                VStack(spacing: 8) {
                    Text("备份你的手账").font(.wandrSerif(24)).foregroundColor(.wandrInk)
                    Text("导出 .wandr 文件，包含所有打卡记录和照片\n可通过 AirDrop 或文件 App 迁移到新设备")
                        .font(.system(size: 14)).foregroundColor(.wandrMuted)
                        .multilineTextAlignment(.center).lineSpacing(4)
                }
                VStack(spacing: 10) {
                    Text("\(entries.count) 条打卡记录").font(.system(size: 15, weight: .medium)).foregroundColor(.wandrInk)
                    Text("照片占用 \(PhotoRepository.shared.totalSizeFormatted)").font(.system(size: 13)).foregroundColor(.wandrMuted)
                }
                .padding(20).background(Color.wandrBlush.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 16))
                Button {} label: {
                    Label("导出备份", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.wandrInk).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                Spacer()
            }
            .padding(24).background(Color.wandrWarm)
            .navigationTitle("导出 / 导入").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Text("✦").font(.system(size: 48)).foregroundColor(.wandrAccent)
                Text("WANDR").font(.wandrSerif(32)).foregroundColor(.wandrInk)
                Text("全球探店电子手账").font(.system(size: 16)).foregroundColor(.wandrMuted)
                Divider().padding(.horizontal, 40)
                VStack(spacing: 10) {
                    AboutRow(icon: "lock.shield.fill", text: "所有数据仅保存在你的设备")
                    AboutRow(icon: "wifi.slash", text: "完全离线可用")
                    AboutRow(icon: "person.slash.fill", text: "无账号，无追踪，无广告")
                }
                .padding(.horizontal, 32)
                Spacer()
            }
            .background(Color.wandrWarm)
            .navigationTitle("关于").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
    }
}

struct AboutRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.wandrAccent).frame(width: 24)
            Text(text).font(.system(size: 14)).foregroundColor(.wandrInk)
            Spacer()
        }
    }
}
SWIFT_EOF

echo ""
echo "✅ 所有文件同步完成！"
echo ""
echo "📁 目标路径: $TARGET"
echo "   ├── WandrApp.swift"
echo "   ├── RootView.swift"
echo "   ├── Entry.swift"
echo "   ├── Tag.swift"
echo "   ├── PhotoRepository.swift"
echo "   ├── LocationManager.swift"
echo "   ├── DesignSystem.swift"
echo "   ├── HomeView.swift"
echo "   ├── EntryCard.swift"
echo "   ├── EntryDetailView.swift"
echo "   ├── AddEntryView.swift"
echo "   ├── MapTabView.swift"
echo "   ├── CollectionView.swift"
echo "   ├── ProfileView.swift"
echo "   └── Assets.xcassets/"
echo ""
echo "⚠️  接下来在 Xcode 里："
echo "   1. 打开 WanderLog.xcodeproj"
echo "   2. 把 WanderLog/ 文件夹里的 .swift 文件拖入 Xcode 左侧文件树"
echo "   3. 把 Assets.xcassets 也拖进去（替换原有的）"
echo "   4. Signing & Capabilities 里改好 Bundle ID"
echo "   5. ⌘+R 运行 🎉"
