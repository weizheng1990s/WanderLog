import SwiftUI
import MapKit

struct EntryDetailView: View {
    let entry: Entry
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @State private var photos: [UIImage] = []
    @State private var selectedPhotoIndex = 0
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showFullMap = false
   

    // Always read from store so edits are reflected live
    private var liveEntry: Entry {
        store.entries.first { $0.id == entry.id } ?? entry
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                photoCarousel.frame(height: 320)

                VStack(alignment: .leading, spacing: 20) {
                    titleSection
                    Divider().foregroundColor(.wanderBlush)
                    if !liveEntry.tags.isEmpty { tagsSection }
                    infoGrid
                    if !liveEntry.note.isEmpty { noteSection }
                    if liveEntry.coordinate != nil { mapSnippet }
                    Spacer(minLength: 100)
                }
                .padding(24)
            }
        }
        .background(Color.wanderWarm)
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) { backButton }
        .overlay(alignment: .topTrailing) { menuButton }
        .alert(lang.s.deleteEntryTitle, isPresented: $showDeleteAlert) {
            Button(lang.s.delete, role: .destructive) { deleteEntry() }
            Button(lang.s.cancel, role: .cancel) {}
        } message: {
            Text(lang.s.deleteEntryMessage)
        }
        .sheet(isPresented: $showEditSheet) { AddEntryView(editingEntry: liveEntry) }
        .task { await loadPhotos() }
    }

    private var photoCarousel: some View {
        ZStack {
            if photos.isEmpty {
                LinearGradient(colors: categoryColors(for: liveEntry.category),
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
                HStack(spacing: 4) {
                    Image(systemName: store.categoryIcon(for: liveEntry)).font(.system(size: 11))
                    Text(store.categoryDisplayName(for: liveEntry, lang: lang.language))
                }
                .font(.system(size: 11, weight: .semibold)).tracking(0.5)
                .foregroundColor(.wanderAccent)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Color.wanderBlush).clipShape(Capsule())
                Spacer()
                Button {
                    var updated = liveEntry
                    updated.isFavorite.toggle()
                    store.update(updated)
                } label: {
                    Image(systemName: liveEntry.isFavorite ? "bookmark.fill" : "bookmark")
                        .foregroundColor(liveEntry.isFavorite ? .wanderAccent : .wanderMuted)
                        .font(.system(size: 20))
                }
            }
            Text(liveEntry.name).font(.wanderSerif(28)).foregroundColor(.wanderInk)
            HStack(spacing: 16) {
                if !liveEntry.city.isEmpty {
                    Label([liveEntry.city, liveEntry.country].filter { !$0.isEmpty }.joined(separator: ", "),
                          systemImage: "mappin.circle.fill")
                        .font(.system(size: 13)).foregroundColor(.wanderMuted)
                }
                Label(liveEntry.visitedAt.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar")
                    .font(.system(size: 13)).foregroundColor(.wanderMuted)
            }
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= liveEntry.rating ? "star.fill" : "star")
                        .foregroundColor(star <= liveEntry.rating ? .wanderAccent : .wanderBlush)
                        .font(.system(size: 16))
                }
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lang.s.myNotes)
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundColor(.wanderMuted).textCase(.uppercase)
            Text(liveEntry.note)
                .font(.system(size: 14)).foregroundColor(.wanderInk)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16).background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.wanderBlush, lineWidth: 1))
        }
    }

    private var tagsSection: some View {
        FlowLayout(spacing: 6) {
            ForEach(liveEntry.tags, id: \.self) { tag in
                Text("#\(tag)").font(.system(size: 12, weight: .medium))
                    .foregroundColor(.wanderAccent)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.wanderBlush).clipShape(Capsule())
            }
        }
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            if !liveEntry.city.isEmpty { InfoCard(label: lang.s.city, value: liveEntry.city) }
            if !liveEntry.country.isEmpty { InfoCard(label: lang.s.country, value: liveEntry.country) }
        }
    }

    private var mapSnippet: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(lang.s.location, systemImage: "map.fill")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundColor(.wanderMuted).textCase(.uppercase)
            if let coord = liveEntry.coordinate {
                let region = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                Button { showFullMap = true } label: {
                    ZStack(alignment: .bottomTrailing) {
                        Map(coordinateRegion: .constant(region),
                            annotationItems: [liveEntry]) { e in
                            MapAnnotation(coordinate: coord) {
                                ZStack {
                                    Circle().fill(Color.wanderAccent).frame(width: 28, height: 28)
                                    Image(systemName: store.categoryIcon(for: liveEntry))
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .allowsHitTesting(false)

                        // 右下角提示
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 10, weight: .medium))
                            Text("全屏查看")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.black.opacity(0.45))
                        .clipShape(Capsule())
                        .padding(10)
                    }
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showFullMap) {
                    FullMapView(entry: liveEntry, categoryIcon: store.categoryIcon(for: liveEntry))
                }
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
            Button { showEditSheet = true } label: { Label(lang.s.edit, systemImage: "pencil") }
            Button(role: .destructive) { showDeleteAlert = true } label: { Label(lang.s.delete, systemImage: "trash") }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                .frame(width: 36, height: 36).background(.black.opacity(0.35)).clipShape(Circle())
        }
        .padding(.trailing, 20).padding(.top, 56)
    }

    private func deleteEntry() {
        store.delete(liveEntry)
        dismiss()
    }

    private func loadPhotos() async {
        let filenames = liveEntry.photoFilenames
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
                .foregroundColor(.wanderMuted).textCase(.uppercase)
            Text(value).font(.system(size: 14, weight: .medium)).foregroundColor(.wanderInk)
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
