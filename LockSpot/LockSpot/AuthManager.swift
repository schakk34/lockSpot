//
//  AuthManager.swift
//  LockSpot
//
//  Created by Shreya Chakraborty on 1/26/26.
//
import Foundation
import FirebaseAuth

@MainActor
final class AuthManager: ObservableObject {
    func signInAnonymouslyIfNeeded() async {
        if Auth.auth().currentUser != nil {
            return
        }
        do {
            _ = try await Auth.auth().signInAnonymously()
        } catch {
            print(error.localizedDescription)
        }
    }
}
