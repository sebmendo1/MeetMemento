// generate-follow-up/types.ts
//
// TypeScript type definitions for the generate-follow-up function
//
// Purpose:
// - Define interfaces for request/response
// - Define database table types
// - Ensure type safety across modules

// TODO: Define Entry interface (from Supabase database)
// export interface Entry {
//   id: string
//   user_id: string
//   text: string
//   title: string
//   created_at: string
//   is_follow_up: boolean
// }

// TODO: Define FollowUpQuestion interface (from Supabase database)
// export interface FollowUpQuestion {
//   id: string
//   user_id: string
//   question_text: string
//   relevance_score: number
//   generated_at: string
//   expires_at: string
//   is_answered: boolean
//   answered_at: string | null
//   source_entry_ids: string[]
// }

// TODO: Define function request/response types
// export interface GenerateQuestionsRequest {
//   // Currently no request body needed (user ID from JWT)
// }

// export interface GenerateQuestionsResponse {
//   questions: FollowUpQuestion[]
//   metadata?: {
//     entriesAnalyzed: number
//     generatedAt: string
//     expiresAt: string
//   }
// }

// TODO: Define error response type
// export interface ErrorResponse {
//   error: string
//   details?: string
// }
