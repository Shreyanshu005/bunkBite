# Razorpay to Cashfree Migration Guide

## Migration Summary

BunkBite payment integration has been successfully migrated from **Razorpay** to **Cashfree Payment Gateway**.

**Migration Date:** November 17, 2024  
**SDK Version:** CashfreePG 2.0.19

---

## What Changed

### 1. Dependencies

**Before (Razorpay):**
```ruby
pod 'razorpay-pod', '1.2.5'
```

**After (Cashfree):**
```ruby
pod 'CashfreePG', '~> 2.0.15'
```

### 2. Imports

**Before:**
```swift
import Razorpay
```

**After:**
```swift
import CashfreePG
import CashfreePGCoreSDK
import CashfreePGUISDK
```

### 3. Configuration (Constants.swift)

**Before:**
```swift
static let razorpayKey = "rzp_test_RgMWemF69VDJHw"
```

**After:**
```swift
static let cashfreeAppId = "TEST"
static let cashfreeEnvironment: CashfreeEnvironment = .sandbox
```

---

## Files Modified

### 1. **Podfile**
- Removed: `pod 'razorpay-pod', '1.2.5'`
- Added: `pod 'CashfreePG', '~> 2.0.15'`
- Updated comments to reflect Cashfree

### 2. **BunkBite/Utils/Constants.swift**
- Removed Razorpay configuration
- Added Cashfree configuration with environment enum
- Added `CashfreeEnvironment` enum for sandbox/production switching

### 3. **BunkBite/Services/CashfreeDelegate.swift** (New)
- Complete rewrite of payment delegate
- Implements `CFResponseDelegate` protocol
- Handles payment success, failure, and verification
- Comprehensive logging for debugging

### 4. **BunkBite/Views/User/PaymentSheet.swift**
- Replaced Razorpay SDK calls with Cashfree SDK
- Updated payment initiation flow
- Changed payment session creation
- Updated UI text from "Razorpay" to "Cashfree"
- Modified payment method integration

### 5. **BunkBite/Views/User/CartSheet.swift**
- Replaced Razorpay payment flow with Cashfree
- Updated callback handling
- Changed payment response processing
- Updated test payment instructions

### 6. **BunkBite/Services/RazorpayDelegate.swift** (Deleted)
- Old Razorpay delegate removed completely

---

## Key Differences Between Razorpay and Cashfree

| Feature | Razorpay | Cashfree |
|---------|----------|----------|
| **SDK Import** | `import Razorpay` | `import CashfreePG` |
| **Session Creation** | Direct with key | Builder pattern with CFSession |
| **Environment** | Test/Live key | Enum: `.SANDBOX` / `.PRODUCTION` |
| **Delegate Protocol** | `RazorpayPaymentCompletionProtocolWithData` | `CFResponseDelegate` |
| **Payment Methods** | Auto-detected | Configured via `CFPaymentComponentBuilder` |
| **Theme** | Options dictionary | `CFThemeBuilder` |
| **Test Card** | 4111 1111 1111 1111 | 4111 1111 1111 1111 (same) |
| **Test UPI** | `success@razorpay` | `testsuccess@gocash` |

---

## Migration Steps Performed

### Step 1: Remove Razorpay
```bash
pod deintegrate
```

### Step 2: Update Podfile
```ruby
pod 'CashfreePG', '~> 2.0.15'
```

### Step 3: Install Cashfree
```bash
pod install
```

### Step 4: Update Code
- Modified Constants.swift
- Created CashfreeDelegate.swift
- Updated PaymentSheet.swift
- Updated CartSheet.swift
- Removed RazorpayDelegate.swift

### Step 5: Test
- Build project
- Test payment flow
- Verify callbacks

---

## Cashfree Integration Details

### Session Builder Pattern

```swift
let session = CFSession.CFSessionBuilder()
    .setEnvironment(.SANDBOX)  // or .PRODUCTION
    .setOrderId(orderId)
    .setOrderAmount(String(format: "%.2f", amount))
    .setOrderCurrency("INR")
    .setCustomerDetails(CFCustomerDetails(
        customerId: "customer_id",
        customerPhone: "9999999999",
        customerEmail: "user@example.com"
    ))
    .build()
```

### Theme Customization

```swift
let theme = CFThemeBuilder()
    .setNavigationBarBackgroundColor(UIColor.systemPink)
    .setNavigationBarTextColor(UIColor.white)
    .setPrimaryFont("Urbanist")
    .setSecondaryFont("Urbanist")
    .build()
```

### Payment Components

```swift
let paymentComponent = CFPaymentComponentBuilder()
    .enableComponents([
        "order-details",
        "card",
        "upi",
        "nb",
        "wallet",
        "paylater"
    ])
    .build()
```

### Initiating Payment

```swift
let cashfree = CFPaymentGatewayService.getInstance()
cashfree.setCallback(callback)
cashfree.doPayment(session, 
                   paymentComponent: paymentComponent,
                   viewController: topController,
                   theme: theme)
```

---

## Callback Handling

### Success Callback

```swift
func onPaymentCompletion(_ cfPaymentResponse: CFPaymentGatewayResponse?) {
    guard let response = cfPaymentResponse else { return }
    
    let data = response.getData()
    let paymentId = data?["cf_payment_id"] as? String
    let orderId = response.getOrderID()
    let txStatus = response.getTxStatus()
    
    if txStatus.uppercased() == "SUCCESS" {
        // Handle success
    }
}
```

### Error Callback

```swift
func onError(_ error: CFErrorResponse, order_id: String) {
    print("Error: \(error.message)")
    print("Error Code: \(error.status)")
    print("Error Type: \(error.type)")
}
```

### Verify Callback

```swift
func verifyPayment(order_id: String) {
    // Verify payment status with your backend
}
```

---

## Testing

### Test Cards

**Credit/Debit Card:**
- Card Number: `4111 1111 1111 1111`
- CVV: `123`
- Expiry: Any future date (e.g., `12/25`)

**UPI:**
- Test UPI ID: `testsuccess@gocash`

**Netbanking:**
- Select any bank
- Use "Success" as credentials

### Test Environment

Set in Constants.swift:
```swift
static let cashfreeEnvironment: CashfreeEnvironment = .sandbox
```

For production:
```swift
static let cashfreeEnvironment: CashfreeEnvironment = .production
```

---

## Environment Configuration

### Sandbox (Development/Testing)
```swift
static let cashfreeAppId = "TEST"
static let cashfreeEnvironment: CashfreeEnvironment = .sandbox
```

### Production (Live)
```swift
static let cashfreeAppId = "YOUR_PRODUCTION_APP_ID"
static let cashfreeEnvironment: CashfreeEnvironment = .production
```

**Note:** Get your production App ID from [Cashfree Merchant Dashboard](https://merchant.cashfree.com/merchants/login)

---

## Backend Integration (When Ready)

### Create Order API

Your backend should provide an endpoint to create Cashfree orders:

```
POST /api/v1/payment/create-order
```

**Request:**
```json
{
  "amount": 250.00,
  "canteen_id": "canteen_123",
  "items": [...],
  "customer_id": "user_123"
}
```

**Response:**
```json
{
  "order_id": "order_xyz",
  "payment_session_id": "session_abc",
  "order_amount": "250.00",
  "order_currency": "INR"
}
```

### Verify Payment API

```
POST /api/v1/payment/verify
```

**Request:**
```json
{
  "order_id": "order_xyz",
  "payment_id": "cf_payment_123",
  "signature": "signature_hash"
}
```

**Response:**
```json
{
  "status": "SUCCESS",
  "order_status": "PAID",
  "payment_time": "2024-11-17T10:30:00Z"
}
```

---

## Benefits of Cashfree

1. **Lower Transaction Fees:** Typically lower than Razorpay
2. **Faster Settlements:** Quicker fund transfers
3. **Better UPI Success Rate:** Optimized UPI routing
4. **Instant Refunds:** Automated refund processing
5. **Better Dashboard:** Improved merchant portal
6. **Advanced Analytics:** Detailed payment insights

---

## Troubleshooting

### Issue: Build Errors After Migration

**Solution:**
```bash
# Clean build folder
rm -rf Pods/ Podfile.lock
pod install
# Clean Xcode build folder (Cmd+Shift+K)
```

### Issue: Payment UI Not Opening

**Solution:**
- Check that `CFPaymentGatewayService.getInstance()` is called
- Verify callback is set before `doPayment()`
- Ensure view controller is valid and presented

### Issue: "Invalid session" Error

**Solution:**
- Verify order_id is unique
- Check order_amount format (must be string with 2 decimals)
- Ensure environment matches (SANDBOX vs PRODUCTION)

### Issue: Payment Success But Callback Not Called

**Solution:**
- Ensure callback object is retained (stored in @State variable)
- Check `CFResponseDelegate` methods are implemented
- Verify callback is set before payment initiation

---

## Migration Checklist

- [x] Remove Razorpay pod from Podfile
- [x] Add Cashfree pod to Podfile
- [x] Run `pod install`
- [x] Update Constants.swift
- [x] Create CashfreeDelegate.swift
- [x] Update PaymentSheet.swift
- [x] Update CartSheet.swift
- [x] Remove RazorpayDelegate.swift
- [ ] Test payment flow with test cards
- [ ] Update backend integration (when ready)
- [ ] Get production Cashfree App ID
- [ ] Switch to production environment for App Store build
- [ ] Update App Store submission notes

---

## Next Steps

1. **Test Thoroughly:**
   - Test all payment methods (Card, UPI, Netbanking, Wallets)
   - Test success and failure scenarios
   - Verify payment callbacks

2. **Backend Integration:**
   - Implement order creation API
   - Implement payment verification API
   - Add webhook handlers for payment notifications

3. **Production Setup:**
   - Get Cashfree production App ID
   - Update `cashfreeAppId` in Constants.swift
   - Change environment to `.production`
   - Test in production mode before submission

4. **App Store:**
   - Update app description if mentioning payment provider
   - Ensure all payment flows work correctly
   - Submit updated build

---

## Support & Documentation

- **Cashfree iOS SDK Docs:** https://docs.cashfree.com/docs/ios
- **Cashfree Dashboard:** https://merchant.cashfree.com
- **Cashfree API Reference:** https://docs.cashfree.com/reference
- **Support Email:** support@bunkbite.me

---

## Summary

The migration from Razorpay to Cashfree has been completed successfully. All payment functionality remains the same from a user perspective, but now uses Cashfree's payment gateway infrastructure. The codebase has been cleaned up, test modes are configured, and the app is ready for testing.

**Status:** ✅ Migration Complete - Ready for Testing
