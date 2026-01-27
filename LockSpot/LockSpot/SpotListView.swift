//
//  SpotListView.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/26/26.
//
import SwiftUI
import MapKit

struct Spot: Identifiable, Hashable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    let address: String?
    let website: String?
    let phone: String?
    let category: String?
    let hours: String?
    
    static func == (lhs: Spot, rhs: Spot) -> Bool { // make struct equatable
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Spot {
    init?(from element: OSMEElement) {
        guard let lat = element.lat, let lon = element.lon else { return nil }
        
        let tags = element.tags ?? [:]
        let name = tags["name"] ?? "Unnamed"
        
        let house = tags["addr:housenumber"]
        let street = tags["addr:street"]
        let city = tags["addr:city"]
        let postcode = tags["addr:postcode"]
        
        let addressParts = [
            [house, street].compactMap { $0 }.joined(separator: " "),
            city,
            postcode
        ].compactMap{ $0 }
            .filter { !$0.isEmpty }

        let address = addressParts.isEmpty ? nil : addressParts.joined(separator: ", ")

        let website = tags["website"] ?? tags["contact:website"]
        let phone = tags["phone"] ?? tags["contact:phone"]
        let hours = tags["opening_hours"]

        let category = tags["amenity"] ?? tags["building"]

        self.id = String(element.id)
        self.name = name
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.address = address
        self.website = website
        self.phone = phone
        self.category = category
        self.hours = hours
    }
}

let campusBuildings: [Spot] = [
    Spot(
        id: "klaus",
        name: "Klaus Advanced Computing Building",
        coordinate: CLLocationCoordinate2D(latitude: 33.7770, longitude: -84.3958),
        address: "266 Ferst Dr NW, Atlanta, GA 30332",
        website: "https://scs.gatech.edu/building-facilities",
        phone: "404-894-2000",
        category: "campus_building",
        hours: nil
    ),
    Spot(
        id: "coc",
        name: "College of Computing",
        coordinate: CLLocationCoordinate2D(latitude: 33.7773, longitude: -84.3972),
        address: "801 Atlantic Dr NW, Atlanta, GA 30332",
        website: "https://www.cc.gatech.edu/",
        phone: "404-894-2000",
        category: "campus_building",
        hours: nil
    ),
    Spot(
        id: "culc",
        name: "Clough Undergraduate Learning Commons (CULC)",
        coordinate: CLLocationCoordinate2D(latitude: 33.7746, longitude: -84.3963),
        address: "266 4th St NW, Atlanta, GA 30332",
        website: "https://library.gatech.edu/clough",
        phone: "404-894-4500",
        category: "campus_building",
        hours: nil
    ),
    Spot(
        id: "scheller",
        name: "Scheller College of Business",
        coordinate: CLLocationCoordinate2D(latitude: 33.7764, longitude: -84.3877),
        address: "800 W Peachtree St NW, Atlanta, GA 30308",
        website: "https://www.scheller.gatech.edu/index.html",
        phone: "404-894-2600",
        category: "campus_building",
        hours: nil
    ),
    Spot(
        id: "boggs",
        name: "Boggs Building",
        coordinate: CLLocationCoordinate2D(latitude: 33.78, longitude: -84.4),
        address: "770 State St NW, Atlanta, GA 30332",
        website: "https://www.studentcenter.gatech.edu/classroom/boggs",
        phone: "404-894-2000",
        category: "campus_building",
        hours: nil
    ),
    Spot(
        id: "student_center",
        name: "Georgia Tech Student Center",
        coordinate: CLLocationCoordinate2D(latitude: 33.7736, longitude: -84.3985),
        address: "351 Ferst Dr NW, Atlanta, GA 30332",
        website: "https://www.studentcenter.gatech.edu",
        phone: "404-894-2000",
        category: "campus_building",
        hours: nil
    )
]

struct SpotListView: View {
    // Temporary hardcoded list (we’ll swap to GT Spaces API later)
    @State private var spots: [Spot] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    private let client = OverpassClient()
    
    @MainActor
    private func loadBuildings() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Georgia Tech-ish center:
            let elements = try await client.fetchSpots(centerLat: 33.7753, centerLon: -84.3966, radiusMeters: 1200)

            // Convert + dedupe by name (OSM can return near-duplicates)
            var seen = Set<String>()
            let converted = elements
                .compactMap { Spot(from: $0) }
                .filter { seen.insert($0.name.lowercased()).inserted }

            var merged = converted
            for building in campusBuildings {
                merged.append(building)
            }
            
            spots = merged.sorted { $0.name < $1.name }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @State private var selectedSpot: Spot? = nil

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.7753, longitude: -84.3966),
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )
    )

    var body: some View {
        VStack{
            Text("Spots loaded: \(spots.count)")
                .font(.caption)
                .padding(.top, 8)
            
            Map(position: $cameraPosition, selection: $selectedSpot) {
                ForEach(spots) {
                    spot in Marker(spot.name, coordinate: spot.coordinate).tag(spot)
                }
            }
            .frame(height:260)
            .mapStyle(.standard)
            .overlay(alignment: .topLeading) {
                if let selectedSpot = selectedSpot {
                    Text("Selected: \(selectedSpot.name)")
                        .font(.subheadline)
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                }
            }
            
            if isLoading {
                ProgressView("Loading buildings…")
                    .padding(.vertical, 8)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
            }
            
            List(spots) { spot in
                NavigationLink(spot.name) {
                    SpotDetailView(spot: spot)
                }
            }
            .navigationTitle("Study Spots")
            .task {
                print("SpotListView task fired")
                await loadBuildings()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpotListView()
    }
}

