# Generate Follow-Up Questions - TF-IDF Implementation

This function analyzes journal entries and recommends personalized follow-up questions using TF-IDF (Term Frequency-Inverse Document Frequency) algorithm.

## 🧪 Testing Locally (CS50 Style)

Before deploying to the edge function, test the logic locally:

### 1. Install Deno (if not installed)

```bash
curl -fsSL https://deno.land/install.sh | sh

# Add to PATH (add to ~/.zshrc or ~/.bash_profile)
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Reload shell
source ~/.zshrc

# Verify
deno --version
```

### 2. Run the Test Suite

```bash
# Navigate to this directory
cd supabase/functions/generate-follow-up

# Run the test
deno run --allow-read test.ts
```

### 3. What the Test Does

The test script (`test.ts`) runs 9 comprehensive tests:

1. **Tokenization** - Verifies text is split correctly into words
2. **Stop Word Removal** - Checks common words are filtered
3. **Term Frequency (TF)** - Validates word frequency calculation
4. **Inverse Document Frequency (IDF)** - Tests rarity scoring
5. **TF-IDF Vector** - Verifies combined TF-IDF computation
6. **Cosine Similarity** - Tests similarity scoring between vectors
7. **Question Matching** - Runs full pipeline with sample journal entries
8. **Theme Diversity** - Checks top questions cover different themes
9. **Score Distribution** - Analyzes score spread

### 4. Expected Output

```
🧪 Testing TF-IDF Follow-Up Question Generation
============================================================

📝 Test 1: Tokenization
------------------------------------------------------------
Input: Hello World! This is a test.
Tokens: [ "hello", "world", "test" ]
✅ Expected: lowercase words without punctuation

... (8 more tests)

🎯 Top 10 Recommended Questions:
------------------------------------------------------------
1. [Score: 0.4523] What strategies help you manage stress effectively?
   Themes: stress, coping, self-care

2. [Score: 0.3891] What boundaries do you need to set to protect your energy?
   Themes: self-care, boundaries, work-life-balance

... (8 more questions)

🎉 All Tests Complete!
```

### 5. Modify Sample Data

Edit `test.ts` to test different scenarios:

```typescript
// Change the sample entries to test different topics
const sampleEntries = [
  {
    id: '1',
    text: 'Your custom journal entry here...',
    created_at: '2025-01-15'
  },
  // Add more entries...
];
```

### 6. Debug Individual Functions

You can also test individual functions:

```typescript
// Create a new file: debug.ts
import { tokenize, computeTF } from './tfidf.ts';

const text = 'test your text here';
const tokens = tokenize(text);
console.log('Tokens:', tokens);

const tf = computeTF(tokens);
console.log('TF:', tf);
```

Run with:
```bash
deno run debug.ts
```

## 📊 Understanding the Output

### TF-IDF Scores

- **High scores (> 0.3)** = Strong relevance to entry content
- **Medium scores (0.1 - 0.3)** = Moderate relevance
- **Low scores (< 0.1)** = Weak relevance

### Cosine Similarity

- **1.0** = Identical content
- **0.7-0.9** = Very similar
- **0.4-0.6** = Moderately similar
- **0.0-0.3** = Different topics

## 🔧 Customization

### Add More Questions

Edit `question-bank.ts`:

```typescript
{
  id: 'q016',
  text: 'Your new question here?',
  themes: ['theme1', 'theme2'],
  keywords: ['keyword1', 'keyword2', 'keyword3'],
  emotionalTone: 'reflective',
  depth: 'medium'
}
```

### Adjust Stop Words

Edit `tfidf.ts` to add/remove stop words:

```typescript
const STOP_WORDS = new Set([
  // Add your custom stop words here
  'the', 'a', 'an', ...
]);
```

### Change Minimum Token Length

In `tfidf.ts`, adjust the filter:

```typescript
.filter(word => word.length > 2); // Change 2 to 3 for longer words only
```

## 🚀 Deploy to Edge Function

Once testing is complete:

```bash
# From project root
cd /Users/sebastianmendo/Swift-projects/MeetMemento

# Deploy
supabase functions deploy generate-follow-up
```

## 📝 File Structure

```
generate-follow-up/
├── index.ts          # Edge function entry point (TODO: implement)
├── tfidf.ts          # TF-IDF algorithm ✅ COMPLETE
├── question-bank.ts  # Curated questions ✅ COMPLETE (15 questions)
├── precompute.ts     # Pre-computation ✅ COMPLETE
├── types.ts          # TypeScript types (TODO: implement)
├── test.ts           # Test suite ✅ COMPLETE
└── README.md         # This file
```

## 🎯 Next Steps

1. ✅ Run `deno run --allow-read test.ts`
2. ✅ Verify top questions make sense for sample entries
3. ✅ Experiment with different entry content
4. ⏭️ Expand question bank to 100+ questions
5. ⏭️ Implement edge function in `index.ts`
6. ⏭️ Deploy to Supabase

## 💡 Tips

- **Start simple**: Test with 2-3 entries first
- **Check keywords**: Make sure question keywords match entry topics
- **Theme diversity**: Top 5 should cover different themes
- **Score calibration**: Adjust if all scores are too high/low

## 🐛 Troubleshooting

### "Module not found" error
- Make sure you're in the `generate-follow-up/` directory
- Check import paths end with `.ts`

### All scores are 0
- Entries might not match any question keywords
- Try adding more relevant keywords to questions
- Check stop words aren't removing key terms

### Questions seem random
- Review question keywords in `question-bank.ts`
- Ensure keywords align with likely entry content
- Add more specific keywords for better matching
