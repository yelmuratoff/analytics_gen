# Analytics Events Documentation

Generated on: 2025-11-13T17:42:19.731648

## Table of Contents

- [screen](#screen)
- [auth](#auth)
- [purchase](#purchase)

## Summary

- **Total Domains**: 3
- **Total Events**: 6
- **Total Parameters**: 12

## screen

Events: 1 | Parameters: 3

| Event | Description | Parameters |
|-------|-------------|------------|
| Screen: View | User views a screen | `screen_name` (string)<br>`previous_screen` (string?): Name of the previous screen<br>`duration_ms` (int?): Time spent on previous screen in milliseconds |

### Code Examples

```dart
Analytics.instance.logScreenView(
  screenName: 'example',
  previousScreen: null,
  durationMs: null,
);

```

## auth

Events: 3 | Parameters: 3

| Event | Description | Parameters |
|-------|-------------|------------|
| auth: login | User logs in to the application | `method` (string): Login method (email, google, apple) |
| auth: logout | User logs out | - |
| auth: signup | User creates a new account | `method` (string)<br>`referral_code` (string?): Optional referral code used during signup |

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

| Event | Description | Parameters |
|-------|-------------|------------|
| purchase: completed | User completed a purchase | `product_id` (string)<br>`price` (double)<br>`currency` (string)<br>`quantity` (int): Number of items purchased |
| purchase: cancelled | User cancelled a purchase | `product_id` (string)<br>`reason` (string?): Reason for cancellation |

### Code Examples

```dart
Analytics.instance.logPurchaseCompleted(
  productId: 'example',
  price: 1.5,
  currency: 'example',
  quantity: 123,
);

Analytics.instance.logPurchaseCancelled(
  productId: 'example',
  reason: null,
);

```

## Usage Examples

```dart
import 'package:analytics_gen/analytics_gen.dart';

// Initialize with your analytics provider
Analytics.initialize(yourAnalyticsService);

// Log events
Analytics.instance.logScreenView(
  screenName: value,
  previousScreen: value,
  durationMs: value,
);
```

