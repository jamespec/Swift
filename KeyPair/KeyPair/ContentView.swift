//
//  ContentView.swift
//  KeyPair
//
//  Created by James Pecoraro on 12/26/24.
//

import Foundation
import Security

import SwiftUI
import CryptoKit
import CoreImage.CIFilterBuiltins


struct ContentView: View {
    private let keyTag = "com.bny.da.authorizerKey"

    var body: some View {
        VStack(spacing: 20) {
            Image("90BA458B-E209-42C7-BC6A-0641DA000B66")
                .resizable()
                .interpolation(.none)
                .frame(width: 200, height: 100)
            Text("Digital Assets").bold().font(.title)
            Text("Transaction Authorization").bold().padding(0)

            NavigationSplitView {
                List {
                    NavigationLink {
                        TransactionView(keyTag: keyTag)
                    } label: {
                        Text("Sign Transaction")
                    }
                    NavigationLink {
                        ShowPublicKeyView(keyTag: keyTag)
                    } label: {
                        Text("Show PublicKey")
                    }
                    NavigationLink {
                        SendMailView(keyTag: keyTag)
                    } label: {
                        Text("Email PublicKey")
                    }
                }
                .navigationTitle("Operations")
            } detail: {
                Text("Select an Operation")
            }
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
