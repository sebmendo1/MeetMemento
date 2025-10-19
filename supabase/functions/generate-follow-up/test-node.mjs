// test-node.mjs
// Node.js version of the test (use if you don't want to install Deno)
// Run with: node test-node.mjs

// Note: In Node.js, we need to convert imports
// This is a simplified version - Deno version is more comprehensive

// ============================================================
// TF-IDF Implementation (inline for Node.js compatibility)
// ============================================================

function tokenize(text) {
  return text
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .split(/\s+/)
    .filter(word => word.length > 2);
}

const STOP_WORDS = new Set([
  'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
  'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'been', 'be',
  'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
  'should', 'may', 'might', 'can', 'this', 'that', 'these', 'those',
  'i', 'you', 'he', 'she', 'it', 'we', 'they', 'my', 'your', 'his',
  'her', 'its', 'our', 'their', 'me', 'him', 'them', 'us'
]);

function removeStopWords(tokens) {
  return tokens.filter(token => !STOP_WORDS.has(token));
}

function computeTF(tokens) {
  const tf = new Map();
  const totalTokens = tokens.length;
  if (totalTokens === 0) return tf;

  for (const token of tokens) {
    tf.set(token, (tf.get(token) || 0) + 1);
  }

  for (const [word, count] of tf.entries()) {
    tf.set(word, count / totalTokens);
  }

  return tf;
}

function computeIDF(documents) {
  const idf = new Map();
  const totalDocs = documents.length;
  if (totalDocs === 0) return idf;

  const wordDocCount = new Map();
  for (const doc of documents) {
    const uniqueWords = new Set(doc);
    for (const word of uniqueWords) {
      wordDocCount.set(word, (wordDocCount.get(word) || 0) + 1);
    }
  }

  for (const [word, docCount] of wordDocCount.entries()) {
    idf.set(word, Math.log(totalDocs / docCount));
  }

  return idf;
}

function computeTFIDF(tokens, idf) {
  const tf = computeTF(tokens);
  const tfidf = new Map();

  for (const [word, tfScore] of tf.entries()) {
    const idfScore = idf.get(word) || 0;
    tfidf.set(word, tfScore * idfScore);
  }

  return tfidf;
}

function cosineSimilarity(vec1, vec2) {
  let dotProduct = 0;
  let magnitude1 = 0;
  let magnitude2 = 0;

  const allWords = new Set([...vec1.keys(), ...vec2.keys()]);

  for (const word of allWords) {
    const val1 = vec1.get(word) || 0;
    const val2 = vec2.get(word) || 0;

    dotProduct += val1 * val2;
    magnitude1 += val1 * val1;
    magnitude2 += val2 * val2;
  }

  magnitude1 = Math.sqrt(magnitude1);
  magnitude2 = Math.sqrt(magnitude2);

  if (magnitude1 === 0 || magnitude2 === 0) return 0;

  return dotProduct / (magnitude1 * magnitude2);
}

// ============================================================
// Sample Data
// ============================================================

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

const questionBank = [
  {
    id: 'q001',
    text: 'What boundaries do you need to set to protect your energy?',
    keywords: ['boundary', 'energy', 'protect', 'limit', 'space', 'overwhelm', 'drain', 'tired', 'exhausted']
  },
  {
    id: 'q002',
    text: 'What strategies help you manage stress effectively?',
    keywords: ['stress', 'anxious', 'worry', 'overwhelm', 'pressure', 'deadline', 'manage', 'cope']
  },
  {
    id: 'q003',
    text: 'How can you communicate your needs more clearly at work?',
    keywords: ['work', 'team', 'communicate', 'needs', 'express', 'ask', 'help', 'support']
  },
  {
    id: 'q004',
    text: 'What small step can you take to build confidence in challenging situations?',
    keywords: ['anxious', 'nervous', 'afraid', 'scared', 'worry', 'confidence', 'challenge', 'difficult']
  },
  {
    id: 'q005',
    text: 'When do you feel most at ease, and how can you create more of those moments?',
    keywords: ['anxious', 'calm', 'peace', 'ease', 'relax', 'breathe', 'safe', 'comfortable']
  },
  {
    id: 'q006',
    text: 'What relationships in your life deserve more attention?',
    keywords: ['family', 'friend', 'love', 'relationship', 'connection', 'time', 'quality', 'present']
  },
  {
    id: 'q007',
    text: 'How did you show yourself compassion today?',
    keywords: ['compassion', 'kind', 'gentle', 'care', 'support', 'love', 'accept', 'forgive']
  },
  {
    id: 'q008',
    text: 'What patterns are you noticing in your emotional responses?',
    keywords: ['pattern', 'notice', 'realize', 'aware', 'recognize', 'emotion', 'feel', 'react']
  },
  {
    id: 'q009',
    text: 'How could more preparation support your peace of mind?',
    keywords: ['prepare', 'practice', 'ready', 'plan', 'nervous', 'presentation', 'speaking', 'public']
  },
  {
    id: 'q010',
    text: 'What helps you truly disconnect and be present?',
    keywords: ['present', 'disconnect', 'mindful', 'aware', 'moment', 'now', 'focus', 'attention']
  }
];

// ============================================================
// Run Tests
// ============================================================

console.log('🧪 Testing TF-IDF Follow-Up Question Generation (Node.js)\n');
console.log('='.repeat(60));

// Test: Full pipeline
console.log('\n📝 Running Full TF-IDF Pipeline');
console.log('-'.repeat(60));

// Combine all entries
const combinedText = sampleEntries.map(e => e.text).join(' ');
const userTokens = removeStopWords(tokenize(combinedText));

console.log('Sample entries:', sampleEntries.length);
console.log('Combined text length:', combinedText.length, 'characters');
console.log('Unique tokens:', userTokens.length);

// Pre-compute question vectors
const allDocs = sampleEntries.map(e => removeStopWords(tokenize(e.text)));
const docIDF = computeIDF(allDocs);
const userVector = computeTFIDF(userTokens, docIDF);

const questionDocs = questionBank.map(q => {
  const tokens = tokenize(q.keywords.join(' '));
  return removeStopWords(tokens);
});
const questionIDF = computeIDF(questionDocs);

const precomputedQuestions = questionBank.map((question, idx) => ({
  question,
  vector: computeTFIDF(questionDocs[idx], questionIDF)
}));

console.log('✅ Pre-computed', precomputedQuestions.length, 'question vectors\n');

// Compute similarity scores
const scoredQuestions = precomputedQuestions.map(({ question, vector }) => ({
  question,
  score: cosineSimilarity(userVector, vector)
}));

// Sort by score
scoredQuestions.sort((a, b) => b.score - a.score);

console.log('🎯 Top 5 Recommended Questions:');
console.log('-'.repeat(60));
scoredQuestions.slice(0, 5).forEach((q, idx) => {
  console.log(`${idx + 1}. [Score: ${q.score.toFixed(4)}] ${q.question.text}`);
});

console.log('\n' + '='.repeat(60));
console.log('🎉 Test Complete!');
console.log('='.repeat(60));
console.log('\nExpected: Top questions relate to stress, work, anxiety');
console.log('');
