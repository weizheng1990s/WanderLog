import Foundation
import CoreLocation

struct Entry: Identifiable, Codable {
    var id: UUID
    var name: String
    var category: PlaceCategory
    var note: String
    var mood: Mood
    var rating: Int
    var city: String
    var country: String
    var latitude: Double?
    var longitude: Double?
    var photoFilenames: [String]
    var isFavorite: Bool
    var visitedAt: Date
    var createdAt: Date
    var tags: [String]

    init(
        name: String,
        category: PlaceCategory,
        note: String = "",
        mood: Mood = .relaxed,
        rating: Int = 4,
        city: String = "",
        country: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        photoFilenames: [String] = [],
        isFavorite: Bool = false,
        visitedAt: Date = Date(),
        tags: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.note = note
        self.mood = mood
        self.rating = rating
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.photoFilenames = photoFilenames
        self.isFavorite = isFavorite
        self.visitedAt = visitedAt
        self.createdAt = Date()
        self.tags = tags
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var firstPhotoFilename: String? { photoFilenames.first }
}

enum PlaceCategory: String, CaseIterable, Codable, Identifiable {
    case cafe       = "咖啡馆"
    case museum     = "博物馆"
    case bookstore  = "书店"
    case bar        = "酒吧"
    case gallery    = "展览 / 美术馆"
    case selectShop = "买手店"
    case restaurant = "餐厅"
    case other      = "其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cafe:       return "cup.and.saucer.fill"
        case .museum:     return "building.columns.fill"
        case .bookstore:  return "books.vertical.fill"
        case .bar:        return "wineglass.fill"
        case .gallery:    return "photo.artframe"
        case .selectShop: return "bag.fill"
        case .restaurant: return "fork.knife"
        case .other:      return "mappin.and.ellipse"
        }
    }
}

enum Mood: String, CaseIterable, Codable {
    case loved   = "loved"
    case relaxed = "relaxed"
    case amazed  = "amazed"
    case neutral = "neutral"
    case tired   = "tired"

    var icon: String {
        switch self {
        case .loved:   return "heart.fill"
        case .relaxed: return "leaf.fill"
        case .amazed:  return "star.fill"
        case .neutral: return "minus.circle.fill"
        case .tired:   return "moon.fill"
        }
    }

    var label: String {
        switch self {
        case .loved:   return "很爱"
        case .relaxed: return "治愈"
        case .amazed:  return "震撼"
        case .neutral: return "一般"
        case .tired:   return "疲惫"
        }
    }
}
