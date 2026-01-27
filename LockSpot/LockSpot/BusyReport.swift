//
//  BusyReport.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/26/26.
//
import Foundation

struct BusyReport: Identifiable {
    let id: String
    let spotId: String
    let spotName: String
    let rating: String
    let note: String?
    let createdAt: Date
    let userId: String?
}
