# 🚀 Launch Screen Setup Guide

## Current Status

Your app already has a beautiful animated `LaunchScreenView.swift` with:
- ✅ Gradient background
- ✅ Rotating circles animation
- ✅ Pulsing logo
- ✅ Bouncing text
- ✅ Loading dots
- ✅ Urbanist font styling

## iOS Launch Screen Setup

iOS apps use a **static** launch screen (storyboard or image) that shows instantly, then transitions to your animated SwiftUI view.

### Option 1: LaunchScreen.storyboard (Recommended for iOS 13+)

1. **In Xcode, select BunkBite.xcodeproj**
2. **Go to Info.plist**
3. **Find "Launch Screen" section**
4. **It should reference `LaunchScreen.storyboard`**

### Option 2: Static Image in Assets (iOS 14+)

#### Step 1: Create Launch Screen Image

You need to create a simple static version of your launch screen as an image:

**Required Sizes:**
- **1x**: 375 x 812 pts (iPhone 11 Pro)
- **2x**: 750 x 1624 px (iPhone 11 Pro @2x)
- **3x**: 1125 x 2436 px (iPhone 11 Pro @3x)

**Design Specifications:**
- Background: Gradient (Orange #FF6B35 to lighter orange)
- Center: White circle with fork.knife icon
- Text: "BunkBite" in white (Urbanist Bold)
- Tagline: "Fresh Food, Instant Delivery" (Urbanist Medium)

#### Step 2: Add to Assets

1. In Xcode: **Assets.xcassets** → Right-click → **New Image Set**
2. Name it: `LaunchImage`
3. Drag your images:
   - 1x image → 1x slot
   - 2x image → 2x slot
   - 3x image → 3x slot

#### Step 3: Configure Info.plist

1. Open `Info.plist`
2. Add new row: **UILaunchScreen**
3. Add child: **UIImageName** = `LaunchImage`
4. Add child: **UIColorName** (optional) = `LaunchScreenBackground`

### Option 3: Launch Storyboard (Current Setup - Easiest)

**This is what iOS uses by default.**

1. **Find LaunchScreen.storyboard** in Project Navigator
2. **Open it in Interface Builder**
3. **Add elements to match your design:**
   - Background view with gradient
   - ImageView with your app icon
   - Label with "BunkBite"
   - Label with tagline

**Colors:**
- Background: Orange (#FF6B35)
- Text: White
- Icon: White on orange background

---

## 🎨 Recommended Approach: Use Storyboard

Since you have `LaunchScreenView.swift` for the animated version, use a **simple storyboard** for the static launch:

### LaunchScreen.storyboard Configuration:

1. **Open LaunchScreen.storyboard**
2. **Select the View**
3. **Set background color**: Orange (#FF6B35)
4. **Add a centered VStack:**
   - **ImageView** (100x100): System icon "fork.knife" or your logo
   - **Label**: "BunkBite" (42pt, Bold, White)
   - **Label**: "Fresh Food, Instant Delivery" (16pt, Medium, White)

5. **Set constraints** to center everything

### Verification:

1. **Build and run** the app
2. **First screen** you see should be the static launch screen (0.5-1 second)
3. **Then** it transitions to your animated `LaunchScreenView.swift`

---

## 🎯 Current Animation Flow

```
App Launch
    ↓
LaunchScreen.storyboard (static, instant)
    ↓ (0.5-1 second)
LaunchScreenView.swift (animated, 2-3 seconds)
    ↓
Main App (LoginSheet or Home)
```

---

## 📱 Testing Launch Screen

### Test on Real Device:
1. **Delete the app** from device/simulator
2. **Clean build folder**: Cmd + Shift + K
3. **Build and run**: Cmd + R
4. **Watch the launch sequence**

### Test on Simulator:
1. **Select Simulator**: iPhone 14 Pro
2. **Delete app** from home screen
3. **Run** from Xcode
4. **You should see**:
   - Static launch screen (brief)
   - Animated LaunchScreenView (2-3 seconds)
   - Main app

---

## 🎨 Design Assets Needed

If you want a professional launch screen, you need:

### 1. App Icon
- Already in `Assets.xcassets/AppIcon`
- Used on home screen

### 2. Launch Icon (Optional)
- Simplified version for launch screen
- Can be same as app icon or simplified

### 3. Background Color
- Orange (#FF6B35) or gradient
- Set in Assets or storyboard

---

## 🔧 Quick Fix: Update Storyboard

**Steps to update LaunchScreen.storyboard:**

1. **Open LaunchScreen.storyboard**
2. **Click on the View** (background)
3. **Attributes Inspector** (right sidebar)
4. **Background Color** → Custom → RGB:
   - R: 255
   - G: 107
   - B: 53
   - Alpha: 1.0

5. **Add ImageView** (fork.knife icon):
   - Drag UIImageView to center
   - Set to 100x100
   - Tint: White

6. **Add Label** ("BunkBite"):
   - Drag UILabel below icon
   - Text: "BunkBite"
   - Font: System Bold 42pt
   - Color: White
   - Alignment: Center

7. **Add Label** (tagline):
   - Drag UILabel below BunkBite
   - Text: "Fresh Food, Instant Delivery"
   - Font: System 16pt
   - Color: White (90% opacity)
   - Alignment: Center

8. **Set Constraints**:
   - Center ImageView horizontally and vertically (-50 from center)
   - BunkBite label: 20pt below ImageView
   - Tagline: 8pt below BunkBite label

---

## ✅ Current Setup is Good!

Your `LaunchScreenView.swift` is **perfect** for the animated splash screen.

Just make sure:
1. ✅ LaunchScreen.storyboard exists and has basic UI
2. ✅ Info.plist points to LaunchScreen.storyboard
3. ✅ LaunchScreenView.swift is shown after storyboard

**Your launch screen animations are already implemented beautifully!** The storyboard just needs to match the design for the brief moment before your animated view loads.

---

## 🚨 Common Issues

### Issue 1: Launch screen not updating
**Fix:**
- Delete app from device/simulator
- Clean build folder (Cmd + Shift + K)
- Rebuild

### Issue 2: Launch screen shows white
**Fix:**
- Check LaunchScreen.storyboard exists
- Check Info.plist has correct reference
- Verify background color is set

### Issue 3: Launch screen lasts too long
**Fix:**
- Reduce delay in LaunchScreenView.swift
- Make sure app initializes quickly

---

## 📝 Summary

**Your app already has:**
- ✅ Beautiful animated splash screen (LaunchScreenView.swift)
- ✅ Proper animations (rotating, pulsing, bouncing)
- ✅ Urbanist font usage
- ✅ Brand colors

**What you might need to do:**
- Update LaunchScreen.storyboard to match your animated design
- Or create static launch images for Assets

**The animations are already perfect!** Just make sure the static launch screen (storyboard) looks similar so the transition is smooth.
