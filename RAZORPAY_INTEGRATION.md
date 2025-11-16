# Razorpay Integration Guide - BunkBite

## Overview

BunkBite now uses **Razorpay** as the complete payment gateway for all transactions. This document covers the full integration including iOS implementation and required backend endpoints.

---

## Table of Contents

1. [iOS Setup](#ios-setup)
2. [Backend Integration](#backend-integration)
3. [Payment Flow](#payment-flow)
4. [Testing](#testing)
5. [Production Deployment](#production-deployment)
6. [Troubleshooting](#troubleshooting)

---

## iOS Setup

### ✅ Already Completed

- Razorpay SDK installed via CocoaPods (v1.3.14)
- PaymentSheet integrated with Razorpay checkout
- RazorpayService created for API calls
- Payment delegate implemented
- UI designed with Razorpay branding

### Configuration Required

#### 1. Add Your Razorpay Key

Edit `BunkBite/Utils/Constants.swift`:

```swift
static let razorpayKey = "rzp_test_abc123..."  // Your actual test key
```

Get your keys from: https://dashboard.razorpay.com/app/keys

#### 2. Open Workspace in Xcode

**IMPORTANT:** Always open `BunkBite.xcworkspace` (not `.xcodeproj`)

```bash
open BunkBite.xcworkspace
```

#### 3. Build Settings (if needed)

If you encounter build issues, set the Objective-C Bridging Header:

- Project Settings → Build Settings
- Search for "Objective-C Bridging Header"
- Set to: `$(PROJECT_DIR)/BunkBite/BunkBite-Bridging-Header.h`

---

## Backend Integration

### Required Endpoints

Your backend needs to implement these two endpoints:

#### 1. Create Order Endpoint

**POST** `/api/payments/create-order`

Creates a Razorpay order and returns order_id for iOS to process.

**Request Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 15000,
  "currency": "INR",
  "canteen_id": "canteen_123",
  "items": [
    {
      "menu_item_id": "item_1",
      "name": "Masala Dosa",
      "quantity": 2,
      "price": 75.00
    }
  ]
}
```

**Response (Success):**
```json
{
  "success": true,
  "order_id": "order_MNqwerty123456",
  "amount": 15000,
  "currency": "INR",
  "key": "rzp_test_abc123..."
}
```

**Node.js Implementation Example:**

```javascript
const Razorpay = require('razorpay');

const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
});

app.post('/api/payments/create-order', authenticateToken, async (req, res) => {
    try {
        const { amount, currency, canteen_id, items } = req.body;

        // Validate amount
        if (!amount || amount <= 0) {
            return res.status(400).json({
                success: false,
                error: 'Invalid amount'
            });
        }

        // Create Razorpay order
        const options = {
            amount: amount, // amount in paise
            currency: currency || 'INR',
            receipt: `order_${Date.now()}`,
            notes: {
                user_id: req.user.id,
                canteen_id: canteen_id,
                items: JSON.stringify(items)
            }
        };

        const order = await razorpay.orders.create(options);

        // Save order to database
        await db.orders.create({
            order_id: order.id,
            user_id: req.user.id,
            canteen_id: canteen_id,
            amount: amount,
            currency: currency,
            status: 'created',
            items: items,
            created_at: new Date()
        });

        res.json({
            success: true,
            order_id: order.id,
            amount: order.amount,
            currency: order.currency,
            key: process.env.RAZORPAY_KEY_ID
        });

    } catch (error) {
        console.error('Order creation error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create order'
        });
    }
});
```

#### 2. Verify Payment Endpoint

**POST** `/api/payments/verify`

Verifies the payment signature and updates order status.

**Request Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "razorpay_order_id": "order_MNqwerty123456",
  "razorpay_payment_id": "pay_MNabcdef123456",
  "razorpay_signature": "generated_signature_string"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "order_id": "order_internal_123"
}
```

**Node.js Implementation Example:**

```javascript
const crypto = require('crypto');

app.post('/api/payments/verify', authenticateToken, async (req, res) => {
    try {
        const {
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature
        } = req.body;

        // Verify signature
        const sign = razorpay_order_id + '|' + razorpay_payment_id;
        const expectedSign = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(sign.toString())
            .digest('hex');

        if (razorpay_signature !== expectedSign) {
            return res.status(400).json({
                success: false,
                error: 'Invalid signature'
            });
        }

        // Find order in database
        const order = await db.orders.findOne({
            where: { order_id: razorpay_order_id }
        });

        if (!order) {
            return res.status(404).json({
                success: false,
                error: 'Order not found'
            });
        }

        // Verify order belongs to user
        if (order.user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                error: 'Unauthorized'
            });
        }

        // Update order status
        await db.orders.update({
            status: 'paid',
            payment_id: razorpay_payment_id,
            signature: razorpay_signature,
            paid_at: new Date()
        }, {
            where: { order_id: razorpay_order_id }
        });

        // Trigger order fulfillment (notify canteen, etc.)
        await notifyCanteen(order.canteen_id, order.id);

        res.json({
            success: true,
            message: 'Payment verified successfully',
            order_id: order.id
        });

    } catch (error) {
        console.error('Payment verification error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to verify payment'
        });
    }
});
```

### Database Schema Example

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(255) UNIQUE NOT NULL,
    user_id INTEGER NOT NULL,
    canteen_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    status VARCHAR(50) DEFAULT 'created',
    payment_id VARCHAR(255),
    signature TEXT,
    items JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    paid_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (canteen_id) REFERENCES canteens(id)
);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_order_id ON orders(order_id);
```

---

## Payment Flow

### Complete Flow Diagram

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │ 1. Adds items to cart
       │ 2. Clicks "Pay Now"
       ▼
┌─────────────────┐
│  iOS App        │
│  (PaymentSheet) │
└────────┬────────┘
         │ 3. POST /api/payments/create-order
         │    { amount, canteen_id, items }
         ▼
┌──────────────────┐
│  Backend Server  │
└────────┬─────────┘
         │ 4. Creates Razorpay order
         │ 5. Saves to database
         │ 6. Returns order_id
         ▼
┌─────────────────┐
│  iOS App        │
└────────┬────────┘
         │ 7. Opens Razorpay checkout
         │    with order_id
         ▼
┌──────────────────┐
│  Razorpay SDK    │
│  (Native UI)     │
└────────┬─────────┘
         │ 8. User completes payment
         │    (UPI/Card/Netbanking)
         │ 9. Returns payment_id & signature
         ▼
┌─────────────────┐
│  iOS App        │
└────────┬────────┘
         │ 10. POST /api/payments/verify
         │     { order_id, payment_id, signature }
         ▼
┌──────────────────┐
│  Backend Server  │
└────────┬─────────┘
         │ 11. Verifies signature
         │ 12. Updates order status to "paid"
         │ 13. Notifies canteen
         ▼
┌─────────────────┐
│  iOS App        │
│  Shows success  │
│  with confetti! │
└─────────────────┘
```

### Security Features

✅ **Server-side order creation** - Prevents amount tampering
✅ **Signature verification** - Ensures payment authenticity
✅ **Token authentication** - Secures API endpoints
✅ **User ownership validation** - Prevents unauthorized access
✅ **HTTPS only** - Encrypted communication
✅ **No secrets in client** - Key/secret stay on backend

---

## Testing

### Test Mode Setup

1. **Get Test Credentials**
   - Login to https://dashboard.razorpay.com/
   - Go to Settings → API Keys
   - Copy Test Key ID (starts with `rzp_test_`)
   - Copy Test Key Secret (keep this SECRET on backend only!)

2. **Update Constants**
   ```swift
   static let razorpayKey = "rzp_test_abc123..."
   ```

3. **Update Backend Environment**
   ```bash
   RAZORPAY_KEY_ID=rzp_test_abc123...
   RAZORPAY_KEY_SECRET=your_test_secret_here
   ```

### Test Cards & UPI

#### Test Card (Success)
```
Card Number: 4111 1111 1111 1111
CVV: Any 3 digits
Expiry: Any future date
```

#### Test Card (Failure)
```
Card Number: 4111 1111 1111 1112
CVV: Any 3 digits
Expiry: Any future date
```

#### Test UPI
```
UPI ID: success@razorpay
```

#### Test Wallets
All test wallets will show success in test mode.

### Testing Checklist

- [ ] Order creation succeeds
- [ ] Razorpay checkout opens correctly
- [ ] Payment with test card succeeds
- [ ] Payment verification completes
- [ ] Success popup shows with confetti
- [ ] Order status updates in database
- [ ] Failed payment shows error alert
- [ ] Cancelled payment handles gracefully

---

## Production Deployment

### Pre-deployment Checklist

- [ ] Replace test key with live key in Constants.swift
- [ ] Replace test credentials on backend
- [ ] Enable webhooks on Razorpay dashboard
- [ ] Set up proper error logging
- [ ] Configure retry logic for failed verifications
- [ ] Add rate limiting to payment endpoints
- [ ] Enable HTTPS/SSL on backend
- [ ] Test with real small amount (₹1)
- [ ] Review transaction logs
- [ ] Set up payment failure notifications

### Environment Variables (Backend)

```bash
# Production
RAZORPAY_KEY_ID=rzp_live_xyz...
RAZORPAY_KEY_SECRET=your_live_secret
NODE_ENV=production

# Test
RAZORPAY_KEY_ID=rzp_test_abc...
RAZORPAY_KEY_SECRET=your_test_secret
NODE_ENV=development
```

### iOS Configuration

Update Constants.swift for production:

```swift
#if DEBUG
static let razorpayKey = "rzp_test_abc123..."
#else
static let razorpayKey = "rzp_live_xyz789..."
#endif
```

---

## Troubleshooting

### Common Issues

#### 1. "No such module 'Razorpay'"

**Solution:**
- Make sure you're opening `BunkBite.xcworkspace` (not `.xcodeproj`)
- Run `pod install` again
- Clean build folder (⇧⌘K) and rebuild

#### 2. Order creation fails

**Check:**
- Backend endpoint is accessible
- Authentication token is valid
- Amount is in paise (multiply by 100)
- Razorpay credentials are correct

#### 3. Payment verification fails

**Check:**
- Signature verification logic is correct
- Key secret matches the key ID used
- Order exists in database
- User owns the order

#### 4. Razorpay checkout doesn't open

**Check:**
- Order ID is valid
- Razorpay key is correct
- View controller reference is valid
- iOS version is 13+

### Debug Logging

Enable detailed logging:

```swift
// In PaymentSheet
print("🔔 Order created: \(orderId)")
print("💰 Amount: ₹\(Double(amount) / 100)")
print("📦 Opening Razorpay...")
```

Backend logging:
```javascript
console.log('Creating order:', { amount, currency, userId });
console.log('Razorpay response:', order);
```

### Support

- **Razorpay Docs:** https://razorpay.com/docs/
- **iOS Integration:** https://razorpay.com/docs/payments/payment-gateway/ios-integration/
- **API Reference:** https://razorpay.com/docs/api/
- **Support:** support@razorpay.com

---

## Files Modified

### iOS Files
- ✅ `PaymentSheet.swift` - Razorpay checkout integration
- ✅ `RazorpayService.swift` - Backend API service
- ✅ `Constants.swift` - Razorpay key configuration
- ✅ `Podfile` - CocoaPods dependencies

### Backend Files (To Implement)
- ⏳ `routes/payments.js` - Payment endpoints
- ⏳ `models/Order.js` - Order database model
- ⏳ `.env` - Environment variables

---

## Summary

✅ **iOS Integration:** Complete
✅ **SDK Installed:** Razorpay v1.3.14
✅ **Payment UI:** Beautiful & branded
⏳ **Backend:** Needs implementation
⏳ **Production:** Needs deployment

**Next Steps:**
1. Implement backend endpoints
2. Add your Razorpay test keys
3. Test payment flow
4. Deploy to production with live keys

---

**Status:** Ready for backend integration
**Mode:** Using Razorpay for all payments
**Security:** Production-grade implementation
