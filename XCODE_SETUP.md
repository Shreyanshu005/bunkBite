# Xcode Project Setup Instructions

Follow these steps to properly configure the BunkBite app in Xcode:

## 1. Open Project
- Open `BunkBite.xcodeproj` in Xcode

## 2. Configure Network Security (Allow HTTP)

Since the API uses HTTP instead of HTTPS, you need to configure App Transport Security:

### Steps:
1. In Xcode, select the **BunkBite** project in the navigator
2. Select the **BunkBite** target
3. Go to the **Info** tab
4. Right-click on any row and select **"Add Row"** or click the **+** button
5. Add the following key-value pairs:

#### Add App Transport Security Settings:

```
Key: App Transport Security Settings (NSAppTransportSecurity)
Type: Dictionary

Inside this dictionary, add:

1. Key: Allow Arbitrary Loads (NSAllowsArbitraryLoads)
   Type: Boolean
   Value: YES

2. Key: Exception Domains (NSExceptionDomains)
   Type: Dictionary

   Inside Exception Domains, add:

   Key: 13.204.203.159
   Type: Dictionary

   Inside 13.204.203.159, add:

   a) Key: NSExceptionAllowsInsecureHTTPLoads
      Type: Boolean
      Value: YES

   b) Key: NSIncludesSubdomains
      Type: Boolean
      Value: YES
```

### Visual Reference:
```
▼ App Transport Security Settings (Dictionary)
  ▼ Exception Domains (Dictionary)
    ▼ 13.204.203.159 (Dictionary)
        NSExceptionAllowsInsecureHTTPLoads (Boolean) YES
        NSIncludesSubdomains (Boolean) YES
    NSAllowsArbitraryLoads (Boolean) YES
```

## 3. Select Development Team
1. In the **Signing & Capabilities** tab
2. Select your **Team** from the dropdown
3. Xcode will automatically handle provisioning

## 4. Build and Run
1. Select a simulator or connected device from the scheme selector
2. Press **⌘ + R** or click the **Run** button
3. The app will build and launch

## 5. Testing the App

### Test User Flow:
1. Launch app → You'll see the email login screen
2. Enter your email address
3. Click "Send OTP"
4. Check your email for the 6-digit OTP
5. Enter the OTP in the verification screen
6. Based on your role:
   - **User role** → Home, Past Orders, Profile tabs
   - **Admin role** → Inventory, Orders, Profile tabs

### Test API Endpoints:

You can test with these curl commands:

```bash
# Send OTP
curl -X POST http://13.204.203.159/api/v1/auth/email/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"shreyanshu005@gmail.com"}'

# Verify OTP (use the OTP from your email)
curl -X POST http://13.204.203.159/api/v1/auth/email/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"shreyanshu005@gmail.com","otp":"123456"}'
```

## 6. Common Issues and Fixes

### Issue: "Multiple commands produce Info.plist"
**Solution**: This has been fixed by removing the separate Info.plist file. The project now uses the target's Info settings.

### Issue: Build fails with Combine errors
**Solution**: Fixed by adding `import Combine` to AuthViewModel.swift

### Issue: "Cannot connect to server"
**Solution**: Make sure you've configured App Transport Security settings as shown above.

### Issue: Dark mode appears
**Solution**: The app is configured to force light mode. If it still appears dark:
- Check that `preferredColorScheme(.light)` is set in BunkBiteApp.swift
- Restart the simulator

## 7. Project Structure in Xcode

After opening, you should see this structure:

```
BunkBite/
├── BunkBite/
│   ├── Assets.xcassets
│   ├── BunkBiteApp.swift ⭐ Entry point
│   ├── ContentView.swift (unused)
│   ├── Models/
│   │   └── User.swift
│   ├── Services/
│   │   └── APIService.swift
│   ├── ViewModels/
│   │   └── AuthViewModel.swift
│   ├── Views/
│   │   ├── RootView.swift ⭐ Main coordinator
│   │   ├── Auth/
│   │   │   ├── EmailLoginView.swift
│   │   │   └── OTPVerificationView.swift
│   │   ├── Components/
│   │   │   └── CustomButton.swift
│   │   ├── User/
│   │   │   ├── UserMainView.swift
│   │   │   ├── UserHomeView.swift
│   │   │   ├── UserPastOrdersView.swift
│   │   │   └── UserProfileView.swift
│   │   └── Owner/
│   │       ├── OwnerMainView.swift
│   │       ├── OwnerInventoryView.swift
│   │       ├── OwnerOrdersView.swift
│   │       └── OwnerProfileView.swift
│   └── Utils/
│       └── Constants.swift
├── BunkBiteTests/
└── BunkBiteUITests/
```

## 8. Customization

### Change Theme Color:
Edit `Constants.swift` line 13:
```swift
static let primaryColor = Color(hex: "#f62f56") // Change hex code here
```

### Change API Base URL:
Edit `Constants.swift` line 10:
```swift
static let baseURL = "http://13.204.203.159" // Change URL here
```

### Adjust Animations:
Edit `Constants.swift` lines 19-20:
```swift
static let bouncyAnimation = Animation.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)
static let quickBounce = Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2)
```

## 9. Deployment Checklist

Before deploying to App Store:

- [ ] Change to HTTPS endpoints (not HTTP)
- [ ] Remove `NSAllowsArbitraryLoads` from Info settings
- [ ] Update version number in target settings
- [ ] Add app icon in Assets.xcassets
- [ ] Test on real devices
- [ ] Add proper error handling for production
- [ ] Configure proper authentication token storage (Keychain)
- [ ] Add analytics if needed
- [ ] Create screenshots for App Store
- [ ] Write App Store description

## 10. Debug Tips

### View Debug Hierarchy:
- Run app → **Debug** menu → **View Debugging** → **Capture View Hierarchy**

### Network Debugging:
Add this to `APIService.swift` for logging:
```swift
print("📤 Request: \(request.url?.absoluteString ?? "")")
print("📥 Response: \(String(data: data, encoding: .utf8) ?? "")")
```

### Animation Testing:
- Use **Slow Animations** in simulator: **Debug** menu → **Slow Animations** (⌘ + T)

## Support

If you encounter any issues:
1. Clean build folder: **Product** → **Clean Build Folder** (⇧ + ⌘ + K)
2. Restart Xcode
3. Delete DerivedData folder
4. Check that all files are added to target membership

## Ready to Go!

Your BunkBite app is now ready to build and run. Enjoy! 🍔🎉
