// test.ts
//
// Standalone test script for TF-IDF follow-up question generation
// Run with: deno run --allow-read test.ts
//
// Purpose: Test the TF-IDF logic locally before deploying to edge function
// This is like running a CS50 check50 - verify logic works before submission

import { tokenize, removeStopWords, computeTF, computeIDF, computeTFIDF, cosineSimilarity } from './tfidf.ts';
import { questionBank } from './question-bank.ts';
import { precomputeQuestionVectors } from './precompute.ts';

// Sample journal entries for testing
const sampleEntries = [
  {
    id: '1',
    text: 'Today was really stressful at work. I had three deadlines and felt completely overwhelmed. I need to learn better time management and set boundaries with my team.',
    created_at: '2025-01-15'
  },
  {
    id: '2',
    text: 'Feeling anxious about the upcoming presentation. I always get nervous speaking in front of people. Maybe I should practice more or try some breathing exercises.',
    created_at: '2025-01-16'
  },
  {
    id: '3',
    text: 'Spent quality time with family today. It reminded me how important it is to disconnect from work and be present. Grateful for these moments of peace.',
    created_at: '2025-01-17'
  }
];

console.log('🧪 Testing TF-IDF Follow-Up Question Generation\n');
console.log('=' .repeat(60));

// Test 1: Tokenization
console.log('\n📝 Test 1: Tokenization');
console.log('-'.repeat(60));
const testText = 'Hello World! This is a test.';
const tokens = tokenize(testText);
console.log('Input:', testText);
console.log('Tokens:', tokens);
console.log('✅ Expected: lowercase words without punctuation');

// Test 2: Stop Word Removal
console.log('\n📝 Test 2: Stop Word Removal');
console.log('-'.repeat(60));
const withStopWords = ['the', 'quick', 'brown', 'fox', 'is', 'very', 'fast'];
const withoutStopWords = removeStopWords(withStopWords);
console.log('Before:', withStopWords);
console.log('After:', withoutStopWords);
console.log('✅ Expected: "quick", "brown", "fox", "fast" (removed: the, is, very)');

// Test 3: Term Frequency
console.log('\n📝 Test 3: Term Frequency (TF)');
console.log('-'.repeat(60));
const sampleTokens = ['stress', 'work', 'stress', 'deadline', 'overwhelm'];
const tf = computeTF(sampleTokens);
console.log('Tokens:', sampleTokens);
console.log('TF scores:');
tf.forEach((score, word) => {
  console.log(`  ${word}: ${score.toFixed(3)} (appears ${sampleTokens.filter(t => t === word).length} times)`);
});
console.log('✅ Expected: "stress" has highest TF (appears twice)');

// Test 4: IDF Computation
console.log('\n📝 Test 4: Inverse Document Frequency (IDF)');
console.log('-'.repeat(60));
const documents = [
  ['stress', 'work', 'deadline'],
  ['family', 'grateful', 'peace'],
  ['stress', 'anxious', 'nervous']
];
const idf = computeIDF(documents);
console.log('Documents:', documents);
console.log('IDF scores:');
idf.forEach((score, word) => {
  const docCount = documents.filter(doc => doc.includes(word)).length;
  console.log(`  ${word}: ${score.toFixed(3)} (appears in ${docCount}/${documents.length} docs)`);
});
console.log('✅ Expected: "stress" lower IDF (common), "family" higher IDF (rare)');

// Test 5: Full TF-IDF Vector
console.log('\n📝 Test 5: TF-IDF Vector Computation');
console.log('-'.repeat(60));
const entryText = sampleEntries[0].text;
const entryTokens = removeStopWords(tokenize(entryText));
const allDocs = sampleEntries.map(e => removeStopWords(tokenize(e.text)));
const docIDF = computeIDF(allDocs);
const tfidfVector = computeTFIDF(entryTokens, docIDF);

console.log('Entry:', entryText.slice(0, 80) + '...');
console.log('Top 10 TF-IDF terms:');
const sortedTerms = Array.from(tfidfVector.entries())
  .sort((a, b) => b[1] - a[1])
  .slice(0, 10);
sortedTerms.forEach(([word, score]) => {
  console.log(`  ${word}: ${score.toFixed(4)}`);
});
console.log('✅ Expected: "stress", "work", "overwhelm" have high scores');

// Test 6: Cosine Similarity
console.log('\n📝 Test 6: Cosine Similarity');
console.log('-'.repeat(60));
const vec1 = new Map([['stress', 0.8], ['work', 0.6], ['deadline', 0.5]]);
const vec2 = new Map([['stress', 0.7], ['anxious', 0.6], ['nervous', 0.4]]);
const vec3 = new Map([['family', 0.9], ['grateful', 0.8], ['peace', 0.7]]);

const similarity1_2 = cosineSimilarity(vec1, vec2);
const similarity1_3 = cosineSimilarity(vec1, vec3);

console.log('Vector 1 (work/stress):', Array.from(vec1.entries()));
console.log('Vector 2 (stress/anxiety):', Array.from(vec2.entries()));
console.log('Vector 3 (family/peace):', Array.from(vec3.entries()));
console.log('');
console.log(`Similarity (Vec1 ↔ Vec2): ${similarity1_2.toFixed(3)} - Both about stress`);
console.log(`Similarity (Vec1 ↔ Vec3): ${similarity1_3.toFixed(3)} - Different topics`);
console.log('✅ Expected: Vec1-Vec2 > Vec1-Vec3 (work/stress more similar than work/family)');

// Test 7: Question Matching
console.log('\n📝 Test 7: Question Matching with Real Data');
console.log('-'.repeat(60));

// Combine all entry texts
const combinedText = sampleEntries.map(e => e.text).join(' ');
const userTokens = removeStopWords(tokenize(combinedText));
const userVector = computeTFIDF(userTokens, docIDF);

console.log('User entries combined length:', combinedText.length, 'characters');
console.log('Unique tokens:', userTokens.length);

// Pre-compute question vectors
console.log('\nPre-computing question vectors...');
const precomputedQuestions = precomputeQuestionVectors();
console.log(`✅ Pre-computed ${precomputedQuestions.length} question vectors`);

// Compute similarity scores
console.log('\nComputing similarity scores...');
const scoredQuestions = precomputedQuestions.map(({ question, vector }) => ({
  question,
  score: cosineSimilarity(userVector, vector)
}));

// Sort by score
scoredQuestions.sort((a, b) => b.score - a.score);

console.log('\n🎯 Top 10 Recommended Questions:');
console.log('-'.repeat(60));
scoredQuestions.slice(0, 10).forEach((q, idx) => {
  console.log(`${idx + 1}. [Score: ${q.score.toFixed(4)}] ${q.question.text}`);
  console.log(`   Themes: ${q.question.themes.join(', ')}`);
  console.log('');
});

console.log('✅ Expected: Top questions relate to stress, work, anxiety (from entries)');

// Test 8: Diversity Check
console.log('\n📝 Test 8: Theme Diversity in Top 5');
console.log('-'.repeat(60));
const top5 = scoredQuestions.slice(0, 5);
const allThemes = new Set(top5.flatMap(q => q.question.themes));
console.log('Top 5 questions cover these themes:', Array.from(allThemes).join(', '));
console.log(`Theme diversity: ${allThemes.size} unique themes in top 5`);
console.log('✅ Expected: At least 3-4 different themes (avoid repetition)');

// Test 9: Score Distribution
console.log('\n📝 Test 9: Score Distribution Analysis');
console.log('-'.repeat(60));
const scores = scoredQuestions.map(q => q.score);
const avgScore = scores.reduce((a, b) => a + b, 0) / scores.length;
const maxScore = Math.max(...scores);
const minScore = Math.min(...scores);

console.log(`Highest score: ${maxScore.toFixed(4)}`);
console.log(`Lowest score: ${minScore.toFixed(4)}`);
console.log(`Average score: ${avgScore.toFixed(4)}`);
console.log(`Score range: ${(maxScore - minScore).toFixed(4)}`);
console.log('✅ Expected: Clear differentiation between top and bottom questions');

// Summary
console.log('\n' + '='.repeat(60));
console.log('🎉 All Tests Complete!');
console.log('='.repeat(60));
console.log('\nNext Steps:');
console.log('1. Review top recommended questions - do they make sense?');
console.log('2. Try different sample entries to test various scenarios');
console.log('3. Adjust question keywords if needed for better matching');
console.log('4. Once satisfied, deploy to edge function!');
console.log('');
console.log('To run again: deno run --allow-read test.ts');
console.log('');
