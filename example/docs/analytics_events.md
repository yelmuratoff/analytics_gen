# Analytics Events Documentation

Fingerprint: `-1c1db37546dc4641`
Domains: 3 | Events: 7 | Parameters: 13

## Table of Contents

- [auth](#auth)
- [purchase](#purchase)
- [screen](#screen)

## Summary

- **Total Domains**: 3
- **Total Events**: 7
- **Total Parameters**: 13

## auth

Events: 4 | Parameters: 4

| Event | Description | Status | Parameters |
|-------|-------------|--------|------------|
| auth: login | User logs in to the application | **Deprecated** -> `auth.login_v2` | `method` (string): Login method (email, google, apple) |
| auth: login_v2 | User logs in to the application (v2) | Active | `method` (string): Login method v2 (email, google, apple) |
| auth: logout | User logs out | Active | - |
| auth: signup | User creates a new account | Active | `method` (string)<br>`referral_code` (string?): Optional referral code used during signup |

### Code Examples

```dart
Analytics.instance.logAuthLogin(
  method: 'example',
);

Analytics.instance.logAuthLoginV2(
  method: 'example',
);

Analytics.instance.logAuthLogout();

```

## purchase

Events: 2 | Parameters: 6

| Event | Description | Status | Parameters |
|-------|-------------|--------|------------|
| purchase: cancelled | User cancelled a purchase | Active | `product_id` (string)<br>`reason` (string?): Reason for cancellation |
| purchase: completed | User completed a purchase | Active | `currency` (string)<br>`price` (double)<br>`product_id` (string)<br>`quantity` (int): Number of items purchased |

### Code Examples

```dart
Analytics.instance.logPurchaseCancelled(
  productId: 'example',
  reason: null,
);

Analytics.instance.logPurchaseCompleted(
  currency: 'example',
  price: 1.5,
  productId: 'example',
  quantity: 123,
);

```

## screen

Events: 1 | Parameters: 3

| Event | Description | Status | Parameters |
|-------|-------------|--------|------------|
| Screen: View | User views a screen | Active | `duration_ms` (int?): Time spent on previous screen in milliseconds<br>`previous_screen` (string?): Name of the previous screen<br>`screen_name` (string) |

### Code Examples

```dart
Analytics.instance.logScreenView(
  durationMs: null,
  previousScreen: null,
  screenName: 'example',
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

