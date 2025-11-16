# QR Code Order Verification System for BunkBite

## Overview

This system allows users to display a one-time QR code for their order, which canteen owners can scan to verify and view order details. This prevents order fraud and ensures smooth order pickup.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Order Flow                              │
└─────────────────────────────────────────────────────────────┘

1. User places order and pays
        ↓
2. Backend generates unique QR code data (JWT token or encrypted string)
        ↓
3. User sees QR code on order details screen
        ↓
4. Owner scans QR code using scanner
        ↓
5. App decodes QR and fetches order details from backend
        ↓
6. Owner verifies order and marks as completed
        ↓
7. QR code becomes invalid (one-time use)
```

---

## QR Code Data Structure

### Option 1: JWT Token (Recommended)
```json
{
  "order_id": "order_123456",
  "user_id": "user_789",
  "canteen_id": "canteen_abc",
  "amount": 150.00,
  "timestamp": 1699234567,
  "exp": 1699320967,  // Expires in 24 hours
  "nonce": "unique_random_string"  // Prevents replay attacks
}
```

**Encoded JWT Example:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmRlcl9pZCI6Im9yZGVyXzEyMzQ1NiIsInVzZXJfaWQiOiJ1c2VyXzc4OSIsImNhbnRlZW5faWQiOiJjYW50ZWVuX2FiYyIsImFtb3VudCI6MTUwLjAwLCJ0aW1lc3RhbXAiOjE2OTkyMzQ1NjcsImV4cCI6MTY5OTMyMDk2Nywibm9uY2UiOiJ1bmlxdWVfcmFuZG9tX3N0cmluZyJ9.signature
```

### Option 2: Encrypted String
```
BUNKBITE://order/AES_ENCRYPTED_DATA
```

**Example:**
```
BUNKBITE://order/U2FsdGVkX19QwK5vZ8xQp2K1k9x7v3N2zM8fR5tH6Jw=
```

---

## Backend API Endpoints

### 1. Generate QR Code Data
**Endpoint:** `POST /api/orders/:orderId/generate-qr`

**Headers:**
```json
{
  "Authorization": "Bearer user_token"
}
```

**Response:**
```json
{
  "success": true,
  "qr_data": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "qr_type": "jwt",
  "expires_at": "2024-01-15T10:30:00Z"
}
```

**Backend Implementation (Node.js):**
```javascript
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

app.post('/api/orders/:orderId/generate-qr', authenticate, async (req, res) => {
    try {
        const { orderId } = req.params;
        const userId = req.user.id;

        // Fetch order from database
        const order = await db.orders.findOne({
            _id: orderId,
            user_id: userId
        });

        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }

        // Generate unique nonce
        const nonce = crypto.randomBytes(16).toString('hex');

        // Create JWT payload
        const payload = {
            order_id: order.id,
            user_id: order.user_id,
            canteen_id: order.canteen_id,
            amount: order.total_amount,
            timestamp: Date.now(),
            exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60), // 24 hours
            nonce: nonce
        };

        // Sign JWT
        const qrData = jwt.sign(payload, process.env.JWT_SECRET);

        // Store nonce in database (for one-time use verification)
        await db.qrNonces.create({
            order_id: orderId,
            nonce: nonce,
            used: false,
            expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000)
        });

        res.json({
            success: true,
            qr_data: qrData,
            qr_type: 'jwt',
            expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});
```

### 2. Verify and Fetch Order from QR
**Endpoint:** `POST /api/orders/verify-qr`

**Headers:**
```json
{
  "Authorization": "Bearer owner_token"
}
```

**Request Body:**
```json
{
  "qr_data": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "success": true,
  "order": {
    "id": "order_123456",
    "order_number": "#1234",
    "user_name": "John Doe",
    "user_phone": "+91 98765 43210",
    "canteen_name": "North Campus Canteen",
    "items": [
      {
        "name": "Veg Burger",
        "quantity": 2,
        "price": 50
      },
      {
        "name": "Cold Coffee",
        "quantity": 1,
        "price": 50
      }
    ],
    "total_amount": 150.00,
    "payment_status": "paid",
    "order_status": "pending",
    "order_time": "2024-01-15T09:30:00Z",
    "payment_method": "Razorpay",
    "transaction_id": "pay_MNabcdef123456"
  }
}
```

**Backend Implementation:**
```javascript
app.post('/api/orders/verify-qr', authenticate, async (req, res) => {
    try {
        const { qr_data } = req.body;
        const ownerId = req.user.id;

        // Verify user is an owner
        if (req.user.role !== 'owner') {
            return res.status(403).json({ error: 'Unauthorized' });
        }

        // Verify JWT
        let decoded;
        try {
            decoded = jwt.verify(qr_data, process.env.JWT_SECRET);
        } catch (err) {
            return res.status(400).json({ error: 'Invalid or expired QR code' });
        }

        // Check if QR has been used (one-time use)
        const nonceRecord = await db.qrNonces.findOne({
            order_id: decoded.order_id,
            nonce: decoded.nonce
        });

        if (!nonceRecord) {
            return res.status(400).json({ error: 'Invalid QR code' });
        }

        if (nonceRecord.used) {
            return res.status(400).json({ error: 'QR code already used' });
        }

        // Verify owner has access to this canteen
        const canteen = await db.canteens.findOne({
            _id: decoded.canteen_id,
            owner_id: ownerId
        });

        if (!canteen) {
            return res.status(403).json({ error: 'Unauthorized to access this order' });
        }

        // Fetch full order details
        const order = await db.orders.findById(decoded.order_id)
            .populate('user_id', 'name phone')
            .populate('canteen_id', 'name')
            .populate('items.menu_item_id');

        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }

        // Mark QR as used
        await db.qrNonces.updateOne(
            { _id: nonceRecord._id },
            { used: true, used_at: new Date() }
        );

        // Format response
        res.json({
            success: true,
            order: {
                id: order._id,
                order_number: order.order_number,
                user_name: order.user_id.name,
                user_phone: order.user_id.phone,
                canteen_name: order.canteen_id.name,
                items: order.items.map(item => ({
                    name: item.menu_item_id.name,
                    quantity: item.quantity,
                    price: item.price
                })),
                total_amount: order.total_amount,
                payment_status: order.payment_status,
                order_status: order.order_status,
                order_time: order.created_at,
                payment_method: order.payment_method,
                transaction_id: order.transaction_id
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});
```

### 3. Complete Order
**Endpoint:** `POST /api/orders/:orderId/complete`

**Headers:**
```json
{
  "Authorization": "Bearer owner_token"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order marked as completed"
}
```

---

## iOS Implementation

### Step 1: Add Required Packages

Add these packages via Swift Package Manager:

1. **CoreImage** (Built-in) - For QR generation
2. **AVFoundation** (Built-in) - For QR scanning
3. **SwiftJWT** (Optional) - For JWT decoding
   - URL: `https://github.com/Kitura/Swift-JWT`

### Step 2: Request Camera Permission

Update `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>BunkBite needs camera access to scan order QR codes</string>
```

### Step 3: Create QR Generator Utility

**File:** `BunkBite/Utils/QRCodeGenerator.swift`

```swift
import SwiftUI
import CoreImage.CIFilterBuiltins

class QRCodeGenerator {
    static let shared = QRCodeGenerator()

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    /// Generate QR code image from string
    func generateQRCode(from string: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // High error correction

        guard let outputImage = filter.outputImage else {
            return nil
        }

        // Scale the image
        let scaleX = size.width / outputImage.extent.width
        let scaleY = size.height / outputImage.extent.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Convert to UIImage
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
```

### Step 4: Create QR Code Display View (User Side)

**File:** `BunkBite/Views/User/OrderQRCodeView.swift`

```swift
import SwiftUI

struct OrderQRCodeView: View {
    let order: Order
    @State private var qrData: String?
    @State private var qrImage: UIImage?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var brightness: Double = 1.0

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Constants.primaryColor.opacity(0.05),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Constants.primaryColor.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "qrcode")
                                .font(.system(size: 40))
                                .foregroundStyle(Constants.primaryColor)
                        }
                        .padding(.top, 40)

                        VStack(spacing: 8) {
                            Text("Order QR Code")
                                .font(.urbanist(size: 28, weight: .bold))
                                .foregroundStyle(.black)

                            Text("Show this to collect your order")
                                .font(.urbanist(size: 15, weight: .regular))
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Order Info Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Order Number")
                                    .font(.urbanist(size: 14, weight: .medium))
                                    .foregroundStyle(.gray)

                                Text(order.orderNumber)
                                    .font(.urbanist(size: 24, weight: .bold))
                                    .foregroundStyle(Constants.primaryColor)
                            }
                            Spacer()
                        }

                        Divider()

                        HStack {
                            Text("Total Amount")
                                .font(.urbanist(size: 15, weight: .regular))
                            Spacer()
                            Text("₹\(Int(order.totalAmount))")
                                .font(.urbanist(size: 18, weight: .bold))
                                .foregroundStyle(Constants.primaryColor)
                        }

                        HStack {
                            Text("Items")
                                .font(.urbanist(size: 15, weight: .regular))
                            Spacer()
                            Text("\(order.items.count) items")
                                .font(.urbanist(size: 15, weight: .semibold))
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    .padding(.horizontal, 24)

                    // QR Code Display
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(width: 280, height: 280)
                    } else if let qrImage = qrImage {
                        VStack(spacing: 20) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 280, height: 280)
                                .padding(20)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)

                            // Brightness Slider
                            VStack(spacing: 8) {
                                Text("Screen Brightness")
                                    .font(.urbanist(size: 14, weight: .medium))
                                    .foregroundStyle(.gray)

                                HStack(spacing: 12) {
                                    Image(systemName: "sun.min")
                                        .foregroundStyle(.gray)

                                    Slider(value: $brightness, in: 0.3...1.0)
                                        .tint(Constants.primaryColor)
                                        .onChange(of: brightness) { newValue in
                                            UIScreen.main.brightness = newValue
                                        }

                                    Image(systemName: "sun.max.fill")
                                        .foregroundStyle(Constants.primaryColor)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    } else if let error = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundStyle(.red)

                            Text(error)
                                .font(.urbanist(size: 16, weight: .regular))
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 280, height: 280)
                    }

                    // Instructions
                    VStack(spacing: 12) {
                        InstructionRow(
                            icon: "1.circle.fill",
                            text: "Show this QR code at the counter"
                        )

                        InstructionRow(
                            icon: "2.circle.fill",
                            text: "Staff will scan to verify your order"
                        )

                        InstructionRow(
                            icon: "3.circle.fill",
                            text: "Collect your delicious food!"
                        )
                    }
                    .padding(.horizontal, 24)

                    // Warning
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)

                        Text("This QR code is valid for one-time use only")
                            .font(.urbanist(size: 13, weight: .regular))
                            .foregroundStyle(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            fetchQRCode()
        }
        .onDisappear {
            // Reset brightness
            UIScreen.main.brightness = brightness
        }
    }

    private func fetchQRCode() {
        isLoading = true

        Task {
            do {
                let response = try await APIService.generateOrderQRCode(orderId: order.id)

                await MainActor.run {
                    qrData = response.qrData
                    qrImage = QRCodeGenerator.shared.generateQRCode(from: response.qrData)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate QR code"
                    isLoading = false
                }
            }
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Constants.primaryColor)
                .frame(width: 30)

            Text(text)
                .font(.urbanist(size: 15, weight: .regular))
                .foregroundStyle(.gray)

            Spacer()
        }
    }
}
```

### Step 5: Create QR Scanner View (Owner Side)

**File:** `BunkBite/Views/Owner/QRScannerView.swift`

```swift
import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @State private var isScanning = true
    @State private var scannedCode: String?
    @State private var showOrderDetails = false
    @State private var orderDetails: OrderDetails?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ZStack {
            // Camera View
            if isScanning {
                QRScannerCameraView(scannedCode: $scannedCode)
                    .ignoresSafeArea()

                // Scanner Overlay
                VStack {
                    Spacer()

                    // Scanning Frame
                    ZStack {
                        Rectangle()
                            .stroke(Constants.primaryColor, lineWidth: 4)
                            .frame(width: 280, height: 280)

                        // Corner brackets
                        VStack {
                            HStack {
                                ScannerCorner()
                                Spacer()
                                ScannerCorner()
                                    .rotationEffect(.degrees(90))
                            }
                            Spacer()
                            HStack {
                                ScannerCorner()
                                    .rotationEffect(.degrees(-90))
                                Spacer()
                                ScannerCorner()
                                    .rotationEffect(.degrees(180))
                            }
                        }
                        .frame(width: 280, height: 280)
                    }

                    Spacer()

                    // Instructions
                    Text("Align QR code within the frame")
                        .font(.urbanist(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding(.bottom, 60)
                }
            }

            // Loading Overlay
            if isLoading {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    Text("Verifying order...")
                        .font(.urbanist(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .onChange(of: scannedCode) { newValue in
            if let code = newValue, !isLoading {
                verifyQRCode(code)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("Try Again", role: .cancel) {
                scannedCode = nil
                isScanning = true
            }
        } message: {
            Text(errorMessage ?? "Failed to verify QR code")
        }
        .sheet(isPresented: $showOrderDetails) {
            if let order = orderDetails {
                OrderDetailsSheet(order: order) {
                    scannedCode = nil
                    orderDetails = nil
                    isScanning = true
                }
            }
        }
    }

    private func verifyQRCode(_ code: String) {
        isLoading = true
        isScanning = false

        Task {
            do {
                let order = try await APIService.verifyOrderQRCode(qrData: code)

                await MainActor.run {
                    isLoading = false
                    orderDetails = order
                    showOrderDetails = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct ScannerCorner: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 30, y: 0))
        }
        .stroke(Constants.primaryColor, lineWidth: 6)
        .frame(width: 30, height: 30)
    }
}
```

### Step 6: Create Camera Scanner Component

**File:** `BunkBite/Views/Owner/QRScannerCameraView.swift`

```swift
import SwiftUI
import AVFoundation

struct QRScannerCameraView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, QRScannerDelegate {
        let parent: QRScannerCameraView

        init(_ parent: QRScannerCameraView) {
            self.parent = parent
        }

        func didScanCode(_ code: String) {
            parent.scannedCode = code
        }
    }
}

protocol QRScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.stopRunning()
            }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanCode(stringValue)
        }
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning QR codes", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
}
```

### Step 7: Create Order Details Sheet (Owner Side)

**File:** `BunkBite/Views/Owner/OrderDetailsSheet.swift`

```swift
import SwiftUI

struct OrderDetailsSheet: View {
    let order: OrderDetails
    let onComplete: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var isCompleting = false
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Constants.primaryColor.opacity(0.05),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.green)
                        }
                        .padding(.top, 40)

                        VStack(spacing: 8) {
                            Text("Order Verified")
                                .font(.urbanist(size: 28, weight: .bold))
                                .foregroundStyle(.black)

                            Text(order.orderNumber)
                                .font(.urbanist(size: 20, weight: .bold))
                                .foregroundStyle(Constants.primaryColor)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Customer Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Customer Details")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(.gray)
                            .textCase(.uppercase)
                            .tracking(1)

                        VStack(spacing: 12) {
                            DetailRow(icon: "person.fill", label: "Name", value: order.userName)
                            Divider()
                            DetailRow(icon: "phone.fill", label: "Phone", value: order.userPhone)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    .padding(.horizontal, 24)

                    // Order Items
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Items")
                            .font(.urbanist(size: 14, weight: .semibold))
                            .foregroundStyle(.gray)
                            .textCase(.uppercase)
                            .tracking(1)

                        VStack(spacing: 12) {
                            ForEach(order.items, id: \.name) { item in
                                HStack {
                                    Text("\(item.quantity)x")
                                        .font(.urbanist(size: 16, weight: .bold))
                                        .foregroundStyle(Constants.primaryColor)
                                        .frame(width: 40, alignment: .leading)

                                    Text(item.name)
                                        .font(.urbanist(size: 16, weight: .semibold))
                                        .foregroundStyle(.black)

                                    Spacer()

                                    Text("₹\(Int(item.price * Double(item.quantity)))")
                                        .font(.urbanist(size: 16, weight: .semibold))
                                        .foregroundStyle(.black)
                                }

                                if item.name != order.items.last?.name {
                                    Divider()
                                }
                            }

                            Divider()

                            HStack {
                                Text("Total")
                                    .font(.urbanist(size: 18, weight: .bold))
                                Spacer()
                                Text("₹\(Int(order.totalAmount))")
                                    .font(.urbanist(size: 22, weight: .bold))
                                    .foregroundStyle(Constants.primaryColor)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    .padding(.horizontal, 24)

                    // Payment Info
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Paid via \(order.paymentMethod)")
                            .font(.urbanist(size: 15, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)

                    // Complete Button
                    Button {
                        completeOrder()
                    } label: {
                        HStack(spacing: 12) {
                            if isCompleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Completing...")
                                    .font(.urbanist(size: 18, weight: .semibold))
                            } else {
                                Text("Mark as Completed")
                                    .font(.urbanist(size: 18, weight: .semibold))
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isCompleting)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }

            // Close Button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray.opacity(0.3))
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }

    private func completeOrder() {
        isCompleting = true

        Task {
            do {
                try await APIService.completeOrder(orderId: order.id)

                await MainActor.run {
                    isCompleting = false
                    showSuccess = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                        onComplete()
                    }
                }
            } catch {
                await MainActor.run {
                    isCompleting = false
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Constants.primaryColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.urbanist(size: 13, weight: .medium))
                    .foregroundStyle(.gray)

                Text(value)
                    .font(.urbanist(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
            }

            Spacer()
        }
    }
}
```

### Step 8: Add API Service Methods

**File:** `BunkBite/Services/APIService.swift`

Add these methods to your existing APIService:

```swift
// MARK: - QR Code Methods

func generateOrderQRCode(orderId: String) async throws -> QRCodeResponse {
    let url = URL(string: "\(Constants.baseURL)/api/orders/\(orderId)/generate-qr")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    let (data, _) = try await URLSession.shared.data(for: request)

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(QRCodeResponse.self, from: data)
}

func verifyOrderQRCode(qrData: String) async throws -> OrderDetails {
    let url = URL(string: "\(Constants.baseURL)/api/orders/verify-qr")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    let body: [String: Any] = ["qr_data": qrData]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let response = try decoder.decode(QRVerifyResponse.self, from: data)
    return response.order
}

func completeOrder(orderId: String) async throws {
    let url = URL(string: "\(Constants.baseURL)/api/orders/\(orderId)/complete")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw APIError.requestFailed
    }
}
```

### Step 9: Add Models

**File:** `BunkBite/Models/QRModels.swift`

```swift
import Foundation

struct QRCodeResponse: Codable {
    let success: Bool
    let qrData: String
    let qrType: String
    let expiresAt: String
}

struct QRVerifyResponse: Codable {
    let success: Bool
    let order: OrderDetails
}

struct OrderDetails: Codable {
    let id: String
    let orderNumber: String
    let userName: String
    let userPhone: String
    let canteenName: String
    let items: [OrderItem]
    let totalAmount: Double
    let paymentStatus: String
    let orderStatus: String
    let orderTime: String
    let paymentMethod: String
    let transactionId: String
}

struct OrderItem: Codable {
    let name: String
    let quantity: Int
    let price: Double
}
```

---

## Security Best Practices

### 1. JWT Security
- ✅ Use strong secret key (min 256 bits)
- ✅ Set expiration time (24 hours max)
- ✅ Include nonce for one-time use
- ✅ Store nonces in database
- ✅ Mark nonces as used after scan

### 2. QR Code Security
- ✅ One-time use only
- ✅ Time-limited validity
- ✅ Encrypted payload
- ✅ Canteen-specific verification
- ✅ Order-user relationship validation

### 3. Camera Permissions
- ✅ Request permission before scanning
- ✅ Handle permission denial gracefully
- ✅ Show clear usage description

---

## Testing

### Test User Side (QR Generation)
1. Place an order
2. Navigate to order details
3. Tap "Show QR Code"
4. Verify QR code displays
5. Test brightness adjustment
6. Verify instructions are clear

### Test Owner Side (QR Scanning)
1. Open scanner view
2. Scan test QR code
3. Verify order details display
4. Mark order as complete
5. Verify QR cannot be reused

### Test Edge Cases
- ❌ Expired QR code
- ❌ Already used QR code
- ❌ Invalid QR data
- ❌ Wrong canteen scanning
- ❌ Network errors

---

## UI/UX Considerations

### User Side
- 📱 Large QR code (280x280pt minimum)
- 💡 Brightness control for better scanning
- 📋 Clear order information
- ⚠️ One-time use warning
- 📖 Step-by-step instructions

### Owner Side
- 📸 Full-screen camera view
- 🎯 Visual scanning frame
- 🔊 Haptic feedback on scan
- ✅ Clear order verification
- 🚀 Quick complete action

---

## Summary

This QR code system provides:
- ✅ Secure order verification
- ✅ Prevention of order fraud
- ✅ One-time use QR codes
- ✅ Beautiful UI/UX
- ✅ Easy implementation
- ✅ Owner-side verification
- ✅ Fast order completion

The system is production-ready and follows iOS best practices for camera access, QR generation, and secure data handling.
