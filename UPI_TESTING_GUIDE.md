# 🧪 UPI Payment Testing Guide for Development Builds

## ⚠️ The Problem

When testing UPI payments in a **development/debug build** (not from App Store):
- **UPI apps block the payment** due to risk policy
- Error: "Payment failed as per UPI risk policy"
- This is a security measure by UPI providers to prevent fraud from unsigned apps

---

## ✅ Solutions for Testing UPI Payments

### **Option 1: Simulate Payment (Current Implementation)** ⭐ RECOMMENDED

Your app currently has **simulated payment verification** which is perfect for testing:

**How it works:**
1. User clicks UPI app (Google Pay, PhonePe, etc.)
2. UPI app opens but may show risk policy error
3. User returns to BunkBite app
4. App simulates successful payment after 1.5 seconds
5. Transaction details are captured
6. Order is placed successfully

**Code Location:** [PaymentSheet.swift:302-314](BunkBite/Views/User/PaymentSheet.swift#L302-L314)

```swift
private func verifyPaymentStatus() {
    // Simulate payment verification
    print("🔍 Verifying payment status...")

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        isCheckingPayment = false
        showSuccessPopup = true
        print("✅ Payment verified successfully")
    }
}
```

**✅ What's Being Tested:**
- Payment flow from cart to completion
- Transaction ID generation
- Payment details capture
- Order placement logic
- Success animations (confetti, checkmark)
- Cart clearing after successful payment

**❌ What's NOT Being Tested:**
- Actual money transfer
- Real UPI verification
- Payment gateway integration
- Backend payment confirmation

---

### **Option 2: Add Mock Payment Button** (Easy to Implement)

Add a "Test Payment" button for development that bypasses UPI entirely:

**Implementation:**

1. Add this to [PaymentSheet.swift:172](BunkBite/Views/User/PaymentSheet.swift#L172) (inside the Form, after the info section):

```swift
#if DEBUG
Section {
    Button {
        // Directly trigger success for testing
        isCheckingPayment = true
        verifyPaymentStatus()
    } label: {
        HStack {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
            Text("Mock Successful Payment (Dev Only)")
                .font(.urbanist(size: 15, weight: .semibold))
            Spacer()
        }
        .padding(.vertical, 8)
    }
    .buttonStyle(.borderedProminent)
    .tint(.green)
} header: {
    Text("Development Testing")
} footer: {
    Text("This button only appears in debug builds")
}
#endif
```

This button:
- Only appears in DEBUG builds
- Instantly triggers successful payment
- Perfect for testing order flow
- Won't appear in production/TestFlight builds

---

### **Option 3: Enhance Transaction Logging**

Capture and display detailed transaction data for testing:

**Add Transaction Logger:**

1. Create a new file `TransactionLogger.swift`:

```swift
import Foundation

class TransactionLogger {
    static let shared = TransactionLogger()
    private init() {}

    struct Transaction: Codable, Identifiable {
        let id: String
        let amount: Double
        let timestamp: Date
        let status: String
        let upiApp: String
        let merchantUPI: String
        let customerUPI: String?
        let canteenName: String
        let itemCount: Int
    }

    @Published var transactions: [Transaction] = []

    func logTransaction(_ details: PaymentDetails) {
        let transaction = Transaction(
            id: details.transactionId,
            amount: details.amount,
            timestamp: details.timestamp,
            status: details.status.rawValue,
            upiApp: details.upiApp,
            merchantUPI: details.merchantUPI,
            customerUPI: details.customerUPI,
            canteenName: details.canteenName,
            itemCount: details.itemCount
        )
        transactions.append(transaction)

        // Print to console for debugging
        print("""
        📝 Transaction Logged:
        ID: \(transaction.id)
        Amount: ₹\(transaction.amount)
        Status: \(transaction.status)
        UPI App: \(transaction.upiApp)
        Merchant: \(transaction.merchantUPI)
        Customer: \(transaction.customerUPI ?? "N/A")
        Canteen: \(transaction.canteenName)
        Items: \(transaction.itemCount)
        Time: \(transaction.timestamp)
        """)
    }
}
```

2. Update `verifyPaymentStatus()` in PaymentSheet.swift:

```swift
private func verifyPaymentStatus() {
    print("🔍 Verifying payment status...")

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        if let details = self.paymentDetails {
            // Log transaction for testing
            TransactionLogger.shared.logTransaction(details)
        }

        isCheckingPayment = false
        showSuccessPopup = true
        print("✅ Payment verified successfully")
    }
}
```

3. Add a debug view to see all transactions in UserProfileView:

```swift
#if DEBUG
NavigationLink {
    List(TransactionLogger.shared.transactions) { transaction in
        VStack(alignment: .leading, spacing: 8) {
            Text("TXN: \(transaction.id)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("₹\(transaction.amount, specifier: "%.2f")")
                .font(.title2)
                .fontWeight(.bold)
            Text("\(transaction.status) • \(transaction.upiApp)")
            Text(transaction.timestamp, style: .relative)
                .font(.caption)
        }
    }
    .navigationTitle("Test Transactions")
} label: {
    HStack {
        Image(systemName: "doc.text.magnifyingglass")
        Text("View Test Transactions")
    }
}
#endif
```

---

### **Option 4: TestFlight Build** (Production-Like Testing)

To test with real UPI payments:

1. **Create an Archive:**
   - Product → Archive in Xcode

2. **Upload to TestFlight:**
   - Distribute App → App Store Connect → Upload

3. **Install via TestFlight:**
   - TestFlight builds are signed by Apple
   - UPI apps will accept payments from TestFlight builds
   - You can test with actual small amounts (₹1-10)

**⚠️ Important:**
- Use your own UPI ID for testing
- Test with small amounts
- Keep merchant UPI as test account
- Don't process real customer orders until backend is ready

---

## 🎯 Recommended Testing Approach

### **Phase 1: Development (Current)**
✅ Use simulated payments
✅ Test UI/UX flow
✅ Verify cart clearing
✅ Test animations
✅ Log transaction details to console

### **Phase 2: Internal Testing**
✅ Add mock payment button (#if DEBUG)
✅ Test different scenarios (success, failure, timeout)
✅ Verify transaction logging
✅ Test edge cases (network loss, app backgrounding)

### **Phase 3: Beta Testing**
✅ TestFlight build with real UPI
✅ Small amount testing (₹1-5)
✅ Test with multiple UPI apps
✅ Verify backend integration

### **Phase 4: Production**
✅ Full payment gateway integration
✅ Backend payment verification
✅ Webhook for payment status
✅ Proper error handling and retry logic

---

## 📋 What You're Currently Testing Successfully

Even without real UPI payments, you're testing:

1. ✅ **User Flow**
   - Cart → Payment Sheet → UPI Selection → Return to App → Success

2. ✅ **UI/UX**
   - Payment sheet design
   - UPI app detection
   - Loading states
   - Success animations (confetti, checkmark pulse)
   - Error messages

3. ✅ **Data Capture**
   - Transaction ID generation
   - Payment details structure
   - Amount calculation
   - Timestamp recording
   - UPI app selection

4. ✅ **State Management**
   - Cart state updates
   - Payment verification states
   - Order placement flow
   - Navigation between screens

5. ✅ **Edge Cases**
   - Empty cart prevention
   - Multiple item handling
   - Quantity updates
   - Cart clearing after payment

---

## 🔧 Quick Implementation: Mock Payment Button

Here's the simplest way to add mock payment for testing:

**Add to PaymentSheet.swift after line 171:**

```swift
#if DEBUG
Section {
    Button {
        paymentDetails = PaymentDetails(
            transactionId: "TEST\(Int(Date().timeIntervalSince1970))",
            amount: cart.totalAmount,
            timestamp: Date(),
            status: .success,
            upiApp: "Mock Payment",
            merchantUPI: "8178785849@fam",
            customerUPI: nil,
            canteenName: canteen?.name ?? "BunkBite",
            itemCount: cart.items.count,
            paymentMethod: "TEST"
        )
        isCheckingPayment = true
        verifyPaymentStatus()
    } label: {
        Label("Test Payment (Dev Only)", systemImage: "checkmark.seal.fill")
            .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(.green)
}
#endif
```

---

## 🎓 Summary

**For Development Testing:**
- Current simulated payment is PERFECT for UI/UX testing
- Add mock button for instant testing (#if DEBUG)
- Log transactions to console for verification

**For Real Payment Testing:**
- Use TestFlight builds
- Start with small amounts
- Verify backend integration
- Test webhook callbacks

**Your app is ready for UI/UX testing!** The payment simulation works great for development. When you're ready for production, integrate with a payment gateway (Razorpay, PayU, etc.) that handles UPI verification on the backend.
