// tfidf.ts
// TF-IDF implementation for analyzing journal entries

/**
 * Tokenize text: convert to lowercase, remove punctuation, split into words
 */
export function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ') // Replace punctuation with spaces
    .split(/\s+/) // Split on whitespace
    .filter(word => word.length > 2); // Remove very short words
}

/**
 * Common English stop words that don't carry meaning
 */
const STOP_WORDS = new Set([
  'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
  'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'been', 'be',
  'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
  'should', 'may', 'might', 'can', 'this', 'that', 'these', 'those',
  'i', 'you', 'he', 'she', 'it', 'we', 'they', 'my', 'your', 'his',
  'her', 'its', 'our', 'their', 'me', 'him', 'them', 'us', 'am',
  'what', 'when', 'where', 'who', 'which', 'how', 'all', 'each',
  'every', 'some', 'any', 'few', 'more', 'most', 'other', 'such',
  'no', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very'
]);

/**
 * Remove stop words from token array
 */
export function removeStopWords(tokens: string[]): string[] {
  return tokens.filter(token => !STOP_WORDS.has(token));
}

/**
 * Compute Term Frequency (TF) for a document
 * TF = (count of word in doc) / (total words in doc)
 */
export function computeTF(tokens: string[]): Map<string, number> {
  const tf = new Map<string, number>();
  const totalTokens = tokens.length;

  if (totalTokens === 0) return tf;

  // Count occurrences
  for (const token of tokens) {
    tf.set(token, (tf.get(token) || 0) + 1);
  }

  // Normalize by document length
  for (const [word, count] of tf.entries()) {
    tf.set(word, count / totalTokens);
  }

  return tf;
}

/**
 * Compute Inverse Document Frequency (IDF) across all documents
 * IDF = log(total_documents / documents_containing_word)
 */
export function computeIDF(documents: string[][]): Map<string, number> {
  const idf = new Map<string, number>();
  const totalDocs = documents.length;

  if (totalDocs === 0) return idf;

  // Count documents containing each word
  const wordDocCount = new Map<string, number>();
  for (const doc of documents) {
    const uniqueWords = new Set(doc);
    for (const word of uniqueWords) {
      wordDocCount.set(word, (wordDocCount.get(word) || 0) + 1);
    }
  }

  // Compute IDF for each word
  for (const [word, docCount] of wordDocCount.entries()) {
    idf.set(word, Math.log(totalDocs / docCount));
  }

  return idf;
}

/**
 * Compute TF-IDF vector for a document
 * TF-IDF = TF * IDF
 */
export function computeTFIDF(
  tokens: string[],
  idf: Map<string, number>
): Map<string, number> {
  const tf = computeTF(tokens);
  const tfidf = new Map<string, number>();

  for (const [word, tfScore] of tf.entries()) {
    const idfScore = idf.get(word) || 0;
    tfidf.set(word, tfScore * idfScore);
  }

  return tfidf;
}

/**
 * Compute cosine similarity between two TF-IDF vectors
 * Returns: 0 to 1 (0 = completely different, 1 = identical)
 */
export function cosineSimilarity(
  vec1: Map<string, number>,
  vec2: Map<string, number>
): number {
  let dotProduct = 0;
  let magnitude1 = 0;
  let magnitude2 = 0;

  // Get all unique words from both vectors
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

  if (magnitude1 === 0 || magnitude2 === 0) {
    return 0;
  }

  return dotProduct / (magnitude1 * magnitude2);
}
