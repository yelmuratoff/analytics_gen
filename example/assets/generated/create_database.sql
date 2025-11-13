-- Analytics Events Database Schema
-- Generated on: 2025-11-13T17:42:19.743566

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
  FOREIGN KEY (event_id) REFERENCES events(id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_events_domain ON events(domain_id);
CREATE INDEX IF NOT EXISTS idx_parameters_event ON parameters(event_id);

-- Insert domain data
INSERT INTO domains (id, name, event_count, parameter_count) VALUES (1, 'screen', 1, 3);
INSERT INTO domains (id, name, event_count, parameter_count) VALUES (2, 'auth', 3, 3);
INSERT INTO domains (id, name, event_count, parameter_count) VALUES (3, 'purchase', 2, 6);

-- Insert event data
INSERT INTO events (id, domain_id, name, event_name, description) VALUES (1, 1, 'view', 'Screen: View', 'User views a screen');
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (1, 'screen_name', 'string', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (1, 'previous_screen', 'string', 1, 'Name of the previous screen');
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (1, 'duration_ms', 'int', 1, 'Time spent on previous screen in milliseconds');
INSERT INTO events (id, domain_id, name, event_name, description) VALUES (2, 2, 'login', 'auth: login', 'User logs in to the application');
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (2, 'method', 'string', 0, 'Login method (email, google, apple)');
INSERT INTO events (id, domain_id, name, event_name, description) VALUES (3, 2, 'logout', 'auth: logout', 'User logs out');
INSERT INTO events (id, domain_id, name, event_name, description) VALUES (4, 2, 'signup', 'auth: signup', 'User creates a new account');
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (4, 'method', 'string', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (4, 'referral_code', 'string', 1, 'Optional referral code used during signup');
INSERT INTO events (id, domain_id, name, event_name, description) VALUES (5, 3, 'completed', 'purchase: completed', 'User completed a purchase');
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (5, 'product_id', 'string', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (5, 'price', 'double', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (5, 'currency', 'string', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (5, 'quantity', 'int', 0, 'Number of items purchased');
INSERT INTO events (id, domain_id, name, event_name, description) VALUES (6, 3, 'cancelled', 'purchase: cancelled', 'User cancelled a purchase');
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (6, 'product_id', 'string', 0, NULL);
INSERT INTO parameters (event_id, name, type, nullable, description) VALUES (6, 'reason', 'string', 1, 'Reason for cancellation');

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

