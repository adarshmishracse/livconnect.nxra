export type UserRole =
  | 'super_admin'
  | 'library_owner'
  | 'library_admin'
  | 'branch_manager'
  | 'librarian'
  | 'staff'
  | 'member';

export interface Profile {
  id: string;
  organization_id: string | null;
  role: UserRole;
  full_name: string;
  email?: string;
  phone?: string;
  avatar_url?: string;
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
  is_active: boolean;
  last_login_at?: string;
  created_at: string;
  updated_at: string;
}

export interface AuthCredentials {
  email: string;
  password: string;
}

export interface RegisterData extends AuthCredentials {
  full_name: string;
  phone?: string;
  role?: UserRole;
  organization_name?: string;
}

export interface UpdateProfileData {
  full_name?: string;
  phone?: string;
  avatar_url?: string;
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
}
