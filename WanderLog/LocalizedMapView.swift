import SwiftUI
import MapKit

// MARK: - Pin data model

struct MapPinData: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let icon: String
    let name: String
}

// MARK: - UIViewRepresentable

struct LocalizedMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var showsUserLocation: Bool = false
    var isInteractionEnabled: Bool = true
    var pins: [MapPinData] = []
    var selectedID: UUID? = nil
    var onPinTap: ((UUID) -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = showsUserLocation
        map.isUserInteractionEnabled = isInteractionEnabled
        map.setRegion(region, animated: false)
        map.register(WanderPinView.self, forAnnotationViewWithReuseIdentifier: WanderPinView.reuseID)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        // Sync region (avoid feedback loop)
        let cur = map.region
        let tol = 0.0001
        if abs(cur.center.latitude - region.center.latitude) > tol ||
           abs(cur.center.longitude - region.center.longitude) > tol {
            map.setRegion(region, animated: true)
        }

        // Sync annotations
        let existing = map.annotations.compactMap { $0 as? WanderAnnotation }
        let existingIDs = Set(existing.map(\.id))
        let newIDs = Set(pins.map(\.id))
        map.removeAnnotations(existing.filter { !newIDs.contains($0.id) })
        map.addAnnotations(pins.filter { !existingIDs.contains($0.id) }.map(WanderAnnotation.init))

        // Refresh selected state
        for ann in map.annotations.compactMap({ $0 as? WanderAnnotation }) {
            (map.view(for: ann) as? WanderPinView)?.setSelected(ann.id == selectedID)
        }
    }

    // MARK: Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: LocalizedMapView

        init(_ parent: LocalizedMapView) { self.parent = parent }

        func mapView(_ map: MKMapView, regionDidChangeAnimated _: Bool) {
            guard parent.isInteractionEnabled else { return }
            DispatchQueue.main.async { self.parent.region = map.region }
        }

        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let ann = annotation as? WanderAnnotation else { return nil }
            let view = map.dequeueReusableAnnotationView(
                withIdentifier: WanderPinView.reuseID, for: ann) as? WanderPinView
                ?? WanderPinView(annotation: ann, reuseIdentifier: WanderPinView.reuseID)
            view.configure(icon: ann.icon, name: ann.name, isSelected: ann.id == parent.selectedID)
            return view
        }

        func mapView(_ map: MKMapView, didSelect annotation: MKAnnotation) {
            guard let ann = annotation as? WanderAnnotation else { return }
            map.deselectAnnotation(annotation, animated: false)
            parent.onPinTap?(ann.id)
        }
    }
}

// MARK: - MKAnnotation wrapper

final class WanderAnnotation: NSObject, MKAnnotation {
    let id: UUID
    @objc dynamic var coordinate: CLLocationCoordinate2D
    let title: String?
    let icon: String
    let name: String

    init(_ pin: MapPinData) {
        self.id = pin.id
        self.coordinate = pin.coordinate
        self.title = pin.name
        self.icon = pin.icon
        self.name = pin.name
    }
}

// MARK: - Annotation view

final class WanderPinView: MKAnnotationView {
    static let reuseID = "WanderPin"

    // Accent color matching wanderAccent (#9B7241 approx)
    private static let accent = UIColor(red: 0.608, green: 0.447, blue: 0.255, alpha: 1)

    private let capsule = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let dot = UIView()
    private let hStack = UIStackView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        buildLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildLayout() {
        // capsule content
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Self.accent
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        nameLabel.font = .systemFont(ofSize: 11, weight: .medium)
        nameLabel.textColor = .white
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.isHidden = true

        hStack.axis = .horizontal
        hStack.spacing = 4
        hStack.alignment = .center
        hStack.addArrangedSubview(iconView)
        hStack.addArrangedSubview(nameLabel)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        capsule.addSubview(hStack)
        capsule.layer.cornerRadius = 15
        capsule.layer.shadowColor = UIColor.black.cgColor
        capsule.layer.shadowOpacity = 0.25
        capsule.layer.shadowRadius = 4
        capsule.layer.shadowOffset = CGSize(width: 0, height: 2)
        capsule.backgroundColor = .systemBackground
        capsule.translatesAutoresizingMaskIntoConstraints = false

        dot.backgroundColor = .systemBackground
        dot.layer.cornerRadius = 3
        dot.layer.shadowColor = UIColor.black.cgColor
        dot.layer.shadowOpacity = 0.2
        dot.layer.shadowRadius = 1
        dot.translatesAutoresizingMaskIntoConstraints = false

        let vStack = UIStackView(arrangedSubviews: [capsule, dot])
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 2
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            vStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            hStack.leadingAnchor.constraint(equalTo: capsule.leadingAnchor, constant: 8),
            hStack.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -8),
            hStack.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 12),
            iconView.heightAnchor.constraint(equalToConstant: 12),

            capsule.heightAnchor.constraint(equalToConstant: 30),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),
        ])

        frame = CGRect(x: -20, y: -40, width: 40, height: 42)
    }

    func configure(icon: String, name: String, isSelected: Bool) {
        iconView.image = UIImage(systemName: icon)
        nameLabel.text = name
        setSelected(isSelected)
    }

    func setSelected(_ selected: Bool) {
        capsule.backgroundColor = selected ? Self.accent : .systemBackground
        iconView.tintColor = selected ? .white : Self.accent
        dot.backgroundColor = selected ? Self.accent : .systemBackground
        nameLabel.isHidden = !selected
        // Resize frame to fit label when selected
        layoutIfNeeded()
        let w = max(40, hStack.systemLayoutSizeFitting(.zero).width + 16 + 16)
        frame.size.width = w
        frame.origin.x = -w / 2
    }
}
