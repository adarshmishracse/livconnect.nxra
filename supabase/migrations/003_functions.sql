-- Database Functions for Library Management Platform
-- Migration: 003_functions.sql

-- Check if a seat is available for a shift in a date range
CREATE OR REPLACE FUNCTION check_seat_availability(
  p_seat_id UUID,
  p_shift_template_id UUID,
  p_start_date DATE,
  p_end_date DATE,
  p_exclude_membership_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_conflicts INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_conflicts
  FROM seat_allocations sa
  JOIN memberships m ON sa.membership_id = m.id
  WHERE sa.seat_id = p_seat_id
    AND sa.shift_template_id = p_shift_template_id
    AND sa.is_active = true
    AND m.status IN ('active', 'pending')
    AND (sa.start_date, sa.end_date + INTERVAL '1 day') OVERLAPS (p_start_date, p_end_date + INTERVAL '1 day')
    AND (p_exclude_membership_id IS NULL OR sa.membership_id != p_exclude_membership_id);

  RETURN v_conflicts = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if a shift overlaps with existing shifts in a branch
CREATE OR REPLACE FUNCTION check_shift_time_overlap(
  p_branch_id UUID,
  p_start_time TIME,
  p_end_time TIME,
  p_days shift_day[],
  p_exclude_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_has_overlap BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM shift_templates st
    WHERE st.branch_id = p_branch_id
      AND st.is_active = true
      AND (p_exclude_id IS NULL OR st.id != p_exclude_id)
      AND st.applicable_days && p_days
      AND NOT st.is_overnight
      AND NOT (p_end_time <= p_start_time) -- not overnight check
      AND (p_start_time, p_end_time) OVERLAPS (st.start_time, st.end_time)
  ) INTO v_has_overlap;

  RETURN v_has_overlap;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get real-time shift occupancy for a date
CREATE OR REPLACE FUNCTION get_shift_occupancy(
  p_shift_template_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
  shift_id UUID,
  shift_name TEXT,
  total_capacity INTEGER,
  allocated INTEGER,
  checked_in INTEGER,
  available INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    st.id,
    st.name,
    st.capacity,
    COUNT(DISTINCT CASE WHEN m.status = 'active' AND m.start_date <= p_date AND m.end_date >= p_date THEN m.id END)::INTEGER,
    COUNT(DISTINCT CASE WHEN ar.attendance_date = p_date THEN ar.id END)::INTEGER,
    (st.capacity - COUNT(DISTINCT CASE WHEN m.status = 'active' AND m.start_date <= p_date AND m.end_date >= p_date THEN m.id END)::INTEGER)::INTEGER
  FROM shift_templates st
  LEFT JOIN memberships m ON m.shift_template_id = st.id
  LEFT JOIN attendance_records ar ON ar.shift_template_id = st.id AND ar.attendance_date = p_date
  WHERE st.id = p_shift_template_id
  GROUP BY st.id, st.name, st.capacity;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get branch shift occupancy summary for a date
CREATE OR REPLACE FUNCTION get_branch_shift_summary(
  p_branch_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
  shift_id UUID,
  shift_name TEXT,
  start_time TIME,
  end_time TIME,
  total_capacity INTEGER,
  allocated INTEGER,
  checked_in INTEGER,
  available INTEGER,
  occupancy_pct NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    st.id,
    st.name,
    st.start_time,
    st.end_time,
    st.capacity,
    COUNT(DISTINCT CASE WHEN m.status = 'active' AND m.start_date <= p_date AND m.end_date >= p_date THEN m.id END)::INTEGER,
    COUNT(DISTINCT CASE WHEN ar.attendance_date = p_date THEN ar.id END)::INTEGER,
    GREATEST(0, st.capacity - COUNT(DISTINCT CASE WHEN m.status = 'active' AND m.start_date <= p_date AND m.end_date >= p_date THEN m.id END)::INTEGER)::INTEGER,
    CASE WHEN st.capacity > 0
      THEN ROUND((COUNT(DISTINCT CASE WHEN m.status = 'active' AND m.start_date <= p_date AND m.end_date >= p_date THEN m.id END)::NUMERIC / st.capacity) * 100, 1)
      ELSE 0
    END
  FROM shift_templates st
  LEFT JOIN memberships m ON m.shift_template_id = st.id
  LEFT JOIN attendance_records ar ON ar.shift_template_id = st.id AND ar.attendance_date = p_date
  WHERE st.branch_id = p_branch_id
    AND st.is_active = true
    AND (to_char(p_date, 'FMDay')::TEXT ILIKE ANY(
      SELECT unnest(st.applicable_days)::TEXT
    ) OR true) -- simplified day check
  GROUP BY st.id, st.name, st.start_time, st.end_time, st.capacity
  ORDER BY st.display_order, st.start_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate unique membership number
CREATE OR REPLACE FUNCTION generate_membership_number(p_org_id UUID) RETURNS TEXT AS $$
DECLARE
  v_count INTEGER;
  v_number TEXT;
  v_exists BOOLEAN;
BEGIN
  LOOP
    SELECT COUNT(*) + 1 INTO v_count FROM members WHERE organization_id = p_org_id;
    v_number := 'MEM' || TO_CHAR(NOW(), 'YYYYMM') || LPAD(v_count::TEXT, 4, '0');
    SELECT EXISTS(SELECT 1 FROM members WHERE membership_number = v_number) INTO v_exists;
    EXIT WHEN NOT v_exists;
    v_count := v_count + 1;
  END LOOP;
  RETURN v_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Expire overdue memberships
CREATE OR REPLACE FUNCTION expire_memberships() RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE memberships
  SET status = 'expired', actual_end_date = CURRENT_DATE
  WHERE status = 'active' AND end_date < CURRENT_DATE;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate book fine
CREATE OR REPLACE FUNCTION calculate_book_fine(
  p_due_date DATE,
  p_return_date DATE DEFAULT CURRENT_DATE,
  p_fine_per_day DECIMAL DEFAULT 2.00
) RETURNS DECIMAL AS $$
DECLARE
  v_days INTEGER;
BEGIN
  v_days := GREATEST(0, (p_return_date - p_due_date)::INTEGER);
  RETURN v_days * p_fine_per_day;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Dashboard statistics (org-level or branch-level)
CREATE OR REPLACE FUNCTION get_dashboard_stats(
  p_org_id UUID,
  p_branch_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_members',
      (SELECT COUNT(*) FROM members WHERE organization_id = p_org_id AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'active_members',
      (SELECT COUNT(*) FROM members WHERE organization_id = p_org_id AND status = 'active' AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'inactive_members',
      (SELECT COUNT(*) FROM members WHERE organization_id = p_org_id AND status != 'active' AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'active_memberships',
      (SELECT COUNT(*) FROM memberships WHERE organization_id = p_org_id AND status = 'active' AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'expired_memberships',
      (SELECT COUNT(*) FROM memberships WHERE organization_id = p_org_id AND status = 'expired' AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'total_seats',
      (SELECT COUNT(*) FROM seats WHERE organization_id = p_org_id AND is_active = true AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'today_attendance',
      (SELECT COUNT(*) FROM attendance_records WHERE organization_id = p_org_id AND attendance_date = CURRENT_DATE AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'total_shifts',
      (SELECT COUNT(*) FROM shift_templates WHERE organization_id = p_org_id AND is_active = true AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'today_revenue',
      (SELECT COALESCE(SUM(net_amount), 0) FROM payment_transactions WHERE organization_id = p_org_id AND status = 'completed' AND DATE(payment_date) = CURRENT_DATE AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'monthly_revenue',
      (SELECT COALESCE(SUM(net_amount), 0) FROM payment_transactions WHERE organization_id = p_org_id AND status = 'completed' AND DATE_TRUNC('month', payment_date) = DATE_TRUNC('month', NOW()) AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'pending_payments',
      (SELECT COALESCE(SUM(net_amount), 0) FROM payment_transactions WHERE organization_id = p_org_id AND status = 'pending' AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'expiring_memberships_7days',
      (SELECT COUNT(*) FROM memberships WHERE organization_id = p_org_id AND status = 'active' AND end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 7 AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'total_books',
      (SELECT COUNT(*) FROM books WHERE organization_id = p_org_id),
    'books_issued',
      (SELECT COUNT(*) FROM book_issues WHERE organization_id = p_org_id AND status = 'issued' AND (p_branch_id IS NULL OR branch_id = p_branch_id)),
    'overdue_books',
      (SELECT COUNT(*) FROM book_issues WHERE organization_id = p_org_id AND status = 'issued' AND due_date < CURRENT_DATE AND (p_branch_id IS NULL OR branch_id = p_branch_id))
  ) INTO v_stats;

  RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attendance report for a date range
CREATE OR REPLACE FUNCTION get_attendance_report(
  p_org_id UUID,
  p_branch_id UUID,
  p_start_date DATE,
  p_end_date DATE,
  p_shift_id UUID DEFAULT NULL
) RETURNS TABLE(
  attendance_date DATE,
  shift_id UUID,
  shift_name TEXT,
  total_allocated INTEGER,
  present INTEGER,
  absent INTEGER,
  late INTEGER,
  attendance_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(p_start_date, p_end_date, '1 day'::INTERVAL)::DATE AS d
  ),
  shifts AS (
    SELECT id, name FROM shift_templates
    WHERE branch_id = p_branch_id
      AND is_active = true
      AND (p_shift_id IS NULL OR id = p_shift_id)
  ),
  allocated AS (
    SELECT m.shift_template_id, COUNT(DISTINCT m.id)::INTEGER AS cnt
    FROM memberships m
    WHERE m.branch_id = p_branch_id AND m.status = 'active'
    GROUP BY m.shift_template_id
  )
  SELECT
    ds.d,
    sh.id,
    sh.name,
    COALESCE(al.cnt, 0),
    COUNT(CASE WHEN ar.status = 'present' THEN 1 END)::INTEGER,
    COALESCE(al.cnt, 0) - COUNT(ar.id)::INTEGER,
    COUNT(CASE WHEN ar.is_late THEN 1 END)::INTEGER,
    CASE WHEN COALESCE(al.cnt, 0) > 0
      THEN ROUND((COUNT(ar.id)::NUMERIC / al.cnt) * 100, 1)
      ELSE 0
    END
  FROM date_series ds
  CROSS JOIN shifts sh
  LEFT JOIN allocated al ON al.shift_template_id = sh.id
  LEFT JOIN attendance_records ar ON ar.attendance_date = ds.d
    AND ar.shift_template_id = sh.id
    AND ar.organization_id = p_org_id
  GROUP BY ds.d, sh.id, sh.name, al.cnt
  ORDER BY ds.d, sh.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Revenue report
CREATE OR REPLACE FUNCTION get_revenue_report(
  p_org_id UUID,
  p_branch_id UUID DEFAULT NULL,
  p_start_date DATE DEFAULT CURRENT_DATE - 30,
  p_end_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
  report_date DATE,
  total_collected DECIMAL,
  cash_collected DECIMAL,
  online_collected DECIMAL,
  transaction_count INTEGER,
  pending_amount DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    DATE(pt.payment_date)::DATE,
    SUM(CASE WHEN pt.status = 'completed' THEN pt.net_amount ELSE 0 END),
    SUM(CASE WHEN pt.status = 'completed' AND pt.payment_method = 'cash' THEN pt.net_amount ELSE 0 END),
    SUM(CASE WHEN pt.status = 'completed' AND pt.payment_method IN ('online','upi','card','bank_transfer') THEN pt.net_amount ELSE 0 END),
    COUNT(CASE WHEN pt.status = 'completed' THEN 1 END)::INTEGER,
    SUM(CASE WHEN pt.status = 'pending' THEN pt.net_amount ELSE 0 END)
  FROM payment_transactions pt
  WHERE pt.organization_id = p_org_id
    AND (p_branch_id IS NULL OR pt.branch_id = p_branch_id)
    AND DATE(pt.payment_date) BETWEEN p_start_date AND p_end_date
  GROUP BY DATE(pt.payment_date)
  ORDER BY DATE(pt.payment_date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Allocate seat transactionally (prevents race conditions)
CREATE OR REPLACE FUNCTION allocate_seat(
  p_membership_id UUID,
  p_seat_id UUID,
  p_shift_template_id UUID,
  p_member_id UUID,
  p_org_id UUID,
  p_branch_id UUID,
  p_start_date DATE,
  p_end_date DATE,
  p_allocated_by UUID
) RETURNS UUID AS $$
DECLARE
  v_available BOOLEAN;
  v_allocation_id UUID;
BEGIN
  -- Check availability with row lock
  PERFORM 1 FROM seats WHERE id = p_seat_id FOR UPDATE;

  v_available := check_seat_availability(p_seat_id, p_shift_template_id, p_start_date, p_end_date, p_membership_id);

  IF NOT v_available THEN
    RAISE EXCEPTION 'Seat is not available for the selected shift and date range';
  END IF;

  INSERT INTO seat_allocations (
    membership_id, seat_id, shift_template_id, member_id,
    organization_id, branch_id, start_date, end_date, allocated_by
  ) VALUES (
    p_membership_id, p_seat_id, p_shift_template_id, p_member_id,
    p_org_id, p_branch_id, p_start_date, p_end_date, p_allocated_by
  )
  RETURNING id INTO v_allocation_id;

  -- Update membership seat
  UPDATE memberships SET seat_id = p_seat_id WHERE id = p_membership_id;

  RETURN v_allocation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check in member (prevents duplicate check-ins)
CREATE OR REPLACE FUNCTION member_check_in(
  p_member_id UUID,
  p_shift_template_id UUID,
  p_seat_id UUID,
  p_org_id UUID,
  p_branch_id UUID,
  p_method TEXT DEFAULT 'manual',
  p_created_by UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_exists BOOLEAN;
  v_record_id UUID;
  v_membership_id UUID;
  v_shift_start TIME;
  v_is_late BOOLEAN := false;
  v_late_minutes INTEGER := 0;
BEGIN
  -- Check for duplicate
  SELECT EXISTS(
    SELECT 1 FROM attendance_records
    WHERE member_id = p_member_id
      AND shift_template_id = p_shift_template_id
      AND attendance_date = v_today
      AND check_in_time IS NOT NULL
  ) INTO v_exists;

  IF v_exists THEN
    RAISE EXCEPTION 'Member already checked in for this shift today';
  END IF;

  -- Get active membership
  SELECT id INTO v_membership_id
  FROM memberships
  WHERE member_id = p_member_id
    AND shift_template_id = p_shift_template_id
    AND status = 'active'
    AND start_date <= v_today
    AND end_date >= v_today
  LIMIT 1;

  -- Get shift start time to check lateness
  SELECT start_time INTO v_shift_start FROM shift_templates WHERE id = p_shift_template_id;

  IF v_shift_start IS NOT NULL THEN
    v_late_minutes := GREATEST(0, EXTRACT(EPOCH FROM (NOW()::TIME - v_shift_start))/60)::INTEGER;
    v_is_late := v_late_minutes > 15; -- 15 min grace period
  END IF;

  INSERT INTO attendance_records (
    member_id, membership_id, shift_template_id, seat_id,
    organization_id, branch_id, attendance_date,
    check_in_time, status, check_in_method, is_late, late_minutes, created_by
  ) VALUES (
    p_member_id, v_membership_id, p_shift_template_id, p_seat_id,
    p_org_id, p_branch_id, v_today,
    NOW(), 'present', p_method, v_is_late, v_late_minutes, p_created_by
  )
  ON CONFLICT (member_id, shift_template_id, attendance_date) DO UPDATE
    SET check_in_time = NOW(), check_in_method = p_method,
        is_late = EXCLUDED.is_late, late_minutes = EXCLUDED.late_minutes,
        updated_by = p_created_by, updated_at = NOW()
  RETURNING id INTO v_record_id;

  RETURN v_record_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check out member
CREATE OR REPLACE FUNCTION member_check_out(
  p_member_id UUID,
  p_shift_template_id UUID,
  p_method TEXT DEFAULT 'manual',
  p_updated_by UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
BEGIN
  UPDATE attendance_records
  SET check_out_time = NOW(),
      check_out_method = p_method,
      updated_by = p_updated_by,
      updated_at = NOW()
  WHERE member_id = p_member_id
    AND shift_template_id = p_shift_template_id
    AND attendance_date = v_today
    AND check_out_time IS NULL;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate receipt number
CREATE OR REPLACE FUNCTION generate_receipt_number(p_org_id UUID) RETURNS TEXT AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) + 1 INTO v_count FROM payment_transactions WHERE organization_id = p_org_id;
  RETURN 'RCP' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(v_count::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
