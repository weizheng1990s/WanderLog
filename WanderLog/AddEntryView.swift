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
            if !val.isEmpty {
                city = val
                resolvedCoordinate = locationManager.coordinate
            }
        }
        .onChange(of: locationManager.country) { val in
            if !val.isEmpty { country = val }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            if isSaving {
                ProgressView().tint(.wanderInk)
            } else {
                Text(lang.s.save)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(name.isEmpty ? Color.wanderMuted : Color.wanderInk)
                    .clipShape(Capsule())
            }
        }
        .disabled(name.isEmpty || isSaving)
    }

    // MARK: - Photo

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(lang.s.photos)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, img in
                        photoThumb(img, index: idx)
                    }
                    addPhotoButton
                }
            }
        }
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

    private func photoThumb(_ image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 14))
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
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(lang.s.category)
            categoryGrid
        }
        .alert("新增类型", isPresented: $showAddCategory) {
            TextField("类型名称", text: $newCategoryName)
            Button("取消", role: .cancel) { newCategoryName = "" }
            Button("添加") {
                let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    let cat = store.addCustomCategory(name: trimmed)
                    categorySelection = .custom(cat.id)
                }
                newCategoryName = ""
            }
        }
        .alert("编辑类型", isPresented: $showEditCategory) {
            TextField("类型名称", text: $newCategoryName)
            Button("取消", role: .cancel) {
                editingCustomCategory = nil
                newCategoryName = ""
            }
            Button("保存") {
                if var cat = editingCustomCategory {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { cat.name = trimmed }
                    store.updateCustomCategory(cat)
                }
                editingCustomCategory = nil
                newCategoryName = ""
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
            spacing: 8
        ) {
            // 固定类型（排除 .other）
            ForEach(PlaceCategory.allCases.filter { $0 != .other }) { cat in
                CategoryButton(
                    icon: cat.icon,
                    localizedName: cat.localizedName(lang: lang.language),
                    isSelected: categorySelection == .standard(cat)
                ) {
                    categorySelection = .standard(cat)
                }
            }

            // 自定义类型
            ForEach(store.customCategories) { cat in
                CustomCategoryButton(
                    category: cat,
                    isSelected: categorySelection == .custom(cat.id),
                    onTap: { categorySelection = .custom(cat.id) },
                    onEdit: {
                        editingCustomCategory = cat
                        newCategoryName = cat.name
                        showEditCategory = true
                    },
                    onDelete: {
                        store.deleteCustomCategory(cat)
                        if categorySelection == .custom(cat.id) {
                            categorySelection = .standard(.cafe)
                        }
                    }
                )
            }

            // 新增按钮
            Button { newCategoryName = ""; showAddCategory = true } label: {
                VStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(.wanderAccent)
                    Text(lang.s.add)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.wanderInk)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundColor(Color.wanderAccent.opacity(0.6))
                )
            }
        }
    }

    // MARK: - Location + Basic Info

    private var locationSection: some View {
        VStack(spacing: 12) {
            // 位置 label + 地址输入 + 搜索按钮
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
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 15, weight: .medium))
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

            // 城市 + 国家 + 自动定位
            HStack(spacing: 8) {
                TextField(lang.s.city, text: $city).textFieldStyle(WanderTextFieldStyle())
                TextField(lang.s.country, text: $country).textFieldStyle(WanderTextFieldStyle())
                locationButton
            }

            // 名称 label + 店名输入
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
                .font(.system(size: 14))
                .foregroundColor(.wanderInk)
                .tint(.wanderAccent)
        }
    }

    private var locationButton: some View {
        Button {
            locationManager.requestLocation()
        } label: {
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
                    Button {
                        rating = star
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(star <= rating ? .wanderAccent : .wanderBlush)
                            .font(.system(size: 22))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(lang.s.myNotes)
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text(lang.s.notesPlaceholder)
                        .font(.system(size: 14))
                        .foregroundColor(.wanderMuted)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                }
                TextEditor(text: $note)
                    .font(.system(size: 14))
                    .foregroundColor(.wanderInk)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(10)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.wanderBlush, lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1)
            .foregroundColor(.wanderMuted)
            .textCase(.uppercase)
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
                    if let locality = item.placemark.locality, !locality.isEmpty { self.city = locality }
                    if let countryName = item.placemark.country, !countryName.isEmpty { self.country = countryName }
                    self.resolvedCoordinate = item.placemark.coordinate
                }
                return
            }
            // 搜索无结果，回退到纯地址解析
            CLGeocoder().geocodeAddressString(query) { placemarks, _ in
                DispatchQueue.main.async {
                    self.isGeocoding = false
                    guard let placemark = placemarks?.first else { return }
                    if let locality = placemark.locality, !locality.isEmpty { self.city = locality }
                    if let countryName = placemark.country, !countryName.isEmpty { self.country = countryName }
                    self.resolvedCoordinate = placemark.location?.coordinate
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
        guard let entry = editingEntry else { return }
        name = entry.name; note = entry.note
        rating = entry.rating; city = entry.city
        country = entry.country; visitedAt = entry.visitedAt
        if let customID = entry.customCategoryID {
            categorySelection = .custom(customID)
        } else {
            categorySelection = .standard(entry.category)
        }
        if let lat = entry.latitude, let lng = entry.longitude {
            resolvedCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        Task {
            let loaded = await Task.detached {
                PhotoRepository.shared.loadAll(entry.photoFilenames)
            }.value
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
                entry.photoFilenames = newFilenames
                entry.customCategoryID = customID
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
            errorMessage = error.localizedDescription
            showError = true
        }
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
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .wanderAccent)
                Text(localizedName)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(isSelected ? .white : .wanderInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.wanderInk : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color.wanderBlush, lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Custom Category Button

struct CustomCategoryButton: View {
    let category: CustomCategory
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .wanderAccent)
                Text(category.name)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(isSelected ? .white : .wanderInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.wanderInk : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color.wanderBlush, lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .contextMenu {
            Button { onEdit() } label: { Label("编辑", systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label("删除", systemImage: "trash") }
        }
    }
}

// MARK: - TextField Style

struct WanderTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14))
            .foregroundColor(Color.wanderInk)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.wanderBlush, lineWidth: 1)
            )
    }
}
