# Flutter Implementation Prompt for BunkBite Features

Implement the following features in the Flutter version of BunkBite to match the iOS app exactly:

## 1. Bottom Navigation Bar (Floating Tab Bar)

Create a custom floating bottom navigation bar with:
- **Position**: Floating 14px from the bottom, centered horizontally
- **Design**: 
  - Rounded corners (radius: 28px)
  - White background with subtle shadow
  - 3 tabs: Menu (home icon), Orders (receipt icon), Profile (person icon)
- **Behavior**:
  - Selected tab has black icon and text
  - Unselected tabs have gray (#9CA3AF) icon and text
  - Smooth animation when switching tabs
  - Tab changes should be instant - if user is in cart and taps menu, immediately navigate to menu
- **Implementation**: Use `Stack` with `Positioned` widget, custom `BottomNavigationBar` or build custom widget

## 2. Search Sheet

Implement a bottom sheet for search with real-time sync:
- **Trigger**: Tap on search bar in home screen
- **Design**:
  - Half-screen bottom sheet (use `showModalBottomSheet` with `isScrollControlled: true`)
  - White background
  - Search input at top with autofocus
  - Real-time search results below
- **Functionality**:
  - **Real-time sync**: As user types, filter menu items instantly
  - Search across: item name, description, category
  - Show filtered results with same card design as menu
  - Empty state when no results found
  - Debounce search input (300ms) for performance
- **Code Structure**:
```dart
class SearchSheet extends StatefulWidget {
  final List<MenuItem> menuItems;
  final Function(MenuItem) onItemTap;
  
  @override
  _SearchSheetState createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  TextEditingController _searchController = TextEditingController();
  List<MenuItem> _filteredItems = [];
  Timer? _debounce;
  
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filteredItems = widget.menuItems.where((item) =>
          item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.description.toLowerCase().contains(query.toLowerCase()) ||
          item.category.toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
    });
  }
}
```

## 3. Login Sheets (Half-Screen)

Implement authentication sheets matching iOS design:

### Login Sheet
- **Presentation**: Half-screen bottom sheet (50% height, expandable to full)
- **Design**:
  - White background with padding (24px horizontal, 32px vertical)
  - No close button (user can swipe down to dismiss)
  - Drag indicator at top
- **Content**:
  - Title: "Welcome to BunkBite" (Urbanist-Bold, 24px)
  - Subtitle: "Order food from your favourite canteen" (Urbanist-Regular, 16px, gray)
  - Email input field with label "Enter your Email"
  - Button: "Send OTP" (black background, white text, disabled when email empty)
  - Error message display (red text) if API returns error
- **Implementation**:
```dart
void _showLoginSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => LoginSheet(),
    ),
  );
}
```

### OTP Verification Sheet
- **Triggered**: After successful OTP send from login sheet
- **Same design** as login sheet but with:
  - Title: "Enter OTP"
  - Subtitle: "We've sent a code to em***@example.com" (mask email)
  - 6-digit OTP input (number keyboard)
  - Button: "Verify" (disabled until 6 digits entered)
  - "Resend OTP" text button below
- **Behavior**:
  - Auto-focus OTP input when sheet opens
  - Limit input to 6 digits
  - On successful verification, close both sheets and refresh user state

## 4. Additional Requirements

### State Management
- Use Provider or Riverpod for state management
- Persist `hasLoadedInitially` flag in OrderViewModel to prevent orders from refetching on tab switch
- Only fetch orders once on first visit to orders tab

### Navigation
- When user taps "Browse Menu" in empty cart, dismiss cart and switch to menu tab
- When user taps "Back to Menu" after order success, dismiss success screen and switch to menu tab
- Implement `Navigator.pop()` when tab changes if user is in a pushed route (like cart)

### Authentication Check
- In cart, when user taps "Proceed to Checkout" while not logged in, show login sheet
- After successful login, allow user to continue checkout

### API Integration
- Use same backend endpoints as iOS app
- Base URL: Get from Constants
- Implement proper error handling for non-JSON responses (HTML error pages)
- Check HTTP status codes before decoding JSON

## 5. Design Specifications

### Colors
- Primary: #0B7D3B (green)
- Dark: #0D1317 (black)
- Gray: #6B7280
- Light Gray: #F3F4F6
- Background: #FFFFFF

### Typography
- Use Google Fonts: Urbanist
- Bold: FontWeight.w700
- Medium: FontWeight.w500
- Regular: FontWeight.w400

### Spacing
- Standard padding: 20-24px
- Button height: 56px
- Border radius: 12px (buttons, inputs), 20px (sheets)

## 6. Testing Checklist

- [ ] Bottom nav bar floats correctly and switches tabs instantly
- [ ] Search sheet opens and filters results in real-time
- [ ] Login sheet opens when needed (checkout without auth)
- [ ] OTP sheet opens after sending OTP
- [ ] Email masking works correctly (em***@domain.com)
- [ ] Orders don't refetch when switching tabs
- [ ] Cart dismisses when switching tabs
- [ ] "Browse Menu" and "Back to Menu" buttons work correctly
- [ ] All sheets have white background (no transparency)
- [ ] Sheets are dismissible by swiping down
- [ ] Input validation works (email format, OTP length)

Implement these features maintaining the exact same UX as the iOS version.
