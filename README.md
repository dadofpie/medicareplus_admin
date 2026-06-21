# medicare_admin_remaster

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Dev Supabase Setup (Recommended)

Use a separate Supabase project for dev/staging and keep production untouched.

1. Create `/Users/gpiedad/Documents/CodeRepo/medicareplus_admin/env/dev.json` from the template:

```bash
cp /Users/gpiedad/Documents/CodeRepo/medicareplus_admin/env/dev.example.json /Users/gpiedad/Documents/CodeRepo/medicareplus_admin/env/dev.json
```

2. Edit `/Users/gpiedad/Documents/CodeRepo/medicareplus_admin/env/dev.json` and set:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `API_BASE_URL` (your dev backend URL)

3. Run with:

```bash
flutter run -d chrome --dart-define-from-file=/Users/gpiedad/Documents/CodeRepo/medicareplus_admin/env/dev.json
```

Notes:
- `/Users/gpiedad/Documents/CodeRepo/medicareplus_admin/env/dev.json` is gitignored.
- Keep `USE_SUPABASE=true` and `INCLUDE_SUPABASE_HEADERS=true` for one-to-one behavior with live flows.

## Local Environment (No Supabase Calls)

You can run this app against a local backend and disable Supabase usage:

```bash
flutter run -d chrome \
  --dart-define=APP_ENV=local \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=USE_SUPABASE=false \
  --dart-define=INCLUDE_SUPABASE_HEADERS=false \
  --dart-define=ENABLE_LOCAL_AUTH_MOCK=true
```

Notes:
- `API_BASE_URL` should point to your local backend root.
- When `USE_SUPABASE=false`, the app skips `Supabase.initialize`.
- When `INCLUDE_SUPABASE_HEADERS=false`, requests do not send `supabase-url` or `supabase-key` headers.
- When `ENABLE_LOCAL_AUTH_MOCK=true`, login is handled locally using:
  - email: `test.admin@medicare.local`
  - password: `Test123456`
- You can override those credentials with:
  - `--dart-define=LOCAL_TEST_ADMIN_EMAIL=...`
  - `--dart-define=LOCAL_TEST_ADMIN_PASSWORD=...`
