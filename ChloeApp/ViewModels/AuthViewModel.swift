import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signIn(email: String) async {
        // TODO: Implement authentication
        isLoading = true
        defer { isLoading = false }

        self.email = email
        isAuthenticated = true
    }

    func signOut() {
        isAuthenticated = false
        email = ""
    }
}
