//
//  PhantomSDK.swift
//  PhantomSDK
//
//  Created by Maxim Geerinck on 12/03/2025.
//


import Foundation
import Security
import CommonCrypto

public class SDK {
    // Singleton pattern to ensure only one instance of the SDK
    public static let shared = SDK()
    
    // App group identifier - this should be configured in your entitlements
    private let appGroupIdentifier = "group.app.phantom.sdkgroup"
    
    // Service name for keychain
    private let keychainServiceName = "app.phantom.sdk.keychain"
    
    // Secret salt that only exists within the SDK and is never exposed
    // This ensures that even if the app tries to read the keychain item,
    // it wouldn't be able to decode the value correctly
    private let secretSalt = "rT5$k9L@pZ7*xC2!qY3&jW8"
    
    // Private encryption key only known to the SDK
    private let encryptionKey: [UInt8] = [
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
        0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
    ]
    
    // Private initializer to enforce singleton pattern
    private init() {
        // Initialize any required components
    }
    
    // Public method that can be called from the test app
    public func performOperation(with data: String) -> String {
        // Example operation using the data
        return "MySDK processed: \(data)"
    }
    
    // Method to store a secret key in the keychain that only the SDK can access
    public func storeSecretKey(_ key: String) -> Bool {
        print("🔐 SDK: Starting to store secret key")
        
        // First, encrypt the key with the SDK's private encryption logic
        guard let encryptedData = encrypt(string: key + secretSalt) else {
            print("❌ SDK: Failed to encrypt data")
            return false
        }
        print("✅ SDK: Successfully encrypted data")
        
        // First, try to delete any existing items
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Create a keychain query using the standard keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecValueData as String: encryptedData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        print("🔑 SDK: Attempting to store in keychain with service: \(keychainServiceName)")
        
        // Add the new key to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ SDK: Successfully stored in keychain")
        } else {
            print("❌ SDK: Failed to store in keychain. Status: \(status)")
        }
        
        return status == errSecSuccess
    }
    
    // Method to retrieve the secret key from the keychain
    public func retrieveSecretKey() -> String? {
        print("🔍 SDK: Starting to retrieve secret key")
        
        // Create a keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne // Changed from kSecMatchLimitAll
        ]
        
        print("🔑 SDK: Querying keychain with service: \(keychainServiceName)")
        
        // Try to fetch the key from the keychain
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            print("✅ SDK: Successfully retrieved item from keychain")
            if let data = dataTypeRef as? Data {
                print("📦 SDK: Found data of length: \(data.count)")
                if let decryptedString = decrypt(data: data) {
                    print("🔓 SDK: Successfully decrypted data")
                    // Check if this decrypted string contains our salt
                    if decryptedString.hasSuffix(secretSalt) {
                        let actualKey = String(decryptedString.dropLast(secretSalt.count))
                        print("✅ SDK: Found valid secret key")
                        return actualKey
                    } else {
                        print("⚠️ SDK: Decrypted data doesn't contain valid salt")
                    }
                } else {
                    print("❌ SDK: Failed to decrypt data")
                }
            } else {
                print("⚠️ SDK: Retrieved data is not in expected format")
            }
        } else {
            print("❌ SDK: Failed to retrieve from keychain. Status: \(status)")
        }
        
        print("❌ SDK: No valid secret key found")
        return nil
    }
    
    
    // Basic encryption function (in a real implementation, use a more sophisticated approach)
    private func encrypt(string: String) -> Data? {
       guard let data = string.data(using: .utf8) else { return nil }
       
       var encryptedData = Data(count: data.count)
       
       // Use modern Swift buffer API to properly handle pointers
       data.withUnsafeBytes { rawBufferPointer in
           let dataBytes = rawBufferPointer.bindMemory(to: UInt8.self)
           
           encryptedData.withUnsafeMutableBytes { mutableRawBufferPointer in
               let encryptedBytes = mutableRawBufferPointer.bindMemory(to: UInt8.self)
               
               for i in 0..<data.count {
                   let keyByte = encryptionKey[i % encryptionKey.count]
                   encryptedBytes[i] = dataBytes[i] ^ keyByte
               }
           }
       }
       
       return encryptedData
   }
   
   // Basic decryption function
   private func decrypt(data: Data) -> String? {
       var decryptedData = Data(count: data.count)
       
       // Use modern Swift buffer API to properly handle pointers
       data.withUnsafeBytes { rawBufferPointer in
           let dataBytes = rawBufferPointer.bindMemory(to: UInt8.self)
           
           decryptedData.withUnsafeMutableBytes { mutableRawBufferPointer in
               let decryptedBytes = mutableRawBufferPointer.bindMemory(to: UInt8.self)
               
               for i in 0..<data.count {
                   let keyByte = encryptionKey[i % encryptionKey.count]
                   decryptedBytes[i] = dataBytes[i] ^ keyByte
               }
           }
       }
       
       return String(data: decryptedData, encoding: .utf8)
   }
}





