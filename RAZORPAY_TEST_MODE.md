# Razorpay Test Mode Integration Guide

## 🎯 Overview
BunkBite is configured to use Razorpay in **TEST MODE** for development and testing. This allows you to simulate real payments without any actual money being transferred.

## 🔑 Test Configuration
- **Test Key:** `rzp_test_RgMWemF69VDJHw`
- **Mode:** Test/Sandbox
- **Location:** `BunkBite/Utils/Constants.swift`

## 💳 Test Payment Methods

### Credit/Debit Cards
Use these test card numbers for successful payments:

| Card Number | Card Type | Success |
|------------|-----------|---------|
| `4111 1111 1111 1111` | Visa | ✅ Yes |
| `5555 5555 5555 4444` | Mastercard | ✅ Yes |
| `3782 822463 10005` | American Express | ✅ Yes |

**Additional Details:**
- CVV: Any 3 digits (e.g., 123)
- Expiry: Any future date (e.g., 12/25)
- Name: Any name

### UPI
- **Success:** `success@razorpay`
- **Failure:** `failure@razorpay`

### Netbanking
1. Select any bank from the list
2. Click "Success" on the test page to simulate successful payment
3. Click "Failure" to simulate failed payment

### Wallets
All test wallets will show a mock payment page where you can choose success or failure.

## 📊 Payment Flow

### 1. Initiating Payment
When user clicks "Pay Now":
```
1. Cart total calculated
2. Temporary order ID generated (format: order_XXXXX)
3. Razorpay checkout UI opens
```

### 2. Payment Processing
```
User selects payment method → Completes payment → Razorpay processes
```

### 3. Response Captured
After successful payment, the following data is captured:

#### Primary Fields
- `razorpay_payment_id`: Unique payment identifier (e.g., `pay_ABC123xyz`)
- `razorpay_order_id`: Order identifier (e.g., `order_XYZ456abc`)
- `razorpay_signature`: HMAC signature for verification

#### Payment Method Details
- `method`: Payment method used (card/upi/netbanking/wallet)
- `email`: Customer email
- `contact`: Customer phone number
- `card_id`: Card identifier (for card payments)
- `bank`: Bank name (for netbanking)
- `wallet`: Wallet name (for wallet payments)
- `vpa`: UPI ID (for UPI payments)

#### Transaction Details
- `amount`: Amount in paise (multiply by 100)
- `currency`: INR
- `status`: captured/failed

## 🔍 Viewing Payment Details

All payment information is logged to the Xcode console. Look for:

### Success Log Format
```
============================================================
🎉 PAYMENT SUCCESS - RAZORPAY RESPONSE
============================================================

💳 PAYMENT DETAILS:
Payment ID: pay_ABC123xyz
Order ID: order_XYZ456abc

📦 COMPLETE RESPONSE DATA:
  razorpay_payment_id: pay_ABC123xyz
  razorpay_order_id: order_XYZ456abc
  razorpay_signature: abc123...
  method: card
  email: test@bunkbite.com
  contact: 9876543210

🔐 PAYMENT METHOD DETAILS:
Method: CARD
Email: test@bunkbite.com
Contact: 9876543210

🔑 SIGNATURE VERIFICATION:
Signature: ✅ abc123def456...
Status: ✅ READY FOR VERIFICATION

💰 TRANSACTION SUMMARY:
Amount Paid: ₹150.0
Amount in Paise: 15000
Currency: INR
Items: 3
Canteen: Central Cafeteria

📊 KEY FIELDS FOR BACKEND API:
┌─────────────────────────────────────────────────
│ razorpay_payment_id: pay_ABC123xyz
│ razorpay_order_id: order_XYZ456abc
│ razorpay_signature: abc123def456...
│ amount: 15000 (paise)
│ currency: INR
│ method: card
│ status: captured
└─────────────────────────────────────────────────
```

### Error Log Format
```
============================================================
❌ PAYMENT FAILED - RAZORPAY ERROR
============================================================
🔴 Error Code: 2
📝 Description: Payment cancelled by user
📦 Order ID: order_XYZ456abc

💡 TEST MODE TIPS:
- Use test card: 4111 1111 1111 1111
- Use test UPI: success@razorpay
```

## 🚀 Data Structure for Backend API

The app creates a complete `OrderSubmission` object containing:

### Payment Information
```json
{
  "razorpay_payment_id": "pay_ABC123xyz",
  "razorpay_order_id": "order_XYZ456abc",
  "razorpay_signature": "signature_hash"
}
```

### Order Details
```json
{
  "order_id": "order_XYZ456abc",
  "total_amount": 150.0,
  "currency": "INR",
  "item_count": 3
}
```

### User Details
```json
{
  "user_id": "user_123",
  "user_phone": "9876543210",
  "user_email": "test@bunkbite.com"
}
```

### Canteen Details
```json
{
  "canteen_id": "canteen_xyz",
  "canteen_name": "Central Cafeteria"
}
```

### Cart Items
```json
{
  "items": [
    {
      "menu_item_id": "item_1",
      "name": "Coffee",
      "quantity": 2,
      "unit_price": 50.0,
      "total_price": 100.0
    }
  ]
}
```

### Metadata
```json
{
  "order_created_at": "2025-11-16T15:30:00Z",
  "payment_completed_at": "2025-11-16T15:32:00Z",
  "platform": "iOS",
  "app_version": "1.0",
  "device_model": "iPhone 15"
}
```

## 📱 Testing Steps

### 1. Add Items to Cart
- Browse menu items
- Add items to cart
- Review cart total

### 2. Initiate Payment
- Tap "Checkout" or "Pay Now"
- Razorpay checkout opens

### 3. Complete Test Payment
Choose any test method:

**Option A: Test Card**
1. Select "Card"
2. Enter: `4111 1111 1111 1111`
3. CVV: `123`
4. Expiry: `12/25`
5. Click "Pay"

**Option B: Test UPI**
1. Select "UPI"
2. Enter: `success@razorpay`
3. Click "Pay"

**Option C: Netbanking**
1. Select "Netbanking"
2. Choose any bank
3. Click "Success" on test page

### 4. Verify Data Capture
- Check Xcode console for detailed logs
- Verify all payment fields are captured
- Check that order data is saved locally

## 🔐 Security Notes

### Test Mode (Current)
- No real money is transferred
- Can use test credentials freely
- Signature verification is simulated
- Data is saved locally only

### Production Mode (When Backend is Ready)
- Switch to live Razorpay key
- Enable signature verification on backend
- Implement webhook for payment notifications
- Store orders in database
- Enable order status tracking

## 🎨 UI Features

### Payment Sheet Shows:
- Total amount prominently
- Available payment methods with icons
- Security badges (PCI DSS, SSL)
- Test mode indicator (in development)

### After Payment Success:
- Confetti animation 🎉
- Success message
- Order details
- Cart is cleared

## 📝 Next Steps for Backend Integration

1. **Create Order API Endpoint**
   ```
   POST /api/orders/create
   Body: OrderSubmission JSON
   Returns: Order confirmation
   ```

2. **Verify Payment Signature**
   ```
   Use Razorpay signature verification on backend
   Prevent payment tampering
   ```

3. **Store Order in Database**
   ```
   Save order details
   Update canteen inventory
   Notify canteen staff
   ```

4. **Order Status Updates**
   ```
   Track order status
   Send notifications to user
   Update order history
   ```

## 🐛 Troubleshooting

### Payment Not Opening
- Check: Workspace is open (not xcodeproj)
- Check: Razorpay framework is linked
- Check: Test key is valid

### Signature Not Captured
- This is expected in test mode without backend
- Will be provided when using Razorpay Orders API
- Backend should generate orders first

### Console Logs Not Showing
- Check Xcode console is visible (Cmd+Shift+Y)
- Check filter is set to "All Output"
- Look for emoji indicators (🎉, ❌, 💳, etc.)

## 📞 Support

### Razorpay Documentation
- Test Mode: https://razorpay.com/docs/payments/payments/test-mode/
- iOS SDK: https://razorpay.com/docs/payment-gateway/ios-integration/
- Test Cards: https://razorpay.com/docs/payments/payments/test-card-details/

### Dashboard
- Test Mode Dashboard: https://dashboard.razorpay.com/app/dashboard
- Switch between Test/Live mode in top left

---

**Current Status:** ✅ Test Mode Active - Ready for Testing
**Last Updated:** November 16, 2025
