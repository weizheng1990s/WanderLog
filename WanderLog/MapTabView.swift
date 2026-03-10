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
                    Text("地图").font(.wanderSerif(22)).foregroundColor(.wanderInk)
                    Spacer()
                    Text("\(filteredEntries.count) 个打卡").font(.system(size: 13)).foregroundColor(.wanderMuted)
                }
                .padding(.horizontal, 20).padding(.top, 60)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(label: "全部", isSelected: selectedCategory == nil) { selectedCategory = nil }
                        ForEach(PlaceCategory.allCases) { cat in
                            CategoryChip(label: "\(cat.icon) \(cat.rawValue)", isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
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
                        Text("暂无地图打卡").font(.wanderSerif(16)).foregroundColor(.wanderInk)
                        Text("打卡时开启定位，记录就会出现在地图上")
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

struct EntryMapPin: View {
    let entry: Entry
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Capsule().fill(isSelected ? Color.wanderInk : Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                HStack(spacing: 4) {
                    Text(entry.category.icon).font(.system(size: 12))
                    if isSelected {
                        Text(entry.name).font(.system(size: 11, weight: .medium))
                            .foregroundColor(.wanderCream).lineLimit(1)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
            }
            .frame(height: 30)
            Circle().fill(isSelected ? Color.wanderInk : Color.white)
                .frame(width: 6, height: 6).shadow(color: .black.opacity(0.15), radius: 1)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}
