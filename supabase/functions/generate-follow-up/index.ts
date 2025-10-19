// generate-follow-up/index.ts
//
// Main entry point for the follow-up question generation edge function
// Analyzes user's journal entries using TF-IDF and recommends personalized questions
//
// Deploy: supabase functions deploy generate-follow-up
// Endpoint: https://YOUR_PROJECT.supabase.co/functions/v1/generate-follow-up

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { tokenize, removeStopWords, computeIDF, computeTFIDF, cosineSimilarity } from './tfidf.ts';
import { precomputeQuestionVectors } from './precompute.ts';

// CORS headers for cross-origin requests
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

/**
 * Calculate ISO week number for a given date
 * Returns week number (1-52/53)
 */
function getWeekNumber(date: Date): number {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ============================================================
    // 1. AUTHENTICATE USER
    // ============================================================

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create authenticated Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get current user from JWT
    const { data: { user }, error: userError } = await supabase.auth.getUser();

    if (userError || !user) {
      console.error('Auth error:', userError);
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body for options
    let lookbackDays = 14; // Default: analyze last 2 weeks
    let saveToDatabase = false; // Default: return JSON only
    let mostRecentEntries: number | undefined = undefined; // Optional: analyze N most recent entries

    if (req.method === 'POST') {
      try {
        const body = await req.json();
        lookbackDays = body.lookbackDays || 14;
        saveToDatabase = body.saveToDatabase || false;
        mostRecentEntries = body.mostRecentEntries; // For first-time users
      } catch {
        // If no body or invalid JSON, use defaults
      }
    }

    const modeDesc = mostRecentEntries
      ? `${mostRecentEntries} most recent entries`
      : `lookback: ${lookbackDays} days`;
    console.log(`📝 Generating questions for user: ${user.id} (${modeDesc})`);

    // ============================================================
    // 2. FETCH USER'S RECENT JOURNAL ENTRIES
    // ============================================================

    let entries;
    let entriesError;

    if (mostRecentEntries) {
      // MODE 1: First-time users - fetch N most recent entries (no date filter)
      console.log(`📅 Analyzing ${mostRecentEntries} most recent entries (first-time generation)`);

      const result = await supabase
        .from('entries')
        .select('id, text, created_at')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(mostRecentEntries); // Get exactly N most recent

      entries = result.data;
      entriesError = result.error;
    } else {
      // MODE 2: Regular users - fetch entries within time window
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - lookbackDays);
      const cutoffISO = cutoffDate.toISOString();

      console.log(`📅 Analyzing entries since: ${cutoffISO}`);

      const result = await supabase
        .from('entries')
        .select('id, text, created_at')
        .eq('user_id', user.id)
        .gte('created_at', cutoffISO) // Only entries after cutoff date
        .order('created_at', { ascending: false })
        .limit(20); // Max 20 entries (prevents huge queries)

      entries = result.data;
      entriesError = result.error;
    }

    if (entriesError) {
      console.error('Database error:', entriesError);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch journal entries' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Filter out entries with empty or invalid text
    const validEntries = entries?.filter(e => e.text && e.text.trim().length > 0) || [];

    // Check minimum entry requirement
    if (validEntries.length < 1) {
      console.log(`⚠️ User has only ${validEntries.length} valid entries (need 1)`);
      return new Response(
        JSON.stringify({
          error: 'Need at least 1 journal entry to generate questions',
          currentEntries: validEntries.length,
          required: 1
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`📊 Analyzing ${validEntries.length} entries`);

    // ============================================================
    // 3. COMPUTE TF-IDF VECTOR FOR USER'S ENTRIES (WITH UNIFIED IDF)
    // ============================================================

    // Combine all entry texts
    const combinedText = validEntries.map(e => e.text).join(' ');
    console.log(`📝 Combined text length: ${combinedText.length} characters`);

    // Tokenize and remove stop words
    const entryTokens = removeStopWords(tokenize(combinedText));
    console.log(`🔤 Extracted ${entryTokens.length} meaningful tokens`);

    // Validate that we have tokens to analyze
    if (entryTokens.length === 0) {
      console.log('⚠️ No meaningful tokens found in entries');
      return new Response(
        JSON.stringify({
          error: 'Unable to analyze entries - no meaningful content found',
          details: 'Entries may be too short or contain only common words'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // CRITICAL FIX: Prepare user documents for unified IDF
    const userDocuments = validEntries.map(e => removeStopWords(tokenize(e.text)));

    // ============================================================
    // 4. COMPUTE SIMILARITY WITH PRE-COMPUTED QUESTIONS (UNIFIED IDF)
    // ============================================================

    console.log('🔍 Computing question similarities with unified IDF...');

    // CRITICAL FIX: Pass user documents to get unified IDF across both questions and entries
    const { questions: precomputedQuestions, idf: unifiedIDF } = precomputeQuestionVectors(userDocuments);

    console.log(`📐 Unified IDF vocabulary: ${unifiedIDF.size} unique terms`);

    // Compute entry vector using the SAME unified IDF (critical for accurate comparison)
    const entryVector = computeTFIDF(entryTokens, unifiedIDF);

    // Log top terms for debugging
    const topTerms = Array.from(entryVector.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([word, score]) => `${word}(${score.toFixed(3)})`);
    console.log(`📈 Top entry terms: ${topTerms.join(', ')}`);

    // Compute similarity scores
    const scoredQuestions = precomputedQuestions.map(({ question, vector }) => ({
      question,
      score: cosineSimilarity(entryVector, vector)
    }));

    // Log top scores for debugging
    const topScores = [...scoredQuestions]
      .sort((a, b) => b.score - a.score)
      .slice(0, 3)
      .map(q => `${q.question.text.slice(0, 40)}... (${q.score.toFixed(3)})`);
    console.log(`🎯 Top 3 similarity scores: ${topScores.join(' | ')}`);

    // ============================================================
    // 5. RANK AND SELECT TOP QUESTIONS WITH DIVERSITY
    // ============================================================

    // Sort by similarity score
    scoredQuestions.sort((a, b) => b.score - a.score);

    // Select top 3 with theme diversity
    const selectedQuestions: { text: string; score: number }[] = [];
    const usedThemes = new Set<string>();

    for (const { question, score } of scoredQuestions) {
      // Check for theme overlap
      const hasThemeOverlap = question.themes.some(theme => usedThemes.has(theme));

      // Allow some overlap in first 2, enforce diversity after
      if (hasThemeOverlap && selectedQuestions.length >= 2) {
        continue;
      }

      // Add question
      selectedQuestions.push({
        text: question.text,
        score: score
      });

      // Track themes
      question.themes.forEach(theme => usedThemes.add(theme));

      // Stop at 3 questions
      if (selectedQuestions.length >= 3) break;
    }

    // Ensure we have at least some questions
    if (selectedQuestions.length === 0) {
      console.log('⚠️ No questions matched - returning top scored questions');
      // Fallback: just return top 3 by score without diversity check
      scoredQuestions.slice(0, 3).forEach(({ question, score }) => {
        selectedQuestions.push({
          text: question.text,
          score: score
        });
      });
    }

    // ENGAGEMENT REQUIREMENT: Ensure minimum 3 questions for initial engagement
    if (selectedQuestions.length < 3 && scoredQuestions.length > 0) {
      console.log(`⚠️ Only ${selectedQuestions.length} questions selected - adding more to reach minimum of 3`);

      // Add more questions from scored list until we have 3
      for (const { question, score } of scoredQuestions) {
        // Check if this question is already selected
        const alreadySelected = selectedQuestions.find(q => q.text === question.text);
        if (!alreadySelected) {
          selectedQuestions.push({
            text: question.text,
            score: score
          });
          console.log(`   Added: ${question.text.slice(0, 50)}... (score: ${score.toFixed(3)})`);

          // Stop when we reach 3
          if (selectedQuestions.length >= 3) break;
        }
      }
      console.log(`✅ Reached ${selectedQuestions.length} questions (minimum requirement met)`);
    }

    console.log(`✅ Selected ${selectedQuestions.length} questions`);
    console.log(`   Top scores: ${selectedQuestions.map(q => q.score.toFixed(3)).join(', ')}`);
    console.log(`   Themes: ${Array.from(usedThemes).join(', ')}`);

    // ============================================================
    // 6. SAVE TO DATABASE (OPTIONAL)
    // ============================================================

    if (saveToDatabase) {
      console.log('💾 Saving questions to database...');

      const now = new Date();
      const weekNumber = getWeekNumber(now);
      const year = now.getFullYear();

      // Delete old questions for this week (replace with new ones)
      await supabase
        .from('follow_up_questions')
        .delete()
        .eq('user_id', user.id)
        .eq('week_number', weekNumber)
        .eq('year', year);

      // Insert new questions
      const questionsToInsert = selectedQuestions.map(q => ({
        user_id: user.id,
        question_text: q.text,
        relevance_score: q.score,
        week_number: weekNumber,
        year: year,
        generated_at: now.toISOString()
      }));

      const { error: insertError } = await supabase
        .from('follow_up_questions')
        .insert(questionsToInsert);

      if (insertError) {
        console.error('Failed to save questions:', insertError);
        // Don't fail the request - still return the questions
      } else {
        console.log(`✅ Saved ${selectedQuestions.length} questions to database`);
      }
    }

    // ============================================================
    // 7. RETURN RESPONSE
    // ============================================================

    const response = {
      questions: selectedQuestions,
      metadata: {
        entriesAnalyzed: validEntries.length,
        generatedAt: new Date().toISOString(),
        themesCount: usedThemes.size,
        lookbackDays: lookbackDays,
        savedToDatabase: saveToDatabase
      }
    };

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    // ============================================================
    // ERROR HANDLING
    // ============================================================

    console.error('❌ Unexpected error:', error);

    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});
