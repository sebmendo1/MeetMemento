// weekly-question-generator/index.ts
//
// Cron job that runs every week to generate follow-up questions for all active users
//
// Schedule: Every Sunday at 9:00 PM UTC
// Setup: supabase functions deploy weekly-question-generator
// Trigger: Supabase Dashboard → Edge Functions → weekly-question-generator → Settings → Cron

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  console.log('🚀 Weekly Question Generator started at', new Date().toISOString());

  try {
    // ============================================================
    // 1. VERIFY CRON AUTHORIZATION
    // ============================================================

    const authHeader = req.headers.get('Authorization');

    // Check for cron secret (set in Supabase Dashboard)
    const cronSecret = Deno.env.get('CRON_SECRET');
    const providedSecret = req.headers.get('x-cron-secret');

    if (cronSecret && providedSecret !== cronSecret) {
      console.error('❌ Unauthorized cron request');
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401 }
      );
    }

    // ============================================================
    // 2. CREATE ADMIN SUPABASE CLIENT
    // ============================================================

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', // Service role for admin access
    );

    // ============================================================
    // 3. FETCH ACTIVE USERS
    // ============================================================

    // Define "active" as users who have written at least 1 entry in the last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    console.log('📊 Fetching active users...');

    const { data: activeUsers, error: usersError } = await supabase
      .from('entries')
      .select('user_id')
      .gte('created_at', thirtyDaysAgo.toISOString())
      .order('created_at', { ascending: false });

    if (usersError) {
      console.error('Database error:', usersError);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch active users' }),
        { status: 500 }
      );
    }

    // Get unique user IDs
    const uniqueUserIds = [...new Set(activeUsers?.map(e => e.user_id) || [])];
    console.log(`✅ Found ${uniqueUserIds.length} active users`);

    if (uniqueUserIds.length === 0) {
      console.log('ℹ️ No active users to process');
      return new Response(
        JSON.stringify({
          message: 'No active users found',
          processed: 0
        }),
        { status: 200 }
      );
    }

    // ============================================================
    // 4. GENERATE QUESTIONS FOR EACH USER
    // ============================================================

    const results = {
      total: uniqueUserIds.length,
      successful: 0,
      failed: 0,
      skipped: 0,
      errors: [] as string[]
    };

    for (const userId of uniqueUserIds) {
      try {
        console.log(`🔄 Processing user: ${userId}`);

        // ============================================================
        // ENGAGEMENT GATE: Check if user has answered at least 3 questions
        // ============================================================

        const { data: completedQuestions, error: completionError } = await supabase
          .from('follow_up_questions')
          .select('id', { count: 'exact' })
          .eq('user_id', userId)
          .eq('is_completed', true);

        if (completionError) {
          console.error(`Failed to check completion status for ${userId}:`, completionError);
          // Continue anyway - don't block on this check
        }

        const completionCount = completedQuestions?.length || 0;

        // Skip if user hasn't engaged enough (< 3 questions answered)
        if (completionCount < 3) {
          console.log(`⏭️ Skipping user ${userId}: Only ${completionCount}/3 questions answered - needs more engagement`);
          results.skipped++;
          continue;
        }

        console.log(`✅ User ${userId} has answered ${completionCount} questions - generating new ones`);

        // Get user's auth token (needed to call generate-follow-up function)
        const { data: { user }, error: userError } = await supabase.auth.admin.getUserById(userId);

        if (userError || !user) {
          console.error(`Failed to get user ${userId}:`, userError);
          results.failed++;
          results.errors.push(`User ${userId}: ${userError?.message || 'User not found'}`);
          continue;
        }

        // Create a session for this user
        const { data: sessionData, error: sessionError } = await supabase.auth.admin.createSession({
          user_id: userId,
          options: {
            ttl: 3600 // 1 hour session
          }
        });

        if (sessionError || !sessionData.session) {
          console.error(`Failed to create session for ${userId}:`, sessionError);
          results.failed++;
          results.errors.push(`User ${userId}: Failed to create session`);
          continue;
        }

        // Call generate-follow-up function with the user's token
        const functionUrl = `${Deno.env.get('SUPABASE_URL')}/functions/v1/generate-follow-up`;

        const response = await fetch(functionUrl, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${sessionData.session.access_token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            lookbackDays: 14, // Analyze last 2 weeks
            saveToDatabase: true // Save to database
          })
        });

        if (!response.ok) {
          const errorText = await response.text();
          console.error(`Failed to generate questions for ${userId}:`, errorText);
          results.failed++;
          results.errors.push(`User ${userId}: ${response.status} - ${errorText}`);
          continue;
        }

        const result = await response.json();
        console.log(`✅ Generated ${result.questions?.length || 0} questions for user ${userId}`);
        results.successful++;

      } catch (error) {
        console.error(`Error processing user ${userId}:`, error);
        results.failed++;
        results.errors.push(`User ${userId}: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    // ============================================================
    // 5. RETURN SUMMARY
    // ============================================================

    console.log('🎉 Weekly question generation complete!');
    console.log(`   Total users: ${results.total}`);
    console.log(`   Successful: ${results.successful}`);
    console.log(`   Skipped (need engagement): ${results.skipped}`);
    console.log(`   Failed: ${results.failed}`);

    return new Response(
      JSON.stringify({
        message: 'Weekly question generation complete',
        timestamp: new Date().toISOString(),
        results: results
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('❌ Unexpected error:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { status: 500 }
    );
  }
});
