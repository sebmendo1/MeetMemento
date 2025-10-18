// question-bank.ts
// Curated questions for follow-up recommendations

export interface Question {
  id: string;
  text: string;
  themes: string[];
  keywords: string[];
  emotionalTone: 'reflective' | 'growth' | 'processing' | 'gratitude' | 'challenge';
  depth: 'light' | 'medium' | 'deep';
}

// Sample question bank (will expand to 100+ later)
export const questionBank: Question[] = [
  // Work/Stress Related
  {
    id: 'q001',
    text: 'What boundaries do you need to set to protect your energy?',
    themes: ['self-care', 'boundaries', 'work-life-balance'],
    keywords: ['boundary', 'energy', 'protect', 'limit', 'space', 'overwhelm', 'drain', 'tired', 'exhausted'],
    emotionalTone: 'reflective',
    depth: 'medium'
  },
  {
    id: 'q002',
    text: 'What strategies help you manage stress effectively?',
    themes: ['stress', 'coping', 'self-care'],
    keywords: ['stress', 'anxious', 'worry', 'overwhelm', 'pressure', 'deadline', 'manage', 'cope'],
    emotionalTone: 'processing',
    depth: 'medium'
  },
  {
    id: 'q003',
    text: 'How can you communicate your needs more clearly at work?',
    themes: ['work', 'communication', 'boundaries'],
    keywords: ['work', 'team', 'communicate', 'needs', 'express', 'ask', 'help', 'support'],
    emotionalTone: 'growth',
    depth: 'medium'
  },

  // Anxiety/Nervousness
  {
    id: 'q004',
    text: 'What small step can you take to build confidence in challenging situations?',
    themes: ['confidence', 'growth', 'challenge'],
    keywords: ['anxious', 'nervous', 'afraid', 'scared', 'worry', 'confidence', 'challenge', 'difficult'],
    emotionalTone: 'growth',
    depth: 'medium'
  },
  {
    id: 'q005',
    text: 'When do you feel most at ease, and how can you create more of those moments?',
    themes: ['self-care', 'peace', 'awareness'],
    keywords: ['anxious', 'calm', 'peace', 'ease', 'relax', 'breathe', 'safe', 'comfortable'],
    emotionalTone: 'reflective',
    depth: 'light'
  },

  // Gratitude/Family
  {
    id: 'q006',
    text: 'What relationships in your life deserve more attention?',
    themes: ['relationships', 'gratitude', 'connection'],
    keywords: ['family', 'friend', 'love', 'relationship', 'connection', 'time', 'quality', 'present'],
    emotionalTone: 'gratitude',
    depth: 'light'
  },
  {
    id: 'q007',
    text: 'How did you show yourself compassion today?',
    themes: ['self-compassion', 'self-care'],
    keywords: ['compassion', 'kind', 'gentle', 'care', 'support', 'love', 'accept', 'forgive'],
    emotionalTone: 'gratitude',
    depth: 'light'
  },

  // Personal Growth
  {
    id: 'q008',
    text: 'What patterns are you noticing in your emotional responses?',
    themes: ['awareness', 'patterns', 'emotions'],
    keywords: ['pattern', 'notice', 'realize', 'aware', 'recognize', 'emotion', 'feel', 'react'],
    emotionalTone: 'processing',
    depth: 'deep'
  },
  {
    id: 'q009',
    text: 'What would living more authentically look like for you?',
    themes: ['authenticity', 'values', 'growth'],
    keywords: ['authentic', 'true', 'honest', 'real', 'value', 'believe', 'important', 'matter'],
    emotionalTone: 'reflective',
    depth: 'deep'
  },

  // Time Management
  {
    id: 'q010',
    text: 'What can you delegate or let go of to create more space?',
    themes: ['boundaries', 'time-management', 'prioritization'],
    keywords: ['time', 'busy', 'deadline', 'manage', 'priority', 'important', 'urgent', 'schedule'],
    emotionalTone: 'growth',
    depth: 'medium'
  },

  // Practice/Preparation
  {
    id: 'q011',
    text: 'How could more preparation support your peace of mind?',
    themes: ['preparation', 'anxiety', 'control'],
    keywords: ['prepare', 'practice', 'ready', 'plan', 'nervous', 'presentation', 'speaking', 'public'],
    emotionalTone: 'growth',
    depth: 'medium'
  },

  // Disconnection/Balance
  {
    id: 'q012',
    text: 'What helps you truly disconnect and be present?',
    themes: ['mindfulness', 'presence', 'balance'],
    keywords: ['present', 'disconnect', 'mindful', 'aware', 'moment', 'now', 'focus', 'attention'],
    emotionalTone: 'reflective',
    depth: 'light'
  },

  // Gratitude General
  {
    id: 'q013',
    text: 'What are you grateful for right now?',
    themes: ['gratitude', 'appreciation'],
    keywords: ['grateful', 'thankful', 'appreciate', 'blessing', 'lucky', 'fortunate', 'gift'],
    emotionalTone: 'gratitude',
    depth: 'light'
  },

  // Challenge/Difficulty
  {
    id: 'q014',
    text: 'What was the most challenging part of your day?',
    themes: ['challenge', 'difficulty', 'processing'],
    keywords: ['difficult', 'hard', 'challenge', 'struggle', 'tough', 'problem', 'issue'],
    emotionalTone: 'processing',
    depth: 'light'
  },

  // Self-Care
  {
    id: 'q015',
    text: 'How did you practice self-care today?',
    themes: ['self-care', 'wellness'],
    keywords: ['self-care', 'care', 'rest', 'sleep', 'exercise', 'healthy', 'wellness', 'nurture'],
    emotionalTone: 'gratitude',
    depth: 'light'
  }
];
