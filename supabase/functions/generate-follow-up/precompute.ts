// precompute.ts
// IMPROVED: Pre-compute TF-IDF vectors with unified IDF across user entries + questions

import { questionBank, Question } from './question-bank.ts';
import { tokenize, removeStopWords, computeIDF, computeTFIDF } from './tfidf.ts';

export interface QuestionWithVector {
  question: Question;
  vector: Map<string, number>;
}

export interface PrecomputedResult {
  questions: QuestionWithVector[];
  idf: Map<string, number>;  // Return IDF for reuse
}

/**
 * IMPROVED: Pre-compute TF-IDF vectors for questions using UNIFIED IDF
 *
 * Key improvement: Accepts user entry documents to compute IDF across
 * both questions AND user entries, ensuring comparable vector spaces.
 *
 * @param userEntryDocuments - User's journal entries (tokenized, stop words removed)
 * @returns Questions with TF-IDF vectors and the unified IDF map
 */
export function precomputeQuestionVectors(
  userEntryDocuments: string[][] = []
): PrecomputedResult {

  // ============================================================
  // 1. PREPARE QUESTION DOCUMENTS
  // ============================================================

  const questionDocuments = questionBank.map(q => {
    // IMPROVEMENT: Include both question text AND keywords
    // This gives richer vector representation
    const combinedText = q.text + ' ' + q.keywords.join(' ');
    const tokens = tokenize(combinedText);
    return removeStopWords(tokens);
  });

  // ============================================================
  // 2. COMPUTE UNIFIED IDF (Critical Fix!)
  // ============================================================

  // CRITICAL FIX: Combine question docs + user entry docs for unified IDF
  const allDocuments = userEntryDocuments.length > 0
    ? [...questionDocuments, ...userEntryDocuments]  // User entries included
    : questionDocuments;  // Fallback if no user entries provided

  // Compute IDF across the COMBINED corpus
  // This ensures question vectors and entry vectors are in same IDF space
  const unifiedIDF = computeIDF(allDocuments);

  console.log(`📐 Computing unified IDF from ${allDocuments.length} documents (${questionDocuments.length} questions + ${userEntryDocuments.length} entries)`);

  // ============================================================
  // 3. COMPUTE TF-IDF VECTORS FOR QUESTIONS
  // ============================================================

  const questionVectors = questionBank.map((question, idx) => ({
    question,
    vector: computeTFIDF(questionDocuments[idx], unifiedIDF)  // Use unified IDF
  }));

  return {
    questions: questionVectors,
    idf: unifiedIDF  // Return IDF for computing entry vector with same scale
  };
}

/**
 * Helper: Get vocabulary size from IDF map
 */
export function getVocabularySize(idf: Map<string, number>): number {
  return idf.size;
}

/**
 * Helper: Get top N terms by IDF (rarest terms)
 */
export function getTopIDFTerms(idf: Map<string, number>, n: number = 10): [string, number][] {
  return Array.from(idf.entries())
    .sort((a, b) => b[1] - a[1])  // Sort by IDF descending
    .slice(0, n);
}
