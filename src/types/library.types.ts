export type LibraryStatus = 'active' | 'inactive' | 'suspended';

export interface Organization {
  id: string;
  name: string;
  slug: string;
  logo_url?: string;
  contact_email?: string;
  contact_phone?: string;
  address?: string;
  city?: string;
  state?: string;
  country: string;
  postal_code?: string;
  website?: string;
  status: LibraryStatus;
  settings: Record<string, unknown>;
  subscription_plan: string;
  subscription_expires_at?: string;
  created_at: string;
  updated_at: string;
}

export interface Library {
  id: string;
  organization_id: string;
  name: string;
  code: string;
  description?: string;
  logo_url?: string;
  contact_email?: string;
  contact_phone?: string;
  address: string;
  city?: string;
  state?: string;
  postal_code?: string;
  latitude?: number;
  longitude?: number;
  total_capacity: number;
  total_seats: number;
  operating_hours: Record<string, unknown>;
  facilities?: string[];
  policies?: string;
  timezone: string;
  status: LibraryStatus;
  settings: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface LibraryBranch {
  id: string;
  library_id: string;
  organization_id: string;
  name: string;
  code: string;
  description?: string;
  contact_email?: string;
  contact_phone?: string;
  address: string;
  city?: string;
  total_capacity: number;
  total_seats: number;
  floor_count: number;
  operating_hours: Record<string, unknown>;
  is_main_branch: boolean;
  status: LibraryStatus;
  settings: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface LibraryHoliday {
  id: string;
  library_id: string;
  branch_id?: string;
  organization_id: string;
  name: string;
  holiday_date: string;
  is_recurring: boolean;
  notes?: string;
  created_at: string;
}

export interface CreateLibraryData {
  name: string;
  code: string;
  description?: string;
  contact_email?: string;
  contact_phone?: string;
  address: string;
  city?: string;
  state?: string;
  postal_code?: string;
  timezone?: string;
  facilities?: string[];
  policies?: string;
}

export interface CreateBranchData {
  library_id: string;
  name: string;
  code: string;
  description?: string;
  contact_email?: string;
  contact_phone?: string;
  address: string;
  city?: string;
  total_capacity?: number;
  floor_count?: number;
  is_main_branch?: boolean;
}
