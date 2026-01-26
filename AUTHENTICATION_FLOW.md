# 🔐 Authentication System - Complete Flow

## 📱 Authentication Screens

### 1. **Login Screen** (`/login`) - Initial Screen
**Features:**
- Email/Password login
- Password visibility toggle
- "Forgot Password?" link
- Social login buttons (Google, OTP)
- Guest login option (limited features)
- Register link
- Language selector
- Animated logo with particle effects
- Glassmorphism design

**Login Options:**
1. **Email/Password**: Traditional login
2. **Google**: Social authentication (mock)
3. **OTP**: Navigate to OTP authentication screen
4. **Guest**: Direct access with limited features (no registration required)

**Navigation:**
- Login Success → `/dashboard`
- Register Link → `/register`
- OTP Button → `/otp-auth`
- Guest Login → `/dashboard` (instant access)

---

### 2. **Register Screen** (`/register`)
**Features:**
- Full Name input
- Email Address input
- Phone Number input
- Password input (with visibility toggle)
- Confirm Password input (with visibility toggle)
- Terms & Conditions checkbox (required)
- Privacy Policy link
- Social registration (Google, Phone)
- Back to Login link
- Form validation

**Fields:**
- ✅ Full Name (required)
- ✅ Email (required, validated)
- ✅ Phone (required, 10 digits)
- ✅ Password (required, min 8 chars)
- ✅ Confirm Password (must match)
- ✅ Terms Agreement (checkbox required)

**Navigation:**
- Register Success → `/dashboard`
- Login Link → `/login` (back)
- Phone Registration → `/otp-auth`

---

### 3. **OTP Authentication Screen** (`/otp-auth`)
**Features:**
- Phone number input
- OTP verification
- Language selector
- Animated logo
- Particle background
- "Get OTP" button
- Terms & Privacy Policy agreement

**Navigation:**
- OTP Success → `/dashboard`

---

## 🔄 Complete Authentication Flow

```
App Start
    ↓
/login (Login Screen)
    ├→ Email/Password Login → /dashboard
    ├→ Google Login → /dashboard
    ├→ OTP Button → /otp-auth → /dashboard
    ├→ Guest Login → /dashboard (instant, no auth)
    └→ Register Link → /register
                          ├→ Create Account → /dashboard
                          ├→ Phone Register → /otp-auth → /dashboard
                          └→ Login Link → /login (back)
```

---

## 👤 User Types

### 1. **Registered User** (Full Access)
- Email/Password login
- Google login
- OTP login
- Full profile access
- All features unlocked
- Application tracking
- Personalized dashboard

### 2. **Guest User** (Limited Access)
- One-click access
- Browse services
- View service details
- Access external links
- **Cannot:**
  - Save applications
  - Track status
  - Access profile
  - Use voice features (optional)

---

## 🎨 Design Features

### All Auth Screens Include:
- **Animated Gradient Background**: Deep space blue with moving gradients
- **Particle System**: 60-80 floating particles with connections
- **Glassmorphism Cards**: Backdrop blur with gradient borders
- **Animated Logo**: Elastic entrance with glow effects
- **Glowing Buttons**: Pulsing glow animation on primary buttons
- **Language Selector**: 4 languages (English, Hindi, Marathi, Tamil)
- **Smooth Transitions**: Page transitions and micro-animations

### Color Scheme:
- Background: Deep Space Blue (#0A192F)
- Primary: Electric Blue (#00D4FF)
- Accent: Neon Cyan (#00FFE0)
- Success: #00FF9D
- Error: #FF6B6B

---

## 🔒 Security Features (Mock)

### Login Screen:
- Password masking with toggle
- "Forgot Password" recovery
- Session management (mock)
- Secure input fields

### Register Screen:
- Password strength validation
- Confirm password matching
- Email format validation
- Phone number validation
- Terms & Conditions agreement
- Privacy Policy compliance

### OTP Screen:
- Phone number verification
- OTP timeout (mock)
- Resend OTP option
- Rate limiting (mock)

---

## 📱 Responsive Design

All screens are:
- ✅ Scrollable (no overflow)
- ✅ Mobile-optimized
- ✅ Tablet-friendly
- ✅ Keyboard-aware
- ✅ Touch-optimized

---

## 🚀 Quick Start Guide

### For Users:

**Option 1: Quick Access (Guest)**
1. Open app → Login Screen
2. Tap "Continue as Guest" → Instant Dashboard Access
3. Browse services, view details, access external links

**Option 2: Full Registration**
1. Open app → Login Screen
2. Tap "Register" → Register Screen
3. Fill form → Create Account → Dashboard
4. Full access to all features

**Option 3: Existing User**
1. Open app → Login Screen
2. Enter email/password → Login → Dashboard
3. Or use Google/OTP login

---

## 🎯 Key Benefits

### Guest Login:
- ✅ Zero friction onboarding
- ✅ Instant access to services
- ✅ No registration required
- ✅ Browse and explore freely
- ✅ Access official government websites

### Registered Login:
- ✅ Personalized experience
- ✅ Application tracking
- ✅ Save progress
- ✅ Voice assistant access
- ✅ Full profile management
- ✅ Multi-device sync (mock)

---

## 📝 Mock Data

### Demo Credentials:
```
Email: demo@cvi.gov.in
Password: demo1234

Or use any email/password - all logins succeed (mock)
```

### Guest Access:
- No credentials needed
- Click "Continue as Guest"
- Instant dashboard access

---

## 🔄 Logout Flow

From any screen:
1. Navigate to Profile (tap avatar)
2. Scroll to bottom
3. Tap "Logout" button
4. Returns to `/login`

---

**Complete authentication system with 3 screens, 4 login methods, and guest access!** 🎉
