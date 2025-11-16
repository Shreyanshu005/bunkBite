# BunkBite App Structure

## App Flow

```
BunkBiteApp (Entry Point)
    ↓
RootView (Coordinator)
    ↓
[Checks Authentication]
    ↓
    ├─→ NOT AUTHENTICATED
    │       ↓
    │   EmailLoginView
    │       ↓
    │   [Enter Email] → Send OTP
    │       ↓
    │   OTPVerificationView
    │       ↓
    │   [Enter 6-digit OTP] → Verify
    │       ↓
    │   [Success with User Role]
    │
    └─→ AUTHENTICATED
            ↓
        [Check User Role]
            ↓
            ├─→ USER ROLE
            │       ↓
            │   UserMainView (Bottom Navigation)
            │       ├─→ Tab 1: UserHomeView
            │       │   • Welcome banner
            │       │   • Today's special
            │       │   • Quick actions
            │       │   • Categories
            │       │
            │       ├─→ Tab 2: UserPastOrdersView
            │       │   • Order history
            │       │   • Reorder functionality
            │       │   • Order details
            │       │
            │       └─→ Tab 3: UserProfileView
            │           • Profile info
            │           • Settings
            │           • Logout
            │
            └─→ ADMIN ROLE (Owner)
                    ↓
                OwnerMainView (Bottom Navigation)
                    ├─→ Tab 1: OwnerInventoryView
                    │   • Stats cards
                    │   • Search items
                    │   • Category filters
                    │   • Item management
                    │   • Stock tracking
                    │
                    ├─→ Tab 2: OwnerOrdersView
                    │   • Order statistics
                    │   • Status filters
                    │   • Order cards with actions
                    │   • Accept/Reject orders
                    │
                    └─→ Tab 3: OwnerProfileView
                        • Business stats
                        • Management options
                        • Settings
                        • Logout
```

## Screen Details

### Authentication Flow

#### 1. EmailLoginView
- **Purpose**: Collect user email
- **Features**:
  - Logo with bouncy entrance animation
  - Email input field
  - Send OTP button
  - Error message display
  - Smooth transitions

#### 2. OTPVerificationView
- **Purpose**: Verify 6-digit OTP
- **Features**:
  - 6 individual digit boxes
  - Auto-focus and validation
  - 30-second countdown for resend
  - Back navigation
  - Verify button
  - Error handling

### User Panel

#### 1. UserHomeView
- **Purpose**: Main dashboard for users
- **Components**:
  - Personalized greeting
  - Featured "Today's Special" card with gradient
  - Quick action buttons (Menu, Favorites, Repeat, Offers)
  - Category cards (Beverages, Meals, Snacks, Healthy)
  - Smooth scroll animations

#### 2. UserPastOrdersView
- **Purpose**: View order history
- **Components**:
  - Filter button
  - Order cards with:
    - Order number and date
    - Status badge (Delivered/Completed)
    - Item count and total
    - Reorder button
    - View Details button
  - Staggered entrance animations

#### 3. UserProfileView
- **Purpose**: User settings and info
- **Components**:
  - Profile avatar with initial
  - User name and email
  - Profile options:
    - Edit Profile
    - Notifications
    - Payment Methods
    - Saved Addresses
    - Favorites
    - Help & Support
    - Terms & Privacy
  - Logout button with confirmation
  - Version number

### Owner Panel

#### 1. OwnerInventoryView
- **Purpose**: Manage menu items
- **Components**:
  - Search bar
  - Add new item button
  - Stats cards (Total Items, Low Stock, Out of Stock)
  - Category filter chips
  - Inventory item cards with:
    - Item image placeholder
    - Name, category, price
    - Stock status with color coding
    - Available toggle
  - Real-time stock monitoring

#### 2. OwnerOrdersView
- **Purpose**: Manage incoming orders
- **Components**:
  - Order stats (Pending, Preparing, Ready)
  - Status filter chips
  - Order cards with:
    - Order number and time
    - Customer name
    - Status badge (color-coded)
    - Item count and total
    - Action buttons based on status:
      - Pending: Accept/Reject
      - Preparing: Mark as Ready
      - Ready: Mark as Delivered
  - Real-time order updates

#### 3. OwnerProfileView
- **Purpose**: Business management
- **Components**:
  - Owner badge
  - Today's overview stats:
    - Orders count
    - Revenue
  - Management options:
    - Analytics
    - Business Hours
    - Promotions
    - Staff Management
    - Notifications
  - Settings options
  - Logout button

## Design System

### Colors
- **Primary**: #f62f56 (Pink/Red)
- **Background**: White
- **Text**: Black
- **Light Gray**: #F5F5F5
- **Dark Gray**: #666666

### Typography
- **Headers**: System Bold (24-36pt)
- **Body**: System Regular/Medium (14-16pt)
- **Small Text**: System Regular (12-13pt)

### Animations
- **Bouncy Animation**: Spring (response: 0.6, damping: 0.7)
- **Quick Bounce**: Spring (response: 0.3, damping: 0.6)
- **Usage**:
  - Screen transitions
  - Button presses (scale effect)
  - Tab switching
  - Card entrance animations
  - Staggered list animations

### Components

#### CustomButton
- Rounded corners (16pt)
- Height: 56pt
- Loading state with spinner
- Press animation (scale 0.95)
- Primary color background

#### CustomTextField
- Light gray background
- Rounded corners (12pt)
- Primary color focus border
- Keyboard type support

#### OTPTextField
- 6 separate digit boxes
- 50x56pt each
- Focus indicator with primary color
- Auto-advances on input

#### TabBar (Both Panels)
- Custom bottom navigation
- Selected state with colored circle
- Smooth matched geometry animation
- Icons scale on selection
- White background with shadow

### Navigation Pattern
- Bottom tab bar (3 tabs each panel)
- Matched geometry effect for smooth transitions
- No standard iOS tab bar
- Custom design for better UX

## API Integration

### AuthViewModel
- Manages authentication state
- Handles OTP sending/verification
- User data persistence
- Role-based routing
- Logout functionality

### APIService
- Centralized API calls
- Async/await support
- Error handling
- JSON encoding/decoding
- HTTP support for development API

## State Management
- `@StateObject` for ViewModels
- `@ObservedObject` for shared ViewModels
- `@State` for local UI state
- `@FocusState` for keyboard management
- UserDefaults for persistence

## Best Practices Used
1. MVVM architecture
2. Async/await for network calls
3. Proper error handling
4. Reusable components
5. Smooth animations
6. Role-based access control
7. Clean code structure
8. Constants file for theming
9. Proper state management
10. User-friendly UI/UX
