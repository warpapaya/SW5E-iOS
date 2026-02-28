import Foundation

// MARK: - API Service for SW5E Backend

/// Service for communicating with the SW5E backend API
class APIService: ObservableObject {
    static let shared = APIService()
    
    @Published var serverURL: String = "https://sw5e-api.petieclark.com"
    @Published var isConnected: Bool = false
    
    private init() {}
    
    // MARK: - Character Endpoints
    
    /// Fetch all characters for the current user
    func fetchCharacters() async throws -> [Character] {
        let url = URL(string: "\(serverURL)/api/characters")!
        return try await fetchData(from: url)
    }
    
    /// Fetch a single character by ID
    func fetchCharacter(id: String) async throws -> Character {
        let url = URL(string: "\(serverURL)/api/characters/\(id)")!
        var req = URLRequest(url: url)
        req.timeoutInterval = 15 // Increased timeout for HTTPS production load
        return try await fetchData(from: req)
    }
    
    /// Create a new character
    func createCharacter(_ character: Character) async throws -> Character {
        let url = URL(string: "\(serverURL)/api/characters")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(character)
        
        return try await performRequest(request)
    }
    
    /// Update an existing character
    func updateCharacter(_ character: Character) async throws -> Character {
        let url = URL(string: "\(serverURL)/api/characters/\(character.id)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(character)
        
        return try await performRequest(request)
    }
    
    /// Delete a character by ID
    func deleteCharacter(id: String) async throws {
        let url = URL(string: "\(serverURL)/api/characters/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 404 else { return }
    }
    
    // MARK: - Campaign Endpoints
    
    /// Fetch all campaigns for the current user
    func fetchCampaigns() async throws -> [Campaign] {
        let url = URL(string: "\(serverURL)/api/campaigns")!
        return try await fetchData(from: url)
    }
    
    /// Fetch a single campaign by ID
    func fetchCampaign(id: String) async throws -> Campaign {
        let url = URL(string: "\(serverURL)/api/campaigns/\(id)")!
        return try await fetchData(from: url)
    }
    
    /// Create a new campaign
    func createCampaign(_ campaign: Campaign) async throws -> Campaign {
        let url = URL(string: "\(serverURL)/api/campaigns")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(campaign)
        
        return try await performRequest(request)
    }
    
    // MARK: - Generic Request Methods
    
    private func fetchData<T: Decodable>(from url: URL) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    private func fetchData<T: Decodable>(from request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest, expectSuccess: Bool = true) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        if !expectSuccess && (400...499).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(T.self, from: data)  // Return empty on expected error
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Health Check
    
    func checkConnection() async -> Bool {
        let url = URL(string: "\(serverURL)/health")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            isConnected = (200...299).contains(httpResponse.statusCode)
            return isConnected
            
        } catch {
            isConnected = false
            return false
        }
    }
}

// MARK: - API Error Types

enum APIServiceError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP Error \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
