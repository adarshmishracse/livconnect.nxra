-- Seed Data for Development
-- Migration: 004_seed_data.sql
-- NOTE: This seed data is for development/testing only.
-- Do not run in production without modifying credentials.

-- Insert notification templates
-- These will be inserted per-organization on first setup via the app.
-- This is a reference template only.

/*
Example data inserted via app setup:

INSERT INTO notification_templates (organization_id, name, type, title_template, body_template, channels) VALUES
  ('{org_id}', 'Membership Expiry (7 days)', 'membership_expiry', 'Membership Expiring Soon', 'Dear {{member_name}}, your membership expires on {{expiry_date}}. Please renew to continue.', ARRAY['push','email']),
  ('{org_id}', 'Membership Expiry (1 day)', 'membership_expiry', 'Membership Expires Tomorrow', 'Dear {{member_name}}, your membership expires tomorrow. Renew today!', ARRAY['push','sms']),
  ('{org_id}', 'Payment Confirmation', 'payment_due', 'Payment Received', 'Receipt #{{receipt_no}}: Payment of ₹{{amount}} received for {{plan_name}}.', ARRAY['push','email']),
  ('{org_id}', 'Attendance Check-in', 'attendance', 'Check-in Confirmed', 'You checked in at {{time}} for {{shift_name}}.', ARRAY['push']);
*/

-- This migration intentionally contains no data rows
-- Data is created through the app onboarding flow
SELECT 1; -- No-op to make migration valid
