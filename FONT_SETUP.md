# Adding Urbanist Font to BunkBite

## Step 1: Download Urbanist Font

1. Go to [Google Fonts - Urbanist](https://fonts.google.com/specimen/Urbanist)
2. Click "Download family" button
3. Extract the downloaded ZIP file

## Step 2: Add Fonts to Xcode

1. In Finder, navigate to the extracted `Urbanist` folder
2. Open the `static` folder
3. Select these font files:
   - `Urbanist-Regular.ttf`
   - `Urbanist-Medium.ttf`
   - `Urbanist-SemiBold.ttf`
   - `Urbanist-Bold.ttf`
   - `Urbanist-Black.ttf`
   - `Urbanist-Light.ttf`
   - `Urbanist-Thin.ttf`

4. In Xcode, right-click on the `BunkBite` folder in the Project Navigator
5. Select "Add Files to BunkBite..."
6. Navigate to and select all the font files listed above
7. Make sure these options are checked:
   - ✅ "Copy items if needed"
   - ✅ "Create groups"
   - ✅ Target: BunkBite

## Step 3: Register Fonts in Info.plist

1. Open `Info.plist` in Xcode
2. Add a new key: `Fonts provided by application` (or `UIAppFonts`)
3. Add these items to the array:
   ```
   Urbanist-Regular.ttf
   Urbanist-Medium.ttf
   Urbanist-SemiBold.ttf
   Urbanist-Bold.ttf
   Urbanist-Black.ttf
   Urbanist-Light.ttf
   Urbanist-Thin.ttf
   ```

## Step 4: Verify Font Installation

Build and run the app. The fonts should now be available!

## Usage

The app now includes a font extension that makes it easy to use Urbanist:

```swift
// Using the extension
Text("Hello World")
    .font(.urbanist(size: 24, weight: .bold))

// Or with the view modifier
Text("Hello World")
    .urbanistFont(size: 24, weight: .bold)
```

## Font already configured in:

The `FontExtension.swift` file has been created with helper methods to use Urbanist throughout the app. The font will fallback to system font if not installed.

## Optional: Apply Globally

To apply Urbanist as the default font throughout the app, you can update the `Constants.swift` file or create a custom view modifier.
