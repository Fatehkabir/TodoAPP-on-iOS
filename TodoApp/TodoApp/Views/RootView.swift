import SwiftUI

struct RootView: View {
    @State private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn {
                TaskListView(isLoggedIn: $isLoggedIn)
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            isLoggedIn = FirebaseManager.shared.currentUserId != nil
        }
    }
}

#Preview {
    RootView()
}
