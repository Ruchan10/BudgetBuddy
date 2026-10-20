// Budget Buddy: "categorize" Edge Function (optional)
//
// Fills in missing categories for the signed-in user's transactions with
// Supabase's built-in gte-small embedding model. It runs inside your own
// Supabase project: no API key and no third-party AI service.
//
// Deploy: Supabase Dashboard > Edge Functions > Deploy a new function >
// Via Editor. Name it "categorize", replace the example code with this file
// and press Deploy function.

import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

// Names must match the app (lib/models/category.dart). Each category has a
// few short example phrases; a title gets the category of its closest phrase.
// Positive amounts are always "Income".
const CATEGORIES: Record<string, string[]> = {
  'Food & Drinks': ['restaurant meal', 'coffee and snacks', 'lunch with friends'],
  'Groceries': ['supermarket groceries', 'vegetables and fruit', 'milk eggs and bread'],
  'Transport': ['taxi ride', 'bus fare', 'fuel for the car'],
  'Shopping': ['clothes and shoes', 'online shopping order', 'new phone or laptop'],
  'Bills & Utilities': ['electricity bill', 'internet and phone bill', 'insurance payment'],
  'Rent & Housing': ['monthly rent', 'house repair', 'furniture for the apartment'],
  'Health': ['doctor visit', 'pharmacy medicine', 'gym membership'],
  'Personal Care': ['haircut at the salon', 'cosmetics and toiletries', 'spa massage'],
  'Entertainment': ['movie tickets', 'streaming subscription', 'video game'],
  'Education': ['school tuition fee', 'books and stationery', 'online course'],
  'Travel': ['flight ticket', 'hotel booking', 'holiday trip'],
  'Gifts & Donations': ['birthday gift', 'charity donation', 'wedding present'],
};

// gte-small rates even unrelated phrases as fairly similar, so only accept a
// clear winner. These are cautious starting values: raise them if you see
// wrong categories, lower them if too much stays uncategorized.
const MIN_SCORE = 0.8;
const MIN_LEAD = 0.01;

// A request gets about 2 seconds of CPU. Stop well before that; the app calls
// again while "remaining" is above zero.
const TIME_BUDGET_MS = 1000;
const BATCH_SIZE = 40;

const createSession = () => new Supabase.ai.Session('gte-small');
let session: ReturnType<typeof createSession> | undefined;

// Embeddings of the example phrases, kept while this worker stays warm.
const examples: { category: string; phrase: string; vector: number[] }[] = [];

async function embed(text: string): Promise<number[]> {
  session ??= createSession();
  return (await session.run(text, { mean_pool: true, normalize: true })) as number[];
}

// Vectors are normalized, so the dot product is the cosine similarity.
function similarity(a: number[], b: number[]): number {
  let sum = 0;
  for (let i = 0; i < a.length; i++) sum += a[i] * b[i];
  return sum;
}

async function loadExamples(hasTime: () => boolean): Promise<boolean> {
  for (const [category, phrases] of Object.entries(CATEGORIES)) {
    for (const phrase of phrases) {
      if (examples.some((e) => e.phrase === phrase)) continue;
      if (!hasTime()) return false;
      examples.push({ category, phrase, vector: await embed(phrase) });
    }
  }
  return true;
}

async function classify(title: string): Promise<string | null> {
  const vector = await embed(title.toLowerCase());
  const best = new Map<string, number>();
  for (const example of examples) {
    const score = similarity(vector, example.vector);
    if (score > (best.get(example.category) ?? -1)) best.set(example.category, score);
  }
  const [first, second] = [...best.entries()].sort((a, b) => b[1] - a[1]);
  if (!first || first[1] < MIN_SCORE) return null;
  if (second && first[1] - second[1] < MIN_LEAD) return null;
  return first[0];
}

Deno.serve(async (req) => {
  const authorization = req.headers.get('Authorization');
  const apikey = req.headers.get('apikey');
  if (!authorization || !apikey) {
    return Response.json({ error: 'Call this from Budget Buddy while signed in.' }, { status: 401 });
  }

  // Acts as the signed-in user, so row level security limits it to their rows.
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, apikey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: rows, count, error } = await supabase
    .from('transactions')
    .select('id, title, amount', { count: 'exact' })
    .is('category', null)
    .is('ai_checked_at', null)
    .eq('deleted', false)
    .order('server_updated_at', { ascending: false })
    .limit(BATCH_SIZE);
  if (error) return Response.json({ error: error.message }, { status: 500 });
  const total = count ?? rows.length;
  if (rows.length === 0) return Response.json({ updated: 0, remaining: 0 });

  const started = Date.now();
  const hasTime = () => Date.now() - started < TIME_BUDGET_MS;

  // First call after a cold start may only get the model ready.
  if (!(await loadExamples(hasTime))) {
    return Response.json({ updated: 0, remaining: total });
  }

  const idsByCategory = new Map<string, string[]>();
  const unsure: string[] = [];
  for (const row of rows) {
    if (!hasTime()) break;
    const category = Number(row.amount) > 0 ? 'Income' : await classify(String(row.title));
    if (category) {
      idsByCategory.set(category, [...(idsByCategory.get(category) ?? []), row.id]);
    } else {
      unsure.push(row.id);
    }
  }

  // Mark every row looked at, so unsure ones aren't retried on each sync.
  // Editing a title in the app clears the mark and lets the AI try again.
  const checkedAt = new Date().toISOString();
  let updated = 0;
  for (const [category, ids] of idsByCategory) {
    const { error } = await supabase
      .from('transactions')
      .update({ category, ai_checked_at: checkedAt })
      .in('id', ids)
      .is('category', null); // never overwrite a category picked meanwhile
    if (error) return Response.json({ error: error.message }, { status: 500 });
    updated += ids.length;
  }
  if (unsure.length > 0) {
    const { error } = await supabase
      .from('transactions')
      .update({ ai_checked_at: checkedAt })
      .in('id', unsure);
    if (error) return Response.json({ error: error.message }, { status: 500 });
  }

  const processed = updated + unsure.length;
  return Response.json({ updated, remaining: Math.max(total - processed, 0) });
});
