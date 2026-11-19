-- RLS Policies for Library Management Platform
-- Migration: 002_rls_policies.sql

-- Enable RLS on all tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE libraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_exceptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE seat_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE seat_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_copies ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_shift_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper functions (security definer - called with elevated privilege)
CREATE OR REPLACE FUNCTION auth_user_org_id() RETURNS UUID AS $$
  SELECT organization_id FROM profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION auth_user_role() RETURNS user_role AS $$
  SELECT role FROM profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_admin_role() RETURNS BOOLEAN AS $$
  SELECT role IN ('super_admin','library_owner','library_admin','branch_manager')
  FROM profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_staff_role() RETURNS BOOLEAN AS $$
  SELECT role IN ('super_admin','library_owner','library_admin','branch_manager','librarian','staff')
  FROM profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Profiles
CREATE POLICY profiles_select ON profiles FOR SELECT USING (
  id = auth.uid() OR organization_id = auth_user_org_id()
);
CREATE POLICY profiles_insert ON profiles FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY profiles_update ON profiles FOR UPDATE USING (
  id = auth.uid() OR
  (organization_id = auth_user_org_id() AND auth_user_role() IN ('super_admin','library_owner','library_admin'))
);

-- Organizations
CREATE POLICY orgs_select ON organizations FOR SELECT USING (
  id = auth_user_org_id() OR auth_user_role() = 'super_admin'
);
CREATE POLICY orgs_insert ON organizations FOR INSERT WITH CHECK (true); -- Allow insert during registration
CREATE POLICY orgs_update ON organizations FOR UPDATE USING (
  id = auth_user_org_id() AND auth_user_role() IN ('super_admin','library_owner')
);

-- Libraries
CREATE POLICY libraries_select ON libraries FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY libraries_insert ON libraries FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);
CREATE POLICY libraries_update ON libraries FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);
CREATE POLICY libraries_delete ON libraries FOR DELETE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner')
);

-- Library Branches
CREATE POLICY branches_select ON library_branches FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY branches_insert ON library_branches FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);
CREATE POLICY branches_update ON library_branches FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager')
);
CREATE POLICY branches_delete ON library_branches FOR DELETE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner')
);

-- Library Holidays
CREATE POLICY holidays_all ON library_holidays FOR ALL USING (organization_id = auth_user_org_id());

-- Shift Templates
CREATE POLICY shifts_select ON shift_templates FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY shifts_insert ON shift_templates FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager')
);
CREATE POLICY shifts_update ON shift_templates FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager')
);
CREATE POLICY shifts_delete ON shift_templates FOR DELETE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);

-- Shift Schedules & Exceptions
CREATE POLICY shift_sched_all ON shift_schedules FOR ALL USING (organization_id = auth_user_org_id());
CREATE POLICY shift_except_all ON shift_exceptions FOR ALL USING (organization_id = auth_user_org_id());

-- Seat Sections
CREATE POLICY sections_all ON seat_sections FOR ALL USING (organization_id = auth_user_org_id());

-- Seats
CREATE POLICY seats_select ON seats FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY seats_insert ON seats FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager')
);
CREATE POLICY seats_update ON seats FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager','librarian')
);
CREATE POLICY seats_delete ON seats FOR DELETE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);

-- Membership Plans
CREATE POLICY plans_select ON membership_plans FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY plans_insert ON membership_plans FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);
CREATE POLICY plans_update ON membership_plans FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);
CREATE POLICY plans_delete ON membership_plans FOR DELETE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner')
);

-- Members
CREATE POLICY members_select ON members FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY members_insert ON members FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND is_staff_role()
);
CREATE POLICY members_update ON members FOR UPDATE USING (
  organization_id = auth_user_org_id() AND is_staff_role()
);
CREATE POLICY members_delete ON members FOR DELETE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);

-- Memberships
CREATE POLICY memberships_select ON memberships FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY memberships_insert ON memberships FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND is_staff_role()
);
CREATE POLICY memberships_update ON memberships FOR UPDATE USING (
  organization_id = auth_user_org_id() AND is_staff_role()
);
CREATE POLICY memberships_delete ON memberships FOR DELETE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);

-- Seat Allocations
CREATE POLICY seat_alloc_select ON seat_allocations FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY seat_alloc_insert ON seat_allocations FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND is_staff_role()
);
CREATE POLICY seat_alloc_update ON seat_allocations FOR UPDATE USING (
  organization_id = auth_user_org_id() AND is_staff_role()
);
CREATE POLICY seat_alloc_delete ON seat_allocations FOR DELETE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager','librarian')
);

-- Attendance
CREATE POLICY attendance_select ON attendance_records FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY attendance_insert ON attendance_records FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND is_staff_role()
);
CREATE POLICY attendance_update ON attendance_records FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager','librarian')
);

-- Books
CREATE POLICY books_select ON books FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY books_insert ON books FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager','librarian')
);
CREATE POLICY books_update ON books FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager','librarian')
);
CREATE POLICY books_delete ON books FOR DELETE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);

-- Book Categories
CREATE POLICY categories_all ON book_categories FOR ALL USING (organization_id = auth_user_org_id());

-- Book Copies
CREATE POLICY book_copies_select ON book_copies FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY book_copies_write ON book_copies FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager','librarian')
);
CREATE POLICY book_copies_update ON book_copies FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin','branch_manager','librarian')
);

-- Book Issues
CREATE POLICY issues_select ON book_issues FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY issues_insert ON book_issues FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND is_staff_role()
);
CREATE POLICY issues_update ON book_issues FOR UPDATE USING (
  organization_id = auth_user_org_id() AND is_staff_role()
);

-- Payments
CREATE POLICY payments_select ON payment_transactions FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY payments_insert ON payment_transactions FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND is_staff_role()
);
CREATE POLICY payments_update ON payment_transactions FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);

-- Staff
CREATE POLICY staff_select ON staff_members FOR SELECT USING (organization_id = auth_user_org_id());
CREATE POLICY staff_insert ON staff_members FOR INSERT WITH CHECK (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);
CREATE POLICY staff_update ON staff_members FOR UPDATE USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);

-- Staff Shift Assignments
CREATE POLICY staff_shifts_all ON staff_shift_assignments FOR ALL USING (organization_id = auth_user_org_id());

-- Notifications
CREATE POLICY notif_select ON notifications FOR SELECT USING (
  organization_id = auth_user_org_id() AND
  (recipient_id = auth.uid() OR auth_user_role() IN ('super_admin','library_owner','library_admin'))
);
CREATE POLICY notif_insert ON notifications FOR INSERT WITH CHECK (organization_id = auth_user_org_id());
CREATE POLICY notif_update ON notifications FOR UPDATE USING (recipient_id = auth.uid());

-- Notification Templates
CREATE POLICY notif_templates_all ON notification_templates FOR ALL USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);

-- Audit Logs
CREATE POLICY audit_select ON audit_logs FOR SELECT USING (
  organization_id = auth_user_org_id() AND
  auth_user_role() IN ('super_admin','library_owner','library_admin')
);
CREATE POLICY audit_insert ON audit_logs FOR INSERT WITH CHECK (organization_id = auth_user_org_id());
