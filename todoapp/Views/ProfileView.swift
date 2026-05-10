import SwiftUI
import CryptoKit
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("user_email") private var storedEmail = ""
    @AppStorage("user_password_hash") private var storedHash = ""
    @AppStorage("user_is_logged_in") private var isLoggedIn = false
    @AppStorage("user_display_name") private var displayName = ""
    @AppStorage("user_avatar") private var avatarData: Data = Data()
    @AppStorage("user_job_title") private var jobTitle = ""
    @AppStorage("user_bio") private var bio = ""
    @AppStorage("user_goals") private var goals = ""

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var regJobTitle = ""
    @State private var regBio = ""
    @State private var regGoals = ""
    @State private var isRegister = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var photoItem: PhotosPickerItem?

    private let avatarSize: CGFloat = 72

    var body: some View {
        Group {
            if isLoggedIn {
                VStack(spacing: 0) {
                    header
                    loggedInView
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    header
                    authForm
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(hex: "f9f9f9"))
        .alert(alertMessage, isPresented: $showAlert) { Button("OK") {} }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "444748").opacity(0.6))
            }
            Spacer()
            Text("Profile")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "1a1c1c"))
            Spacer()
            Color.clear.frame(width: 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

            // MARK: - Auth Form

    private var authForm: some View {
        VStack(spacing: 20) {
            // Focus branding
            HStack(spacing: 6) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "1a1c1c"))
                Text("Focus")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))
            }
            .padding(.top, 24)
            .padding(.bottom, 8)

            Text(isRegister ? "Create account" : "Sign in")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "1a1c1c"))

            VStack(spacing: 12) {
                field("Email", text: $email, keyboard: .emailAddress)
                SecureField("Password", text: $password)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(hex: "ffffff"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "c4c7c7").opacity(0.3), lineWidth: 1)
                    )

                if isRegister {
                    SecureField("Confirm password", text: $confirmPassword)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(Color(hex: "1a1c1c"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(hex: "ffffff"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "c4c7c7").opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)

            if isRegister {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optional info")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "444748").opacity(0.5))
                        .padding(.leading, 4)

                    VStack(spacing: 10) {
                        field("Job title", text: $regJobTitle)
                        field("What do you do?", text: $regBio, axis: .vertical)
                            .frame(minHeight: 60)
                        field("Your goals", text: $regGoals, axis: .vertical)
                            .frame(minHeight: 60)
                    }
                }
                .padding(.horizontal, 20)
            }

            Button {
                isRegister ? register() : login()
            } label: {
                Text(isRegister ? "Create Account" : "Sign In")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "1a1c1c"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)

            Button {
                withAnimation { isRegister.toggle() }
            } label: {
                Text(isRegister ? "Already have an account? Sign In" : "Don't have an account? Create one")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color(hex: "006685"))
            }
        }
    }

    // MARK: - Logged In View

    private var loggedInView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar section
                PhotosPicker(selection: $photoItem, matching: .images) {
                    if avatarData.isEmpty {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "e2e2e2"))
                                .frame(width: avatarSize, height: avatarSize)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "444748").opacity(0.4))
                        }
                    } else {
                        Image(uiImage: UIImage(data: avatarData) ?? UIImage())
                            .resizable()
                            .scaledToFill()
                            .frame(width: avatarSize, height: avatarSize)
                            .clipShape(Circle())
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color(hex: "c4c7c7").opacity(0.2), lineWidth: 1)
                )

                Text(displayName.isEmpty ? storedEmail : displayName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))

                if !jobTitle.isEmpty {
                    Text(jobTitle)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color(hex: "444748").opacity(0.6))
                        .padding(.top, -16)
                }

                // Info cards
                VStack(spacing: 10) {
                    if !bio.isEmpty {
                        infoCard(icon: "person.text.rectangle", title: "About", text: bio)
                    }
                    if !goals.isEmpty {
                        infoCard(icon: "target", title: "Goals", text: goals)
                    }
                    infoCard(icon: "envelope", title: "Email", text: storedEmail)
                }
                .padding(.horizontal, 20)

                // Sign Out
                Button {
                    isLoggedIn = false
                    displayName = ""
                    jobTitle = ""
                    bio = ""
                    goals = ""
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14))
                        Text("Sign Out")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "c42b2b"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.top, 40)
            .padding(.bottom, 40)
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                await MainActor.run { avatarData = data }
            }
        }
    }

    // MARK: - Helpers

    private func field(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, axis: Axis = .horizontal) -> some View {
        TextField(placeholder, text: text, axis: axis)
            .font(.system(size: 15, design: .rounded))
            .foregroundColor(Color(hex: "1a1c1c"))
            .autocapitalization(.none)
            .keyboardType(keyboard)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(hex: "ffffff"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "c4c7c7").opacity(0.3), lineWidth: 1)
            )
    }

    private func infoCard(icon: String, title: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "006685"))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "444748").opacity(0.5))
                Text(text)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(hex: "ffffff"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "c4c7c7").opacity(0.2), lineWidth: 1)
        )
    }

    private func hash(_ value: String) -> String {
        let data = Data(value.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func register() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Fill in all fields"
            showAlert = true
            return
        }
        guard password == confirmPassword else {
            alertMessage = "Passwords don't match"
            showAlert = true
            return
        }
        guard password.count >= 6 else {
            alertMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }

        storedEmail = email
        storedHash = hash(password)
        displayName = email.components(separatedBy: "@").first ?? email
        jobTitle = regJobTitle
        bio = regBio
        goals = regGoals
        isLoggedIn = true
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Fill in all fields"
            showAlert = true
            return
        }
        guard email == storedEmail, hash(password) == storedHash else {
            alertMessage = "Invalid email or password"
            showAlert = true
            return
        }
        isLoggedIn = true
    }
}
