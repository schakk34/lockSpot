//
//  ReportsService.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/26/26.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

final class ReportsService {
    private let db = Firestore.firestore()

    // spots/{spotId}/reports/{reportId}
    func submitReport(spot: Spot, rating: BusyRating, note: String?) async throws {
        let uid = Auth.auth().currentUser?.uid
        let reportId = UUID().uuidString

        let data: [String: Any] = [
            "id": reportId,
            "spotId": spot.id,
            "spotName": spot.name,
            "rating": rating.rawValue,
            "note": note as Any,
            "createdAt": Timestamp(date: Date()),
            "userId": uid as Any
        ]

        try await db.collection("spots")
            .document(spot.id)
            .collection("reports")
            .document(reportId)
            .setData(data)
    }

    func fetchRecentReports(spotId: String, limit: Int = 10) async throws -> [BusyReport] {
        let snap = try await db.collection("spots")
            .document(spotId)
            .collection("reports")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snap.documents.compactMap { doc in
            let d = doc.data()

            let rating = d["rating"] as? String ?? "Unknown"
            let spotName = d["spotName"] as? String ?? ""
            let note = d["note"] as? String
            let ts = d["createdAt"] as? Timestamp
            let createdAt = ts?.dateValue() ?? Date()
            let userId = d["userId"] as? String

            return BusyReport(
                id: doc.documentID,
                spotId: spotId,
                spotName: spotName,
                rating: rating,
                note: note,
                createdAt: createdAt,
                userId: userId
            )
        }
    }
}
