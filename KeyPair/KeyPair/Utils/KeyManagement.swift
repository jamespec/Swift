//
//  KeyManagement.swift
//  KeyPair
//
//  Created by James Pecoraro on 12/31/24.
//

import Foundation
import Security

// This is a static utility class.  This could have been written as a Class or Struct with all static members as well.
// The use of enum also works and has the "benefit" of syntically prevent instantiation.
// I'm not a fan but it is a common idiom in Swift so, here it is...

enum KeyManagement {
    // KeyManagement routines using the Security API rather than the CryptoKit
    // The CryptoKit is higher level and much easier to use, eliminating much of the casting and deferencing.
    // The problem is that CryptoKit has very limited ability to manage the Keys by Tag.
    // If you only have a single key in your app then CryptoKit would be fine and desirable.
    
    static func createAndStoreKeyInSecureEnclave(tag: String) -> Bool {
        // You can't change a key in the SecureEnclave once created.
        // To reuse the tag you must delete the existing key first.
        // Creating a second with the same key is possible and VERY annoying.
        // You need to query for the set of keys with the tag and choose the one you want...

        if !deleteKey(forTag: tag) {
            print("Error deleting key")
            return false
        }
        
        // Define the attributes for the private key
        let privateKeyAttributes: [String: Any] = [
            kSecAttrIsPermanent as String: true,                // Make the key persistent
            kSecAttrApplicationTag as String: tag.data(using: .utf8) as Any // Tag to identify the key (Data)
        ]
        
        // Define the key pair attributes
        // Note that the SecureEnclave only supports Elliptic Curve with 256 bit curves, sorry, no Edwards.
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,            // Use elliptic curve cryptography
            kSecAttrKeySizeInBits as String: 256,                    // Key size
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave, // Store in Secure Enclave
            kSecPrivateKeyAttrs as String: privateKeyAttributes
        ]
        
        var error: Unmanaged<CFError>?
        
        // Generate the private key
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            print("Error creating key: \(error!.takeRetainedValue())")
            return false
        }
        
        // Key created, pull the Public Key and print to console.
        let publicKey = SecKeyCopyPublicKey(privateKey)
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey!, &error) as Data? else {
            print("Error fetching external representation: \(error!.takeRetainedValue())")
            return false
        }
        
        let publicKeyString = publicKeyData.base64EncodedString()
        print("Public key: \(publicKeyString)")
        
        return true
    }


    // Fetch from the SecureEnclave a reference to the private key to use for signing/encryption
    // The references happen to be stored in the keychain but this is an internal detail.
    // You'll see documentation, like below, that refers to the keychain, the real key is in the Enclave.
   
    static func fetchPrivateKeyReference(forTag tag: String) -> SecKey? {
        let tagData = tag.data(using: .utf8)!
        
        // Query for the key in the Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrApplicationTag as String: tagData,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            let privateKey = item as! SecKey
            return (privateKey)
        } else if status == errSecItemNotFound {
            print("No private key found for tag \(tag).")
        } else {
            print("Error retrieving private key: \(status).")
        }
        
        return nil
    }
    
    static func fetchPublicKeyAsBase64String(forTag keyTag:String) -> String? {
        let privateKey: SecKey? = KeyManagement.fetchPrivateKeyReference(forTag: keyTag)
        if privateKey == nil {
            print("No private key found for tag \(keyTag).")
            return nil
        }
        
        let publicKey = SecKeyCopyPublicKey(privateKey!)
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey!, nil) as Data? else {
            print("Failed to get external representation of the SecKey.")
            return nil
        }
        
        let publicKeyString = publicKeyData.base64EncodedString()
        return publicKeyString
    }


    // List All keys for this application to the console.
    // This is primarily for debugging purposes, you should know your key tags!
    static func listAllKeys() {
        // Query all Keys, return the attributes but don't need the keys themselves, just tag.
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,          // Look only for keys
            kSecReturnAttributes as String: true,       // Return attributes for the keys
            // kSecReturnRef as String: true,              // Include SecKey references in results
            kSecMatchLimit as String: kSecMatchLimitAll // Match all keys
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let items = result as? [[String: Any]] {
            print("Found \(items.count) keys:")
            
            for item in items {
                let tag = item[kSecAttrApplicationTag as String] as! Data
                print("Tag: \( String(data: tag, encoding: .utf8)! )")
            }
        } else if status == errSecItemNotFound {
            print("No keys found.")
        } else {
            print("Failed to query keys with status: \(status)")
        }
    }

    
    // Delete a key from the Secure Enclave for specified Tag
    static func deleteKey( forTag tag: String) -> Bool {
        // Define the query to match for a key in the Enclave.
        // Be specific to avoid inadvertantly deleting the wrong key, we add EC key type
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom
        ]
        
        // A request to delete a non-existant key will be treated as success.
        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            print("Failed to delete existing key: \(deleteStatus)")
            return false
        }
        
        return true
    }
    
    static func signData( keyTag tag: String, data: Data ) -> Data? {
        if let privateKey = fetchPrivateKeyReference(forTag: tag) {
            var error: Unmanaged<CFError>?
            let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256
            
            guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
                print("Algorithm not supported")
                return nil
            }
            
            guard let signature = SecKeyCreateSignature(privateKey, algorithm, data as CFData, &error) else {
                print("Error signing data: \(error!.takeRetainedValue())")
                return nil
            }
            
            return signature as Data
        }
        return nil
    }
    
    static func verifySignature(keyTag tag: String, signature: Data, data: Data) -> Bool {
        let privateKey: SecKey? = KeyManagement.fetchPrivateKeyReference(forTag: tag)
        if privateKey == nil {
            print("No private key found for tag \(tag).")
            return false
        }
        
        let publicKey = SecKeyCopyPublicKey(privateKey!)
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey!, nil) as Data? else {
            print("Failed to get external representation of the SecKey.")
            return false
        }

        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256
        
        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(publicKey!, algorithm, data as CFData, signature as CFData, &error)
        
        if let error = error {
            print("Error verifying signature: \(error.takeRetainedValue())")
        }
        return result
    }
}
