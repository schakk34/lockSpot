//
//  GTPlacesClient.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/26/26.
//
import Foundation
struct OverpassResponse: Codable {
    let elements: [OSMEElement]
}

struct OSMEElement: Codable {
    let id: Int
    let lat: Double?
    let lon: Double?
    let tags: [String: String]?
}

final class OverpassClient {
    func fetchSpots(centerLat: Double, centerLon: Double, radiusMeters: Int = 1200) async throws -> [OSMEElement] {
        let query = """
                [out:json][timeout:25];
                (
                  node["amenity"="library"](around:\(radiusMeters),\(centerLat),\(centerLon));
                  node["amenity"="cafe"](around:\(radiusMeters),\(centerLat),\(centerLon));
                  node["amenity"="college"](around:\(radiusMeters),\(centerLat),\(centerLon));
                  node["amenity"="university"](around:\(radiusMeters),\(centerLat),\(centerLon));
                );
                out body;
                """
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        let url = URL(string: "https://overpass-api.de/api/interpreter?data=\(encoded)")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        
        let(data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "OverpassClient", code: 1, userInfo: [NSLocalizedDescriptionKey : msg])
        }
        
        return try JSONDecoder().decode(OverpassResponse.self, from:data).elements
    }
}

