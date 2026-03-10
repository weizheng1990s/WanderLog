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
                    Divider().foregroundColor(.wanderBlush)
                    if !entry.note.isEmpty { noteSection }
                    if !entry.tags.isEmpty { tagsSection }
                    infoGrid
                    if entry.coordinate != nil { mapSnippet }
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
                Text("\(entry.category.icon) \(entry.category.rawValue)")
                    .font(.system(size: 11, weight: .semibold)).tracking(0.5)
                    .foregroundColor(.wanderAccent)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Color.wanderBlush).clipShape(Capsule())
                Spacer()
                Button { entry.isFavorite.toggle() } label: {
                    Image(systemName: entry.isFavorite ? "bookmark.fill" : "bookmark")
                        .foregroundColor(entry.isFavorite ? .wanderAccent : .wanderMuted)
                        .font(.system(size: 20))
                }
            }
            Text(entry.name).font(.wanderSerif(28)).foregroundColor(.wanderInk)
            HStack(spacing: 16) {
                if !entry.city.isEmpty {
                    Label([entry.city, entry.country].filter { !$0.isEmpty }.joined(separator: ", "),
                          systemImage: "mappin.fill")
                        .font(.system(size: 13)).foregroundColor(.wanderMuted)
                }
                Label(entry.visitedAt.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar")
                    .font(.system(size: 13)).foregroundColor(.wanderMuted)
            }
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= entry.rating ? "star.fill" : "star")
                        .foregroundColor(star <= entry.rating ? .wanderAccent : .wanderBlush)
                        .font(.system(size: 16))
                }
                Text(entry.mood.icon).font(.system(size: 18)).padding(.leading, 8)
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("我的笔记", systemImage: "pencil")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundColor(.wanderMuted).textCase(.uppercase)
            Text(entry.note)
                .font(.system(size: 15)).foregroundColor(.wanderInk)
                .lineSpacing(6).italic()
                .padding(16).background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var tagsSection: some View {
        FlowLayout(spacing: 6) {
            ForEach(entry.tags) { tag in
                Text("#\(tag.name)").font(.system(size: 12, weight: .medium))
                    .foregroundColor(.wanderAccent)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.wanderBlush).clipShape(Capsule())
            }
        }
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            InfoCard(label: "心情", value: "\(entry.mood.icon) \(entry.mood.label)")
            InfoCard(label: "评分", value: "\(entry.rating) / 5 ⭐")
            if !entry.city.isEmpty { InfoCard(label: "城市", value: entry.city) }
            if !entry.country.isEmpty { InfoCard(label: "国家", value: entry.country) }
        }
    }

    private var mapSnippet: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("位置", systemImage: "map.fill")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundColor(.wanderMuted).textCase(.uppercase)
            if let coord = entry.coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))) {
                    Annotation(entry.name, coordinate: coord) {
                        ZStack {
                            Circle().fill(Color.wanderAccent).frame(width: 28, height: 28)
                            Text(entry.category.icon).font(.system(size: 14))
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
