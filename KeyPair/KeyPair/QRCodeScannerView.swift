//
//  QRCodeScannerView.swift
//  KeyPair
//
//  Created by James Pecoraro on 1/3/25.
//

import SwiftUI
import UIKit
import AVFoundation

class CameraView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()

        // Ensure the preview layer fills the entire view
        previewLayer?.frame = self.bounds
    }
}

struct QRCodeScannerView: UIViewRepresentable {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView

        init(parent: QRCodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               metadataObject.type == .qr,
               let scannedValue = metadataObject.stringValue {
                DispatchQueue.main.async {
                    self.parent.scannedCode = scannedValue
                }
//                output.metadataObjectsDelegate = nil // Optional: Prevent further detection
                let session = AVCaptureSession()
                session.stopRunning() // Stop the video preview
            }
        }
    }

    @Binding var scannedCode: String?
    var onScanCompleted: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let cameraView = CameraView()

        let session = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return cameraView }
        let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice)
        if let videoInput = videoInput, session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = cameraView.bounds
        cameraView.previewLayer = previewLayer
        cameraView.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        return cameraView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    @State @Previewable var scannedCode: String?

    QRCodeScannerView(scannedCode: $scannedCode)
}

