# Event Naming & Configuration Guide

Each team has a preferred way to name analytics events. Developers often prefer `snake_case` (DB-friendly), while Product Managers and Analysts may prefer `Title Case` (Dashboard-friendly).

`analytics_gen` allows you to configure this globally without forcing developers to manually format every string in YAML.

## Concepts

1.  **Template**: How the raw string is constructed from the domain and event keys.
    *   Default: `{domain}: {event}`
2.  **Casing**: How the final string is formatted after the template is rendered.
    *   `snake_case`: `User Flow: Started` -> `user_flow_started`
    *   `title_case`: `User Flow: Started` -> `User Flow Started`
    *   `original`: `User Flow: Started` -> `User Flow: Started` (No changes)
3.  **Aliases**: Optional mapping to rename technical domain keys (e.g. `auth`) to human-readable names (e.g. `Authentication`).

---

## Scenarios

### 1. The "Engineer Friendly" (Default)
**Goal**: Identifiers in Code (`logAuthLogin`) match identifiers in Data Warehouse (`auth_login`).
**Best for**: SQL, BigQuery, ClickHouse.

**Configuration:**
```yaml
analytics_gen:
  naming:
    casing: snake_case
    event_name_template: "{domain}: {event}" # (Default)
```

**Result:**
*   YAML: `auth` / `login`
*   Template: `auth: login`
*   **Output**: `auth_login`

### 2. The "Business Readable"
**Goal**: Events look great in Mixpanel/Amplitude/Segment UIs without extra formatting.
**Best for**: Non-technical stakeholders, Product Managers.

**Configuration:**
```yaml
analytics_gen:
  naming:
    casing: title_case
    event_name_template: "{domain} {event}"
```

**Result:**
*   YAML: `auth` / `login`
*   Template: `auth login`
*   **Output**: `Auth Login`

### 3. The "Detailed Business Readable" (Aliases)
**Goal**: Use full English names for domains (e.g. "Authentication" instead of "auth").

**Configuration:**
```yaml
analytics_gen:
  naming:
    casing: title_case
    event_name_template: "{domain_alias} {event}"
    domain_aliases:
      auth: "Authentication"
      kyc: "Identity Verification"
```

**Result:**
*   YAML: `auth` / `login_success`
*   Template: `Authentication login_success`
*   **Output**: `Authentication Login Success`

### 4. The "Legacy / Original"
**Goal**: Preserve existing specific naming conventions (e.g. using colons) exactly as they are in the template.

**Configuration:**
```yaml
analytics_gen:
  naming:
    casing: original
    event_name_template: "{domain}: {event}"
```

**Result:**
*   YAML: `auth` / `login`
*   Template: `auth: login`
*   **Output**: `auth: login`

---

## Manual Overrides

If a specific event needs to violate the global rules, use `event_name` in the YAML definition. **Manual overrides always bypass automatic casing.**

```yaml
auth:
  login:
    event_name: "USER_LOGGED_IN_LEGACY" # Will remain exactly like this
    parameters: ...
```
