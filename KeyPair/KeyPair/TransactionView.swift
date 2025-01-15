//
//  TransactionView.swift
//  KeyPair
//
//  Created by James Pecoraro on 1/3/25.
//

import SwiftUI

struct TransactionView: View {
    let keyTag: String
    @State private var scannedCode: String?
    @State private var signatureQRImage: UIImage? = nil
    @State private var showAlert = false

    init(keyTag: String) {
        self.keyTag = keyTag
    }

    var body: some View {
        VStack {
            if let code = scannedCode {
                if let qrImage = signatureQRImage {
                    Text("Signature").font(.title)
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                }
                else {
                    if let tx = parseScannedTransaction(scannedCode: code) {
                        Text("Transaction").font(.title)
                        HStack {
                            Text("GSP:")
                            Spacer()
                            Text(tx.GSP)
                        }
                        HStack {
                            Text("VaultId:")
                            Spacer()
                            Text(String(tx.vaultId))
                        }
                        HStack {
                            Text("Amount:")
                            Spacer()
                            Text(String(tx.amount))
                        }
                        HStack {
                            Text("Asset:")
                            Spacer()
                            Text(tx.asset)
                        }
                        HStack {
                            Text("To:")
                            Spacer()
                            Text(tx.destination)
                        }
                        Spacer()
                        Button("Authorize?") {
                            showAlert = true
                        }
                        .alert("Are you sure?", isPresented: $showAlert) {
                            Button("Cancel", role: .cancel) {}
                            Button("Authorize", role: .destructive) {
                                signTransactionShowQR(tx)
                            }
                        } message: {
                            Text("You understand that you are authorizing a transfer that is not client initiated?")
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    else {
                        Text("Not a valid transaction")
                    }
                }
            } else {
                QRCodeScannerView(scannedCode: $scannedCode).frame(height: 300)
            }
        }
        .onAppear {
            scannedCode = nil
        }
    }

    func parseScannedTransaction(scannedCode: String) -> Transaction? {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Transaction.self, from: scannedCode.data(using: .utf8)! )
        } catch {
        }
        
        return nil
    }

    func signTransactionShowQR(_ tx: Transaction ) -> Bool {
        var txData: Data
        
        do {
            let encoder = JSONEncoder()
            txData = try encoder.encode( tx )
        } catch {
            return false
        }

        if let sig = KeyManagement.signData(keyTag: keyTag, data: txData) {
            let filter = CIFilter.qrCodeGenerator()
            filter.setValue(sig, forKey: "inputMessage")
            
            guard let outputImage = filter.outputImage else { return false }
            
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                signatureQRImage = UIImage(cgImage: cgImage)
                return true
            }
        }

        return false
    }
}

#Preview {
    TransactionView(keyTag: "com.bny.da.authorizerKey")
}
