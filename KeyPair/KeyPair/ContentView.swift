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
    @AppStorage("email")  private var email: String = "james315@icloud.com"
    @AppStorage("keyTag") private var keyTag: String = "com.bny.da.authorizerKey"

    var body: some View {
        VStack(spacing: 20) {
            NavigationSplitView {
                Image("90BA458B-E209-42C7-BC6A-0641DA000B66")
                    .resizable()
                    .interpolation(.none)
                        .frame(width: 200, height: 100)
                Text("Digital Assets").bold().font(.title)
                Text("Transaction Authorization").bold().padding(0)

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
                        SettingsView(email: $email, keyTag: $keyTag)
                    } label: {
                        Text("Settings")
                    }
                }
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
