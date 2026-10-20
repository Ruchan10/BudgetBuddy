# Budget Buddy

A simple, private, offline-first budget tracker for Android.

- **Quick entry**: type a title and an amount, that's it. The keyboard can open as soon as the app starts.
- **Categories fill themselves in** on the device and learn from your corrections. Tap a category to change it.
- **Works fully offline.** Optional sync with your own free [Supabase](https://supabase.com) project keeps several devices in step.
- Current balance, grouped history with daily, monthly and yearly totals.
- Light, dark or system theme. Any currency symbol, or none.
- No ads, no tracking, no account required.

## Cloud sync (optional)

Everything the server side needs is in [`supabase/`](supabase):

| File | What it does |
| --- | --- |
| [`setup.sql`](supabase/setup.sql) | Tables, row level security and the sync function. Paste into Supabase > SQL Editor and run it. Safe to re-run. |
| [`functions/categorize/index.ts`](supabase/functions/categorize/index.ts) | Optional Edge Function that fills in missing categories with Supabase's built-in `gte-small` model (no API key needed). |

The app walks through the whole setup, with copy buttons, under
**Settings > Setup guide**. Sync is last-write-wins per transaction; the app
always reads and writes local data and syncs in the background when online.

## Building

```sh
flutter build apk --release
```

F-Droid builds should leave out the GitHub update checker, since F-Droid
delivers updates itself and signs APKs with its own key:

```sh
flutter build apk --release --dart-define=UPDATE_CHECKER=false
```
