import { z } from 'zod';

export const TransactionSchema = z.object({
  id: z.string().uuid(),
  description: z.string().min(1),
  amount: z.number(),
  type: z.enum(['income', 'expense']),
  category: z.string(),
  date: z.string().datetime(),
});

export type Transaction = z.infer<typeof TransactionSchema>;
