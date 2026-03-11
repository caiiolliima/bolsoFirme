export type { Transaction } from './schemas';

export interface ApiResponse<T> {
  data: T;
  message?: string;
  error?: string;
}
