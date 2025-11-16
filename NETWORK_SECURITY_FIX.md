# Fix: App Transport Security Error

## Error Message
```
The resource could not be loaded because the App Transport Security policy
requires the use of a secure connection.
```

## Solution: Configure ATS in Xcode

Follow these **exact** steps:

### Step 1: Open Project Settings
1. Open `BunkBite.xcodeproj` in Xcode
2. In the left navigator, click on **BunkBite** (the blue project icon at the top)
3. Under **TARGETS**, select **BunkBite**

### Step 2: Go to Info Tab
1. Click on the **Info** tab (at the top)
2. You'll see a list of properties

### Step 3: Add App Transport Security Settings

#### Option A: Using the GUI (Recommended)

1. **Hover over any row** and you'll see a **+** button appear on the right
2. Click the **+** button to add a new row
3. In the new row that appears:
   - **Key**: Start typing "App Transport" and select **"App Transport Security Settings"**
   - It should automatically be set to **Type: Dictionary**

4. **Click the disclosure triangle** (▶) next to "App Transport Security Settings" to expand it

5. **Hover over "App Transport Security Settings"** row and click the **+** that appears
6. Add this entry:
   - **Key**: Type "Allow" and select **"Allow Arbitrary Loads"**
   - **Type**: Boolean
   - **Value**: Click the dropdown and select **YES**

7. **Hover over "App Transport Security Settings"** again and click **+** to add another entry
8. Add this entry:
   - **Key**: Type "Exception" and select **"Exception Domains"**
   - **Type**: Dictionary

9. **Click the disclosure triangle** next to "Exception Domains" to expand it

10. **Hover over "Exception Domains"** and click **+**
11. Add this entry:
    - **Key**: Type exactly: **13.204.203.159**
    - **Type**: Dictionary

12. **Click the disclosure triangle** next to "13.204.203.159" to expand it

13. **Hover over "13.204.203.159"** and click **+**
14. Add this entry:
    - **Key**: Type "NSException" and select **"Exception Allows Insecure HTTP Loads"**
    - **Type**: Boolean
    - **Value**: YES

15. **Hover over "13.204.203.159"** again and click **+**
16. Add this entry:
    - **Key**: Type "NSIncludes" and select **"Exception Requires Forward Secrecy"**
    - **Type**: Boolean
    - **Value**: NO

### Final Structure Should Look Like This:

```
▼ App Transport Security Settings          (Dictionary)
    Allow Arbitrary Loads                   (Boolean) YES
  ▼ Exception Domains                       (Dictionary)
    ▼ 13.204.203.159                        (Dictionary)
        Exception Allows Insecure HTTP Loads (Boolean) YES
        Exception Requires Forward Secrecy   (Boolean) NO
```

#### Option B: Using Raw Keys (Alternative)

If Option A doesn't work, you can use raw key names:

1. Add a new row with Key: **NSAppTransportSecurity** (Type: Dictionary)
2. Expand it and add:
   - **NSAllowsArbitraryLoads** (Boolean): YES
3. Add another key under NSAppTransportSecurity:
   - **NSExceptionDomains** (Dictionary)
4. Expand NSExceptionDomains and add:
   - **13.204.203.159** (Dictionary)
5. Expand 13.204.203.159 and add:
   - **NSExceptionAllowsInsecureHTTPLoads** (Boolean): YES
   - **NSExceptionRequiresForwardSecrecy** (Boolean): NO

### Step 4: Save and Build
1. Press **⌘ + S** to save
2. **Clean Build Folder**: Press **⌘ + Shift + K**
3. **Build**: Press **⌘ + B**
4. **Run**: Press **⌘ + R**

### Step 5: Verify
After running the app:
1. Try to send an OTP
2. Check the console - you should NOT see the ATS error anymore
3. The API call should succeed

## Visual Guide

### Before (Error):
```
❌ Error Domain=NSURLErrorDomain Code=-1022
   "App Transport Security policy requires secure connection"
```

### After (Success):
```
✅ OTP sent successfully
```

## Screenshot of Info Tab Structure

```
Info Tab
├─ Bundle Identifier: com.yourcompany.BunkBite
├─ Bundle Version: 1
├─ Launch Screen: ...
├─ ▼ App Transport Security Settings
│   ├─ Allow Arbitrary Loads: YES
│   └─ ▼ Exception Domains
│       └─ ▼ 13.204.203.159
│           ├─ Exception Allows Insecure HTTP Loads: YES
│           └─ Exception Requires Forward Secrecy: NO
└─ ...
```

## Troubleshooting

### Issue: Can't find "App Transport Security Settings"
**Solution**: Type the exact text: "App Transport Security Settings" or use the raw key "NSAppTransportSecurity"

### Issue: Changes don't take effect
**Solution**:
1. Clean build folder (⌘ + Shift + K)
2. Quit simulator completely
3. Restart Xcode
4. Build again

### Issue: Still getting ATS error
**Solution**: Make sure you have BOTH:
- `Allow Arbitrary Loads = YES` at the top level
- The exception domain for your specific IP

### Issue: Can't see the Info tab
**Solution**: Make sure you're selecting the TARGET (BunkBite) not the PROJECT

## Important Notes

⚠️ **For Development Only**: This configuration allows insecure HTTP connections. Before releasing to App Store:
1. Switch your API to HTTPS
2. Remove the `Allow Arbitrary Loads` setting
3. Only keep specific exception domains if absolutely necessary

## After Setup

Once configured correctly, your app will:
- ✅ Successfully send OTP requests
- ✅ Successfully verify OTP
- ✅ Work with the HTTP API at http://13.204.203.159
- ✅ Display proper error messages from the API
- ✅ Navigate between screens smoothly

## Next Steps

After the network is working:
1. Test login flow completely
2. Check both user and owner panels
3. Test all animations and transitions
4. Verify logout functionality

Good luck! 🚀
