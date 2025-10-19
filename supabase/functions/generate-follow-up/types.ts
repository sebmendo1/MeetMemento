// types.ts
// TypeScript type definitions for the generate-follow-up function

/**
 * Response format for generated questions
 */
export interface QuestionResponse {
  text: string;
  score: number;
}

/**
 * Successful response from generate-follow-up function
 */
export interface GenerateResponse {
  questions: QuestionResponse[];
  metadata?: {
    entriesAnalyzed: number;
    generatedAt: string;
    themesCount: number;
  };
}

/**
 * Error response format
 */
export interface ErrorResponse {
  error: string;
  details?: string;
  currentEntries?: number;
  required?: number;
}

/**
 * Database entry type (from journal_entries table)
 */
export interface JournalEntry {
  id: string;
  user_id: string;
  text: string;
  title: string;
  created_at: string;
  updated_at: string;
  is_follow_up: boolean;
}
