# Complete Payment Flow: Backend + Frontend Integration Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Backend Implementation](#backend-implementation)
3. [Frontend (iOS) Implementation](#frontend-ios-implementation)
4. [Security Best Practices](#security-best-practices)
5. [Testing Guide](#testing-guide)
6. [Production Checklist](#production-checklist)

---

## Architecture Overview

### High-Level Flow Diagram

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│             │         │             │         │             │
│  iOS App    │────────▶│   Backend   │────────▶│  Cashfree   │
│             │         │   Server    │         │   Gateway   │
│             │         │             │         │             │
└─────────────┘         └─────────────┘         └─────────────┘
       │                       │                        │
       │                       │                        │
       └───────────────────────┴────────────────────────┘
                    (Payment Status Updates)
```

### Complete Payment Flow

```
1. User adds items to cart
2. User clicks "Proceed to Checkout"
3. iOS app validates cart
4. iOS app calls backend: POST /api/v1/payments/create-order
5. Backend validates user session
6. Backend calculates order amount (server-side validation)
7. Backend creates order in Cashfree
8. Backend stores order in database
9. Backend returns payment_session_id to iOS
10. iOS opens WKWebView with Cashfree checkout
11. User completes payment in Cashfree
12. Cashfree calls backend webhook
13. Backend verifies payment status
14. Backend updates order status in database
15. iOS detects return URL and closes WebView
16. iOS calls backend to verify payment
17. iOS shows success/failure UI
```

---

## Backend Implementation

### Tech Stack
- Node.js / Python / Go (choose your backend language)
- Database: PostgreSQL / MongoDB
- Cashfree SDK for backend

### 1. Environment Setup

#### Environment Variables (.env)
```bash
# Server Configuration
NODE_ENV=development
PORT=3000
BASE_URL=https://api.bunkbite.me

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/bunkbite

# Cashfree Configuration
CASHFREE_APP_ID_TEST=CF10714837D4FUFG2HGG9C73CS3J4G
CASHFREE_SECRET_KEY_TEST=cfsk_ma_test_9d2e4af14158a82c9c01241724470538_794498d5
CASHFREE_APP_ID_PROD=<your-production-app-id>
CASHFREE_SECRET_KEY_PROD=<your-production-secret-key>
CASHFREE_ENVIRONMENT=sandbox # or production

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRY=7d

# Webhook Secret (for verifying Cashfree webhooks)
CASHFREE_WEBHOOK_SECRET=your-webhook-secret-here
```

### 2. Database Schema

#### Orders Table
```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id VARCHAR(100) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id),
    canteen_id UUID NOT NULL REFERENCES canteens(id),

    -- Order Details
    items JSONB NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    tax DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,

    -- Payment Details
    payment_session_id VARCHAR(255),
    payment_id VARCHAR(255),
    payment_method VARCHAR(50),

    -- Status
    order_status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, PAID, FAILED, CANCELLED
    payment_status VARCHAR(20) DEFAULT 'INITIATED', -- INITIATED, SUCCESS, FAILED

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    paid_at TIMESTAMP,

    -- Metadata
    metadata JSONB,

    INDEX idx_order_id (order_id),
    INDEX idx_user_id (user_id),
    INDEX idx_payment_session_id (payment_session_id)
);
```

#### Payment Transactions Table (for audit trail)
```sql
CREATE TABLE payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id VARCHAR(100) NOT NULL REFERENCES orders(order_id),

    -- Transaction Details
    transaction_id VARCHAR(255),
    payment_gateway VARCHAR(50) DEFAULT 'cashfree',
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'INR',

    -- Status
    status VARCHAR(20) NOT NULL, -- INITIATED, SUCCESS, FAILED, PENDING

    -- Gateway Response
    gateway_response JSONB,
    error_message TEXT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    INDEX idx_order_id (order_id),
    INDEX idx_transaction_id (transaction_id)
);
```

### 3. Backend API Endpoints

#### A. Create Payment Order

**Endpoint:** `POST /api/v1/payments/create-order`

**Request Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
    "canteen_id": "uuid-of-canteen",
    "items": [
        {
            "menu_item_id": "uuid-of-menu-item",
            "name": "Burger",
            "price": 50.00,
            "quantity": 2
        },
        {
            "menu_item_id": "uuid-of-menu-item-2",
            "name": "Coffee",
            "price": 30.00,
            "quantity": 1
        }
    ]
}
```

**Backend Logic (Node.js Example):**

```javascript
// controllers/paymentController.js
const { Cashfree } = require('cashfree-pg');
const Order = require('../models/Order');
const User = require('../models/User');

// Initialize Cashfree
const cashfree = new Cashfree({
    env: process.env.CASHFREE_ENVIRONMENT, // 'sandbox' or 'production'
    appId: process.env.CASHFREE_ENVIRONMENT === 'production'
        ? process.env.CASHFREE_APP_ID_PROD
        : process.env.CASHFREE_APP_ID_TEST,
    secretKey: process.env.CASHFREE_ENVIRONMENT === 'production'
        ? process.env.CASHFREE_SECRET_KEY_PROD
        : process.env.CASHFREE_SECRET_KEY_TEST
});

exports.createPaymentOrder = async (req, res) => {
    try {
        // 1. Authenticate user from JWT token
        const userId = req.user.id; // Extracted from JWT middleware
        const user = await User.findById(userId);

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'User not authenticated'
            });
        }

        // 2. Extract and validate request data
        const { canteen_id, items } = req.body;

        if (!canteen_id || !items || items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Invalid request: canteen_id and items are required'
            });
        }

        // 3. SERVER-SIDE VALIDATION: Recalculate order amount
        // NEVER trust amounts from client side!
        const validatedItems = await validateAndCalculateOrder(items);

        const subtotal = validatedItems.reduce((sum, item) => {
            return sum + (item.validated_price * item.quantity);
        }, 0);

        const tax = 0; // Add tax calculation if needed
        const totalAmount = subtotal + tax;

        // 4. Generate unique order ID
        const orderId = `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        // 5. Create order in Cashfree
        const cashfreeOrderRequest = {
            order_amount: totalAmount,
            order_currency: 'INR',
            order_id: orderId,
            customer_details: {
                customer_id: user.id,
                customer_name: user.name || 'BunkBite User',
                customer_email: user.email,
                customer_phone: user.phone || '9999999999'
            },
            order_meta: {
                return_url: `bunkbite://payment-return?order_id=${orderId}`,
                notify_url: `${process.env.BASE_URL}/api/v1/payments/webhook`
            },
            order_note: `Order for ${items.length} items from canteen ${canteen_id}`
        };

        console.log('Creating Cashfree order:', orderId);

        const cashfreeResponse = await cashfree.PGCreateOrder('2023-08-01', cashfreeOrderRequest);

        if (!cashfreeResponse || !cashfreeResponse.payment_session_id) {
            throw new Error('Failed to create payment session with Cashfree');
        }

        // 6. Store order in database
        const order = await Order.create({
            order_id: orderId,
            user_id: userId,
            canteen_id: canteen_id,
            items: validatedItems,
            subtotal: subtotal,
            tax: tax,
            total_amount: totalAmount,
            payment_session_id: cashfreeResponse.payment_session_id,
            order_status: 'PENDING',
            payment_status: 'INITIATED',
            metadata: {
                cf_order_id: cashfreeResponse.cf_order_id,
                order_expiry_time: cashfreeResponse.order_expiry_time
            }
        });

        // 7. Create initial payment transaction record
        await PaymentTransaction.create({
            order_id: orderId,
            amount: totalAmount,
            currency: 'INR',
            status: 'INITIATED',
            payment_gateway: 'cashfree'
        });

        // 8. Return response to iOS app
        return res.status(200).json({
            success: true,
            message: 'Payment session created successfully',
            data: {
                order_id: orderId,
                payment_session_id: cashfreeResponse.payment_session_id,
                amount: totalAmount,
                currency: 'INR',
                customer: {
                    name: user.name,
                    email: user.email,
                    phone: user.phone
                }
            }
        });

    } catch (error) {
        console.error('Error creating payment order:', error);

        return res.status(500).json({
            success: false,
            message: 'Failed to create payment order',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// Helper function to validate items and recalculate prices
async function validateAndCalculateOrder(items) {
    const MenuItem = require('../models/MenuItem');
    const validatedItems = [];

    for (const item of items) {
        // Fetch actual price from database
        const menuItem = await MenuItem.findById(item.menu_item_id);

        if (!menuItem) {
            throw new Error(`Invalid menu item: ${item.menu_item_id}`);
        }

        if (!menuItem.is_available) {
            throw new Error(`Item not available: ${menuItem.name}`);
        }

        // Use server-side price, NOT client-provided price
        validatedItems.push({
            menu_item_id: item.menu_item_id,
            name: menuItem.name,
            client_price: item.price, // For logging/comparison
            validated_price: menuItem.price, // ACTUAL price from DB
            quantity: item.quantity,
            total: menuItem.price * item.quantity
        });
    }

    return validatedItems;
}
```

**Response (Success):**
```json
{
    "success": true,
    "message": "Payment session created successfully",
    "data": {
        "order_id": "order_1637123456_abc123",
        "payment_session_id": "session_Y4ZwWUwVRsyoq9C5Aph0B...",
        "amount": 130.00,
        "currency": "INR",
        "customer": {
            "name": "John Doe",
            "email": "john@example.com",
            "phone": "9876543210"
        }
    }
}
```

**Response (Error):**
```json
{
    "success": false,
    "message": "Failed to create payment order",
    "error": "Item not available: Burger"
}
```

---

#### B. Verify Payment Status

**Endpoint:** `GET /api/v1/payments/verify/:orderId`

**Request Headers:**
```
Authorization: Bearer <jwt-token>
```

**Backend Logic:**

```javascript
exports.verifyPaymentStatus = async (req, res) => {
    try {
        const { orderId } = req.params;
        const userId = req.user.id;

        // 1. Fetch order from database
        const order = await Order.findOne({
            order_id: orderId,
            user_id: userId
        });

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        // 2. Fetch latest status from Cashfree
        const cashfreeOrder = await cashfree.PGFetchOrder('2023-08-01', orderId);

        // 3. Update order status in database
        const paymentStatus = cashfreeOrder.order_status; // 'PAID', 'ACTIVE', 'EXPIRED'

        if (paymentStatus === 'PAID') {
            await Order.update(
                { order_id: orderId },
                {
                    order_status: 'PAID',
                    payment_status: 'SUCCESS',
                    payment_id: cashfreeOrder.cf_order_id,
                    payment_method: cashfreeOrder.payment_method || 'unknown',
                    paid_at: new Date(),
                    updated_at: new Date()
                }
            );

            // Update transaction record
            await PaymentTransaction.update(
                { order_id: orderId },
                {
                    status: 'SUCCESS',
                    transaction_id: cashfreeOrder.cf_order_id,
                    gateway_response: cashfreeOrder,
                    updated_at: new Date()
                }
            );
        } else {
            await Order.update(
                { order_id: orderId },
                {
                    payment_status: 'FAILED',
                    updated_at: new Date()
                }
            );
        }

        // 4. Return status to iOS app
        return res.status(200).json({
            success: true,
            data: {
                order_id: orderId,
                order_status: paymentStatus,
                payment_status: paymentStatus === 'PAID' ? 'SUCCESS' : 'FAILED',
                amount: order.total_amount,
                paid_at: order.paid_at,
                payment_method: cashfreeOrder.payment_method
            }
        });

    } catch (error) {
        console.error('Error verifying payment:', error);

        return res.status(500).json({
            success: false,
            message: 'Failed to verify payment status'
        });
    }
};
```

**Response:**
```json
{
    "success": true,
    "data": {
        "order_id": "order_1637123456_abc123",
        "order_status": "PAID",
        "payment_status": "SUCCESS",
        "amount": 130.00,
        "paid_at": "2025-11-21T10:30:45.123Z",
        "payment_method": "UPI"
    }
}
```

---

#### C. Webhook Handler (Cashfree → Backend)

**Endpoint:** `POST /api/v1/payments/webhook`

**Important:** This endpoint is called by Cashfree, NOT by your iOS app.

**Backend Logic:**

```javascript
const crypto = require('crypto');

exports.handleWebhook = async (req, res) => {
    try {
        // 1. Verify webhook signature (CRITICAL for security)
        const signature = req.headers['x-webhook-signature'];
        const timestamp = req.headers['x-webhook-timestamp'];

        const isValid = verifyWebhookSignature(
            req.body,
            signature,
            timestamp,
            process.env.CASHFREE_WEBHOOK_SECRET
        );

        if (!isValid) {
            console.error('Invalid webhook signature');
            return res.status(401).json({ message: 'Invalid signature' });
        }

        // 2. Extract payment data
        const {
            type,
            data: {
                order
            }
        } = req.body;

        console.log('Webhook received:', type, order.order_id);

        // 3. Handle different webhook events
        switch (type) {
            case 'PAYMENT_SUCCESS_WEBHOOK':
                await handlePaymentSuccess(order);
                break;

            case 'PAYMENT_FAILED_WEBHOOK':
                await handlePaymentFailure(order);
                break;

            case 'PAYMENT_USER_DROPPED_WEBHOOK':
                await handlePaymentDropped(order);
                break;

            default:
                console.log('Unknown webhook type:', type);
        }

        // 4. Always return 200 OK to Cashfree
        return res.status(200).json({ message: 'Webhook processed' });

    } catch (error) {
        console.error('Webhook processing error:', error);
        return res.status(500).json({ message: 'Webhook processing failed' });
    }
};

// Verify webhook signature
function verifyWebhookSignature(payload, signature, timestamp, secret) {
    const signatureString = `${timestamp}${JSON.stringify(payload)}`;
    const computedSignature = crypto
        .createHmac('sha256', secret)
        .update(signatureString)
        .digest('base64');

    return computedSignature === signature;
}

// Handle successful payment
async function handlePaymentSuccess(order) {
    try {
        await Order.update(
            { order_id: order.order_id },
            {
                order_status: 'PAID',
                payment_status: 'SUCCESS',
                payment_id: order.cf_order_id,
                payment_method: order.payment_method,
                paid_at: new Date(),
                updated_at: new Date()
            }
        );

        await PaymentTransaction.update(
            { order_id: order.order_id },
            {
                status: 'SUCCESS',
                transaction_id: order.cf_order_id,
                gateway_response: order,
                updated_at: new Date()
            }
        );

        // Send notification to user (optional)
        // await sendPushNotification(order.user_id, 'Payment successful!');

        console.log(`Payment successful for order: ${order.order_id}`);
    } catch (error) {
        console.error('Error handling payment success:', error);
    }
}

// Handle failed payment
async function handlePaymentFailure(order) {
    try {
        await Order.update(
            { order_id: order.order_id },
            {
                payment_status: 'FAILED',
                updated_at: new Date()
            }
        );

        await PaymentTransaction.update(
            { order_id: order.order_id },
            {
                status: 'FAILED',
                error_message: order.payment_failure_reason,
                gateway_response: order,
                updated_at: new Date()
            }
        );

        console.log(`Payment failed for order: ${order.order_id}`);
    } catch (error) {
        console.error('Error handling payment failure:', error);
    }
}

// Handle dropped payment (user closed payment page)
async function handlePaymentDropped(order) {
    try {
        await Order.update(
            { order_id: order.order_id },
            {
                payment_status: 'CANCELLED',
                updated_at: new Date()
            }
        );

        console.log(`Payment dropped for order: ${order.order_id}`);
    } catch (error) {
        console.error('Error handling payment dropped:', error);
    }
}
```

---

### 4. Authentication Middleware

```javascript
// middleware/auth.js
const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.authenticate = async (req, res, next) => {
    try {
        // 1. Extract token from header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'No authentication token provided'
            });
        }

        const token = authHeader.substring(7); // Remove 'Bearer ' prefix

        // 2. Verify JWT token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // 3. Check if user exists
        const user = await User.findById(decoded.userId);

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'User not found'
            });
        }

        // 4. Attach user to request object
        req.user = {
            id: user.id,
            email: user.email,
            name: user.name,
            phone: user.phone
        };

        next();

    } catch (error) {
        console.error('Authentication error:', error);

        return res.status(401).json({
            success: false,
            message: 'Invalid or expired token'
        });
    }
};
```

---

### 5. Backend Routes Setup

```javascript
// routes/paymentRoutes.js
const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticate } = require('../middleware/auth');

// Protected routes (require authentication)
router.post('/create-order', authenticate, paymentController.createPaymentOrder);
router.get('/verify/:orderId', authenticate, paymentController.verifyPaymentStatus);
router.get('/order/:orderId', authenticate, paymentController.getOrderDetails);

// Public route (for Cashfree webhook)
router.post('/webhook', paymentController.handleWebhook);

module.exports = router;
```

```javascript
// app.js
const express = require('express');
const paymentRoutes = require('./routes/paymentRoutes');

const app = express();

app.use(express.json());

// Mount payment routes
app.use('/api/v1/payments', paymentRoutes);

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
```

---

## Frontend (iOS) Implementation

### 1. Update APIService.swift

```swift
// BunkBite/Services/APIService.swift

import Foundation

class PaymentAPIService {
    static let shared = PaymentAPIService()

    private let baseURL = Constants.baseURL

    // MARK: - Create Payment Order

    func createPaymentOrder(canteenId: String, items: [CartItem]) async throws -> PaymentOrderResponse {
        let url = URL(string: "\(baseURL)/api/v1/payments/create-order")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add JWT authentication token
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Prepare request body
        let requestBody: [String: Any] = [
            "canteen_id": canteenId,
            "items": items.map { item in
                return [
                    "menu_item_id": item.menuItem.id,
                    "name": item.menuItem.name,
                    "price": item.menuItem.price,
                    "quantity": item.quantity
                ]
            }
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("🔵 Creating payment order...")
        print("📦 Canteen ID: \(canteenId)")
        print("📦 Items count: \(items.count)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentError.invalidResponse
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Error: \(errorMsg)")
            throw PaymentError.serverError(errorMsg)
        }

        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiResponse = try decoder.decode(PaymentOrderAPIResponse.self, from: data)

        if !apiResponse.success {
            throw PaymentError.serverError(apiResponse.message ?? "Unknown error")
        }

        guard let paymentData = apiResponse.data else {
            throw PaymentError.missingData
        }

        print("✅ Payment session created: \(paymentData.paymentSessionId)")

        return paymentData
    }

    // MARK: - Verify Payment Status

    func verifyPaymentStatus(orderId: String) async throws -> PaymentVerificationResponse {
        let url = URL(string: "\(baseURL)/api/v1/payments/verify/\(orderId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add JWT authentication token
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        print("🔍 Verifying payment status for order: \(orderId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PaymentError.serverError(errorMsg)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiResponse = try decoder.decode(PaymentVerificationAPIResponse.self, from: data)

        guard let verificationData = apiResponse.data else {
            throw PaymentError.missingData
        }

        print("✅ Payment status: \(verificationData.paymentStatus)")

        return verificationData
    }
}

// MARK: - Models

struct PaymentOrderAPIResponse: Codable {
    let success: Bool
    let message: String?
    let data: PaymentOrderResponse?
}

struct PaymentOrderResponse: Codable {
    let orderId: String
    let paymentSessionId: String
    let amount: Double
    let currency: String
    let customer: CustomerInfo?
}

struct CustomerInfo: Codable {
    let name: String?
    let email: String?
    let phone: String?
}

struct PaymentVerificationAPIResponse: Codable {
    let success: Bool
    let data: PaymentVerificationResponse?
}

struct PaymentVerificationResponse: Codable {
    let orderId: String
    let orderStatus: String
    let paymentStatus: String
    let amount: Double
    let paidAt: String?
    let paymentMethod: String?
}

enum PaymentError: Error, LocalizedError {
    case invalidResponse
    case serverError(String)
    case missingData
    case authenticationRequired

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        case .missingData:
            return "Missing data in response"
        case .authenticationRequired:
            return "Please login to continue"
        }
    }
}
```

### 2. Update PaymentSheet.swift

Replace the direct Cashfree API call with backend API call:

```swift
// BunkBite/Views/User/PaymentSheet.swift

private func initiatePayment() {
    print("\n" + String(repeating: "=", count: 60))
    print("🔵 PAYMENT BUTTON CLICKED - initiatePayment() called")
    print(String(repeating: "=", count: 60))

    guard let canteen = canteen else {
        print("❌ ERROR: No canteen information available")
        handlePaymentFailure(error: "Canteen information not available")
        return
    }

    isProcessingPayment = true
    print("✅ isProcessingPayment set to true")

    let amountInRupees = cart.totalAmount

    print("\n🚀 INITIATING PAYMENT")
    print("Amount: ₹\(amountInRupees)")
    print("Canteen: \(canteen.name)")
    print("Items: \(cart.items.count)\n")

    // Call backend to create payment order
    Task {
        do {
            // Call backend API
            let paymentOrder = try await PaymentAPIService.shared.createPaymentOrder(
                canteenId: canteen.id,
                items: cart.items
            )

            print("✅ Received payment session from backend:")
            print("   Order ID: \(paymentOrder.orderId)")
            print("   Payment Session ID: \(paymentOrder.paymentSessionId)")
            print("   Amount: ₹\(paymentOrder.amount)")
            print("")

            await MainActor.run {
                currentOrderId = paymentOrder.orderId
                openWebCheckout(
                    paymentSessionId: paymentOrder.paymentSessionId,
                    orderId: paymentOrder.orderId,
                    amount: paymentOrder.amount
                )
            }
        } catch {
            print("❌ Failed to create order: \(error.localizedDescription)")
            await MainActor.run {
                handlePaymentFailure(error: error.localizedDescription)
            }
        }
    }
}

private func openWebCheckout(paymentSessionId: String, orderId: String, amount: Double) {
    print("\n💳 Opening WKWebView for Cashfree Checkout")
    print("Payment Session ID: \(paymentSessionId)")

    // Get the topmost view controller
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let rootViewController = window.rootViewController else {
        handlePaymentFailure(error: "Unable to open payment window")
        return
    }

    var topController = rootViewController
    while let presentedViewController = topController.presentedViewController {
        topController = presentedViewController
    }

    // Open payment using WKWebView
    CashfreeWebCheckoutManager.shared.openPayment(
        paymentSessionId: paymentSessionId,
        orderId: orderId,
        amount: amount,
        from: topController,
        onSuccess: { [self] orderId in
            self.verifyPaymentWithBackend(orderId: orderId)
        },
        onFailure: { [self] error in
            self.handlePaymentFailure(error: error)
        }
    )
}

private func verifyPaymentWithBackend(orderId: String) {
    print("\n🔍 Verifying payment with backend...")

    Task {
        do {
            let verification = try await PaymentAPIService.shared.verifyPaymentStatus(orderId: orderId)

            await MainActor.run {
                if verification.paymentStatus == "SUCCESS" {
                    handlePaymentSuccess(orderId: orderId, verification: verification)
                } else {
                    handlePaymentFailure(error: "Payment verification failed")
                }
            }
        } catch {
            await MainActor.run {
                handlePaymentFailure(error: "Failed to verify payment: \(error.localizedDescription)")
            }
        }
    }
}

private func handlePaymentSuccess(orderId: String, verification: PaymentVerificationResponse) {
    isProcessingPayment = false

    paymentDetails = PaymentDetails(
        transactionId: orderId,
        amount: verification.amount,
        timestamp: Date(),
        status: .success,
        paymentMethod: verification.paymentMethod ?? "Cashfree",
        canteenName: canteen?.name ?? "BunkBite",
        itemCount: cart.items.count
    )

    print("\n✅ Payment Successful")
    print("📋 Order ID: \(orderId)")
    print("💳 Payment Method: \(verification.paymentMethod ?? "N/A")")
    print("💰 Amount: ₹\(verification.amount)\n")

    showSuccessPopup = true
}
```

### 3. Create WKWebView Manager

Create a new file for handling WKWebView-based checkout:

```swift
// BunkBite/Services/CashfreeWebViewManager.swift

import Foundation
import WebKit
import UIKit

class CashfreeWebCheckoutManager: NSObject {
    static let shared = CashfreeWebCheckoutManager()

    private var onSuccess: ((String) -> Void)?
    private var onFailure: ((String) -> Void)?
    private var currentOrderId: String?
    private var webViewController: UIViewController?

    func openPayment(
        paymentSessionId: String,
        orderId: String,
        amount: Double,
        from viewController: UIViewController,
        onSuccess: @escaping (String) -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.currentOrderId = orderId

        print("\n🌐 OPENING CASHFREE WEB CHECKOUT (WKWebView)")
        print("============================================================")
        print("📦 Order ID: \(orderId)")
        print("💰 Amount: ₹\(amount)")
        print("🔑 Session ID: \(paymentSessionId.prefix(50))...")
        print("============================================================\n")

        // Create WKWebView configuration
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self

        // Create HTML form to submit to Cashfree
        let htmlForm = createCashfreeForm(paymentSessionId: paymentSessionId)

        // Create view controller for web view
        let webVC = CashfreeWebViewController(webView: webView, orderId: orderId)
        webVC.modalPresentationStyle = .fullScreen
        self.webViewController = webVC

        // Load the HTML form
        webView.loadHTMLString(htmlForm, baseURL: nil)

        // Present the web view
        viewController.present(webVC, animated: true)
    }

    private func createCashfreeForm(paymentSessionId: String) -> String {
        let environment = Constants.cashfreeEnvironment
        let checkoutURL = environment == .sandbox
            ? "https://sandbox.cashfree.com/pg/view/sessions/checkout"
            : "https://api.cashfree.com/pg/view/sessions/checkout"

        let platform = "iosx-c-x-x-x-w-x-a-1.0.0" // Your app version

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                }
                .loader {
                    text-align: center;
                }
                .spinner {
                    border: 4px solid #f3f3f3;
                    border-top: 4px solid #f62f56;
                    border-radius: 50%;
                    width: 40px;
                    height: 40px;
                    animation: spin 1s linear infinite;
                    margin: 0 auto 20px;
                }
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
            </style>
        </head>
        <body>
            <div class="loader">
                <div class="spinner"></div>
                <p>Loading payment page...</p>
            </div>

            <form id="redirectForm" method="post" action="\(checkoutURL)">
                <input type="hidden" name="payment_session_id" value="\(paymentSessionId)">
                <input type="hidden" name="platform" value="\(platform)">
            </form>

            <script type="text/javascript">
                window.onload = function() {
                    const form = document.getElementById('redirectForm');
                    const meta = {
                        userAgent: window.navigator.userAgent
                    };
                    const sortedMeta = Object.entries(meta).sort().reduce((o, [k, v]) => {
                        o[k] = v;
                        return o;
                    }, {});
                    const base64Meta = btoa(JSON.stringify(sortedMeta));

                    const metaInput = document.createElement('input');
                    metaInput.setAttribute('type', 'hidden');
                    metaInput.setAttribute('name', 'browser_meta');
                    metaInput.setAttribute('value', base64Meta);
                    form.appendChild(metaInput);

                    form.submit();
                };
            </script>
        </body>
        </html>
        """
    }

    func closeWebView() {
        webViewController?.dismiss(animated: true) {
            self.webViewController = nil
        }
    }
}

// MARK: - WKNavigationDelegate

extension CashfreeWebCheckoutManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url {
            let urlString = url.absoluteString

            print("🌐 Navigation to: \(urlString)")

            // Check if this is the return URL
            if urlString.starts(with: "bunkbite://payment-return") {
                print("✅ Payment return URL detected")

                decisionHandler(.cancel)

                // Close web view
                closeWebView()

                // Extract order ID from URL
                if let orderId = currentOrderId {
                    onSuccess?(orderId)
                }

                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView navigation failed: \(error.localizedDescription)")

        closeWebView()
        onFailure?("Payment page failed to load: \(error.localizedDescription)")
    }
}

// MARK: - Web View Controller

class CashfreeWebViewController: UIViewController {
    private let webView: WKWebView
    private let orderId: String

    init(webView: WKWebView, orderId: String) {
        self.webView = webView
        self.orderId = orderId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // Add web view
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        closeButton.tintColor = .systemGray
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        closeButton.layer.cornerRadius = 20
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true) {
            CashfreeWebCheckoutManager.shared.onFailure?("Payment cancelled by user")
        }
    }
}
```

### 4. Update Info.plist for URL Scheme

Add the custom URL scheme for deep linking:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.bunkbite.payment</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>bunkbite</string>
        </array>
    </dict>
</array>

<!-- Add these for UPI apps -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>bhim</string>
    <string>paytmmp</string>
    <string>phonepe</string>
    <string>tez</string>
    <string>credpay</string>
</array>
```

### 5. Handle Deep Links in App

Update your BunkBiteApp.swift:

```swift
// BunkBite/BunkBiteApp.swift

import SwiftUI

@main
struct BunkBiteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
        }
    }

    private func handleDeepLink(url: URL) {
        print("🔗 Deep link received: \(url.absoluteString)")

        if url.scheme == "bunkbite" && url.host == "payment-return" {
            print("✅ Payment return deep link detected")

            // Extract order ID from URL
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let orderId = components.queryItems?.first(where: { $0.name == "order_id" })?.value {
                print("📦 Order ID: \(orderId)")

                // The web view manager will handle the success callback
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("🔗 App delegate received URL: \(url.absoluteString)")
        return true
    }
}
```

---

## Security Best Practices

### 1. Never Store Sensitive Data in iOS App

❌ **DON'T:**
```swift
// NEVER hardcode in production
static let cashfreeSecretKey = "cfsk_ma_prod_xxxxx"
```

✅ **DO:**
```swift
// Keep only non-sensitive config in app
static let apiBaseURL = "https://api.bunkbite.me"
```

### 2. Always Validate on Backend

❌ **DON'T trust client-side calculations:**
```javascript
// Client sends amount - DON'T trust this!
const amount = req.body.amount;
```

✅ **DO recalculate on backend:**
```javascript
// Fetch prices from database and calculate
const items = await validateItems(req.body.items);
const amount = items.reduce((sum, item) => sum + (item.price * item.qty), 0);
```

### 3. Use HTTPS Everywhere

- ✅ Backend API: `https://api.bunkbite.me`
- ✅ Webhook endpoint: `https://api.bunkbite.me/webhooks`
- ❌ Never use HTTP in production

### 4. Verify Webhook Signatures

Always verify that webhooks are actually from Cashfree:

```javascript
function verifyWebhookSignature(payload, signature, timestamp, secret) {
    const signatureString = `${timestamp}${JSON.stringify(payload)}`;
    const computedSignature = crypto
        .createHmac('sha256', secret)
        .update(signatureString)
        .digest('base64');

    return computedSignature === signature;
}
```

### 5. Implement Rate Limiting

Prevent abuse of your payment endpoints:

```javascript
const rateLimit = require('express-rate-limit');

const paymentLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10, // Max 10 requests per 15 minutes per IP
    message: 'Too many payment requests, please try again later'
});

router.post('/create-order', authenticate, paymentLimiter, createPaymentOrder);
```

### 6. Log Everything (Securely)

```javascript
// Log payment attempts (without sensitive data)
console.log({
    event: 'payment_initiated',
    order_id: orderId,
    user_id: userId,
    amount: amount,
    timestamp: new Date().toISOString()
    // DON'T log: credit card numbers, CVV, passwords, API keys
});
```

### 7. Handle PCI Compliance

- ✅ Cashfree handles all payment data (PCI compliant)
- ✅ Never store credit card details
- ✅ Never log sensitive payment information
- ✅ Use Cashfree's tokenization for saved cards

---

## Testing Guide

### 1. Test Environment Setup

**Backend:**
```bash
# Set environment to sandbox
CASHFREE_ENVIRONMENT=sandbox
CASHFREE_APP_ID=CF10714837D4FUFG2HGG9C73CS3J4G
CASHFREE_SECRET_KEY=cfsk_ma_test_9d2e4af14158a82c9c01241724470538_794498d5
```

**iOS App:**
```swift
static let apiBaseURL = "https://api-staging.bunkbite.me" // Use staging
```

### 2. Test Credentials (Cashfree Sandbox)

**Test Cards:**
```
Card Number: 4111 1111 1111 1111
CVV: 123
Expiry: 12/25
OTP: 123456
```

**Test UPI:**
```
Success: testsuccess@gocash
Failure: testfailure@gocash
```

**Test Netbanking:**
```
Bank: Any test bank
Username: test
Password: test
```

### 3. Test Scenarios

#### Scenario 1: Successful Payment
1. Add items to cart
2. Click "Pay Now"
3. Select UPI
4. Enter `testsuccess@gocash`
5. Verify order status becomes "PAID"
6. Check database: order_status = 'PAID'

#### Scenario 2: Failed Payment
1. Add items to cart
2. Click "Pay Now"
3. Select UPI
4. Enter `testfailure@gocash`
5. Verify error message shown
6. Check database: payment_status = 'FAILED'

#### Scenario 3: User Abandons Payment
1. Add items to cart
2. Click "Pay Now"
3. Close payment page
4. Verify order remains in "PENDING" state

#### Scenario 4: Network Error
1. Turn off internet
2. Try to create payment
3. Verify proper error message

#### Scenario 5: Backend Validation
1. Modify item price in iOS app (try to send lower price)
2. Backend should reject or recalculate
3. Use correct server-side price

### 4. Testing Checklist

**Backend Tests:**
- [ ] Create order API returns payment_session_id
- [ ] Server-side amount validation works
- [ ] Webhook signature verification works
- [ ] Order status updates correctly
- [ ] Database records created properly
- [ ] Authentication middleware works
- [ ] Rate limiting works
- [ ] Error handling works

**iOS Tests:**
- [ ] Payment sheet opens correctly
- [ ] WKWebView loads Cashfree page
- [ ] Payment successful flow works
- [ ] Payment failure flow works
- [ ] Payment cancellation works
- [ ] Deep link handling works
- [ ] Network error handling works
- [ ] UI updates correctly after payment

**Integration Tests:**
- [ ] End-to-end successful payment
- [ ] End-to-end failed payment
- [ ] Webhook updates order correctly
- [ ] Multiple concurrent payments
- [ ] Payment retry after failure

---

## Production Checklist

### Backend

- [ ] **Environment Variables**
  - [ ] Production Cashfree credentials configured
  - [ ] JWT secret is strong and unique
  - [ ] Webhook secret configured
  - [ ] Database connection secure

- [ ] **Security**
  - [ ] HTTPS enabled
  - [ ] CORS configured properly
  - [ ] Rate limiting enabled
  - [ ] SQL injection protection
  - [ ] XSS protection
  - [ ] Webhook signature verification

- [ ] **Monitoring**
  - [ ] Error logging (Sentry, LogRocket, etc.)
  - [ ] Performance monitoring (New Relic, DataDog)
  - [ ] Webhook failure alerts
  - [ ] Payment failure alerts

- [ ] **Cashfree Configuration**
  - [ ] Production API keys added
  - [ ] Webhook URL configured
  - [ ] IP whitelisting (backend server IP only)
  - [ ] Domain whitelisting
  - [ ] Return URL configured

### iOS App

- [ ] **Configuration**
  - [ ] Production API URL configured
  - [ ] Remove all test credentials
  - [ ] URL scheme configured
  - [ ] LSApplicationQueriesSchemes added

- [ ] **Security**
  - [ ] SSL pinning (optional but recommended)
  - [ ] No hardcoded secrets
  - [ ] JWT token stored securely (Keychain)
  - [ ] Proper error messages (no sensitive info)

- [ ] **Testing**
  - [ ] Test on real devices
  - [ ] Test with production API (staging)
  - [ ] Test all payment methods
  - [ ] Test network failures
  - [ ] Test UI on different screen sizes

### Final Steps

- [ ] **Documentation**
  - [ ] API documentation complete
  - [ ] Payment flow documented
  - [ ] Error codes documented
  - [ ] Runbook for common issues

- [ ] **Compliance**
  - [ ] Privacy policy updated
  - [ ] Terms of service updated
  - [ ] Refund policy defined
  - [ ] Customer support process

- [ ] **Deployment**
  - [ ] Staging environment tested
  - [ ] Load testing completed
  - [ ] Backup strategy in place
  - [ ] Rollback plan ready

---

## Summary

### Key Changes from Current Implementation

**Before (Direct API Calls):**
```
iOS App → Cashfree API (with secret keys in app ❌)
```

**After (Backend Integration):**
```
iOS App → Your Backend → Cashfree API ✅
```

### Benefits

1. **Security**: Secret keys never leave backend
2. **Reliability**: Server-side validation prevents tampering
3. **Flexibility**: Easy to change payment providers
4. **Compliance**: Proper audit trail in database
5. **Control**: You control the entire payment flow

### Next Steps

1. **Immediate**: Disable IP whitelisting in Cashfree dashboard to test current implementation
2. **Short-term**: Implement backend endpoints as described above
3. **Long-term**: Add monitoring, analytics, and optimize the flow

---

**Questions or Issues?**

- Backend API not working → Check logs, verify credentials
- iOS app crashing → Check console for errors
- Payment not completing → Check webhook logs
- Webhook not receiving → Verify URL in Cashfree dashboard

**Remember:** Always test thoroughly in sandbox before going to production!
