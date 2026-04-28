# BunkBite - Canteen Ordering App

A professional iOS canteen ordering app built with SwiftUI, featuring separate panels for users and owners.

## Features

### Authentication
- Email-based OTP authentication
- Automatic role detection (User/Owner)
- Persistent login with UserDefaults

### User Panel
- **Home Tab**: Browse menu, quick actions, and categories
- **Past Orders Tab**: View order history and reorder
- **Profile Tab**: Manage account settings

### Owner Panel
- **Inventory Tab**: Manage menu items and stock levels
- **Orders Tab**: View and manage incoming orders
- **Profile Tab**: Business analytics and settings

## App Screenshots

| | | |
| :---: | :---: | :---: |
| <img src="https://i.ibb.co/JRWfBBwj/IMG-1770.png" width="200" /> | <img src="https://i.ibb.co/3md7qWt9/IMG-1771.png" width="200" /> | <img src="https://i.ibb.co/zTdjwnQP/IMG-1772-2.png" width="200" /> |
| <img src="https://i.ibb.co/DfMmNCkk/IMG-1774.png" width="200" /> | <img src="https://i.ibb.co/S7GhPxMN/IMG-1777-2.png" width="200" /> | <img src="https://i.ibb.co/mFhRmqys/IMG-1778-2.png" width="200" /> |
| <img src="https://i.ibb.co/Qvx7Db4C/IMG-1776.png" width="200" /> | | |

## Design
- **Theme Colors**:
  - Primary: #f62f56 (Pink)
  - Background: White
  - Light mode only (dark mode disabled)
- **Animations**: Smooth bouncy spring animations throughout the app
- **UI Components**: Custom buttons, text fields, and cards with professional styling

## Project Structure

```
BunkBite/
├── Models/
│   └── User.swift - User and authentication models
├── Services/
│   └── APIService.swift - API communication layer
├── ViewModels/
│   └── AuthViewModel.swift - Authentication state management
├── Views/
│   ├── Auth/
│   │   ├── EmailLoginView.swift - Email input screen
│   │   └── OTPVerificationView.swift - OTP verification screen
│   ├── User/
│   │   ├── UserMainView.swift - User tab navigation
│   │   ├── UserHomeView.swift - User home screen
│   │   ├── UserPastOrdersView.swift - Order history
│   │   └── UserProfileView.swift - User profile
│   ├── Owner/
│   │   ├── OwnerMainView.swift - Owner tab navigation
│   │   ├── OwnerInventoryView.swift - Inventory management
│   │   ├── OwnerOrdersView.swift - Order management
│   │   └── OwnerProfileView.swift - Owner profile
│   ├── Components/
│   │   └── CustomButton.swift - Reusable UI components
│   └── RootView.swift - App coordinator
├── Utils/
│   └── Constants.swift - App constants and theme
└── BunkBiteApp.swift - App entry point

## API Configuration

**Base URL**: http://13.204.203.159

### Endpoints

1. **Send OTP**
   - Route: `/api/v1/auth/email/send-otp`
   - Method: POST
   - Body: `{ "email": "user@example.com" }`

2. **Verify OTP**
   - Route: `/api/v1/auth/email/verify-otp`
   - Method: POST
   - Body: `{ "email": "user@example.com", "otp": "123456" }`

## Setup

1. Open `BunkBite.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on simulator or device

## Network Security

The app is configured to allow HTTP connections to the API server (13.204.203.159) via Info.plist settings.

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Notes

- The app uses `@MainActor` for proper async/await handling
- All network calls are handled asynchronously
- Smooth animations with spring physics for better UX
- Role-based navigation (admin → Owner Panel, user → User Panel)
