//
//  SettingsView.swift
//  KeyPair
//
//  Created by James Pecoraro on 1/17/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var email: String
    @Binding var keyTag: String
    @State private var newEmail: String = ""
    @State private var newKeyTag: String = ""
    @State private var changes: Bool = false
    
    init( email: Binding<String>, keyTag: Binding<String> ) {
        self._email = email
        self._keyTag = keyTag
        
        _newEmail = State(initialValue: email.wrappedValue)
        _newKeyTag = State(initialValue: keyTag.wrappedValue)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Production Services Email").foregroundColor(email != newEmail ? .red : .blue)) {
                    TextField("Email", text: $newEmail)
                }
                
                Section(header: Text("Key Name in Enclave").foregroundColor(keyTag != newKeyTag ? .red : .blue)) {
                    TextField("Key ", text: $newKeyTag)
                }
                
                Section {
                    HStack {
                        Button("Update") {
                            email = newEmail
                            keyTag = newKeyTag
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        if( email != newEmail || keyTag != newKeyTag ) {
                            Text("Changes to be saved").foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}

#Preview {
    @State @Previewable var email: String = "james"
    @State @Previewable var keyTag: String = "foo"

    SettingsView(email: $email, keyTag: $keyTag)
}

