# Mix App Paystack + Supabase Deployment Guide
## Full Setup Guide for Payment Initialization in Mix
## Using Supabase Edge Functions + Firestore Payment Docs

---

# Table of Contents

1. Purpose
2. Current Payment Architecture
3. What Has Already Been Implemented in Flutter
4. What Still Needs to Be Done
5. Why Supabase Is Used Here
6. What the Edge Function Does
7. What Supabase Secrets Are Required
8. Required Secret Names
9. How To Add Secrets in Supabase
10. What PAYSTACK_SECRET_KEY Is
11. What MIX_FUNCTION_SECRET Is
12. Example Secret Values
13. Security Notes
14. Edge Function Folder Structure
15. Function URL
16. Function Request Contract
17. Function Response Contract
18. Flutter Flow Summary
19. Firestore Payment Flow Summary
20. Payment Attempt Lifecycle
21. Payment Verification Lifecycle
22. What the Super Admin Controls
23. How Pricing Updates Work Without App Update
24. GitHub Actions Notes
25. Deployment Checklist
26. Common Errors
27. Testing Checklist
28. Production Upgrade Path
29. Final Summary

---

# 1. Purpose

This document explains exactly how to deploy and configure the Paystack + Supabase payment setup for Mix.

It is written for:
- current maintainer
- future engineer
- super admin operator
- backend integrator

The goal is to make sure this payment system is understandable and repeatable.

---

# 2. Current Payment Architecture

The current architecture is:

## Flutter app
- creates payment attempt
- asks Supabase to initialize Paystack transaction
- receives Paystack authorization URL
- opens Paystack checkout page
- returns user to app manually
- verification screen confirms payment completion
- then order is created
- then delivery ride is created

## Supabase Edge Function
- securely uses `PAYSTACK_SECRET_KEY`
- calls Paystack `/transaction/initialize`
- returns authorization URL to app

## Firebase / Firestore
- stores payment attempts
- stores successful payment records
- stores orders
- stores rides/deliveries

---

# 3. What Has Already Been Implemented in Flutter

The app now already includes:
- payment settings screen for super admin
- payment config model
- payment service
- cart checkout flow
- manual return verification screen
- Firestore collections for payments and attempts
- app constants for Supabase Paystack function endpoint

That means Flutter-side preparation is mostly done.

---

# 4. What Still Needs to Be Done

You still need to do the backend runtime setup:
- create Supabase function
- add required secrets
- deploy function
- test function
- use your real edge function secret in app config or later move it behind safer internal flow

---

# 5. Why Supabase Is Used Here

Supabase is used because:
- you prefer free tier for backend runtime support
- Flutter Paystack plugin route was problematic with dependency compatibility
- Paystack transaction initialization requires secret key
- secret key must not be stored in Flutter app

So Supabase becomes the secure runtime helper.

---

# 6. What the Edge Function Does

The `init-paystack-transaction` function:
1. receives request from app
2. validates auth secret
3. reads `PAYSTACK_SECRET_KEY`
4. sends initialization request to Paystack
5. returns authorization URL and reference

It does **not** place order.
It only helps the app start payment securely.

---

# 7. What Supabase Secrets Are Required

You need to create these in Supabase environment/secrets:

- `PAYSTACK_SECRET_KEY`
- `MIX_FUNCTION_SECRET`

---

# 8. Required Secret Names

Use these exact names:

## `PAYSTACK_SECRET_KEY`
Your Paystack secret key

## `MIX_FUNCTION_SECRET`
A custom private secret you generate yourself to protect the function endpoint

---

# 9. How To Add Secrets in Supabase

Inside Supabase:
- go to project dashboard
- go to Edge Functions / secrets or environment variables
- add each secret by exact name

Because your UI screenshot showed Vault/Secrets area, that is where you should store these securely.

---

# 10. What PAYSTACK_SECRET_KEY Is

This is the Paystack secret key from your Paystack dashboard.

Important:
- this is **not** the public key
- this is the backend-only secret
- never put it in Flutter app code

---

# 11. What MIX_FUNCTION_SECRET Is

This is your own custom secret string used to protect the Supabase edge function from random public usage.

Example:
- long random string
- generated manually

The app sends:
- `Authorization: Bearer <MIX_FUNCTION_SECRET>`

and the Edge Function only accepts requests that match.

---

# 12. Example Secret Values

## Example only
Do not use exactly these.

- `PAYSTACK_SECRET_KEY = sk_test_xxxxxxxxxxxxx`
- `MIX_FUNCTION_SECRET = mix_secure_runtime_secret_2025_xxxxxxx`

---

# 13. Security Notes

Important notes:
- do not expose Paystack secret key in Flutter
- do not commit function secret publicly
- do not put these secrets into client-visible files in production
- use Supabase secrets or CI-managed deploy env

The app currently uses a placeholder for function secret in constants.
That should be replaced carefully.

---

# 14. Edge Function Folder Structure

Recommended structure in repo:

```text
supabase/
  functions/
    init-paystack-transaction/
      index.ts
```

This is where the function code lives.

---

# 15. Function URL

Expected deployed function URL:

```text
https://twrinntnsfqxslbauotw.supabase.co/functions/v1/init-paystack-transaction
```

This already matches the constant in your app.

---

# 16. Function Request Contract

The app sends something like:

```json
{
  "email": "user@example.com",
  "amountNaira": 8500,
  "reference": "MIX_1740000000_123456",
  "currency": "NGN",
  "metadata": {
    "type": "cart_checkout",
    "userId": "abc123",
    "itemsCount": 3,
    "itemsTotal": 7000,
    "deliveryFee": 1500,
    "distanceKm": 9.2,
    "eta": "18 mins"
  }
}
```

Headers include:
- `Content-Type: application/json`
- `Authorization: Bearer MIX_FUNCTION_SECRET`

---

# 17. Function Response Contract

Expected successful response:

```json
{
  "success": true,
  "message": "Authorization URL created",
  "data": {
    "authorization_url": "https://checkout.paystack.com/....",
    "access_code": "...",
    "reference": "MIX_1740000000_123456"
  }
}
```

The app then opens `authorization_url`.

---

# 18. Flutter Flow Summary

Current Flutter checkout behavior should be:

1. User calculates delivery estimate
2. User taps checkout
3. App initializes payment via Supabase function
4. App receives authorization URL
5. App opens Paystack checkout page
6. User completes payment
7. User returns to app manually
8. User taps “I Have Completed Payment”
9. App marks payment success in Firestore
10. App places order
11. App creates delivery ride

---

# 19. Firestore Payment Flow Summary

Two collections are used:

## `payment_attempts`
Tracks initialization + status changes

## `payments`
Tracks confirmed payment success records

This provides traceability.

---

# 20. Payment Attempt Lifecycle

Typical payment attempt statuses:
- `initiated`
- `initialized`
- `client_success`
- `client_failed`

This shows the payment journey over time.

---

# 21. Payment Verification Lifecycle

In the current manual return approach:
- user returns from browser
- app confirms completion manually
- app writes successful payment doc
- then order flow continues

This is not the strongest fraud-proof verification possible, but it is workable and aligned with your current preference and architecture.

---

# 22. What the Super Admin Controls

Super admin now has a settings screen for:
- enabling/disabling Paystack
- setting active gateway
- changing ride base fare
- changing ride price per km
- changing delivery base fare
- changing delivery price per km
- updating Paystack public key

This means pricing can change live via Firestore.

---

# 23. How Pricing Updates Work Without App Update

This is one of the most important benefits.

Because payment/pricing config is in Firestore:
- super admin changes values
- app reads updated values
- users use latest values automatically

So:
- no forced full app update
- no stale hardcoded pricing issue
- better business control

---

# 24. GitHub Actions Notes

You said you use GitHub Actions and not local Flutter.

That is okay.

The payment setup still works because:
- Flutter app builds via GitHub Actions
- Supabase function can be managed separately
- secrets can live in Supabase
- no local Flutter build is required

If you later want CI deployment for the function, GitHub secrets can help, but runtime secrets still belong in Supabase.

---

# 25. Deployment Checklist

Before payment works:
- [ ] create `PAYSTACK_SECRET_KEY` in Supabase
- [ ] create `MIX_FUNCTION_SECRET` in Supabase
- [ ] deploy `init-paystack-transaction` function
- [ ] ensure function URL matches app constant
- [ ] update app constant secret handling if needed
- [ ] test transaction initialization
- [ ] test authorization URL opens
- [ ] test manual return verification
- [ ] test order creation after payment
- [ ] test delivery ride creation after payment

---

# 26. Common Errors

## Error: function returns unauthorized
Cause:
- `MIX_FUNCTION_SECRET` missing or wrong

## Error: Paystack initialize failed
Cause:
- `PAYSTACK_SECRET_KEY` missing
- secret key invalid
- request malformed

## Error: app opens checkout but nothing happens after payment
Cause:
- manual return verification step not completed
- user did not return to app
- verification screen flow not followed

## Error: order created without payment
Cause:
- checkout flow still directly calling order creation before verification
- must ensure latest cart/payment code is active

---

# 27. Testing Checklist

## Payment config
- [ ] super admin can open payment settings
- [ ] super admin can save pricing
- [ ] values persist

## Checkout init
- [ ] signed-in user can initialize payment
- [ ] guest is blocked correctly
- [ ] auth URL opens

## Manual return
- [ ] verification screen opens
- [ ] payment confirmation writes docs
- [ ] order is placed after confirmation
- [ ] delivery ride is created after confirmation

---

# 28. Production Upgrade Path

Current approach is good for:
- test mode
- MVP
- controlled rollout

Later improvements may include:
- Paystack verification by secret key after callback/reference check
- webhook support
- automatic return deep linking
- stronger backend verification before creating `payments`
- anti-fraud checks

---

# 29. Final Summary

Your Mix app can now use:
- Firestore-driven pricing
- super admin payment configuration
- Supabase secure transaction initialization
- Paystack browser checkout
- manual return verification
- order creation after payment
- delivery creation after payment

This is a practical and stable payment architecture for your current stack and deployment style.

---

# End of Paystack + Supabase Deployment Guide
