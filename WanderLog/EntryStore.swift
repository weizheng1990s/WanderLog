import Foundation
import Combine

struct CustomCategory: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String
    var sourcePlaceCategory: PlaceCategory?  // 记录对应的标准品类，改名后仍可关联旧数据

    init(id: UUID = UUID(), name: String, icon: String = "tag.fill", sourcePlaceCategory: PlaceCategory? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sourcePlaceCategory = sourcePlaceCategory
    }
}

final class EntryStore: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var customCategories: [CustomCategory] = []

    private let saveURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("entries.json")
    }()

    private let customCatsURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("customCategories.json")
    }()

    init() {
        load()
        loadCustomCategories()
        seedDefaultCategoriesIfNeeded()
        migrateCustomCategoriesIfNeeded()  // 给已有自定义品类补上 sourcePlaceCategory
        migrateEntriesIfNeeded()           // 给旧 entry 补上 customCategoryID
    }

    private func seedDefaultCategoriesIfNeeded() {
        guard customCategories.isEmpty else { return }
        let defaults: [(String, String, PlaceCategory)] = [
            ("咖啡馆",       "cup.and.saucer.fill",  .cafe),
            ("博物馆",       "building.columns.fill", .museum),
            ("书店",         "books.vertical.fill",   .bookstore),
            ("酒吧",         "wineglass.fill",         .bar),
            ("展览 / 美术馆","photo.artframe",          .gallery),
            ("买手店",       "bag.fill",               .selectShop),
            ("餐厅",         "fork.knife",             .restaurant),
        ]
        customCategories = defaults.map { CustomCategory(name: $0.0, icon: $0.1, sourcePlaceCategory: $0.2) }
        saveCustomCategories()
    }

    // MARK: - Entry CRUD

    func add(_ entry: Entry) {
        entries.insert(entry, at: 0)
        save()
    }

    func update(_ entry: Entry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        save()
    }

    func delete(_ entry: Entry) {
        PhotoRepository.shared.delete(entry.photoFilenames)
        entries.removeAll { $0.id == entry.id }
        save()
    }

    // MARK: - CustomCategory CRUD

    @discardableResult
    func addCustomCategory(name: String, icon: String = "tag.fill") -> CustomCategory {
        let cat = CustomCategory(name: name, icon: icon)
        customCategories.append(cat)
        saveCustomCategories()
        return cat
    }

    func updateCustomCategory(_ cat: CustomCategory) {
        guard let idx = customCategories.firstIndex(where: { $0.id == cat.id }) else { return }
        customCategories[idx] = cat
        saveCustomCategories()
    }

    func deleteCustomCategory(_ cat: CustomCategory) {
        customCategories.removeAll { $0.id == cat.id }
        for i in entries.indices where entries[i].customCategoryID == cat.id {
            entries[i].customCategoryID = nil
        }
        save()
        saveCustomCategories()
    }

    // MARK: - Helpers

    func customCategory(for entry: Entry) -> CustomCategory? {
        guard let id = entry.customCategoryID else { return nil }
        return customCategories.first { $0.id == id }
    }

    func categoryDisplayName(for entry: Entry, lang: AppLanguage) -> String {
        if let custom = customCategory(for: entry) {
            // Default categories (have sourcePlaceCategory) auto-translate
            if let source = custom.sourcePlaceCategory { return source.localizedName(lang: lang) }
            // User-created custom categories keep their user-given name
            return custom.name
        }
        return entry.category.localizedName(lang: lang)
    }

    func displayName(for customCat: CustomCategory, lang: AppLanguage) -> String {
        if let source = customCat.sourcePlaceCategory { return source.localizedName(lang: lang) }
        return customCat.name
    }

    func categoryIcon(for entry: Entry) -> String {
        if let custom = customCategory(for: entry) { return custom.icon }
        return entry.category.icon
    }

    // MARK: - Migration

    /// 给已保存的自定义品类补上 sourcePlaceCategory（用 icon 反推，改名后仍准确）
    private func migrateCustomCategoriesIfNeeded() {
        let iconMap: [String: PlaceCategory] = [
            "cup.and.saucer.fill":  .cafe,
            "building.columns.fill": .museum,
            "books.vertical.fill":  .bookstore,
            "wineglass.fill":       .bar,
            "photo.artframe":       .gallery,
            "bag.fill":             .selectShop,
            "fork.knife":           .restaurant,
        ]
        var changed = false
        for i in customCategories.indices where customCategories[i].sourcePlaceCategory == nil {
            if let pc = iconMap[customCategories[i].icon] {
                customCategories[i].sourcePlaceCategory = pc
                changed = true
            }
        }
        if changed { saveCustomCategories() }
    }

    /// 给没有 customCategoryID 的旧 entry 补上对应的自定义品类 ID
    private func migrateEntriesIfNeeded() {
        var changed = false
        for i in entries.indices where entries[i].customCategoryID == nil {
            let pc = entries[i].category
            if let matched = customCategories.first(where: { $0.sourcePlaceCategory == pc }) {
                entries[i].customCategoryID = matched.id
                changed = true
            }
        }
        if changed { save() }
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: saveURL)
        } catch {
            print("EntryStore save error: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Entry].self, from: data) else { return }
        entries = decoded
    }

    private func saveCustomCategories() {
        guard let data = try? JSONEncoder().encode(customCategories) else { return }
        try? data.write(to: customCatsURL)
    }

    private func loadCustomCategories() {
        guard let data = try? Data(contentsOf: customCatsURL),
              let decoded = try? JSONDecoder().decode([CustomCategory].self, from: data) else { return }
        customCategories = decoded
    }
}
