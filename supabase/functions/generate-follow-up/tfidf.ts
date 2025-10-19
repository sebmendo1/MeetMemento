// tfidf.ts
// IMPROVED TF-IDF implementation with stemming, better stop words, and smoothing

/**
 * Simple stemmer - removes common English suffixes
 * Not as sophisticated as Porter Stemmer but covers 80% of cases
 */
export function stem(word: string): string {
  // Remove common suffixes in order of specificity
  if (word.endsWith('ies') && word.length > 5) {
    return word.slice(0, -3) + 'y';  // worries → worry
  }
  if (word.endsWith('ing') && word.length > 6) {
    return word.slice(0, -3);  // working → work
  }
  if (word.endsWith('ed') && word.length > 5) {
    return word.slice(0, -2);  // worked → work
  }
  if (word.endsWith('ful') && word.length > 6) {
    return word.slice(0, -3);  // stressful → stress
  }
  if (word.endsWith('ness') && word.length > 7) {
    return word.slice(0, -4);  // happiness → happi
  }
  if (word.endsWith('ly') && word.length > 5) {
    return word.slice(0, -2);  // quickly → quick
  }
  if (word.endsWith('ous') && word.length > 6) {
    return word.slice(0, -3);  // anxious → anxi
  }
  if (word.endsWith('ive') && word.length > 6) {
    return word.slice(0, -3);  // creative → creat
  }
  if (word.endsWith('er') && word.length > 5) {
    return word.slice(0, -2);  // worker → work
  }
  if (word.endsWith('est') && word.length > 6) {
    return word.slice(0, -3);  // hardest → hard
  }
  if (word.endsWith('s') && word.length > 4) {
    return word.slice(0, -1);  // deadlines → deadline
  }
  return word;
}

/**
 * Tokenize text: convert to lowercase, remove punctuation, split into words, and stem
 */
export function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ') // Replace punctuation with spaces
    .split(/\s+/) // Split on whitespace
    .filter(word => word.length > 2) // Remove very short words
    .map(word => stem(word)); // Apply stemming
}

/**
 * EXPANDED stop words list - includes common journal-specific words
 */
const STOP_WORDS = new Set([
  // Articles & conjunctions
  'the', 'a', 'an', 'and', 'or', 'but', 'if', 'because', 'as', 'until',
  'while', 'although', 'though', 'nor', 'yet',

  // Prepositions
  'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'up', 'about',
  'into', 'through', 'during', 'before', 'after', 'above', 'below', 'between',
  'under', 'over', 'out', 'off', 'down', 'near', 'across', 'behind',

  // Be verbs
  'is', 'am', 'are', 'was', 'were', 'been', 'be', 'being',

  // Have verbs
  'have', 'has', 'had', 'having',

  // Do verbs
  'do', 'does', 'did', 'doing', 'done',

  // Modal verbs
  'will', 'would', 'could', 'should', 'may', 'might', 'can', 'must', 'shall',

  // Pronouns
  'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'them', 'us',
  'my', 'your', 'his', 'its', 'our', 'their', 'mine', 'yours', 'hers', 'ours',
  'theirs', 'myself', 'yourself', 'himself', 'herself', 'itself', 'ourselves',
  'yourselves', 'themselves',

  // Demonstratives
  'this', 'that', 'these', 'those',

  // Quantifiers
  'all', 'each', 'every', 'some', 'any', 'few', 'many', 'much', 'more', 'most',
  'several', 'no', 'none', 'both', 'either', 'neither',

  // Wh-words
  'what', 'when', 'where', 'who', 'whom', 'whose', 'which', 'why', 'how',

  // Adverbs (common fillers)
  'not', 'only', 'just', 'very', 'too', 'also', 'so', 'than', 'such', 'really',
  'quite', 'rather', 'even', 'still', 'already', 'yet', 'never', 'always',
  'often', 'sometimes', 'usually', 'generally', 'especially', 'particularly',

  // Time words (journal-specific)
  'today', 'yesterday', 'tomorrow', 'now', 'then', 'ago', 'later', 'soon',
  'day', 'week', 'month', 'year', 'morning', 'afternoon', 'evening', 'night',

  // Common verbs (journal-specific)
  'feel', 'felt', 'seem', 'seemed', 'look', 'looked', 'got', 'get',
  'went', 'go', 'made', 'make', 'said', 'say', 'told', 'tell',
  'came', 'come', 'became', 'become', 'took', 'take', 'gave', 'give',
  'found', 'find', 'thought', 'think', 'knew', 'know', 'saw', 'see',

  // Other common words
  'own', 'same', 'other', 'another', 'such', 'thing', 'things',
  'way', 'ways', 'place', 'places', 'time', 'times', 'back',
  'new', 'first', 'last', 'long', 'good', 'great', 'little', 'old',
  'right', 'big', 'high', 'different', 'small', 'large', 'next', 'early',
  'young', 'important', 'few', 'public', 'bad', 'same', 'able',

  // Extra fillers
  'kind', 'sort', 'type', 'lot', 'lots', 'bit', 'piece',
  'something', 'anything', 'nothing', 'everything', 'someone', 'anyone',
  'everyone', 'nobody', 'somebody', 'anybody', 'everybody'
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
 * IDF = log((total_documents + 1) / (documents_containing_word + 1))
 * Note: Uses add-one smoothing to prevent division issues
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

  // Compute IDF for each word with smoothing
  for (const [word, docCount] of wordDocCount.entries()) {
    // Add-one smoothing to prevent log(0) and handle rare terms better
    idf.set(word, Math.log((totalDocs + 1) / (docCount + 1)));
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
