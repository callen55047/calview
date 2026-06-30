import SwiftUI

struct LegendEntry: Identifiable, Codable {
    var id: String
    var label: String
    var hex: String

    var color: Color { Color(hex: hex) }
}
