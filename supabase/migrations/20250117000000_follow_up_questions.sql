-- Migration: Create follow_up_questions table
-- Purpose: Store generated follow-up questions for users
-- Created: 2025-01-17

-- TODO: Create follow_up_questions table
-- CREATE TABLE follow_up_questions (
--   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--   user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
--   question_text TEXT NOT NULL,
--   relevance_score FLOAT,
--   generated_at TIMESTAMP DEFAULT NOW(),
--   expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days'),
--   is_answered BOOLEAN DEFAULT FALSE,
--   answered_at TIMESTAMP,
--   source_entry_ids UUID[] NOT NULL,
--   created_at TIMESTAMP DEFAULT NOW()
-- );

-- TODO: Create indexes for performance
-- CREATE INDEX idx_follow_up_user_id ON follow_up_questions(user_id);
-- CREATE INDEX idx_follow_up_expires ON follow_up_questions(user_id, expires_at);
-- CREATE INDEX idx_follow_up_answered ON follow_up_questions(user_id, is_answered);

-- TODO: Enable Row Level Security
-- ALTER TABLE follow_up_questions ENABLE ROW LEVEL SECURITY;

-- TODO: Create RLS policies
-- CREATE POLICY "Users can view their own questions"
--   ON follow_up_questions FOR SELECT
--   USING (auth.uid() = user_id);

-- CREATE POLICY "Users can update their own questions"
--   ON follow_up_questions FOR UPDATE
--   USING (auth.uid() = user_id);

-- TODO: Create function to auto-delete expired questions
-- CREATE OR REPLACE FUNCTION delete_expired_questions()
-- RETURNS void AS $$
-- BEGIN
--   DELETE FROM follow_up_questions WHERE expires_at < NOW();
-- END;
-- $$ LANGUAGE plpgsql;

-- Note: Run this migration with:
-- $ supabase db push
-- or apply manually in Supabase SQL Editor
