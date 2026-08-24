//
//  OptionalsExampleView.swift
//  github_repo_search_iOS_app
//
//  Swift Optionals Examples
//
//  Demonstrates optional types, unwrapping, optional binding, nil coalescing,
//  optional chaining, and the guard statement.
//

import SwiftUI

struct OptionalsExampleView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    OptionalsHeaderCard()

                    // Example 1: Optional Declaration & Unwrapping
                    OptionalUnwrappingExample()

                    // Example 2: Optional Binding (if let)
                    OptionalBindingExample()

                    // Example 3: Nil Coalescing
                    NilCoalescingExample()

                    // Example 4: Optional Chaining
                    OptionalChainingExample()

                    // Example 5: Guard Statement
                    GuardStatementExample()

                    // Best Practices
                    OptionalsBestPracticesCard()
                }
                .padding()
            }
            .navigationTitle("Optionals")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Header Card

struct OptionalsHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.blue)
                Text("Swift Optionals")
                    .font(.headline)
            }

            Text("""
            Optionals represent a value that might be absent.
            Type? means "value or nil"

            Key Concepts:
            • Optional declaration (String?, Int?)
            • Force unwrapping (!)
            • Optional binding (if let, guard let)
            • Nil coalescing (??)
            • Optional chaining (?.)
            """)
            .font(.caption)
            .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Example 1: Optional Unwrapping

struct OptionalUnwrappingExample: View {
    @State private var userInput: String = ""
    @State private var result: String = ""

    var body: some View {
        ExampleCard(
            title: "1. Optional Declaration & Unwrapping",
            description: "Understanding optional types and safe unwrapping"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Enter a number", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)

                Button("Convert to Int (Safely)") {
                    safeConvert()
                }
                .buttonStyle(.borderedProminent)

                Button("Convert to Int (Force Unwrap - Dangerous!)") {
                    forceUnwrap()
                }
                .buttonStyle(.bordered)
                .tint(.red)

                if !result.isEmpty {
                    Text(result)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }

                CodeExample("""
                // Declaration
                var optionalInt: Int? = nil  // Can be nil
                var regularInt: Int = 0     // Cannot be nil

                // Conversion
                let number = Int(userInput)  // Returns Int?

                // ✅ GOOD: Safe unwrapping
                if let unwrapped = number {
                    print("Number: \\(unwrapped)")
                } else {
                    print("Invalid input")
                }

                // ❌ BAD: Force unwrapping (crashes if nil!)
                let forced = number!  // Runtime crash if nil
                """)
            }
        }
    }

    private func safeConvert() {
        if let number = Int(userInput) {
            result = "✅ Success! Converted '\(userInput)' to Int: \(number)"
        } else {
            result = "⚠️ Invalid input. '\(userInput)' is not a valid number."
        }
    }

    private func forceUnwrap() {
        // This demonstrates why force unwrapping is dangerous
        if let _ = Int(userInput) {
            result = "✅ Force unwrap would work here (but still dangerous!)"
        } else {
            result = "❌ Force unwrap would CRASH here! App would terminate."
        }
    }
}

// MARK: - Example 2: Optional Binding

struct OptionalBindingExample: View {
    @State private var username: String = ""
    @State private var age: String = ""
    @State private var validationResult: String = ""

    var body: some View {
        ExampleCard(
            title: "2. Optional Binding (if let, guard let)",
            description: "Safely unwrap multiple optionals at once"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)

                TextField("Age", text: $age)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)

                Button("Validate User") {
                    validateUser()
                }
                .buttonStyle(.borderedProminent)

                if !validationResult.isEmpty {
                    Text(validationResult)
                        .font(.subheadline)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }

                CodeExample("""
                // Multiple optional binding
                if let name = optionalName,
                   let userAge = Int(ageString),
                   userAge >= 18 {
                    print("Valid: \\(name), \\(userAge)")
                } else {
                    print("Invalid user data")
                }

                // guard let (early exit)
                guard let name = optionalName,
                      let userAge = Int(ageString) else {
                    print("Missing data")
                    return
                }
                // name and userAge available here
                """)
            }
        }
    }

    private func validateUser() {
        if let name = username.isEmpty ? nil : username,
           let userAge = Int(age),
           userAge >= 18 {
            validationResult = "✅ Valid user: \(name), age \(userAge)"
        } else if username.isEmpty {
            validationResult = "⚠️ Username is required"
        } else if let userAge = Int(age), userAge < 18 {
            validationResult = "⚠️ Must be 18 or older (got \(userAge))"
        } else {
            validationResult = "⚠️ Invalid age input"
        }
    }
}

// MARK: - Example 3: Nil Coalescing

struct NilCoalescingExample: View {
    @State private var optionalName: String = ""
    @State private var displayName: String = ""

    var body: some View {
        ExampleCard(
            title: "3. Nil Coalescing Operator (??)",
            description: "Provide default values for optionals"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Enter name (or leave empty)", text: $optionalName)
                    .textFieldStyle(.roundedBorder)

                Button("Get Display Name") {
                    let name: String? = optionalName.isEmpty ? nil : optionalName
                    displayName = name ?? "Guest"
                }
                .buttonStyle(.borderedProminent)

                if !displayName.isEmpty {
                    Text("Display name: \(displayName)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }

                CodeExample("""
                let name: String? = userName

                // Nil coalescing
                let display = name ?? "Guest"
                // If name is nil, uses "Guest"

                // Chaining nil coalescing
                let final = primaryName ?? secondaryName ?? "Unknown"

                // Common use cases
                let count = items?.count ?? 0
                let title = book?.title ?? "Untitled"
                """)
            }
        }
    }
}

// MARK: - Example 4: Optional Chaining

struct OptionalChainingExample: View {
    @State private var result: String = ""

    struct User {
        var profile: Profile?
    }

    struct Profile {
        var address: Address?
    }

    struct Address {
        var city: String
    }

    var body: some View {
        ExampleCard(
            title: "4. Optional Chaining (?.)",
            description: "Access nested optionals safely"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button("Get User City (with profile)") {
                    let user = User(profile: Profile(address: Address(city: "San Francisco")))
                    result = "City: \(user.profile?.address?.city ?? "Unknown")"
                }
                .buttonStyle(.borderedProminent)

                Button("Get User City (no profile)") {
                    let user = User(profile: nil)
                    result = "City: \(user.profile?.address?.city ?? "Unknown")"
                }
                .buttonStyle(.bordered)

                if !result.isEmpty {
                    Text(result)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                CodeExample("""
                struct User {
                    var profile: Profile?
                }

                struct Profile {
                    var address: Address?
                }

                struct Address {
                    var city: String
                }

                let user: User? = getUser()

                // Optional chaining
                let city = user?.profile?.address?.city
                // Returns String? (nil if any step is nil)

                // Without optional chaining (verbose!)
                if let u = user {
                    if let p = u.profile {
                        if let a = p.address {
                            let c = a.city
                        }
                    }
                }
                """)
            }
        }
    }
}

// MARK: - Example 5: Guard Statement

struct GuardStatementExample: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loginResult: String = ""

    var body: some View {
        ExampleCard(
            title: "5. Guard Statement (Early Exit)",
            description: "Validate requirements and exit early"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                Button("Login") {
                    attemptLogin()
                }
                .buttonStyle(.borderedProminent)

                if !loginResult.isEmpty {
                    Text(loginResult)
                        .font(.subheadline)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }

                CodeExample("""
                func login(email: String?, password: String?) {
                    // Guard validates and exits early
                    guard let email = email,
                          !email.isEmpty else {
                        print("Email required")
                        return  // Early exit
                    }

                    guard let pass = password,
                          pass.count >= 8 else {
                        print("Password must be 8+ chars")
                        return  // Early exit
                    }

                    // email and pass are available here (unwrapped)
                    performLogin(email: email, password: pass)
                }

                // vs if let (nested and harder to read)
                func loginBad(email: String?, password: String?) {
                    if let email = email, !email.isEmpty {
                        if let pass = password, pass.count >= 8 {
                            performLogin(email: email, password: pass)
                        } else {
                            print("Password issue")
                        }
                    } else {
                        print("Email issue")
                    }
                }
                """)
            }
        }
    }

    private func attemptLogin() {
        guard !email.isEmpty else {
            loginResult = "⚠️ Email is required"
            return
        }

        guard email.contains("@") else {
            loginResult = "⚠️ Invalid email format"
            return
        }

        guard !password.isEmpty else {
            loginResult = "⚠️ Password is required"
            return
        }

        guard password.count >= 8 else {
            loginResult = "⚠️ Password must be at least 8 characters"
            return
        }

        loginResult = "✅ Login successful for \(email)"
    }
}

// MARK: - Best Practices Card

struct OptionalsBestPracticesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best Practices")
                .font(.headline)

            Text("""
            ✅ DO:
            • Use if let or guard let for safe unwrapping
            • Use nil coalescing (??) for default values
            • Use optional chaining (?.) for nested access
            • Prefer guard for early exit/validation

            ❌ DON'T:
            • Force unwrap (!) unless 100% certain
            • Use implicitly unwrapped optionals (!) unless necessary
            • Ignore compiler warnings about optionals

            When to use each:
            • if let: When you need optional logic
            • guard let: For validation/early exit
            • ??: For default values
            • ?.: For nested optional access
            """)
            .font(.caption)
            .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct OptionalsExampleView_Previews: PreviewProvider {
    static var previews: some View {
        OptionalsExampleView()
    }
}
