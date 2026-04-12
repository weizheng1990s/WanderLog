import SwiftUI
import PhotosUI
import CoreLocation
import MapKit

enum CategorySelection: Equatable {
    case standard(PlaceCategory)
    case custom(UUID)
}

struct AddEntryView: View {
    @EnvironmentObject var store: EntryStore
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var editingEntry: Entry? = nil

    @State private var name: String = ""
    @State private var categorySelection: CategorySelection = .standard(.cafe)
    @State private var showAddCategory = false
    @State private var showEditCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "tag.fill"
    @State private var editingCustomCategory: CustomCategory? = nil
    @State private var note: String = ""
    @State private var rating: Int = 4
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var visitedAt: Date = Date()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var addressInput: String = ""
    @State private var isGeocoding = false
    @State private var resolvedCoordinate: CLLocationCoordinate2D? = nil
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    // drag state
    @State private var draggingIndex: Int? = nil

    @ObservedObject private var locationManager = LocationManager.shared

    var isEditing: Bool { editingEntry != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    photoSection
                    categorySection
                    locationSection
                    ratingSection
                    noteSection
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color.wanderWarm)
            .navigationTitle(isEditing ? lang.s.editEntry : lang.s.newEntry)
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.s.cancel) { dismiss() }.foregroundColor(.wanderMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
            .alert(lang.s.saveFailed, isPresented: $showError) {
                Button(lang.s.ok) {}
            } message: { Text(errorMessage) }
        }
        .onAppear { populateIfEditing() }
        .onChange(of: selectedItems) { items in Task { await loadSelectedPhotos(items) } }
        .onChange(of: locationManager.city) { val in
            if !val.isEmpty { city = val; resolvedCoordinate = locationManager.coordinate }
        }
        .onChange(of: locationManager.country) { val in
            if !val.isEmpty { country = val }
        }
    }

    private var saveButton: some View {
        Button { Task { await save() } } label: {
            if isSaving {
                ProgressView().tint(.wanderInk)
            } else {
                Text(lang.s.save)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 7)
                    .background(name.isEmpty ? Color.wanderMuted : Color.wanderInk)
                    .clipShape(Capsule())
            }
        }
        .disabled(name.isEmpty || isSaving)
    }

    // MARK: - Photo Section (draggable)

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel(lang.s.photos)
                if selectedImages.count > 1 {
                    Text(lang.s.dragToSort)
                        .font(.system(size: 11))
                        .foregroundColor(.wanderMuted)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, img in
                        draggablePhotoThumb(img, index: idx)
                    }
                    addPhotoButton
                }
                .padding(.vertical, 6) // 给拖拽留点空间
            }
        }
    }

    private func draggablePhotoThumb(_ image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(draggingIndex == index ? Color.wanderAccent : Color.clear, lineWidth: 2)
                )
                .scaleEffect(draggingIndex == index ? 1.05 : 1.0)
                .opacity(draggingIndex == index ? 0.75 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: draggingIndex)

            // 删除按钮
            Button {
                selectedImages.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
        .onDrag {
            draggingIndex = index
            return NSItemProvider(object: "\(index)" as NSString)
        }
        .onDrop(of: [.text], delegate: PhotoDropDelegate(
            toIndex: index,
            images: $selectedImages,
            draggingIndex: $draggingIndex
        ))
    }

    private var addPhotoButton: some View {
        PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.wanderBlush.opacity(0.5))
                    .frame(width: 90, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.wanderAccent.opacity(0.5),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    )
                VStack(spacing: 4) {
                    Image(systemName: "plus").font(.system(size: 20))
                    Text(lang.s.add).font(.system(size: 11))
                }
                .foregroundColor(.wanderAccent)
            }
        }
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(lang.s.category)
            categoryGrid
        }
        .sheet(isPresented: $showAddCategory) {
            IconPickerSheet(
                title: lang.s.addCategory,
                name: $newCategoryName,
                icon: $newCategoryIcon
            ) { name, icon in
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    let cat = store.addCustomCategory(name: trimmed, icon: icon)
                    categorySelection = .custom(cat.id)
                }
                newCategoryName = ""
                newCategoryIcon = "tag.fill"
            }
        }
        .sheet(isPresented: $showEditCategory) {
            IconPickerSheet(
                title: lang.s.editCategory,
                name: $newCategoryName,
                icon: $newCategoryIcon
            ) { name, icon in
                if var cat = editingCustomCategory {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        let langKey = lang.language.rawValue
                        if let source = cat.sourcePlaceCategory {
                            // 默认品类：仅覆盖当前语言，与默认译名相同则移除（恢复自动翻译）
                            if trimmed == source.localizedName(lang: lang.language) {
                                cat.localizedNames.removeValue(forKey: langKey)
                            } else {
                                cat.localizedNames[langKey] = trimmed
                            }
                        } else {
                            // 纯自定义品类：只更新当前语言覆盖
                            // cat.name 保留创建时的原始名，作为无覆盖语言的兜底，不修改
                            cat.localizedNames[langKey] = trimmed
                        }
                        cat.icon = icon
                    }
                    store.updateCustomCategory(cat)
                }
                editingCustomCategory = nil
                newCategoryName = ""
                newCategoryIcon = "tag.fill"
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(store.customCategories) { cat in
                CustomCategoryButton(
                    category: cat,
                    displayName: store.displayName(for: cat, lang: lang.language),
                    isSelected: categorySelection == .custom(cat.id),
                    onTap: { categorySelection = .custom(cat.id) },
                    onEdit: { editingCustomCategory = cat; newCategoryName = store.displayName(for: cat, lang: lang.language); newCategoryIcon = cat.icon; showEditCategory = true },
                    onDelete: {
                        store.deleteCustomCategory(cat)
                        if categorySelection == .custom(cat.id) {
                            categorySelection = store.customCategories.first.map { .custom($0.id) } ?? .standard(.other)
                        }
                    }
                )
            }
            Button { newCategoryName = ""; showAddCategory = true } label: {
                VStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 20)).foregroundColor(.wanderAccent)
                    Text(lang.s.add).font(.system(size: 10, weight: .medium)).foregroundColor(.wanderInk)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundColor(Color.wanderAccent.opacity(0.6))
                )
            }
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(lang.s.location)
                HStack(spacing: 8) {
                    TextField(lang.s.addressPlaceholder, text: $addressInput)
                        .textFieldStyle(WanderTextFieldStyle())
                        .onSubmit { geocodeAddress() }
                    Button { geocodeAddress() } label: {
                        Group {
                            if isGeocoding {
                                ProgressView().scaleEffect(0.7).tint(.wanderAccent)
                            } else {
                                Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .medium))
                            }
                        }
                        .foregroundColor(.wanderAccent)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.wanderBlush, lineWidth: 1))
                    }
                    .disabled(isGeocoding || addressInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            HStack(spacing: 8) {
                TextField(lang.s.city, text: $city).textFieldStyle(WanderTextFieldStyle())
                TextField(lang.s.country, text: $country).textFieldStyle(WanderTextFieldStyle())
                locationButton
            }
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(lang.s.name)
                TextField(lang.s.shopNamePlaceholder, text: $name).textFieldStyle(WanderTextFieldStyle())
            }
            if resolvedCoordinate != nil {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill").font(.system(size: 10))
                    Text(lang.s.coordinateObtained).font(.system(size: 11))
                }
                .foregroundColor(.wanderAccent)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            DatePicker(lang.s.visitDate, selection: $visitedAt, displayedComponents: .date)
                .font(.system(size: 14)).foregroundColor(.wanderInk).tint(.wanderAccent)
        }
    }

    private var locationButton: some View {
        Button { locationManager.requestLocation() } label: {
            HStack(spacing: 4) {
                if locationManager.isLocating {
                    ProgressView().scaleEffect(0.7).tint(.wanderAccent)
                } else {
                    Image(systemName: "location.fill")
                }
                Text(locationManager.isLocating ? lang.s.locating : lang.s.autoLocate)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.wanderAccent)
        }
        .disabled(locationManager.isLocating)
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(lang.s.rating)
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Button { rating = star } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(star <= rating ? .wanderAccent : .wanderBlush)
                            .font(.system(size: 22))
                    }
                }
            }
        }
        .padding(16).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(lang.s.myNotes)
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text(lang.s.notesPlaceholder)
                        .font(.system(size: 14)).foregroundColor(.wanderMuted)
                        .padding(.horizontal, 16).padding(.top, 14)
                }
                TextEditor(text: $note)
                    .font(.system(size: 14)).foregroundColor(.wanderInk)
                    .frame(minHeight: 100).scrollContentBackground(.hidden).padding(10)
            }
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.wanderBlush, lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .semibold)).tracking(1)
            .foregroundColor(.wanderMuted).textCase(.uppercase)
    }

    private func geocodeAddress() {
        let query = addressInput.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        isGeocoding = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        MKLocalSearch(request: request).start { response, _ in
            if let item = response?.mapItems.first {
                DispatchQueue.main.async {
                    self.isGeocoding = false
                    if let l = item.placemark.locality, !l.isEmpty { self.city = l }
                    if let c = item.placemark.country, !c.isEmpty { self.country = c }
                    self.resolvedCoordinate = item.placemark.coordinate
                }
                return
            }
            CLGeocoder().geocodeAddressString(query) { placemarks, _ in
                DispatchQueue.main.async {
                    self.isGeocoding = false
                    guard let p = placemarks?.first else { return }
                    if let l = p.locality, !l.isEmpty { self.city = l }
                    if let c = p.country, !c.isEmpty { self.country = c }
                    self.resolvedCoordinate = p.location?.coordinate
                }
            }
        }
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
        // 新建时默认选中第一个自定义分类
        if editingEntry == nil {
            if let first = store.customCategories.first {
                categorySelection = .custom(first.id)
            }
            return
        }
        guard let entry = editingEntry else { return }
        name = entry.name; note = entry.note
        rating = entry.rating; city = entry.city
        country = entry.country; visitedAt = entry.visitedAt
        if let customID = entry.customCategoryID {
            categorySelection = .custom(customID)
        } else {
            // 兼容旧数据：找名字匹配的自定义分类
            let matchName = entry.category.rawValue
            if let matched = store.customCategories.first(where: { $0.name == matchName }) {
                categorySelection = .custom(matched.id)
            } else {
                categorySelection = store.customCategories.first.map { .custom($0.id) } ?? .standard(.other)
            }
        }
        if let lat = entry.latitude, let lng = entry.longitude {
            resolvedCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
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
            let (cat, customID): (PlaceCategory, UUID?) = {
                switch categorySelection {
                case .standard(let c): return (c, nil)
                case .custom(let id): return (.other, id)
                }
            }()
            if var entry = editingEntry {
                PhotoRepository.shared.delete(entry.photoFilenames)
                entry.name = name; entry.category = cat; entry.note = note
                entry.rating = rating; entry.city = city
                entry.country = country; entry.visitedAt = visitedAt
                entry.photoFilenames = newFilenames; entry.customCategoryID = customID
                store.update(entry)
            } else {
                let entry = Entry(
                    name: name, category: cat, note: note,
                    rating: rating, city: city, country: country,
                    latitude: resolvedCoordinate?.latitude,
                    longitude: resolvedCoordinate?.longitude,
                    photoFilenames: newFilenames, visitedAt: visitedAt,
                    customCategoryID: customID
                )
                store.add(entry)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription; showError = true
        }
    }
}

// MARK: - Photo Drop Delegate

struct PhotoDropDelegate: DropDelegate {
    let toIndex: Int
    @Binding var images: [UIImage]
    @Binding var draggingIndex: Int?

    func performDrop(info: DropInfo) -> Bool {
        draggingIndex = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let from = draggingIndex, from != toIndex else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            images.move(fromOffsets: IndexSet(integer: from),
                        toOffset: toIndex > from ? toIndex + 1 : toIndex)
        }
        draggingIndex = toIndex
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let icon: String
    let localizedName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .wanderAccent)
                Text(localizedName).font(.system(size: 10, weight: .medium))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .foregroundColor(isSelected ? .white : .wanderInk)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(isSelected ? Color.wanderInk : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.clear : Color.wanderBlush, lineWidth: 1))
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Custom Category Button

struct CustomCategoryButton: View {
    let category: CustomCategory
    let displayName: String
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: category.icon).font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .wanderAccent)
                Text(displayName).font(.system(size: 10, weight: .medium))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .foregroundColor(isSelected ? .white : .wanderInk)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(isSelected ? Color.wanderInk : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.clear : Color.wanderBlush, lineWidth: 1))
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .contextMenu {
            Button { onEdit() } label: { Label(lang.s.edit, systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label(lang.s.delete, systemImage: "trash") }
        }
    }
}

// MARK: - TextField Style

struct WanderTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14)).foregroundColor(Color.wanderInk)
            .padding(.horizontal, 16).padding(.vertical, 13)
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.wanderBlush, lineWidth: 1))
    }
}
