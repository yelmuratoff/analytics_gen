# Analytics Events Documentation

Fingerprint: `-6973fa48b7dfcee0`
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
| purchase: cancelled | User cancelled a purchase | `product_id` (string)<br>`reason` (string?): Reason for cancellation |
| purchase: completed | User completed a purchase | `product_id` (string)<br>`price` (double)<br>`currency` (string)<br>`quantity` (int): Number of items purchased |

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

