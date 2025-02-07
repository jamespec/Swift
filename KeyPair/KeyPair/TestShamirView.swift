//
//  TransactionView.swift
//  KeyPair
//
//  Created by James Pecoraro on 1/3/25.
//

import SwiftUI


struct TestShamirView: View {
    @State private var secret: String = ""
    @State private var newSecret: String = ""
    @State private var share1: String = ""
    @State private var share2: String = ""
    @State private var recovered: String = "test"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Secret to Share").foregroundColor(secret != newSecret ? .red : .blue)) {
                    TextField("Secret", text: $newSecret)
                }

                Section(header: Text("Share1")) {
                    TextField("Share1", text: $share1)
                    TextField("Share2", text: $share2)
                    Text(recovered)
                }

                Section {
                    HStack {
                        Button("Generate") {
                            secret = newSecret
                            var shares = ShamirSecrets.generateShares(secretString: secret, totalShares: 2, threshold: 2)
                            share1 = shares[0]
                            share2 = shares[1]
                            shares = ["801670d806d65dc971fd0c0aaf28e7bdae7", "802ce1a1ddacaa6338fbd29494d0159a90b"]
                            
                            if let data = ShamirSecrets.recoverSecret(shares: shares, threshold: 2) {
                                recovered = data
                            }
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

}

#Preview {
    TestShamirView()
}
