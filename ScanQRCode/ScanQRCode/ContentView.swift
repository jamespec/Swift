//
//  ContentView.swift
//  QR Scanner
//
//  Created by James Pecoraro on 12/31/24.
//

import SwiftUI
import AVFoundation


struct QRCodeScannerView: NSViewRepresentable {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView
        var session: AVCaptureSession?

        init(parent: QRCodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               metadataObject.type == .qr,
               let scannedValue = metadataObject.stringValue {
                parent.onCodeDetected(scannedValue)
            }
        }
    }

    var onCodeDetected: (String) -> Void
    let session = AVCaptureSession() // Persistent session instance

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(parent: self)
        coordinator.session = session
        return coordinator
    }

    func makeNSView(context: Context) -> NSView {
        let nsView = NSView(frame: .zero)

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return nsView
        }

        session.addInput(input)

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            //metadataOutput.metadataObjectTypes = [.qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = nsView.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        nsView.layer = previewLayer

        session.startRunning()
        return nsView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed for now
    }
    
    func teardown() {
        session.stopRunning()
    }
}

struct ContentView: View {
    @State private var detectedCode: String? = nil

    init() {
        requestCameraAccess { granted in
            if granted {
                // Proceed with camera usage
            } else {
                // Inform the user that camera access is required
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Scan a QR Code")
                .font(.headline)

            if let code = detectedCode {
                Text("Detected QR Code: \(code)")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding()
            } else {
                QRCodeScannerView { scannedValue in
                    self.detectedCode = scannedValue
                }
                .frame(width: 300, height: 300)
                .background(Color.gray.opacity(0.2))
                .border(Color.black, width: 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

func requestCameraAccess(completion: @escaping (Bool) -> Void) {
    AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
            if granted {
                print("Camera access granted")
            } else {
                print("Camera access denied")
            }
            completion(granted)
        }
    }
}
