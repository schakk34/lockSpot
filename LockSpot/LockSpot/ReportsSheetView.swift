//
//  ReportsSheetView.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/27/26.
//
import SwiftUI

struct ReportsSheetView: View {
    let spotName: String
    let isLoading: Bool
    let reports: [BusyReport]
    let onRefresh: () async -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reports.isEmpty {
                    ContentUnavailableView(
                        "No reports yet",
                        systemImage: "clock",
                        description: Text("Be the first to submit one for \(spotName).")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(reports) { r in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(r.rating)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(width: 80, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 4) {
                                        if let note = r.note, !note.isEmpty {
                                            Text(note)
                                                .font(.footnote)
                                        }

                                        Text(r.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(12)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding()
                    }
                    .refreshable { await onRefresh() }
                }
            }
            .navigationTitle("Recent reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    Task { await onRefresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

