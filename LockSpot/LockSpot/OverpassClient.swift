//
//  GTPlacesClient.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/26/26.
//
import Foundation
final class GTPlacesClient {
    private let buildingsURL = URL(string: "https://m.gatech.edu/api/gtplaces/buildings/")!
    
    func fetchBuildings() async throws -> [GTBuildingDTO] {
        var request = URLRequest(url: buildingsURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("🌐 bytes:", data.count)
        print("🌐 first 200 chars:", String(data: data.prefix(200), encoding: .utf8) ?? "nil")
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([GTBuildingDTO].self, from: data)
    }
    
}

