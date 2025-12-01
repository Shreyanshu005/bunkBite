# Cashfree Integration - Quick Start Guide

## ✅ Migration Complete!

BunkBite now uses **Cashfree Payment Gateway** instead of Razorpay.

---

## Quick Setup (3 Steps)

### 1. Install Dependencies
```bash
cd /path/to/BunkBite
pod install
```

### 2. Open Project
```bash
open BunkBite.xcworkspace
```

### 3. Configure Environment
In `BunkBite/Utils/Constants.swift`:

**For Testing (Sandbox):**
```swift
static let cashfreeAppId = "TEST"
static let cashfreeEnvironment: CashfreeEnvironment = .sandbox
```

**For Production:**
```swift
static let cashfreeAppId = "YOUR_PRODUCTION_APP_ID"
static let cashfreeEnvironment: CashfreeEnvironment = .production
```

---

## Test Payment

### Test Cards
- **Card:** `4111 1111 1111 1111`
- **CVV:** `123`
- **Expiry:** Any future date (e.g., `12/25`)

### Test UPI
- **UPI ID:** `testsuccess@gocash`

### Netbanking
- Select any bank and use "Success" credentials

---

## What's New

### Files Changed
- ✅ `Podfile` - Now uses Cashfree SDK
- ✅ `Constants.swift` - Cashfree configuration
- ✅ `CashfreeDelegate.swift` - New payment handler
- ✅ `PaymentSheet.swift` - Updated for Cashfree
- ✅ `CartSheet.swift` - Updated for Cashfree
- ❌ `RazorpayDelegate.swift` - Removed

### Payment Flow
1. User adds items to cart
2. Clicks "Pay" button
3. Cashfree payment screen opens
4. User completes payment
5. Success/failure callback handled
6. Order confirmed

---

## Build & Run

```bash
# Clean and rebuild
xcodebuild clean -workspace BunkBite.xcworkspace -scheme BunkBite
xcodebuild -workspace BunkBite.xcworkspace -scheme BunkBite
```

Or use Xcode: **Product → Build** (Cmd+B)

---

## Troubleshooting

### Build Errors?
```bash
# Clean everything
rm -rf Pods/ Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/BunkBite-*
pod install
```

### Payment Not Working?
1. Check environment is set to `.sandbox`
2. Use test card: `4111 1111 1111 1111`
3. Check console logs for detailed payment info

### Need Production Keys?
1. Visit: https://merchant.cashfree.com
2. Get your App ID from Dashboard
3. Update `cashfreeAppId` in Constants.swift
4. Change environment to `.production`

---

## Backend Integration (TODO)

When backend is ready, you'll need:

### 1. Create Order Endpoint
```
POST /api/v1/payment/create-order
```

Returns: `order_id`, `payment_session_id`

### 2. Verify Payment Endpoint
```
POST /api/v1/payment/verify
```

Validates payment and updates order status

**Documentation:** [CASHFREE_MIGRATION.md](./CASHFREE_MIGRATION.md)

---

## Support

- **Documentation:** [CASHFREE_MIGRATION.md](./CASHFREE_MIGRATION.md)
- **Cashfree Docs:** https://docs.cashfree.com/docs/ios
- **App Support:** support@bunkbite.me

---

**Status:** ✅ Ready to Test!
