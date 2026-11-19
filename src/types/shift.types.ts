export type ShiftDay = 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday';

export interface ShiftTemplate {
  id: string;
  branch_id: string;
  organization_id: string;
  name: string;
  description?: string;
  start_time: string;
  end_time: string;
  is_overnight: boolean;
  duration_minutes: number;
  capacity: number;
  applicable_days: ShiftDay[];
  is_active: boolean;
  display_order: number;
  color: string;
  base_fee: number;
  created_at: string;
  updated_at: string;
}

export interface ShiftSchedule {
  id: string;
  shift_template_id: string;
  branch_id: string;
  organization_id: string;
  schedule_date: string;
  actual_start_time?: string;
  actual_end_time?: string;
  override_capacity?: number;
  is_cancelled: boolean;
  cancellation_reason?: string;
  notes?: string;
  created_at: string;
}

export interface ShiftException {
  id: string;
  shift_template_id: string;
  branch_id: string;
  organization_id: string;
  exception_date: string;
  exception_type: 'cancelled' | 'modified' | 'extra';
  modified_start_time?: string;
  modified_end_time?: string;
  modified_capacity?: number;
  reason?: string;
  created_by?: string;
  created_at: string;
}

export interface ShiftOccupancy {
  shift_id: string;
  shift_name: string;
  total_capacity: number;
  allocated: number;
  checked_in: number;
  available: number;
  occupancy_pct?: number;
}

export interface CreateShiftData {
  branch_id: string;
  name: string;
  description?: string;
  start_time: string;
  end_time: string;
  is_overnight?: boolean;
  capacity: number;
  applicable_days: ShiftDay[];
  color?: string;
  base_fee?: number;
  display_order?: number;
}

export interface UpdateShiftData extends Partial<CreateShiftData> {
  is_active?: boolean;
}

export const ALL_DAYS: ShiftDay[] = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

export const DAY_LABELS: Record<ShiftDay, string> = {
  monday: 'Mon',
  tuesday: 'Tue',
  wednesday: 'Wed',
  thursday: 'Thu',
  friday: 'Fri',
  saturday: 'Sat',
  sunday: 'Sun',
};
