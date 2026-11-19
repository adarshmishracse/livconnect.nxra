-- Library Management Platform - Initial Schema
-- Migration: 001_initial_schema.sql

-- Enums
CREATE TYPE user_role AS ENUM ('super_admin', 'library_owner', 'library_admin', 'branch_manager', 'librarian', 'staff', 'member');
CREATE TYPE library_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE member_status AS ENUM ('active', 'inactive', 'suspended', 'expired');
CREATE TYPE membership_status AS ENUM ('active', 'pending', 'expired', 'cancelled', 'paused');
CREATE TYPE seat_status AS ENUM ('available', 'allocated', 'reserved', 'blocked', 'maintenance');
CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'half_day');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded', 'partial');
CREATE TYPE payment_method AS ENUM ('cash', 'online', 'card', 'upi', 'bank_transfer');
CREATE TYPE book_status AS ENUM ('available', 'issued', 'reserved', 'lost', 'damaged', 'maintenance');
CREATE TYPE issue_status AS ENUM ('issued', 'returned', 'overdue', 'lost');
CREATE TYPE shift_day AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');
CREATE TYPE notification_type AS ENUM ('membership_expiry', 'payment_due', 'shift_change', 'attendance', 'announcement', 'system');

-- Organizations (multi-tenant root)
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  logo_url TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT DEFAULT 'IN',
  postal_code TEXT,
  website TEXT,
  status library_status DEFAULT 'active',
  settings JSONB DEFAULT '{}',
  subscription_plan TEXT DEFAULT 'free',
  subscription_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User profiles (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id),
  role user_role NOT NULL DEFAULT 'member',
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  avatar_url TEXT,
  date_of_birth DATE,
  gender TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  id_type TEXT,
  id_number TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Libraries
CREATE TABLE libraries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  logo_url TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  address TEXT NOT NULL,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  total_capacity INTEGER DEFAULT 0,
  total_seats INTEGER DEFAULT 0,
  operating_hours JSONB DEFAULT '{}',
  facilities TEXT[],
  policies TEXT,
  timezone TEXT DEFAULT 'Asia/Kolkata',
  status library_status DEFAULT 'active',
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, code)
);

-- Library Branches
CREATE TABLE library_branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  library_id UUID NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  address TEXT NOT NULL,
  city TEXT,
  total_capacity INTEGER DEFAULT 0,
  total_seats INTEGER DEFAULT 0,
  floor_count INTEGER DEFAULT 1,
  operating_hours JSONB DEFAULT '{}',
  is_main_branch BOOLEAN DEFAULT false,
  status library_status DEFAULT 'active',
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(library_id, code)
);

-- Library Holidays
CREATE TABLE library_holidays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  library_id UUID NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES library_branches(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  name TEXT NOT NULL,
  holiday_date DATE NOT NULL,
  is_recurring BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shift Templates (configurable, unlimited shifts per branch)
CREATE TABLE shift_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES library_branches(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id),
  name TEXT NOT NULL,
  description TEXT,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_overnight BOOLEAN DEFAULT false,
  duration_minutes INTEGER GENERATED ALWAYS AS (
    CASE
      WHEN end_time > start_time THEN EXTRACT(EPOCH FROM (end_time - start_time))/60
      ELSE EXTRACT(EPOCH FROM (end_time + INTERVAL '1 day' - start_time))/60
    END
  )::INTEGER STORED,
  capacity INTEGER NOT NULL DEFAULT 0,
  applicable_days shift_day[] DEFAULT ARRAY['monday','tuesday','wednesday','thursday','friday','saturday','sunday']::shift_day[],
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  color TEXT DEFAULT '#3B82F6',
  base_fee DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shift Schedules (per-day overrides)
CREATE TABLE shift_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_template_id UUID NOT NULL REFERENCES shift_templates(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES library_branches(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  schedule_date DATE NOT NULL,
  actual_start_time TIME,
  actual_end_time TIME,
  override_capacity INTEGER,
  is_cancelled BOOLEAN DEFAULT false,
  cancellation_reason TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(shift_template_id, schedule_date)
);

-- Shift Exceptions
CREATE TABLE shift_exceptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_template_id UUID NOT NULL REFERENCES shift_templates(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES library_branches(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  exception_date DATE NOT NULL,
  exception_type TEXT NOT NULL CHECK (exception_type IN ('cancelled', 'modified', 'extra')),
  modified_start_time TIME,
  modified_end_time TIME,
  modified_capacity INTEGER,
  reason TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seat Sections
CREATE TABLE seat_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES library_branches(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id),
  name TEXT NOT NULL,
  floor INTEGER DEFAULT 1,
  description TEXT,
  capacity INTEGER DEFAULT 0,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seats
CREATE TABLE seats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES library_branches(id) ON DELETE CASCADE,
  section_id UUID REFERENCES seat_sections(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  seat_number TEXT NOT NULL,
  label TEXT,
  floor INTEGER DEFAULT 1,
  row_number TEXT,
  column_number TEXT,
  seat_type TEXT DEFAULT 'standard',
  features TEXT[],
  status seat_status DEFAULT 'available',
  is_active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(branch_id, seat_number)
);

-- Membership Plans
CREATE TABLE membership_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  library_id UUID NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id),
  name TEXT NOT NULL,
  description TEXT,
  duration_days INTEGER NOT NULL,
  duration_type TEXT NOT NULL CHECK (duration_type IN ('daily', 'weekly', 'monthly', 'quarterly', 'half_yearly', 'yearly', 'custom')),
  base_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  security_deposit DECIMAL(10,2) DEFAULT 0,
  includes_all_shifts BOOLEAN DEFAULT false,
  allowed_shifts UUID[],
  max_simultaneous_seats INTEGER DEFAULT 1,
  features JSONB DEFAULT '[]',
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Members
CREATE TABLE members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  library_id UUID NOT NULL REFERENCES libraries(id),
  branch_id UUID NOT NULL REFERENCES library_branches(id),
  membership_number TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT NOT NULL,
  avatar_url TEXT,
  date_of_birth DATE,
  gender TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  id_type TEXT,
  id_number TEXT,
  id_document_url TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  registration_date DATE DEFAULT CURRENT_DATE,
  status member_status DEFAULT 'active',
  notes TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Memberships (shift assignments with dates)
CREATE TABLE memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES membership_plans(id),
  shift_template_id UUID NOT NULL REFERENCES shift_templates(id),
  seat_id UUID REFERENCES seats(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  branch_id UUID NOT NULL REFERENCES library_branches(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  actual_end_date DATE,
  fee_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  security_deposit DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) GENERATED ALWAYS AS (fee_amount - discount_amount + security_deposit) STORED,
  status membership_status DEFAULT 'active',
  renewal_count INTEGER DEFAULT 0,
  previous_membership_id UUID REFERENCES memberships(id),
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT valid_dates CHECK (end_date >= start_date)
);

-- Seat Allocations (per membership, per shift - prevents double booking)
CREATE TABLE seat_allocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  membership_id UUID NOT NULL REFERENCES memberships(id) ON DELETE CASCADE,
  seat_id UUID NOT NULL REFERENCES seats(id),
  shift_template_id UUID NOT NULL REFERENCES shift_templates(id),
  member_id UUID NOT NULL REFERENCES members(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  branch_id UUID NOT NULL REFERENCES library_branches(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  allocated_by UUID REFERENCES profiles(id),
  allocated_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  UNIQUE(seat_id, shift_template_id, start_date, end_date)
);

-- Attendance Records
CREATE TABLE attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES members(id),
  membership_id UUID REFERENCES memberships(id),
  shift_template_id UUID NOT NULL REFERENCES shift_templates(id),
  seat_id UUID REFERENCES seats(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  branch_id UUID NOT NULL REFERENCES library_branches(id),
  attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  status attendance_status DEFAULT 'present',
  check_in_method TEXT DEFAULT 'manual' CHECK (check_in_method IN ('manual', 'qr', 'barcode', 'rfid')),
  check_out_method TEXT,
  is_late BOOLEAN DEFAULT false,
  late_minutes INTEGER,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  updated_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(member_id, shift_template_id, attendance_date)
);

-- Book Categories
CREATE TABLE book_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  library_id UUID NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id),
  name TEXT NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES book_categories(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Books
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  library_id UUID NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id),
  isbn TEXT,
  title TEXT NOT NULL,
  subtitle TEXT,
  authors TEXT[] NOT NULL,
  publisher TEXT,
  publication_year INTEGER,
  edition TEXT,
  language TEXT DEFAULT 'English',
  pages INTEGER,
  category_id UUID REFERENCES book_categories(id),
  tags TEXT[],
  description TEXT,
  cover_url TEXT,
  total_copies INTEGER DEFAULT 1,
  available_copies INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Book Copies
CREATE TABLE book_copies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES library_branches(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  copy_number TEXT NOT NULL,
  barcode TEXT UNIQUE,
  condition TEXT DEFAULT 'good',
  status book_status DEFAULT 'available',
  location TEXT,
  notes TEXT,
  acquired_date DATE,
  acquired_price DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(book_id, copy_number)
);

-- Book Issues
CREATE TABLE book_issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  copy_id UUID NOT NULL REFERENCES book_copies(id),
  member_id UUID NOT NULL REFERENCES members(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  branch_id UUID NOT NULL REFERENCES library_branches(id),
  issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  return_date DATE,
  renewal_count INTEGER DEFAULT 0,
  status issue_status DEFAULT 'issued',
  fine_amount DECIMAL(10,2) DEFAULT 0,
  fine_paid BOOLEAN DEFAULT false,
  issued_by UUID REFERENCES profiles(id),
  returned_to UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment Transactions
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES members(id),
  membership_id UUID REFERENCES memberships(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  branch_id UUID NOT NULL REFERENCES library_branches(id),
  transaction_type TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  net_amount DECIMAL(10,2) GENERATED ALWAYS AS (amount - discount_amount) STORED,
  payment_method payment_method NOT NULL,
  status payment_status DEFAULT 'pending',
  reference_number TEXT UNIQUE,
  gateway_transaction_id TEXT,
  gateway_response JSONB,
  receipt_number TEXT UNIQUE,
  payment_date TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  collected_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staff Members
CREATE TABLE staff_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  library_id UUID NOT NULL REFERENCES libraries(id),
  branch_id UUID REFERENCES library_branches(id),
  employee_id TEXT,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  role user_role NOT NULL,
  designation TEXT,
  department TEXT,
  join_date DATE,
  is_active BOOLEAN DEFAULT true,
  permissions JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staff Shift Assignments
CREATE TABLE staff_shift_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES staff_members(id),
  shift_template_id UUID NOT NULL REFERENCES shift_templates(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification Templates
CREATE TABLE notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  name TEXT NOT NULL,
  type notification_type NOT NULL,
  title_template TEXT NOT NULL,
  body_template TEXT NOT NULL,
  channels TEXT[] DEFAULT ARRAY['push'],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  recipient_id UUID REFERENCES profiles(id),
  member_id UUID REFERENCES members(id),
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  sent_via TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit Logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id),
  user_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_profiles_organization ON profiles(organization_id);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_libraries_organization ON libraries(organization_id);
CREATE INDEX idx_branches_library ON library_branches(library_id);
CREATE INDEX idx_branches_organization ON library_branches(organization_id);
CREATE INDEX idx_shift_templates_branch ON shift_templates(branch_id);
CREATE INDEX idx_shift_templates_organization ON shift_templates(organization_id);
CREATE INDEX idx_seats_branch ON seats(branch_id);
CREATE INDEX idx_seats_section ON seats(section_id);
CREATE INDEX idx_members_organization ON members(organization_id);
CREATE INDEX idx_members_branch ON members(branch_id);
CREATE INDEX idx_members_status ON members(status);
CREATE INDEX idx_members_phone ON members(phone);
CREATE INDEX idx_memberships_member ON memberships(member_id);
CREATE INDEX idx_memberships_shift ON memberships(shift_template_id);
CREATE INDEX idx_memberships_status ON memberships(status);
CREATE INDEX idx_memberships_dates ON memberships(start_date, end_date);
CREATE INDEX idx_memberships_organization ON memberships(organization_id);
CREATE INDEX idx_seat_allocations_seat ON seat_allocations(seat_id);
CREATE INDEX idx_seat_allocations_shift ON seat_allocations(shift_template_id);
CREATE INDEX idx_seat_allocations_membership ON seat_allocations(membership_id);
CREATE INDEX idx_attendance_member ON attendance_records(member_id);
CREATE INDEX idx_attendance_date ON attendance_records(attendance_date);
CREATE INDEX idx_attendance_shift ON attendance_records(shift_template_id);
CREATE INDEX idx_attendance_organization ON attendance_records(organization_id);
CREATE INDEX idx_books_library ON books(library_id);
CREATE INDEX idx_books_isbn ON books(isbn);
CREATE INDEX idx_book_copies_branch ON book_copies(branch_id);
CREATE INDEX idx_book_copies_barcode ON book_copies(barcode);
CREATE INDEX idx_issues_member ON book_issues(member_id);
CREATE INDEX idx_issues_status ON book_issues(status);
CREATE INDEX idx_payments_member ON payment_transactions(member_id);
CREATE INDEX idx_payments_status ON payment_transactions(status);
CREATE INDEX idx_payments_organization ON payment_transactions(organization_id);
CREATE INDEX idx_payments_date ON payment_transactions(payment_date);
CREATE INDEX idx_audit_organization ON audit_logs(organization_id);
CREATE INDEX idx_audit_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_notifications_member ON notifications(member_id);
CREATE INDEX idx_notifications_unread ON notifications(recipient_id, is_read) WHERE is_read = false;

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'organizations','profiles','libraries','library_branches',
    'shift_templates','seats','membership_plans','members',
    'memberships','seat_allocations','attendance_records',
    'books','book_copies','book_issues','payment_transactions','staff_members'
  ]
  LOOP
    EXECUTE format('CREATE TRIGGER trigger_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at()', t);
  END LOOP;
END;
$$;

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'member')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
