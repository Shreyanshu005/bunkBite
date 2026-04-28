import Foundation
import AVFoundation
import Combine
import UIKit

enum QRVerificationResult {
    case success(Order)
    case alreadyPickedUp(Order, String)
    case invalidQR(String)
}

@MainActor
class ScannerViewModel: ObservableObject {
    @Published var scannedOrder: Order?
    @Published var scanError: String?
    @Published var isScanning = true
    @Published var permissionGranted = false
    @Published var isLoading = false
    @Published var showPickupSuccess = false
    @Published var showAlreadyPickedUp = false
    @Published var alreadyPickedUpMessage: String = ""
    @Published var lastScannedCode: String = ""

    private let apiService = APIService.shared

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                }
            }
        default:
            permissionGranted = false
        }
    }

    func onCodeScanned(code: String, token: String) async {
        guard isScanning else { return }
        isScanning = false
        lastScannedCode = code
        isLoading = true
        scanError = nil
        showAlreadyPickedUp = false

        do {
            let order = try await apiService.verifyQR(qrData: code, token: token)
            scannedOrder = order
        } catch {

            let errorString = error.localizedDescription
            if errorString.contains("already picked up") || errorString.contains("completed") {
                showAlreadyPickedUp = true
                alreadyPickedUpMessage = "This order has already been picked up"

            } else {
                scanError = "Invalid or expired QR code"
            }
            isScanning = true
        }

        isLoading = false
    }

    func completePickup(qrData: String, token: String) async {
        isLoading = true
        scanError = nil
        showAlreadyPickedUp = false

        do {
            let order = try await apiService.completePickup(qrData: qrData, token: token)
            scannedOrder = order
            showPickupSuccess = true

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {

            let errorString = error.localizedDescription
            if errorString.contains("already picked up") || errorString.contains("completed") {
                showAlreadyPickedUp = true
                alreadyPickedUpMessage = "Order already picked up/completed"
            } else {
                scanError = "Failed to complete pickup. Please try again."
            }
        }

        isLoading = false
    }

    func resetScan() {
        scannedOrder = nil
        scanError = nil
        isScanning = true
        showPickupSuccess = false
        showAlreadyPickedUp = false
        alreadyPickedUpMessage = ""
        lastScannedCode = ""
    }
}
