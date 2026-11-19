export type MemberStatus = 'active' | 'inactive' | 'suspended' | 'expired';
export type MembershipStatus = 'active' | 'pending' | 'expired' | 'cancelled' | 'paused';
export type SeatStatus = 'available' | 'allocated' | 'reserved' | 'blocked' | 'maintenance';
export type AttendanceStatus = 'present' | 'absent' | 'late' | 'half_day';

export interface Member {
  id: string;
  profile_id?: string;
  organization_id: string;
  library_id: string;
  branch_id: string;
  membership_number: string;
  full_name: string;
  email?: string;
  phone: string;
  avatar_url?: string;
  date_of_birth?: string;
  gender?: string;
  address?: string;
  city?: string;
  state?: string;
  postal_code?: string;
  id_type?: string;
  id_number?: string;
  id_document_url?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
  registration_date: string;
  status: MemberStatus;
  notes?: string;
  tags?: string[];
  created_at: string;
  updated_at: string;
}

export interface MembershipPlan {
  id: string;
  library_id: string;
  organization_id: string;
  name: string;
  description?: string;
  duration_days: number;
  duration_type: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'half_yearly' | 'yearly' | 'custom';
  base_fee: number;
  security_deposit: number;
  includes_all_shifts: boolean;
  allowed_shifts?: string[];
  max_simultaneous_seats: number;
  features: unknown[];
  is_active: boolean;
  display_order: number;
  created_at: string;
  updated_at: string;
}

export interface Membership {
  id: string;
  member_id: string;
  plan_id?: string;
  shift_template_id: string;
  seat_id?: string;
  organization_id: string;
  branch_id: string;
  start_date: string;
  end_date: string;
  actual_end_date?: string;
  fee_amount: number;
  discount_amount: number;
  security_deposit: number;
  total_amount: number;
  status: MembershipStatus;
  renewal_count: number;
  previous_membership_id?: string;
  notes?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
}

export interface Seat {
  id: string;
  branch_id: string;
  section_id?: string;
  organization_id: string;
  seat_number: string;
  label?: string;
  floor: number;
  row_number?: string;
  column_number?: string;
  seat_type: string;
  features?: string[];
  status: SeatStatus;
  is_active: boolean;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface SeatSection {
  id: string;
  branch_id: string;
  organization_id: string;
  name: string;
  floor: number;
  description?: string;
  capacity: number;
  display_order: number;
  created_at: string;
}

export interface SeatAllocation {
  id: string;
  membership_id: string;
  seat_id: string;
  shift_template_id: string;
  member_id: string;
  organization_id: string;
  branch_id: string;
  start_date: string;
  end_date: string;
  is_active: boolean;
  allocated_by?: string;
  allocated_at: string;
  notes?: string;
}

export interface AttendanceRecord {
  id: string;
  member_id: string;
  membership_id?: string;
  shift_template_id: string;
  seat_id?: string;
  organization_id: string;
  branch_id: string;
  attendance_date: string;
  check_in_time?: string;
  check_out_time?: string;
  status: AttendanceStatus;
  check_in_method: 'manual' | 'qr' | 'barcode' | 'rfid';
  check_out_method?: string;
  is_late: boolean;
  late_minutes?: number;
  notes?: string;
  created_by?: string;
  updated_by?: string;
  created_at: string;
  updated_at: string;
}

export interface CreateMemberData {
  full_name: string;
  phone: string;
  email?: string;
  date_of_birth?: string;
  gender?: string;
  address?: string;
  city?: string;
  state?: string;
  postal_code?: string;
  id_type?: string;
  id_number?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
  notes?: string;
  tags?: string[];
}

export interface CreateMembershipData {
  member_id: string;
  shift_template_id: string;
  plan_id?: string;
  seat_id?: string;
  start_date: string;
  end_date: string;
  fee_amount: number;
  discount_amount?: number;
  security_deposit?: number;
  notes?: string;
}

export interface MemberFilters {
  search?: string;
  status?: MemberStatus;
  branch_id?: string;
  shift_id?: string;
  page?: number;
  limit?: number;
}
