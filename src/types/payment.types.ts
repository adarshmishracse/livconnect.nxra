export type PaymentStatus = 'pending' | 'completed' | 'failed' | 'refunded' | 'partial';
export type PaymentMethod = 'cash' | 'online' | 'card' | 'upi' | 'bank_transfer';

export interface PaymentTransaction {
  id: string;
  member_id: string;
  membership_id?: string;
  organization_id: string;
  branch_id: string;
  transaction_type: string;
  amount: number;
  discount_amount: number;
  net_amount: number;
  payment_method: PaymentMethod;
  status: PaymentStatus;
  reference_number?: string;
  gateway_transaction_id?: string;
  gateway_response?: Record<string, unknown>;
  receipt_number?: string;
  payment_date: string;
  notes?: string;
  collected_by?: string;
  created_at: string;
  updated_at: string;
}

export interface CollectPaymentData {
  member_id: string;
  membership_id?: string;
  transaction_type: string;
  amount: number;
  discount_amount?: number;
  payment_method: PaymentMethod;
  notes?: string;
  reference_number?: string;
}

export interface DashboardStats {
  total_members: number;
  active_members: number;
  inactive_members: number;
  active_memberships: number;
  expired_memberships: number;
  total_seats: number;
  today_attendance: number;
  total_shifts: number;
  today_revenue: number;
  monthly_revenue: number;
  pending_payments: number;
  expiring_memberships_7days: number;
  total_books: number;
  books_issued: number;
  overdue_books: number;
}

export interface RevenueReportRow {
  report_date: string;
  total_collected: number;
  cash_collected: number;
  online_collected: number;
  transaction_count: number;
  pending_amount: number;
}
