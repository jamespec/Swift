//
//  ShowPublicKey.swift
//  KeyPair
//
//  Created by James Pecoraro on 12/31/24.
//

import SwiftUI

struct ShowPublicKeyView: View {
    let keyTag: String
    @State private var publicKeyData: String? = nil
    @State private var publicKeyQRImage: UIImage? = nil
    @State private var keyGenerationError: String? = nil
    @State private var showAlert = false
    @State private var showAlert2 = false

    init(keyTag: String) {
        self.keyTag = keyTag

        guard let pkString = KeyManagement.fetchPublicKeyAsBase64String(forTag: keyTag) else { return }
        print("ShowPublicKeyView:init - Loaded: \(pkString)")
        _publicKeyData = State( initialValue: pkString )
    
        guard let qrImage = createQRCodeFromPublicKey(pkString) else { return }
        _publicKeyQRImage = State(initialValue: qrImage)
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
                            print("--- Creating new key ---")
                            if KeyManagement.createAndStoreKeyInSecureEnclave(tag: keyTag) {
                                guard let pkString = KeyManagement.fetchPublicKeyAsBase64String(forTag: keyTag) else {
                                    print("Failed to create key.")
                                    return
                                }
                                publicKeyData = pkString
                                publicKeyQRImage = createQRCodeFromPublicKey(pkString)
                            } else {
                                print("!!! Unable to create key in the Secure Enclage !!!")
                            }
                        }
                    } message: {
                        Text("Make sure Production Services knows that they need to register a new key in the Verifier.")
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    if let pkData = publicKeyData {
                        SendMailView(pkData, "Public Key")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Public Key")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func createQRCodeFromPublicKey(_ keyData: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue( Data(keyData.utf8), forKey: "inputMessage")

        guard let outputImage = filter.outputImage else { return nil }
 
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    ShowPublicKeyView(keyTag: "com.bny.da.authorizerKey")
}
