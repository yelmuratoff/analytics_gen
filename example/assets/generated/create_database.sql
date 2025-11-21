-- Analytics Events Database Schema
-- Fingerprint: -793406a6e0411e6f (domains=3, events=9, parameters=17)

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
  description TEXT NOT NULL,
  deprecated INTEGER NOT NULL DEFAULT 0,
  replacement TEXT,
  FOREIGN KEY (domain_id) REFERENCES domains(id),
  UNIQUE(domain_id, name)
);

-- Create parameters table
CREATE TABLE IF NOT EXISTS parameters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  nullable INTEGER NOT NULL,
  description TEXT,
  allowed_values TEXT,
  FOREIGN KEY (event_id) REFERENCES events(id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_events_domain ON events(domain_id);
CREATE INDEX IF NOT EXISTS idx_parameters_event ON parameters(event_id);

-- Insert domain data
INSERT INTO domains (id, name, event_count, parameter_count) VALUES (1, 'auth', 5, 7);
INSERT INTO domains (id, name, event_count, parameter_count) VALUES (2, 'purchase', 2, 6);
INSERT INTO domains (id, name, event_count, parameter_count) VALUES (3, 'screen', 2, 4);

-- Insert event data
INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) VALUES (1, 1, 'login', 'auth: login', 'User logs in to the application', 1, 'auth.login_v2');
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (1, 'method', 'string', 0, 'Login method (email, google, apple)', NULL);
INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) VALUES (2, 1, 'login_v2', 'auth: login_v2', 'User logs in to the application (v2)', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (2, 'login-method', 'string', 0, 'Login method v2 (email, google, apple)', 'email, google, apple');
INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) VALUES (3, 1, 'logout', 'auth: logout', 'User logs out', 0, NULL);
INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) VALUES (4, 1, 'phone_login', 'Auth: Phone {phone_country}', 'When user logs in via phone', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (4, 'phone_country', 'string', 0, 'ISO country code for the dialed number', NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (4, 'tracking-token', 'string', 0, 'Legacy token kept for backend reconciliation', NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (4, 'user_exists', 'bool', 1, 'Whether the user exists or not', NULL);
INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) VALUES (5, 1, 'signup', 'auth: signup', 'User creates a new account', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (5, 'method', 'string', 0, NULL, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (5, 'referral_code', 'string', 1, 'Optional referral code used during signup', NULL);
INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) VALUES (6, 2, 'cancelled', 'Purchase Flow: cancelled', 'User cancelled a purchase', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (6, 'product_id', 'string', 0, NULL, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (6, 'reason', 'string', 1, 'Reason for cancellation', NULL);
INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) VALUES (7, 2, 'completed', 'Purchase Flow: completed', 'User completed a purchase', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (7, 'currency-code', 'string', 0, NULL, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (7, 'amount_value', 'double', 0, 'Localized amount used by legacy dashboards', NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (7, 'product_id', 'string', 0, NULL, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (7, 'quantity', 'int', 0, 'Number of items purchased', NULL);
INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) VALUES (8, 3, 'legacy_view', 'Screen: Legacy', 'Legacy backend identifier kept for parity', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (8, 'legacy-screen-code', 'string', 0, 'Three-letter code provided by data team', NULL);
INSERT INTO events (id, domain_id, name, event_name, description, deprecated, replacement) VALUES (9, 3, 'view', 'Screen: {screen_name}', 'User views a screen', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (9, 'duration_ms', 'int', 1, 'Time spent on previous screen in milliseconds', NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (9, 'previous_screen', 'string', 1, 'Name of the previous screen', NULL);
INSERT INTO parameters (event_id, name, type, nullable, description, allowed_values) VALUES (9, 'screen_name', 'string', 0, NULL, NULL);

-- Create useful views
CREATE VIEW IF NOT EXISTS events_with_domain AS
SELECT 
  e.id,
  d.name AS domain,
  e.name AS event,
  e.event_name,
  e.description
FROM events e
JOIN domains d ON e.domain_id = d.id;

