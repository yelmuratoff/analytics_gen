# Analytics Events Documentation

Fingerprint: `-3362e98eb3426bac`
Domains: 3 | Events: 10 | Parameters: 20

## Table of Contents

- [auth](#auth)
- [purchase](#purchase)
- [screen](#screen)
- [Theme](#theme)
- [User Properties](#user-properties)

## Summary

- **Total Domains**: 3
- **Total Events**: 10
- **Total Parameters**: 20

## auth

Events: 6 | Parameters: 10

| Event | Description | Status | Parameters | Metadata |
|-------|-------------|--------|------------|----------|
| auth: login | User logs in to the application | **Deprecated** -> `auth.login_v2` | `method` (string): Login method (email, google, apple) [is_sensitive: true] | **owner**: auth-team<br>**tier**: critical |
| auth: login_v2 | User logs in to the application (v2) | Active | `login-method` (string): Login method v2 (email, google, apple) (allowed: email, google, apple)<br>`session_id` (String): Unique identifier for the current session. | - |
| auth: logout | User logs out | Active | - | - |
| Auth: Phone {phone_country} | When user logs in via phone | Active | `phone_country` (string): ISO country code for the dialed number<br>`tracking-token` (string): Legacy token kept for backend reconciliation<br>`user_exists` (bool?): Whether the user exists or not | - |
| auth: signup | User creates a new account | Active | `method` (string)<br>`referral_code` (string?): Optional referral code used during signup | - |
| auth: verify_user | User verification status change | Active | `local_status` (import)<br>`status` (import) | - |

### Code Examples

```dart
Analytics.instance.logAuthLogin(
  method: 'example',
);

Analytics.instance.logAuthLoginV2(
  loginMethod: 'example',
  sessionId: 'example',
);

Analytics.instance.logAuthLogout();

```

## purchase

Events: 2 | Parameters: 6

| Event | Description | Status | Parameters | Metadata |
|-------|-------------|--------|------------|----------|
| Purchase Flow: cancelled | User cancelled a purchase | Active | `product_id` (string)<br>`reason` (string?): Reason for cancellation | - |
| Purchase Flow: completed | User completed a purchase | Active | `currency-code` (string)<br>`amount_value` (double): Localized amount used by legacy dashboards<br>`product_id` (string)<br>`quantity` (int): Number of items purchased | - |

### Code Examples

```dart
Analytics.instance.logPurchaseCancelled(
  productId: 'example',
  reason: null,
);

Analytics.instance.logPurchaseCompleted(
  currencyCode: 'example',
  price: 1.5,
  productId: 'example',
  quantity: 123,
);

```

## screen

Events: 2 | Parameters: 4

| Event | Description | Status | Parameters | Metadata |
|-------|-------------|--------|------------|----------|
| Screen: Legacy | Legacy backend identifier kept for parity | Active | `legacy-screen-code` (string): Three-letter code provided by data team | - |
| Screen: {screen_name} | User views a screen | Active | `duration_ms` (int?): Time spent on previous screen in milliseconds<br>`previous_screen` (string?): Name of the previous screen<br>`screen_name` (string) | - |

### Code Examples

```dart
Analytics.instance.logScreenLegacyView(
  legacyScreenCode: 'example',
);

Analytics.instance.logScreenView(
  durationMs: null,
  previousScreen: null,
  screenName: 'example',
);

```

## Theme

Count: 2

| Property | Type | Description | Allowed Values | Metadata |
|----------|------|-------------|----------------|----------|
| is_dark_mode | bool | Whether the app is in dark mode | - | - |
| primary_color | String | The primary color hex code | #FF0000, #00FF00, #0000FF | - |

## User Properties

Count: 5

| Property | Type | Description | Allowed Values | Metadata |
|----------|------|-------------|----------------|----------|
| is_premium | bool | Whether the user has a premium subscription | - | - |
| login_count | int | Total number of logins | - | - |
| tags | List<String> | User tags | - | - |
| user_id | String | Unique identifier for the user | - | - |
| user_role | String | Role of the user in the system | admin, editor, viewer | - |

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

