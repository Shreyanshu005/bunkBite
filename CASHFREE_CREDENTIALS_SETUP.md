# Cashfree Credentials Setup Guide

## 🚨 ISSUE: Invalid API Credentials

You're getting this error:
```json
{"message":"endpoint or method is not valid, please check api documentation","code":"request_failed","type":"api_connection_error"}
```

This error means your Cashfree API credentials are **invalid or not properly configured**.

## 📋 Current Credentials in Constants.swift

```swift
cashfreeAppId = "TEST1071483728c8caaaea9712f6c11573841701"
cashfreeSecretKey = "cfsk_ma_test_1ebc1d93322e969fd16bb27961a8a193_5d39f41e"
```

These appear to be placeholder credentials and need to be replaced with **real credentials from your Cashfree dashboard**.

---

## 🔧 How to Get Valid Cashfree Credentials

### Step 1: Log in to Cashfree Merchant Dashboard

1. Go to: **https://merchant.cashfree.com/merchants/login**
2. Log in with your Cashfree account
3. If you don't have an account, sign up at: **https://www.cashfree.com/signup**

### Step 2: Get Your Test/Sandbox Credentials

1. After logging in, go to **Developers** section
2. Click on **API Keys** or **Credentials**
3. You should see two sets of credentials:
   - **TEST/SANDBOX** credentials (for development)
   - **PRODUCTION** credentials (for live payments)

4. Copy your **TEST credentials**:
   - **App ID** (Client ID) - starts with "TEST" followed by numbers
   - **Secret Key** - starts with "cfsk_ma_test_" followed by alphanumeric string

### Step 3: Update Constants.swift

Open `BunkBite/Utils/Constants.swift` and replace the credentials:

```swift
// Cashfree Configuration
static let cashfreeAppId = "YOUR_TEST_APP_ID_HERE" // e.g., TEST1071483728c8caaaea9712f6c11573841701
static let cashfreeSecretKey = "YOUR_TEST_SECRET_KEY_HERE" // e.g., cfsk_ma_test_xxxxxxxxxxxxx
static let cashfreeEnvironment: CashfreeEnvironment = .sandbox // Keep as .sandbox for testing
```

### Step 4: Verify API Version

Cashfree has multiple API versions. The current implementation uses **2023-08-01**. If this doesn't work, try:
- `2023-08-01` (recommended for latest features)
- `2022-09-01` (stable version)
- `2022-01-01` (older version)

---

## 🧪 Alternative: Use Cashfree's Public Test Credentials

If you're just testing and don't want to sign up yet, you can search for Cashfree's public test credentials in their documentation. However, these are **not recommended for production** and may have limitations.

**Cashfree Documentation:**
- API Reference: https://docs.cashfree.com/reference/pg-new-apis-endpoint
- Getting Started: https://docs.cashfree.com/docs/getting-started

---

## 🔍 After Updating Credentials

### Test the Integration:

1. Update the credentials in `Constants.swift`
2. Clean and rebuild your app:
   ```bash
   # In Xcode: Product → Clean Build Folder (Cmd+Shift+K)
   # Then rebuild: Product → Build (Cmd+B)
   ```
3. Run the app and try making a payment
4. Check the console for these logs:

```
🔍 DEBUG: Cashfree API Request Details
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Endpoint: https://sandbox.cashfree.com/pg/orders
Method: POST
App ID: YOUR_APP_ID
Secret Key (first 20 chars): cfsk_ma_test_xxxxxxx...
API Version: 2023-08-01
Environment: SANDBOX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Expected Success Response:

If credentials are correct, you should see:
```
Cashfree API Response Status: 200
Full API Response: {
    "cf_order_id": ...,
    "order_id": "order_xxx",
    "payment_session_id": "session_xxx",
    ...
}
```

---

## ⚠️ Common Issues

### Issue 1: "endpoint or method is not valid"
**Cause:** Invalid credentials or wrong API version
**Solution:** Double-check your App ID and Secret Key from dashboard

### Issue 2: "Invalid signature"
**Cause:** Secret key doesn't match App ID
**Solution:** Ensure both credentials are from the same environment (TEST or PROD)

### Issue 3: "Account not activated"
**Cause:** Cashfree account not fully set up
**Solution:** Complete KYC and account activation in dashboard

### Issue 4: API version mismatch
**Cause:** Using wrong API version
**Solution:** Try different versions (2023-08-01, 2022-09-01, 2022-01-01)

---

## 🔒 Security Note

**IMPORTANT:** Once you get valid credentials:

1. ✅ Use TEST credentials for development
2. ✅ Keep credentials in Constants.swift for now (for testing only)
3. ❌ **NEVER commit production credentials to git**
4. ❌ **NEVER hardcode credentials in production app**

**Before going live:**
- Move credential management to your backend server
- Create endpoint: `POST /api/v1/payments/create-order`
- Backend should call Cashfree API with production credentials
- iOS app should only call your backend, not Cashfree directly

---

## 📞 Need Help?

If you still face issues after updating credentials:

1. **Check Cashfree Status:** https://status.cashfree.com/
2. **Documentation:** https://docs.cashfree.com/
3. **Support:** Contact Cashfree support from your merchant dashboard
4. **API Logs:** Check API request/response logs in Cashfree dashboard

---

## ✅ Checklist

- [ ] Logged in to Cashfree merchant dashboard
- [ ] Got TEST App ID from Developers > API Keys
- [ ] Got TEST Secret Key from Developers > API Keys
- [ ] Updated both values in `Constants.swift`
- [ ] Verified environment is set to `.sandbox`
- [ ] Cleaned and rebuilt Xcode project
- [ ] Tested payment flow
- [ ] Verified console shows 200 response from Cashfree API

---

**Last Updated:** November 21, 2025
**Status:** Waiting for valid Cashfree credentials
