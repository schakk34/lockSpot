//
//  ContentView.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/26/26.
//

import SwiftUI

struct ContentView: View {
    private static let tips = [
        "Tap a pin to open details, then submit a quick report.",
        "Check out recent reports to see what others have to say.",
        "Add in comments to specify floor details.",
        "Click on a pin to enlarge it.",
        "If you want to see how far it is, open the spot in Maps!"
    ]

    @State private var tipIndex = 0
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("hero_image")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                LinearGradient(
                    colors: [Color.blue.opacity(0.20), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {

                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("LockSpot")
                            .font(.system(size: 48, weight: .black)) // BIG + heavy
                            .foregroundStyle(.white)

                        Text("Powered by community check-ins.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .multilineTextAlignment(.center)

                    NavigationLink {
                        SpotListView()
                    } label: {
                        HStack {
                            Spacer()
                            Text("View Study Spots")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.12, green: 0.45, blue: 0.42))

                    VStack(spacing: 6) {
                        Text("Tip")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(Self.tips[tipIndex])
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .onAppear {
                        if hasAppeared {
                            tipIndex = (tipIndex + 1) % Self.tips.count
                        } else {
                            hasAppeared = true
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
