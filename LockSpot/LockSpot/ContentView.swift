//
//  ContentView.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/26/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack{
            VStack {
                Text("Lock Spot").font(.largeTitle).fontWeight(.bold)
                Text("Find the perfect spot for your next lock in.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                NavigationLink("View Study Spots") {
                    SpotListView()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
