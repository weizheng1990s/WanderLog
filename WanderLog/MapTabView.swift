import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30.0, longitude: 105.0),
        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
    )
    @State private var selectedEntry: Entry? = nil
    @State private var selectedCategory: CategorySelection? = nil
    @State private var showDetail = false

    var entries: [Entry] {
        store.entries.sorted { $0.visitedAt > $1.visitedAt }
    }

    var filteredEntries: [Entry] {
        let geoEntries = entries.filter { $0.latitude != nil && $0.longitude != nil }
        guard let sel = selectedCategory else { return geoEntries }
        switch sel {
        case .standard(let cat):
            return geoEntries.filter { $0.category == cat && $0.customCategoryID == nil }
        case .custom(let id):
            return geoEntries.filter { $0.customCategoryID == id }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    annotationItems: filteredEntries) { entry in
                    MapAnnotation(coordinate: entry.coordinate!) {
                        EntryMapPin(
                            entry: entry,
                            isSelected: selectedEntry?.id == entry.id,
                            categoryIcon: store.categoryIcon(for: entry)
                        )
                        .onTapGesture {
                            selectedEntry = entry
                            showDetail = true
                        }
                    }
                }
                .ignoresSafeArea(edges: .all)

                VStack(spacing: 10) {
                    HStack {
                        Text(lang.s.mapTitle).font(.wanderSerif(22)).foregroundColor(.wanderInk)
                        Spacer()
                        Text(lang.s.entriesCount(filteredEntries.count)).font(.system(size: 13)).foregroundColor(.wanderMuted)
                    }
                    .padding(.horizontal, 20).padding(.top, 60)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(label: lang.s.all, isSelected: selectedCategory == nil) { selectedCategory = nil }
                            ForEach(store.customCategories) { cat in
                                CategoryChip(icon: cat.icon, label: cat.name, isSelected: selectedCategory == .custom(cat.id)) {
                                    selectedCategory = selectedCategory == .custom(cat.id) ? nil : .custom(cat.id)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .background(LinearGradient(colors: [Color.wanderWarm, Color.wanderWarm.opacity(0)],
                                           startPoint: .top, endPoint: .bottom).ignoresSafeArea())

                if filteredEntries.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        VStack(spacing: 10) {
                            Text("🗺").font(.system(size: 40))
                            Text(lang.s.noMapEntries).font(.wanderSerif(16)).foregroundColor(.wanderInk)
                            Text(lang.s.noMapEntriesHint)
                                .font(.system(size: 13)).foregroundColor(.wanderMuted).multilineTextAlignment(.center)
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
}

struct EntryMapPin: View {
    let entry: Entry
    let isSelected: Bool
    let categoryIcon: String

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Capsule()
                    .fill(isSelected ? Color.wanderAccent : Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
                HStack(spacing: 4) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : .wanderAccent)
                    if isSelected {
                        Text(entry.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
            }
            .frame(height: 30)
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : Color.wanderAccent.opacity(0.3), lineWidth: 1)
            )
            Circle()
                .fill(isSelected ? Color.wanderAccent : Color(UIColor.systemBackground))
                .frame(width: 6, height: 6)
                .shadow(color: .black.opacity(0.2), radius: 1)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
    }
}
