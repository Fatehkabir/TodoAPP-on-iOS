import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                
                Image(systemName: "checklist")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text(isSignUpMode ? "Create Account" : "Welcome Back")
                    .font(.largeTitle)
                    .bold()
                    .animation(.easeInOut, value: isSignUpMode)

                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        SecureField("Password", text: $password)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Button {
                    _Concurrency.Task { await handleAuth() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isSignUpMode ? "Sign Up" : "Log In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Button {
                    withAnimation {
                        isSignUpMode.toggle()
                        errorMessage = ""
                    }
                } label: {
                    Text(isSignUpMode
                         ? "Already have an account? Log In"
                         : "Don't have an account? Sign Up")
                        .font(.footnote)
                }

                Spacer()
                Spacer()
            }
            .padding()
        }
    }

    @MainActor
    private func handleAuth() async {
        errorMessage = ""
        isLoading = true
        defer { isLoading = false }

        do {
            if isSignUpMode {
                try await FirebaseManager.shared.signUp(email: email, password: password)
            } else {
                try await FirebaseManager.shared.login(email: email, password: password)
            }
            withAnimation {
                isLoggedIn = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}
