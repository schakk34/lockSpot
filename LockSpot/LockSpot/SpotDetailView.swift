//
//  SpotDetailView.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/26/26.
//
import SwiftUI
import MapKit

enum BusyRating: String, CaseIterable, Identifiable {
    case empty = "Empty"
    case medium = "Medium"
    case packed = "Packed"
    var id: String { rawValue }
}

struct SpotDetailView: View {
    let spot: Spot

    @State private var selectedRating: BusyRating? = nil
    @State private var note: String = ""
    @State private var camera: MapCameraPosition

    @StateObject private var auth = AuthManager()
    private let service = ReportsService()

    @State private var isSubmitting = false
    @State private var submitError: String? = nil
    @State private var submitSuccess = false

    @State private var recentReports: [BusyReport] = []
    @State private var isLoadingRecentReports = false
    
    private var latestReport: BusyReport? { recentReports.first }
    
    private func ratingColor(_ rating: String) -> Color {
        switch rating.lowercased() {
        case "empty": return .green
        case "medium": return .yellow
        case "packed": return .red
        default: return .gray
        }
    }


    @State private var showReportsSheet = false

    init(spot: Spot) {
        self.spot = spot
        _camera = State(initialValue: .region(
            MKCoordinateRegion(
                center: spot.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )
        ))
    }

    @MainActor
    private func loadRecentReports() async {
        isLoadingRecentReports = true
        defer { isLoadingRecentReports = false }
        do {
            recentReports = try await service.fetchRecentReports(spotId: spot.id)
        } catch {
            print("❌ fetchRecentReports error:", error)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(spot.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let latest = latestReport {
                    HStack(spacing: 10) {
                        Label("Latest report", systemImage: "bolt.fill")
                            .foregroundStyle(.secondary)

                        Text(latest.rating)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(ratingColor(latest.rating).opacity(0.18))
                            .foregroundStyle(ratingColor(latest.rating))
                            .clipShape(Capsule())

                        Spacer()

                        Text(latest.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }


                HStack(spacing: 12) {
                    if let website = spot.website, let url = URL(string: website) {
                        Link(destination: url) {
                            Label("Website", systemImage: "safari")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        let placemark = MKPlacemark(coordinate: spot.coordinate)
                        let item = MKMapItem(placemark: placemark)
                        item.name = spot.name
                        item.openInMaps(launchOptions: [
                            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
                        ])
                    } label: {
                        Label("Open in Maps", systemImage: "map")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let hours = spot.hours {
                    Label("Hours: \(hours)", systemImage: "clock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ZStack {
                    Map(position: $camera) {
                        Marker(spot.name, coordinate: spot.coordinate)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("How busy is it right now?")
                        .font(.headline)

                    HStack {
                        ForEach(BusyRating.allCases) { rating in
                            Button(rating.rawValue) {
                                selectedRating = rating
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedRating == rating ? Color(red: 0.12, green: 0.45, blue: 0.42) : .gray)
                        }
                    }

                    TextField("Optional note (e.g., quiet, lots of outlets)", text: $note)
                        .textFieldStyle(.roundedBorder)

                    Button(isSubmitting ? "Submitting..." : "Submit Report") {
                        guard let selectedRating else { return }

                        Task {
                            submitError = nil
                            submitSuccess = false
                            isSubmitting = true

                            await auth.signInAnonymouslyIfNeeded()

                            do {
                                try await service.submitReport(
                                    spot: spot,
                                    rating: selectedRating,
                                    note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
                                )

                                submitSuccess = true
                                note = ""
                                self.selectedRating = nil

                                // refresh data, then (optionally) pop open the sheet
                                await loadRecentReports()
                                showReportsSheet = true
                            } catch {
                                print("❌ submitReport error:", error)
                                submitError = error.localizedDescription
                            }

                            isSubmitting = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedRating == nil || isSubmitting)

                    if let submitError {
                        Text(submitError)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    if submitSuccess {
                        Text("✅ Report submitted!")
                            .foregroundStyle(.green)
                            .font(.footnote)
                    }

                    // ✅ Button to open the pull-up
                    Button {
                        Task {
                            await loadRecentReports()
                            showReportsSheet = true
                        }
                    } label: {
                        Label("View recent reports", systemImage: "list.bullet.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await auth.signInAnonymouslyIfNeeded()
            await loadRecentReports()
        }
        // ✅ Pull-up sheet
        .sheet(isPresented: $showReportsSheet) {
            ReportsSheetView(
                spotName: spot.name,
                isLoading: isLoadingRecentReports,
                reports: recentReports,
                onRefresh: {
                    await loadRecentReports()
                }
            )
            .presentationDetents([.fraction(0.25), .medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
