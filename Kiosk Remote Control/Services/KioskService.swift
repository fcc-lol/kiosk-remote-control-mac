import Foundation

class KioskService {
    static let shared = KioskService()
    
    private init() {}
    
    func fetchKioskURLs() async throws -> [KioskURL] {
        let urlString = "https://fcc-kiosk-server.noshado.ws/urls?fccApiKey=\(Secrets.fccApiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode([KioskURL].self, from: data)
    }
    
    func fetchCurrentURL() async throws -> String {
        let urlString = "https://fcc-kiosk-server.noshado.ws/current-url?fccApiKey=\(Secrets.fccApiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let response = try decoder.decode(CurrentURLResponse.self, from: data)
        return response.url
    }
    
    func changeKioskURL(_ id: String) async throws {
        let endpointURL = "https://fcc-kiosk-server.noshado.ws/change-url"
        
        guard let requestURL = URL(string: endpointURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["id": id, "fccApiKey": Secrets.fccApiKey]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

struct CurrentURLResponse: Codable {
    let url: String
} 