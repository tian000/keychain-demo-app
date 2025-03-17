//
//  ContentView.swift
//  napasapp2
//
//  Created by nudom on 3/11/25.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ContentView: View {
    @State private var showingShareSheet = false
    @State private var image = UIImage(systemName: "globe")!
    @State private var secretText = ""
    @State private var retrievedSecret = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    func debugRetrieveSecret() {
        print("🔍 Starting secret retrieval...")
        
        // Try to retrieve the secret
        let result = SDK.shared.retrieveSecretKey()
        print("📝 Retrieval result: \(result != nil ? "Got a value" : "No value found")")
        
        if let secret = result {
            print("✅ Successfully retrieved secret with length: \(secret.count)")
            retrievedSecret = secret
            alertMessage = "Retrieved secret: \(secret)"
        } else {
            print("❌ Failed to retrieve secret - returned nil")
            alertMessage = "No secret found"
        }
        showAlert = true
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            TextField("Enter secret to store", text: $secretText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Store Secret") {
                print("📥 Attempting to store secret: \(secretText)")
                if SDK.shared.storeSecretKey(secretText) {
                    print("✅ Secret stored successfully")
                    alertMessage = "Secret stored successfully!"
                    showAlert = true
                    secretText = ""
                } else {
                    print("❌ Failed to store secret")
                    alertMessage = "Failed to store secret"
                    showAlert = true
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Retrieve Secret") {
                debugRetrieveSecret()
            }
            .buttonStyle(.bordered)
            
            if !retrievedSecret.isEmpty {
                Text("Retrieved Secret: \(retrievedSecret)")
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Button("Share with Extension") {
                showingShareSheet = true
            }
            .padding()
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [image])
            }
        }
        .padding()
        .alert("Secret Operation", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    ContentView()
}
