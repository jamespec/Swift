//
//  ShowPublicKey.swift
//  KeyPair
//
//  Created by James Pecoraro on 12/31/24.
//

import SwiftUI

struct ShowPublicKeyView: View {
    let keyTag: String
    @State private var publicKeyQRImage: UIImage? = nil
    @State private var keyGenerationError: String? = nil
    @State private var showAlert = false
    @State private var showAlert2 = false

    init(keyTag: String) {
        self.keyTag = keyTag
        _publicKeyQRImage = State(initialValue: createQRCodeFromPublicKey())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let qrImage = publicKeyQRImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                } else if let error = keyGenerationError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    Text("No public key available.")
                }
                Spacer()

                HStack {
                    Button("Regenerate") {
                        showAlert = true
                    }
                    .alert("Are you sure?", isPresented: $showAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Regenerate", role: .destructive) {
                            showAlert2 = true
                        }
                    } message: {
                        Text("The new key will need to be registered with the Verifier, contact Production Services before doing this.")
                    }
                    .alert("Did you read the warning carefully?", isPresented: $showAlert2) {
                        Button("Cancel", role: .cancel) {}
                        Button("Regenerate", role: .destructive) {
                            if KeyManagement.createAndStoreKeyInSecureEnclave(tag: keyTag) {
                                publicKeyQRImage = createQRCodeFromPublicKey()
                                print("Key successfully created and stored in Secure Enclave!")
                            } else {
                                print("Failed to create key.")
                            }
                        }
                    } message: {
                        Text("Make sure Production Services knows that they need to register a new key in the Verifier.")
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    SendMailView(keyTag: keyTag)
                }
            }
            .padding()
        }
        .navigationTitle("Key Management")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func createQRCodeFromPublicKey() -> UIImage? {
        if let publicKeyString = KeyManagement.fetchPublicKeyAsBase64String(forTag: keyTag) {
            print("Public key: \(publicKeyString)")
            
            let data = Data(publicKeyString.utf8)
            let filter = CIFilter.qrCodeGenerator()
            filter.setValue(data, forKey: "inputMessage")
            
            guard let outputImage = filter.outputImage else { return nil }
            
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}

#Preview {
    ShowPublicKeyView(keyTag: "com.bny.da.authorizerKey")
}
