import Foundation
import Combine

struct CustomCategory: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String

    init(id: UUID = UUID(), name: String, icon: String = "tag.fill") {
        self.id = id
        self.name = name
        self.icon = icon
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
    }

    private func seedDefaultCategoriesIfNeeded() {
        guard customCategories.isEmpty else { return }
        let defaults: [(String, String)] = [
            ("咖啡馆",       "cup.and.saucer.fill"),
            ("博物馆",       "building.columns.fill"),
            ("书店",         "books.vertical.fill"),
            ("酒吧",         "wineglass.fill"),
            ("展览 / 美术馆","photo.artframe"),
            ("买手店",       "bag.fill"),
            ("餐厅",         "fork.knife"),
        ]
        customCategories = defaults.map { CustomCategory(name: $0.0, icon: $0.1) }
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
        if let custom = customCategory(for: entry) { return custom.name }
        return entry.category.localizedName(lang: lang)
    }

    func categoryIcon(for entry: Entry) -> String {
        if let custom = customCategory(for: entry) { return custom.icon }
        return entry.category.icon
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
