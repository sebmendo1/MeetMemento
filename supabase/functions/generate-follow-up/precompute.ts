// precompute.ts
// Pre-compute TF-IDF vectors for all questions (runs once)

import { questionBank, Question } from './question-bank.ts';
import { tokenize, removeStopWords, computeIDF, computeTFIDF } from './tfidf.ts';

export interface QuestionWithVector {
  question: Question;
  vector: Map<string, number>;
}

/**
 * Pre-compute TF-IDF vectors for all questions in the bank
 * This runs once when the module loads, then the result is cached
 */
export function precomputeQuestionVectors(): QuestionWithVector[] {
  // Tokenize all question keywords
  const allDocuments = questionBank.map(q => {
    const tokens = tokenize(q.keywords.join(' '));
    return removeStopWords(tokens);
  });

  // Compute IDF across all questions
  const idf = computeIDF(allDocuments);

  // Compute TF-IDF vector for each question
  return questionBank.map((question, idx) => ({
    question,
    vector: computeTFIDF(allDocuments[idx], idf)
  }));
}
