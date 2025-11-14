# Analytics Events Documentation

Fingerprint: `74b7c22b40f24619`
Domains: 3 | Events: 6 | Parameters: 12

## Table of Contents

- [auth](#auth)
- [purchase](#purchase)
- [screen](#screen)

## Summary

- **Total Domains**: 3
- **Total Events**: 6
- **Total Parameters**: 12

## auth

Events: 3 | Parameters: 3

| Event | Description | Status | Parameters |
|-------|-------------|--------|------------|
| auth: login | User logs in to the application | **Deprecated** -> `auth.login_v2` | `method` (string): Login method (email, google, apple) |
| auth: logout | User logs out | Active | - |
| auth: signup | User creates a new account | Active | `method` (string)<br>`referral_code` (string?): Optional referral code used during signup |

### Code Examples

```dart
Analytics.instance.logAuthLogin(
  method: 'example',
);

Analytics.instance.logAuthLogout();

Analytics.instance.logAuthSignup(
  method: 'example',
  referralCode: null,
);

```

## purchase

Events: 2 | Parameters: 6

| Event | Description | Status | Parameters |
|-------|-------------|--------|------------|
| purchase: cancelled | User cancelled a purchase | Active | `product_id` (string)<br>`reason` (string?): Reason for cancellation |
| purchase: completed | User completed a purchase | Active | `product_id` (string)<br>`price` (double)<br>`currency` (string)<br>`quantity` (int): Number of items purchased |

### Code Examples

```dart
Analytics.instance.logPurchaseCancelled(
  productId: 'example',
  reason: null,
);

Analytics.instance.logPurchaseCompleted(
  productId: 'example',
  price: 1.5,
  currency: 'example',
  quantity: 123,
);

```

## screen

Events: 1 | Parameters: 3

| Event | Description | Status | Parameters |
|-------|-------------|--------|------------|
| Screen: View | User views a screen | Active | `screen_name` (string)<br>`previous_screen` (string?): Name of the previous screen<br>`duration_ms` (int?): Time spent on previous screen in milliseconds |

### Code Examples

```dart
Analytics.instance.logScreenView(
  screenName: 'example',
  previousScreen: null,
  durationMs: null,
);

```

## Usage Examples

```dart
import 'package:analytics_gen/analytics_gen.dart';

// Initialize with your analytics provider
Analytics.initialize(yourAnalyticsService);

// Log events
Analytics.instance.logAuthLogin(
  method: value,
);
```

