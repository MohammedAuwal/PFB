# Mix App Firebase + Supabase CI/CD Notes
## For GitHub Actions Build Workflow

---

# Important Notes

Since this project is built using GitHub Actions and not a local Flutter installation:

- Flutter code changes can still be pushed normally
- GitHub Actions can build the app
- Supabase Edge Function code can live in the same repository
- Supabase deployment can later be done from CI or manually

---

# Recommended Repo Structure

You can keep:

- Flutter app code in the root project
- Supabase edge function code in:
  - `supabase/functions/send-fcm-notification/index.ts`

This is a valid repo structure.

---

# Recommended Future CI Jobs

Later, GitHub Actions can have separate jobs:

## 1. Flutter build job
- build Android APK/AAB

## 2. Supabase function deploy job
- deploy edge function

## 3. Validation job
- lint/check config files

---

# Important Secret Handling

GitHub repository secrets are the right place for:
- Firebase build secrets if needed
- Supabase deploy token if needed

Do not commit private credentials to the repository.

---

# Summary

Your no-local-Flutter workflow is compatible with this architecture.
GitHub Actions can handle the build side while Supabase handles the notification backend side.

