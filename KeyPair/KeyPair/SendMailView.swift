//
//  MailView.swift
//  KeyPair
//
//  Created by James Pecoraro on 1/3/25.
//

import SwiftUI
import MessageUI


struct SendMailView: View {
    let keyTag: String
    private var publicKeyString: String? = nil
    @State private var showingMailView = false
    @State private var mailServiceUnavailable = false

    init(keyTag: String) {
        self.keyTag = keyTag
        publicKeyString = KeyManagement.fetchPublicKeyAsBase64String(forTag: keyTag)
    }
    
    var body: some View {
        VStack {
            Button(action: {
                if MFMailComposeViewController.canSendMail() {
                    showingMailView.toggle()
                } else {
                    mailServiceUnavailable = true
                }
            }) {
                Text("Send Email")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showingMailView) {
            MailView(
                recipients: ["james315@icloud.com"],
                subject: "Authorization",
                body: publicKeyString!
            )
        }
        .alert(isPresented: $mailServiceUnavailable) {
            Alert(
                title: Text("Error"),
                message: Text("Mail services are not available."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    SendMailView(keyTag: "com.bny.da.authorizerKey")
}

struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    var recipients: [String]
    var subject: String
    var body: String
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                self.parent.presentation.wrappedValue.dismiss()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = context.coordinator
        mailComposeVC.setToRecipients(recipients)
        mailComposeVC.setSubject(subject)
        mailComposeVC.setMessageBody(body, isHTML: false)
        return mailComposeVC
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

