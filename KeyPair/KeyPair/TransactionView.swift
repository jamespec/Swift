//
//  TransactionView.swift
//  KeyPair
//
//  Created by James Pecoraro on 1/3/25.
//

import SwiftUI


struct TransactionView: View {
    let keyTag: String
    @State private var scannedData: String? = nil
    @State private var signatureString: String? = nil
    @State private var signatureQRImage: UIImage? = nil
    @State private var showAlert = false

    init(keyTag: String) {
        self.keyTag = keyTag
    }

    var body: some View {
        VStack {
            if scannedData == nil {
                QRCodeScannerView(scannedData: $scannedData).frame(height: 300)
            }
            else if let code = scannedData {
                if let qrImage = signatureQRImage {
                    Text("Signature").font(.title)
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 300, height: 300)

                    if let sigString = signatureString {
                        SendMailView(sigString, "Approval")
                    }
                    else {
                        Text("Signature data is nil!")
                    }
                }
                else if let tx = parseScannedTransaction(scannedCode: code) {
                    Text("Transaction").font(.title)
                    HStack {
                        Text("GSP:"); Spacer(); Text(tx.GSP)
                    }
                    HStack {
                        Text("VaultId:"); Spacer(); Text(String(tx.vaultId))
                    }
                    HStack {
                        Text("Amount:"); Spacer(); Text(String(tx.amount))
                    }
                    HStack {
                        Text("Asset:"); Spacer(); Text(tx.asset)
                    }
                    HStack {
                        Text("To:"); Spacer(); Text(tx.destination)
                    }
                    Spacer()
                    Button("Authorize?") {
                        showAlert = true
                    }
                    .alert("Are you sure?", isPresented: $showAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Authorize", role: .destructive) {
                            signTransaction(tx)
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
        }
        .onAppear {
            scannedData = nil
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

    func signTransaction(_ tx: Transaction ) {
        var txData: Data
        
        do {
            let encoder = JSONEncoder()
            txData = try encoder.encode( tx )
            print("Encoded data: \(txData)")
        } catch {
            return
        }

        guard let sig = KeyManagement.signData(keyTag: keyTag, data: txData) else { return }
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(sig, forKey: "inputMessage")
        
        guard let outputImage = filter.outputImage else { return }
        
        let context = CIContext()
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            signatureQRImage = UIImage(cgImage: cgImage)
            signatureString = sig.base64EncodedString()
        }
    }
}

#Preview {
    TransactionView(keyTag: "com.bny.da.authorizerKey")
}
