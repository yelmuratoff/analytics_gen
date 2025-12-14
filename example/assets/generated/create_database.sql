-- Analytics Events Database Schema
-- Fingerprint: 61c5a4357487b877 (domains=3, events=9, parameters=18)

-- Create domains table
CREATE TABLE IF NOT EXISTS domains (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  event_count INTEGER NOT NULL,
  parameter_count INTEGER NOT NULL
);

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  domain_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  event_name TEXT NOT NULL,
  identifier TEXT NOT NULL,
  description TEXT NOT NULL,
  deprecated INTEGER NOT NULL DEFAULT 0,
  replacement TEXT,
  added_in TEXT,
  deprecated_in TEXT,
  custom_event_name TEXT,
  dual_write_to TEXT,
  meta TEXT,
  source_path TEXT,
  line_number INTEGER,
  FOREIGN KEY (domain_id) REFERENCES domains(id),
  UNIQUE(domain_id, name)
);

-- Create parameters table
CREATE TABLE IF NOT EXISTS parameters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  source_name TEXT,
  code_name TEXT NOT NULL,
  type TEXT NOT NULL,
  nullable INTEGER NOT NULL,
  description TEXT,
  allowed_values TEXT,
  regex TEXT,
  min_length INTEGER,
  max_length INTEGER,
  min REAL,
  max REAL,
  operations TEXT,
  added_in TEXT,
  deprecated_in TEXT,
  meta TEXT,
  FOREIGN KEY (event_id) REFERENCES events(id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_events_domain ON events(domain_id);
CREATE INDEX IF NOT EXISTS idx_parameters_event ON parameters(event_id);

-- Insert domain data
INSERT INTO domains (id, name, event_count, parameter_count) VALUES (1, 'auth', 5, 8);
INSERT INTO domains (id, name, event_count, parameter_count) VALUES (2, 'purchase', 2, 6);
INSERT INTO domains (id, name, event_count, parameter_count) VALUES (3, 'screen', 2, 4);

-- Insert event data
INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (1, 1, 'login', 'auth: login', 'auth.login', 'User logs in to the application', 1, 'auth.login_v2', NULL, NULL, NULL, NULL, '{"owner":"auth-team","tier":"critical"}', '/Users/yelamanyelmuratov/Development/analytics_gen/example/events/auth.yaml', 3);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (1, 'method', 'method', 'method', 'string', 0, 'Login method (email, google, apple)', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"is_sensitive":true}');
INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (2, 1, 'login_v2', 'auth: login_v2', 'auth.login_v2', 'User logs in to the application (v2)', 0, NULL, NULL, NULL, NULL, '["auth.login"]', NULL, '/Users/yelamanyelmuratov/Development/analytics_gen/example/events/auth.yaml', 17);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (2, 'login-method', 'method', 'login_method', 'string', 0, 'Login method v2 (email, google, apple)', '["email","google","apple"]', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (2, 'session_id', 'session_id', 'session_id', 'String', 0, 'Unique identifier for the current session.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (3, 1, 'logout', 'auth: logout', 'auth.logout', 'User logs out', 0, NULL, NULL, NULL, NULL, NULL, NULL, '/Users/yelamanyelmuratov/Development/analytics_gen/example/events/auth.yaml', 29);
INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (4, 1, 'phone_login', 'Auth: Phone {phone_country}', 'auth.phone_login', 'When user logs in via phone', 0, NULL, NULL, NULL, 'Auth: Phone {phone_country}', NULL, NULL, '/Users/yelamanyelmuratov/Development/analytics_gen/example/events/auth.yaml', 42);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (4, 'phone_country', 'phone_country', 'phone_country', 'string', 0, 'ISO country code for the dialed number', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (4, 'tracking-token', 'tracking_token', 'tracking_token', 'string', 0, 'Legacy token kept for backend reconciliation', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (4, 'user_exists', 'user_exists', 'user_exists', 'bool', 1, 'Whether the user exists or not', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (5, 1, 'signup', 'auth: signup', 'auth.signup', 'User creates a new account', 0, NULL, NULL, NULL, NULL, NULL, NULL, '/Users/yelamanyelmuratov/Development/analytics_gen/example/events/auth.yaml', 33);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (5, 'method', 'method', 'method', 'string', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (5, 'referral_code', 'referral_code', 'referral_code', 'string', 1, 'Optional referral code used during signup', NULL, '^[A-Z0-9]{6}$', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (6, 2, 'cancelled', 'Purchase Flow: cancelled', 'purchase.cancelled', 'User cancelled a purchase', 0, NULL, NULL, NULL, NULL, NULL, NULL, '/Users/yelamanyelmuratov/Development/analytics_gen/example/events/purchase.yaml', 19);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (6, 'product_id', 'product_id', 'product_id', 'string', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (6, 'reason', 'reason', 'reason', 'string', 1, 'Reason for cancellation', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (7, 2, 'completed', 'Purchase Flow: completed', 'purchase.completed', 'User completed a purchase', 0, NULL, NULL, NULL, NULL, NULL, NULL, '/Users/yelamanyelmuratov/Development/analytics_gen/example/events/purchase.yaml', 3);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (7, 'amount_value', 'price', 'price', 'double', 0, 'Localized amount used by legacy dashboards', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (7, 'currency-code', 'currency', 'currency_code', 'string', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (7, 'product_id', 'product_id', 'product_id', 'string', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (7, 'quantity', 'quantity', 'quantity', 'int', 0, 'Number of items purchased', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (8, 3, 'legacy_view', 'Screen: Legacy', 'screen.legacy_view', 'Legacy backend identifier kept for parity', 0, NULL, NULL, NULL, 'Screen: Legacy', NULL, NULL, '/Users/yelamanyelmuratov/Development/analytics_gen/example/events/screen.yaml', 15);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (8, 'legacy-screen-code', 'legacy_screen_code', 'legacy_screen_code', 'string', 0, 'Three-letter code provided by data team', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO events (id, domain_id, name, event_name, identifier, description, deprecated, replacement, added_in, deprecated_in, custom_event_name, dual_write_to, meta, source_path, line_number) VALUES (9, 3, 'view', 'Screen: {screen_name}', 'Screen: {screen_name}', 'User views a screen', 0, NULL, NULL, NULL, 'Screen: {screen_name}', NULL, NULL, '/Users/yelamanyelmuratov/Development/analytics_gen/example/events/screen.yaml', 3);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (9, 'duration_ms', 'duration_ms', 'duration_ms', 'int', 1, 'Time spent on previous screen in milliseconds', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (9, 'previous_screen', 'previous_screen', 'previous_screen', 'string', 1, 'Name of the previous screen', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO parameters (event_id, name, source_name, code_name, type, nullable, description, allowed_values, regex, min_length, max_length, min, max, operations, added_in, deprecated_in, meta) VALUES (9, 'screen_name', 'screen_name', 'screen_name', 'string', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Create useful views
CREATE VIEW IF NOT EXISTS events_with_domain AS
SELECT 
  e.id,
  d.name AS domain,
  e.name AS event,
  e.event_name,
  e.identifier,
  e.description,
  e.deprecated,
  e.replacement,
  e.added_in,
  e.deprecated_in,
  e.custom_event_name,
  e.dual_write_to,
  e.meta
FROM events e
JOIN domains d ON e.domain_id = d.id;

CREATE VIEW IF NOT EXISTS parameters_with_event AS
SELECT
  p.id,
  d.name AS domain,
  e.name AS event,
  e.event_name,
  p.name AS parameter,
  p.source_name,
  p.code_name,
  p.type,
  p.nullable,
  p.description,
  p.allowed_values,
  p.regex,
  p.min_length,
  p.max_length,
  p.min,
  p.max,
  p.operations,
  p.added_in,
  p.deprecated_in,
  p.meta
FROM parameters p
JOIN events e ON p.event_id = e.id
JOIN domains d ON e.domain_id = d.id;

