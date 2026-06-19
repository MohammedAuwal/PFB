# Mix App Supabase Edge Function + FCM Guide (Option A)
## Direct Notification Sender Implementation Plan
## Free-Tier Friendly Notification Backend for Mix

---

# Table of Contents

1. Purpose of This Guide
2. Why Option A Is Chosen
3. Why Supabase Free Tier Is Suitable
4. Architecture Summary
5. What This Option Will Do
6. What This Option Will Not Yet Do
7. Required Supabase Secrets
8. Required FCM Credentials
9. Required Flutter-Side Data
10. Direct Send Flow
11. Security Notes
12. Function Input Contract
13. Function Output Contract
14. Recommended Trigger Strategy
15. Suggested Next Steps After Option A
16. Final Summary

---

# 1. Purpose of This Guide

This guide documents the first backend notification implementation approach for Mix using:

- Supabase Edge Functions
- Firebase Cloud Messaging

This is Option A:
**direct notification sending**

This option is a good starting point because:
- it is easier to implement
- it works with the free tier
- it proves the push notification flow quickly
- it does not require building full queue processing first

---

# 2. Why Option A Is Chosen

You said you chose Supabase because of the free tier.

That makes sense.

Option A is therefore a strong first phase because:
- it keeps cost low
- it minimizes backend complexity
- it lets you verify real push behavior quickly
- it is enough for early operational events

---

# 3. Why Supabase Free Tier Is Suitable

Supabase free tier is useful here because:
- Edge Functions can run lightweight backend logic
- secrets can be stored securely
- it is enough for early push event traffic
- you do not need to set up a full custom backend server

As long as notification volume is not too high initially, this approach is practical.

---

# 4. Architecture Summary

In Option A:

1. Flutter app stores FCM tokens in Firestore
2. A trusted caller triggers a Supabase Edge Function
3. The Edge Function sends push message to FCM
4. Device receives push
5. Flutter app handles display and navigation

---

# 5. What This Option Will Do

Option A will support:
- sending a notification directly to one or more FCM tokens
- use secure secrets stored in Supabase
- allow transactional notification sending
- work even when app is closed

---

# 6. What This Option Will Not Yet Do

Option A does not yet include:
- notification queue processing
- retries
- idempotency
- automatic cleanup of invalid tokens
- Firestore trigger automation
- full notification analytics

Those can come later.

---

# 7. Required Supabase Secrets

The Edge Function will need secure environment variables such as:
- Firebase project ID
- Firebase client email
- Firebase private key

---

# 8. Required FCM Credentials

The function should use a Firebase service account that has permission to send messages.

---

# 9. Required Flutter-Side Data

The Flutter app should provide or make available:
- target token(s)
- notification title
- notification body
- notification type
- target screen
- target ID

---

# 10. Direct Send Flow

Recommended direct send flow:

1. event happens
2. app/backend determines recipient tokens
3. direct request sent to Supabase Edge Function
4. function sends to FCM immediately
5. response returned

---

# 11. Security Notes

Only trusted callers should call the Edge Function.

Do not expose service credentials anywhere in Flutter code.

---

# 12. Function Input Contract

Recommended input:
- `tokens`
- `title`
- `body`
- `type`
- `targetScreen`
- `targetId`

---

# 13. Function Output Contract

Recommended output:
- success boolean
- FCM response details
- failure reason if any

---

# 14. Recommended Trigger Strategy

For Option A, the fastest start is:
- call send function after important app events
- later move to stronger backend automation

---

# 15. Suggested Next Steps After Option A

After Option A works:
1. add event wrappers
2. add retry support
3. add notification queue
4. add analytics
5. add admin/super admin operational alerts

---

# 16. Final Summary

Option A is the right first move for Mix because:
- it fits your free-tier reason
- it is easier to deliver
- it proves the full notification path fast

---

# End of Guide
