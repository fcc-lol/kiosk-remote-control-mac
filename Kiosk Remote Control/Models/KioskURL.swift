import Foundation

struct KioskURL: Identifiable, Codable {
    let id: String
    let title: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
    }
} 