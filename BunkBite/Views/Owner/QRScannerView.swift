//
//  QRScannerView.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @ObservedObject var viewModel: ScannerViewModel
    let token: String
    
    var body: some View {
        ZStack {
            if viewModel.permissionGranted {
                CameraPreview(viewModel: viewModel, token: token)
                    .ignoresSafeArea()
                    .overlay(
                        ZStack {
                            Rectangle()
                                .fill(Color.black.opacity(0.5))
                            
                            RoundedRectangle(cornerRadius: 12)
                                .blendMode(.destinationOut)
                                .frame(width: 250, height: 250)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        .compositingGroup()
                    )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.gray)
                    
                    Text("Camera Access Required")
                        .font(.headline)
                    
                    Text("Please verify camera access in settings to scan QR codes.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.gray)
                    
                    Button("Check Permission") {
                        viewModel.checkCameraPermission()
                    }
                    .padding()
                    .background(Constants.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.checkCameraPermission()
        }
        .alert("Invalid QR Code", isPresented: Binding(
            get: { viewModel.scanError != nil },
            set: { if !$0 { viewModel.scanError = nil } }
        )) {
            Button("OK") {
                viewModel.scanError = nil
            }
        } message: {
            Text(viewModel.scanError ?? "The QR code is invalid or has expired.")
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var viewModel: ScannerViewModel
    let token: String
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return view
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Store session and layer in context for later use
        context.coordinator.captureSession = captureSession
        context.coordinator.previewLayer = previewLayer
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view size changes
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CameraPreview
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        init(parent: CameraPreview) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                      let stringValue = readableObject.stringValue else { return }
                
                // Prevent scanning the same code multiple times
                guard parent.viewModel.isScanning else { return }
                guard stringValue != parent.viewModel.lastScannedCode else { return }
                
                // Haptic feedback
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                print("📱 QR Code Scanned: \(stringValue)")
                
                Task {
                    await parent.viewModel.onCodeScanned(code: stringValue, token: parent.token)
                }
            }
        }
    }
}
