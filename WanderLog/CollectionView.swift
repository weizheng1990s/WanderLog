import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    @State private var viewMode: ViewMode = .category
    @State private var selectedEntry: Entry? = nil
    @State private var showDetail = false

    enum ViewMode: String, CaseIterable {
        case category = "品类"
        case country  = "国家"
        case favorite = "收藏"
    }

    var entries: [Entry] {
        store.entries.sorted { $0.visitedAt > $1.visitedAt }
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
                    Text(lang.s.collectionTitle).font(.wanderSerif(28)).foregroundColor(.wanderInk)
                        .padding(.horizontal, 24).padding(.top, 20)
                    Picker("", selection: $viewMode) {
                        Text(lang.s.byCategory).tag(ViewMode.category)
                        Text(lang.s.byCountry).tag(ViewMode.country)
                        Text(lang.s.favorites).tag(ViewMode.favorite)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 16).background(Color.wanderWarm)

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
                .background(Color.wanderWarm)
            }
            .navigationDestination(isPresented: $showDetail) {
                if let entry = selectedEntry {
                    EntryDetailView(entry: entry)
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(spacing: 16) {
            ForEach(store.customCategories.filter { customCat in
                entries.contains { $0.customCategoryID == customCat.id }
            }) { customCat in
                CategoryGroupCard(
                    category: .other,
                    categoryDisplayName: store.displayName(for: customCat, lang: lang.language),
                    categoryIcon: customCat.icon,
                    entries: entries.filter { $0.customCategoryID == customCat.id }
                ) { entry in
                    selectedEntry = entry
                    showDetail = true
                }
            }
            ForEach(PlaceCategory.allCases.filter { cat in
                entries.contains { $0.customCategoryID == nil && $0.category == cat }
            }) { cat in
                CategoryGroupCard(
                    category: cat,
                    entries: entries.filter { $0.customCategoryID == nil && $0.category == cat }
                ) { entry in
                    selectedEntry = entry
                    showDetail = true
                }
            }
            if entries.isEmpty {
                emptyStateView(icon: "📂", message: lang.s.homeNoEntries)
            }
        }
    }

    private var countrySection: some View {
        VStack(spacing: 16) {
            ForEach(entriesByCountry.keys.sorted(), id: \.self) { country in
                CountryGroupCard(country: country, entries: entriesByCountry[country] ?? []) { entry in
                    selectedEntry = entry
                    showDetail = true
                }
            }
            if entriesByCountry.isEmpty {
                emptyStateView(icon: "🌍", message: lang.s.emptyCountryHint)
            }
        }
    }

    private var favoriteSection: some View {
        VStack(spacing: 12) {
            if favoriteEntries.isEmpty {
                emptyStateView(icon: "🔖", message: lang.s.emptyFavoritesHint)
                    .padding(.top, 40)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(favoriteEntries) { entry in
                        EntryCard(entry: entry)
                            .onTapGesture {
                                selectedEntry = entry
                                showDetail = true
                            }
                    }
                }
            }
        }
    }

    private func emptyStateView(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Text(icon).font(.system(size: 40))
            Text(message).font(.system(size: 14)).foregroundColor(.wanderMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(32)
    }
}

struct CategoryGroupCard: View {
    let category: PlaceCategory
    var categoryDisplayName: String? = nil
    var categoryIcon: String? = nil
    let entries: [Entry]
    let onTap: (Entry) -> Void
    @EnvironmentObject var lang: LanguageManager
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isExpanded.toggle() }
            } label: {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: categoryIcon ?? category.icon).font(.system(size: 22)).foregroundColor(.wanderAccent)
                        Text(categoryDisplayName ?? category.localizedName(lang: lang.language)).font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.wanderInk)
                    }
                    Spacer()
                    Text("\(entries.count)").font(.system(size: 13, weight: .medium))
                        .foregroundColor(.wanderMuted)
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium))
                        .foregroundColor(.wanderMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }
            if isExpanded {
                Divider().padding(.horizontal, 16)
                VStack(spacing: 0) {
                    ForEach(entries.prefix(5)) { entry in
                        Button { onTap(entry) } label: { EntryRowItem(entry: entry) }
                        if entry.id != entries.prefix(5).last?.id {
                            Divider().padding(.horizontal, 16)
                        }
                    }
                    if entries.count > 5 {
                        Text(lang.s.seeAll(entries.count)).font(.system(size: 13))
                            .foregroundColor(.wanderAccent).frame(maxWidth: .infinity).padding(14)
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
    @EnvironmentObject var lang: LanguageManager
    @State private var isExpanded = false

    var cities: String {
        Array(Set(entries.map { $0.city }.filter { !$0.isEmpty })).prefix(3).joined(separator: "、")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isExpanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(country).font(.system(size: 16, weight: .semibold)).foregroundColor(.wanderInk)
                        if !cities.isEmpty {
                            Text(cities).font(.system(size: 12)).foregroundColor(.wanderMuted)
                        }
                    }
                    Spacer()
                    Text(lang.s.entriesCount(entries.count)).font(.system(size: 12)).foregroundColor(.wanderMuted)
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.wanderMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }
            if isExpanded {
                Divider().padding(.horizontal, 16)
                ForEach(entries.prefix(5)) { entry in
                    Button { onTap(entry) } label: { EntryRowItem(entry: entry) }
                    if entry.id != entries.prefix(5).last?.id {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct EntryRowItem: View {
    let entry: Entry
    @EnvironmentObject var store: EntryStore
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let img = thumbnail {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Rectangle().fill(
                        LinearGradient(colors: [Color(hex: "3A2A1A"), Color(hex: "8B6040")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                }
            }
            .frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name).font(.system(size: 14, weight: .medium))
                    .foregroundColor(.wanderInk).lineLimit(1)
                HStack(spacing: 8) {
                    Image(systemName: store.categoryIcon(for: entry)).font(.system(size: 10)); Text(entry.city)
                        .font(.system(size: 12)).foregroundColor(.wanderMuted)
                    Text(entry.visitedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12)).foregroundColor(.wanderMuted)
                }
            }
            Spacer()
            HStack(spacing: 1) {
                ForEach(1...5, id: \.self) { s in
                    Image(systemName: s <= entry.rating ? "star.fill" : "star")
                        .font(.system(size: 9))
                        .foregroundColor(s <= entry.rating ? .wanderAccent : .wanderBlush)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12).contentShape(Rectangle())
        .task {
            if let filename = entry.firstPhotoFilename {
                thumbnail = await Task.detached {
                    PhotoRepository.shared.load(filename)
                }.value
            }
        }
    }
}
