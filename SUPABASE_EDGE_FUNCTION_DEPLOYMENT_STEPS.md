# Supabase Edge Function Deployment Steps for Mix FCM
## Step-by-Step Setup Guide

---

# 1. Create Supabase Project
If you do not already have one:
- create a Supabase project
- note the project URL

---

# 2. Create Edge Function
Function name:
- `send-fcm-notification`

Place the `index.ts` file in:

- `supabase/functions/send-fcm-notification/index.ts`

---

# 3. Set Supabase Secrets
You need these secrets:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `MIX_FUNCTION_SECRET`

---

# 4. Firebase Service Account
From Firebase / Google Cloud:
- create or use service account
- ensure it can send Firebase Cloud Messaging messages
- copy:
  - project ID
  - client email
  - private key

---

# 5. Private Key Formatting
Because environment variables often escape line breaks, store private key carefully.
The function already tries to restore `\\n` into real line breaks.

---

# 6. Deploy Function
Deploy your edge function using Supabase CLI.

Function endpoint will look like:

`https://YOUR_PROJECT.supabase.co/functions/v1/send-fcm-notification`

---

# 7. Update Flutter App Constants
Replace:

- `AppConstants.supabaseFcmFunctionUrl`
- `AppConstants.supabaseFunctionSecret`

with your real values.

---

# 8. Test With Known Token
Use a real device token from Firestore and send a sample push payload.

---

# 9. Validate App Behavior
Test:
- foreground
- background
- terminated app

---

# 10. Important Security Note
Direct client calling with a shared secret is acceptable as a first proof-of-concept,
but it is not the strongest long-term design.

Later you should move toward:
- server-generated event triggers
- queue-based processing
- less direct client initiation

---

# End of Deployment Steps
