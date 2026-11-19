export type BookStatus = 'available' | 'issued' | 'reserved' | 'lost' | 'damaged' | 'maintenance';
export type IssueStatus = 'issued' | 'returned' | 'overdue' | 'lost';

export interface BookCategory {
  id: string;
  library_id: string;
  organization_id: string;
  name: string;
  description?: string;
  parent_id?: string;
  created_at: string;
}

export interface Book {
  id: string;
  library_id: string;
  organization_id: string;
  isbn?: string;
  title: string;
  subtitle?: string;
  authors: string[];
  publisher?: string;
  publication_year?: number;
  edition?: string;
  language: string;
  pages?: number;
  category_id?: string;
  tags?: string[];
  description?: string;
  cover_url?: string;
  total_copies: number;
  available_copies: number;
  created_at: string;
  updated_at: string;
  category?: BookCategory;
}

export interface BookCopy {
  id: string;
  book_id: string;
  branch_id: string;
  organization_id: string;
  copy_number: string;
  barcode?: string;
  condition: string;
  status: BookStatus;
  location?: string;
  notes?: string;
  acquired_date?: string;
  acquired_price?: number;
  created_at: string;
  updated_at: string;
  book?: Book;
}

export interface BookIssue {
  id: string;
  copy_id: string;
  member_id: string;
  organization_id: string;
  branch_id: string;
  issue_date: string;
  due_date: string;
  return_date?: string;
  renewal_count: number;
  status: IssueStatus;
  fine_amount: number;
  fine_paid: boolean;
  issued_by?: string;
  returned_to?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
  copy?: BookCopy;
}

export interface CreateBookData {
  isbn?: string;
  title: string;
  subtitle?: string;
  authors: string[];
  publisher?: string;
  publication_year?: number;
  edition?: string;
  language?: string;
  pages?: number;
  category_id?: string;
  tags?: string[];
  description?: string;
  cover_url?: string;
}

export interface IssueBookData {
  copy_id: string;
  member_id: string;
  issue_date: string;
  due_date: string;
  notes?: string;
}

export interface BookFilters {
  search?: string;
  category_id?: string;
  status?: BookStatus;
  language?: string;
  page?: number;
  limit?: number;
}
