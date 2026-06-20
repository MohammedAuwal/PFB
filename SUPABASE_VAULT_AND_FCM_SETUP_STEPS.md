# Mix App Supabase Vault + FCM Setup Steps
## Exact Practical Setup Guide for Your Supabase Project
## Project: twrinntnsfqxslbauotw.supabase.co

---

# Table of Contents

1. Purpose
2. What You Already Have
3. What You Still Need
4. Why Supabase Vault/Secrets Matters
5. Public Keys vs Secret Keys
6. Which Values Are Safe
7. Which Values Must Stay Secret
8. Secrets You Must Add to Supabase
9. How To Create the Edge Function Secret
10. Firebase Credentials Needed
11. Where To Get Firebase Credentials
12. Firebase Service Account Steps
13. What To Paste into Supabase Secrets
14. Exact Secret Names to Use
15. Function Endpoint You Will Use
16. How Flutter Will Use It
17. Why GitHub Actions Works Fine for This
18. Why You Do Not Need Flutter Installed Locally
19. Recommended Deployment Flow
20. Important Security Warning
21. Final Setup Summary

---

# 1. Purpose

This guide explains exactly how to prepare your Supabase project so the FCM Edge Function can work for Mix.

You already gave:
- Supabase URL
- anon key
- publishable key

That is useful.

Now the next important thing is the **secret configuration** inside Supabase.

---

# 2. What You Already Have

You already have:

## Supabase project URL
`https://twrinntnsfqxslbauotw.supabase.co`

## Supabase anon key
Public safe key

## Supabase publishable key
Public safe key

These are okay.

---

# 3. What You Still Need

To send push notifications through FCM using Supabase Edge Functions, you still need:

- a function secret for authorization
- Firebase service account credentials
- deployed edge function

---

# 4. Why Supabase Vault/Secrets Matters

The Edge Function must securely hold:
- Firebase credentials
- function secret

Those secrets must never be hardcoded in Flutter app code permanently.

That is why Supabase secrets/vault is important.

---

# 5. Public Keys vs Secret Keys

## Public keys
Okay to expose in Flutter app:
- Supabase URL
- anon key
- publishable key

## Secret keys
Must never be exposed in app:
- edge function secret
- Firebase private key
- Firebase client secret-style credentials

---

# 6. Which Values Are Safe

Safe in app or repo:
- Supabase project URL
- Supabase anon key
- Supabase publishable key

---

# 7. Which Values Must Stay Secret

Must be stored only in Supabase secrets:
- `MIX_FUNCTION_SECRET`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

---

# 8. Secrets You Must Add to Supabase

You need these exact secrets:

- `MIX_FUNCTION_SECRET`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

Optional future secrets:
- logging endpoints
- analytics endpoints
- internal webhook tokens

---

# 9. How To Create the Edge Function Secret

Create a random secure secret value.

Example:
- a long random string
- at least 32+ characters

Example format:
`mix_edge_secret_1f8a0d9e4a7c...`

Do not use something easy to guess.

Store it as:
- `MIX_FUNCTION_SECRET`

---

# 10. Firebase Credentials Needed

You need Firebase service account credentials that can send FCM messages.

Specifically:
- project ID
- client email
- private key

---

# 11. Where To Get Firebase Credentials

In Firebase / Google Cloud Console:

1. Open your Firebase project
2. Go to Project Settings
3. Go to Service Accounts
4. Generate private key

This gives you a JSON file.

---

# 12. Firebase Service Account Steps

From the JSON file, you will need:

- `project_id`
- `client_email`
- `private_key`

These will be copied into Supabase secrets.

---

# 13. What To Paste into Supabase Secrets

## `FIREBASE_PROJECT_ID`
Value example:
`your-firebase-project-id`

## `FIREBASE_CLIENT_EMAIL`
Value example:
`firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com`

## `FIREBASE_PRIVATE_KEY`
Paste full private key value

Important:
Keep line breaks intact or escaped properly.
The edge function already restores `\\n` to line breaks.

## `MIX_FUNCTION_SECRET`
Your own custom secret string

---

# 14. Exact Secret Names to Use

Use these names exactly:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `MIX_FUNCTION_SECRET`

This matches the code already written.

---

# 15. Function Endpoint You Will Use

The function endpoint will be:

`https://twrinntnsfqxslbauotw.supabase.co/functions/v1/send-fcm-notification`

This is already reflected in your app constants.

---

# 16. How Flutter Will Use It

Flutter-side `SupabaseNotificationService` will call that function with:
- Authorization header using `MIX_FUNCTION_SECRET`
- JSON payload containing:
  - tokens
  - title
  - body
  - type
  - targetScreen
  - targetId

---

# 17. Why GitHub Actions Works Fine for This

You said you do not have Flutter installed locally and use GitHub Actions.

That is totally fine.

This architecture still works because:
- Flutter build can happen in GitHub Actions
- Supabase function deployment can also happen from repo/CI later
- you do not need a local Flutter build environment to benefit from this design

---

# 18. Why You Do Not Need Flutter Installed Locally

You only need to:
- paste code
- push to GitHub
- let GitHub Actions build

That matches your workflow.

The Supabase Edge Function can also be kept in the repo for later deployment.

---

# 19. Recommended Deployment Flow

Recommended order:

1. add Supabase secrets
2. deploy edge function
3. verify endpoint
4. update `MIX_FUNCTION_SECRET` in your app constants or later secure config
5. test notification with one token
6. wire business events

---

# 20. Important Security Warning

For early testing, direct Flutter → Supabase function calls are acceptable.

But long term:
- client should not permanently hold a reusable secret
- move toward backend-generated queue or authenticated internal trigger model

This is especially important as the app grows.

---

# 21. Final Setup Summary

You already have:
- Supabase project URL
- public keys
- GitHub Actions build workflow

You still need:
- Firebase service account values
- one secret string for edge function auth
- deploy the edge function

Once that is done, push notification sending can work properly.

---

# End of Setup Steps
