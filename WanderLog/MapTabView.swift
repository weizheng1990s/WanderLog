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

    var mapPins: [MapPinData] {
        filteredEntries.compactMap { entry in
            guard let coord = entry.coordinate else { return nil }
            return MapPinData(id: entry.id, coordinate: coord,
                              icon: store.categoryIcon(for: entry), name: entry.name)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LocalizedMapView(
                    region: $region,
                    showsUserLocation: true,
                    pins: mapPins,
                    selectedID: selectedEntry?.id,
                    onPinTap: { id in
                        selectedEntry = store.entries.first { $0.id == id }
                        showDetail = true
                    }
                )
                .id(lang.language.rawValue)
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
                                CategoryChip(icon: cat.icon, label: store.displayName(for: cat, lang: lang.language), isSelected: selectedCategory == .custom(cat.id)) {
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
