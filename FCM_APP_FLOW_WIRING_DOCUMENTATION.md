# Mix App FCM Flow Wiring Documentation
## Actual Business Flows Now Connected to Supabase FCM Sending

---

# Table of Contents

1. Purpose
2. What Has Been Wired
3. Ride Creation Notifications
4. Order Creation Notifications
5. Delivery Creation Notifications
6. Ride Status Update Notifications
7. Order Status Update Notifications
8. Escalation Notifications
9. Reassignment Notifications
10. Who Receives What
11. Why This Matters
12. Remaining Limitations
13. Recommended Next Improvements
14. Final Summary

---

# 1. Purpose

This document explains the actual app workflows that have now been connected to Supabase FCM sending.

The purpose is to help future engineers understand exactly where notification sends happen.

---

# 2. What Has Been Wired

The following app flows are now notification-aware:

- ride creation
- order creation
- delivery creation (through order flow)
- ride status update
- order status update
- escalation fallback
- manual reassignment

---

# 3. Ride Creation Notifications

When a ride is created:
- user receives ride-created notification
- assigned admin receives admin-assignment notification
- if no admin qualifies and escalation happens, super admin receives escalation notification

---

# 4. Order Creation Notifications

When an order is placed:
- user receives confirmation notification
- assigned admin receives new-order-assigned notification
- if fallback escalation is used, super admin receives escalation notification

---

# 5. Delivery Creation Notifications

Delivery is created automatically during order placement.
Its notification behavior is effectively part of the order-created flow.

In future, you may split it into a separate dedicated delivery-created notification if needed.

---

# 6. Ride Status Update Notifications

When ride/delivery status is updated:
- the owning user is notified

This includes:
- ride updates
- delivery updates

---

# 7. Order Status Update Notifications

When order status changes:
- user is notified that order status changed

---

# 8. Escalation Notifications

When assignment falls back to super admin:
- super admin gets an escalation notification

This is one of the most important operational push events.

---

# 9. Reassignment Notifications

When a request is manually reassigned:
- the newly assigned admin gets a push notification

This ensures reassignment is visible immediately.

---

# 10. Who Receives What

## User
- ride created
- ride status update
- order created
- order status update
- delivery updates through ride/delivery status

## Assigned Admin
- new ride assigned
- new order assigned
- request reassigned

## Super Admin
- escalation created

---

# 11. Why This Matters

This turns notifications from theory into actual operational workflow.

The app now behaves more like a real platform:
- user gets lifecycle updates
- admins get assignment alerts
- super admin gets escalation alerts

---

# 12. Remaining Limitations

Current limitation:
- sends are triggered from app-side service logic
- not yet from pure backend event queue

This is acceptable for Option A and proof-of-flow, but not the strongest long-term architecture.

---

# 13. Recommended Next Improvements

1. move send triggers into backend queue model
2. log notification results
3. clean invalid tokens
4. add dedicated delivery-created notification
5. add admin order-status notifications if needed
6. add in-app notification center

---

# 14. Final Summary

The Mix app now has end-to-end notification wiring for key business flows using:
- Flutter client token storage and receive logic
- Supabase Edge Function sender
- FCM delivery

This is a strong first full notification integration path.

---

# End of Documentation
