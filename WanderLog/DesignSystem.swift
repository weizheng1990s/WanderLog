import SwiftUI

extension Color {
    static let wanderInk    = Color("WanderInk")
    static let wanderCream  = Color("WanderCream")
    static let wanderAccent = Color("WanderAccent")
    static let wanderMuted  = Color("WanderMuted")
    static let wanderWarm   = Color("WanderWarm")
    static let wanderBlush  = Color("WanderBlush")
}

extension Font {
    static func wanderSerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Georgia", size: size).weight(weight)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
